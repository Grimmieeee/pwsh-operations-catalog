<#PSScriptInfo
.VERSION 0.1.0
.GUID 0f435c77-7679-f315-2590-67c9949e0f61
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
GET-ROOM-RESOURCE-ACCESS.ps1

Read-only room and equipment mailbox access review.

Purpose:
- Reviews one or more room/equipment mailboxes
- Shows Full Access delegates
- Shows in-policy booking principals
- Shows resource delegates
- Optionally exports a compact CSV

Read-only. No changes are made.
#>

param(
    [string[]]$Mailbox
)

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

function Ensure-ExchangeModule {
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw "ExchangeOnlineManagement is not installed. Install it with: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    }

    Import-Module ExchangeOnlineManagement -ErrorAction Stop | Out-Null
}

function Test-AnyResource {
    param([string[]]$Targets)

    foreach ($Target in $Targets) {
        try {
            $MailboxObject = Get-Mailbox -Identity $Target -ErrorAction Stop
            if ($MailboxObject.RecipientTypeDetails -in @("RoomMailbox", "EquipmentMailbox")) {
                return $true
            }
        }
        catch {
        }
    }

    return $false
}

function Connect-ExchangeForResources {
    param([string[]]$Targets)

    Ensure-ExchangeModule

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $Connection = Get-ConnectionInformation -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($Connection -and (Test-AnyResource -Targets $Targets)) {
            Write-OK "Exchange session reused"
            return
        }
    }

    $Parameters = @{ ErrorAction = "Stop" }
    $Command = Get-Command Connect-ExchangeOnline -ErrorAction Stop
    if ($Command.Parameters.ContainsKey("ShowBanner")) {
        $Parameters.ShowBanner = $false
    }

    Write-Info "Connecting to Exchange Online..."
    Connect-ExchangeOnline @Parameters | Out-Null

    if (-not (Test-AnyResource -Targets $Targets)) {
        throw "Exchange connected, but none of the supplied room/equipment mailboxes resolved in the connected tenant."
    }

    Write-OK "Exchange connected"
}

function Read-Targets {
    $Raw = (Read-Host "Room/equipment mailbox or comma-separated list").Trim()
    if ([string]::IsNullOrWhiteSpace($Raw)) { return @() }

    return @(
        $Raw -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        Select-Object -Unique
    )
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

function Confirm-Yes {
    param([string]$Prompt)

    $Answer = Read-Host "$Prompt [Y/N]"
    return ($Answer.Trim().ToUpperInvariant() -eq "Y")
}

try {
    try { $Host.UI.RawUI.WindowTitle = "Room & Resource Access Review" } catch {}

    Clear-Host
    Write-FKStart -Title 'ROOM & RESOURCE ACCESS REVIEW' -Objective 'Shows who can access or book one or more room and equipment mailboxes.' -Mode ''
    Write-Host ''
    Write-Host ""

    if (-not $Mailbox -or $Mailbox.Count -eq 0) {
        $Mailbox = @(Read-Targets)
    }

    if (-not $Mailbox -or $Mailbox.Count -eq 0) {
        throw "At least one room or equipment mailbox is required."
    }

    Connect-ExchangeForResources -Targets $Mailbox

    $Rows = New-Object System.Collections.ArrayList

    foreach ($Target in $Mailbox) {
        Write-Host ""
        Write-Host ("RESOURCE: {0}" -f $Target) -ForegroundColor Cyan

        try {
            $ResourceMailbox = Get-Mailbox -Identity $Target -ErrorAction Stop
        }
        catch {
            Write-Warn ("Mailbox lookup failed: {0}" -f (Get-ShortError $_))
            continue
        }

        if ($ResourceMailbox.RecipientTypeDetails -notin @("RoomMailbox", "EquipmentMailbox")) {
            Write-Warn "Skipped. Target is not a room or equipment mailbox."
            continue
        }

        $Errors = @()
        $FullAccessNames = @()
        $BookInPolicyNames = @()
        $ResourceDelegateNames = @()

        try {
            $FullAccess = @(
                Get-MailboxPermission -Identity $ResourceMailbox.Identity -ErrorAction Stop |
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
            $Calendar = Get-CalendarProcessing -Identity $ResourceMailbox.Identity -ErrorAction Stop
            $BookInPolicyNames = @(Resolve-RecipientNames -Values @($Calendar.BookInPolicy))
            $ResourceDelegateNames = @(Resolve-RecipientNames -Values @($Calendar.ResourceDelegates))
        }
        catch {
            $Errors += "Calendar processing unavailable: $(Get-ShortError $_)"
        }

        Write-Host "Type              : $($ResourceMailbox.RecipientTypeDetails)"
        Write-Host "Full Access       : $(if ($FullAccessNames.Count) { $FullAccessNames -join '; ' } else { 'None found' })"
        Write-Host "Book in policy    : $(if ($BookInPolicyNames.Count) { $BookInPolicyNames -join '; ' } else { 'None found' })"
        Write-Host "Resource delegates: $(if ($ResourceDelegateNames.Count) { $ResourceDelegateNames -join '; ' } else { 'None found' })"

        foreach ($ErrorText in $Errors) {
            Write-Warn $ErrorText
        }

        [void]$Rows.Add([pscustomobject]@{
            Mailbox           = [string]$ResourceMailbox.PrimarySmtpAddress
            Type              = [string]$ResourceMailbox.RecipientTypeDetails
            FullAccess        = ($FullAccessNames -join "; ")
            BookInPolicy      = ($BookInPolicyNames -join "; ")
            ResourceDelegates = ($ResourceDelegateNames -join "; ")
            QueryStatus       = if ($Errors.Count -eq 0) { "Complete" } else { "Partial" }
            Errors            = ($Errors -join " | ")
        })
    }

    if ($Rows.Count -gt 0 -and (Confirm-Yes "Export results to CSV")) {
        $DefaultName = "room-resource-access-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
        $Path = Read-Host "CSV output path [blank for .\$DefaultName]"

        if ([string]::IsNullOrWhiteSpace($Path)) {
            $Path = Join-Path (Get-Location).Path $DefaultName
        }

        $Rows | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        Write-OK "Exported: $Path"
    }

    Write-Host ""
    Write-OK "Review complete"
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
