#requires -Version 5.1

<#
GET-MAILBOX-FORWARDING.ps1

OBJECTIVE
Review mailbox-level and inbox-rule forwarding for one or more Microsoft 365 mailboxes.

INPUT
- One mailbox UPN
- Multiple mailbox UPNs
- TXT/CSV path containing mailbox UPNs

CHANGES
Read-only. No changes are made.

REQUIRES
ExchangeOnlineManagement
#>

[CmdletBinding()]
param(
    [Alias('UPN','Mailbox')]
    [string[]]$InputObject
)

$ErrorActionPreference='Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
}

function Write-OK   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Write-Host "Press Enter to EXIT" -NoNewline
    try {
        do { $key=$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } until ($key.VirtualKeyCode -eq 13)
        Write-Host ""
    }
    catch {
        Write-Host ""
        Read-Host "Press Enter to EXIT" | Out-Null
    }
}

function Get-ShortError {
    param($ErrorRecord)
    $message=$ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) { $message=[string]$ErrorRecord }
    return (($message -replace "\s+"," ").Trim())
}

function Ensure-ExchangeModule {
    $module=Get-Module -ListAvailable -Name ExchangeOnlineManagement -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "ExchangeOnlineManagement is required but is not installed. Install with: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop
}

function Connect-ExchangeAuto {
    Ensure-ExchangeModule

    $connected=$false
    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $connection=Get-ConnectionInformation -ErrorAction SilentlyContinue |
            Where-Object {
                $_.State -eq 'Connected' -or
                $_.ConnectionStatus -eq 'Connected'
            } |
            Select-Object -First 1
        if ($connection) { $connected=$true }
    }

    if (-not $connected) {
        $command=Get-Command Connect-ExchangeOnline -ErrorAction Stop
        $parameters=@{ ErrorAction='Stop' }
        if ($command.Parameters.ContainsKey('ShowBanner')) { $parameters['ShowBanner']=$false }
        Connect-ExchangeOnline @parameters | Out-Null
    }

    Write-OK "Exchange Online connected"
}

function Get-MailboxInputs {
    param([string[]]$Values)

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "Mailbox UPN(s) or TXT/CSV path").Trim().Trim('"')
        if ($entered) { $rawValues=@($entered) }
    }

    foreach ($value in $rawValues) {
        $clean=([string]$value).Trim().Trim('"')
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($clean) -ieq '.csv') {
                foreach ($row in @(Import-Csv -LiteralPath $clean -ErrorAction Stop)) {
                    $candidate=$null
                    foreach ($name in @('UPN','UserPrincipalName','Email','Address','Mailbox','Name','Input')) {
                        if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                            $candidate=[string]$row.$name
                            break
                        }
                    }

                    if (-not $candidate) {
                        $first=$row.PSObject.Properties | Select-Object -First 1
                        if ($first) { $candidate=[string]$first.Value }
                    }

                    if ($candidate -and $candidate.Trim()) {
                        [void]$items.Add($candidate.Trim().Trim('"'))
                    }
                }
            }
            else {
                foreach ($line in @(Get-Content -LiteralPath $clean -Encoding UTF8 -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"')
                    if ($candidate -and $candidate -notmatch '^#') {
                        [void]$items.Add($candidate)
                    }
                }
            }
            continue
        }

        foreach ($candidate in @($clean -split '\s*,\s*')) {
            if ($candidate) { [void]$items.Add($candidate.Trim()) }
        }
    }

    return @($items | Where-Object { $_ } | Select-Object -Unique)
}

function Resolve-ForwardingAddress {
    param($ForwardingAddress)

    if (-not $ForwardingAddress) { return '' }

    try {
        $recipient=Get-Recipient -Identity $ForwardingAddress -ErrorAction Stop
        if ($recipient.PrimarySmtpAddress) { return [string]$recipient.PrimarySmtpAddress }
        if ($recipient.DisplayName) { return [string]$recipient.DisplayName }
    }
    catch {}

    return [string]$ForwardingAddress
}

function Convert-RuleTargets {
    param($Targets)

    return (
        @($Targets) |
        ForEach-Object { [string]$_ } |
        Where-Object { $_ } |
        Sort-Object -Unique
    ) -join '; '
}

function Offer-VerifiedCsv {
    param([object[]]$Rows,[string]$DefaultName='mailbox-forwarding-review.csv')

    if (-not $Rows -or $Rows.Count -eq 0) { return }
    if ((Read-Host "Export results to CSV [Y/N]").Trim() -notmatch '^(?i)y$') { return }

    $path=(Read-Host "CSV output path [blank for .\$DefaultName]").Trim().Trim('"')
    if (-not $path) { $path=Join-Path (Get-Location).Path $DefaultName }

    $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)

    if ($check.Count -ne $Rows.Count) {
        throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
    }

    $expected=@($Rows | ForEach-Object {
        "{0}|{1}|{2}|{3}|{4}|{5}" -f $_.Mailbox,$_.Type,$_.Name,$_.Target,$_.Enabled,$_.Status
    })
    $actual=@($check | ForEach-Object {
        "{0}|{1}|{2}|{3}|{4}|{5}" -f $_.Mailbox,$_.Type,$_.Name,$_.Target,$_.Enabled,$_.Status
    })

    if (@(Compare-Object -ReferenceObject $expected -DifferenceObject $actual -SyncWindow 0).Count -gt 0) {
        throw "CSV verification failed. Exported content did not match the in-memory results."
    }

    Write-OK "Exported and verified: $path"
}

try {
    Write-Host "MAILBOX FORWARDING CHECK"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    $mailboxes=@(Get-MailboxInputs -Values $InputObject)
    if ($mailboxes.Count -eq 0) { throw "At least one mailbox is required." }

    Connect-ExchangeAuto

    $rows=New-Object System.Collections.ArrayList
    $checked=0
    $failed=0

    foreach ($UPN in $mailboxes) {
        Write-Host ""
        Write-Host "MAILBOX"
        Write-Host ("UPN : {0}" -f $UPN)

        try {
            $mailbox=Get-Mailbox -Identity $UPN -ErrorAction Stop
            $checked++

            $mailboxForwardingFound=$false
            $resolvedForwardingAddress=''

            if ($mailbox.ForwardingAddress) {
                $mailboxForwardingFound=$true
                $resolvedForwardingAddress=Resolve-ForwardingAddress -ForwardingAddress $mailbox.ForwardingAddress

                Write-Host ("ForwardingAddress          : {0}" -f $resolvedForwardingAddress)
                [void]$rows.Add([pscustomobject]@{
                    Mailbox=$UPN; Type='MailboxForwarding'; Name='ForwardingAddress'
                    Target=$resolvedForwardingAddress; Enabled=$true; Status='Found'
                })
            }

            if ($mailbox.ForwardingSmtpAddress) {
                $mailboxForwardingFound=$true
                $smtp=[string]$mailbox.ForwardingSmtpAddress

                Write-Host ("ForwardingSmtpAddress      : {0}" -f $smtp)
                [void]$rows.Add([pscustomobject]@{
                    Mailbox=$UPN; Type='MailboxForwarding'; Name='ForwardingSmtpAddress'
                    Target=$smtp; Enabled=$true; Status='Found'
                })
            }

            if ($mailboxForwardingFound) {
                Write-Host ("DeliverToMailboxAndForward : {0}" -f $mailbox.DeliverToMailboxAndForward)
            }
            else {
                Write-Host "Mailbox-level forwarding   : None"
            }

            $rules=@()
            $ruleQueryOk=$true
            $ruleError=''

            try {
                $rules=@(
                    Get-InboxRule -Mailbox $UPN -IncludeHidden -ErrorAction Stop |
                    Where-Object {
                        $_.ForwardTo -or
                        $_.ForwardAsAttachmentTo -or
                        $_.RedirectTo
                    }
                )
            }
            catch {
                $ruleQueryOk=$false
                $ruleError=Get-ShortError $_
            }

            Write-Host ""
            Write-Host "INBOX RULE FORWARDING"

            if (-not $ruleQueryOk) {
                Write-Warn ("Query failed: {0}" -f $ruleError)
                [void]$rows.Add([pscustomobject]@{
                    Mailbox=$UPN; Type='InboxRule'; Name=''; Target=''; Enabled=''; Status="QueryFailed: $ruleError"
                })
            }
            elseif ($rules.Count -eq 0) {
                Write-Host "None found"
            }
            else {
                foreach ($rule in $rules) {
                    $targets=@()
                    if ($rule.ForwardTo) { $targets += "ForwardTo: $(Convert-RuleTargets $rule.ForwardTo)" }
                    if ($rule.ForwardAsAttachmentTo) { $targets += "ForwardAsAttachmentTo: $(Convert-RuleTargets $rule.ForwardAsAttachmentTo)" }
                    if ($rule.RedirectTo) { $targets += "RedirectTo: $(Convert-RuleTargets $rule.RedirectTo)" }

                    Write-Host ("- {0} [{1}]" -f $rule.Name,$(if ($rule.Enabled) {'Enabled'} else {'Disabled'}))
                    foreach ($target in $targets) { Write-Host ("  {0}" -f $target) }

                    [void]$rows.Add([pscustomobject]@{
                        Mailbox=$UPN
                        Type='InboxRule'
                        Name=[string]$rule.Name
                        Target=($targets -join ' | ')
                        Enabled=[bool]$rule.Enabled
                        Status='Found'
                    })
                }
            }

            if (-not $mailboxForwardingFound -and $ruleQueryOk -and $rules.Count -eq 0) {
                [void]$rows.Add([pscustomobject]@{
                    Mailbox=$UPN; Type='Summary'; Name='No forwarding found'; Target=''
                    Enabled=''; Status='Checked'
                })
            }
        }
        catch {
            $failed++
            $message=Get-ShortError $_
            Write-Fail $message
            [void]$rows.Add([pscustomobject]@{
                Mailbox=$UPN; Type='Mailbox'; Name=''; Target=''; Enabled=''; Status="Failed: $message"
            })
        }
    }

    Write-Host ""
    Write-Host "TICKET SUMMARY"
    Write-Host ("Mailboxes requested : {0}" -f $mailboxes.Count)
    Write-Host ("Mailboxes checked   : {0}" -f $checked)
    Write-Host ("Mailbox failures    : {0}" -f $failed)
    Write-Host ("Result rows         : {0}" -f $rows.Count)

    Offer-VerifiedCsv -Rows @($rows)

    Write-Host ""
    Write-OK "Complete. No changes made."
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
