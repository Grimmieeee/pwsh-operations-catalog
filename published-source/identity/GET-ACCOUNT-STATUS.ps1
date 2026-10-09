#requires -Version 5.1

<#
GET-ACCOUNT-STATUS.ps1

OBJECTIVE
Review account state and recorded Entra sign-in activity for one or more users.

INPUT
- One UPN
- Multiple UPNs
- TXT/CSV path containing UPNs
- Optional tenant domain. When omitted, a single input domain is used.

CHANGES
Read-only. No changes are made.

IMPORTANT
Missing sign-in activity is reported as unavailable. It is not treated as inactivity.
#>

[CmdletBinding()]
param(
    [Alias('UPN')]
    [string[]]$InputObject,
    [string]$InputPath,
    [string]$TenantDomain
)

$ErrorActionPreference='Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
}

function Write-OK   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
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

function Encode-Value {
    param([string]$Value)
    return [System.Uri]::EscapeDataString($Value)
}

function Escape-OData {
    param([string]$Value)
    return ([string]$Value).Replace("'","''")
}

function Get-InputUPNs {
    param(
        [string[]]$Values,
        [string]$Path
    )

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    if ($Path) { $rawValues += $Path }

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "User UPN or TXT/CSV path").Trim().Trim('"').Trim("'")
        if ($entered) { $rawValues=@($entered) }
    }

    foreach ($value in $rawValues) {
        $clean=[Environment]::ExpandEnvironmentVariables(([string]$value).Trim().Trim('"').Trim("'"))
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($clean) -ieq '.csv') {
                foreach ($row in @(Import-Csv -LiteralPath $clean -ErrorAction Stop)) {
                    $candidate=$null
                    foreach ($name in @('UPN','UserPrincipalName','Resolved UPN','ResolvedUPN','Email','Mail','Address','User','Input')) {
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
    param(
        [string[]]$UPNs,
        [string]$ExplicitDomain
    )

    if ($ExplicitDomain) { return $ExplicitDomain.Trim().ToLowerInvariant() }

    $domains=@(
        $UPNs |
        ForEach-Object { ($_ -split '@')[-1].ToLowerInvariant() } |
        Sort-Object -Unique
    )

    if ($domains.Count -ne 1) {
        throw "Input spans multiple UPN domains. Specify -TenantDomain explicitly."
    }

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

    Import-Module $module.Path -Force -ErrorAction Stop | Out-Null

    $scopes=@('User.Read.All','Directory.Read.All','AuditLog.Read.All')
    $ctx=Get-MgContext -ErrorAction SilentlyContinue
    $reuse=$false

    if ($ctx) {
        $missing=@($scopes | Where-Object { @($ctx.Scopes) -notcontains $_ })

        if ($missing.Count -eq 0) {
            try {
                $org=Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/organization?$select=verifiedDomains' -ErrorAction Stop
                $domains=@(
                    $org.value |
                    ForEach-Object { $_.verifiedDomains } |
                    ForEach-Object { [string]$_.name } |
                    Where-Object { $_ }
                )

                if ($domains -contains $Tenant) { $reuse=$true }
            }
            catch {}
        }
    }

    if (-not $reuse) {
        if ($ctx) { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null }

        $command=Get-Command Connect-MgGraph -ErrorAction Stop
        $parameters=@{
            TenantId=$Tenant
            Scopes=$scopes
            ErrorAction='Stop'
        }
        if ($command.Parameters.ContainsKey('ContextScope')) { $parameters['ContextScope']='Process' }
        if ($command.Parameters.ContainsKey('NoWelcome')) { $parameters['NoWelcome']=$true }

        Connect-MgGraph @parameters | Out-Null
    }

    $ctx=Get-MgContext -ErrorAction Stop
    foreach ($scope in $scopes) {
        if (@($ctx.Scopes) -notcontains $scope) { throw "Graph token is missing required scope: $scope" }
    }

    $org=Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/organization?$select=verifiedDomains' -ErrorAction Stop
    $domains=@(
        $org.value |
        ForEach-Object { $_.verifiedDomains } |
        ForEach-Object { [string]$_.name } |
        Where-Object { $_ }
    )

    if ($domains -notcontains $Tenant) {
        throw "Graph connected to the wrong tenant for domain $Tenant."
    }

    Write-OK "Graph connected"
}

function Get-UserStatus {
    param([string]$UPN)

    $escaped=Escape-OData $UPN
    $filter=Encode-Value "userPrincipalName eq '$escaped'"
    $uri=('https://graph.microsoft.com/v1.0/users?$filter={0}&$select=displayName,userPrincipalName,accountEnabled,signInActivity,mail,jobTitle,department&$top=2' -f $filter)

    $result=Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop

    if (-not $result.value -or @($result.value).Count -eq 0) {
        return [pscustomobject]@{
            DisplayName=''; UPN=$UPN; AccountStatus='NotFound'; SignInStatus='NotFound'
            LastSignIn=''; DaysSince=$null; JobTitle=''; Department=''; Notes='User not found in tenant'
        }
    }

    if (@($result.value).Count -gt 1) {
        return [pscustomobject]@{
            DisplayName=''; UPN=$UPN; AccountStatus='Ambiguous'; SignInStatus='NotChecked'
            LastSignIn=''; DaysSince=$null; JobTitle=''; Department=''; Notes='More than one account matched the exact filter'
        }
    }

    $u=@($result.value)[0]
    $lastText=''
    $days=$null
    $signInStatus='Unavailable'

    if ($u.signInActivity -and $u.signInActivity.lastSignInDateTime) {
        $last=[datetime]$u.signInActivity.lastSignInDateTime
        $lastText=$last.ToLocalTime().ToString('yyyy-MM-dd HH:mm')
        $days=[int]((Get-Date)-$last).TotalDays
        $signInStatus='Available'
    }

    return [pscustomobject]@{
        DisplayName=[string]$u.displayName
        UPN=[string]$u.userPrincipalName
        AccountStatus=$(if ($u.accountEnabled -eq $true) {'Enabled'} else {'Disabled'})
        SignInStatus=$signInStatus
        LastSignIn=$lastText
        DaysSince=$days
        JobTitle=[string]$u.jobTitle
        Department=[string]$u.department
        Notes=$(if ($signInStatus -eq 'Unavailable') {'No Entra sign-in activity returned'} else {''})
    }
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
    Write-Host "ACCOUNT STATUS REVIEW"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    $upns=@(Get-InputUPNs -Values $InputObject -Path $InputPath)
    if ($upns.Count -eq 0) { throw "At least one UPN is required." }

    $TenantDomain=Get-OneDomain -UPNs $upns -ExplicitDomain $TenantDomain
    Write-Host ("Tenant  : {0}" -f $TenantDomain)
    Write-Host ("Accounts: {0}" -f $upns.Count)
    Write-Host ""

    Ensure-Graph -Tenant $TenantDomain

    $results=New-Object System.Collections.ArrayList
    $i=0

    foreach ($upn in $upns) {
        $i++
        Write-Progress -Activity "Account Status" -Status "$i / $($upns.Count) - $upn" -PercentComplete ([int](($i/$upns.Count)*100))

        try {
            $row=Get-UserStatus -UPN $upn
        }
        catch {
            $row=[pscustomobject]@{
                DisplayName=''; UPN=$upn; AccountStatus='QueryFailed'; SignInStatus='QueryFailed'
                LastSignIn=''; DaysSince=$null; JobTitle=''; Department=''; Notes=$_.Exception.Message
            }
        }

        [void]$results.Add($row)

        $age=$(if ($null -ne $row.DaysSince) { "$($row.DaysSince) days" } else { $row.SignInStatus })
        Write-Host ("  {0,-42} {1,-11} {2}" -f $row.UPN,$row.AccountStatus,$age)
    }

    Write-Progress -Activity "Account Status" -Completed

    Write-Host ""
    Write-Host "SUMMARY"
    Write-Host ("UPNs checked        : {0}" -f $upns.Count)
    Write-Host ("Enabled             : {0}" -f @($results | Where-Object { $_.AccountStatus -eq 'Enabled' }).Count)
    Write-Host ("Disabled            : {0}" -f @($results | Where-Object { $_.AccountStatus -eq 'Disabled' }).Count)
    Write-Host ("Not found           : {0}" -f @($results | Where-Object { $_.AccountStatus -eq 'NotFound' }).Count)
    Write-Host ("Query failures      : {0}" -f @($results | Where-Object { $_.AccountStatus -eq 'QueryFailed' }).Count)
    Write-Host ("Sign-in unavailable : {0}" -f @($results | Where-Object { $_.SignInStatus -eq 'Unavailable' }).Count)

    Offer-VerifiedCsv -Rows @($results) -DefaultName ("account-status-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

    Write-Host ""
    Write-OK "Complete. Missing sign-in data was not classified as inactivity."
}
catch {
    Write-Host ""
    Write-Fail $_.Exception.Message
}
finally {
    Pause-End
}
