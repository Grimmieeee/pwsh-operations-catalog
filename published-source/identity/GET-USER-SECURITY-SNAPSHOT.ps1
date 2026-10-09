<#
GET USER SECURITY SNAPSHOT

OBJECTIVE
Provide a fast, read-only security and identity snapshot for one Microsoft 365 user.

INPUT
One UPN.

CHANGES
Read-only. No changes are made.
#>

param([string]$UPN)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function Write-OK   { param($m) Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "[INFO] $m" }
function Write-Warn { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "[FAIL] $m" -ForegroundColor Red }

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function Pause-End {
    Write-FieldKitFooter
    Write-Host ""
    Write-Host "Press Enter to EXIT" -NoNewline

    try {
        do {
            $key = $Host.UI.RawUI.ReadKey(
                "NoEcho,IncludeKeyDown"
            )
        }
        until ($key.VirtualKeyCode -eq 13)

        Write-Host ""
    }
    catch {
        Write-Host ""
        Read-Host "Press Enter to EXIT" | Out-Null
    }
}

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host $Title
}

function Get-ShortError {
    param($ErrorRecord)

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Ensure-Module {
    param(
        [string]$Name,
        [string]$Command
    )

    $module=Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Name loaded, but $Command is unavailable."
    }
}

function Invoke-GraphGet {
    param([string]$Uri)

    $command = Get-Command Invoke-MgGraphRequest -ErrorAction Stop
    $parameters = @{
        Method      = "GET"
        Uri         = $Uri
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("OutputType")) {
        $parameters["OutputType"] = "PSObject"
    }

    return Invoke-MgGraphRequest @parameters
}

function Get-GraphTenantInfo {
    try {
        $response = Invoke-GraphGet `
            -Uri "https://graph.microsoft.com/v1.0/organization?`$select=displayName,verifiedDomains"

        $organization = @($response.value) | Select-Object -First 1

        if (-not $organization) {
            return $null
        }

        return [PSCustomObject]@{
            DisplayName = [string]$organization.displayName
            Domains = @(
                $organization.verifiedDomains |
                ForEach-Object { [string]$_.name } |
                Where-Object { $_ }
            )
        }
    }
    catch {
        return $null
    }
}

function Test-GraphScopes {
    param(
        $Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) {
        return $false
    }

    foreach ($scope in $RequiredScopes) {
        if (@($Context.Scopes) -notcontains $scope) {
            return $false
        }
    }

    return $true
}

function Test-GraphTarget {
    param([string]$UPN)

    try {
        $encoded = [System.Uri]::EscapeDataString($UPN)

        Invoke-GraphGet `
            -Uri ("https://graph.microsoft.com/v1.0/users/{0}?`$select=id" -f $encoded) |
            Out-Null

        return $true
    }
    catch {
        return $false
    }
}

function Connect-GraphAuto {
    param(
        [string[]]$Scopes,
        [string]$TargetDomain,
        [string]$ValidationUPN
    )

    Ensure-Module `
        -Name "Microsoft.Graph.Authentication" `
        -Command "Connect-MgGraph"

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-GraphScopes -Context $context -RequiredScopes $Scopes) -and
        (Test-GraphTarget -UPN $ValidationUPN)
    ) {
        $tenant = Get-GraphTenantInfo

        if (
            $tenant -and
            (
                [string]::IsNullOrWhiteSpace($TargetDomain) -or
                $tenant.Domains -contains $TargetDomain
            )
        ) {
            Write-OK "Graph session reused"
            return $tenant
        }
    }

    if ($context) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
        }
    }

    Write-Host "Graph: Connecting..."

    $command = Get-Command Connect-MgGraph -ErrorAction Stop
    $parameters = @{
        Scopes      = $Scopes
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ContextScope")) {
        $parameters["ContextScope"] = "Process"
    }

    if ($command.Parameters.ContainsKey("NoWelcome")) {
        $parameters["NoWelcome"] = $true
    }

    if (
        -not [string]::IsNullOrWhiteSpace($TargetDomain) -and
        $command.Parameters.ContainsKey("TenantId")
    ) {
        $parameters["TenantId"] = $TargetDomain
    }

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop

    if (-not (Test-GraphScopes -Context $context -RequiredScopes $Scopes)) {
        throw "The Graph token is missing one or more required delegated scopes."
    }

    if (-not (Test-GraphTarget -UPN $ValidationUPN)) {
        throw "The target user did not resolve in the connected Graph tenant."
    }

    $tenant = Get-GraphTenantInfo

    if (-not $tenant) {
        throw "Graph connected, but tenant details could not be verified."
    }

    if (
        -not [string]::IsNullOrWhiteSpace($TargetDomain) -and
        $tenant.Domains -notcontains $TargetDomain
    ) {
        throw "Graph connected to the wrong tenant for domain $TargetDomain."
    }

    Write-OK "Graph connected"
    return $tenant
}

function Get-GraphUser {
    param([string]$UPN)

    $encoded = [System.Uri]::EscapeDataString($UPN)

    $uri = (
        (
            "https://graph.microsoft.com/v1.0/users/{0}" +
            "?`$select=id,displayName,userPrincipalName,accountEnabled,mail," +
            "mobilePhone,businessPhones,onPremisesSyncEnabled,onPremisesSamAccountName," +
            "lastPasswordChangeDateTime,userType"
        ) -f $encoded
    )

    return Invoke-GraphGet -Uri $uri
}

function Get-GraphPaged {
    param(
        [string]$Uri,
        [int]$MaxPages = 200
    )

    $items = @()
    $next = $Uri
    $pageCount = 0

    while ($next) {
        if ($pageCount -ge $MaxPages) {
            throw (
                "Graph pagination exceeded the safety limit of {0} pages. " +
                "Incomplete results were not accepted."
            ) -f $MaxPages
        }

        $page = Invoke-GraphGet -Uri $next

        if (
            $null -eq $page -or
            $page.PSObject.Properties.Name -notcontains "value"
        ) {
            throw "Graph returned an unexpected paged response. Incomplete results were not accepted."
        }

        $items += @(
            $page.value |
            Where-Object { $null -ne $_ }
        )

        $pageCount++
        $next = [string]$page.'@odata.nextLink'
    }

    return @($items)
}

function Get-AuthenticationMethodInfo {
    param($Method)

    $type = [string]$Method.'@odata.type'

    if ($type -match "microsoftAuthenticator") {
        return [PSCustomObject]@{
            Category = "MFA"
            Label    = "Microsoft Authenticator"
        }
    }

    if ($type -match "phoneAuthentication") {
        $phone = [string]$Method.phoneNumber

        return [PSCustomObject]@{
            Category = "MFA"
            Label    = if ($phone) { "Phone: $phone" } else { "Phone" }
        }
    }

    if ($type -match "fido2") {
        return [PSCustomObject]@{
            Category = "MFA"
            Label    = "FIDO2 security key / passkey"
        }
    }

    if ($type -match "softwareOath") {
        return [PSCustomObject]@{
            Category = "MFA"
            Label    = "Software OATH"
        }
    }

    if ($type -match "windowsHello") {
        return [PSCustomObject]@{
            Category = "MFA"
            Label    = "Windows Hello for Business"
        }
    }

    if ($type -match "platformCredential") {
        return [PSCustomObject]@{
            Category = "MFA"
            Label    = "Platform credential / passkey"
        }
    }

    if ($type -match "emailAuthentication") {
        $email = [string]$Method.emailAddress

        return [PSCustomObject]@{
            Category = "Recovery"
            Label    = if ($email) { "Recovery email: $email" } else { "Recovery email" }
        }
    }

    if ($type -match "temporaryAccessPass") {
        return [PSCustomObject]@{
            Category = "Recovery"
            Label    = "Temporary Access Pass"
        }
    }

    if ($type -match "passwordAuthentication") {
        return [PSCustomObject]@{
            Category = "Baseline"
            Label    = "Password"
        }
    }

    if ($type) {
        return [PSCustomObject]@{
            Category = "Other"
            Label    = "Other authentication method"
        }
    }

    return $null
}

function Get-SignInResult {
    param($SignIn)

    if ($null -eq $SignIn) {
        return "Unknown"
    }

    if ($SignIn.status.errorCode -eq 0) {
        return "Success"
    }

    return "Failed"
}

try {
    Write-Host "USER SNAPSHOT"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        $UPN = (Read-Host "UPN").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        throw "UPN is required."
    }

    $targetDomain = ($UPN -split "@", 2)[1].ToLowerInvariant()

    $tenant = Connect-GraphAuto `
        -Scopes @(
            "User.Read.All",
            "Directory.Read.All",
            "UserAuthenticationMethod.Read.All",
            "AuditLog.Read.All"
        ) `
        -TargetDomain $targetDomain `
        -ValidationUPN $UPN

    $user = Get-GraphUser -UPN $UPN
    $dataGaps = @()

    Write-Host ""
    Write-Section "USER"
    Write-Host (
        "User: {0} <{1}>" -f
        $user.displayName,
        $user.userPrincipalName
    )
    Write-Host ("Tenant: {0}" -f $tenant.DisplayName)
    Write-Host (
        "Status: {0}" -f
        $(if ($user.accountEnabled) { "Enabled" } else { "Disabled" })
    )
    Write-Host (
        "Source: {0}" -f
        $(if ($user.onPremisesSyncEnabled -eq $true) {
            "Active Directory"
        }
        elseif ($user.onPremisesSyncEnabled -eq $false) {
            "Entra ID"
        }
        else {
            "Unknown"
        })
    )

    if ($user.lastPasswordChangeDateTime) {
        $changed = [datetime]$user.lastPasswordChangeDateTime
        $age = [int]((Get-Date) - $changed).TotalDays

        Write-Host (
            "Password: Changed {0} ({1} days ago)" -f
            $changed.ToLocalTime().ToString("yyyy-MM-dd"),
            $age
        )
    }
    else {
        Write-Host "Password: Not available"
        $dataGaps += "Password last-changed data not available."
    }

    Write-Host ""
    Write-Section "AUTHENTICATION"

    try {
        $methodsResponse = Invoke-GraphGet `
            -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)/authentication/methods"

        $methodInfo = @(
            $methodsResponse.value |
            ForEach-Object { Get-AuthenticationMethodInfo $_ } |
            Where-Object { $_ }
        )

        $mfaMethods = @(
            $methodInfo |
            Where-Object { $_.Category -eq "MFA" } |
            ForEach-Object { [string]$_.Label } |
            Where-Object { $_ } |
            Sort-Object -Unique
        )

        $recoveryMethods = @(
            $methodInfo |
            Where-Object { $_.Category -eq "Recovery" } |
            ForEach-Object { [string]$_.Label } |
            Where-Object { $_ } |
            Sort-Object -Unique
        )

        if ($mfaMethods.Count -gt 0) {
            Write-Host "Registered MFA: Yes"
            Write-Host ("Methods: {0}" -f ($mfaMethods -join "; "))
        }
        else {
            Write-Host "Registered MFA: No"
        }

        if ($recoveryMethods.Count -gt 0) {
            Write-Host ("Recovery: {0}" -f ($recoveryMethods -join "; "))
        }
    }
    catch {
        Write-Host "Status: Not available"
        $dataGaps += "Authentication methods: $(Get-ShortError $_)"
    }

    Write-Host ""
    Write-Section "PRIVILEGED ROLES"

    try {
        $memberships = @(
            Get-GraphPaged `
                -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)/transitiveMemberOf?`$select=displayName,roleTemplateId"
        )

        $roles = @(
            $memberships |
            Where-Object {
                $_.'@odata.type' -eq "#microsoft.graph.directoryRole" -or
                $_.roleTemplateId
            } |
            ForEach-Object { [string]$_.displayName } |
            Where-Object { $_ } |
            Sort-Object -Unique
        )

        if ($roles.Count -eq 0) {
            Write-Host "Status: No"
        }
        else {
            Write-Host "Status: Yes"
            $roles | ForEach-Object { Write-Host ("Role: {0}" -f $_) }
        }
    }
    catch {
        Write-Host "Status: Not available"
        $dataGaps += "Privileged roles: $(Get-ShortError $_)"
    }

    Write-Host ""
    Write-Section "DIRECT GROUPS"

    try {
        $groups = @(
            Get-GraphPaged `
                -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)/memberOf/microsoft.graph.group?`$select=displayName"
        )

        if ($groups.Count -eq 0) {
            Write-Host "Status: No"
        }
        else {
            Write-Host ("Status: {0} group(s)" -f $groups.Count)

            foreach ($group in ($groups | Sort-Object displayName)) {
                Write-Host ("Group: {0}" -f $group.displayName)
            }
        }
    }
    catch {
        Write-Host "Status: Not available"
        $dataGaps += "Direct groups: $(Get-ShortError $_)"
    }

    Write-Host ""
    Write-Section "LICENSES"

    try {
        $licenseResponse = Invoke-GraphGet `
            -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)/licenseDetails?`$select=skuPartNumber"

        $licenses = @(
            $licenseResponse.value |
            ForEach-Object { [string]$_.skuPartNumber } |
            Where-Object { $_ } |
            Sort-Object -Unique
        )

        if ($licenses.Count -eq 0) {
            Write-Host "Status: No"
        }
        else {
            Write-Host ("Status: {0} assigned" -f $licenses.Count)

            foreach ($license in $licenses) {
                Write-Host ("License: {0}" -f $license)
            }
        }
    }
    catch {
        Write-Host "Status: Not available"
        $dataGaps += "Licenses: $(Get-ShortError $_)"
    }

    Write-Host ""
    Write-Section "SIGN-INS 48H"

    try {
        $since = (Get-Date).AddHours(-48).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $until = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        $userId = [string]$user.id

        if ([string]::IsNullOrWhiteSpace($userId)) {
            throw "Target user object ID was not available for the sign-in query."
        }

        $filterText = (
            "userId eq '{0}' and createdDateTime ge {1} and createdDateTime le {2}" -f
            $userId,
            $since,
            $until
        )

        $filter = [System.Uri]::EscapeDataString($filterText)
        $uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$top=50&`$filter=$filter"

        $page = Invoke-GraphGet -Uri $uri

        if (
            $null -eq $page -or
            $page.PSObject.Properties.Name -notcontains "value"
        ) {
            throw "Graph returned an unexpected sign-in response."
        }

        $signIns = @(
            $page.value |
            Where-Object { $null -ne $_ }
        )

        $truncated = -not [string]::IsNullOrWhiteSpace(
            [string]$page.'@odata.nextLink'
        )

        if ($truncated) {
            $dataGaps += "Sign-ins: More than 50 records were returned in the 48-hour window. Output is intentionally capped."
        }

        if ($signIns.Count -eq 0) {
            Write-Host "Status: No"
        }
        else {
            $successCount = @(
                $signIns |
                Where-Object { $_.status.errorCode -eq 0 }
            ).Count

            $failedCount = @(
                $signIns |
                Where-Object { $_.status.errorCode -ne 0 }
            ).Count

            $totalText = if ($truncated) {
                "$($signIns.Count)+"
            }
            else {
                [string]$signIns.Count
            }

            Write-Host (
                "Status: {0} total | {1} success | {2} failed" -f
                $totalText,
                $successCount,
                $failedCount
            )

            $seenIps = @{}
            $recentIpRows = New-Object System.Collections.Generic.List[object]

            foreach (
                $signIn in
                ($signIns | Sort-Object createdDateTime -Descending)
            ) {
                if (-not $signIn.createdDateTime) {
                    continue
                }

                $ip = [string]$signIn.ipAddress

                if ([string]::IsNullOrWhiteSpace($ip)) {
                    $ip = "IP unavailable"
                }

                if ($seenIps.ContainsKey($ip)) {
                    continue
                }

                $seenIps[$ip] = $true

                $country = [string]$signIn.location.countryOrRegion

                $recentIpRows.Add(
                    [PSCustomObject]@{
                        IP       = $ip
                        LastSeen = $signIn.createdDateTime
                        Country  = $country
                        Result   = Get-SignInResult $signIn
                    }
                )

                if ($recentIpRows.Count -ge 5) {
                    break
                }
            }

            foreach ($row in $recentIpRows) {
                $lastSeen = (
                    [datetime]$row.LastSeen
                ).ToLocalTime().ToString("yyyy-MM-dd HH:mm")

                $line = "IP: $($row.IP) | Last Seen: $lastSeen"

                if (-not [string]::IsNullOrWhiteSpace($row.Country)) {
                    $line = "$line | Country: $($row.Country)"
                }

                $line = "$line | Result: $($row.Result)"
                Write-Host $line
            }
        }
    }
    catch {
        Write-Host "Status: Not available"
        $dataGaps += "Sign-ins: $(Get-ShortError $_)"
    }

    Write-Host ""
    Write-Section "DATA GAPS"

    $uniqueDataGaps = @(
        $dataGaps |
        Select-Object -Unique
    )

    if ($uniqueDataGaps.Count -eq 0) {
        Write-Host "Status: No"
    }
    else {
        Write-Host "Status: Yes"
        $uniqueDataGaps |
            ForEach-Object { Write-Host ("- {0}" -f $_) }
    }

    Write-Host ""
    Write-OK "Complete. No changes made."

}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}