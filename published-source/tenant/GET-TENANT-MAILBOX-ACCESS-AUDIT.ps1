<#PSScriptInfo
.VERSION 0.1.0
.GUID 709a18a4-ac9c-765e-e1c2-2e4a4215945c
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
GET-TENANT-MAILBOX-ACCESS-AUDIT.ps1

Read-only tenant mailbox access audit.

Purpose:
- Reviews user and shared mailboxes tenant-wide
- Finds mailbox forwarding
- Finds Full Access, Send As, and Send on Behalf delegation
- Keeps query failures visible instead of treating them as clean results
- Optionally exports one row per mailbox to CSV

Read-only. No changes are made.
#>

param()

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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

    $Message = $ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = [string]$ErrorRecord
    }

    return (($Message -replace "\s+", " ").Trim())
}

function Confirm-Yes {
    param([string]$Prompt)

    $Answer = Read-Host "$Prompt [Y/N]"
    return ($Answer.Trim().ToUpperInvariant() -eq "Y")
}

function Ensure-Exchange {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement is not installed. Install it with: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    }

    Import-Module ExchangeOnlineManagement -ErrorAction Stop | Out-Null

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $Connection = Get-ConnectionInformation -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Connection) {
            try {
                Get-Mailbox -ResultSize 1 -ErrorAction Stop | Out-Null
                Write-OK "Exchange session reused"
                return
            }
            catch {
                Write-Warn "Existing Exchange session could not be validated. Reconnecting."
            }
        }
    }

    $Parameters = @{ ErrorAction = "Stop" }
    $Command = Get-Command Connect-ExchangeOnline -ErrorAction Stop
    if ($Command.Parameters.ContainsKey("ShowBanner")) {
        $Parameters.ShowBanner = $false
    }

    Write-Info "Connecting to Exchange Online..."
    Connect-ExchangeOnline @Parameters | Out-Null

    Get-Mailbox -ResultSize 1 -ErrorAction Stop | Out-Null
    Write-OK "Exchange connected"
}

function Resolve-RecipientNames {
    param([object[]]$Values)

    $Names = @()

    foreach ($Value in @($Values)) {
        if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
            continue
        }

        try {
            $Recipient = Get-Recipient -Identity $Value -ErrorAction Stop
            if ($Recipient.PrimarySmtpAddress) {
                $Names += [string]$Recipient.PrimarySmtpAddress
            }
            elseif ($Recipient.DisplayName) {
                $Names += [string]$Recipient.DisplayName
            }
            else {
                $Names += [string]$Value
            }
        }
        catch {
            $Names += [string]$Value
        }
    }

    return @($Names | Sort-Object -Unique)
}

try {
    try { $Host.UI.RawUI.WindowTitle = "Tenant Mailbox Access Audit" } catch {}

    Clear-Host
    Write-FKStart -Title 'TENANT MAILBOX ACCESS AUDIT' -Objective 'Finds mailbox forwarding and delegated access across the tenant without opening mailboxes one at a time.' -Mode ''
    Write-Host ''
    Write-Host ""

    Ensure-Exchange

    $RecipientTypes = @("UserMailbox", "SharedMailbox")
    $Mailboxes = @(
        Get-Mailbox `
            -ResultSize Unlimited `
            -RecipientTypeDetails $RecipientTypes `
            -ErrorAction Stop
    )

    Write-Info ("Mailboxes in scope: {0}" -f $Mailboxes.Count)

    $Rows = New-Object System.Collections.ArrayList
    $FailureCount = 0
    $FindingCount = 0

    foreach ($Mailbox in $Mailboxes) {
        $Errors = @()
        $Forwarding = @()
        $FullAccessNames = @()
        $SendAsNames = @()
        $SendOnBehalfNames = @()

        if ($Mailbox.ForwardingSmtpAddress) {
            $Forwarding += [string]$Mailbox.ForwardingSmtpAddress
        }
        if ($Mailbox.ForwardingAddress) {
            $Forwarding += [string]$Mailbox.ForwardingAddress
        }

        try {
            $FullAccess = @(
                Get-MailboxPermission -Identity $Mailbox.Identity -ErrorAction Stop |
                Where-Object {
                    $_.IsInherited -eq $false -and
                    $_.User -ne "NT AUTHORITY\SELF" -and
                    $_.AccessRights -contains "FullAccess"
                }
            )
            $FullAccessNames = @($FullAccess | ForEach-Object { [string]$_.User } | Sort-Object -Unique)
        }
        catch {
            $Errors += "Full Access unavailable: $(Get-ShortError $_)"
        }

        try {
            $SendAs = @(
                Get-RecipientPermission -Identity $Mailbox.Identity -ErrorAction Stop |
                Where-Object {
                    $_.Trustee -ne "NT AUTHORITY\SELF" -and
                    $_.AccessRights -contains "SendAs"
                }
            )
            $SendAsNames = @($SendAs | ForEach-Object { [string]$_.Trustee } | Sort-Object -Unique)
        }
        catch {
            $Errors += "Send As unavailable: $(Get-ShortError $_)"
        }

        try {
            $SendOnBehalfNames = @(Resolve-RecipientNames -Values @($Mailbox.GrantSendOnBehalfTo))
        }
        catch {
            $Errors += "Send on Behalf unavailable: $(Get-ShortError $_)"
        }

        $HasFindings = (
            $Forwarding.Count -gt 0 -or
            $FullAccessNames.Count -gt 0 -or
            $SendAsNames.Count -gt 0 -or
            $SendOnBehalfNames.Count -gt 0
        )

        if ($HasFindings) {
            $FindingCount++
            Write-Host ("{0} | forwarding:{1} full:{2} sendas:{3} behalf:{4}" -f
                $Mailbox.PrimarySmtpAddress,
                $Forwarding.Count,
                $FullAccessNames.Count,
                $SendAsNames.Count,
                $SendOnBehalfNames.Count
            )
        }

        if ($Errors.Count -gt 0) {
            $FailureCount++
            Write-Warn ("{0} | {1}" -f $Mailbox.PrimarySmtpAddress, ($Errors -join " | "))
        }

        [void]$Rows.Add([pscustomobject]@{
            Mailbox                    = [string]$Mailbox.PrimarySmtpAddress
            Type                       = [string]$Mailbox.RecipientTypeDetails
            Forwarding                 = (($Forwarding | Sort-Object -Unique) -join "; ")
            DeliverToMailboxAndForward = [bool]$Mailbox.DeliverToMailboxAndForward
            FullAccess                 = ($FullAccessNames -join "; ")
            SendAs                     = ($SendAsNames -join "; ")
            SendOnBehalf               = ($SendOnBehalfNames -join "; ")
            QueryStatus                = if ($Errors.Count -eq 0) { "Complete" } else { "Partial" }
            Errors                     = ($Errors -join " | ")
        })
    }

    Write-Host ""
    Write-FKHeading -Title 'TICKET SUMMARY'
    Write-Host "Mailboxes checked : $($Mailboxes.Count)"
    Write-Host "With findings     : $FindingCount"
    Write-Host "Partial/failed    : $FailureCount"

    if ($Rows.Count -gt 0 -and (Confirm-Yes "Export results to CSV")) {
        $DefaultName = "tenant-mailbox-access-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $Path = Read-Host "CSV output path [blank for .\$DefaultName]"

        if ([string]::IsNullOrWhiteSpace($Path)) {
            $Path = Join-Path (Get-Location).Path $DefaultName
        }

        $Rows | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-OK "Exported: $Path"
    }

    Write-Host ""
    Write-OK "Audit complete"
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
