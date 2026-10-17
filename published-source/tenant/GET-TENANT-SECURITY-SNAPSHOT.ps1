<#PSScriptInfo
.VERSION 0.1.0
.GUID dc906537-b32e-7d31-a04d-cc3f5507b455
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
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


# Console presentation only. Does not request scopes, query services or write data.
$script:FKEndWritten = $false
$script:FKStatusWritten = $false
$script:FKHasIssue = $false
function Write-FKStatus {
    param([string]$Status)
    Write-Host ''
    if ($Status -eq 'REVIEW REQUIRED') { Write-Host ('STATUS: '+$Status) -ForegroundColor Yellow }
    else { Write-Host ('STATUS: '+$Status) }
    $script:FKStatusWritten = $true
}
function Write-FKStart {
    param([string]$Title,[string]$Objective,[string]$Mode)
    Write-Host $Title
    Write-Host $Objective
    if ($Mode) { Write-Host $Mode }
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Host ''
}
function Write-FKHeading {
    param([string]$Title)
    Write-Host ''
    switch ($Title.Trim().ToUpperInvariant()) {
        'SUMMARY' { Write-Host 'TICKET SUMMARY'; break }
        'FOLLOW-UP' { Write-Host 'NEXT STEP'; break }
        'NEXT' { Write-Host 'NEXT STEP'; break }
        default { Write-Host $Title }
    }
}
function Close-FKConsole {
    param([bool]$SkipPause = $false)
    if (-not $script:FKEndWritten) {
        Write-Host ''
        if (-not $script:FKStatusWritten) {
            Write-FKStatus $(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } else { 'RUN FINISHED' })
        }
        Write-Host ("COMPLETED: {0}" -f (Get-Date).ToString('MM/dd/yyyy HH:mm'))
        $script:FKEndWritten = $true
    }
    if ($SkipPause) { return }
    Write-Host ''
    Write-Host 'Press ESC to close'
    if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and
        (Get-Command Read-Host).CommandType -ne 'Function') {
        try {
            while ($true) {
                $key=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                if ($key.VirtualKeyCode -eq 27 -or $key.VirtualKeyCode -eq 13) { return }
            }
        }
        catch { Write-Host 'Key input unavailable here.' }
    }
    while ($true) {
        $answer=Read-Host 'Type ESC then press ENTER to close'
        if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -ieq 'ESC' -or $answer -eq [string][char]27) { return }
    }
}

function Write-OK {
    param([string]$Message)
    Write-Host '[OK] ' -ForegroundColor Green -NoNewline
    Write-Host $Message
}
function Write-Info {
    param([string]$Message)
    Write-Host '[INFO] ' -NoNewline
    Write-Host $Message
}
function Write-Warn {
    param([string]$Message)
    $script:FKHasIssue = $true
    Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}
function Write-Fail {
    param([string]$Message)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Pause-End {
    Close-FKConsole
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
    Write-FKHeading -Title $Title
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
    Write-FKStart -Title 'TENANT SECURITY SNAPSHOT' -Objective 'Gives a fast tenant security overview before you open the deeper focused audits.' -Mode ''
    Write-Host ''
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
