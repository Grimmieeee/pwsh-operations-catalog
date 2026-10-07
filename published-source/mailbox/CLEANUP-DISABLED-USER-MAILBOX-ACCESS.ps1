<#
CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1

Guarded cleanup for mailbox access still assigned to a disabled user.

Purpose:
- Verifies the target Entra account is disabled before allowing cleanup
- Finds Full Access and Send As rights the user holds on other mailboxes
- Shows the complete removal plan before any change
- Removes only the discovered mailbox rights after typed confirmation

Makes changes. No mailbox content is deleted.
#>

param(
    [string]$UPN
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

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    Write-Warn $Prompt
    $Answer = Read-Host "Type $Required to continue"
    return ($Answer.Trim().ToUpperInvariant() -eq $Required.ToUpperInvariant())
}

function Ensure-GraphModule {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph.Authentication is not installed. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop | Out-Null
}

function Invoke-GraphGet {
    param([string]$Uri)

    return Invoke-MgGraphRequest `
        -Method GET `
        -Uri $Uri `
        -OutputType PSObject `
        -ErrorAction Stop
}

function Resolve-GraphUser {
    param([string]$UserPrincipalName)

    $Encoded = [System.Uri]::EscapeDataString($UserPrincipalName)
    return Invoke-GraphGet -Uri "https://graph.microsoft.com/v1.0/users/$Encoded?`$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSyncEnabled"
}

function Connect-GraphForUser {
    param([string]$UserPrincipalName)

    Ensure-GraphModule

    $RequiredScopes = @("User.Read.All")
    $Context = Get-MgContext -ErrorAction SilentlyContinue
    $ScopesOK = $false

    if ($Context) {
        $ScopesOK = $true
        foreach ($Scope in $RequiredScopes) {
            if (@($Context.Scopes) -notcontains $Scope) {
                $ScopesOK = $false
                break
            }
        }
    }

    if ($Context -and $ScopesOK) {
        try {
            $User = Resolve-GraphUser -UserPrincipalName $UserPrincipalName
            if ($User -and $User.id) {
                Write-OK "Graph session reused"
                return $User
            }
        }
        catch {
            Write-Warn "Existing Graph session could not resolve the target user. Reconnecting."
        }
    }

    if ($Context) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    $Domain = ($UserPrincipalName -split '@')[-1]
    $Parameters = @{
        TenantId     = $Domain
        Scopes       = $RequiredScopes
        ContextScope = 'Process'
        ErrorAction  = 'Stop'
    }

    $Command = Get-Command Connect-MgGraph -ErrorAction Stop
    if ($Command.Parameters.ContainsKey('NoWelcome')) {
        $Parameters.NoWelcome = $true
    }

    Write-Info "Connecting to Microsoft Graph..."
    Connect-MgGraph @Parameters | Out-Null

    $User = Resolve-GraphUser -UserPrincipalName $UPN
    if (-not $User -or -not $User.id) {
        throw "The target user was not found in the connected tenant."
    }

    Write-OK "Graph connected"
    return $User
}

function Ensure-Exchane {
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

function Test-PrincipalMatch {
    param(
        [object]$Value,
        [string[]]$Identities
    )

    $Text = ([string]$Value).Trim()
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }

    foreach ($Identity in $Identities) {
        if (-not [string]::IsNullOrWhiteSpace($Identity) -and $Text -ieq $Identity) {
            return $true
        }
    }

    return $false
}

try {
    try { $Host.UI.RawUI.WindowTitle = "Disabled User Mailbox Access Cleanup" } catch {}

    Clear-Host
    Write-Host "DISABLED USER MAILBOX ACCESS CLEANUP"
    Write-Host "MAKES CHANGES. NO MAILBOX CONTENT IS DELETED."
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        $UPN = (Read-Host "Disabled user UPN").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($UPN) -or $UPN -notmatch '@') {
        throw "A valid user UPN is required."
    }

    $GraphUser = Connect-GraphForUser -UserPrincipalName $UPN

    Write-Host ""
    Write-Host "ACCOUNT CHECK" -ForegroundColor Cyan
    Write-Host "Name          : $($GraphUser.displayName)"
    Write-Host "UPN           : $($GraphUser.userPrincipalName)"
    Write-Host "Enabled       : $($GraphUser.accountEnabled)"
    Write-Host "Hybrid synced : $($GraphUser.onPremisesSyncEnabled -eq $true)"

    if ($GraphUser.accountEnabled -ne $false) {
        throw "Cleanup blocked. The target account is still enabled. Disable the account first or use the normal offboarding workflow."
    }

    Write-OK "Target account is disabled"

    Ensure-Exchange

    $TargetRecipient = $null
    try {
        $TargetRecipient = Get-Recipient -Identity $UPN -ErrorAction Stop
    }
    catch {
        Write-Warn "The target does not resolve as an Exchange recipient. Permission matching will use the UPN only."
    }

    $Identities = @($UPN)
    if ($TargetRecipient) {
        foreach ($Candidate in @(
            [string]$TargetRecipient.PrimarySmtpAddress,
            [string]$TargetRecipient.WindowsEmailAddress,
            [string]$TargetRecipient.Identity,
            [string]$TargetRecipient.Name
        )) {
            if (-not [string]::IsNullOrWhiteSpace($Candidate)) {
                $Identities += $Candidate
            }
        }
    }
    $Identities = @($Identities | Sort-Object -Unique)

    Write-Info "Scanning mailbox permissions..."
    $Mailboxes = @(Get-Mailbox -ResultSize Unlimited -ErrorAction Stop)
    $Findings = New-Object System.Collections.ArrayList
    $ScanFailures = 0

    foreach ($Mailbox in $Mailboxes) {
        try {
            $FullAccess = @(
                Get-MailboxPermission -Identity $Mailbox.Identity -ErrorAction Stop |
                Where-Object {
                    $_.IsInherited -eq $false -and
                    $_.AccessRights -contains "FullAccess" -and
                    (Test-PrincipalMatch -Value $_.User -Identities $Identities)
                }
            )

            if ($FullAccess.Count -gt 0) {
                [void]$Findings.Add([pscustomobject]@{
                    Mailbox = [string]$Mailbox.PrimarySmtpAddress
                    Right   = "FullAccess"
                })
            }
        }
        catch {
            $ScanFailures++
            Write-Warn ("Full Access scan failed for {0}: {1}" -f $Mailbox.PrimarySmtpAddress, (Get-ShortError $_))
        }

        try {
            $SendAs = @(
                Get-RecipientPermission -Identity $Mailbox.Identity -ErrorAction Stop |
                Where-Object {
                    $_.AccessRights -contains "SendAs" -and
                    (Test-PrincipalMatch -Value $_.Trustee -Identities $Identities)
                }
            )

            if ($SendAs.Count -gt 0) {
                [void]$Findings.Add([pscustomobject]@{
                    Mailbox = [string]$Mailbox.PrimarySmtpAddress
                    Right   = "SendAs"
                })
            }
        }
        catch {
            $ScanFailures++
            Write-Warn ("Send As scan failed for {0}: {1}" -f $Mailbox.PrimarySmtpAddress, (Get-ShortError $_))
        }
    }

    Write-Host ""
    Write-Host "REMOVAL PLAN" -ForegroundColor Cyan

    if ($Findings.Count -eq 0) {
        Write-Host "No matching Full Access or Send As rights were found."
        if ($ScanFailures -gt 0) {
            Write-Warn "$ScanFailures permission query failure(s) occurred. Do not treat this as a clean result without reviewing those failures."
        }
        Write-OK "No changes made"
        return
    }

    foreach ($Finding in ($Findings | Sort-Object Mailbox, Right)) {
        Write-Host ("- {0} | {1}" -f $Finding.Mailbox, $Finding.Right)
    }

    if ($ScanFailures -gt 0) {
        Write-Warn "$ScanFailures permission query failure(s) occurred. Cleanup will only touch rights that were positively discovered above."
    }

    if (-not (Confirm-Type "Remove the discovered mailbox rights for $UPN." "CLEANUP")) {
        Write-Warn "Cleanup cancelled"
        return
    }

    $Completed = New-Object System.Collections.ArrayList
    $Failed = New-Object System.Collections.ArrayList

    foreach ($Finding in $Findings) {
        try {
            if ($Finding.Right -eq "FullAccess") {
                Remove-MailboxPermission `
                    -Identity $Finding.Mailbox `
                    -User $UPN `
                    -AccessRights FullAccess `
                    -InheritanceType All `
                    -Confirm:$false `
                    -ErrorAction Stop
            }
            elseif ($Finding.Right -eq "SendAs") {
                Remove-RecipientPermission `
                    -Identity $Finding.Mailbox `
                    -Trustee $UPN `
                    -AccessRights SendAs `
                    -Confirm:$false `
                    -ErrorAction Stop
            }

            [void]$Completed.Add($Finding)
            Write-OK ("Removed {0} from {1}" -f $Finding.Right, $Finding.Mailbox)
        }
        catch {
            [void]$Failed.Add([pscustomobject]@{
                Mailbox = $Finding.Mailbox
                Right   = $Finding.Right
                Error   = Get-ShortError $_
            })
            Write-Fail ("Failed {0} on {1}: {2}" -f $Finding.Right, $Finding.Mailbox, (Get-ShortError $_))
        }
    }

    Write-Host ""
    Write-Host "SUMMARY" -ForegroundColor Cyan
    Write-Host "Target    : $UPN"
    Write-Host "Discovered: $($Findings.Count)"
    Write-Host "Removed   : $($Completed.Count)"
    Write-Host "Failed    : $($Failed.Count)"

    if ($Failed.Count -gt 0) {
        Write-Warn "One or more removals failed. Review the failures above."
    }
    else {
        Write-OK "Cleanup complete"
    }
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
