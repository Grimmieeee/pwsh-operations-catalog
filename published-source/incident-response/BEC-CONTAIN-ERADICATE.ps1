<#PSScriptInfo
.VERSION 1.0.3
.GUID d6441bc3-67ed-412b-bd3c-080a2ea6ef45
.AUTHOR FIELD // KIT
.DESCRIPTION Contain and clean up one compromised account after approval.
#>
<#
.SYNOPSIS
BEC: Contain and Clean Up
.DESCRIPTION
Makes only selected and explicitly confirmed changes to one M365 identity/mailbox.
Synced identity changes use the matching AD SID, never a name-only match or cloud fallback.
AD changes use the current Windows identity on the client jumpbox. Cloud sign-in does not grant AD rights.
No automatic delta sync or remoting is attempted. Validate synchronization separately.
Generates a strong temporary password and displays it only after a successful reset. No clipboard copy or export. No automatic module installs.
Run all steps in the same Windows PowerShell 5.1 or PowerShell 7 window, global Microsoft cloud only.
Validated Graph and Exchange connections and target details are reused.
.PARAMETER UPN
Target user principal name. Prompts if omitted.
.PARAMETER Tenant
Expected tenant GUID or verified domain. Prompts if omitted.
.PARAMETER SkipExchange
Allow identity/session/OAuth work without Exchange. Mailbox actions are unavailable.
.PARAMETER NoPause
Suppress end-of-step navigation. Does not suppress any action confirmation.
.NOTES
Release 1.0.0, adapted from response v1.1. Offers same-process handoff after validation.
Requires Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+.
#>

[CmdletBinding()]
param(
    [string]$UPN,
    [string]$Tenant,
    [switch]$SkipExchange,
    [switch]$NoPause,
    [ValidateRange(0,2000)][int]$OutputDelayMs = 200
)

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

$script:DataGaps = New-Object System.Collections.ArrayList
$script:ActionLog = New-Object System.Collections.ArrayList
$script:AdChanged = $false
$script:SyncResult = 'Not required'
$script:ExpectedTenantId = ''
$script:ExpectedUserId = ''
$script:ExpectedUpn = ''
$script:ExpectedSid = ''
$script:ExpectedSynced = $false
$script:GraphOpened = $false
$script:ResponseExoConnections = @()
$script:OriginalTitle = $null
$script:NextIRFile = ''
$script:Phase = 'Discovery'
$script:ContainmentBlocked = $false

function Write-Info { param([string]$Message) Write-IRLine "[INFO] $Message" }
function Write-Ok   { param([string]$Message) Write-IRLine '[OK]   ' -ForegroundColor Green -NoNewline; Write-IRLine $Message }
function Write-Warn { param([string]$Message) Write-IRLine '[WARN] ' -ForegroundColor Yellow -NoNewline; Write-IRLine $Message }
function Write-Fail { param([string]$Message) Write-IRLine '[FAIL] ' -ForegroundColor Red -NoNewline; Write-IRLine $Message }

function Write-Section {
    param([string]$Title)

    if ($Title -eq 'ADDITIONAL CHECKS: ALL CLEAR') { Write-IRLine $Title -ForegroundColor Green }
    else { Write-IRLine $Title }
}



function Section([string]$Title) {
    Write-IRLine ''
    Write-IRLine $Title
}

function Write-ResourceFooter {
    param([datetime]$Completed)
    Write-IRLine "COMPLETED: $($Completed.ToString('MM/dd/yyyy HH:mm'))" -ForegroundColor Cyan
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

function Confirm-EradicationGate {
    param([string]$Identity)
    if ($script:ContainmentBlocked -or @($script:ActionLog | Where-Object { $_.Result -eq 'Failed' }).Count) {
        Write-Fail 'Cleanup blocked: selected containment did not complete. Resolve it and rerun.'
        Add-Action 'Response' 'Eradication phase' 'Skipped' 'Selected containment incomplete'
        return $false
    }
    if (-not (Confirm-Exact 'ERADICATE')) {
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

function New-ResponsePassword {
    $alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%*-_'
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        do {
            $chars = New-Object System.Collections.Generic.List[char]
            $bytes = New-Object byte[] 1
            $limit = 256 - (256 % $alphabet.Length)
            while ($chars.Count -lt 24) {
                $rng.GetBytes($bytes)
                if ([int]$bytes[0] -lt $limit) { $chars.Add($alphabet[[int]$bytes[0] % $alphabet.Length]) }
            }
            $password = -join $chars
        } until ($password -cmatch '[A-Z]' -and $password -cmatch '[a-z]' -and $password -match '[0-9]' -and $password -match '[!@#$%*_-]')
        return $password
    }
    finally { $rng.Dispose() }
}

function Set-AdUserPassword {
    param($AdUser, [string]$Password)
    try {
        Assert-AdTarget $AdUser
        $AdUser.Entry.Invoke('SetPassword', @($Password)) | Out-Null
        $script:AdChanged = $true
        $AdUser.Entry.Properties['pwdLastSet'].Value = 0
        $AdUser.Entry.CommitChanges()
        $script:AdChanged = $true
        Add-Action 'Identity' 'Reset Active Directory password' 'Completed' 'Force change at next sign-in'
        return $true
    }
    catch {
        Add-Action 'Identity' 'Reset Active Directory password' 'Failed' 'Password operation failed or was not fully applied; validate AD before retrying.'
        $cause = $_.Exception
        while ($cause.InnerException) { $cause = $cause.InnerException }
        $code = '0x{0:X8}' -f $cause.HResult
        Write-Fail "Active Directory password reset failed ($code). AD uses the current Windows identity: $env:USERDOMAIN\$env:USERNAME. Verify delegated reset rights, DC connectivity, and password policy."
        return $false
    }
}

function Set-CloudUserPassword {
    param($GraphUser, [string]$Password)
    $body = @{ passwordProfile = @{ password = $Password; forceChangePasswordNextSignIn = $true } }
    if (Invoke-GraphWrite -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$($GraphUser.id)" -Body $body) {
        Add-Action 'Identity' 'Reset Entra ID password' 'Completed' 'Force change at next sign-in'
        return $true
    }
    Add-Action 'Identity' 'Reset Entra ID password' 'Failed' $script:LastWriteError
    Write-Fail 'Entra ID password reset failed'
    return $false
}

function Record-AdSyncPending {
    if (-not $script:AdChanged) { $script:SyncResult='Not required'; return }
    $script:SyncResult='Not requested - AD replication and cloud synchronization require separate validation'
    # Keep internal sync state; client synchronization is validated before rollout.
}

function Revoke-UserSessions {
    param($GraphUser)
    if (Invoke-GraphWrite -Method POST -Uri "https://graph.microsoft.com/v1.0/users/$($GraphUser.id)/revokeSignInSessions" -Body $null) {
        Add-Action 'Sessions' 'Revoke active sessions' 'Completed' 'Session revocation submitted; invalidation may be delayed'
        Write-Ok 'Session revocation submitted'
        return $true
    }
    Add-Action 'Sessions' 'Revoke active sessions' 'Failed' $script:LastWriteError
    Write-Fail 'Session revocation failed'
    return $false
}

function Disable-UserAccount {
    param($GraphUser, $AdUser)
    $cloudOk = $false
    if (Invoke-GraphWrite -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$($GraphUser.id)" -Body @{ accountEnabled = $false }) {
        $verified = Get-GraphUser $GraphUser.userPrincipalName
        $cloudOk = $verified -and $verified.id -eq $GraphUser.id -and $verified.accountEnabled -eq $false
        if ($cloudOk) {
            Add-Action 'Identity' 'Block Entra sign-in' 'Completed' 'Disabled state verified'
            Write-Ok 'Entra sign-in blocked'
        }
        else { Add-Action 'Identity' 'Block Entra sign-in' 'Failed' 'Disabled state not verified' }
    }
    else { Add-Action 'Identity' 'Block Entra sign-in' 'Failed' $script:LastWriteError }
    $adOk = $true
    if ($GraphUser.onPremisesSyncEnabled -eq $true) {
        if (-not $AdUser) {
            Add-Action 'Identity' 'Disable AD account' 'Failed' 'SID-matched AD account unavailable; verify AD manually'
            $adOk = $false
        }
        else { $adOk = Disable-AdUser $AdUser }
    }
    return $cloudOk -and $adOk
}

function Confirm-UserMfaProtection {
    param($GraphUser)
    # Action 8 is explicitly attested in the single RESPOND approval.
    Add-Action 'MFA' 'Verify user MFA protection' 'Completed' 'MFA enforced - operator confirmed; registered methods trusted'
    return $true
}

function Reset-UserPassword {
    param($GraphUser, $AdUser)
    $password = New-ResponsePassword
    try {
        if ($GraphUser.onPremisesSyncEnabled -eq $true) {
            if (-not $AdUser) {
                Add-Action 'Identity' 'Reset password' 'Failed' 'SID-matched AD account unavailable; no cloud reset attempted'
                return $false
            }
            $success = Set-AdUserPassword -AdUser $AdUser -Password $password
        }
        else { $success = Set-CloudUserPassword -GraphUser $GraphUser -Password $password }
        if ($success) {
            Write-Ok "$(if ($GraphUser.onPremisesSyncEnabled -eq $true) {'Active Directory'} else {'Entra ID'}) password reset"
            Write-IRLine ''
            Write-IRLine "Temporary password: $password"
            Write-IRLine 'Deliver through the approved secure channel.'
            Write-IRLine 'Script clears its password variable after the secure-delivery pause.'
            [void](Read-Host 'Press ENTER after secure delivery to continue')
        }
        return [bool]$success
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

function Read-CleanupApproval {
    Write-IRLine '[ESC] Return to response menu. Completed containment remains in effect.'
    if ($Host.Name -ne 'ConsoleHost' -or [Console]::IsInputRedirected -or (Get-Command Read-Host).CommandType -eq 'Function') {
        return (Read-Host 'Type ERADICATE to continue, or ESC to return')
    }
    Write-IRLine 'Type ERADICATE to continue: ' -NoNewline
    $text=''
    while ($true) {
        $key=[Console]::ReadKey($true)
        if ($key.Key -eq 'Escape') { Write-IRLine ''; return 'ESC' }
        if ($key.Key -eq 'Enter') { Write-IRLine ''; return $text }
        if ($key.Key -eq 'Backspace') {
            if ($text.Length) { $text=$text.Substring(0,$text.Length-1); Write-IRLine "`b `b" -NoNewline }
        } elseif (-not [char]::IsControl($key.KeyChar)) { $text += $key.KeyChar; Write-IRLine $key.KeyChar -NoNewline }
    }
}

function Confirm-Exact {
    param([string]$Required)
    while ($true) {
        $value = if ($Required -eq 'ERADICATE') { Read-CleanupApproval } else { Read-Host "Type $Required to continue" }
        if ($Required -eq 'ERADICATE' -and $value -ieq 'ESC') { $script:ReturnToMenu=$true; return $false }
        if ([string]::IsNullOrWhiteSpace($value) -or $value.Trim() -ieq 'N') { return $false }
        if ($value.Trim() -ieq $Required) { return $true }
        Write-Warn "Not confirmed. Enter: $Required"
        Write-IRLine 'Press Enter or type N to cancel.'
    }
}

function Remove-SelectedRules {
    param([object[]]$Rules, [string]$Identity)
    if ($Rules.Count -eq 0) { Add-Action 'Mailbox Persistence' 'Remove inbox rules' 'Skipped' 'No rules selected'; return }
    foreach ($rule in $Rules) {
        try {
            Assert-ResponseContext -Exchange
            # Resolve inside the validated mailbox immediately before removal.
            $fresh = @(Get-InboxRuleItems $Identity | Where-Object { [string]$_.Identity -ceq [string]$rule.Identity })
            if ($fresh.Count -ne 1) { throw 'Selected rule no longer resolves uniquely. Review and select it again.' }
            $before = "$($rule.Name)|$($rule.Enabled)|$($rule.Hidden)|$($rule.Actions -join ';')|$($rule.Targets -join ';')"
            $now = "$($fresh[0].Name)|$($fresh[0].Enabled)|$($fresh[0].Hidden)|$($fresh[0].Actions -join ';')|$($fresh[0].Targets -join ';')"
            if ($before -cne $now) { throw 'Selected rule changed after approval. Review and select it again.' }
            $ruleId = [string]$fresh[0].Identity
            if ([string]::IsNullOrWhiteSpace($ruleId)) { throw 'Selected rule identity is unavailable.' }
            if ($ruleId.Contains('\')) {
                Remove-IRWorkflowInboxRule -Identity $ruleId -Confirm:$false -ErrorAction Stop
            }
            else {
                Remove-IRWorkflowInboxRule -Mailbox $Identity -Identity $ruleId -Confirm:$false -ErrorAction Stop
            }
            $remaining = @(Get-InboxRuleItems $Identity | Where-Object { [string]$_.Identity -ceq $ruleId })
            if ($script:DataGaps.Count -gt 0) { throw 'Rule removal verification is incomplete. Recheck the mailbox.' }
            if ($remaining.Count) { throw 'Rule still present after removal. Recheck the mailbox.' }
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
    Write-IRLine 'Current mailbox forwarding:'
    foreach ($item in $MailboxState.Forwarding) { Write-IRLine "- $item" }
    try {
        Assert-ResponseContext -Exchange; Set-IRWorkflowMailbox -Identity $Identity -ForwardingAddress $null -ForwardingSmtpAddress $null -DeliverToMailboxAndForward $false -ErrorAction Stop
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
    foreach ($item in $Items) { Write-IRLine "- $($item.App) | $($item.Publisher) | Scope: $($item.Scope)" }
    Write-Warn 'This removes user-specific delegated consent only. Tenant-wide admin consent is not included.'
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
    foreach ($item in $Items) { Write-IRLine "- $($item.Type): $($item.Display)" }
    foreach ($item in $Items) {
        try {
            switch ($item.Type) {
                'Full Access' { Assert-ResponseContext -Exchange; Remove-IRWorkflowMailboxPermission -Identity $Identity -User $item.Raw -AccessRights FullAccess -Confirm:$false -ErrorAction Stop }
                'Send As' { Assert-ResponseContext -Exchange; Remove-IRWorkflowRecipientPermission -Identity $Identity -Trustee $item.Raw -AccessRights SendAs -Confirm:$false -ErrorAction Stop }
                'Send On Behalf' { Assert-ResponseContext -Exchange; Set-IRWorkflowMailbox -Identity $Identity -GrantSendOnBehalfTo @{ remove = $item.Raw } -ErrorAction Stop }
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
    try {
        Assert-ResponseContext -Exchange; Set-IRWorkflowCASMailbox -Identity $Identity -ImapEnabled $false -PopEnabled $false -SmtpClientAuthenticationDisabled $true -ErrorAction Stop
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
    if ($items.Count -eq 0) { Write-IRLine '- None'; return }
    foreach ($item in $items) { Write-IRLine "- $($item.Action): $($item.Detail)" }
}

function Invoke-EradicationPlan {
    param([string]$Identity, [int[]]$Selections, [object[]]$Rules, $MailboxState,
          [object[]]$OAuth, [object[]]$Access, [bool]$ExchangeAvailable)
    if (-not @($Selections | Where-Object { $_ -ge 4 -and $_ -le 7 }).Count) { return }
    if ($script:ContainmentBlocked -or @($script:ActionLog | Where-Object { $_.Result -eq 'Failed' }).Count) {
        Write-Fail 'Cleanup blocked: selected containment did not complete. Resolve it and rerun.'
        return
    }
    $selectedRules=@(); $selectedOAuth=@(); $selectedAccess=@(); $clearForwarding=$false
    $plan=New-Object System.Collections.Generic.List[string]
    if ($Selections -contains 4) {
        if (-not $ExchangeAvailable) { Add-Action 'Mailbox Persistence' 'Mailbox cleanup' 'Failed' 'Exchange unavailable' }
        else {
            if ($Rules.Count) {
                Section 'INBOX RULE SELECTION'
                for ($i=0; $i -lt $Rules.Count; $i++) {
                    $r=$Rules[$i]
                    Write-IRLine "[$($i+1)] $($r.Name) | Hidden: $($r.Hidden) | $($r.Actions -join ', ') | $($r.Targets -join ', ')"
                }
                $selectedRules=@(Select-Items -Items $Rules -Prompt 'Select rules to remove')
                foreach ($r in $selectedRules) { $plan.Add("Remove rule: $($r.Name) | $($r.Actions -join ', ') | $($r.Targets -join ', ')") }
            }
            if (-not $selectedRules.Count) { Add-Action 'Mailbox Persistence' 'Remove inbox rules' 'Skipped' 'No rules selected or returned' }
            if ($MailboxState.Forwarding.Count) {
                Write-IRLine "Mailbox forwarding: $($MailboxState.Forwarding -join '; ')"
                $clearForwarding=((Read-Host 'Include mailbox forwarding removal? [Y/N]').Trim() -ieq 'Y')
                if ($clearForwarding) { $plan.Add("Clear forwarding: $($MailboxState.Forwarding -join '; ')") }
            }
            if (-not $clearForwarding) { Add-Action 'Mailbox Persistence' 'Clear mailbox forwarding' 'Skipped' 'No forwarding selected or returned' }
        }
    }
    if ($Selections -contains 5) {
        if ($OAuth.Count) {
            Section 'OAUTH SELECTION'
            for ($i=0; $i -lt $OAuth.Count; $i++) { Write-IRLine "[$($i+1)] $($OAuth[$i].App) | $($OAuth[$i].Publisher) | $($OAuth[$i].Scope)" }
            $selectedOAuth=@(Select-Items -Items $OAuth -Prompt 'Select user-specific OAuth grants to remove')
            foreach ($o in $selectedOAuth) { $plan.Add("Remove user consent: $($o.App) | $($o.Scope)") }
        }
        if (-not $selectedOAuth.Count) { Add-Action 'OAuth' 'Remove user-specific OAuth consent' 'Skipped' 'No grants selected or returned' }
    }
    if ($Selections -contains 6) {
        if (-not $ExchangeAvailable) { Add-Action 'Mailbox Access' 'Remove mailbox access' 'Failed' 'Exchange unavailable' }
        else {
            if ($Access.Count) {
                Section 'MAILBOX ACCESS SELECTION'
                for ($i=0; $i -lt $Access.Count; $i++) { Write-IRLine "[$($i+1)] $($Access[$i].Type): $($Access[$i].Display)" }
                $selectedAccess=@(Select-Items -Items $Access -Prompt 'Select mailbox access entries to remove')
                foreach ($a in $selectedAccess) { $plan.Add("Remove $($a.Type): $($a.Display)") }
            }
            if (-not $selectedAccess.Count) { Add-Action 'Mailbox Access' 'Remove mailbox access' 'Skipped' 'No access selected or returned' }
        }
    }
    $disableLegacy=($Selections -contains 7 -and $ExchangeAvailable -and $MailboxState.Legacy.Count -gt 0)
    if ($Selections -contains 7) {
        if (-not $ExchangeAvailable) { Add-Action 'Legacy Authentication' 'Disable legacy authentication' 'Failed' 'Exchange unavailable' }
        elseif ($disableLegacy) { $plan.Add("Disable protocols: $($MailboxState.Legacy -join ', ')") }
        else { Add-Action 'Legacy Authentication' 'Disable legacy authentication' 'Skipped' 'No enabled mailbox protocols returned' }
    }
    if (-not $plan.Count) { Write-IRLine 'No cleanup changes selected.'; return }
    Section 'VERIFY CLEANUP PLAN'
    foreach ($line in $plan) { Write-IRLine "- $line" }
    if ($selectedOAuth.Count) { Write-IRLine 'Only selected user-specific consent is removed; tenant-wide consent is unchanged.' }
    if (-not (Confirm-EradicationGate $Identity)) { return }
    if ($selectedRules.Count) { Remove-SelectedRules $selectedRules $Identity }
    if ($clearForwarding) { Clear-MailboxForwarding $Identity $MailboxState }
    if ($selectedOAuth.Count) { Remove-SelectedOAuth $selectedOAuth $Identity }
    if ($selectedAccess.Count) { Remove-SelectedMailboxAccess $selectedAccess $Identity }
    if ($disableLegacy) { Disable-LegacyAuthentication $Identity $MailboxState.Legacy }
}


try {
    Enable-Tls12
    try { $script:OriginalTitle=$Host.UI.RawUI.WindowTitle; $Host.UI.RawUI.WindowTitle='BEC: Contain and Clean Up' } catch {}

    Write-IRLine 'BEC: Contain and Clean Up'
    Write-IRLine 'Contain and clean up one compromised account after approval.'
    Write-IRLine (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-IRLine 'Review legacy app passwords separately in Entra if applicable; this script does not clear them.'
    Write-IRLine ''
    $inputs = Get-IRWorkflowInput $UPN $Tenant
    $UPN=$inputs.UPN; $Tenant=$inputs.Tenant
    if ($global:FieldKitIRSession) { $global:FieldKitIRSession.Response = $null; $global:FieldKitIRSession.Recovery = $null }
    $exoOk = $false

    $scopes = @(Get-IRWorkflowScopes)
    $user = Connect-GraphForTarget -UserPrincipalName $UPN -Scopes $scopes
    if (-not $user) {
        Write-Fail 'Target could not be safely resolved. No action was performed.'
        foreach ($gap in $script:DataGaps) { Write-IRLine "- $gap" }
        return
    }

    $context = Get-MgContext -ErrorAction SilentlyContinue
    $tenantInfo = Get-TenantInfo
    if (-not $tenantInfo -or -not $tenantInfo.id) {
        Write-Fail 'Tenant identity could not be validated. No action was performed.'
        Add-DataGap 'Tenant organization lookup did not return a tenant ID.'
        foreach ($gap in $script:DataGaps) { Write-IRLine "- $gap" }
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
        $adUser = Find-AdUser $user
        if (-not $adUser) { Add-DataGap 'Synced user could not be resolved in Active Directory. AD changes are blocked.' }
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
    Write-IRLine "UPN: $($user.userPrincipalName)"
    Write-IRLine "Account Status: $accountStatus"

    if ($adUser) {
    }

    Write-IRLine ''
    $initialCounts=@{Account=$accountStatus;Rules=$ruleItems.Count;Forwarding=$mailboxState.Forwarding.Count;OAuth=$oauthItems.Count;Access=$accessItems.Count}
    do {
    $script:ReturnToMenu=$false
    Write-Section 'AVAILABLE RESPONSE ACTIONS'
    Write-IRLine $(if ($script:ContainmentApproved) { 'Enter numbers separated by commas, or ENTER for remaining cleanup (4-7).' } else { 'Enter numbers separated by commas, or ENTER for ALL.' })
    Write-IRLine ''
    Write-IRLine '[1] Revoke Active Sessions'
    Write-IRLine '[2] Disable Account'
    Write-IRLine '[3] Reset Password'
    Write-IRLine '[4] Remove Mailbox Rules / Forwarding'
    Write-IRLine '[5] Remove User-Specific OAuth Consent'
    Write-IRLine '[6] Remove Mailbox Access'
    Write-IRLine '[7] Disable Legacy Authentication'
    Write-IRLine '[8] Verify MFA Protection'
    Write-IRLine '[N] No changes'
    Write-IRLine ''
    Write-IRLine 'Actions execute in a fixed safe order regardless of selection order.'
    if ($script:ContainmentApproved) { Write-IRLine 'On return, ENTER selects cleanup only (4-7). Select 1-3 explicitly to repeat containment.' }
    $selectionText = Read-Host 'Selection'
    if ([string]::IsNullOrWhiteSpace($selectionText)) { $selectionText = if ($script:ContainmentApproved) {'4,5,6,7'} else {'1,2,3,4,5,6,7,8'} }
    if ($selectionText.Trim().ToUpper() -eq 'N') {
        Add-Action 'Response' 'Account response' 'Skipped' 'No actions selected'
    }
    else {
        $selections = @(Convert-SelectionToNumbers -InputText $selectionText -Maximum 8)
        if ($selections.Count -eq 0) {
            Add-Action 'Response' 'Account response' 'Skipped' 'No valid actions selected'
        }
        else {
            Write-IRLine ''
            Write-Section 'PLANNED ACTIONS'
            $labels = @{
                1='Revoke active sessions'; 2='Disable account'; 3='Reset password';
                4='Review/remove mailbox rules and forwarding'; 5='Review/remove user-specific OAuth consent';
                6='Review/remove mailbox access'; 7='Disable legacy authentication'; 8='Confirm MFA is enforced and registered methods are trusted (operator verified)'
            }
            foreach ($number in $selections) { Write-IRLine "- $($labels[$number])" }
            if ($selections -contains 2 -and $selections -notcontains 1) { Write-Warn 'Account disable was selected without session revocation.' }
            if ($selections -contains 5 -and $selections -notcontains 1) { Write-Warn 'OAuth removal was selected without session revocation; existing access tokens can remain valid until expiry.' }
            Write-IRLine ''
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

                if ($selections -contains 8) {
                }
                if (-not (Confirm-Exact 'RESPOND')) {
                    Add-Action 'Response' 'Account response' 'Skipped' 'Typed workflow confirmation not entered'
                }
                else {
                    Write-IRLine ''
                    $script:ContainmentApproved=$true
                    $script:Phase = 'Containment'
                    if ($selections -contains 1) { [void](Revoke-UserSessions $user) }

                if ($selections -contains 2) { [void](Disable-UserAccount -GraphUser $user -AdUser $adUser) }
                if ($selections -contains 3) { [void](Reset-UserPassword -GraphUser $user -AdUser $adUser) }

                if ($selections -contains 8) { [void](Confirm-UserMfaProtection $user) }
                Record-AdSyncPending
                $script:Phase = 'Eradication'
                Invoke-EradicationPlan -Identity $UPN -Selections $selections -Rules $ruleItems -MailboxState $mailboxState -OAuth $oauthItems -Access $accessItems -ExchangeAvailable $exoOk

                }
            }
        }
    }

    if ($script:ReturnToMenu) {
        $ruleItems=@(Get-InboxRuleItems $UPN)
        $mailboxState=Get-MailboxState $UPN
        $oauthItems=@(Get-OAuthItems $user)
        $accessItems=@(Get-MailboxAccessItems $mailboxState)
        Write-IRLine 'Choose the remaining actions. Earlier changes have not been undone.'
    }
    } while ($script:ReturnToMenu)

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
        $recommendation = 'Resolve failed actions before restoring access.'
    }
    elseif ($script:DataGaps.Count -gt 0) {
        $status = 'RESPONSE VALIDATION INCOMPLETE'
        $recommendation = 'Resolve missing evidence before restoring access.'
    }
    elseif ($remainingHighRiskRules.Count -gt 0 -or $postMailboxState.Forwarding.Count -gt 0 -or $remainingSensitiveOAuth.Count -gt 0) {
        $status = 'RESPONSE INCOMPLETE - PERSISTENCE REMAINS'
        $recommendation = 'Finish persistence review and cleanup before restoring access.'
    }
    elseif ($user.onPremisesSyncEnabled -eq $true -and $currentAd -and (Test-AdUserDisabled $currentAd) -and $postStatus -ne 'Disabled') {
        $status = 'RESPONSE INCOMPLETE - CLOUD SYNC PENDING'
        $recommendation = 'AD is disabled but the cloud account is not verified disabled. Validate synchronization before restoring access.'
    }
    elseif ($postStatus -eq 'Disabled') {
        $status = 'ACCOUNT CONTAINED'
        $recommendation = 'Confirm user identity, device safety, and approval before recovery.'
    }
    elseif ($completedCount -eq 0) {
        $status = 'NO RESPONSE ACTIONS COMPLETED'
        $recommendation = 'No actions were recorded as completed. Review evidence and the action log.'
    }

    $global:FieldKitIRSession.Response = @{
        Completed=Get-Date; UserId=$script:ExpectedUserId; TenantId=$script:ExpectedTenantId
        Summary=$status; Failed=$failedCount; ContainmentBlocked=$script:ContainmentBlocked
        Actions=@($script:ActionLog | ForEach-Object { @{Action=$_.Action;Result=$_.Result;Detail=$_.Detail} })
        Before=$initialCounts
        After=@{Account=$postStatus;Rules=$postRules.Count;Forwarding=$postMailboxState.Forwarding.Count;OAuth=$postOAuth.Count;Access=$postAccess.Count}
        RecoveryReady=($failedCount -eq 0 -and -not $script:ContainmentBlocked -and $script:DataGaps.Count -eq 0 -and
            $postStatus -eq 'Disabled' -and $remainingHighRiskRules.Count -eq 0 -and
            $remainingSensitiveOAuth.Count -eq 0 -and $postMailboxState.Forwarding.Count -eq 0)
    }
    Write-IRLine ''
    Write-IRLine "STATUS: $status" -ForegroundColor $(if ($failedCount -or $status -eq 'ACCOUNT CONTAINED') { 'Red' } else { 'Yellow' })
    Write-IRLine $recommendation

    Write-IRLine ''
    Write-ActionSection 'Failed'
    Write-IRLine ''
    Write-ActionSection 'Skipped'

    Write-IRLine ''
    Write-Section 'VALIDATION'
    Write-IRLine ("Entra Account: {0}" -f $postStatus)
    if ($user.onPremisesSyncEnabled -eq $true) {
        Write-IRLine (
            "AD Account: {0}" -f
            $(if ($currentAd) {
                if (Test-AdUserDisabled $currentAd) { 'Disabled' } else { 'Enabled' }
            }
            else { 'Not available' })
        )
        # No repeated synchronization output.
    }
    if ($script:DataGaps.Count) { Write-Warn 'Counts below are observed results only; unavailable checks are NOT verified clear.' }
    Write-IRLine ("Inbox Rules Remaining: {0}" -f $postRules.Count)
    Write-IRLine ("Forwarding Remaining: {0}" -f $postMailboxState.Forwarding.Count)
    Write-IRLine ("OAuth Grants Remaining: {0}" -f $postOAuth.Count)
    Write-IRLine ("Mailbox Access Remaining: {0}" -f $postAccess.Count)
    Write-IRLine ("Legacy Auth: {0}" -f $(if ($postMailboxState.Legacy.Count -gt 0) { $postMailboxState.Legacy -join '; ' } else { 'No' }))

    foreach ($rule in $postRules) {
        $hidden = if ($rule.Hidden) { ' [Hidden]' } else { '' }
        Write-IRLine ("Rule: {0}{1} | {2}" -f $rule.Name, $hidden, ($rule.Actions -join '; '))
    }

    if ($script:DataGaps.Count -gt 0) {
        Section 'REVIEW ITEMS'

        foreach ($gap in @($script:DataGaps | Select-Object -Unique)) {
            Write-IRLine ("- {0}" -f $gap)
        }
    }

    Write-IRLine "`nCOMPLETED: $((Get-Date).ToString('MM/dd/yyyy HH:mm'))"
    if ($global:FieldKitIRSession.Response.RecoveryReady) {
        Write-IRLine ''
        Write-IRLine 'STATUS: RECOVERY REQUIRED' -ForegroundColor Red
        Section 'NEXT STEP'
        Write-IRLine 'Confirm recovery readiness and restore approved access.'
        $script:NextIRFile='BEC-RECOVER-VALIDATE'
    }
    elseif ($failedCount -gt 0 -or $script:DataGaps.Count -gt 0 -or $remainingHighRiskRules.Count -gt 0 -or $postMailboxState.Forwarding.Count -gt 0 -or $remainingSensitiveOAuth.Count -gt 0) {
        Section 'NEXT STEP'
        Write-IRLine 'BEC-CONTAIN-ERADICATE'
        Write-IRLine 'Resolve failed actions and review remaining findings before recovery.'
        Write-IRLine 'Then run BEC-RECOVER-VALIDATE to complete the response.'
    }
    else {
        Section 'NEXT STEP'
        Write-IRLine 'BEC-RECOVER-VALIDATE'
        Write-IRLine 'Review skipped actions and current account state before recovery.'
    }

}
catch {
    Write-IRLine ''
    Write-Fail 'Response stopped'
    Write-IRLine 'NEXT: BEC-CONTAIN-ERADICATE'
    Write-IRLine 'Resolve the reported items and finish response before restoring access.'
    Write-IRLine (Get-ShortError $_)
    if ($script:ActionLog.Count) {
        Write-Warn 'Some changes may already be applied. Review the results before retrying.'
            Write-ActionSection 'Failed'
        Write-ActionSection 'Skipped'
    }
}


finally {
    if ($null -ne $script:OriginalTitle) { try { $Host.UI.RawUI.WindowTitle=$script:OriginalTitle } catch {} }
}

Invoke-IRNextStep -FileName $script:NextIRFile -Objective 'Next: verify readiness and restore approved access.'
