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

function Write-OK   { param($Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "[INFO] $Message" }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param($Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
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
    Write-Host "ROOM & RESOURCE ACCESS REVIEW"
    Write-Host "READ-ONLY. NO CHANGES MADE."
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
