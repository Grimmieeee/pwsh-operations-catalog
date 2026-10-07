<#
GET-USER-SECURITY-SNAPSHOT.ps1

Read-only one-user security snapshot.

Purpose:
- Reviews identity state and hybrid source
- Shows password age and registered authentication methods
- Shows active admin roles and direct group memberships
- Shows recent Entra sign-ins

Read-only. No changes are made.
#>

param(
    [string]$UPN,
    [int]$SignInHours = 48
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function Write-OK   { param($Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "[INFO] $Message" }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param($Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
}

function Get-ShortError {
    param($ErrorRecord)

    $Message = $ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = [string]$ErrorRecord
    }

    return (($Message -replace "\s+", " ").Trim())
}

function Ensure-GraphModule {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph.Authentication is not installed. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop | Out-Null
}

function Test-GraphScopes {
    param(
        [object]$Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) { return $false }

    foreach ($Scope in $RequiredScopes) {
        if (@($Context.Scopes) -notcontains $Scope) {
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

function Get-GraphPages {
    param([string]$Uri)

    $Items = New-Object System.Collections.ArrayList

    while ($Uri) {
        $Page = Invoke-GraphGet -Uri $Uri

        foreach ($Item in @($Page.value)) {
            [void]$Items.Add($Item)
        }

        $Uri = [string]$Page.'@odata.nextLink'
    }

    return @($Items)
}

function Resolve-GraphUser {
    param([string]$UserPrincipalName)

    $Encoded = [System.Uri]::EscapeDataString($UserPrincipalName)
    $Uri = (
        "https://graph.microsoft.com/v1.0/users/{0}" +
        "?`$select=id,displayName,userPrincipalName,accountEnabled,userType," +
        "onPremisesSyncEnabled,onPremisesDomainName,lastPasswordChangeDateTime"
    ) -f $Encoded

    return Invoke-GraphGet -Uri $Uri
}

function Connect-GraphForUser {
    param(
        [string]$UserPrincipalName,
        [string[]]$Scopes
    )

    Ensure-GraphModule

    $Context = Get-MgContext -ErrorAction SilentlyContinue

    if ($Context -and (Test-GraphScopes -Context $Context -RequiredScopes $Scopes)) {
        try {
            $User = Resolve-GraphUser -UserPrincipalName $UserPrincipalName
            if ($User -and $User.id) {
                Write-OK "Graph session reused"
                return $User
            }
        }
        catch {
            Write-Warn "Existing Graph session could not resolve the target user. Reconnecting."
        }
    }

    if ($Context) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    $Domain = ($UserPrincipalName -split '@')[-1]
    $Parameters = @{
        TenantId     = $Domain
        Scopes       = $Scopes
        ContextScope = 'Process'
        ErrorAction  = 'Stop'
    }

    $Command = Get-Command Connect-MgGraph -ErrorAction Stop
    if ($Command.Parameters.ContainsKey('NoWelcome')) {
        $Parameters.NoWelcome = $true
    }

    Write-Info "Connecting to Microsoft Graph..."
    Connect-MgGraph @Parameters | Out-Null

    $User = Resolve-GraphUser -UserPrincipalName $UserPrincipalName
    if (-not $User -or -not $User.id) {
        throw "The target user was not found in the connected tenant."
    }

    Write-OK "Graph connected"
    return $User
}

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("-" * $Title.Length) -ForegroundColor Cyan
}

function Write-Unavailable {
    param(
        [string]$Label,
        $ErrorRecord
    )

    Write-Host "Status : Not available"
    Write-Warn ("{0}: {1}" -f $Label, (Get-ShortError $ErrorRecord))
}

try {
    try { $Host.UI.RawUI.WindowTitle = "User Security Snapshot" } catch {}

    Clear-Host
    Write-Host "USER SECURITY SNAPSHOT"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        $UPN = (Read-Host "User UPN").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($UPN) -or $UPN -notmatch '@') {
        throw "A valid user UPN is required."
    }

    $Scopes = @(
        "User.Read.All",
        "UserAuthenticationMethod.Read.All",
        "Directory.Read.All",
        "AuditLog.Read.All"
    )

    $User = Connect-GraphForUser -UserPrincipalName $UPN -Scopes $Scopes

    Write-Section "IDENTITY"

    $PasswordAge = "Unavailable"
    if ($User.lastPasswordChangeDateTime) {
        try {
            $LastPasswordChange = [datetime]$User.lastPasswordChangeDateTime
            $PasswordAge = [int]((Get-Date) - $LastPasswordChange.ToLocalTime()).TotalDays
        }
        catch {
            $PasswordAge = "Unavailable"
        }
    }

    Write-Host "Name             : $($User.displayName)"
    Write-Host "UPN              : $($User.userPrincipalName)"
    Write-Host "Enabled          : $($User.accountEnabled)"
    Write-Host "User type        : $($User.userType)"
    Write-Host "Hybrid synced    : $($User.onPremisesSyncEnabled -eq $true)"
    Write-Host "On-prem domain   : $($User.onPremisesDomainName)"
    Write-Host "Password age days: $PasswordAge"

    Write-Section "MFA METHODS"
    try {
        $Methods = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/users/$($User.id)/authentication/methods")

        if ($Methods.Count -eq 0) {
            Write-Host "None returned"
        }
        else {
            foreach ($Method in $Methods) {
                $Type = [string]$Method.'@odata.type'
                if ([string]::IsNullOrWhiteSpace($Type)) {
                    $Type = "Unknown authentication method"
                }
                else {
                    $Type = $Type -replace '^#microsoft\.graph\.', ''
                }

                Write-Host ("- {0}" -f $Type)
            }
        }
    }
    catch {
        Write-Unavailable -Label "MFA methods query failed" -ErrorRecord $_
    }

    Write-Section "ACTIVE ADMIN ROLES"
    try {
        $RolesUri = "https://graph.microsoft.com/v1.0/users/$($User.id)/memberOf/microsoft.graph.directoryRole?`$select=id,displayName"
        $Roles = @(Get-GraphPages -Uri $RolesUri)

        if ($Roles.Count -eq 0) {
            Write-Host "None found"
        }
        else {
            $Roles | Sort-Object displayName | ForEach-Object {
                Write-Host ("- {0}" -f $_.displayName)
            }
        }
    }
    catch {
        Write-Unavailable -Label "Admin role query failed" -ErrorRecord $_
    }

    Write-Section "DIRECT GROUPS"
    try {
        $GroupsUri = "https://graph.microsoft.com/v1.0/users/$($User.id)/memberOf/microsoft.graph.group?`$select=id,displayName,mail,onPremisesSyncEnabled"
        $Groups = @(Get-GraphPages -Uri $GroupsUri)

        if ($Groups.Count -eq 0) {
            Write-Host "None found"
        }
        else {
            $Groups | Sort-Object displayName | ForEach-Object {
                $Source = if ($_.onPremisesSyncEnabled -eq $true) { "AD synced" } else { "Cloud" }
                Write-Host ("- {0} [{1}]" -f $_.displayName, $Source)
            }
        }
    }
    catch {
        Write-Unavailable -Label "Group membership query failed" -ErrorRecord $_
    }

    Write-Section "RECENT SIGN-INS"
    try {
        $Since = (Get-Date).ToUniversalTime().AddHours(-1 * [math]::Abs($SignInHours)).ToString("yyyy-MM-ddTHH:mm:ssZ")
        $Filter = [System.Uri]::EscapeDataString("userId eq '$($User.id)' and createdDateTime ge $Since")
        $SignInUri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$filter=$Filter&`$top=20&`$orderby=createdDateTime desc"
        $SignIns = @(Get-GraphPages -Uri $SignInUri)

        if ($SignIns.Count -eq 0) {
            Write-Host "No sign-ins returned for the selected window"
        }
        else {
            foreach ($SignIn in ($SignIns | Select-Object -First 20)) {
                $When = [datetime]$SignIn.createdDateTime
                $Status = if ($SignIn.status.errorCode -eq 0) { "Success" } else { "Failed" }
                $Country = [string]$SignIn.location.countryOrRegion
                Write-Host ("- {0} | {1} | {2} | {3} | {4}" -f $When.ToLocalTime(), $Status, $SignIn.ipAddress, $Country, $SignIn.appDisplayName)
            }
        }
    }
    catch {
        Write-Unavailable -Label "Sign-in query failed" -ErrorRecord $_
    }

    Write-Host ""
    Write-OK "Snapshot complete"
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
