#Requires -Version 5.1

<#
INVOKE-RESET-CLOUD-USER-PASSWORD.ps1

OBJECTIVE
Reset one or more cloud-only Entra user passwords.

INPUT
- One UPN.
- Comma-separated UPNs.
- TXT or CSV file containing UPNs.

SAFETY
- Refuses users with OnPremisesSyncEnabled = true so Active Directory remains authoritative.
- Shows a preview before changes.
- Requires typed RESET confirmation.
- Generates a cryptographically random temporary password.
- Never exports or writes generated passwords to disk.
- Temporary passwords are shown only after a successful reset.

GRAPH
Requires Microsoft.Graph.Authentication and delegated scopes:
- User.Read.All
- User-PasswordProfile.ReadWrite.All
#>

[CmdletBinding()]
param(
    [Alias('UPN','User')]
    [string[]]$InputObject,

    [string]$TenantDomain,

    [ValidateRange(16,64)]
    [int]$PasswordLength = 20,

    [switch]$NoForceChangeNextSignIn
)

$ErrorActionPreference = 'Stop'

function Write-OK   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function Pause-End {
    Write-FieldKitFooter
    Read-Host "Press Enter to EXIT" | Out-Null
}

function Ensure-GraphAuthentication {
    $module = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "Microsoft.Graph.Authentication is required. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop
}

function Get-InputUsers {
    param([string[]]$Values)

    $items = New-Object System.Collections.ArrayList
    $rawValues = @($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($rawValues.Count -eq 0) {
        $entered = (Read-Host "User UPN, comma-separated UPNs, or TXT/CSV path").Trim().Trim('"')
        if ($entered) { $rawValues = @($entered) }
    }

    foreach ($value in $rawValues) {
        $clean = ([string]$value).Trim().Trim('"')
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($clean) -ieq '.csv') {
                foreach ($row in @(Import-Csv -LiteralPath $clean -ErrorAction Stop)) {
                    $candidate = $null

                    foreach ($name in @('UPN','UserPrincipalName','Email','Address','User','Input')) {
                        if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                            $candidate = [string]$row.$name
                            break
                        }
                    }

                    if (-not $candidate) {
                        $first = $row.PSObject.Properties | Select-Object -First 1
                        if ($first) { $candidate = [string]$first.Value }
                    }

                    if ($candidate -and $candidate.Trim()) {
                        [void]$items.Add($candidate.Trim().Trim('"'))
                    }
                }
            }
            else {
                foreach ($line in @(Get-Content -LiteralPath $clean -Encoding UTF8 -ErrorAction Stop)) {
                    $candidate = ([string]$line).Trim().Trim('"')
                    if ($candidate -and $candidate -notmatch '^#') {
                        [void]$items.Add($candidate)
                    }
                }
            }

            continue
        }

        foreach ($candidate in @($clean -split '\s*,\s*')) {
            if ($candidate) {
                [void]$items.Add($candidate.Trim())
            }
        }
    }

    return @($items | Where-Object { $_ } | Select-Object -Unique)
}

function Test-ScopesPresent {
    param(
        $Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) { return $false }

    foreach ($scope in $RequiredScopes) {
        if ($Context.Scopes -notcontains $scope) {
            return $false
        }
    }

    return $true
}

function Connect-FieldKitGraph {
    param(
        [string]$Tenant,
        [string[]]$Scopes
    )

    Ensure-GraphAuthentication

    $context = Get-MgContext -ErrorAction SilentlyContinue
    if ($context) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
        }
    }

    $command = Get-Command Connect-MgGraph -ErrorAction Stop
    $parameters = @{
        Scopes = $Scopes
        ErrorAction = 'Stop'
    }

    if ($Tenant -and $command.Parameters.ContainsKey('TenantId')) {
        $parameters['TenantId'] = $Tenant
    }

    if ($command.Parameters.ContainsKey('ContextScope')) {
        $parameters['ContextScope'] = 'Process'
    }

    if ($command.Parameters.ContainsKey('NoWelcome')) {
        $parameters['NoWelcome'] = $true
    }

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop
    if (-not (Test-ScopesPresent -Context $context -RequiredScopes $Scopes)) {
        throw "Graph connected, but the required password-reset scopes are not present."
    }

    Write-OK "Microsoft Graph connected"
    if ($context.Account) { Write-Host ("Account : {0}" -f $context.Account) }
    if ($context.TenantId) { Write-Host ("Tenant  : {0}" -f $context.TenantId) }
}

function Get-GraphUser {
    param([string]$UPN)

    $encoded = [System.Uri]::EscapeDataString($UPN)
    $query = '$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSyncEnabled,lastPasswordChangeDateTime'
    $uri = "https://graph.microsoft.com/v1.0/users/{0}?{1}" -f $encoded,$query

    return Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
}

function Get-CryptoIndex {
    param(
        [System.Security.Cryptography.RandomNumberGenerator]$Rng,
        [int]$Maximum
    )

    $bytes = New-Object byte[] 4
    $Rng.GetBytes($bytes)
    $value = [BitConverter]::ToUInt32($bytes,0)
    return [int]($value % [uint32]$Maximum)
}

function New-TemporaryPassword {
    param([int]$Length)

    $lower = 'abcdefghijkmnopqrstuvwxyz'.ToCharArray()
    $upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ'.ToCharArray()
    $digits = '23456789'.ToCharArray()
    $special = '!@#$%*-_=+'.ToCharArray()
    $all = @($lower + $upper + $digits + $special)

    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()

    try {
        $chars = New-Object System.Collections.ArrayList
        [void]$chars.Add($lower[(Get-CryptoIndex -Rng $rng -Maximum $lower.Count)])
        [void]$chars.Add($upper[(Get-CryptoIndex -Rng $rng -Maximum $upper.Count)])
        [void]$chars.Add($digits[(Get-CryptoIndex -Rng $rng -Maximum $digits.Count)])
        [void]$chars.Add($special[(Get-CryptoIndex -Rng $rng -Maximum $special.Count)])

        while ($chars.Count -lt $Length) {
            [void]$chars.Add($all[(Get-CryptoIndex -Rng $rng -Maximum $all.Count)])
        }

        for ($i = $chars.Count - 1; $i -gt 0; $i--) {
            $j = Get-CryptoIndex -Rng $rng -Maximum ($i + 1)
            $tmp = $chars[$i]
            $chars[$i] = $chars[$j]
            $chars[$j] = $tmp
        }

        return (-join $chars)
    }
    finally {
        $rng.Dispose()
    }
}

try {
    Write-Host "RESET CLOUD USER PASSWORD"
    Write-Host "MAKES CHANGES. CLOUD-ONLY USERS ONLY."
    Write-Host ""

    $users = @(Get-InputUsers -Values $InputObject)
    if ($users.Count -eq 0) {
        throw "At least one user UPN is required."
    }

    $validUsers = @($users | Where-Object { $_ -match '^[^@\s]+@[^@\s]+$' })
    if ($validUsers.Count -ne $users.Count) {
        throw "Every target must be a valid user UPN."
    }

    $domains = @($validUsers | ForEach-Object { ($_ -split '@')[-1].ToLowerInvariant() } | Select-Object -Unique)

    if (-not $TenantDomain) {
        if ($domains.Count -ne 1) {
            throw "Targets span multiple UPN domains. Supply -TenantDomain or run each tenant separately."
        }

        $TenantDomain = $domains[0]
    }

    $requiredScopes = @(
        'User.Read.All',
        'User-PasswordProfile.ReadWrite.All'
    )

    Connect-FieldKitGraph -Tenant $TenantDomain -Scopes $requiredScopes

    $targets = New-Object System.Collections.ArrayList

    foreach ($upn in $validUsers) {
        try {
            $user = Get-GraphUser -UPN $upn
            $status = if ($user.onPremisesSyncEnabled -eq $true) {
                'SKIP - synced / AD authoritative'
            }
            else {
                'READY - cloud-only'
            }

            [void]$targets.Add([pscustomobject]@{
                UPN = $user.userPrincipalName
                DisplayName = $user.displayName
                Enabled = $user.accountEnabled
                Synced = ($user.onPremisesSyncEnabled -eq $true)
                LastPasswordChange = $user.lastPasswordChangeDateTime
                Status = $status
            })
        }
        catch {
            [void]$targets.Add([pscustomobject]@{
                UPN = $upn
                DisplayName = ''
                Enabled = $null
                Synced = $null
                LastPasswordChange = $null
                Status = 'ERROR - user not resolved'
            })
        }
    }

    Write-Host ""
    Write-Host "PREVIEW"
    $targets | Select-Object UPN,DisplayName,Enabled,Synced,Status | Format-Table -AutoSize

    $ready = @($targets | Where-Object { $_.Status -eq 'READY - cloud-only' })
    if ($ready.Count -eq 0) {
        Write-Warn "No cloud-only users are eligible for reset."
        Write-OK "No changes made."
        return
    }

    $forceChange = -not $NoForceChangeNextSignIn
    if (-not $NoForceChangeNextSignIn) {
        $answer = (Read-Host "Force password change at next sign-in [Y/n]").Trim()
        if ($answer -match '^(?i)n') {
            $forceChange = $false
        }
    }

    Write-Host ""
    Write-Warn "Temporary passwords will be printed to this console after each successful reset."
    Write-Warn "Terminal capture or PowerShell transcription may record console output."
    $confirm = (Read-Host "Type RESET to continue").Trim()

    if ($confirm -ne 'RESET') {
        Write-Warn "Cancelled. No passwords were reset."
        return
    }

    $results = New-Object System.Collections.ArrayList

    foreach ($target in $targets) {
        if ($target.Status -ne 'READY - cloud-only') {
            [void]$results.Add([pscustomobject]@{
                UPN = $target.UPN
                Result = $target.Status
                Verification = 'Not changed'
            })
            continue
        }

        $temporaryPassword = $null

        try {
            $temporaryPassword = New-TemporaryPassword -Length $PasswordLength

            $encoded = [System.Uri]::EscapeDataString($target.UPN)
            $uri = "https://graph.microsoft.com/v1.0/users/{0}" -f $encoded
            $body = @{
                passwordProfile = @{
                    password = $temporaryPassword
                    forceChangePasswordNextSignIn = $forceChange
                }
            } | ConvertTo-Json -Depth 4 -Compress

            Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null

            $verified = $false
            $afterValue = $null

            for ($attempt = 1; $attempt -le 5; $attempt++) {
                Start-Sleep -Seconds 2
                $after = Get-GraphUser -UPN $target.UPN
                $afterValue = $after.lastPasswordChangeDateTime

                if (
                    $afterValue -and
                    (
                        -not $target.LastPasswordChange -or
                        [string]$afterValue -ne [string]$target.LastPasswordChange
                    )
                ) {
                    $verified = $true
                    break
                }
            }

            Write-Host ""
            Write-Host "RESET COMPLETE"
            Write-Host ("UPN                : {0}" -f $target.UPN)
            Write-Host ("Temporary password : {0}" -f $temporaryPassword) -ForegroundColor Yellow
            Write-Host ("Force change       : {0}" -f $forceChange)
            Write-Host ("Verification       : {0}" -f $(if ($verified) { 'Verified by password-change timestamp' } else { 'Command accepted; timestamp pending' }))

            [void]$results.Add([pscustomobject]@{
                UPN = $target.UPN
                Result = 'Reset submitted'
                Verification = $(if ($verified) { 'Verified' } else { 'Timestamp pending' })
            })
        }
        catch {
            Write-Fail ("{0} :: {1}" -f $target.UPN,$_.Exception.Message)

            [void]$results.Add([pscustomobject]@{
                UPN = $target.UPN
                Result = 'Failed'
                Verification = 'Failed'
            })
        }
        finally {
            $temporaryPassword = $null
            Remove-Variable temporaryPassword -ErrorAction SilentlyContinue
        }
    }

    Write-Host ""
    Write-Host "SUMMARY"
    $results | Format-Table UPN,Result,Verification -AutoSize
    Write-Host ""
    Write-OK "Complete. Generated passwords were not exported."
}
catch {
    Write-Fail $_.Exception.Message
}
finally {
    Pause-End
}
