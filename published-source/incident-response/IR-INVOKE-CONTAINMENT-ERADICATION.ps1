<#PSScriptInfo
.VERSION 0.1.1
.GUID d6441bc3-67ed-412b-bd3c-080a2ea6ef45
.AUTHOR FIELD // KIT
.DESCRIPTION Selective containment and eradication candidate; controlled testing required.
#>
<#
.SYNOPSIS
IR: Contain and Eradicate
.DESCRIPTION
Makes only selected and explicitly confirmed changes to one M365 identity/mailbox.
Synced identity changes use the matching AD SID, never a name-only match or cloud fallback.
Requires an explicitly supplied and validated Entra Connect server for AD identity changes.
No password generation, display, clipboard copy, or export. No automatic module installs.
Run in a fresh Windows PowerShell 5.1 or PowerShell 7 window, global Microsoft cloud only.
.PARAMETER UPN
Target user principal name. Prompts if omitted.
.PARAMETER Tenant
Expected tenant GUID or verified domain. Prompts if omitted.
.PARAMETER SyncServer
Entra Connect host for hybrid identity changes. Prompts only when those actions are selected.
.PARAMETER SkipExchange
Allow identity/session/OAuth work without Exchange. Mailbox actions are unavailable.
.PARAMETER NoPause
Suppress Enter to exit. Does not suppress any action confirmation.
.NOTES
Candidate 0.1.1, adapted from response v1.1. No implicit handoff to recovery.
Requires Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+.
#>

[CmdletBinding()]
param(
    [string]$UPN,
    [string]$SyncServer,
    [string]$Tenant,
    [switch]$SkipExchange,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'
$script:DataGaps = New-Object System.Collections.ArrayList
$script:ActionLog = New-Object System.Collections.ArrayList
$script:AdChanged = $false
$script:SyncResult = 'Not required'
$script:ResolvedSyncServer = ''
$script:ExpectedTenantId = ''
$script:ExpectedUserId = ''
$script:ExpectedUpn = ''
$script:ExpectedSid = ''
$script:ExpectedSynced = $false
$script:GraphOpened = $false
$script:ResponseExoConnections = @()
$script:OriginalTitle = $null
$script:Phase = 'Discovery'
$script:ContainmentBlocked = $false

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Write-Section {
    param([string]$Title)

    Write-Host $Title -ForegroundColor Cyan
}



function Section([string]$Title) {
    Write-Host ''
    Write-Host $Title -ForegroundColor Cyan
}

function Write-ResourceFooter {
    param([datetime]$Completed)
    Write-Host "COMPLETED: $($Completed.ToString('MM/dd/yyyy HH:mm'))" -ForegroundColor Cyan
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
    if (-not $NoPause) { try { [void](Read-Host 'Press Enter to exit') } catch {} }
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
    try { Import-Module $available.Path -ErrorAction Stop; return $true }
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
    $parameters = @{ TenantId=$Tenant; Scopes=$Scopes; ContextScope='Process'; NoWelcome=$true; ErrorAction='Stop' }
    Connect-MgGraph @parameters | Out-Null
    $script:GraphOpened = $true
    $context = Get-MgContext -ErrorAction Stop
    if (-not $context -or $context.AuthType -ne 'Delegated' -or $context.ContextScope -ne 'Process' -or
        $context.Environment -ne 'Global' -or -not (Test-ScopesPresent $context $Scopes)) {
        throw 'Graph context or required consent could not be validated.'
    }
    $guid = [guid]::Empty
    if ([guid]::TryParse($Tenant, [ref]$guid)) {
        if ([string]$context.TenantId -ne $guid.ToString()) { throw 'Graph tenant mismatch.' }
    }
    else {
        $domains = Get-GraphCollection -Uri 'https://graph.microsoft.com/v1.0/domains?$select=id,isVerified' -Name 'Tenant domains'
        if (-not $domains.Success -or -not @($domains.Items | Where-Object { $_.isVerified -and $_.id -eq $Tenant }).Count) {
            throw 'Requested domain is not verified in the connected tenant.'
        }
    }
    $target = Get-GraphUser $UserPrincipalName
    if (-not $target) { throw 'Target user could not be uniquely resolved.' }
    $script:ExpectedTenantId = [string]$context.TenantId
    $script:ExpectedUserId = [string]$target.id
    $script:ExpectedUpn = [string]$target.userPrincipalName
    $script:ExpectedSid = [string]$target.onPremisesSecurityIdentifier
    $script:ExpectedSynced = $target.onPremisesSyncEnabled -eq $true
    Write-Info "CONNECTED // $Tenant | $($context.Account)"
    return $target
}

function Get-TenantInfo {
    $result = Invoke-GraphGet -Uri 'https://graph.microsoft.com/v1.0/organization?$select=id,displayName' -Name 'Tenant organization lookup'
    if ($result -and @($result.value).Count -gt 0) { return @($result.value)[0] }
    return $null
}

function Connect-ExchangeForTarget {
    param([string]$Identity)
    if ($SkipExchange) { Add-DataGap 'Exchange checks and actions skipped.'; return $false }
    if (-not (Ensure-Module 'ExchangeOnlineManagement')) { return $false }
    try {
        if (@(Get-ConnectionInformation -ErrorAction Stop | Where-Object { $_.ModulePrefix -eq 'IRResponse' }).Count) {
            throw 'A response Exchange connection already exists. Use a fresh PowerShell window.'
        }
        try { Connect-ExchangeOnline -Prefix IRResponse -ShowBanner:$false -ErrorAction Stop | Out-Null }
        finally {
            $script:ResponseExoConnections = @(Get-ConnectionInformation -ErrorAction Stop | Where-Object { $_.ModulePrefix -eq 'IRResponse' })
        }
        Assert-ResponseContext -Exchange
        Write-Ok 'Exchange tenant and mailbox matched'
        return $true
    }
    catch { Add-DataGap "Exchange unavailable: $(Get-ShortError $_)"; return $false }
}

function Assert-ResponseContext {
    param([switch]$Exchange)
    $context = Get-MgContext -ErrorAction Stop
    if (-not $context -or [string]$context.TenantId -ne $script:ExpectedTenantId -or $context.AuthType -ne 'Delegated') {
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
            Where-Object { $_.ModulePrefix -eq 'IRResponse' -and $_.State -eq 'Connected' })
        if ($connections.Count -ne 1 -or [string]$connections[0].TenantID -ne $script:ExpectedTenantId) {
            throw 'Exchange tenant could not be matched to Graph.'
        }
        $mailbox = Get-IRResponseMailbox -Identity $script:ExpectedUpn -ErrorAction Stop
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

function Confirm-EradicationGate {
    param([string]$Identity)
    if ($script:ContainmentBlocked -or @($script:ActionLog | Where-Object { $_.Result -eq 'Failed' }).Count) {
        Write-Fail 'Cleanup blocked: selected containment or sync did not complete. Resolve it and rerun.'
        Add-Action 'Response' 'Eradication phase' 'Skipped' 'Selected containment incomplete'
        return $false
    }
    Write-Warn 'Cleanup removes selected persistence/access. It does not authorize recovery.'
    if (-not (Confirm-Exact "ERADICATE $Identity")) {
        Add-Action 'Response' 'Eradication phase' 'Skipped' 'Phase confirmation not entered'
        return $false
    }
    return $true
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

function Disable-AdUser {
    param($AdUser)
    try {
        Assert-AdTarget $AdUser
        $current = [int]$AdUser.Entry.Properties['userAccountControl'].Value
        $AdUser.Entry.Properties['userAccountControl'].Value = ($current -bor 2)
        $AdUser.Entry.CommitChanges()
        $script:AdChanged = $true
        $AdUser.Entry.RefreshCache(@('userAccountControl'))
        if (([int]$AdUser.Entry.Properties['userAccountControl'].Value -band 2) -eq 0) { throw 'AD disable was not verified.' }
        Add-Action 'Identity' 'Disable Active Directory account' 'Completed' $AdUser.UPN
        Write-Ok 'Active Directory account disabled'
        return $true
    }
    catch {
        Add-Action 'Identity' 'Disable Active Directory account' 'Failed' (Get-ShortError $_)
        Write-Fail 'Active Directory account disable failed'
        return $false
    }
}

function Convert-SecureStringToPlainText {
    param([Security.SecureString]$SecureString)
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try { return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
}

function Read-ConfirmedPassword {
    Write-Host ''
    Write-Host 'Enter an approved response password. It will not be printed or logged.'
    $firstSecure = Read-Host 'Response password' -AsSecureString
    $secondSecure = Read-Host 'Confirm response password' -AsSecureString
    $first = Convert-SecureStringToPlainText $firstSecure
    $second = Convert-SecureStringToPlainText $secondSecure
    if ($first -ne $second) {
        Write-Fail 'Passwords did not match'
        return $null
    }
    if ([string]::IsNullOrWhiteSpace($first)) {
        Write-Fail 'Password was blank'
        return $null
    }
    return $first
}

function Set-AdUserPassword {
    param($AdUser, [string]$Password)
    try {
        Assert-AdTarget $AdUser
        $AdUser.Entry.Invoke('SetPassword', $Password) | Out-Null
        $script:AdChanged = $true
        $AdUser.Entry.Properties['pwdLastSet'].Value = 0
        $AdUser.Entry.CommitChanges()
        $script:AdChanged = $true
        Add-Action 'Identity' 'Reset Active Directory password' 'Completed' 'Force change at next sign-in'
        Write-Ok 'Active Directory password reset'
        return $true
    }
    catch {
        Add-Action 'Identity' 'Reset Active Directory password' 'Failed' 'Password operation failed or was not fully applied; validate AD before retrying.'
        Write-Fail 'Active Directory password reset failed'
        return $false
    }
}

function Set-CloudUserPassword {
    param($GraphUser, [string]$Password)
    $body = @{ passwordProfile = @{ password = $Password; forceChangePasswordNextSignIn = $true } }
    if (Invoke-GraphWrite -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$($GraphUser.id)" -Body $body) {
        Add-Action 'Identity' 'Reset Entra ID password' 'Completed' 'Force change at next sign-in'
        Write-Ok 'Entra ID password reset'
        return $true
    }
    Add-Action 'Identity' 'Reset Entra ID password' 'Failed' $script:LastWriteError
    Write-Fail 'Entra ID password reset failed'
    return $false
}

function Get-SyncServerForTarget {
    param([string]$UserPrincipalName, [string]$ExplicitServer)
    if (-not [string]::IsNullOrWhiteSpace($ExplicitServer)) { return $ExplicitServer.Trim() }
    return ''
}

function Test-EntraConnectServer {
    param([string]$Server)
    $script:SyncPreflightError = ''
    if ([string]::IsNullOrWhiteSpace($Server)) {
        $script:SyncPreflightError = 'No Entra Connect server was supplied; no connection was attempted.'
        return $false
    }
    try {
        Invoke-Command -ComputerName $Server -ScriptBlock {
            Import-Module ADSync -ErrorAction Stop
            Get-Command Start-ADSyncSyncCycle -ErrorAction Stop | Out-Null
        } -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        $script:SyncPreflightError = "Cannot validate Entra Connect on ${Server}: $(Get-ShortError $_)"
        return $false
    }
}

function Invoke-DeltaSyncOnce {
    if (-not $script:AdChanged) { $script:SyncResult='Not required'; return }
    try {
        if (-not $script:ResolvedSyncServer) { throw 'Validated sync server unavailable.' }
        $result = Invoke-Command -ComputerName $script:ResolvedSyncServer -ScriptBlock {
            Import-Module ADSync -ErrorAction Stop
            Start-ADSyncSyncCycle -PolicyType Delta -ErrorAction Stop
        } -ErrorAction Stop
        if (-not $result -or [string]$result.Result -ne 'Success') { throw 'Delta sync start was not acknowledged as Success.' }
        $script:SyncResult='Requested; cloud convergence still requires validation'
        Add-Action 'Sync' 'Request Entra Connect delta sync' 'Completed' $script:SyncResult
        Write-Ok 'Delta sync requested; this does not prove cloud convergence'
    }
    catch {
        $script:SyncResult='Failed or unverified'
        Add-Action 'Sync' 'Request Entra Connect delta sync' 'Failed' (Get-ShortError $_)
        Write-Fail 'Sync request failed or could not be verified. Validate the sync server before recovery.'
    }
}

function Revoke-UserSessions {
    param($GraphUser)
    if (Invoke-GraphWrite -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$($GraphUser.id)/revokeSignInSessions" -Body $null) {
        Add-Action 'Sessions' 'Revoke active sessions' 'Completed' 'Request accepted; invalidation may be delayed'
        Write-Ok 'Session revocation request accepted'
        return $true
    }
    Add-Action 'Sessions' 'Revoke active sessions' 'Failed' $script:LastWriteError
    Write-Fail 'Session revocation failed'
    return $false
}

function Disable-UserAccount {
    param($GraphUser, $AdUser)
    if ($GraphUser.onPremisesSyncEnabled -eq $true) {
        if (-not $AdUser) {
            Add-Action 'Identity' 'Disable account' 'Failed' 'Synced user could not be resolved in Active Directory'
            Write-Fail 'Synced user could not be resolved in Active Directory. Entra ID was not modified.'
            return $false
        }
        return Disable-AdUser $AdUser
    }
    if (Invoke-GraphWrite -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$($GraphUser.id)" -Body @{ accountEnabled = $false }) {
        $verified = Get-GraphUser $GraphUser.userPrincipalName
        if (-not $verified -or $verified.id -ne $GraphUser.id -or $verified.accountEnabled -ne $false) {
            Add-Action 'Identity' 'Disable Entra ID account' 'Failed' 'Write accepted but disabled state not verified; review before retrying'
            Write-Fail 'Account disable not yet verified'
            return $false
        }
        Add-Action 'Identity' 'Disable Entra ID account' 'Completed' 'accountEnabled=false verified'
        Write-Ok 'Entra ID account disabled'
        return $true
    }
    Add-Action 'Identity' 'Disable Entra ID account' 'Failed' $script:LastWriteError
    Write-Fail 'Entra ID account disable failed'
    return $false
}

function Reset-UserPassword {
    param($GraphUser, $AdUser)
    $password = Read-ConfirmedPassword
    if ($null -eq $password) { Add-Action 'Identity' 'Reset password' 'Skipped' 'Password entry cancelled or invalid'; return $false }
    try {
        if ($GraphUser.onPremisesSyncEnabled -eq $true) {
            if (-not $AdUser) {
                Add-Action 'Identity' 'Reset password' 'Failed' 'Synced user could not be resolved in Active Directory'
                Write-Fail 'Synced user could not be resolved in Active Directory. Cloud password reset was not attempted.'
                return $false
            }
            return Set-AdUserPassword -AdUser $AdUser -Password $password
        }
        return Set-CloudUserPassword -GraphUser $GraphUser -Password $password
    }
    finally { $password = $null }
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
    try { $raw = @(Get-IRResponseInboxRule -Mailbox $Identity -IncludeHidden -ErrorAction Stop) }
    catch {
        try {
            $raw = @(Get-IRResponseInboxRule -Mailbox $Identity -ErrorAction Stop)
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
    try { return Get-IRResponseMailbox -Identity $Identity -ErrorAction Stop }
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
        if (Get-Command Get-IRResponseMailboxPermission -ErrorAction SilentlyContinue) {
            $items = @(Get-IRResponseMailboxPermission -Identity $Identity -ErrorAction Stop | Where-Object { $_.User -notlike 'NT AUTHORITY\SELF' -and $_.IsInherited -eq $false -and $_.Deny -ne $true -and $_.AccessRights -contains 'FullAccess' })
        }
        else { throw 'Required Exchange permission read command is unavailable.' }
        foreach ($item in $items) { [void]$fullAccess.Add([pscustomobject]@{ Display=[string]$item.User; Raw=[string]$item.User }) }
    }
    catch { Add-DataGap "Full Access lookup unavailable: $(Get-ShortError $_)" }

    try {
        $items = @()
        if (Get-Command Get-IRResponseRecipientPermission -ErrorAction SilentlyContinue) {
            $items = @(Get-IRResponseRecipientPermission -Identity $Identity -ErrorAction Stop | Where-Object { $_.Trustee -notlike 'NT AUTHORITY\SELF' -and $_.AccessRights -contains 'SendAs' })
        }
        else { throw 'Required Exchange permission read command is unavailable.' }
        foreach ($item in $items) { [void]$sendAs.Add([pscustomobject]@{ Display=[string]$item.Trustee; Raw=[string]$item.Trustee }) }
    }
    catch { Add-DataGap "Send As lookup unavailable: $(Get-ShortError $_)" }

    try {
        $cas = Get-IRResponseCASMailbox -Identity $Identity -ErrorAction Stop
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

function Convert-SelectionToNumbers {
    param([string]$InputText, [int]$Maximum)
    $numbers = New-Object System.Collections.ArrayList
    if ([string]::IsNullOrWhiteSpace($InputText)) { return @() }
    foreach ($token in ($InputText -split ',')) {
        $number = 0
        if ([int]::TryParse($token.Trim(), [ref]$number) -and $number -ge 1 -and $number -le $Maximum -and -not $numbers.Contains($number)) { [void]$numbers.Add($number) }
    }
    return @($numbers | Sort-Object)
}

function Select-Items {
    param(
        [object[]]$Items,
        [string]$Prompt
    )
    if (-not $Items -or $Items.Count -eq 0) { return @() }
    $answer = Read-Host "$Prompt (comma-separated, A=all, N=none)"
    if ($answer.Trim().ToUpper() -eq 'A') { return @($Items) }
    if ($answer.Trim().ToUpper() -eq 'N') { return @() }
    $numbers = Convert-SelectionToNumbers -InputText $answer -Maximum $Items.Count
    $selected = New-Object System.Collections.ArrayList
    foreach ($number in $numbers) { [void]$selected.Add($Items[$number - 1]) }
    return @($selected)
}

function Confirm-Exact {
    param([string]$Required)
    while ($true) {
        $value = Read-Host "Type $Required to continue"
        if ([string]::IsNullOrWhiteSpace($value) -or $value.Trim() -ieq 'N') { return $false }
        if ($value.Trim() -ieq $Required) { return $true }
        Write-Warn "Not confirmed. Enter the full phrase including the target: $Required"
        Write-Host 'Press Enter or type N to cancel.'
    }
}

function Remove-SelectedRules {
    param([object[]]$Rules, [string]$Identity)
    if ($Rules.Count -eq 0) { Add-Action 'Mailbox Persistence' 'Remove inbox rules' 'Skipped' 'No rules selected'; return }
    Write-Warn 'Exchange PowerShell rule changes can remove Outlook client-side rule data. Confirm the exact rules below.'
    foreach ($rule in $Rules) { Write-Host "- $($rule.Name) | Hidden: $($rule.Hidden) | Action: $($rule.Actions -join ', ') | Target: $($rule.Targets -join ', ')" }
    if (-not (Confirm-Exact "REMOVE RULES $Identity")) { Add-Action 'Mailbox Persistence' 'Remove inbox rules' 'Skipped' 'Typed confirmation not entered'; return }
    foreach ($rule in $Rules) {
        try {
            Assert-ResponseContext -Exchange; Remove-IRResponseInboxRule -Mailbox $Identity -Identity $rule.Identity -Confirm:$false -ErrorAction Stop
            Add-Action 'Mailbox Persistence' 'Remove inbox rule' 'Completed' "$($rule.Name) | $($rule.Actions -join ', ')"
            Write-Ok "Removed inbox rule: $($rule.Name)"
        }
        catch {
            Add-Action 'Mailbox Persistence' 'Remove inbox rule' 'Failed' "$($rule.Name) | $(Get-ShortError $_)"
            Write-Fail "Failed to remove inbox rule: $($rule.Name)"
        }
    }
}

function Clear-MailboxForwarding {
    param([string]$Identity, $MailboxState)
    if ($MailboxState.Forwarding.Count -eq 0) { Add-Action 'Mailbox Persistence' 'Clear mailbox forwarding' 'Skipped' 'No mailbox forwarding returned'; return }
    Write-Host 'Current mailbox forwarding:'
    foreach ($item in $MailboxState.Forwarding) { Write-Host "- $item" }
    if (-not (Confirm-Exact "CLEAR FORWARDING $Identity")) { Add-Action 'Mailbox Persistence' 'Clear mailbox forwarding' 'Skipped' 'Typed confirmation not entered'; return }
    try {
        Assert-ResponseContext -Exchange; Set-IRResponseMailbox -Identity $Identity -ForwardingAddress $null -ForwardingSmtpAddress $null -DeliverToMailboxAndForward $false -ErrorAction Stop
        Add-Action 'Mailbox Persistence' 'Clear mailbox forwarding' 'Completed' ($MailboxState.Forwarding -join '; ')
        Write-Ok 'Mailbox forwarding cleared'
    }
    catch {
        Add-Action 'Mailbox Persistence' 'Clear mailbox forwarding' 'Failed' (Get-ShortError $_)
        Write-Fail 'Mailbox forwarding removal failed'
    }
}

function Remove-SelectedOAuth {
    param([object[]]$Items, [string]$Identity)
    if ($Items.Count -eq 0) { Add-Action 'OAuth' 'Remove user-specific OAuth consent' 'Skipped' 'No grants selected'; return }
    foreach ($item in $Items) { Write-Host "- $($item.App) | $($item.Publisher) | Scope: $($item.Scope)" }
    Write-Warn 'This removes user-specific delegated consent only. Tenant-wide admin consent is not included.'
    if (-not (Confirm-Exact "REMOVE OAUTH $Identity")) { Add-Action 'OAuth' 'Remove user-specific OAuth consent' 'Skipped' 'Typed confirmation not entered'; return }
    foreach ($item in $Items) {
        if (Invoke-GraphWrite -Method DELETE -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants/$($item.Id)" -Body $null) {
            Add-Action 'OAuth' 'Remove user-specific OAuth consent' 'Completed' "$($item.App) | $($item.Scope)"
            Write-Ok "Removed OAuth consent: $($item.App)"
        }
        else {
            Add-Action 'OAuth' 'Remove user-specific OAuth consent' 'Failed' "$($item.App) | $script:LastWriteError"
            Write-Fail "Failed to remove OAuth consent: $($item.App)"
        }
    }
}

function Get-MailboxAccessItems {
    param($MailboxState)
    $items = New-Object System.Collections.ArrayList
    foreach ($entry in $MailboxState.FullAccess) { [void]$items.Add([pscustomobject]@{ Type='Full Access'; Display=$entry.Display; Raw=$entry.Raw }) }
    foreach ($entry in $MailboxState.SendAs) { [void]$items.Add([pscustomobject]@{ Type='Send As'; Display=$entry.Display; Raw=$entry.Raw }) }
    foreach ($entry in $MailboxState.SendOnBehalf) { [void]$items.Add([pscustomobject]@{ Type='Send On Behalf'; Display=$entry.Display; Raw=$entry.Raw }) }
    return @($items)
}

function Remove-SelectedMailboxAccess {
    param([object[]]$Items, [string]$Identity)
    if ($Items.Count -eq 0) { Add-Action 'Mailbox Access' 'Remove mailbox access' 'Skipped' 'No access entries selected'; return }
    foreach ($item in $Items) { Write-Host "- $($item.Type): $($item.Display)" }
    if (-not (Confirm-Exact "REMOVE ACCESS $Identity")) { Add-Action 'Mailbox Access' 'Remove mailbox access' 'Skipped' 'Typed confirmation not entered'; return }
    foreach ($item in $Items) {
        try {
            switch ($item.Type) {
                'Full Access' { Assert-ResponseContext -Exchange; Remove-IRResponseMailboxPermission -Identity $Identity -User $item.Raw -AccessRights FullAccess -Confirm:$false -ErrorAction Stop }
                'Send As' { Assert-ResponseContext -Exchange; Remove-IRResponseRecipientPermission -Identity $Identity -Trustee $item.Raw -AccessRights SendAs -Confirm:$false -ErrorAction Stop }
                'Send On Behalf' { Assert-ResponseContext -Exchange; Set-IRResponseMailbox -Identity $Identity -GrantSendOnBehalfTo @{ remove = $item.Raw } -ErrorAction Stop }
            }
            Add-Action 'Mailbox Access' "Remove $($item.Type)" 'Completed' $item.Display
            Write-Ok "Removed $($item.Type): $($item.Display)"
        }
        catch {
            Add-Action 'Mailbox Access' "Remove $($item.Type)" 'Failed' "$($item.Display) | $(Get-ShortError $_)"
            Write-Fail "Failed to remove $($item.Type): $($item.Display)"
        }
    }
}

function Disable-LegacyAuthentication {
    param([string]$Identity, [string[]]$EnabledProtocols)
    if ($EnabledProtocols.Count -eq 0) { Add-Action 'Legacy Authentication' 'Disable legacy authentication' 'Skipped' 'No enabled mailbox protocols returned'; return }
    if (-not (Confirm-Exact "DISABLE LEGACY $Identity")) { Add-Action 'Legacy Authentication' 'Disable legacy authentication' 'Skipped' 'Typed confirmation not entered'; return }
    try {
        Assert-ResponseContext -Exchange; Set-IRResponseCASMailbox -Identity $Identity -ImapEnabled $false -PopEnabled $false -SmtpClientAuthenticationDisabled $true -ErrorAction Stop
        Add-Action 'Legacy Authentication' 'Disable legacy authentication' 'Completed' ($EnabledProtocols -join ', ')
        Write-Ok 'IMAP, POP, and Authenticated SMTP disabled at mailbox level'
    }
    catch {
        Add-Action 'Legacy Authentication' 'Disable legacy authentication' 'Failed' (Get-ShortError $_)
        Write-Fail 'Legacy authentication disable failed'
    }
}

function Write-ActionSection {
    param([string]$Result)
    Write-Section ("ACTIONS " + $Result.ToUpper())
    $items = @($script:ActionLog | Where-Object { $_.Result -eq $Result })
    if ($items.Count -eq 0) { Write-Host '- None'; return }
    foreach ($item in $items) { Write-Host "- $($item.Action): $($item.Detail)" }
}

try {
    Enable-Tls12
    try { $script:OriginalTitle=$Host.UI.RawUI.WindowTitle; $Host.UI.RawUI.WindowTitle='IR: Contain and Eradicate' } catch {}

    Write-Host 'IR: Contain and Eradicate // MAKES CHANGES' -ForegroundColor Cyan
    Write-Host 'Selective containment and persistence removal for one confirmed user.'
    Write-Host ''
    if ([string]::IsNullOrWhiteSpace($UPN)) { $UPN = (Read-Host 'UPN').Trim() }
    if ([string]::IsNullOrWhiteSpace($UPN)) { throw 'UPN is required.' }

    if ($UPN -notmatch '^[^\s@]+@[^\s@]+$') { throw 'Enter one valid target UPN.' }
    if ([string]::IsNullOrWhiteSpace($Tenant)) { $Tenant=(Read-Host 'Tenant domain or tenant ID').Trim() }
    if ($Tenant -notmatch '^[a-zA-Z0-9][a-zA-Z0-9.-]+$' -or $Tenant -in @('common','organizations','consumers')) { throw 'Enter a specific tenant domain or GUID.' }
    $exoOk = $false

    $scopes = @(
        'User.Read.All',
        'User.RevokeSessions.All','User.EnableDisableAccount.All','User-PasswordProfile.ReadWrite.All',
        'Directory.Read.All','DelegatedPermissionGrant.ReadWrite.All'
    )
    $user = Connect-GraphForTarget -UserPrincipalName $UPN -Scopes $scopes
    if (-not $user) {
        Write-Fail 'Target could not be safely resolved. No action was performed.'
        foreach ($gap in $script:DataGaps) { Write-Host "- $gap" }
        return
    }

    $context = Get-MgContext -ErrorAction SilentlyContinue
    $tenantInfo = Get-TenantInfo
    if (-not $tenantInfo -or -not $tenantInfo.id) {
        Write-Fail 'Tenant identity could not be validated. No action was performed.'
        Add-DataGap 'Tenant organization lookup did not return a tenant ID.'
        foreach ($gap in $script:DataGaps) { Write-Host "- $gap" }
        return
    }
    $tenantName = if ($tenantInfo.displayName) { [string]$tenantInfo.displayName } else { 'Not available' }
    $tenantId = [string]$tenantInfo.id
    if ($context -and $context.TenantId -and ([string]$context.TenantId -ne $tenantId)) {
        Write-Fail 'Graph context and organization lookup returned different tenant IDs. No action was performed.'
        return
    }
    $accountSource = if ($user.onPremisesSyncEnabled -eq $true) { 'Active Directory' } else { 'Entra ID' }
    $accountStatus = if ($user.accountEnabled -eq $true) { 'Enabled' } elseif ($user.accountEnabled -eq $false) { 'Disabled' } else { 'Unknown' }
    $operator = if ($env:USERNAME) { $env:USERNAME } else { [Environment]::UserName }

    $adUser = $null
    if ($user.onPremisesSyncEnabled -eq $true) {
        $script:ResolvedSyncServer = Get-SyncServerForTarget `
            -UserPrincipalName $UPN `
            -ExplicitServer $SyncServer
        $adUser = Find-AdUser $user
        if (-not $adUser) { Add-DataGap 'Synced user could not be resolved in Active Directory. Identity changes are blocked.' }
    }

    $exoOk = Connect-ExchangeForTarget -Identity $UPN

    $ruleItems = @()
    $mailboxState = [pscustomobject]@{ Mailbox=$null; Forwarding=@(); FullAccess=@(); SendAs=@(); SendOnBehalf=@(); Legacy=@() }
    if ($exoOk) {
        $ruleItems = @(Get-InboxRuleItems $UPN)
        $mailboxState = Get-MailboxState $UPN
    }
    $oauthItems = @(Get-OAuthItems $user)
    $accessItems = @(Get-MailboxAccessItems $mailboxState)

    Section 'TARGET'
    Write-Host "UPN: $($user.userPrincipalName)"
    Write-Host "Status: $accountStatus"
    Write-Host "Account Source: $accountSource"

    if ($adUser) {
        Write-Host "AD User: $($adUser.DisplayName) <$($adUser.UPN)>"
        Write-Host "AD Status: $(if (Test-AdUserDisabled $adUser) { 'Disabled' } else { 'Enabled' })"
    }

    $highRiskRules = @(
        $ruleItems |
        Where-Object { $_.HighRisk }
    )

    $visibleHighRiskRules = @(
        $highRiskRules |
        Where-Object { -not $_.Hidden }
    )

    $hiddenHighRiskRules = @(
        $highRiskRules |
        Where-Object { $_.Hidden }
    )

    Section 'INBOX RULES - VISIBLE'

    if ($visibleHighRiskRules.Count -gt 0) {
        Write-Host 'Status: Yes'

        foreach ($rule in $visibleHighRiskRules) {
            Write-Host "Rule: $($rule.Name)"
            Write-Host ("Action: {0}" -f ($rule.Actions -join '; '))

            if ($rule.Targets.Count -gt 0) {
                Write-Host ("Target: {0}" -f ($rule.Targets -join '; '))
            }
        }
    }
    elseif ($exoOk) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available'
    }

    Section 'INBOX RULES - HIDDEN'

    if ($hiddenHighRiskRules.Count -gt 0) {
        Write-Host 'Status: Yes'

        foreach ($rule in $hiddenHighRiskRules) {
            Write-Host "Rule: $($rule.Name)"
            Write-Host ("Action: {0}" -f ($rule.Actions -join '; '))

            if ($rule.Targets.Count -gt 0) {
                Write-Host ("Target: {0}" -f ($rule.Targets -join '; '))
            }
        }
    }
    elseif ($exoOk) {
        Write-Host 'Status: No suspicious rules'
    }
    else {
        Write-Host 'Status: Not available'
    }

    Section 'EXTERNAL FORWARDING'
    if ($mailboxState.Forwarding.Count -gt 0) {
        Write-Host 'Status: Yes'

        foreach ($item in $mailboxState.Forwarding) {
            Write-Host ("Target: {0}" -f $item)
        }
    }
    elseif ($exoOk) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available'
    }

    $sensitiveOAuth = @(
        $oauthItems |
        Where-Object {
            $_.Sensitive -and
            $_.Publisher -eq 'Unverified publisher'
        }
    )

    if ($script:DataGaps.Count) { Write-Warn 'Some checks are unavailable. Empty lists below are not proof of absence; see review items.' }
    Section 'UNVERIFIED OAUTH GRANTS'
    if ($sensitiveOAuth.Count -gt 0) {
        Write-Host 'Status: Yes'

        foreach ($item in $sensitiveOAuth) {
            Write-Host "App: $($item.App)"
            Write-Host "Scope: $($item.Scope)"
        }
    }
    else {
        Write-Host 'Status: No'
    }

    Section 'MAILBOX PERMISSIONS'
    if ($accessItems.Count -gt 0) {
        Write-Host 'Status: Yes'

        foreach ($item in $accessItems) {
            Write-Host ("{0}: {1}" -f $item.Type, $item.Display)
        }
    }
    elseif ($exoOk) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available'
    }

    Section 'LEGACY AUTH'
    if ($mailboxState.Legacy.Count -gt 0) {
        Write-Host 'Status: Yes'

        foreach ($item in $mailboxState.Legacy) {
            Write-Host $item
        }
    }
    elseif ($exoOk) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available'
    }

    Write-Host ''
    Write-Section 'AVAILABLE RESPONSE ACTIONS'
    Write-Host '[1] Revoke Active Sessions'
    Write-Host '[2] Disable Account'
    Write-Host '[3] Reset Password'
    Write-Host '[4] Remove Mailbox Rules / Forwarding'
    Write-Host '[5] Remove User-Specific OAuth Consent'
    Write-Host '[6] Remove Mailbox Access'
    Write-Host '[7] Disable Legacy Authentication'
    Write-Host '[N] No changes'
    Write-Host ''
    Write-Host 'Actions execute in a fixed safe order regardless of selection order.'
    Write-Host 'Select session revocation again only if another revocation is intended.'
    $selectionText = Read-Host 'Select approved actions (example: 1,2,3,4)'
    if ($selectionText.Trim().ToUpper() -eq 'N' -or [string]::IsNullOrWhiteSpace($selectionText)) {
        Add-Action 'Response' 'Account response' 'Skipped' 'No actions selected'
    }
    else {
        $selections = @(Convert-SelectionToNumbers -InputText $selectionText -Maximum 7)
        if ($selections.Count -eq 0) {
            Add-Action 'Response' 'Account response' 'Skipped' 'No valid actions selected'
        }
        else {
            Write-Host ''
            Write-Section 'PLANNED ACTIONS'
            $labels = @{
                1='Revoke active sessions'; 2='Disable account'; 3='Reset password';
                4='Review/remove mailbox rules and forwarding'; 5='Review/remove user-specific OAuth consent';
                6='Review/remove mailbox access'; 7='Disable legacy authentication'
            }
            foreach ($number in $selections) { Write-Host "- $($labels[$number])" }
            if ($selections -contains 2 -and $selections -notcontains 1) { Write-Warn 'Account disable was selected without session revocation.' }
            if ($selections -contains 5 -and $selections -notcontains 1) { Write-Warn 'OAuth removal was selected without session revocation; existing access tokens can remain valid until expiry.' }
            Write-Host ''
            $validatedUser = Get-GraphUser $UPN
            if (-not $validatedUser -or [string]$validatedUser.id -ne [string]$user.id) {
                Write-Fail 'The target could not be revalidated immediately before response. No action was performed.'
                Add-Action 'Response' 'Account response' 'Failed' 'Target revalidation failed'
            }
            else {
                $user = $validatedUser
                if ($user.onPremisesSyncEnabled -eq $true) {
                    $validatedAdUser = Find-AdUser $user
                    $adUser = $validatedAdUser
                }

                $adChangeAllowed = $true

                if (
                    $user.onPremisesSyncEnabled -eq $true -and
                    (
                        $selections -contains 2 -or
                        $selections -contains 3
                    )
                ) {
                    if ([string]::IsNullOrWhiteSpace($script:ResolvedSyncServer)) {
                        $script:ResolvedSyncServer=(Read-Host 'Entra Connect server hostname (required for AD disable/reset; Enter skips those actions)').Trim()
                    }
                    if (
                        -not (Test-EntraConnectServer -Server $script:ResolvedSyncServer)
                    ) {
                        $adChangeAllowed = $false
                        Write-Warn $script:SyncPreflightError
                        Write-Warn 'Selected AD disable/reset actions are blocked.'
                        Write-Host 'Use the same Entra Connect hostname supplied to your working sync test; a domain name alone is not the server.'
                    }
                }

                if (-not (Confirm-Exact "RESPOND $($user.userPrincipalName)")) {
                    Add-Action 'Response' 'Account response' 'Skipped' 'Typed workflow confirmation not entered'
                }
                else {
                    $script:Phase = 'Containment'
                    if ($selections -contains 1) { [void](Revoke-UserSessions $user) }

                if ($selections -contains 2) {
                    if (
                        $user.onPremisesSyncEnabled -eq $true -and
                        -not $adChangeAllowed
                    ) {
                        Add-Action 'Identity' 'Disable account' 'Skipped' 'Entra sync preflight unavailable'
                    }
                    elseif (Confirm-Exact "DISABLE $($user.userPrincipalName)") {
                        [void](Disable-UserAccount -GraphUser $user -AdUser $adUser)
                    }
                    else {
                        Add-Action 'Identity' 'Disable account' 'Skipped' 'Typed confirmation not entered'
                    }
                }

                if ($selections -contains 3) {
                    if (
                        $user.onPremisesSyncEnabled -eq $true -and
                        -not $adChangeAllowed
                    ) {
                        Add-Action 'Identity' 'Reset password' 'Skipped' 'Entra sync preflight unavailable'
                    }
                    elseif (Confirm-Exact "RESET $($user.userPrincipalName)") {
                        [void](Reset-UserPassword -GraphUser $user -AdUser $adUser)
                    }
                    else {
                        Add-Action 'Identity' 'Reset password' 'Skipped' 'Typed confirmation not entered'
                    }
                }

                Invoke-DeltaSyncOnce
                $cleanupSelected = @($selections | Where-Object { $_ -ge 4 }).Count -gt 0
                $cleanupAllowed = $false
                if ($cleanupSelected) { $cleanupAllowed = Confirm-EradicationGate $UPN }
                $script:Phase = 'Eradication'

                if ($cleanupAllowed -and $selections -contains 4) {
                    if (-not $exoOk) { Add-Action 'Mailbox Persistence' 'Mailbox persistence removal' 'Failed' 'Exchange Online unavailable' }
                    else {
                        if ($ruleItems.Count -gt 0) {
                            Write-Host ''
                            Write-Section 'INBOX RULE SELECTION'
                            for ($i=0; $i -lt $ruleItems.Count; $i++) {
                                $rule = $ruleItems[$i]
                                Write-Host "[$($i+1)] $($rule.Name) | Hidden: $($rule.Hidden) | Action: $($rule.Actions -join ', ') | Target: $($rule.Targets -join ', ')"
                            }
                            $selectedRules = @(Select-Items -Items $ruleItems -Prompt 'Select rules to remove')
                            Remove-SelectedRules -Rules $selectedRules -Identity $UPN
                        }
                        else { Add-Action 'Mailbox Persistence' 'Remove inbox rules' 'Skipped' 'No non-default rules returned' }

                        if ($mailboxState.Forwarding.Count -gt 0) {
                            $clearForwarding = Read-Host 'Clear mailbox-level forwarding? [Y/N]'
                            if ($clearForwarding.Trim().ToUpper() -eq 'Y') { Clear-MailboxForwarding -Identity $UPN -MailboxState $mailboxState }
                            else { Add-Action 'Mailbox Persistence' 'Clear mailbox forwarding' 'Skipped' 'Operator did not select forwarding removal' }
                        }
                        else { Add-Action 'Mailbox Persistence' 'Clear mailbox forwarding' 'Skipped' 'No mailbox forwarding returned' }
                    }
                }

                if ($cleanupAllowed -and $selections -contains 5) {
                    if ($oauthItems.Count -gt 0) {
                        Write-Host ''
                        Write-Section 'OAUTH SELECTION'
                        for ($i=0; $i -lt $oauthItems.Count; $i++) {
                            $item = $oauthItems[$i]
                            Write-Host "[$($i+1)] $($item.App) | $($item.Publisher) | Scope: $($item.Scope)"
                        }
                        $selectedOAuth = @(Select-Items -Items $oauthItems -Prompt 'Select user-specific OAuth grants to remove')
                        Remove-SelectedOAuth -Items $selectedOAuth -Identity $UPN
                    }
                    else { Add-Action 'OAuth' 'Remove user-specific OAuth consent' 'Skipped' 'No grants returned' }
                }

                if ($cleanupAllowed -and $selections -contains 6) {
                    if (-not $exoOk) { Add-Action 'Mailbox Access' 'Remove mailbox access' 'Failed' 'Exchange Online unavailable' }
                    elseif ($accessItems.Count -gt 0) {
                        Write-Host ''
                        Write-Section 'MAILBOX ACCESS SELECTION'
                        for ($i=0; $i -lt $accessItems.Count; $i++) {
                            $item = $accessItems[$i]
                            Write-Host "[$($i+1)] $($item.Type): $($item.Display)"
                        }
                        $selectedAccess = @(Select-Items -Items $accessItems -Prompt 'Select mailbox access entries to remove')
                        Remove-SelectedMailboxAccess -Items $selectedAccess -Identity $UPN
                    }
                    else { Add-Action 'Mailbox Access' 'Remove mailbox access' 'Skipped' 'No access entries returned' }
                }

                    if ($cleanupAllowed -and $selections -contains 7) {
                        if (-not $exoOk) { Add-Action 'Legacy Authentication' 'Disable legacy authentication' 'Failed' 'Exchange Online unavailable' }
                        else { Disable-LegacyAuthentication -Identity $UPN -EnabledProtocols $mailboxState.Legacy }
                    }
                }
            }
        }
    }

    $refreshedUser = Get-GraphUser $UPN
    if (-not $refreshedUser -or $refreshedUser.id -ne $script:ExpectedUserId) { Add-DataGap 'Post-response target could not be validated.' }
    $postStatus = if ($refreshedUser -and $refreshedUser.accountEnabled -eq $true) { 'Enabled' } elseif ($refreshedUser -and $refreshedUser.accountEnabled -eq $false) { 'Disabled' } else { 'Not available' }
    $postRules = if ($exoOk) { @(Get-InboxRuleItems $UPN) } else { @() }
    $postMailboxState = if ($exoOk) { Get-MailboxState $UPN } else { [pscustomobject]@{ Forwarding=@(); FullAccess=@(); SendAs=@(); SendOnBehalf=@(); Legacy=@() } }
    $postOAuth = @(Get-OAuthItems $user)
    $postAccess = @(Get-MailboxAccessItems $postMailboxState)
    $currentAd = if ($user.onPremisesSyncEnabled -eq $true) { Find-AdUser $user } else { $null }
    $remainingHighRiskRules = @($postRules | Where-Object { $_.HighRisk -and $_.Enabled -eq 'Enabled' })
    $remainingSensitiveOAuth = @($postOAuth | Where-Object { $_.Sensitive -and $_.Publisher -eq 'Unverified publisher' })

    $failedCount = @($script:ActionLog | Where-Object { $_.Result -eq 'Failed' }).Count
    $completedCount = @($script:ActionLog | Where-Object { $_.Result -eq 'Completed' }).Count
    $status = 'PARTIAL RESPONSE COMPLETE'
    $recommendation = 'Review skipped items and validation results before deciding whether recovery is appropriate.'
    if ($failedCount -gt 0) {
        $status = 'RESPONSE COMPLETED WITH FAILURES'
        $recommendation = 'Escalate failed actions and do not proceed to recovery until the required response is complete.'
    }
    elseif ($script:DataGaps.Count -gt 0) {
        $status = 'RESPONSE VALIDATION INCOMPLETE'
        $recommendation = 'Resolve missing evidence and rerun validation before recovery.'
    }
    elseif ($remainingHighRiskRules.Count -gt 0 -or $postMailboxState.Forwarding.Count -gt 0 -or $remainingSensitiveOAuth.Count -gt 0) {
        $status = 'RESPONSE INCOMPLETE - PERSISTENCE REMAINS'
        $recommendation = 'Continue Account Response or complete manual GUI remediation before recovery.'
    }
    elseif ($user.onPremisesSyncEnabled -eq $true -and $currentAd -and (Test-AdUserDisabled $currentAd) -and $postStatus -ne 'Disabled') {
        $status = 'RESPONSE INCOMPLETE - CLOUD SYNC PENDING'
        $recommendation = 'AD is disabled but the cloud account is not verified disabled. Validate synchronization before recovery.'
    }
    elseif ($postStatus -eq 'Disabled') {
        $status = 'ACCOUNT CONTAINED - RECOVERY NOT YET AUTHORIZED'
        $recommendation = 'Verify the user, client authorization, endpoint posture, and remaining review items before Account Recovery.'
    }
    elseif ($completedCount -eq 0) {
        $status = 'NO RESPONSE ACTIONS COMPLETED'
        $recommendation = 'No actions were recorded as completed. Review evidence and the action log.'
    }

    Write-Host ''
    Write-Host "SUMMARY: $status" -ForegroundColor $(if ($failedCount) { 'Red' } else { 'Yellow' })
    Write-Host "ACTION: $recommendation"

    Write-Host ''
    Write-ActionSection 'Completed'
    Write-Host ''
    Write-ActionSection 'Failed'
    Write-Host ''
    Write-ActionSection 'Skipped'

    Write-Host ''
    Write-Section 'VALIDATION'
    Write-Host ("Entra Account: {0}" -f $postStatus)
    if ($user.onPremisesSyncEnabled -eq $true) {
        Write-Host (
            "AD Account: {0}" -f
            $(if ($currentAd) {
                if (Test-AdUserDisabled $currentAd) { 'Disabled' } else { 'Enabled' }
            }
            else { 'Not available' })
        )
        Write-Host ("Delta Sync: {0}" -f $script:SyncResult)
    }
    if ($script:DataGaps.Count) { Write-Warn 'Counts below are observed results only; unavailable checks are NOT verified clear.' }
    Write-Host ("Inbox Rules Remaining: {0}" -f $postRules.Count)
    Write-Host ("Forwarding Remaining: {0}" -f $postMailboxState.Forwarding.Count)
    Write-Host ("OAuth Grants Remaining: {0}" -f $postOAuth.Count)
    Write-Host ("Mailbox Access Remaining: {0}" -f $postAccess.Count)
    Write-Host ("Legacy Auth: {0}" -f $(if ($postMailboxState.Legacy.Count -gt 0) { $postMailboxState.Legacy -join '; ' } else { 'No' }))

    foreach ($rule in $postRules) {
        $hidden = if ($rule.Hidden) { ' [Hidden]' } else { '' }
        Write-Host ("Rule: {0}{1} | {2}" -f $rule.Name, $hidden, ($rule.Actions -join '; '))
    }

    if ($script:DataGaps.Count -gt 0) {
        Section 'REVIEW ITEMS'

        foreach ($gap in @($script:DataGaps | Select-Object -Unique)) {
            Write-Host ("- {0}" -f $gap)
        }
    }

    Section 'NEXT'
    if ($status -like 'ACCOUNT CONTAINED*') {
        Write-Host 'IR-INVOKE-RECOVERY-VALIDATION.ps1 (only after separate recovery authorization)'
    }
    elseif ($status -like 'RESPONSE*INCOMPLETE*' -or $status -like '*FAILURES*') {
        Write-Host 'Do not run recovery yet. Complete remediation here or use the approved GUI path.'
    }
    else {
        Write-Host 'Continue from the discovery findings and runbook.'
    }
    Write-ResourceFooter -Completed (Get-Date)

}
catch {
    Write-Host ''
    Write-Fail 'Response stopped'
    Write-Host (Get-ShortError $_)
    if ($script:ActionLog.Count) {
        Write-Warn 'Some changes may already have been applied. Review before retrying; recovery is not authorized.'
        Write-ActionSection 'Completed'
        Write-ActionSection 'Failed'
        Write-ActionSection 'Skipped'
    }
}


finally {
    foreach ($connection in $script:ResponseExoConnections) {
        try { Disconnect-ExchangeOnline -ConnectionId $connection.ConnectionId -Confirm:$false -ErrorAction Stop | Out-Null }
        catch { Write-Warn 'Exchange cleanup failed; close this PowerShell window.' }
    }
    if ($script:GraphOpened) {
        try { Disconnect-MgGraph -ErrorAction Stop | Out-Null }
        catch { Write-Warn 'Graph cleanup failed; close this PowerShell window.' }
    }
    Pause-End
    if ($null -ne $script:OriginalTitle) { try { $Host.UI.RawUI.WindowTitle=$script:OriginalTitle } catch {} }
}
