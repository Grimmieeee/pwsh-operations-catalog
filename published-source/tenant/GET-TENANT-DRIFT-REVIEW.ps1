<#
GET-TENANT-DRIFT-REVIEW.ps1

Read-only tenant change detector.

Baseline scope:
- Active directory-role assignments
- Eligible directory-role assignments
- Conditional Access policies
- App registrations and credentials
- Delegated OAuth consent grants

The only change this script can make is writing or replacing its local JSON
baseline after explicit approval.
#>

[CmdletBinding()]
param(
    [string]$BaselinePath,
    [switch]$CaptureBaseline
)


[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

function Write-OK {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
}

function Get-FriendlyGraphError {
    param([object]$ErrorRecord)

    if (-not $ErrorRecord) {
        return 'Unknown Graph error'
    }

    $message = [string]$ErrorRecord.Exception.Message

    if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
        $message = "{0} | {1}" -f
            $message,
            [string]$ErrorRecord.ErrorDetails.Message
    }

    if ($message -match '(?i)forbidden|access denied|insufficient privileges|authorization_requestdenied') {
        return 'Access denied for this check'
    }

    if ($message -match '(?i)unauthorized|authentication') {
        return 'Authentication failed for this check'
    }

    if ($message -match '(?i)not licensed|license') {
        return 'The tenant may not be licensed for this capability'
    }

    if ($message -match '(?i)not found|resource.*does not exist|404') {
        return 'This capability or endpoint is not available'
    }

    if ($message -match '(?i)bad request|request URI is not valid|400') {
        return 'Microsoft Graph rejected the request'
    }

    if ([string]::IsNullOrWhiteSpace($message)) {
        return 'Unknown Graph error'
    }

    $oneLine = ($message -replace '[\r\n]+', ' ').Trim()

    if ($oneLine.Length -gt 220) {
        return $oneLine.Substring(0, 220) + '...'
    }

    return $oneLine
}

function Ensure-GraphAuthenticationModule {
    $module=Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "Microsoft.Graph.Authentication is required but is not installed. Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop
}

function Test-GraphScopes {
    param(
        [object]$Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) {
        return $false
    }

    $currentScopes = @($Context.Scopes)

    foreach ($scope in $RequiredScopes) {
        if ($currentScopes -notcontains $scope) {
            return $false
        }
    }

    return $true
}

function Invoke-GraphGet {
    param([string]$Uri)

    return Invoke-MgGraphRequest `
        -Method GET `
        -Uri $Uri `
        -OutputType PSObject `
        -ErrorAction Stop
}

function Invoke-GraphGetSafe {
    param([string]$Uri)

    try {
        return [pscustomobject]@{
            OK    = $true
            Data  = Invoke-GraphGet -Uri $Uri
            Error = ''
        }
    }
    catch {
        return [pscustomobject]@{
            OK    = $false
            Data  = $null
            Error = Get-FriendlyGraphError -ErrorRecord $_
        }
    }
}

function Get-GraphPages {
    param([string]$Uri)

    $items = @()
    $next = $Uri

    while ($next) {
        $page = Invoke-GraphGet -Uri $next

        if ($page -and $page.value) {
            foreach ($item in @($page.value)) {
                $items += $item
            }
        }

        $next = [string]$page.'@odata.nextLink'
    }

    return @($items)
}

function Connect-Graph {
    param([string[]]$Scopes)

    Ensure-GraphAuthenticationModule

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if ($context -and (Test-GraphScopes -Context $context -RequiredScopes $Scopes)) {
        try {
            $test = Invoke-GraphGet -Uri 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName'

            if ($test -and $test.value) {
                Write-OK "Graph session reused"
                return
            }
        }
        catch {
            # Reconnect below.
        }
    }

    if ($context) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Host "Graph: Connecting..."

    $parameters = @{
        Scopes       = $Scopes
        ContextScope = 'Process'
        ErrorAction  = 'Stop'
    }

    $command = Get-Command Connect-MgGraph -ErrorAction Stop

    if ($command.Parameters.ContainsKey('NoWelcome')) {
        $parameters.NoWelcome = $true
    }

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop

    if (-not (Test-GraphScopes -Context $context -RequiredScopes $Scopes)) {
        throw 'Graph connected, but the required delegated scopes were not granted.'
    }

    $test = Invoke-GraphGet -Uri 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName'

    if (-not $test -or -not $test.value) {
        throw 'Graph connected, but tenant validation failed.'
    }

    Write-OK "Graph connected"
}

function Get-TenantInfo {
    $org = Invoke-GraphGet -Uri 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName,verifiedDomains,onPremisesSyncEnabled'
    $tenant = @($org.value) | Select-Object -First 1

    $primaryDomain = ''

    if ($tenant -and $tenant.verifiedDomains) {
        $primary = @(
            $tenant.verifiedDomains |
            Where-Object { $_.isDefault -eq $true }
        ) | Select-Object -First 1

        if (-not $primary) {
            $primary = @($tenant.verifiedDomains) | Select-Object -First 1
        }

        if ($primary) {
            $primaryDomain = [string]$primary.name
        }
    }

    return [pscustomobject]@{
        Id                    = [string]$tenant.id
        DisplayName           = [string]$tenant.displayName
        PrimaryDomain         = $primaryDomain
        OnPremisesSyncEnabled = $tenant.onPremisesSyncEnabled
    }
}


function Get-NormalizedHash {
    param([object]$Value)

    $json = $Value | ConvertTo-Json -Depth 20 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {
        return ([System.BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '')
    }
    finally {
        $sha.Dispose()
    }
}

function Get-PrincipalName {
    param(
        [string]$PrincipalId,
        [hashtable]$Cache
    )

    if ($Cache.ContainsKey($PrincipalId)) {
        return $Cache[$PrincipalId]
    }

    $probe = Invoke-GraphGetSafe -Uri (
        'https://graph.microsoft.com/v1.0/directoryObjects/{0}' -f
        $PrincipalId
    )

    $name = $PrincipalId

    if ($probe.OK -and $probe.Data.displayName) {
        $name = [string]$probe.Data.displayName
    }

    $Cache[$PrincipalId] = $name
    return $name
}

function Get-CurrentSnapshot {
    $tenant = Get-TenantInfo
    $principalCache = @{}

    Write-Info "Reading privileged roles"
    $roles = @(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions?$select=id,displayName&$top=100')
    $roleMap = @{}

    foreach ($role in $roles) {
        $roleMap[[string]$role.id] = [string]$role.displayName
    }

    $active = @(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleAssignmentScheduleInstances?$select=principalId,roleDefinitionId,directoryScopeId,assignmentType,endDateTime&$top=100')
    $eligible = @(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/roleManagement/directory/roleEligibilityScheduleInstances?$select=principalId,roleDefinitionId,directoryScopeId,endDateTime&$top=100')

    $activeRows = @()

    foreach ($item in $active) {
        $roleName = $roleMap[[string]$item.roleDefinitionId]

        if (-not $roleName) {
            $roleName = [string]$item.roleDefinitionId
        }

        $principalName = Get-PrincipalName `
            -PrincipalId ([string]$item.principalId) `
            -Cache $principalCache

        $key = "{0}|{1}|{2}|{3}" -f
            [string]$item.roleDefinitionId,
            [string]$item.principalId,
            [string]$item.directoryScopeId,
            [string]$item.assignmentType

        $activeRows += [pscustomobject]@{
            Key         = $key
            DisplayName = ("{0} | {1}" -f $roleName, $principalName)
            Role        = $roleName
            Principal   = $principalName
            Scope       = [string]$item.directoryScopeId
            Assignment  = [string]$item.assignmentType
            EndDateTime = $item.endDateTime
        }
    }

    $eligibleRows = @()

    foreach ($item in $eligible) {
        $roleName = $roleMap[[string]$item.roleDefinitionId]

        if (-not $roleName) {
            $roleName = [string]$item.roleDefinitionId
        }

        $principalName = Get-PrincipalName `
            -PrincipalId ([string]$item.principalId) `
            -Cache $principalCache

        $key = "{0}|{1}|{2}" -f
            [string]$item.roleDefinitionId,
            [string]$item.principalId,
            [string]$item.directoryScopeId

        $eligibleRows += [pscustomobject]@{
            Key         = $key
            DisplayName = ("{0} | {1}" -f $roleName, $principalName)
            Role        = $roleName
            Principal   = $principalName
            Scope       = [string]$item.directoryScopeId
            EndDateTime = $item.endDateTime
        }
    }

    Write-Info "Reading Conditional Access"
    $policies = @(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies')
    $policyRows = @()

    foreach ($policy in $policies) {
        $fingerprintObject = [ordered]@{
            state           = $policy.state
            conditions      = $policy.conditions
            grantControls   = $policy.grantControls
            sessionControls = $policy.sessionControls
        }

        $policyRows += [pscustomobject]@{
            Key         = [string]$policy.id
            DisplayName = [string]$policy.displayName
            State       = [string]$policy.state
            Hash        = Get-NormalizedHash -Value $fingerprintObject
        }
    }

    Write-Info "Reading app registrations"
    $apps = @(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/applications?$select=id,appId,displayName,passwordCredentials,keyCredentials,createdDateTime&$top=999')
    $appRows = @()

    foreach ($app in $apps) {
        $credentialObject = [ordered]@{
            passwordCredentials = @(
                @($app.passwordCredentials) |
                Sort-Object keyId |
                ForEach-Object {
                    [ordered]@{
                        displayName   = $_.displayName
                        endDateTime   = $_.endDateTime
                        keyId         = $_.keyId
                    }
                }
            )
            keyCredentials = @(
                @($app.keyCredentials) |
                Sort-Object keyId |
                ForEach-Object {
                    [ordered]@{
                        displayName   = $_.displayName
                        endDateTime   = $_.endDateTime
                        keyId         = $_.keyId
                        type          = $_.type
                    }
                }
            )
        }

        $appRows += [pscustomobject]@{
            Key         = [string]$app.id
            AppId       = [string]$app.appId
            DisplayName = [string]$app.displayName
            Hash        = Get-NormalizedHash -Value $credentialObject
        }
    }

    Write-Info "Reading delegated OAuth grants"
    $servicePrincipals = @(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/servicePrincipals?$select=id,displayName&$top=999')
    $spNameMap = @{}

    foreach ($sp in $servicePrincipals) {
        $spNameMap[[string]$sp.id] = [string]$sp.displayName
    }

    $grants = @(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/oauth2PermissionGrants?$top=999')
    $grantRows = @()

    foreach ($grant in $grants) {
        $scope = ([string]$grant.scope).Trim()
        $clientName = [string]$spNameMap[[string]$grant.clientId]
        $resourceName = [string]$spNameMap[[string]$grant.resourceId]

        if (-not $clientName) {
            $clientName = 'Unresolved client'
        }

        if (-not $resourceName) {
            $resourceName = 'Unresolved resource'
        }

        $key = "{0}|{1}|{2}|{3}|{4}" -f
            [string]$grant.clientId,
            [string]$grant.resourceId,
            [string]$grant.principalId,
            [string]$grant.consentType,
            $scope

        $grantRows += [pscustomobject]@{
            Key         = $key
            DisplayName = ("{0} -> {1} | {2}" -f $clientName, $resourceName, $scope)
            ClientId    = [string]$grant.clientId
            ResourceId  = [string]$grant.resourceId
            PrincipalId = [string]$grant.principalId
            ConsentType = [string]$grant.consentType
            Scope       = $scope
        }
    }

    return [pscustomobject]@{
        Metadata = [pscustomobject]@{
            CapturedAt     = Get-Date
            TenantId       = $tenant.Id
            TenantName     = $tenant.DisplayName
            PrimaryDomain  = $tenant.PrimaryDomain
            SchemaVersion  = '1.0'
        }
        ActiveRoles              = @($activeRows | Sort-Object Key)
        EligibleRoles            = @($eligibleRows | Sort-Object Key)
        ConditionalAccess        = @($policyRows | Sort-Object Key)
        Applications             = @($appRows | Sort-Object Key)
        OAuth2PermissionGrants   = @($grantRows | Sort-Object Key)
    }
}

function Write-VerifiedBaseline {
    param(
        [object]$Snapshot,
        [string]$Path
    )

    $json=$Snapshot | ConvertTo-Json -Depth 30
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8 -ErrorAction Stop

    $check=Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

    if (
        -not $check.Metadata -or
        [string]$check.Metadata.TenantId -ne [string]$Snapshot.Metadata.TenantId
    ) {
        throw "Baseline verification failed after write."
    }

    return $check
}

function Compare-KeyedSection {
    param(
        [string]$Name,
        [object[]]$Baseline,
        [object[]]$Current,
        [string]$HashProperty
    )

    $baselineMap = @{}
    $currentMap = @{}

    foreach ($item in @($Baseline)) {
        $baselineMap[[string]$item.Key] = $item
    }

    foreach ($item in @($Current)) {
        $currentMap[[string]$item.Key] = $item
    }

    $added = @()
    $removed = @()
    $changed = @()

    foreach ($key in $currentMap.Keys) {
        if (-not $baselineMap.ContainsKey($key)) {
            $added += $currentMap[$key]
            continue
        }

        if ($HashProperty) {
            if (
                [string]$baselineMap[$key].$HashProperty -ne
                [string]$currentMap[$key].$HashProperty
            ) {
                $changed += $currentMap[$key]
            }
        }
    }

    foreach ($key in $baselineMap.Keys) {
        if (-not $currentMap.ContainsKey($key)) {
            $removed += $baselineMap[$key]
        }
    }

    return [pscustomobject]@{
        Name    = $Name
        Added   = @($added)
        Removed = @($removed)
        Changed = @($changed)
    }
}

function Write-ChangeSection {
    param([object]$Result)

    $total = $Result.Added.Count + $Result.Removed.Count + $Result.Changed.Count

    Write-Host ""
    Write-Host ("{0} ({1} change(s))" -f $Result.Name, $total)

    if ($total -eq 0) {
        Write-Host "No change"
        return
    }

    foreach ($item in $Result.Added) {
        $label = [string]$item.DisplayName

        if (-not $label) {
            $label = [string]$item.Key
        }

        Write-Host ("+ Added: {0}" -f $label)
    }

    foreach ($item in $Result.Removed) {
        $label = [string]$item.DisplayName

        if (-not $label) {
            $label = [string]$item.Key
        }

        Write-Host ("- Removed: {0}" -f $label)
    }

    foreach ($item in $Result.Changed) {
        $label = [string]$item.DisplayName

        if (-not $label) {
            $label = [string]$item.Key
        }

        Write-Host ("~ Changed: {0}" -f $label)
    }
}

try {
    Write-Host "TENANT DRIFT REVIEW"
    Write-Host "Shows high-value tenant changes since the last approved baseline."
    Write-Host ""

    $scopes = @(
        'Directory.Read.All',
        'Application.Read.All',
        'Policy.Read.All',
        'RoleAssignmentSchedule.Read.Directory',
        'RoleEligibilitySchedule.Read.Directory'
    )

    Connect-Graph -Scopes $scopes
    $tenant = Get-TenantInfo

    if (-not $BaselinePath) {
        $safeTenant = ($tenant.PrimaryDomain -replace '[^A-Za-z0-9._-]', '_')

        if (-not $safeTenant) {
            $safeTenant = ($tenant.DisplayName -replace '[^A-Za-z0-9._-]', '_')
        }

        $baselineFolder = Join-Path $PSScriptRoot 'BASELINES'

        if (-not (Test-Path -LiteralPath $baselineFolder)) {
            New-Item -Path $baselineFolder -ItemType Directory -Force | Out-Null
        }

        $BaselinePath = Join-Path $baselineFolder ("tenant-drift-{0}.json" -f $safeTenant)
    }

    Write-Host ""
    Write-Host "TENANT"
    Write-Host ("Name: {0}" -f $tenant.DisplayName)
    Write-Host ("Domain: {0}" -f $tenant.PrimaryDomain)
    Write-Host ("Baseline: {0}" -f $BaselinePath)

    $current = Get-CurrentSnapshot

    if ($CaptureBaseline -or -not (Test-Path -LiteralPath $BaselinePath)) {
        Write-Host ""

        if (-not $CaptureBaseline) {
            $answer = Read-Host "No baseline exists. Create it now? [Y/N]"

            if ($answer -notmatch '^(?i:y)') {
                Write-OK "No local baseline was written."
                Pause-End
                exit 0
            }
        }

        $null=Write-VerifiedBaseline -Snapshot $current -Path $BaselinePath

        Write-OK ("Baseline created and verified: {0}" -f $BaselinePath)
        Write-Host "No tenant changes were made."
        Pause-End
        exit 0
    }

    $baseline = Get-Content -LiteralPath $BaselinePath -Raw | ConvertFrom-Json

    if (
        $baseline.Metadata.TenantId -and
        [string]$baseline.Metadata.TenantId -ne [string]$current.Metadata.TenantId
    ) {
        throw 'The baseline belongs to a different Entra tenant.'
    }

    $results = @()
    $results += Compare-KeyedSection -Name 'ACTIVE ADMIN ACCESS' -Baseline @($baseline.ActiveRoles) -Current @($current.ActiveRoles) -HashProperty ''
    $results += Compare-KeyedSection -Name 'ELIGIBLE ADMIN ACCESS' -Baseline @($baseline.EligibleRoles) -Current @($current.EligibleRoles) -HashProperty ''
    $results += Compare-KeyedSection -Name 'CONDITIONAL ACCESS' -Baseline @($baseline.ConditionalAccess) -Current @($current.ConditionalAccess) -HashProperty 'Hash'
    $results += Compare-KeyedSection -Name 'APP REGISTRATIONS' -Baseline @($baseline.Applications) -Current @($current.Applications) -HashProperty 'Hash'
    $results += Compare-KeyedSection -Name 'OAUTH CONSENT GRANTS' -Baseline @($baseline.OAuth2PermissionGrants) -Current @($current.OAuth2PermissionGrants) -HashProperty ''

    $changeCount = 0

    foreach ($result in $results) {
        $changeCount += $result.Added.Count + $result.Removed.Count + $result.Changed.Count
        Write-ChangeSection -Result $result
    }

    Write-Host ""
    Write-Host "SUMMARY"
    Write-Host ("Changes detected: {0}" -f $changeCount)
    Write-Host ("Baseline captured: {0}" -f $baseline.Metadata.CapturedAt)
    Write-Host ("Current captured : {0}" -f $current.Metadata.CapturedAt)

    if ($changeCount -eq 0) {
        Write-OK "No tracked tenant drift detected."
    }
    else {
        Write-Warn "Tracked tenant drift detected."
        Write-Host "Action: Review the changes before replacing the baseline."
    }

    Write-Host ""
    $replace = Read-Host "Replace the baseline with the current approved state? [Y/N]"

    if ($replace -match '^(?i:y)') {
        $null=Write-VerifiedBaseline -Snapshot $current -Path $BaselinePath

        Write-OK "Baseline updated and verified."
    }
    else {
        Write-OK "Baseline unchanged."
    }

    Write-Host ""
    Write-Host ("Completed: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    Write-Host "READ-ONLY TENANT REVIEW. LOCAL BASELINE WRITE ONLY WHEN APPROVED."

    Pause-End
}
catch {
    Write-Host ""
    Write-Fail $_.Exception.Message
    Pause-End
}

