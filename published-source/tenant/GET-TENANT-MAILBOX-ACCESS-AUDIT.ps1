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
    Write-Host "TENANT MAILBOX ACCESS AUDIT"
    Write-Host "READ-ONLY. NO CHANGES MADE."
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
    Write-Host "SUMMARY" -ForegroundColor Cyan
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
