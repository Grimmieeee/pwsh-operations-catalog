#requires -Version 5.1

<#
INVOKE-ENFORCE-PER-USER-MFA.ps1

OBJECTIVE
Enforce legacy per-user Microsoft Entra MFA for one or more approved users.

INPUT
- One UPN
- Multiple UPNs
- TXT/CSV path containing UPNs

IMPORTANT
Per-user MFA is separate from Conditional Access and Security Defaults.
This workflow uses the Microsoft Graph beta authentication requirements endpoint.

CHANGES
Change-making. A reviewed preview and typed ENFORCE confirmation are required.
#>

[CmdletBinding()]
param(
    [Alias('UPN')]
    [string[]]$InputObject,
    [string]$InputPath,
    [string]$TenantDomain
)

$ErrorActionPreference='Stop'

function Write-OK   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press ENTER to EXIT" | Out-Null
}

function Get-InputUPNs {
    param([string[]]$Values,[string]$Path)

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($Path) { $rawValues += $Path }

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "User UPN or TXT/CSV path").Trim().Trim('"').Trim("'")
        if ($entered) { $rawValues=@($entered) }
    }

    foreach ($value in $rawValues) {
        $clean=([string]$value).Trim().Trim('"').Trim("'")
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($clean) -ieq '.csv') {
                foreach ($row in @(Import-Csv -LiteralPath $clean -ErrorAction Stop)) {
                    $candidate=$null
                    foreach ($name in @('UPN','UserPrincipalName','Email','Mail','Address','User','Input')) {
                        if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                            $candidate=[string]$row.$name
                            break
                        }
                    }
                    if (-not $candidate) {
                        $first=$row.PSObject.Properties | Select-Object -First 1
                        if ($first) { $candidate=[string]$first.Value }
                    }
                    if ($candidate -and $candidate.Trim()) { [void]$items.Add($candidate.Trim().Trim('"').Trim("'")) }
                }
            }
            else {
                foreach ($line in @(Get-Content -LiteralPath $clean -Encoding UTF8 -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"').Trim("'")
                    if ($candidate -and $candidate -notmatch '^#') { [void]$items.Add($candidate) }
                }
            }
            continue
        }

        foreach ($candidate in @($clean -split '\s*,\s*')) {
            if ($candidate) { [void]$items.Add($candidate.Trim()) }
        }
    }

    $upns=@($items | Where-Object { $_ } | Select-Object -Unique)
    foreach ($upn in $upns) {
        if ($upn -notmatch '^[^@\s]+@[^@\s]+$') { throw "Invalid UPN: $upn" }
    }

    return $upns
}

function Get-OneDomain {
    param([string[]]$UPNs,[string]$ExplicitDomain)

    if ($ExplicitDomain) { return $ExplicitDomain.Trim().ToLowerInvariant() }

    $domains=@($UPNs | ForEach-Object { ($_ -split '@')[-1].ToLowerInvariant() } | Sort-Object -Unique)
    if ($domains.Count -ne 1) { throw "Input spans multiple UPN domains. Specify -TenantDomain explicitly." }
    return [string]$domains[0]
}

function Ensure-Graph {
    param([string]$Tenant)

    $module=Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "Microsoft.Graph.Authentication is required but is not installed. Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop

    $scopes=@(
        'Policy.ReadWrite.AuthenticationMethod',
        'UserAuthenticationMethod.Read.All',
        'User.Read.All'
    )

    $ctx=Get-MgContext -ErrorAction SilentlyContinue
    $reuse=$false

    if ($ctx) {
        $missing=@($scopes | Where-Object { @($ctx.Scopes) -notcontains $_ })
        if ($missing.Count -eq 0) {
            try {
                $org=Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/organization?$select=verifiedDomains' -ErrorAction Stop
                $domains=@($org.value | ForEach-Object { $_.verifiedDomains } | ForEach-Object { [string]$_.name } | Where-Object { $_ })
                if ($domains -contains $Tenant) { $reuse=$true }
            }
            catch {}
        }
    }

    if (-not $reuse) {
        if ($ctx) { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null }

        $command=Get-Command Connect-MgGraph -ErrorAction Stop
        $parameters=@{ TenantId=$Tenant; Scopes=$scopes; ErrorAction='Stop' }
        if ($command.Parameters.ContainsKey('ContextScope')) { $parameters['ContextScope']='Process' }
        if ($command.Parameters.ContainsKey('NoWelcome')) { $parameters['NoWelcome']=$true }
        Connect-MgGraph @parameters | Out-Null
    }

    $ctx=Get-MgContext -ErrorAction Stop
    foreach ($scope in $scopes) {
        if (@($ctx.Scopes) -notcontains $scope) { throw "Graph token is missing required scope: $scope" }
    }

    Write-OK "Graph connected"
}

function Get-MethodLabel {
    param([object]$Method)

    switch ([string]$Method.'@odata.type') {
        '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'  { 'Microsoft Authenticator'; break }
        '#microsoft.graph.phoneAuthenticationMethod'                   { 'Phone'; break }
        '#microsoft.graph.fido2AuthenticationMethod'                   { 'FIDO2 Security Key'; break }
        '#microsoft.graph.windowsHelloForBusinessAuthenticationMethod' { 'Windows Hello for Business'; break }
        '#microsoft.graph.softwareOathAuthenticationMethod'            { 'Software OATH'; break }
        '#microsoft.graph.temporaryAccessPassAuthenticationMethod'     { 'Temporary Access Pass'; break }
        '#microsoft.graph.emailAuthenticationMethod'                   { 'Email'; break }
        '#microsoft.graph.platformCredentialAuthenticationMethod'      { 'Platform Credential / Passkey'; break }
        '#microsoft.graph.passwordAuthenticationMethod'                { 'Password'; break }
        default {
            $type=[string]$Method.'@odata.type'
            if ($type) { $type -replace '^#microsoft\.graph\.','' } else { 'Unknown' }
        }
    }
}

function Get-UserRecord {
    param([string]$UPN)
    $encoded=[uri]::EscapeDataString($UPN)
    $uri=('https://graph.microsoft.com/v1.0/users/{0}?$select=id,displayName,userPrincipalName,accountEnabled,userType' -f $encoded)
    return Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
}

function Get-MfaState {
    param([string]$UserId)
    $uri=('https://graph.microsoft.com/beta/users/{0}/authentication/requirements' -f $UserId)
    return Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
}

function Get-AuthenticationMethods {
    param([string]$UserId)
    $uri=('https://graph.microsoft.com/v1.0/users/{0}/authentication/methods' -f $UserId)
    $response=Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
    return @(
        $response.value |
        ForEach-Object { Get-MethodLabel -Method $_ } |
        Where-Object { $_ -and $_ -ne 'Password' } |
        Sort-Object -Unique
    )
}

function Offer-VerifiedCsv {
    param([array]$Rows,[string]$DefaultName)

    if (-not $Rows -or $Rows.Count -eq 0) { return }
    if ((Read-Host "Export results to CSV [Y/N]").Trim() -notmatch '^(?i)y$') { return }

    $path=(Read-Host "CSV output path [blank for .\$DefaultName]").Trim().Trim('"')
    if (-not $path) { $path=Join-Path (Get-Location).Path $DefaultName }

    $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)
    if ($check.Count -ne $Rows.Count) {
        throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
    }

    Write-OK "Exported and verified: $path"
}

try {
    Write-Host "ENFORCE PER-USER MFA"
    Write-Host "Change-making. Per-user MFA is separate from Conditional Access."
    Write-Host ""

    $upns=@(Get-InputUPNs -Values $InputObject -Path $InputPath)
    if ($upns.Count -eq 0) { throw "At least one UPN is required." }

    $TenantDomain=Get-OneDomain -UPNs $upns -ExplicitDomain $TenantDomain
    Ensure-Graph -Tenant $TenantDomain

    $targets=New-Object System.Collections.ArrayList

    Write-Host ""
    Write-Host "PREVIEW"

    foreach ($upn in $upns) {
        try {
            $user=Get-UserRecord -UPN $upn
            $state=Get-MfaState -UserId ([string]$user.id)

            [void]$targets.Add([pscustomobject]@{
                Id=[string]$user.id
                Name=[string]$user.displayName
                UPN=[string]$user.userPrincipalName
                AccountEnabled=[bool]$user.accountEnabled
                Before=[string]$state.perUserMfaState
            })

            Write-Host ("- {0} | {1} | MFA: {2}" -f $user.userPrincipalName,$(if ($user.accountEnabled) {'Enabled'} else {'Disabled'}),$state.perUserMfaState)
        }
        catch {
            Write-Warn ("Unable to preview {0}: {1}" -f $upn,$_.Exception.Message)
        }
    }

    if ($targets.Count -eq 0) { throw "No users were resolved for MFA enforcement." }

    $toChange=@($targets | Where-Object { $_.Before -ne 'enforced' })

    Write-Host ""
    Write-Host ("Users resolved      : {0}" -f $targets.Count)
    Write-Host ("Already enforced    : {0}" -f @($targets | Where-Object { $_.Before -eq 'enforced' }).Count)
    Write-Host ("Would change        : {0}" -f $toChange.Count)

    if ($toChange.Count -gt 0) {
        $confirm=(Read-Host "Type ENFORCE to apply per-user MFA to the listed non-enforced accounts").Trim()
        if ($confirm -ne 'ENFORCE') {
            Write-Warn "Cancelled. No changes made."
            return
        }
    }

    $rows=New-Object System.Collections.ArrayList

    foreach ($target in $targets) {
        $result='AlreadyEnforced'

        if ($target.Before -ne 'enforced') {
            $uri=('https://graph.microsoft.com/beta/users/{0}/authentication/requirements' -f $target.Id)
            $body=@{ perUserMfaState='enforced' } | ConvertTo-Json -Compress

            try {
                Invoke-MgGraphRequest -Method PATCH -Uri $uri -Body $body -ContentType 'application/json' -ErrorAction Stop | Out-Null
                $result='Changed'
            }
            catch {
                $result='Failed'
                Write-Warn ("MFA update failed for {0}: {1}" -f $target.UPN,$_.Exception.Message)
            }
        }

        try {
            $after=Get-MfaState -UserId $target.Id
            $methods=@(Get-AuthenticationMethods -UserId $target.Id)
            $verified=([string]$after.perUserMfaState -eq 'enforced')

            if ($verified) {
                Write-OK ("{0} | MFA enforced" -f $target.UPN)
            }
            else {
                Write-Warn ("{0} | MFA state did not verify as enforced" -f $target.UPN)
                if ($result -ne 'Failed') { $result='FailedValidation' }
            }

            [void]$rows.Add([pscustomobject]@{
                Name=$target.Name
                UPN=$target.UPN
                AccountEnabled=$target.AccountEnabled
                Before=$target.Before
                After=[string]$after.perUserMfaState
                Result=$result
                Methods=($methods -join '; ')
            })
        }
        catch {
            [void]$rows.Add([pscustomobject]@{
                Name=$target.Name
                UPN=$target.UPN
                AccountEnabled=$target.AccountEnabled
                Before=$target.Before
                After=''
                Result='ValidationFailed'
                Methods=''
            })
            Write-Warn ("Validation failed for {0}: {1}" -f $target.UPN,$_.Exception.Message)
        }
    }

    Write-Host ""
    Write-Host "SUMMARY"
    Write-Host ("Users processed    : {0}" -f $rows.Count)
    Write-Host ("Verified enforced  : {0}" -f @($rows | Where-Object { $_.After -eq 'enforced' }).Count)
    Write-Host ("Failures           : {0}" -f @($rows | Where-Object { $_.Result -match 'Failed' }).Count)

    Offer-VerifiedCsv -Rows @($rows) -DefaultName ("per-user-mfa-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
catch {
    Write-Host ""
    Write-Fail $_.Exception.Message
}
finally {
    Pause-End
}
