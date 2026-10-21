# .VERSION 1.0.2
#Requires -Version 5.1

<#
QUARTERLY CLEANUP REVIEW

OBJECTIVE
Review accounts, mailbox access, and licenses for cleanup.

REVIEWS
- Enabled Entra member accounts with recorded sign-in activity older than the threshold
- Enabled Entra member accounts where sign-in activity is unavailable
- Active Entra admin role membership counts
- Cloud-manageable Entra groups without owners
- Exchange Online mailboxes with EXTERNAL forwarding enabled

DEFAULT STALE THRESHOLD
90 days

SAFETY
Read-only.
No changes are made.
Optional Desktop HTML report; default is No.
Query failures are reported as data gaps and are never treated as clean results.
#>

param(
    [ValidateRange(1,3650)]
    [int]$StaleDays = 90,

    [string]$TenantDomain
)

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

function Write-FieldKitFooter {
    Write-FKReportLine ""
    Write-FKReportLine "F I E L D  //  K I T"
    Write-FKReportLine ""
}

function Write-OK   { param($m) Write-FKReportLine "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-FKReportLine "[INFO] $m" }
function Write-Warn { param($m) Write-FKReportLine "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-FKReportLine "[FAIL] $m" -ForegroundColor Red }

function Write-Section {
    param([string]$Title)

    Write-FKReportLine $Title
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

function Get-ShortError {
    param($ErrorRecord)

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Clean-Name {
    param([object]$Name)

    if ($null -eq $Name) {
        return ""
    }

    return (
        [string]$Name -replace
        '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$',
        ''
    ).Trim()
}

function Test-GuidString {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    return (
        $Value -match
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    )
}

function Ensure-Module {
    param(
        [string]$Name,
        [string]$Command
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        return
    }

    $module = Get-Module -ListAvailable -Name $Name |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install it first with: Install-Module $Name -Scope CurrentUser"
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

function Get-GraphTenantInfo {
    $response = Invoke-GraphGet `
        -Uri "https://graph.microsoft.com/v1.0/organization?`$select=displayName,verifiedDomains"

    $organization = @($response.value) | Select-Object -First 1

    if (-not $organization) {
        throw "Graph did not return organization details."
    }

    $defaultDomain = @(
        $organization.verifiedDomains |
        Where-Object { $_.isDefault -eq $true } |
        Select-Object -First 1
    )

    return [PSCustomObject]@{
        DisplayName   = [string]$organization.displayName
        DefaultDomain = if ($defaultDomain) {
            [string]$defaultDomain.name
        }
        else {
            ""
        }
        Domains = @(
            $organization.verifiedDomains |
            ForEach-Object { [string]$_.name } |
            Where-Object { $_ }
        )
    }
}

function Test-GraphScopes {
    param(
        [object]$Context,
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

function Connect-GraphAuto {
    param(
        [string[]]$Scopes,
        [string]$TargetDomain
    )

    Ensure-Module `
        -Name "Microsoft.Graph.Authentication" `
        -Command "Connect-MgGraph"

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-GraphScopes -Context $context -RequiredScopes $Scopes)
    ) {
        try {
            $tenant = Get-GraphTenantInfo

            if ($tenant.Domains -contains $TargetDomain) {
                Write-OK "Graph session reused"
                return $tenant
            }
        }
        catch {
        }
    }

    if ($context) {
        try {
            Disconnect-MgGraph `
                -ErrorAction SilentlyContinue |
                Out-Null
        }
        catch {
        }
    }

    Write-FKReportLine "Graph: Connecting..."

    $command = Get-Command `
        Connect-MgGraph `
        -ErrorAction Stop

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

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop

    if (
        -not (
            Test-GraphScopes `
                -Context $context `
                -RequiredScopes $Scopes
        )
    ) {
        throw "Graph token is missing one or more required scopes."
    }

    $tenant = Get-GraphTenantInfo

    if ($tenant.Domains -notcontains $TargetDomain) {
        throw (
            "Graph connected to a different tenant. " +
            "Expected domain: $TargetDomain"
        )
    }

    Write-OK "Graph connected"
    return $tenant
}

function Get-ActiveExchangeConnection {
    if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        return Get-ConnectionInformation -ErrorAction SilentlyContinue |
            Where-Object {
                $_.State -eq "Connected" -or
                $_.ConnectionStatus -eq "Connected"
            } |
            Select-Object -First 1
    }
    catch {
        return $null
    }
}

function Test-ExchangeRead {
    try {
        $null = Get-AcceptedDomain `
            -ResultSize 1 `
            -ErrorAction Stop

        return $true
    }
    catch {
        return $false
    }
}

function Test-ExchangeTenant {
    param([string]$TargetDomain)

    try {
        $domains = @(
            Get-AcceptedDomain `
                -ResultSize Unlimited `
                -ErrorAction Stop
        )

        return (
            @(
                $domains |
                Where-Object {
                    [string]$_.DomainName -eq $TargetDomain
                }
            ).Count -gt 0
        )
    }
    catch {
        return $false
    }
}

function Connect-ExchangeAuto {
    param([string]$TargetDomain)

    Ensure-Module `
        -Name "ExchangeOnlineManagement" `
        -Command "Connect-ExchangeOnline"

    if (
        (Get-ActiveExchangeConnection) -and
        (Test-ExchangeRead) -and
        (Test-ExchangeTenant -TargetDomain $TargetDomain)
    ) {
        Write-OK "Exchange session reused"
        return
    }

    Write-FKReportLine "Exchange Online: Connecting..."

    $command = Get-Command `
        Connect-ExchangeOnline `
        -ErrorAction Stop

    $parameters = @{
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ShowBanner")) {
        $parameters["ShowBanner"] = $false
    }

    if ($command.Parameters.ContainsKey("ShowProgress")) {
        $parameters["ShowProgress"] = $false
    }

    Connect-ExchangeOnline @parameters | Out-Null

    if (-not (Test-ExchangeRead)) {
        throw "Exchange connected, but read access could not be validated."
    }

    if (-not (Test-ExchangeTenant -TargetDomain $TargetDomain)) {
        throw (
            "Exchange connected to a different tenant. " +
            "Expected domain: $TargetDomain"
        )
    }

    Write-OK "Exchange connected"
}

function Get-StaleLoginReview {
    param([int]$Days)

    # Graph pages containing signInActivity are limited to 500 users.
    $users = @(
        Get-GraphPaged `
            -Uri (
                "https://graph.microsoft.com/v1.0/users?" +
                "`$select=userPrincipalName,accountEnabled,userType,signInActivity" +
                "&`$top=500"
            )
    )

    $enabledMembers = @(
        $users |
        Where-Object {
            $_.accountEnabled -eq $true -and
            $_.userType -ne "Guest"
        }
    )

    $stale = @()
    $unavailable = @()
    $now = Get-Date

    foreach ($user in $enabledMembers) {
        $upn = [string]$user.userPrincipalName

        if (
            $user.signInActivity -and
            $user.signInActivity.lastSignInDateTime
        ) {
            try {
                $last = [datetime]$user.signInActivity.lastSignInDateTime
                $age = [int]($now - $last).TotalDays

                if ($age -ge $Days) {
                    $stale += [PSCustomObject]@{
                        UPN        = $upn
                        LastSignIn = $last.ToLocalTime()
                        Days       = $age
                    }
                }
            }
            catch {
                $unavailable += [PSCustomObject]@{
                    UPN    = $upn
                    Reason = "Sign-in timestamp could not be parsed"
                }
            }
        }
        else {
            $unavailable += [PSCustomObject]@{
                UPN    = $upn
                Reason = "No Entra sign-in activity returned"
            }
        }
    }

    return [PSCustomObject]@{
        Reviewed    = $enabledMembers.Count
        Stale       = @($stale)
        Unavailable = @($unavailable)
    }
}

function Get-AdminRoleReview {
    $rows = @()
    $gaps = @()

    $roles = @(
        Get-GraphPaged `
            -Uri "https://graph.microsoft.com/v1.0/directoryRoles?`$select=id,displayName"
    )

    foreach ($role in $roles) {
        try {
            $members = @(
                Get-GraphPaged `
                    -Uri (
                        "https://graph.microsoft.com/v1.0/directoryRoles/" +
                        "$($role.id)/members?`$select=displayName,userPrincipalName"
                    )
            )

            if ($members.Count -gt 0) {
                $rows += [PSCustomObject]@{
                    Role  = Clean-Name $role.displayName
                    Count = $members.Count
                }
            }
        }
        catch {
            $gaps += (
                "Admin role member lookup failed for " +
                "$(Clean-Name $role.displayName): $(Get-ShortError $_)"
            )
        }
    }

    return [PSCustomObject]@{
        Rows = @($rows)
        Gaps = @($gaps)
    }
}

function Test-GraphOwnerReviewSupported {
    param($Group)

    if ($Group.onPremisesSyncEnabled -eq $true) {
        return $false
    }

    $groupTypes = @($Group.groupTypes)

    if ($groupTypes -contains "Unified") {
        return $true
    }

    if (
        $Group.securityEnabled -eq $true -and
        $Group.mailEnabled -ne $true
    ) {
        return $true
    }

    return $false
}

function Get-OwnerlessGroupReview {
    $ownerless = @()
    $gaps = @()
    $skipped = 0

    $groups = @(
        Get-GraphPaged `
            -Uri (
                "https://graph.microsoft.com/v1.0/groups?" +
                "`$select=id,displayName,groupTypes,mailEnabled,securityEnabled,onPremisesSyncEnabled" +
                "&`$top=999"
            )
    )

    foreach ($group in $groups) {
        if (-not (Test-GraphOwnerReviewSupported -Group $group)) {
            $skipped++
            continue
        }

        try {
            $owners = Invoke-GraphGet `
                -Uri (
                    "https://graph.microsoft.com/v1.0/groups/" +
                    "$($group.id)/owners?`$select=id,displayName,userPrincipalName&`$top=1"
                )

            if ($null -eq $owners -or $null -eq $owners.value) {
                throw "Graph returned an incomplete owner response."
            }

            if (@($owners.value).Count -eq 0) {
                $ownerless += Clean-Name $group.displayName
            }
        }
        catch {
            $gaps += (
                "Group owner lookup failed for " +
                "$(Clean-Name $group.displayName): $(Get-ShortError $_)"
            )
        }
    }

    return [PSCustomObject]@{
        Ownerless = @($ownerless | Sort-Object -Unique)
        Skipped   = $skipped
        Gaps      = @($gaps)
    }
}

function Get-FriendlyForwardingDestination {
    param(
        $Mailbox,
        [System.Collections.Generic.List[string]]$Gaps
    )

    if ($Mailbox.ForwardingSmtpAddress) {
        return (
            ([string]$Mailbox.ForwardingSmtpAddress) -replace
            '^(?i)smtp:',
            ''
        ).Trim()
    }

    if ($Mailbox.ForwardingAddress) {
        try {
            $recipient = Get-Recipient `
                -Identity $Mailbox.ForwardingAddress `
                -ErrorAction Stop -WarningVariable +script:FKReportWarnings

            if ($recipient.PrimarySmtpAddress) {
                return [string]$recipient.PrimarySmtpAddress
            }

            if (
                $recipient.PSObject.Properties.Name -contains
                "ExternalEmailAddress" -and
                $recipient.ExternalEmailAddress
            ) {
                return (
                    ([string]$recipient.ExternalEmailAddress) -replace
                    '^(?i)smtp:',
                    ''
                ).Trim()
            }

            return [string]$recipient.DisplayName
        }
        catch {
            $Gaps.Add(
                "Forwarding destination could not be resolved for " +
                ([string]$Mailbox.UserPrincipalName)
            )

            return [string]$Mailbox.ForwardingAddress
        }
    }

    return ""
}

function Get-MailboxForwardingReview {
    $gaps = New-Object System.Collections.Generic.List[string]
    $rows = @()

    try {
        $acceptedDomains = @(
            Get-AcceptedDomain `
                -ResultSize Unlimited `
                -ErrorAction Stop
        )

        $internalDomains = @(
            $acceptedDomains |
            ForEach-Object {
                ([string]$_.DomainName).Trim().ToLowerInvariant()
            } |
            Where-Object { $_ } |
            Sort-Object -Unique
        )
    }
    catch {
        throw (
            "Accepted-domain enumeration failed: " +
            (Get-ShortError $_)
        )
    }

    try {
        $mailboxes = @(
            Get-Mailbox `
                -ResultSize Unlimited `
                -ErrorAction Stop -WarningVariable +script:FKReportWarnings
        )
    }
    catch {
        throw (
            "Mailbox enumeration failed: " +
            (Get-ShortError $_)
        )
    }

    foreach ($mailbox in $mailboxes) {
        if (
            -not $mailbox.ForwardingSmtpAddress -and
            -not $mailbox.ForwardingAddress
        ) {
            continue
        }

        $destination = Get-FriendlyForwardingDestination `
            -Mailbox $mailbox `
            -Gaps $gaps

        if ([string]::IsNullOrWhiteSpace($destination)) {
            $gaps.Add(
                "Forwarding destination was empty for " +
                ([string]$mailbox.UserPrincipalName)
            )
            continue
        }

        $external = $false
        $destinationDomain = ""

        if (
            $destination -match
            '(?i)([A-Z0-9._%+\-]+@([A-Z0-9.\-]+\.[A-Z]{2,}))'
        ) {
            $destination = $Matches[1]
            $destinationDomain = $Matches[2].ToLowerInvariant()

            if ($internalDomains -notcontains $destinationDomain) {
                $external = $true
            }
        }
        else {
            $gaps.Add(
                "Forwarding destination could not be classified as internal/external for " +
                ([string]$mailbox.UserPrincipalName) +
                ": " +
                $destination
            )
            continue
        }

        if (-not $external) {
            continue
        }

        $upn = [string]$mailbox.UserPrincipalName

        if ([string]::IsNullOrWhiteSpace($upn)) {
            $upn = [string]$mailbox.PrimarySmtpAddress
        }

        $rows += [PSCustomObject]@{
            UPN               = $upn
            Destination       = $destination
            DeliverAndForward = [bool]$mailbox.DeliverToMailboxAndForward
        }
    }

    return [PSCustomObject]@{
        Rows = @($rows)
        Gaps = @($gaps)
    }
}

try {
    Write-FKReportLine 'Review Account Cleanup'
    Write-FKReportLine 'Review accounts, mailbox access, and licenses for cleanup.'
    Write-FKReportLine "READ-ONLY. NO CHANGES MADE."
    Write-FKReportLine ""

    if ([string]::IsNullOrWhiteSpace($TenantDomain)) {
        $TenantDomain = (Read-Host "Tenant domain").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($TenantDomain)) {
        throw "Tenant domain is required."
    }

    $TenantDomain = $TenantDomain.ToLowerInvariant()

    $dataGaps = New-Object System.Collections.Generic.List[string]
    $graphAvailable = $false
    $exchangeAvailable = $false
    $tenant = $null

    try {
        $tenant = Connect-GraphAuto `
            -Scopes @(
                "User.Read.All",
                "Directory.Read.All",
                "AuditLog.Read.All",
                "Group.Read.All"
            ) `
            -TargetDomain $TenantDomain

        $graphAvailable = $true
    }
    catch {
        Write-Warn "Graph review unavailable"
        $dataGaps.Add(
            "Graph: $(Get-ShortError $_)"
        )
    }

    try {
        Connect-ExchangeAuto `
            -TargetDomain $TenantDomain

        $exchangeAvailable = $true
    }
    catch {
        Write-Warn "Exchange review unavailable"
        $dataGaps.Add(
            "Exchange: $(Get-ShortError $_)"
        )
    }

    Write-FKReportLine ""
    Write-Section "TENANT"

    if ($tenant) {
        Write-FKReportLine ("Name: {0}" -f $tenant.DisplayName)
    }
    else {
        Write-FKReportLine "Name: Not available"
    }

    Write-FKReportLine ("Domain: {0}" -f $TenantDomain)
    Write-FKReportLine ("Stale Threshold: {0} days" -f $StaleDays)

    $staleReview = $null
    $adminReview = $null
    $ownerReview = $null
    $forwardingReview = $null

    Write-FKReportLine ""
    Write-Section "STALE ENABLED USERS"

    if ($graphAvailable) {
        try {
            $staleReview = Get-StaleLoginReview `
                -Days $StaleDays

            if ($staleReview.Stale.Count -eq 0) {
                Write-FKReportLine "Status: No"
            }
            else {
                Write-FKReportLine (
                    "Status: Yes | {0} user(s)" -f
                    $staleReview.Stale.Count
                )

                foreach (
                    $row in
                    ($staleReview.Stale |
                        Sort-Object Days -Descending)
                ) {
                    Write-FKReportLine (
                        "{0} | Last Sign-In: {1} | Age: {2} days" -f
                        $row.UPN,
                        $row.LastSignIn.ToString("yyyy-MM-dd"),
                        $row.Days
                    )
                }
            }
        }
        catch {
            Write-FKReportLine "Status: Not available"
            $dataGaps.Add(
                "Stale users: $(Get-ShortError $_)"
            )
        }
    }
    else {
        Write-FKReportLine "Status: Not available"
    }

    Write-FKReportLine ""
    Write-Section "ACTIVITY NOT AVAILABLE"

    if ($staleReview) {
        if ($staleReview.Unavailable.Count -eq 0) {
            Write-FKReportLine "Status: No"
        }
        else {
            Write-FKReportLine (
                "Status: Yes | {0} user(s)" -f
                $staleReview.Unavailable.Count
            )

            foreach (
                $row in
                ($staleReview.Unavailable |
                    Sort-Object UPN)
            ) {
                Write-FKReportLine (
                    "{0} | {1}" -f
                    $row.UPN,
                    $row.Reason
                )
            }
        }
    }
    else {
        Write-FKReportLine "Status: Not available"
    }

    Write-FKReportLine ""
    Write-Section "ADMIN ROLES"

    if ($graphAvailable) {
        try {
            $adminReview = Get-AdminRoleReview

            if ($adminReview.Rows.Count -eq 0) {
                if ($adminReview.Gaps.Count -gt 0) { Write-FKReportLine "Status: Not available" }
                else { Write-FKReportLine "Status: No" }
            }
            else {
                Write-FKReportLine (
                    "Status: {0} active role(s)" -f
                    $adminReview.Rows.Count
                )

                foreach (
                    $row in
                    ($adminReview.Rows |
                        Sort-Object Role)
                ) {
                    Write-FKReportLine (
                        "Role: {0} | Members: {1}" -f
                        $row.Role,
                        $row.Count
                    )
                }
            }

            foreach ($gap in $adminReview.Gaps) {
                $dataGaps.Add($gap)
            }
        }
        catch {
            Write-FKReportLine "Status: Not available"
            $dataGaps.Add(
                "Admin roles: $(Get-ShortError $_)"
            )
        }
    }
    else {
        Write-FKReportLine "Status: Not available"
    }

    Write-FKReportLine ""
    Write-Section "OWNERLESS ENTRA GROUPS"

    if ($graphAvailable) {
        try {
            $ownerReview = Get-OwnerlessGroupReview

            if ($ownerReview.Ownerless.Count -eq 0) {
                Write-FKReportLine "Status: No"
            }
            else {
                Write-FKReportLine (
                    "Status: Yes | {0} group(s)" -f
                    $ownerReview.Ownerless.Count
                )

                foreach ($name in $ownerReview.Ownerless) {
                    Write-FKReportLine $name
                }
            }

            foreach ($gap in $ownerReview.Gaps) {
                $dataGaps.Add($gap)
            }
        }
        catch {
            Write-FKReportLine "Status: Not available"
            $dataGaps.Add(
                "Ownerless groups: $(Get-ShortError $_)"
            )
        }
    }
    else {
        Write-FKReportLine "Status: Not available"
    }

    Write-FKReportLine ""
    Write-Section "EXTERNAL MAILBOX FORWARDING"

    if ($exchangeAvailable) {
        try {
            $forwardingReview = Get-MailboxForwardingReview

            if ($forwardingReview.Rows.Count -eq 0) {
                Write-FKReportLine "Status: No"
            }
            else {
                Write-FKReportLine (
                    "Status: Yes | {0} mailbox(es)" -f
                    $forwardingReview.Rows.Count
                )

                foreach (
                    $row in
                    ($forwardingReview.Rows |
                        Sort-Object UPN)
                ) {
                    $copy = if ($row.DeliverAndForward) {
                        "Yes"
                    }
                    else {
                        "No"
                    }

                    Write-FKReportLine (
                        "{0} -> {1} | Deliver Copy: {2}" -f
                        $row.UPN,
                        $row.Destination,
                        $copy
                    )
                }
            }

            foreach ($gap in $forwardingReview.Gaps) {
                $dataGaps.Add($gap)
            }
        }
        catch {
            Write-FKReportLine "Status: Not available"
            $dataGaps.Add(
                "External forwarding: $(Get-ShortError $_)"
            )
        }
    }
    else {
        Write-FKReportLine "Status: Not available"
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

        foreach ($gap in $uniqueDataGaps) {
            Write-FKReportLine ("- {0}" -f $gap)
        }
    }

    Write-FKReportLine ""
    Write-OK "Complete. No changes made."

}
catch {
    Write-FKReportLine ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Offer-FKDesktopReport -Title 'GET-QUARTERLY-CLEANUP-REVIEW'

    Pause-End
}
