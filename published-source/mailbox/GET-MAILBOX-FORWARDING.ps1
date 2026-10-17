<#PSScriptInfo
.VERSION 0.1.0
.GUID 910adbb8-3887-6094-7b3d-d51a129aca2c
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
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


# Console presentation only. Does not request scopes, query services or write data.
$script:FKEndWritten = $false
$script:FKStatusWritten = $false
$script:FKHasIssue = $false
function Write-FKStatus {
    param([string]$Status)
    Write-Host ''
    if ($Status -eq 'REVIEW REQUIRED') { Write-Host ('STATUS: '+$Status) -ForegroundColor Yellow }
    else { Write-Host ('STATUS: '+$Status) }
    $script:FKStatusWritten = $true
}
function Write-FKStart {
    param([string]$Title,[string]$Objective,[string]$Mode)
    Write-Host $Title
    Write-Host $Objective
    if ($Mode) { Write-Host $Mode }
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Host ''
}
function Write-FKHeading {
    param([string]$Title)
    Write-Host ''
    switch ($Title.Trim().ToUpperInvariant()) {
        'SUMMARY' { Write-Host 'TICKET SUMMARY'; break }
        'FOLLOW-UP' { Write-Host 'NEXT STEP'; break }
        'NEXT' { Write-Host 'NEXT STEP'; break }
        default { Write-Host $Title }
    }
}
function Close-FKConsole {
    param([bool]$SkipPause = $false)
    if (-not $script:FKEndWritten) {
        Write-Host ''
        if (-not $script:FKStatusWritten) {
            Write-FKStatus $(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } else { 'RUN FINISHED' })
        }
        Write-Host ("COMPLETED: {0}" -f (Get-Date).ToString('MM/dd/yyyy HH:mm'))
        $script:FKEndWritten = $true
    }
    if ($SkipPause) { return }
    Write-Host ''
    Write-Host 'Press ESC to close'
    if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and
        (Get-Command Read-Host).CommandType -ne 'Function') {
        try {
            while ($true) {
                $key=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                if ($key.VirtualKeyCode -eq 27 -or $key.VirtualKeyCode -eq 13) { return }
            }
        }
        catch { Write-Host 'Key input unavailable here.' }
    }
    while ($true) {
        $answer=Read-Host 'Type ESC then press ENTER to close'
        if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -ieq 'ESC' -or $answer -eq [string][char]27) { return }
    }
}

function Write-OK {
    param([string]$Message)
    Write-Host '[OK] ' -ForegroundColor Green -NoNewline
    Write-Host $Message
}
function Write-Info {
    param([string]$Message)
    Write-Host '[INFO] ' -NoNewline
    Write-Host $Message
}
function Write-Warn {
    param([string]$Message)
    $script:FKHasIssue = $true
    Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}
function Write-Fail {
    param([string]$Message)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Pause-End {
    Close-FKConsole
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
    Write-FKStart -Title 'MAILBOX FORWARDING CHECK' -Objective 'Shows mailbox-level and inbox-rule forwarding for one or more mailboxes without hiding query failures.' -Mode ''
    Write-Host ''
    Write-Host ""

    $mailboxes=@(Get-MailboxInputs -Values $InputObject)
    if ($mailboxes.Count -eq 0) { throw "At least one mailbox is required." }

    Connect-ExchangeAuto

    $rows=New-Object System.Collections.ArrayList
    $checked=0
    $failed=0

    foreach ($UPN in $mailboxes) {
        Write-Host ""
        Write-FKHeading -Title 'TARGET'
        Write-Host ("UPN : {0}" -f $UPN)

        try {
            $mailbox=Get-Mailbox -Identity $UPN -ErrorAction Stop
            $checked++

            $mailboxForwardingFound=$false
            $resolvedForwardingAddress=''
            Write-FKHeading 'MAILBOX FORWARDING'

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
                Write-Host 'Status: None found'
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
                Write-Host 'Status: None found'
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

    Write-FKStatus $(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } elseif (@($rows | Where-Object { $_.Status -eq 'Found' }).Count) { 'FORWARDING CONFIGURED' } else { 'NO FORWARDING FOUND' })
    Close-FKConsole -SkipPause $true

    Offer-VerifiedCsv -Rows @($rows)

    Write-Host ""
    Write-Host ''
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
