<#
GET-TENANT-SECURITY-SNAPSHOT.ps1

Read-only tenant security overview.

Purpose:
- Gives a fast tenant-level view before deeper focused audits
- Summarizes users and stale enabled accounts
- Summarizes Conditional Access policy state
- Summarizes active Entra admin roles
- Counts delegated OAuth grants

Read-only. No changes are made.
#>

param(
    [int]$StaleDays = 90
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

function Ensure-Graph {
    param([string[]]$Scopes)

    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph.Authentication is not installed. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop | Out-Null

    $Context = Get-MgContext -ErrorAction SilentlyContinue
    $NeedsConnect = $true

    if ($Context) {
        $NeedsConnect = $false
        foreach ($Scope in $Scopes) {
            if (@($Context.Scopes) -notcontains $Scope) {
                $NeedsConnect = $true
                break
            }
        }
    }

    if (-not $NeedsConnect) {
        Write-OK "Graph session reused"
        return
    }

    if ($Context) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    $Parameters = @{
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

    if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
        throw "Microsoft Graph connection could not be validated."
    }

    Write-OK "Graph connected"
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

    Write-Host ("{0}: Not available" -f $Label)
    Write-Warn (Get-ShortError $ErrorRecord)
}

try {
    try { $Host.UI.RawUI.WindowTitle = "Tenant Security Snapshot" } catch {}

    Clear-Host
    Write-Host "TENANT SECURITY SNAPSHOT"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host "Fast overview only. Use focused audits for deeper review."
    Write-Host ""

    $Scopes = @(
        "Organization.Read.All",
        "User.Read.All",
        "AuditLog.Read.All",
        "Directory.Read.All",
        "RoleManagement.Read.Directory",
        "Policy.Read.ConditionalAccess",
        "DelegatedPermissionGrant.Read.All"
    )

    Ensure-Graph -Scopes $Scopes

    Write-Section "ORGANIZATION"
    try {
        $Organizations = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/organization?`$select=id,displayName,verifiedDomains")
        $Organization = $Organizations | Select-Object -First 1

        if ($Organization) {
            Write-Host "Name    : $($Organization.displayName)"

            $DefaultDomain = @($Organization.verifiedDomains | Where-Object { $_.isDefault -eq $true } | Select-Object -First 1)
            if ($DefaultDomain.Count -gt 0) {
                Write-Host "Domain  : $($DefaultDomain[0].name)"
            }
        }
        else {
            Write-Host "Organization: Not available"
        }
    }
    catch {
        Write-Unavailable -Label "Organization" -ErrorRecord $_
    }

    Write-Section "USERS"
    try {
        $UsersUri = "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,accountEnabled,userType,signInActivity&`$top=999"
        $Users = @(Get-GraphPages -Uri $UsersUri)

        $Enabled = @($Users | Where-Object { $_.accountEnabled -eq $true })
        $Disabled = @($Users | Where-Object { $_.accountEnabled -eq $false })
        $Guests = @($Users | Where-Object { $_.userType -eq "Guest" })
        $Stale = New-Object System.Collections.ArrayList

        foreach ($User in $Enabled) {
            $Last = $null
            try {
                if ($User.signInActivity.lastSignInDateTime) {
                    $Last = [datetime]$User.signInActivity.lastSignInDateTime
                }
            }
            catch {
                $Last = $null
            }

            if ($Last -and ((Get-Date) - $Last.ToLocalTime()).TotalDays -gt $StaleDays) {
                [void]$Stale.Add($User)
            }
        }

        Write-Host "Total users          : $($Users.Count)"
        Write-Host "Enabled users        : $($Enabled.Count)"
        Write-Host "Disabled users       : $($Disabled.Count)"
        Write-Host "Guest users          : $($Guests.Count)"
        Write-Host "Stale enabled > $StaleDays d: $($Stale.Count)"

        if ($Stale.Count -gt 0) {
            Write-Host ""
            Write-Host "Oldest stale enabled accounts (first 15):"
            $Stale |
                Sort-Object { [datetime]$_.signInActivity.lastSignInDateTime } |
                Select-Object -First 15 |
                ForEach-Object {
                    Write-Host ("- {0} | {1}" -f $_.userPrincipalName, $_.signInActivity.lastSignInDateTime)
                }
        }
    }
    catch {
        Write-Unavailable -Label "Users" -ErrorRecord $_
    }

    Write-Section "CONDITIONAL ACCESS"
    try {
        $Policies = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?`$select=id,displayName,state")
        Write-Host "Policies    : $($Policies.Count)"
        Write-Host "Enabled     : $(@($Policies | Where-Object { $_.state -eq 'enabled' }).Count)"
        Write-Host "Report-only : $(@($Policies | Where-Object { $_.state -eq 'enabledForReportingButNotEnforced' }).Count)"
        Write-Host "Disabled    : $(@($Policies | Where-Object { $_.state -eq 'disabled' }).Count)"
    }
    catch {
        Write-Unavailable -Label "Conditional Access" -ErrorRecord $_
    }

    Write-Section "ACTIVE ADMIN ROLES"
    try {
        $Roles = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/directoryRoles?`$select=id,displayName")
        $AssignmentCount = 0

        foreach ($Role in ($Roles | Sort-Object displayName)) {
            try {
                $Members = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/directoryRoles/$($Role.id)/members?`$select=id")
                $AssignmentCount += $Members.Count
                Write-Host ("- {0}: {1}" -f $Role.displayName, $Members.Count)
            }
            catch {
                Write-Warn ("{0}: member count unavailable" -f $Role.displayName)
            }
        }

        Write-Host ""
        Write-Host "Active assignments: $AssignmentCount"
    }
    catch {
        Write-Unavailable -Label "Admin roles" -ErrorRecord $_
    }

    Write-Section "DELEGATED OAUTH CONSENT"
    try {
        $Grants = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?`$select=id,clientId,resourceId,consentType,scope")
        Write-Host "Delegated grants: $($Grants.Count)"
        Write-Host "All-principals grants: $(@($Grants | Where-Object { $_.consentType -eq 'AllPrincipals' }).Count)"
    }
    catch {
        Write-Unavailable -Label "OAuth consent" -ErrorRecord $_
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
