<#PSScriptInfo
.VERSION 0.4.0
.GUID 7cf20e90-263b-4c97-98ec-f7d7d105d9aa
.AUTHOR FIELD // KIT
.DESCRIPTION Standalone read-only identity risk assessment. Candidate pending Windows and tenant validation.
#>
<#
.SYNOPSIS
IR: Identity Risk Assessment
.DESCRIPTION
Reviews one M365 identity and mailbox before response decisions. Makes no tenant changes.
Uses delegated Microsoft Graph and Exchange Online sign-in in the global Microsoft cloud.
Requires Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+.
No module installation, execution-policy changes, credentials, or exports are performed.
Run all three steps in the same PowerShell window. Validated connections and target details are reused.
The first sign-in requests the read and response scopes used by all three steps; this assessment makes no changes.
.PARAMETER UserPrincipalName
Exact target UPN. Prompts when omitted.
.PARAMETER Tenant
Expected tenant GUID or verified domain. Prompts when omitted; never guesses from target UPN.
.PARAMETER SkipExchange
Skip mailbox collection. The assessment remains incomplete and requires review.
.PARAMETER NoPause
Suppress end-of-step navigation. Does not bypass action confirmations.
.NOTES
Version 0.4.0 candidate. Derived from the v0.32 risk exposure snapshot.
Preserves indicator rules and summary precedence; not a compromise verdict or incident closure.
Graph sign-ins are a bounded latest-25 sample over 10 days, not a complete investigation.
#>
[CmdletBinding()]
param(
    [string]$UserPrincipalName,
    [string]$Tenant,
    [switch]$SkipExchange,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

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
        Write-Host 'Sign in once for assessment, response, and recovery. Changes require operator confirmation.' -ForegroundColor Cyan
        Connect-MgGraph -TenantId $ExpectedTenant -Scopes $scopes -ContextScope Process -NoWelcome -ErrorAction Stop | Out-Null
        $context = Get-MgContext -ErrorAction Stop
    }
    if (-not (Test-IRWorkflowTenant $context $ExpectedTenant)) { throw 'Graph tenant or sign-in context could not be verified.' }
    $missing = @($scopes | Where-Object { @($context.Scopes) -notcontains $_ })
    if ($missing.Count) { throw "Graph consent is missing: $($missing -join ', ')." }
    Write-Host '[OK]   GRAPH CONNECTED' -ForegroundColor Green
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
    Write-Host '[OK]   EXCHANGE CONNECTED' -ForegroundColor Green
    Write-Host '[OK]   UPN MATCHED' -ForegroundColor Green
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
    if (-not $saved -and -not $NoPause) { [void](Read-Host 'Press [ENTER] to sign in once for assessment, response, and recovery') }
    return @{UPN=$TargetUpn;Tenant=$ExpectedTenant}
}

function Invoke-IRNextStep {
    param([string]$FileName, [string]$Objective)
    if ($NoPause) { return }
    Write-Host ''
    if ([string]::IsNullOrWhiteSpace($FileName)) {
        [void](Read-Host 'Press Enter to return to PowerShell')
        return
    }
    $answer = Read-Host 'Continue? [Y/N; Enter = N]'
    if ($answer.Trim() -ine 'Y') { return }
    $next = Join-Path $PSScriptRoot ($FileName + '.ps1')
    if (-not (Test-Path -LiteralPath $next -PathType Leaf)) {
        Write-Host "Next script not found: $FileName. Keep all three files in the same folder." -ForegroundColor Yellow
        return
    }
    $saved = $global:FieldKitIRSession
    if (-not $saved -or -not $saved.UPN -or -not $saved.TenantId) {
        Write-Host 'Verified target context is unavailable. Start the next script manually.' -ForegroundColor Yellow
        return
    }
    $nextArgs = @{Tenant=[string]$saved.TenantId}
    if ($FileName -eq 'IR-GET-IDENTITY-RISK-ASSESSMENT') { $nextArgs.UserPrincipalName=[string]$saved.UPN }
    else { $nextArgs.UPN=[string]$saved.UPN }
    & $next @nextArgs
}

# End shared workflow functions.


function Section([string]$Title) {
    Write-Host ""
    Write-Host $Title
}

function Import-AssessmentModule([string]$Name, [version]$MinimumVersion) {
    $module = Get-Module -ListAvailable -Name $Name |
        Where-Object { $_.Version -ge $MinimumVersion } |
        Sort-Object Version -Descending | Select-Object -First 1
    if (-not $module) {
        throw "Requires $Name $MinimumVersion or later. Install separately: Install-Module $Name -Scope CurrentUser -MinimumVersion $MinimumVersion"
    }
    Import-Module $module.Path -Global -ErrorAction Stop
}

function Connect-AssessmentGraph([string]$ExpectedTenant) {
    Import-AssessmentModule 'Microsoft.Graph.Authentication' ([version]'2.0.0')
    return Connect-IRWorkflowGraph $ExpectedTenant
}

function Connect-AssessmentExchange([string]$ExpectedTenantId, [string]$TargetId, [string]$TargetUpn) {
    Import-AssessmentModule 'ExchangeOnlineManagement' ([version]'3.2.0')
    return Connect-IRWorkflowExchange $ExpectedTenantId $TargetId $TargetUpn
}

function Add-Unique($List, [string]$Value) {
    if (-not [string]::IsNullOrWhiteSpace($Value) -and -not $List.Contains($Value)) {
        [void]$List.Add($Value)
    }
}

function Format-DateTime($Value, [string]$Format = 'yyyy-MM-dd HH:mm:ss') {
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { return 'Unknown' }
    try { return ([datetime]::Parse([string]$Value)).ToString($Format) }
    catch { return [string]$Value }
}



function Get-SessionAgeInfo($Value) {
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return [pscustomobject]@{ Available = $false; TotalHours = $null; Text = 'Unknown' }
    }

    try {
        $Parsed = ([datetime]::Parse([string]$Value)).ToUniversalTime()
        $Age = (Get-Date).ToUniversalTime() - $Parsed
        $Hours = [math]::Max(0, $Age.TotalHours)

        if ($Hours -lt 1) {
            $Text = 'Less than 1 hour'
        }
        elseif ($Hours -lt 24) {
            $WholeHours = [math]::Floor($Hours)
            $Text = if ($WholeHours -eq 1) { '1 hour' } else { "$WholeHours hours" }
        }
        else {
            $Days = [math]::Floor($Hours / 24)
            $Text = if ($Days -eq 1) { '1 day' } else { "$Days days" }
        }

        return [pscustomobject]@{ Available = $true; TotalHours = $Hours; Text = $Text }
    }
    catch {
        return [pscustomobject]@{ Available = $false; TotalHours = $null; Text = 'Unknown' }
    }
}

function Get-SessionStandardInfo($Value) {
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return [pscustomobject]@{
            Configured = $false
            Valid = $true
            Never = $false
            Hours = $null
            Text = 'Not configured'
        }
    }

    $TextValue = ([string]$Value).Trim()
    if ($TextValue -ieq 'NEVER') {
        return [pscustomobject]@{
            Configured = $true
            Valid = $true
            Never = $true
            Hours = $null
            Text = 'No enforced interval'
        }
    }

    $Hours = 0.0
    $Parsed = [double]::TryParse(
        $TextValue,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$Hours
    )

    if (-not $Parsed -or $Hours -le 0) {
        return [pscustomobject]@{
            Configured = $true
            Valid = $false
            Never = $false
            Hours = $null
            Text = 'Invalid configuration'
        }
    }

    if (($Hours % 24) -eq 0) {
        $Days = [math]::Round($Hours / 24, 2)
        if ($Days -eq 1) { $Display = '1 day' }
        else { $Display = "$Days days" }
    }
    else {
        if ($Hours -eq 1) { $Display = '1 hour' }
        else { $Display = "$Hours hours" }
    }

    return [pscustomobject]@{
        Configured = $true
        Valid = $true
        Never = $false
        Hours = $Hours
        Text = $Display
    }
}

function GraphError($Err) {
    $Message = $Err.Exception.Message
    $ResponseBody = $null

    try {
        if ($Err.Exception.Response.StatusCode) {
            $Message = "HTTP $([int]$Err.Exception.Response.StatusCode) - $Message"
        }
    } catch { }

    try {
        if ($Err.Exception.Response -and $Err.Exception.Response.GetResponseStream()) {
            $Stream = $Err.Exception.Response.GetResponseStream()
            $Reader = New-Object System.IO.StreamReader($Stream)
            $ResponseBody = $Reader.ReadToEnd()
            $Reader.Close()
        }
    } catch { }

    if (-not [string]::IsNullOrWhiteSpace($ResponseBody)) {
        $Message = "$Message | $ResponseBody"
    }

    return $Message
}

function GraphGet([string]$Uri, [hashtable]$Headers) {
    try {
        $parsed = [uri]$Uri
        if (-not $parsed.IsAbsoluteUri -or $parsed.Scheme -ne 'https' -or
            $parsed.Host -ne 'graph.microsoft.com' -or -not $parsed.IsDefaultPort -or $parsed.UserInfo) {
            throw 'Refusing a Graph request outside the expected HTTPS endpoint.'
        }
        $Response = Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject -ErrorAction Stop
        return [pscustomobject]@{ Ok = $true; Data = $Response; Error = $null }
    }
    catch {
        return [pscustomobject]@{ Ok = $false; Data = $null; Error = (GraphError $_) }
    }
}

function GraphGetAll([string]$Uri, [hashtable]$Headers, [int]$MaxPages = 25) {
    $Items = New-Object System.Collections.Generic.List[object]
    $Next = $Uri
    $Page = 0

    while ($Next -and $Page -lt $MaxPages) {
        $Result = GraphGet $Next $Headers
        if (-not $Result.Ok) { return [pscustomobject]@{ Ok = $false; Data = $Items; Error = $Result.Error } }

        foreach ($Item in @($Result.Data.value)) { [void]$Items.Add($Item) }
        $Next = $Result.Data.'@odata.nextLink'
        $Page++
    }

    if ($Next) {
        return [pscustomobject]@{ Ok = $false; Data = $Items; Error = 'Collection exceeded the page limit; coverage is incomplete.' }
    }
    return [pscustomobject]@{ Ok = $true; Data = $Items; Error = $null }
}

function Get-GraphUser([string]$Upn, [hashtable]$Headers) {
    $Filter = [System.Uri]::EscapeDataString("userPrincipalName eq '$($Upn.Replace("'","''"))'")
    $Select = 'id,displayName,userPrincipalName,accountEnabled,createdDateTime,lastPasswordChangeDateTime,onPremisesSyncEnabled'
    $Result = GraphGet "https://graph.microsoft.com/v1.0/users?`$filter=$Filter&`$select=$Select" $Headers
    if (-not $Result.Ok) { return [pscustomobject]@{ Ok = $false; User = $null; Error = $Result.Error } }

    $Matches = @($Result.Data.value)
    if ($Matches.Count -ne 1) { return [pscustomobject]@{ Ok = $false; User = $null; Error = "No user returned for $Upn" } }

    return [pscustomobject]@{ Ok = $true; User = $Matches[0]; Error = $null }
}

function Get-TenantDomains([hashtable]$Headers) {
    $Result = GraphGetAll "https://graph.microsoft.com/v1.0/domains?`$select=id,isVerified,isDefault" $Headers 5
    $Domains = New-Object System.Collections.Generic.List[string]

    if ($Result.Ok) {
        foreach ($Domain in @($Result.Data | Where-Object { $_.isVerified })) {
            Add-Unique $Domains ([string]$Domain.id).ToLower()
        }
    }

    if (-not $Result.Ok -or $Domains.Count -eq 0) { throw 'Verified tenant domains could not be read. Assessment stopped.' }
    return @($Domains)
}

function Get-RecipientAddress($Value) {
    if ($null -eq $Value) { return $null }

    try { if ($Value.PrimarySmtpAddress) { return [string]$Value.PrimarySmtpAddress } } catch { }
    try { if ($Value.ExternalEmailAddress) { return ([string]$Value.ExternalEmailAddress).Replace('SMTP:', '') } } catch { }
    try { if ($Value.emailAddress.address) { return [string]$Value.emailAddress.address } } catch { }
    try { if ($Value.address) { return [string]$Value.address } } catch { }

    $Text = [string]$Value
    if ($Text -match '[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}') { return $Matches[0] }

    # Recipient objects may stringify to a display name or Exchange identity.
    # Do not classify non-SMTP text as an internal forwarding target.
    return $null
}

function Is-ExternalAddress([string]$Address, [string[]]$Domains) {
    if ([string]::IsNullOrWhiteSpace($Address) -or $Address -notmatch '@') { return $false }
    $Domain = ($Address -split '@')[-1].ToLower()
    return -not ($Domains -contains $Domain)
}




function Format-ConditionalAccessPolicyName([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return $Name }

    switch -Regex ($Name.Trim()) {
        '^Block legacy authentication$' {
            return 'Block Legacy Authentication'
        }
        '^Geo Blocking Policy$' {
            return 'Geo-Blocking Policy'
        }
        '^Microsoft-managed: Block device code flow$' {
            return 'Microsoft-managed: Block Device Code Flow'
        }
        '^Microsoft-managed: Multifactor authentication for admins accessing Microsoft Admin Portals$' {
            return 'Microsoft-managed: MFA for Microsoft Portal Admins'
        }
        '^Microsoft-managed: Multifactor authentication and reauthentication for risky sign-ins$' {
            return 'Microsoft-managed: MFA for risky sign-ins'
        }
        '^Microsoft-managed: Multifactor authentication for per-user multifactor authentication users$' {
            return 'Microsoft-managed: MFA per-user'
        }
        '^Require multifactor authentication for admins$' {
            return 'MFA for Admins'
        }
        '^Require multifactor authentication for all users$' {
            return 'MFA for All Users'
        }
        default {
            return $Name.Trim()
        }
    }
}

function Format-MfaMethod($Method) {
    $Type = [string]$Method.'@odata.type'

    switch -Regex ($Type) {
        'passwordAuthenticationMethod' { return $null }
        'phoneAuthenticationMethod' {
            if ($Method.phoneNumber) { return "Phone: $($Method.phoneNumber)" }
            return 'Phone: number hidden'
        }
        'microsoftAuthenticatorAuthenticationMethod' { return 'Microsoft Authenticator' }
        'softwareOathAuthenticationMethod' { return 'Software OATH' }
        'fido2AuthenticationMethod' { return 'FIDO2 Security Key' }
        'windowsHelloForBusinessAuthenticationMethod' { return 'Windows Hello for Business' }
        'temporaryAccessPassAuthenticationMethod' { return 'Temporary Access Pass' }
        'emailAuthenticationMethod' { return "Email: $($Method.emailAddress)" }
        default {
            if ($Type) { return $Type.Replace('#microsoft.graph.', '') }
            return 'Unknown'
        }
    }
}

function SignInResult($SignIn) {
    try {
        if ($SignIn.status.errorCode -eq 0) { return 'Success' }
        if ($SignIn.status.failureReason) { return "Failed - $($SignIn.status.failureReason)" }
        return "Failed - error $($SignIn.status.errorCode)"
    } catch { return 'Unknown' }
}




function Get-ServicePrincipalInfo($ServicePrincipalId, $Headers, $Cache) {
    if ([string]::IsNullOrWhiteSpace($ServicePrincipalId)) {
        return [pscustomobject]@{ Ok = $false; Name = 'Unresolved app'; Microsoft = $false; Verified = $false }
    }

    if ($Cache.ContainsKey($ServicePrincipalId)) { return $Cache[$ServicePrincipalId] }

    $Result = GraphGet "https://graph.microsoft.com/v1.0/servicePrincipals/$ServicePrincipalId?`$select=id,appId,displayName,publisherName,verifiedPublisher" $Headers

    if (-not $Result.Ok) {
        $Filter = [System.Uri]::EscapeDataString("id eq '$ServicePrincipalId'")
        $Result = GraphGet "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=$Filter&`$select=id,appId,displayName,publisherName,verifiedPublisher&`$top=1" $Headers

        if (-not $Result.Ok -or @($Result.Data.value).Count -lt 1) {
            $Info = [pscustomobject]@{ Ok = $false; Name = "Unresolved app ($ServicePrincipalId)"; Microsoft = $false; Verified = $false }
            $Cache[$ServicePrincipalId] = $Info
            return $Info
        }

        $Data = @($Result.Data.value)[0]
    }
    else {
        $Data = $Result.Data
    }

    $Name = if ($Data.displayName) { [string]$Data.displayName } else { 'Unnamed app' }
    $Publisher = if ($Data.publisherName) { [string]$Data.publisherName } else { '' }
    $VerifiedPublisher = ''
    try { if ($Data.verifiedPublisher.displayName) { $VerifiedPublisher = [string]$Data.verifiedPublisher.displayName } } catch { }

    $IsMicrosoft = $false
    if ($Publisher -match 'Microsoft' -or $VerifiedPublisher -match 'Microsoft' -or $Name -match '^(Microsoft|Office 365|SharePoint|Teams|Azure|Windows|Power BI|PowerApps|Power Automate|Yammer|Viva)') { $IsMicrosoft = $true }

    $Info = [pscustomobject]@{ Ok = $true; Name = $Name; Microsoft = $IsMicrosoft; Verified = (-not [string]::IsNullOrWhiteSpace($VerifiedPublisher)) }
    $Cache[$ServicePrincipalId] = $Info
    return $Info
}

function Add-Reason($ReasonList, [string]$Reason) {
    Add-Unique $ReasonList $Reason
}

function Get-GraphRuleIndicators($Rule, [string[]]$TenantDomains) {
    $Actions = New-Object System.Collections.Generic.List[string]
    $Targets = New-Object System.Collections.Generic.List[string]
    $ExternalTargets = New-Object System.Collections.Generic.List[string]
    $InternalTargets = New-Object System.Collections.Generic.List[string]
    $IsBecRule = $false
    $HasExternalForward = $false
    $HasInternalForward = $false
    $HasDeleteHide = $false

    $A = $Rule.actions
    if ($null -eq $A) {
        return [pscustomobject]@{
            Actions=@()
            Targets=@()
            ExternalTargets=@()
            InternalTargets=@()
            IsBecRule=$false
            HasExternalForward=$false
            HasInternalForward=$false
            HasDeleteHide=$false
        }
    }

    foreach ($Prop in @('forwardTo','redirectTo','forwardAsAttachmentTo')) {
        foreach ($Recipient in @($A.$Prop)) {
            $Address = Get-RecipientAddress $Recipient
            if ($Address) {
                Add-Unique $Targets $Address

                if (Is-ExternalAddress $Address $TenantDomains) {
                    Add-Unique $ExternalTargets $Address
                    $HasExternalForward = $true
                }
                else {
                    Add-Unique $InternalTargets $Address
                    $HasInternalForward = $true
                }
            }
        }
    }

    if ($Targets.Count -gt 0) {
        Add-Unique $Actions 'FORWARD/REDIRECT'
        $IsBecRule = $true
    }

    try { if ($A.delete -eq $true) { Add-Unique $Actions 'DELETE'; $IsBecRule = $true; $HasDeleteHide = $true } } catch { }
    try { if ($A.permanentDelete -eq $true) { Add-Unique $Actions 'PERMANENT_DELETE'; $IsBecRule = $true; $HasDeleteHide = $true } } catch { }
    try { if (-not [string]::IsNullOrWhiteSpace([string]$A.moveToFolder)) { Add-Unique $Actions 'MOVE'; $IsBecRule = $true; $HasDeleteHide = $true } } catch { }
    try { if ($A.markAsRead -eq $true) { Add-Unique $Actions 'MARK_READ'; $IsBecRule = $true; $HasDeleteHide = $true } } catch { }
    try { if ($A.stopProcessingRules -eq $true) { Add-Unique $Actions 'STOP_PROCESSING' } } catch { }

    return [pscustomobject]@{
        Actions=$Actions
        Targets=$Targets
        ExternalTargets=$ExternalTargets
        InternalTargets=$InternalTargets
        IsBecRule=$IsBecRule
        HasExternalForward=$HasExternalForward
        HasInternalForward=$HasInternalForward
        HasDeleteHide=$HasDeleteHide
    }
}

function Get-ExoRuleIndicators($Rule, [string[]]$TenantDomains) {
    $Actions = New-Object System.Collections.Generic.List[string]
    $Targets = New-Object System.Collections.Generic.List[string]
    $ExternalTargets = New-Object System.Collections.Generic.List[string]
    $InternalTargets = New-Object System.Collections.Generic.List[string]
    $IsBecRule = $false
    $HasExternalForward = $false
    $HasInternalForward = $false
    $HasDeleteHide = $false

    foreach ($Prop in @('ForwardTo','RedirectTo','ForwardAsAttachmentTo')) {
        foreach ($Recipient in @($Rule.$Prop)) {
            $Address = Get-RecipientAddress $Recipient
            if ($Address) {
                Add-Unique $Targets $Address

                if (Is-ExternalAddress $Address $TenantDomains) {
                    Add-Unique $ExternalTargets $Address
                    $HasExternalForward = $true
                }
                else {
                    Add-Unique $InternalTargets $Address
                    $HasInternalForward = $true
                }
            }
        }
    }

    if ($Targets.Count -gt 0) {
        Add-Unique $Actions 'FORWARD/REDIRECT'
        $IsBecRule = $true
    }

    try { if ($Rule.DeleteMessage -eq $true) { Add-Unique $Actions 'DELETE'; $IsBecRule = $true; $HasDeleteHide = $true } } catch { }
    try { if ($Rule.MarkAsRead -eq $true) { Add-Unique $Actions 'MARK_READ'; $IsBecRule = $true; $HasDeleteHide = $true } } catch { }
    try { if ($Rule.MoveToFolder) { Add-Unique $Actions 'MOVE'; $IsBecRule = $true; $HasDeleteHide = $true } } catch { }
    try { if ($Rule.StopProcessingRules -eq $true) { Add-Unique $Actions 'STOP_PROCESSING' } } catch { }

    return [pscustomobject]@{
        Actions=$Actions
        Targets=$Targets
        ExternalTargets=$ExternalTargets
        InternalTargets=$InternalTargets
        IsBecRule=$IsBecRule
        HasExternalForward=$HasExternalForward
        HasInternalForward=$HasInternalForward
        HasDeleteHide=$HasDeleteHide
    }
}

$Started = Get-Date
$Completed = $null
$HighRiskReasons = New-Object System.Collections.Generic.List[string]
$ReviewReasons = New-Object System.Collections.Generic.List[string]
$Cleared = [ordered]@{}
$DataGaps = New-Object System.Collections.Generic.List[string]
$CriticalDataGaps = New-Object System.Collections.Generic.List[string]
$SpCache = @{}

$GraphConnected = $false
$ExoConnected = $false
$GraphErrorText = $null
$ExoErrorText = $null
$GraphOpened = $false
$AssessmentExoConnections = @()
$OriginalTitle = $null
$script:NextIRFile = ''

$MfaAvailable = $false
$RolesAvailable = $false
$SignInsAvailable = $false
$OAuthAvailable = $false
$MailboxObjectAvailable = $false
$CasMailboxAvailable = $false
$FullAccessAvailable = $false
$SendAsAvailable = $false

$TargetUser = $null
$LastInteractiveSignIn = $null
$LastNonInteractiveSignIn = $null
$SignInActivityDisplayReason = $null
$InteractiveSignInAge = [pscustomobject]@{ Available = $false; TotalHours = $null; Text = 'Unknown' }
$SessionStandard = [pscustomobject]@{ Configured = $false; Valid = $true; Never = $false; Hours = $null; Text = 'Not configured' }
$ReauthHygiene = 'NOT ASSESSED'
$Mailbox = $null
$CasMailbox = $null
$TenantDomains = @()
$MfaMethods = @()
$Roles = @()
$SignIns48 = @()
$ConditionalAccessEnabledPolicies = New-Object System.Collections.Generic.List[string]
$ConditionalAccessPolicyStatus = 'Unknown'
$FailedSignIns = @()
$InboxRules = @()
$InboxRuleCoverage = 'Unavailable'
$ForwardingRules = @()
$ExternalForwardTargets = New-Object System.Collections.Generic.List[string]
$FullAccess = @()
$SendAs = @()
$SendOnBehalf = @()
$UnverifiedOAuth = @()
$LegacyAuth = New-Object System.Collections.Generic.List[string]
$HiddenRuleFindings = @()

try {
    try {
        $OriginalTitle = $Host.UI.RawUI.WindowTitle
        $Host.UI.RawUI.WindowTitle = 'IR: Identity Risk Assessment'
    } catch { }
    Write-Host 'IR: Identity Risk Assessment // READ ONLY'
    Write-Host 'Check the account and mailbox for signs of suspicious activity.'
    Write-Host ''
    $inputs = Get-IRWorkflowInput $UserPrincipalName $Tenant
    $TargetUpn = $inputs.UPN; $Tenant = $inputs.Tenant
    if ($global:FieldKitIRSession) { $global:FieldKitIRSession.Assessment = $null }
    $Headers = @{} # Retained collector signatures; Graph SDK owns token handling.
    $GraphContext = Connect-AssessmentGraph $Tenant
    $GraphConnected = $true

    if ($GraphConnected) {
        $Lookup = Get-GraphUser $TargetUpn $Headers
        if ($Lookup.Ok) { $TargetUser = $Lookup.User }
        else { throw $Lookup.Error }
        Set-IRWorkflowTarget $GraphContext $TargetUser

        $SignInActivityResult = GraphGet "https://graph.microsoft.com/v1.0/users/$($TargetUser.id)?`$select=signInActivity" $Headers
        if ($SignInActivityResult.Ok) {
            try { $LastInteractiveSignIn = $SignInActivityResult.Data.signInActivity.lastSignInDateTime } catch { }
            try { $LastNonInteractiveSignIn = $SignInActivityResult.Data.signInActivity.lastNonInteractiveSignInDateTime } catch { }
        }
        else {
            if ($SignInActivityResult.Error -match 'Authentication_RequestFromNonPremiumTenantOrB2CTenant|doesn''t have premium license') {
                $SignInActivityDisplayReason = 'tenant licensing'
            }
            else {
                $SignInActivityDisplayReason = 'unavailable'
            }

            Add-Unique $DataGaps 'Last sign-in activity unavailable'
        }

        $TenantDomains = Get-TenantDomains $Headers

        $MfaResult = GraphGetAll "https://graph.microsoft.com/v1.0/users/$($TargetUser.id)/authentication/methods" $Headers 5
        if ($MfaResult.Ok) {
            $MfaAvailable = $true
            $MfaMethods = @($MfaResult.Data | ForEach-Object { Format-MfaMethod $_ } | Where-Object { $_ })
        }
        else {
            Add-Unique $DataGaps 'MFA methods unavailable'
            Add-Unique $CriticalDataGaps 'MFA methods unavailable'
        }

        $RolesResult = GraphGetAll "https://graph.microsoft.com/v1.0/users/$($TargetUser.id)/transitiveMemberOf/microsoft.graph.directoryRole?`$select=id,displayName&`$top=100" $Headers 5
        if ($RolesResult.Ok) {
            $RolesAvailable = $true
            $Roles = @($RolesResult.Data | ForEach-Object { $_.displayName } | Where-Object { $_ } | Sort-Object -Unique)
            if ($Roles.Count -gt 0) { Add-Reason $HighRiskReasons 'Privileged admin role assigned' }
        }
        else {
            Add-Unique $DataGaps 'Admin roles unavailable'
            Add-Unique $CriticalDataGaps 'Admin roles unavailable'
        }


        # Bounded sign-in sample: one page, latest 25, selected fields only.
        # Microsoft Graph returns sign-ins in descending createdDateTime order.
        # This reduces timeout risk while preserving first-touch triage context.
        $Since10 = (Get-Date).ToUniversalTime().AddDays(-10).ToString('yyyy-MM-ddTHH:mm:ssZ')
        $SignInFilter = [System.Uri]::EscapeDataString("userId eq '$($TargetUser.id)' and createdDateTime ge $Since10")
        $SignInsResult = GraphGet "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$filter=$SignInFilter&`$top=25&`$select=createdDateTime,ipAddress,location,status" $Headers
        if ($SignInsResult.Ok) {
            $SignInsAvailable = $true
            $AllSignIns = @($SignInsResult.Data.value | Sort-Object createdDateTime -Descending)
            $Since48 = (Get-Date).ToUniversalTime().AddHours(-48)
            $SignIns48 = @($AllSignIns | Where-Object {
                try { ([datetime]::Parse([string]$_.createdDateTime).ToUniversalTime()) -ge $Since48 }
                catch { $false }
            })
            $FailedSignIns = @($AllSignIns | Where-Object { try { $_.status.errorCode -ne 0 } catch { $false } })

            if ($FailedSignIns.Count -gt 0) { Add-Reason $ReviewReasons 'Failed sign-ins observed' }
        }
        else {
            Add-Unique $DataGaps 'Failed sign-ins unavailable'
            Add-Unique $CriticalDataGaps 'Sign-in data unavailable'
        }

        $CaPoliciesResult = GraphGetAll "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?`$top=100" $Headers 10
        if ($CaPoliciesResult.Ok) {
            $ConditionalAccessPolicyStatus = 'Available'
            $EnabledPolicies = @(
                $CaPoliciesResult.Data |
                    Where-Object { $_.state -eq 'enabled' -and -not [string]::IsNullOrWhiteSpace([string]$_.displayName) } |
                    Sort-Object displayName
            )

            foreach ($Policy in $EnabledPolicies) {
                Add-Unique $ConditionalAccessEnabledPolicies ([string]$Policy.displayName)
            }
        }
        else {
            $ConditionalAccessPolicyStatus = 'Unavailable'
            Add-Unique $DataGaps 'Conditional Access policies unavailable'
        }

        $GrantsResult = GraphGetAll "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?`$top=100" $Headers 25
        if ($GrantsResult.Ok) {
            $OAuthAvailable = $true
            $Unverified = New-Object System.Collections.Generic.List[object]
            foreach ($Grant in @($GrantsResult.Data | Where-Object { $_.principalId -eq $TargetUser.id })) {
                $Sp = Get-ServicePrincipalInfo $Grant.clientId $Headers $SpCache
                if ((-not $Sp.Ok) -or ((-not $Sp.Microsoft) -and (-not $Sp.Verified))) {
                    [void]$Unverified.Add([pscustomobject]@{ App = $Sp.Name; Scope = $Grant.scope })
                }
            }
            $UnverifiedOAuth = @($Unverified | Sort-Object App, Scope)
            if ($UnverifiedOAuth.Count -gt 0) { Add-Reason $HighRiskReasons 'Unapproved OAuth grant present' }
        }
        else {
            Add-Unique $DataGaps 'OAuth grants unavailable'
            Add-Unique $CriticalDataGaps 'OAuth grants unavailable'
        }
    }
    else {
        throw 'Graph connection failed. Target user and tenant context could not be resolved.'
    }

    # Dedicated prefixed EXO commands cannot accidentally query a different open session.
    if (-not $SkipExchange) {
        try {
            $Mailbox = Connect-AssessmentExchange ([string]$GraphContext.TenantId) ([string]$TargetUser.id) $TargetUpn
            $MailboxObjectAvailable = $true
            $ExoConnected = $true
        }
        catch {
            $ExoErrorText = $_.Exception.Message
            Add-Unique $DataGaps 'Exchange mailbox checks unavailable'
            Add-Unique $CriticalDataGaps 'Exchange mailbox checks unavailable'
            Write-Host "[!!] Exchange checks unavailable: $ExoErrorText" -ForegroundColor Yellow
        }
    }
    else {
        Add-Unique $DataGaps 'Exchange mailbox checks skipped'
        Add-Unique $CriticalDataGaps 'Exchange mailbox checks skipped'
    }

    if ($ExoConnected) {
        try {
            $CasMailbox = Get-IRWorkflowCASMailbox -Identity $TargetUpn -ErrorAction Stop
            $CasMailboxAvailable = $true
        }
        catch {
            Add-Unique $DataGaps 'Legacy auth configuration unavailable'
            Add-Unique $CriticalDataGaps 'Legacy auth configuration unavailable'
        }

        try {
            $ExoInboxRules = @(Get-IRWorkflowInboxRule -Mailbox $TargetUpn -IncludeHidden -ErrorAction Stop)
            $InboxRuleCoverage = 'Visible + Hidden'

            foreach ($Rule in $ExoInboxRules) {
                $Info = Get-ExoRuleIndicators $Rule $TenantDomains

                if ($Info.IsBecRule) {
                    $InboxRules += [pscustomobject]@{ Name = $Rule.Name; Actions = ($Info.Actions -join ', '); Targets = @($Info.Targets); IsHidden = $Rule.IsHidden }
                }

                if ($Info.HasDeleteHide) {
                    Add-Reason $HighRiskReasons 'Enabled inbox rule with move/delete/mark-read behavior'
                }

                if ($Info.HasExternalForward) {
                    $ForwardingRules += [pscustomobject]@{ Name = $Rule.Name; Actions = 'FORWARD/REDIRECT'; Targets = @($Info.ExternalTargets) }
                    foreach ($Target in @($Info.ExternalTargets)) { Add-Unique $ExternalForwardTargets $Target }
                    Add-Reason $HighRiskReasons 'Enabled inbox rule with external forwarding or redirect'
                }

                if ($Info.HasInternalForward) {
                    Add-Reason $HighRiskReasons 'Enabled inbox rule with internal forwarding or redirect'
                }

                try {
                    if ($Rule.IsHidden -eq $true -and $Info.IsBecRule) {
                        $HiddenRuleFindings += $Rule.Name
                        Add-Reason $HighRiskReasons 'Hidden inbox rule with BEC behavior'
                    }
                } catch { }
            }
        }
        catch {
            Add-Unique $DataGaps 'Inbox rules unavailable'
            Add-Unique $CriticalDataGaps 'Inbox rules unavailable'
        }

        if ($Mailbox) {
            try {
                foreach ($Target in @($Mailbox.ForwardingSmtpAddress, $Mailbox.ForwardingAddress)) {
                    $Address = Get-RecipientAddress $Target
                    if ($Address) {
                        Add-Unique $ExternalForwardTargets $Address
                        Add-Reason $HighRiskReasons 'Mailbox-level forwarding configured'
                    }
                }
            } catch { }

            try {
                foreach ($Delegate in @($Mailbox.GrantSendOnBehalfTo)) {
                    $Address = Get-RecipientAddress $Delegate
                    if ($Address) { $SendOnBehalf += $Address }
                }
            } catch { }
        }

        try {
            $FullAccess = @(Get-IRWorkflowMailboxPermission -Identity $TargetUpn -ErrorAction Stop |
                Where-Object { -not $_.IsInherited -and $_.User -notmatch 'NT AUTHORITY\\SELF|S-1-5-10' -and ($_.AccessRights -contains 'FullAccess') } |
                ForEach-Object { [string]$_.User } |
                Sort-Object -Unique)

            $FullAccessAvailable = $true
            if ($FullAccess.Count -gt 0) { Add-Reason $ReviewReasons 'Mailbox permissions require review' }
        }
        catch {
            Add-Unique $DataGaps 'Full Access permissions unavailable'
            Add-Unique $CriticalDataGaps 'Full Access permissions unavailable'
        }

        try {
            $SendAs = @(Get-IRWorkflowRecipientPermission -Identity $TargetUpn -ErrorAction Stop |
                Where-Object { -not $_.IsInherited -and $_.Trustee -notmatch 'NT AUTHORITY\\SELF|S-1-5-10' -and ($_.AccessRights -contains 'SendAs') } |
                ForEach-Object { [string]$_.Trustee } |
                Sort-Object -Unique)

            $SendAsAvailable = $true
            if ($SendAs.Count -gt 0) { Add-Reason $ReviewReasons 'Mailbox permissions require review' }
        }
        catch {
            Add-Unique $DataGaps 'Send As permissions unavailable'
            Add-Unique $CriticalDataGaps 'Send As permissions unavailable'
        }

        if ($SendOnBehalf.Count -gt 0) { Add-Reason $ReviewReasons 'Mailbox permissions require review' }

        if ($CasMailbox) {
            try { if ($CasMailbox.PopEnabled -eq $true) { Add-Unique $LegacyAuth 'POP' } } catch { }
            try { if ($CasMailbox.ImapEnabled -eq $true) { Add-Unique $LegacyAuth 'IMAP' } } catch { }
            try { if ($CasMailbox.SmtpClientAuthenticationDisabled -ne $true) { Add-Unique $LegacyAuth 'SMTP' } } catch { }
            if ($LegacyAuth.Count -gt 0) { Add-Reason $ReviewReasons 'Legacy auth exposure' }
        }
    }
    else {
        # Delegated Graph mailbox settings do not provide equivalent cross-user access.
        Add-Unique $DataGaps 'Inbox rules unavailable; Exchange is required'
        Add-Unique $CriticalDataGaps 'Inbox rules unavailable'
    }

    # Dedupe repeated findings before output.
    $InboxRuleMap = @{}
    foreach ($Rule in @($InboxRules)) {
        $Key = "$($Rule.Name)|$($Rule.Actions)"
        if (-not $InboxRuleMap.ContainsKey($Key)) { $InboxRuleMap[$Key] = $Rule }
    }
    $InboxRules = @($InboxRuleMap.Values | Sort-Object Name, Actions)

    $ForwardRuleMap = @{}
    foreach ($Rule in @($ForwardingRules)) {
        $Key = "$($Rule.Name)|$($Rule.Actions)"
        if (-not $ForwardRuleMap.ContainsKey($Key)) { $ForwardRuleMap[$Key] = $Rule }
    }
    $ForwardingRules = @($ForwardRuleMap.Values | Sort-Object Name, Actions)

    $OAuthMap = @{}
    foreach ($Grant in @($UnverifiedOAuth)) {
        $Key = "$($Grant.App)|$($Grant.Scope)"
        if (-not $OAuthMap.ContainsKey($Key)) { $OAuthMap[$Key] = $Grant }
    }
    $UnverifiedOAuth = @($OAuthMap.Values | Sort-Object App, Scope)

    $RecentIpRows = New-Object System.Collections.Generic.List[object]
    $SeenIps = @{}
    foreach ($SignIn in @($SignIns48 | Sort-Object createdDateTime -Descending)) {
        $Ip = [string]$SignIn.ipAddress
        if ([string]::IsNullOrWhiteSpace($Ip) -or $SeenIps.ContainsKey($Ip)) { continue }

        $SeenIps[$Ip] = $true
        $Country = ''
        try { $Country = [string]$SignIn.location.countryOrRegion } catch { }

        [void]$RecentIpRows.Add([pscustomobject]@{
            Ip = $Ip
            LastSeen = $SignIn.createdDateTime
            Country = $Country
            Result = (SignInResult $SignIn)
        })

        if ($RecentIpRows.Count -ge 5) { break }
    }

    if ($CriticalDataGaps.Count -gt 0) {
        Add-Reason $ReviewReasons 'Required assessment data unavailable'
    }

    if ($HighRiskReasons.Count -gt 0) {
        $Summary = 'HIGH RISK'
        $Action = 'ESCALATE FOR BEC REVIEW / CONTAINMENT DECISION'
    }
    elseif ($CriticalDataGaps.Count -gt 0) {
        $Summary = 'REVIEW REQUIRED'
        $Action = 'Resolve unavailable assessment data before closure.'
    }
    elseif ($ReviewReasons.Count -gt 0) {
        $Summary = 'REVIEW REQUIRED'
        $Action = 'Review findings before closure.'
    }
    else {
        $Summary = 'NO HIGH-RISK FINDINGS'
        $Action = 'No containment action indicated.'
    }

    $Completed = Get-Date


    Section 'TARGET'
    Write-Host "UPN: $TargetUpn"
    Write-Host "Status: $(if ($TargetUser.accountEnabled) { 'Enabled' } else { 'Disabled' })"
    if (-not $MfaAvailable) {
        Write-Host 'MFA Methods: Not available'
    }
    elseif ($MfaMethods.Count -gt 0) {
        Write-Host "MFA Methods: $($MfaMethods -join '; ')"
    }
    else {
        Write-Host 'MFA Methods: None returned'
    }
    Write-Host "Created: $(Format-DateTime $TargetUser.createdDateTime 'MM/dd/yyyy')"
    Write-Host "Password Last Changed: $(Format-DateTime $TargetUser.lastPasswordChangeDateTime 'MM/dd/yyyy')"
    if ($SignInActivityDisplayReason -eq 'tenant licensing') {
        Write-Host 'Last Interactive Sign-In: Not available - tenant licensing'
    }
    elseif ($SignInActivityDisplayReason -eq 'unavailable') {
        Write-Host 'Last Interactive Sign-In: Not available'
    }
    else {
        Write-Host "Last Interactive Sign-In: $(Format-DateTime $LastInteractiveSignIn 'MM/dd/yyyy HH:mm')"
    }

    Write-Host ""
    $SummaryColor = if ($Summary -eq 'HIGH RISK') { 'Red' } elseif ($Summary -eq 'REVIEW REQUIRED') { 'Yellow' } else { 'Green' }
    Write-Host "$(if ($Summary -eq 'HIGH RISK') {'WARNING: HIGH-RISK FINDINGS'} else {"SUMMARY: $Summary"})" -ForegroundColor $SummaryColor
    if ($DataGaps.Count) {
        Write-Host "[!!] Not checked: $($DataGaps -join '; ')." -ForegroundColor Yellow
    }
    Write-Host "RECOMMENDATION: $Action"

    if ($HighRiskReasons.Count -gt 0) {
        Write-Host ""
        Write-Host 'HIGH-RISK FINDINGS'
        foreach ($Reason in $HighRiskReasons) {
            Write-Host "- $Reason"
        }
    }

    if ($ReviewReasons.Count -gt 0) {
        Write-Host ""
        Write-Host 'REVIEW ITEMS'
        foreach ($Reason in $ReviewReasons) {
            Write-Host "- $Reason"
        }
    }

    Section 'PRIVILEGED ROLES'
    if ($Roles.Count -gt 0) {
        foreach ($Role in $Roles) {
            Write-Host "Role: $Role"
        }
    }
    elseif ($RolesAvailable) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available'
    }

    Section 'SIGN-INS 48H'
    if ($SignIns48.Count -gt 0) {
        Write-Host "Status: $($SignIns48.Count) sampled sign-in(s) in the last 48 hours"
        foreach ($Row in $RecentIpRows) {
            $Line = "IP: $($Row.Ip) | Last Seen: $(Format-DateTime $Row.LastSeen 'MM/dd/yyyy HH:mm')"
            if (-not [string]::IsNullOrWhiteSpace($Row.Country)) {
                $Line = "$Line | Country: $($Row.Country)"
            }
            $Line = "$Line | Result: $($Row.Result)"
            Write-Host $Line
        }
    }
    elseif ($SignInsAvailable) {
        Write-Host 'Status: No sign-ins found in the last 48 hours'
    }
    else {
        Write-Host 'Status: Not available'
    }

    $VisibleInboxRules = @(
        $InboxRules | Where-Object { $_.IsHidden -ne $true }
    )

    $HiddenInboxRules = @(
        $InboxRules | Where-Object { $_.IsHidden -eq $true }
    )

    Section 'INBOX RULES - [ VISIBLE ]'

    if ($InboxRuleCoverage -eq 'Visible + Hidden' -or $InboxRuleCoverage -eq 'Visible Only') {
        if ($VisibleInboxRules.Count -gt 0) {
    
            for ($Index = 0; $Index -lt $VisibleInboxRules.Count; $Index++) {
                if ($Index -gt 0) {
                    Write-Host ""
                }

                $Rule = $VisibleInboxRules[$Index]
                Write-Host "Rule: $($Rule.Name)"
                Write-Host "Action: $($Rule.Actions)"
            }
        }
        else {
            Write-Host 'Status: No'
        }
    }
    else {
        Write-Host 'Status: Not available'
    }

    Section 'INBOX RULES - [ HIDDEN ]'

    if ($InboxRuleCoverage -eq 'Visible + Hidden') {
        if ($HiddenRuleFindings.Count -gt 0) {
    
            $HiddenFindingNames = @(
                $HiddenRuleFindings |
                    ForEach-Object {
                        if ($_ -match '^Hidden inbox rule: (.+)$') {
                            $Matches[1]
                        }
                        else {
                            $_
                        }
                    }
            )

            $SuspiciousHiddenRules = @(
                $HiddenInboxRules |
                    Where-Object {
                        $HiddenFindingNames -contains $_.Name
                    }
            )

            if ($SuspiciousHiddenRules.Count -gt 0) {
                for ($Index = 0; $Index -lt $SuspiciousHiddenRules.Count; $Index++) {
                    if ($Index -gt 0) {
                        Write-Host ""
                    }

                    $Rule = $SuspiciousHiddenRules[$Index]
                    Write-Host "Rule: $($Rule.Name)"
                    Write-Host "Action: $($Rule.Actions)"
                }
            }
            else {
                foreach ($Finding in $HiddenRuleFindings) {
                    Write-Host "Finding: $Finding"
                }
            }
        }
        else {
            Write-Host 'Status: No suspicious rules'
        }
    }
    else {
        Write-Host 'Status: Not available'
    }

    Write-Host ""
    Write-Host 'EXTERNAL FORWARDING'
    if ($ExternalForwardTargets.Count -gt 0 -or $ForwardingRules.Count -gt 0) {
        foreach ($Target in @($ExternalForwardTargets | Sort-Object -Unique)) {
            Write-Host "Target: $Target"
        }
        if ($Mailbox) {
            Write-Host "Deliver copy to mailbox: $($Mailbox.DeliverToMailboxAndForward)"
        }
        foreach ($Rule in $ForwardingRules) {
            Write-Host "Rule: $($Rule.Name)"
            Write-Host "Action: $($Rule.Actions)"
        }
    }
    elseif (
        $MailboxObjectAvailable -and
        ($InboxRuleCoverage -eq 'Visible + Hidden')
    ) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available'
    }

    Section 'MAILBOX PERMISSIONS'
    if ($FullAccess.Count -gt 0 -or $SendAs.Count -gt 0) {
        foreach ($Item in $FullAccess) {
            Write-Host "Full Access: $Item"
        }
        foreach ($Item in $SendAs) {
            Write-Host "Send As: $Item"
        }
    }
    elseif ($FullAccessAvailable -and $SendAsAvailable) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available'
    }

    Section 'UNVERIFIED OAUTH GRANTS'
    if ($UnverifiedOAuth.Count -gt 0) {
        foreach ($Grant in $UnverifiedOAuth) {
            Write-Host "App: $($Grant.App)"
            Write-Host "Scope: $($Grant.Scope)"
        }
    }
    elseif ($OAuthAvailable) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available'
    }

    Section 'LEGACY AUTH PROTOCOLS'
    if ($LegacyAuth.Count -gt 0) {
        foreach ($Item in $LegacyAuth) {
            Write-Host $Item
        }
    }
    elseif ($CasMailboxAvailable) {
        Write-Host 'Status: No'
    }
    else {
        Write-Host 'Status: Not available; please review in M365 Admin portal.'
    }

    Section $(if ($RolesAvailable -and $Roles.Count -eq 0 -and $MailboxObjectAvailable -and $SendOnBehalf.Count -eq 0 -and $SignInsAvailable -and $FailedSignIns.Count -eq 0) { 'ALL CLEAR - ADDITIONAL CHECKS' } else { 'ADDITIONAL CHECKS' })
    if ($Roles.Count -eq 0 -and $RolesAvailable) {
        Write-Host 'Privileged Roles: No'
    }
    elseif (-not $RolesAvailable) {
        Write-Host 'Privileged Roles: Not available'
    }

    if ($SendOnBehalf.Count -gt 0) {
        Write-Host "Send On Behalf: $($SendOnBehalf -join '; ')"
    }
    elseif ($MailboxObjectAvailable) {
        Write-Host 'Send On Behalf: No'
    }
    else {
        Write-Host 'Send On Behalf: Not available'
    }

    if ($FailedSignIns.Count -gt 0) {
        Write-Host "Failed Sign-ins: $($FailedSignIns.Count) in recent 10-day sample"
    }
    elseif ($SignInsAvailable) {
        Write-Host 'Failed Sign-ins: None in recent 10-day sample'
    }
    else {
        Write-Host 'Failed Sign-ins: Not available'
    }

    Section 'CONDITIONAL ACCESS POLICIES - [ ENABLED ]'
    Write-Host 'Policy inventory; user coverage still requires verification.'
    if (
        $ConditionalAccessPolicyStatus -eq 'Available' -and
        $ConditionalAccessEnabledPolicies.Count -gt 0
    ) {
        foreach ($Policy in $ConditionalAccessEnabledPolicies) {
            Write-Host "Policy: $(Format-ConditionalAccessPolicyName $Policy)"
        }
    }
    elseif ($ConditionalAccessPolicyStatus -eq 'Available') {
        Write-Host 'None'
    }
    elseif ($ConditionalAccessPolicyStatus -eq 'Unavailable') {
        Write-Host 'Unable to retrieve'
    }
    else {
        Write-Host 'Unknown'
    }

    $global:FieldKitIRSession.Assessment = @{
        Completed=Get-Date; Summary=$Summary; UserId=[string]$TargetUser.id
        InitialStatus=$(if ($TargetUser.accountEnabled) {'Enabled'} else {'Disabled'})
        HighRisk=@($HighRiskReasons); Review=@($ReviewReasons); Gaps=@($DataGaps)
    }
    Write-Host "`nCOMPLETED: $((Get-Date).ToString('MM/dd/yyyy HH:mm'))"
    Section 'NEXT STEP: DECISION POINT'
    if ($HighRiskReasons.Count -gt 0) {
        Write-Host 'ESCALATION REVIEW'
        Write-Host 'Review the high-risk findings and decide whether to contain this account.'
    }
    elseif ($CriticalDataGaps.Count -gt 0 -or $ReviewReasons.Count -gt 0) {
        Section 'NEXT - REVIEW'
        Write-Host 'Resolve the review items. Continue to containment if the incident evidence warrants it.'
    }
    else {
        Write-Host 'NO CONTAINMENT INDICATED'
        Write-Host 'No high-risk findings in the checks completed. Continue only if other incident evidence warrants response.'
    }
    Write-Host 'N: document findings and return to PowerShell.'
    Write-Host 'Y: contain the account and review persistence removal.'
    Write-Host 'IR-INVOKE-CONTAINMENT-ERADICATION'
    $script:NextIRFile='IR-INVOKE-CONTAINMENT-ERADICATION'

}
catch {
    Write-Host "[FAIL] Assessment incomplete: $($_.Exception.Message)" -ForegroundColor Red
    Section 'NEXT'
    Write-Host 'IR-GET-IDENTITY-RISK-ASSESSMENT'
    Write-Host 'Resolve the reported checks and rerun. Confirmed compromise can still require approved containment.'
}
finally {
    if ($null -ne $OriginalTitle) {
        try { $Host.UI.RawUI.WindowTitle = $OriginalTitle } catch { }
    }
}

Invoke-IRNextStep -FileName $script:NextIRFile -Objective 'Next: contain the account and review approved persistence removal.'
