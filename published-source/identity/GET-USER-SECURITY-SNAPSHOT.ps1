# .VERSION 1.0.1
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

# Embedded into standalone report scripts by tools/reporting/build.ps1.
$script:FKReportLines = New-Object 'Collections.Generic.List[string]'
$script:FKReportWarnings = @()
$script:FKReportStartedUtc = [DateTime]::UtcNow.ToString('o')

function Write-FKReportLine {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Object,
        [object]$Separator=' ',[switch]$NoNewline,
        [ConsoleColor]$ForegroundColor,[ConsoleColor]$BackgroundColor
    )
    $line=($Object | ForEach-Object {[string]$_}) -join [string]$Separator
    $script:FKReportLines.Add($line)
    Write-Host @PSBoundParameters
}

function ConvertTo-FKDesktopReport {
    param([string]$Title,[string[]]$Lines,[string]$StartedUtc,[string]$ScopeNote)
    $encode={param($Text) [Net.WebUtility]::HtmlEncode([string]$Text)}
    $blocks=New-Object 'Collections.Generic.List[string]'
    $section=New-Object 'Collections.Generic.List[string]'
    foreach($line in @($Lines)) {
        if($line -match '^\s*[A-Z][A-Z /+&:()-]{2,}\s*$' -and $line.Trim().Length -lt 90) {
            if($section.Count) {$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>');$section.Clear()}
            $blocks.Add('<h2>'+(& $encode $line.Trim())+'</h2>')
        } else {$section.Add([string]$line)}
    }
    if($section.Count){$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>')}
    $safeTitle=& $encode $Title
    return @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"><title>$safeTitle</title>
<style>body{font:16px/1.55 system-ui,sans-serif;background:#f5f7f7;color:#172524;margin:0}main{max-width:1000px;margin:32px auto;padding:32px;background:white;border-top:4px solid #168779}header{border-bottom:1px solid #d1ddda;padding-bottom:20px}small{letter-spacing:.12em;color:#52716b}h1{font-size:28px;margin:12px 0}h2{font-size:15px;letter-spacing:.1em;color:#166b60;margin:28px 0 10px;border-bottom:1px solid #d1ddda;padding-bottom:8px}pre{font:14px/1.6 ui-monospace,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;margin:0}aside{background:#eef5f2;padding:12px 16px;margin:20px 0}footer{font-size:12px;color:#52716b;margin-top:32px}@media print{body{background:white}main{margin:0;padding:0;max-width:none}h2{break-after:avoid}pre{font-size:11px}}</style></head>
<body><main><header><small>F I E L D // K I T</small><h1>$safeTitle</h1><p>Collection started (UTC): $(& $encode $StartedUtc)</p></header><aside>$(& $encode $ScopeNote) Findings, unavailable checks, and displayed limits below are preserved from this run. Absence of a finding does not establish complete coverage.</aside>$($blocks.ToArray() -join "`n")<footer>Read-only report. No remote content or executable scripts. Review findings in context before taking action.</footer></main></body></html>
"@
}

function Save-FKDesktopReport {
    param([string]$Folder,[string]$Title,[string]$Content)
    if([string]::IsNullOrWhiteSpace($Folder) -or -not [IO.Directory]::Exists($Folder)){throw 'Report folder does not exist.'}
    $stem=($Title -replace '[^a-zA-Z0-9._-]','-').Trim('-')
    if(-not $stem){$stem='field-kit-report'}
    $stem=$stem.Substring(0,[Math]::Min(80,$stem.Length))
    $name=$stem+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.html'
    $path=Join-Path $Folder $name
    $bytes=(New-Object Text.UTF8Encoding($false)).GetBytes($Content)
    $stream=New-Object IO.FileStream($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
    $actual=[IO.File]::ReadAllBytes($path)
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        if([Convert]::ToBase64String($sha.ComputeHash($bytes)) -cne [Convert]::ToBase64String($sha.ComputeHash($actual))){throw 'Report readback did not match the collected content.'}
    }finally{$sha.Dispose()}
    return $path
}

function Offer-FKDesktopReport {
    param([string]$Title,[string]$ScopeNote='Scope matches the console output; only displayed rows are included.',[string]$DesktopFolder=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory))
    if(-not $script:FKReportLines.Count){return}
    try {
        if((Read-Host 'Save report to Desktop? [Y/N]').Trim() -notmatch '^(?i)y$'){return}
        $folder=$DesktopFolder
        $reportLines=@($script:FKReportLines.ToArray())
        if(@($script:FKReportWarnings).Count){$reportLines+=@('','SERVICE WARNINGS');$reportLines+=@($script:FKReportWarnings|ForEach-Object {[string]$_})}
        $content=ConvertTo-FKDesktopReport -Title $Title -Lines $reportLines -StartedUtc $script:FKReportStartedUtc -ScopeNote $ScopeNote
        try {$saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content}
        catch {
            Write-Host '[WARN] Desktop report could not be saved. Choose another existing folder or cancel.' -ForegroundColor Yellow
            $folder=(Read-Host 'Report folder (ENTER cancels)').Trim().Trim('"')
            if(-not $folder){return}
            $saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content
        }
        Write-Host ('[OK] Report saved and readback checked: '+$saved)
    }catch{Write-Host ('[WARN] Report export failed: '+$_.Exception.Message) -ForegroundColor Yellow}
}

function Write-OK   { param($m) Write-FKReportLine "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-FKReportLine "[INFO] $m" }
function Write-Warn { param($m) Write-FKReportLine "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-FKReportLine "[FAIL] $m" -ForegroundColor Red }

function Write-FieldKitFooter {
    Write-FKReportLine ""
    Write-FKReportLine "F I E L D  //  K I T"
    Write-FKReportLine ""
}

function Pause-End {
    Write-FieldKitFooter
    Write-Host ''
    Write-Host 'SESSION COMPLETE'
    Write-FKReportLine ""
    Write-FKReportLine 'Press Enter to close session.' -NoNewline

    try {
        do {
            $key = $Host.UI.RawUI.ReadKey(
                "NoEcho,IncludeKeyDown"
            )
        }
        until ($key.VirtualKeyCode -eq 13)

        Write-FKReportLine ""
    }
    catch {
        Write-FKReportLine ""
        Read-Host 'Press Enter to close session.' | Out-Null
    }
}

function Write-Section {
    param([string]$Title)

    Write-FKReportLine ""
    Write-FKReportLine $Title
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

    Write-FKReportLine "Graph: Connecting..."

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
    Write-FKReportLine 'Get User Security'
    Write-FKReportLine 'Shows the security state around one user before you decide what needs deeper review.'
    Write-FKReportLine "READ-ONLY. NO CHANGES MADE."
    Write-FKReportLine ""

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

    Write-FKReportLine ""
    Write-Section "USER"
    Write-FKReportLine (
        "User: {0} <{1}>" -f
        $user.displayName,
        $user.userPrincipalName
    )
    Write-FKReportLine ("Tenant: {0}" -f $tenant.DisplayName)
    Write-FKReportLine (
        "Status: {0}" -f
        $(if ($user.accountEnabled) { "Enabled" } else { "Disabled" })
    )
    Write-FKReportLine (
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

        Write-FKReportLine (
            "Password: Changed {0} ({1} days ago)" -f
            $changed.ToLocalTime().ToString("yyyy-MM-dd"),
            $age
        )
    }
    else {
        Write-FKReportLine "Password: Not available"
        $dataGaps += "Password last-changed data not available."
    }

    Write-FKReportLine ""
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
            Write-FKReportLine "Registered MFA: Yes"
            Write-FKReportLine ("Methods: {0}" -f ($mfaMethods -join "; "))
        }
        else {
            Write-FKReportLine "Registered MFA: No"
        }

        if ($recoveryMethods.Count -gt 0) {
            Write-FKReportLine ("Recovery: {0}" -f ($recoveryMethods -join "; "))
        }
    }
    catch {
        Write-FKReportLine "Status: Not available"
        $dataGaps += "Authentication methods: $(Get-ShortError $_)"
    }

    Write-FKReportLine ""
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
            Write-FKReportLine "Status: No"
        }
        else {
            Write-FKReportLine "Status: Yes"
            $roles | ForEach-Object { Write-FKReportLine ("Role: {0}" -f $_) }
        }
    }
    catch {
        Write-FKReportLine "Status: Not available"
        $dataGaps += "Privileged roles: $(Get-ShortError $_)"
    }

    Write-FKReportLine ""
    Write-Section "DIRECT GROUPS"

    try {
        $groups = @(
            Get-GraphPaged `
                -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)/memberOf/microsoft.graph.group?`$select=displayName"
        )

        if ($groups.Count -eq 0) {
            Write-FKReportLine "Status: No"
        }
        else {
            Write-FKReportLine ("Status: {0} group(s)" -f $groups.Count)

            foreach ($group in ($groups | Sort-Object displayName)) {
                Write-FKReportLine ("Group: {0}" -f $group.displayName)
            }
        }
    }
    catch {
        Write-FKReportLine "Status: Not available"
        $dataGaps += "Direct groups: $(Get-ShortError $_)"
    }

    Write-FKReportLine ""
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
            Write-FKReportLine "Status: No"
        }
        else {
            Write-FKReportLine ("Status: {0} assigned" -f $licenses.Count)

            foreach ($license in $licenses) {
                Write-FKReportLine ("License: {0}" -f $license)
            }
        }
    }
    catch {
        Write-FKReportLine "Status: Not available"
        $dataGaps += "Licenses: $(Get-ShortError $_)"
    }

    Write-FKReportLine ""
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
            Write-FKReportLine "Status: No"
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

            Write-FKReportLine (
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
                Write-FKReportLine $line
            }
        }
    }
    catch {
        Write-FKReportLine "Status: Not available"
        $dataGaps += "Sign-ins: $(Get-ShortError $_)"
    }

    Write-FKReportLine ""
    Write-Section "DATA GAPS"

    $uniqueDataGaps = @(
        $dataGaps |
        Select-Object -Unique
    )

    if ($uniqueDataGaps.Count -eq 0) {
        Write-FKReportLine "Status: No"
    }
    else {
        Write-FKReportLine "Status: Yes"
        $uniqueDataGaps |
            ForEach-Object { Write-FKReportLine ("- {0}" -f $_) }
    }

    Write-FKReportLine ""
    Write-OK "Complete. No changes made."

}
catch {
    Write-FKReportLine ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Offer-FKDesktopReport -Title 'GET-USER-SECURITY-SNAPSHOT'

    Pause-End
}