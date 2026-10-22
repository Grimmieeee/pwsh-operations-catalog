<#PSScriptInfo
.VERSION 1.0.3
.GUID d77fb13d-5860-46ad-bc7e-2ef0df3a458d
.AUTHOR FIELD // KIT
.DESCRIPTION Check recovery readiness and restore approved account access.
#>
<#
.SYNOPSIS
BEC: Restore and Validate
.DESCRIPTION
Step 3 follows containment and persistence review. Uses the same PowerShell window,
validated connections, and target details. Fresh checks run before any restore.
User identity, password remediation, scope review, and MFA protection require operator confirmation.
No password reset, persistence deletion, automatic sync, module install, or export.
Synced accounts restore in SID-matched AD first, then Entra. Pending sync remains unverified.
#>
[CmdletBinding()]
param([string]$UPN, [string]$Tenant, [switch]$NoPause,
    [ValidateRange(0,2000)][int]$OutputDelayMs = 200)
$ErrorActionPreference = 'Stop'

# Pace completed lines; status prefixes stay attached to their messages.
function Write-IRLine {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromRemainingArguments=$true)][AllowNull()][object]$Object,
        [switch]$NoNewline,
        [object]$Separator,
        [ConsoleColor]$ForegroundColor,
        [ConsoleColor]$BackgroundColor
    )
    Microsoft.PowerShell.Utility\Write-Host @PSBoundParameters
    if (-not $NoNewline -and -not $NoPause -and $OutputDelayMs -gt 0) {
        Start-Sleep -Milliseconds $OutputDelayMs
    }
}




$SkipExchange=$false
$script:DataGaps=New-Object System.Collections.ArrayList
$script:ActionLog=New-Object System.Collections.ArrayList
$script:Phase='Recovery'
$script:ApprovedRecoveryFindings=''
$script:PendingRecoveryFindings=''
$script:RecoverySucceeded=$false
$script:OriginalTitle=$null
$script:AdChanged=$false
$script:SyncResult='Not required'
$script:ExpectedTenantId=''; $script:ExpectedUserId=''; $script:ExpectedUpn=''
$script:ExpectedSid=''; $script:ExpectedSynced=$false

# Shared workflow functions are embedded so each script remains standalone.
function Get-IRWorkflowScopes {
    return @('User.Read.All','Directory.Read.All','UserAuthenticationMethod.Read.All',
        'AuditLog.Read.All','Policy.Read.All','User.RevokeSessions.All',
        'User.EnableDisableAccount.All','User-PasswordProfile.ReadWrite.All',
        'DelegatedPermissionGrant.ReadWrite.All')
}

function Test-IRWorkflowTenant {
    param($Context, [string]$ExpectedTenant)
    if (-not $Context -or $Context.AuthType -ne 'Delegated' -or
        $Context.Environment -ne 'Global' -or $Context.ContextScope -ne 'Process') { return $false }
    $guid = [guid]::Empty
    if ([guid]::TryParse($ExpectedTenant, [ref]$guid)) {
        return [string]$Context.TenantId -eq $guid.ToString()
    }
    $domains = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/domains?$select=id,isVerified' -OutputType PSObject -ErrorAction Stop
    return @($domains.value | Where-Object { $_.isVerified -and $_.id -ieq $ExpectedTenant }).Count -eq 1
}

function Connect-IRWorkflowGraph {
    param([string]$ExpectedTenant)
    $scopes = @(Get-IRWorkflowScopes)
    $context = Get-MgContext -ErrorAction Stop
    $missing = @($scopes | Where-Object { @($context.Scopes) -notcontains $_ })
    $reuse = $context -and $missing.Count -eq 0 -and (Test-IRWorkflowTenant $context $ExpectedTenant)
    if (-not $reuse) {
        Connect-MgGraph -TenantId $ExpectedTenant -Scopes $scopes -ContextScope Process -NoWelcome -ErrorAction Stop | Out-Null
        $context = Get-MgContext -ErrorAction Stop
    }
    if (-not (Test-IRWorkflowTenant $context $ExpectedTenant)) { throw 'Graph tenant or sign-in context could not be verified.' }
    $missing = @($scopes | Where-Object { @($context.Scopes) -notcontains $_ })
    if ($missing.Count) { throw "Graph consent is missing: $($missing -join ', ')." }
    Write-IRLine '[OK]   GRAPH CONNECTED' -ForegroundColor Green
    return $context
}

function Connect-IRWorkflowExchange {
    param([string]$TenantId, [string]$UserId, [string]$TargetUpn)
    $connections = @(Get-ConnectionInformation -ErrorAction Stop | Where-Object {
        $_.ModulePrefix -eq 'IRWorkflow' -and $_.State -eq 'Connected'
    })
    if ($connections.Count -gt 1) { throw 'More than one workflow Exchange session is active. Use one PowerShell window.' }
    if ($connections.Count -eq 0) {
        Connect-ExchangeOnline -Prefix IRWorkflow -ShowBanner:$false -ErrorAction Stop | Out-Null
        $connections = @(Get-ConnectionInformation -ErrorAction Stop | Where-Object {
            $_.ModulePrefix -eq 'IRWorkflow' -and $_.State -eq 'Connected'
        })
    }
    if ($connections.Count -ne 1 -or [string]$connections[0].TenantID -ne $TenantId) {
        throw 'Exchange tenant does not match Graph. No mailbox changes are allowed.'
    }
    $mailbox = Get-IRWorkflowMailbox -Identity $TargetUpn -ErrorAction Stop
    if (-not $mailbox.ExternalDirectoryObjectId -or [string]$mailbox.ExternalDirectoryObjectId -ne $UserId) {
        throw 'UPN/mailbox match failed. No mailbox changes are allowed.'
    }
    Write-IRLine '[OK]   EXCHANGE CONNECTED' -ForegroundColor Green
    Write-IRLine '[OK]   UPN MATCHED' -ForegroundColor Green
    return $mailbox
}

function Set-IRWorkflowTarget {
    param($Context, $User)
    if (-not $User.id -or -not $Context.TenantId) { throw 'Workflow target could not be verified.' }
    $previous = $global:FieldKitIRSession
    if (-not $previous -or $previous.TenantId -ne [string]$Context.TenantId -or $previous.UserId -ne [string]$User.id) {
        $global:FieldKitIRSession = @{
            TenantId=[string]$Context.TenantId; UserId=[string]$User.id; UPN=[string]$User.userPrincipalName
            Assessment=$null; Response=$null; Recovery=$null
        }
    }
    else { $global:FieldKitIRSession.UPN = [string]$User.userPrincipalName }
}

function Get-IRWorkflowInput {
    param([string]$TargetUpn, [string]$ExpectedTenant)
    $saved = $global:FieldKitIRSession
    if ([string]::IsNullOrWhiteSpace($TargetUpn) -and $saved) { $TargetUpn = [string]$saved.UPN }
    if ([string]::IsNullOrWhiteSpace($ExpectedTenant) -and $saved -and $TargetUpn -ieq $saved.UPN) {
        $ExpectedTenant = [string]$saved.TenantId
    }
    if ([string]::IsNullOrWhiteSpace($TargetUpn)) { $TargetUpn = Read-Host 'User UPN' }
    if ([string]::IsNullOrWhiteSpace($ExpectedTenant)) {
        # An established workflow is authoritative only for its previously verified target.
        if ($saved -and $TargetUpn -ieq $saved.UPN) { $ExpectedTenant = [string]$saved.TenantId }
        else { $ExpectedTenant = Read-Host 'Tenant Domain' }
    }
    $TargetUpn=$TargetUpn.Trim(); $ExpectedTenant=$ExpectedTenant.Trim()
    if ($TargetUpn -notmatch '^[^\s@]+@[^\s@]+$') { throw 'Enter one valid user UPN.' }
    if ($ExpectedTenant -notmatch '^[a-zA-Z0-9][a-zA-Z0-9.-]+$' -or $ExpectedTenant -in @('common','organizations','consumers')) {
        throw 'Enter a specific tenant domain or tenant ID.'
    }
    if (-not $saved -and -not $NoPause) {
        Write-IRLine ''
        [void](Read-Host 'Press ENTER to sign in for assessment, response, and recovery. Changes require operator confirmation')
        Write-IRLine ''
    }
    return @{UPN=$TargetUpn;Tenant=$ExpectedTenant}
}

function Read-IRNavigation {
    param([string]$NextLabel)
    Write-IRLine ''
    Write-IRLine "Press ENTER to continue: $NextLabel"
    Write-IRLine 'Press ESC to close'
    if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and
        (Get-Command Read-Host).CommandType -ne 'Function') {
        try {
            while ($true) {
                $key=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                if ($key.VirtualKeyCode -eq 13) { return $true }
                if ($key.VirtualKeyCode -eq 27) { return $false }
            }
        } catch { Write-IRLine 'Key input unavailable here. Type ESC and Enter to close.' }
    }
    while ($true) {
        $answer=Read-Host 'ENTER = continue; type ESC then ENTER to close'
        if ([string]::IsNullOrWhiteSpace($answer)) { return $true }
        if ($answer.Trim() -ieq 'ESC' -or $answer -eq [string][char]27) { return $false }
        Write-IRLine 'Press ENTER to continue, or type ESC and ENTER to close.'
    }
}

function Close-IRWorkflow {
    param([string]$Message, [switch]$Wait)
    Write-IRLine ''
    Write-IRLine $Message
    if ($Wait -and -not $NoPause) { [void](Read-Host 'Press ENTER to finish') }
}

function Invoke-IRNextStep {
    param([string]$FileName, [string]$Objective)
    if ($NoPause) { return }
    if ([string]::IsNullOrWhiteSpace($FileName)) {
        Close-IRWorkflow 'Run finished. Review unresolved items above before continuing.' -Wait
        return
    }
    $label=switch ($FileName) {
        'BEC-CONTAIN-ERADICATE' { 'BEC-CONTAIN-ERADICATE' }
        'BEC-RECOVER-VALIDATE' { 'BEC-RECOVER-VALIDATE' }
        default { 'BEC-RISK-ASSESSMENT (FINAL CHECK)' }
    }
    if (-not (Read-IRNavigation $label)) {
        $message=switch ($FileName) {
            'BEC-CONTAIN-ERADICATE' { 'Assessment complete. Document the findings and follow the recommendation above.' }
            'BEC-RECOVER-VALIDATE' { 'Response run finished. A contained account still requires approved recovery.' }
            default { 'Recovery run finished. Confirm user sign-in with MFA and complete assessment and monitoring.' }
        }
        Close-IRWorkflow $message
        return
    }
    try {
        $next=Join-Path $PSScriptRoot ($FileName+'.ps1')
        if (-not (Test-Path -LiteralPath $next -PathType Leaf)) {
            throw "Next script not found: $FileName. Extract all three files together with their original filenames."
        }
        $saved=$global:FieldKitIRSession
        if (-not $saved -or -not $saved.UPN -or -not $saved.TenantId) {
            throw 'Verified target context unavailable. Start the next script manually.'
        }
        $nextArgs=@{Tenant=[string]$saved.TenantId}
        $command=Get-Command -Name $next -ErrorAction Stop
        if (-not $command.Parameters.ContainsKey('OutputDelayMs')) {
            throw 'Next script is from a different release. Replace all three files together.'
        }
        $nextArgs.OutputDelayMs=$OutputDelayMs
        if ($FileName -eq 'BEC-RISK-ASSESSMENT') {
            $nextArgs.UserPrincipalName=[string]$saved.UPN
            $nextArgs.FinalReview=$true
        } else { $nextArgs.UPN=[string]$saved.UPN }
        & $next @nextArgs
    }
    catch {
        Write-IRLine "[FAIL] Next step did not finish: $($_.Exception.Message)" -ForegroundColor Red
        Close-IRWorkflow 'Workflow stopped. Review the error and current account state before retrying.' -Wait
    }
}

# End shared workflow functions.

function Write-Info { param([string]$Message) Write-IRLine "[INFO] $Message" }

function Write-Ok   { param([string]$Message) Write-IRLine '[OK]   ' -ForegroundColor Green -NoNewline; Write-IRLine $Message }

function Write-Warn { param([string]$Message) Write-IRLine '[WARN] ' -ForegroundColor Yellow -NoNewline; Write-IRLine $Message }

function Write-Fail { param([string]$Message) Write-IRLine '[FAIL] ' -ForegroundColor Red -NoNewline; Write-IRLine $Message }

function Section([string]$Title) {
    Write-IRLine ''
    if ($Title -eq 'ADDITIONAL CHECKS: ALL CLEAR') { Write-IRLine $Title -ForegroundColor Green }
    else { Write-IRLine $Title }
}

function Add-UniqueText {
    param([System.Collections.ArrayList]$List, [string]$Text)
    if (-not [string]::IsNullOrWhiteSpace($Text) -and -not $List.Contains($Text)) { [void]$List.Add($Text) }
}

function Add-DataGap { param([string]$Text) Add-UniqueText -List $script:DataGaps -Text $Text }

function Add-Action {
    param(
        [string]$Category,
        [string]$Action,
        [ValidateSet('Completed','Skipped','Failed')][string]$Result,
        [string]$Detail = ''
    )
    if ($script:Phase -eq 'Containment' -and $Result -ne 'Completed') { $script:ContainmentBlocked = $true }
    [void]$script:ActionLog.Add([pscustomobject]@{
        Time = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
        Category = $Category
        Action = $Action
        Result = $Result
        Detail = $Detail
    })
}

function Pause-End {
    if (-not $NoPause) { try { [void](Read-Host 'Press Enter to return to PowerShell') } catch {} }
}

function Get-ShortError {
    param($ErrorRecord)
    $message = $ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) { return 'Unknown error' }
    return (($message -replace '\s+', ' ').Trim())
}

function Enable-Tls12 { try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {} }

function Ensure-Module {
    param([string]$Name)
    $minimum = if ($Name -eq 'ExchangeOnlineManagement') { [version]'3.2.0' } else { [version]'2.0.0' }
    $available = Get-Module -ListAvailable -Name $Name | Where-Object { $_.Version -ge $minimum } |
        Sort-Object Version -Descending | Select-Object -First 1
    if (-not $available) {
        Add-DataGap "Requires $Name $minimum or later. Install separately: Install-Module $Name -Scope CurrentUser -MinimumVersion $minimum"
        return $false
    }
    try { Import-Module $available.Path -Global -ErrorAction Stop; return $true }
    catch { Add-DataGap "$Name could not be imported: $(Get-ShortError $_)"; return $false }
}

function Encode-UrlValue { param([string]$Value) return [System.Uri]::EscapeDataString($Value) }

function Escape-ODataLiteral { param([string]$Value) return ($Value -replace "'", "''") }

function Invoke-GraphGet {
    param([string]$Uri, [string]$Name, [switch]$DoNotRecordGap)
    try { Assert-GraphEndpoint $Uri; return Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject -ErrorAction Stop }
    catch {
        if (-not $DoNotRecordGap) { Add-DataGap "$Name unavailable: $(Get-ShortError $_)" }
        return $null
    }
}

function Invoke-GraphWrite {
    param(
        [ValidateSet('POST','PATCH','DELETE')][string]$Method,
        [string]$Uri,
        [object]$Body
    )
    try {
        Assert-GraphEndpoint $Uri
        Assert-ResponseContext
        if ($Method -eq 'DELETE') {
            if ($Uri -notmatch '^https://graph\.microsoft\.com/v1\.0/oauth2PermissionGrants/[a-zA-Z0-9_-]+$') { throw 'Unexpected deletion endpoint.' }
            $grant = Invoke-GraphGet -Uri $Uri -Name 'Grant owner validation'
            if (-not $grant -or $grant.consentType -ne 'Principal' -or [string]$grant.principalId -ne $script:ExpectedUserId) {
                throw 'Grant is not user-specific consent belonging to this target.'
            }
        }
        elseif ($Uri -ne "https://graph.microsoft.com/v1.0/users/$($script:ExpectedUserId)" -and
            $Uri -ne "https://graph.microsoft.com/v1.0/users/$($script:ExpectedUserId)/revokeSignInSessions") { throw 'Write target mismatch.' }

        if ($Method -eq 'DELETE') {
            Invoke-MgGraphRequest -Method DELETE -Uri $Uri -ErrorAction Stop | Out-Null
        }
        elseif ($Method -eq 'POST') {
            $json = if ($null -eq $Body) { '{}' } else { $Body | ConvertTo-Json -Depth 12 }
            $result = Invoke-MgGraphRequest -Method POST -Uri $Uri -Body $json -ContentType 'application/json' -OutputType PSObject -ErrorAction Stop
            if ($result.value -ne $true) { throw 'Session revocation was not acknowledged as successful.' }
        }
        else {
            Invoke-MgGraphRequest -Method PATCH -Uri $Uri -Body ($Body | ConvertTo-Json -Depth 12) -ContentType 'application/json' -ErrorAction Stop | Out-Null
        }
        return $true
    }
    catch {
        $script:LastWriteError = if ($Body -and $Body.passwordProfile) { 'Password request failed; response details withheld to protect the supplied password.' } else { Get-ShortError $_ }
        return $false
    }
}

function Get-GraphCollection {
    param([string]$Uri, [string]$Name, [int]$MaximumItems = 250)
    $items = New-Object System.Collections.ArrayList
    $next = $Uri
    $success = $true
    while ($next -and $items.Count -lt $MaximumItems) {
        $page = Invoke-GraphGet -Uri $next -Name $Name
        if (-not $page) { $success = $false; break }
        foreach ($item in @($page.value)) {
            [void]$items.Add($item)
            if ($items.Count -ge $MaximumItems) { break }
        }
        $next = $page.'@odata.nextLink'
    }
    if ($next -or $items.Count -ge $MaximumItems) { $success = $false; Add-DataGap "$Name incomplete: collection limit reached." }
    return [pscustomobject]@{ Success=$success; Items=@($items); Truncated=[bool]$next }
}

function Get-GraphUser {
    param([string]$UserPrincipalName)

    $select = (
        'id,displayName,userPrincipalName,mail,accountEnabled,' +
        'onPremisesSyncEnabled,onPremisesSamAccountName,onPremisesSecurityIdentifier,' +
        'lastPasswordChangeDateTime,signInSessionsValidFromDateTime'
    )

    $escaped = Escape-ODataLiteral $UserPrincipalName
    $filter = Encode-UrlValue "userPrincipalName eq '$escaped'"

    $uri = (
        'https://graph.microsoft.com/v1.0/users?' +
        "`$filter=$filter&`$select=$select"
    )

    $result = Invoke-GraphGet `
        -Uri $uri `
        -Name 'Graph user lookup' `
        -DoNotRecordGap

    if ($result -and @($result.value).Count -eq 1) {
        return @($result.value)[0]
    }

    return $null
}

function Test-ScopesPresent {
    param($Context, [string[]]$RequiredScopes)
    if (-not $Context) { return $false }
    foreach ($scope in $RequiredScopes) { if (@($Context.Scopes) -notcontains $scope) { return $false } }
    return $true
}

function Connect-GraphForTarget {
    param([string]$UserPrincipalName, [string[]]$Scopes)
    if (-not (Ensure-Module 'Microsoft.Graph.Authentication')) { return $null }
    $context = Connect-IRWorkflowGraph $Tenant
    $target = Get-GraphUser $UserPrincipalName
    if (-not $target) { throw 'Target user could not be uniquely resolved.' }
    $script:ExpectedTenantId = [string]$context.TenantId
    $script:ExpectedUserId = [string]$target.id
    $script:ExpectedUpn = [string]$target.userPrincipalName
    $script:ExpectedSid = [string]$target.onPremisesSecurityIdentifier
    $script:ExpectedSynced = $target.onPremisesSyncEnabled -eq $true
    Set-IRWorkflowTarget $context $target
    return $target
}

function Connect-ExchangeForTarget {
    param([string]$Identity)
    if ($SkipExchange) { Add-DataGap 'Exchange checks and actions skipped.'; return $false }
    if (-not (Ensure-Module 'ExchangeOnlineManagement')) { return $false }
    try {
        $null = Connect-IRWorkflowExchange $script:ExpectedTenantId $script:ExpectedUserId $Identity
        return $true
    }
    catch { Add-DataGap "Exchange unavailable: $(Get-ShortError $_)"; return $false }
}

function Assert-ResponseContext {
    param([switch]$Exchange)
    $context = Get-MgContext -ErrorAction Stop
    if (-not $context -or [string]$context.TenantId -ne $script:ExpectedTenantId -or $context.AuthType -ne 'Delegated' -or $context.Environment -ne 'Global' -or $context.ContextScope -ne 'Process' -or
        -not (Test-ScopesPresent $context (Get-IRWorkflowScopes))) {
        throw 'Graph tenant/session changed. Stop and reconnect.'
    }
    $fresh = Get-GraphUser $script:ExpectedUpn
    if (-not $fresh -or [string]$fresh.id -ne $script:ExpectedUserId -or
        ($fresh.onPremisesSyncEnabled -eq $true) -ne $script:ExpectedSynced -or
        [string]$fresh.onPremisesSecurityIdentifier -ne $script:ExpectedSid) {
        throw 'Target identity or authority changed. Stop and rediscover.'
    }
    if ($Exchange) {
        $connections = @(Get-ConnectionInformation -ErrorAction Stop |
            Where-Object { $_.ModulePrefix -eq 'IRWorkflow' -and $_.State -eq 'Connected' })
        if ($connections.Count -ne 1 -or [string]$connections[0].TenantID -ne $script:ExpectedTenantId) {
            throw 'Exchange tenant could not be matched to Graph.'
        }
        $mailbox = Get-IRWorkflowMailbox -Identity $script:ExpectedUpn -ErrorAction Stop
        if (-not $mailbox.ExternalDirectoryObjectId -or [string]$mailbox.ExternalDirectoryObjectId -ne $script:ExpectedUserId) {
            throw 'Exchange mailbox identity does not match Graph.'
        }
    }
}

function Assert-GraphEndpoint {
    param([string]$Uri)
    $parsed = [uri]$Uri
    if (-not $parsed.IsAbsoluteUri -or $parsed.Scheme -ne 'https' -or $parsed.Host -ne 'graph.microsoft.com' -or
        -not $parsed.IsDefaultPort -or $parsed.UserInfo) { throw 'Unexpected Graph endpoint.' }
}

function Escape-LdapFilterValue {
    param([string]$Value)
    if ($null -eq $Value) { return '' }
    $escaped = $Value -replace '\\', '\5c'
    $escaped = $escaped -replace '\*', '\2a'
    $escaped = $escaped -replace '\(', '\28'
    $escaped = $escaped -replace '\)', '\29'
    $escaped = $escaped -replace "`0", '\00'
    return $escaped
}

function Find-AdUser {
    param($GraphUser)
    $searcher = $null; $root = $null; $results = $null
    try {
        if (-not $GraphUser.onPremisesSecurityIdentifier) { throw 'Synced SID unavailable; name-only AD matching is blocked.' }
        $sid = New-Object System.Security.Principal.SecurityIdentifier([string]$GraphUser.onPremisesSecurityIdentifier)
        $bytes = New-Object byte[] $sid.BinaryLength
        $sid.GetBinaryForm($bytes, 0)
        $filterSid = ($bytes | ForEach-Object { '\' + $_.ToString('X2') }) -join ''
        $rootDse = [ADSI]'LDAP://RootDSE'
        $namingContext = [string]$rootDse.defaultNamingContext
        if (-not $namingContext) { throw 'No reachable AD naming context.' }
        $root = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$namingContext")
        $searcher = New-Object System.DirectoryServices.DirectorySearcher($root)
        $searcher.Filter = "(&(objectCategory=person)(objectClass=user)(objectSid=$filterSid))"
        $results = $searcher.FindAll()
        if ($results.Count -ne 1) { throw 'A unique AD object matching the synced SID was not found.' }
        $entry = $results[0].GetDirectoryEntry()
        $actualSid = New-Object System.Security.Principal.SecurityIdentifier([byte[]]$entry.Properties['objectSid'].Value, 0)
        if ($actualSid.Value -ne [string]$GraphUser.onPremisesSecurityIdentifier) { throw 'AD SID mismatch.' }
        return [pscustomobject]@{
            Entry=$entry; Sid=$actualSid.Value; DisplayName=[string]$entry.Properties['displayName'].Value
            UPN=[string]$entry.Properties['userPrincipalName'].Value; SamAccountName=[string]$entry.Properties['sAMAccountName'].Value
            UserAccountControl=[int]$entry.Properties['userAccountControl'].Value
        }
    }
    catch { Add-DataGap "AD identity not validated: $(Get-ShortError $_)"; return $null }
    finally {
        if ($results) { $results.Dispose() }; if ($searcher) { $searcher.Dispose() }; if ($root) { $root.Dispose() }
    }
}

function Assert-AdTarget {
    param($AdUser)
    Assert-ResponseContext
    if (-not $AdUser -or -not $script:ExpectedSynced -or $AdUser.Sid -ne $script:ExpectedSid) { throw 'AD target is not bound to the synced identity.' }
    $AdUser.Entry.RefreshCache(@('objectSid','userAccountControl'))
    $sid = New-Object System.Security.Principal.SecurityIdentifier([byte[]]$AdUser.Entry.Properties['objectSid'].Value, 0)
    if ($sid.Value -ne $script:ExpectedSid) { throw 'AD identity changed before write.' }
}

function Test-AdUserDisabled {
    param($AdUser)
    if (-not $AdUser) { return $null }
    return [bool](([int]$AdUser.UserAccountControl -band 2) -eq 2)
}

function Record-AdSyncPending {
    if (-not $script:AdChanged) { $script:SyncResult='Not required'; return }
    $script:SyncResult='Not requested - AD replication and cloud synchronization require separate validation'
    # Keep internal sync state; client synchronization is validated before rollout.
}

function Test-SensitiveOAuthScope {
    param([string]$Scope)
    if ([string]::IsNullOrWhiteSpace($Scope)) { return $false }
    $patterns = @('^Mail\.','^Mailbox','^Files\.Read','^Files\.ReadWrite','^Sites\.','^Directory\.','^Group\.','^User\.ReadWrite','^Calendars\.ReadWrite','^Contacts\.ReadWrite','^full_access_as_user$','^offline_access$')
    foreach ($token in ($Scope -split '\s+' | Where-Object { $_ })) {
        foreach ($pattern in $patterns) { if ($token -match $pattern) { return $true } }
    }
    return $false
}

function Get-ServicePrincipalInfo {
    param([string]$Id)

    if ([string]::IsNullOrWhiteSpace($Id)) {
        return $null
    }

    $uri = (
        'https://graph.microsoft.com/v1.0/servicePrincipals/{0}' +
        '?$select=displayName,appDisplayName,verifiedPublisher'
    ) -f $Id

    return Invoke-GraphGet `
        -Uri $uri `
        -Name 'OAuth application lookup'
}

function Get-OAuthItems {
    param($GraphUser)
    $items = New-Object System.Collections.ArrayList
    $result = Get-GraphCollection -Uri "https://graph.microsoft.com/v1.0/users/$($GraphUser.id)/oauth2PermissionGrants" -Name 'User-specific OAuth consent lookup' -MaximumItems 200
    if (-not $result.Success) { return @() }
    foreach ($grant in @($result.Items | Where-Object { $_.consentType -eq 'Principal' -and [string]$_.principalId -eq [string]$GraphUser.id })) {
        $sp = Get-ServicePrincipalInfo ([string]$grant.clientId)
        $appName = 'Unknown application'
        $publisher = 'Unverified publisher'
        if ($sp) {
            if ($sp.displayName) { $appName = [string]$sp.displayName }
            elseif ($sp.appDisplayName) { $appName = [string]$sp.appDisplayName }
            if ($sp.verifiedPublisher -and $sp.verifiedPublisher.displayName) { $publisher = "Verified publisher: $($sp.verifiedPublisher.displayName)" }
        }
        $scope = if ($grant.scope) { [string]$grant.scope } else { 'No scope returned' }
        [void]$items.Add([pscustomobject]@{
            Id = [string]$grant.id
            App = $appName
            Publisher = $publisher
            Scope = $scope
            Sensitive = Test-SensitiveOAuthScope $scope
        })
    }
    return @($items)
}

function Get-RuleActions {
    param($Rule)
    $actions = New-Object System.Collections.ArrayList
    if (@($Rule.ForwardTo | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) { Add-UniqueText $actions 'FORWARD' }
    if (@($Rule.RedirectTo | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) { Add-UniqueText $actions 'REDIRECT' }
    if (@($Rule.ForwardAsAttachmentTo | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }).Count -gt 0) { Add-UniqueText $actions 'FORWARD_AS_ATTACHMENT' }
    if ($Rule.DeleteMessage) { Add-UniqueText $actions 'DELETE' }
    if ($Rule.PermanentDelete) { Add-UniqueText $actions 'PERMANENT_DELETE' }
    if ($Rule.MarkAsRead) { Add-UniqueText $actions 'MARK_READ' }
    if ($Rule.MoveToFolder) { Add-UniqueText $actions "MOVE: $($Rule.MoveToFolder)" }
    if ($Rule.CopyToFolder) { Add-UniqueText $actions "COPY: $($Rule.CopyToFolder)" }
    if ($Rule.StopProcessingRules) { Add-UniqueText $actions 'STOP_PROCESSING' }
    if ($actions.Count -eq 0) { Add-UniqueText $actions 'No common BEC action returned' }
    return @($actions)
}

function Get-RuleTargets {
    param($Rule)
    $targets = New-Object System.Collections.ArrayList
    foreach ($propertyName in @('ForwardTo','RedirectTo','ForwardAsAttachmentTo')) {
        foreach ($target in @($Rule.$propertyName)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$target)) { Add-UniqueText $targets ([string]$target) }
        }
    }
    return @($targets)
}

function Test-DefaultSystemRule {
    param($Rule, [string[]]$Actions)
    return ([string]$Rule.Name -eq 'Junk E-mail Rule' -and @($Actions | Where-Object { $_ -ne 'No common BEC action returned' }).Count -eq 0)
}

function Test-RuleHighRisk {
    param($Rule, [string[]]$Actions)
    $text = $Actions -join ' '
    return ($text -match 'FORWARD|REDIRECT|DELETE|PERMANENT_DELETE|MARK_READ' -or ($Rule.IsHidden -and $text -notmatch 'No common BEC action returned'))
}

function Get-InboxRuleItems {
    param([string]$Identity)
    $items = New-Object System.Collections.ArrayList
    try { $raw = @(Get-IRWorkflowInboxRule -Mailbox $Identity -IncludeHidden -ErrorAction Stop) }
    catch {
        try {
            $raw = @(Get-IRWorkflowInboxRule -Mailbox $Identity -ErrorAction Stop)
            Add-DataGap 'Hidden inbox rules could not be queried; visible rules were returned.'
        }
        catch { Add-DataGap "Inbox rule lookup unavailable: $(Get-ShortError $_)"; return @() }
    }
    foreach ($rule in $raw) {
        $actions = @(Get-RuleActions $rule)
        if (Test-DefaultSystemRule -Rule $rule -Actions $actions) { continue }
        [void]$items.Add([pscustomobject]@{
            Identity = $rule.Identity
            Name = [string]$rule.Name
            Enabled = if ($rule.Enabled -eq $true) { 'Enabled' } elseif ($rule.Enabled -eq $false) { 'Disabled' } else { 'Unknown' }
            Hidden = [bool]$rule.IsHidden
            Priority = if ($null -ne $rule.Priority) { [string]$rule.Priority } else { 'Not returned' }
            Actions = $actions
            Targets = @(Get-RuleTargets $rule)
            HighRisk = Test-RuleHighRisk -Rule $rule -Actions $actions
        })
    }
    return @($items)
}

function Normalize-AddressText {
    param($Value)
    if ($null -eq $Value) { return '' }
    return (([string]$Value -replace '^(?i)smtp:', '').Trim())
}

function Get-MailboxObject {
    param([string]$Identity)
    try { return Get-IRWorkflowMailbox -Identity $Identity -ErrorAction Stop }
    catch { Add-DataGap "Mailbox lookup unavailable: $(Get-ShortError $_)"; return $null }
}

function Get-MailboxState {
    param([string]$Identity)
    $mailbox = Get-MailboxObject $Identity
    $forwarding = New-Object System.Collections.ArrayList
    $fullAccess = New-Object System.Collections.ArrayList
    $sendAs = New-Object System.Collections.ArrayList
    $sendOnBehalf = New-Object System.Collections.ArrayList
    $legacy = New-Object System.Collections.ArrayList

    if ($mailbox) {
        $smtp = Normalize-AddressText $mailbox.ForwardingSmtpAddress
        $recipient = Normalize-AddressText $mailbox.ForwardingAddress
        if ($smtp) { Add-UniqueText $forwarding "SMTP forwarding: $smtp" }
        if ($recipient) { Add-UniqueText $forwarding "Recipient forwarding: $recipient" }
        if ($mailbox.DeliverToMailboxAndForward -eq $true) { Add-UniqueText $forwarding 'Deliver copy to mailbox: Yes' }
        foreach ($delegate in @($mailbox.GrantSendOnBehalfTo)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$delegate)) {
                [void]$sendOnBehalf.Add([pscustomobject]@{ Display=[string]$delegate; Raw=$delegate })
            }
        }
    }
    else { Add-DataGap 'Mailbox could not be resolved in Exchange Online.' }

    try {
        $items = @()
        if (Get-Command Get-IRWorkflowMailboxPermission -ErrorAction SilentlyContinue) {
            $items = @(Get-IRWorkflowMailboxPermission -Identity $Identity -ErrorAction Stop | Where-Object { $_.User -notlike 'NT AUTHORITY\SELF' -and $_.IsInherited -eq $false -and $_.Deny -ne $true -and $_.AccessRights -contains 'FullAccess' })
        }
        else { throw 'Required Exchange permission read command is unavailable.' }
        foreach ($item in $items) { [void]$fullAccess.Add([pscustomobject]@{ Display=[string]$item.User; Raw=[string]$item.User }) }
    }
    catch { Add-DataGap "Full Access lookup unavailable: $(Get-ShortError $_)" }

    try {
        $items = @()
        if (Get-Command Get-IRWorkflowRecipientPermission -ErrorAction SilentlyContinue) {
            $items = @(Get-IRWorkflowRecipientPermission -Identity $Identity -ErrorAction Stop | Where-Object { $_.Trustee -notlike 'NT AUTHORITY\SELF' -and $_.AccessRights -contains 'SendAs' })
        }
        else { throw 'Required Exchange permission read command is unavailable.' }
        foreach ($item in $items) { [void]$sendAs.Add([pscustomobject]@{ Display=[string]$item.Trustee; Raw=[string]$item.Trustee }) }
    }
    catch { Add-DataGap "Send As lookup unavailable: $(Get-ShortError $_)" }

    try {
        $cas = Get-IRWorkflowCASMailbox -Identity $Identity -ErrorAction Stop
        if ($cas.ImapEnabled -eq $true) { Add-UniqueText $legacy 'IMAP' }
        if ($cas.PopEnabled -eq $true) { Add-UniqueText $legacy 'POP' }
        if ($cas.SmtpClientAuthenticationDisabled -eq $false) { Add-UniqueText $legacy 'Authenticated SMTP' }
    }
    catch { Add-DataGap "Mailbox protocol lookup unavailable: $(Get-ShortError $_)" }

    return [pscustomobject]@{
        Mailbox = $mailbox
        Forwarding = @($forwarding)
        FullAccess = @($fullAccess)
        SendAs = @($sendAs)
        SendOnBehalf = @($sendOnBehalf)
        Legacy = @($legacy)
    }
}

function Confirm-Exact {
    param([string]$Required)
    while ($true) {
        $value = Read-Host "Type $Required to continue"
        if ([string]::IsNullOrWhiteSpace($value) -or $value.Trim() -ieq 'N') { return $false }
        if ($value.Trim() -ieq $Required) { return $true }
        Write-Warn "Not confirmed. Enter: $Required"
        Write-IRLine 'Press Enter or type N to cancel.'
    }
}

function Enable-AdRecoveryAccount {
    param($AdUser)
    Assert-AdTarget $AdUser
    $current=[int]$AdUser.Entry.Properties['userAccountControl'].Value
    $AdUser.Entry.Properties['userAccountControl'].Value = $current -band (-bnot 2)
    $AdUser.Entry.CommitChanges()
    $script:AdChanged=$true
    $AdUser.Entry.RefreshCache(@('userAccountControl'))
    if (([int]$AdUser.Entry.Properties['userAccountControl'].Value -band 2) -ne 0) {
        throw 'AD account enable was not verified. Entra was not re-enabled.'
    }
    Add-Action 'Identity' 'Restore AD account' 'Completed' 'Enabled state verified'
    Write-Ok 'Active Directory account enabled'
}

function Test-RecoveryReadiness {
    param($GraphUser, [bool]$ExchangeAvailable, [switch]$AllowReview)
    if (-not $ExchangeAvailable) { throw 'Mailbox checks unavailable. Resolve the connection before restoring access.' }
    $rules=@(Get-InboxRuleItems $GraphUser.userPrincipalName)
    $mailbox=Get-MailboxState $GraphUser.userPrincipalName
    $oauth=@(Get-OAuthItems $GraphUser)
    if ($script:DataGaps.Count) { throw 'Recovery checks are incomplete. Resolve the review items before restoring access.' }
    $riskyRules=@($rules | Where-Object { $_.HighRisk -and $_.Enabled -eq 'Enabled' })
    $riskyGrants=@($oauth | Where-Object { $_.Sensitive -and $_.Publisher -eq 'Unverified publisher' })
    $findings=@(
        $riskyRules | ForEach-Object {
            @{ Key="Rule|$($_.Identity)|$($_.Name)|$($_.Actions -join ';')|$($_.Targets -join ';')";
               Text="Rule: $($_.Name) | $($_.Actions -join '; ') | $($_.Targets -join '; ')" }
        }
        $mailbox.Forwarding | ForEach-Object { @{Key="Forwarding|$_";Text="Forwarding: $_"} }
        $riskyGrants | ForEach-Object { @{Key="OAuth|$($_.Id)|$($_.App)|$($_.Scope)";Text="OAuth: $($_.App) | $($_.Scope)"} }
    )
    if ($findings.Count) {
        $fingerprint=($findings | ForEach-Object { $_.Key } | Sort-Object) -join "`n"
        if ($fingerprint -cne $script:ApprovedRecoveryFindings) {
            if (-not $AllowReview) { throw 'Persistence findings changed after approval. Access was not restored.' }
            Write-Warn 'Remaining findings need review. Remove unauthorized items in Step 2.'
            foreach ($finding in $findings) { Write-IRLine $finding.Text }
            Write-IRLine 'Continue only if every listed item is legitimate and approved to remain.'
            $script:PendingRecoveryFindings=$fingerprint
        }
    }
    return $true
}

function Write-IRTicketSummary {
    $session=$global:FieldKitIRSession
    Write-IRLine ''
    Write-IRLine '--------------------------------------'
    Write-IRLine 'TICKET SUMMARY'
    Write-IRLine "User: $($session.UPN)"
    Write-IRLine "Completed: $((Get-Date).ToString('MM/dd/yyyy HH:mm'))"
    if ($session.Assessment) { Write-IRLine "Initial assessment: $(if ($session.Assessment.Summary -eq 'NO HIGH-RISK FINDINGS') {'NO HIGH-RISK IOCs FOUND'} elseif ($session.Assessment.Summary -eq 'HIGH RISK') {'HIGH-RISK IOCs'} else {$session.Assessment.Summary})" }
    if ($session.Response) {
        $response=$session.Response
        if ($response.Before -and $response.After) {
            Write-IRLine "Account: $($response.Before.Account) -> $($response.After.Account) -> Enabled"
        }
        foreach ($action in @($response.Actions)) {
            $result=if ($action.Result -eq 'Completed' -and $action.Action -eq 'Revoke active sessions') { 'Session revocation submitted' }
                elseif ($action.Result -eq 'Completed' -and $action.Action -eq 'Verify user MFA protection') { 'Operator confirmed' }
                else { $action.Result }
            Write-IRLine "$($action.Action): $result$(if ($action.Result -eq 'Skipped') {" - $($action.Detail)"})"
        }
        if ($response.Failed -gt 0) { Write-IRLine 'Earlier response failures: operator confirmed resolution before recovery.' }
    }
    else { Write-IRLine 'Earlier response: no results recorded in this PowerShell session.' }
    Write-IRLine 'Recovery: Account enable verified. Identity, device safety, remediation, and MFA readiness confirmed by operator.'
    Write-IRLine 'Follow-up: verify user sign-in with MFA; monitor for new suspicious activity for 48 hours.'
    Write-IRLine '--------------------------------------'
}


try {
    Enable-Tls12
    try { $script:OriginalTitle=$Host.UI.RawUI.WindowTitle; $Host.UI.RawUI.WindowTitle='BEC: Restore and Validate' } catch {}
    Write-IRLine 'BEC: Restore and Validate'
    Write-IRLine 'Check recovery readiness and restore approved account access.'
    Write-IRLine (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-IRLine '' 
    $inputs=Get-IRWorkflowInput $UPN $Tenant
    $UPN=$inputs.UPN; $Tenant=$inputs.Tenant
    $user=Connect-GraphForTarget $UPN (Get-IRWorkflowScopes)
    $global:FieldKitIRSession.Recovery=$null
    $exoOk=Connect-ExchangeForTarget $UPN
    Section 'TARGET'
    Write-IRLine "UPN: $($user.userPrincipalName)"
    Write-IRLine "Account Status: $(if ($user.accountEnabled -eq $false) {'Disabled'} elseif ($user.accountEnabled -eq $true) {'Enabled'} else {'Unknown'})"
    $null=Test-RecoveryReadiness $user $exoOk -AllowReview
    $adUser=$null
    if ($user.onPremisesSyncEnabled -eq $true) {
        $adUser=Find-AdUser $user
        if (-not $adUser) { throw 'The SID-matched AD account is unavailable. Access was not restored.' }
    }
    $response=$global:FieldKitIRSession.Response
    if (-not $response -or -not $response.RecoveryReady) {
        Write-IRLine 'RECOVER confirms any failed or unfinished response work was completed and verified.'
    }
    Write-IRLine ''
    Write-IRLine 'RECOVERY CHECKLIST'
    Write-IRLine '- User identity verified through a trusted contact method.'
    Write-IRLine '- Device safety confirmed.'
    Write-IRLine '- Password remediation, scope review, and persistence cleanup complete.'
    Write-IRLine '- MFA is enforced for this user and registered methods are trusted (operator confirmed).'
    Write-IRLine '- Recovery approved by the incident owner.'
    if ($script:PendingRecoveryFindings) { Write-IRLine '- Every remaining finding listed above is legitimate and approved to remain.' }
    if (-not (Confirm-Exact 'RECOVER')) { throw 'Recovery cancelled. Access was not restored.' }
    $script:ApprovedRecoveryFindings=$script:PendingRecoveryFindings
    # Recheck live state and evidence after confirmation, not just before the prompt.
    Assert-ResponseContext -Exchange
    $user=Get-GraphUser $UPN
    $null=Test-RecoveryReadiness $user $exoOk
    if ($user.onPremisesSyncEnabled -eq $true) {
        Enable-AdRecoveryAccount $adUser
        Record-AdSyncPending
    }
    if ($user.accountEnabled -eq $false) {
        if (-not (Invoke-GraphWrite -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$($user.id)" -Body @{accountEnabled=$true})) {
            throw "Entra account restore failed: $script:LastWriteError"
        }
    }
    elseif ($user.accountEnabled -ne $true) { throw 'Cloud account state is unknown. Verify manually.' }
    $verified=Get-GraphUser $UPN
    if (-not $verified -or $verified.id -ne $script:ExpectedUserId -or $verified.accountEnabled -ne $true) {
        throw 'Entra account enable was not verified. Check current state before retrying.'
    }
    Add-Action 'Identity' 'Restore Entra account' 'Completed' 'Enabled state verified'
    Write-Ok 'Entra account enabled'
    $global:FieldKitIRSession.Recovery=@{Completed=Get-Date;UserId=$script:ExpectedUserId;Status='Access restored; monitoring required'}
    $script:RecoverySucceeded=$true
    Write-IRLine ''
    Write-IRLine 'STATUS: ACCOUNT ENABLED' -ForegroundColor Green
    Write-IRLine 'User sign-in with MFA still needs validation.'
    Write-IRLine 'Identity, remediation, and MFA readiness confirmed by the operator.'
    Write-IRTicketSummary

    Write-IRLine "`nCOMPLETED: $((Get-Date).ToString('MM/dd/yyyy HH:mm'))"
    Section 'NEXT STEP'
    Write-IRLine 'Verify user sign-in with MFA.'
    Write-IRLine 'Run the final assessment and monitor for new suspicious activity for 48 hours.'
}
catch {
    Write-Fail "Recovery incomplete: $(Get-ShortError $_)"
    foreach ($item in $script:ActionLog) { Write-IRLine "$($item.Action): $($item.Result)" }
    foreach ($gap in $script:DataGaps) { Write-Warn $gap }
    if ($script:AdChanged) { Write-Warn 'AD may already be enabled. Verify AD and Entra state before retrying.' }
    Section 'NEXT STEP'
    Write-IRLine 'BEC-RECOVER-VALIDATE'
    Write-IRLine 'Resolve the reported items, then finish recovery. Do not assume access was fully restored.'
}
finally {
    if ($null -ne $script:OriginalTitle) { try { $Host.UI.RawUI.WindowTitle=$script:OriginalTitle } catch {} }
}
if ($script:RecoverySucceeded) {
    Invoke-IRNextStep -FileName 'BEC-RISK-ASSESSMENT' -Objective 'Next: rerun the read-only assessment for fresh account and mailbox checks.'
}
else { Invoke-IRNextStep -FileName '' -Objective '' }
