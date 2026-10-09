<#
GET-ADMIN-ROLE-AUDIT.ps1

Read-only tenant admin role audit.

Purpose:
- Reviews active Entra directory role assignments
- Includes user status, hybrid status, and last sign-in where available
- Optional CSV export only when approved
#>

param(
    [int]$StaleDays = 30
)
$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function RISK($m) { Write-Host "[RISK] $m" -ForegroundColor Red }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host "--------------------------------------" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "Timestamp: $(Now)" -ForegroundColor Cyan
    Write-Host "--------------------------------------" -ForegroundColor Cyan
}

function Confirm-Yes {
    param([string]$Prompt)

    $a = Read-Host "$Prompt [Y/N]"
    return ($a.Trim().ToUpper() -eq "Y")
}

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    WARN $Prompt
    $a = Read-Host "Type $Required to continue"

    return ($a.Trim().ToUpper() -eq $Required.ToUpper())
}

function Encode-Value {
    param([string]$Value)
    return [System.Uri]::EscapeDataString($Value)
}

function Escape-OData {
    param([string]$Value)
    return ($Value -replace "'", "''")
}

function Clean-Name {
    param([object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    $text = [string]$Value
    return ($text -replace '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$', '').Trim()
}

function Get-InputLines {
    param([string]$Path)

    if (-not $Path) {
        $Path = (Read-Host "Input TXT/CSV path").Trim().Trim('"')
    }

    if (-not $Path -or -not (Test-Path $Path)) {
        FAIL "Input file not found"
        return @()
    }

    $items = New-Object System.Collections.ArrayList

    try {
        if ($Path.ToLower().EndsWith(".csv")) {
            $rows = Import-Csv -Path $Path -ErrorAction Stop

            foreach ($row in $rows) {
                $value = $null

                foreach ($name in @("UPN","UserPrincipalName","Email","Address","Group","GroupName","Name","Input")) {
                    if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                        $value = "$($row.$name)"
                        break
                    }
                }

                if (-not $value) {
                    $first = $row.PSObject.Properties | Select-Object -First 1
                    if ($first) { $value = "$($first.Value)" }
                }

                if ($value -and $value.Trim()) {
                    [void]$items.Add($value.Trim().Trim('"'))
                }
            }
        }
        else {
            $lines = Get-Content -Path $Path -Encoding UTF8 -ErrorAction Stop

            foreach ($line in $lines) {
                $clean = $line.Trim().Trim('"')

                if ($clean -and $clean -notmatch '^#') {
                    [void]$items.Add($clean)
                }
            }
        }
    }
    catch {
        FAIL "Could not read input file"
        return @()
    }

    return @($items | Select-Object -Unique)
}

function Offer-ExportCsv {
    param(
        [array]$Rows,
        [string]$DefaultName
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return
    }

    if (-not (Confirm-Yes "Export results to CSV")) {
        return
    }

    $path = Read-Host "CSV output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        OK "Exported: $path"
    }
    catch {
        WARN "CSV export failed"
    }
}

function Graph-Get {
    param([string]$Uri)

    try {
        return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop
    } catch {
        return $null
    }
}

function Ensure-Graph {
    param([string[]]$Scopes)

    Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue | Out-Null

    if (-not (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue)) {
        FAIL "Microsoft.Graph.Authentication module not available"
        Write-Host "Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
        return $false
    }

    $ctx = Get-MgContext -ErrorAction SilentlyContinue

    if (-not $ctx) {
        WARN "Graph not connected"

        if (-not (Confirm-Yes "Connect to Graph now")) {
            return $false
        }

        try {
            Connect-MgGraph -Scopes $Scopes -ContextScope Process -NoWelcome -ErrorAction Stop | Out-Null
        }
        catch {
            try {
                Connect-MgGraph -Scopes $Scopes -ContextScope Process -ErrorAction Stop | Out-Null
            }
            catch {
                FAIL "Graph connection failed"
                return $false
            }
        }
    }

    $ctx = Get-MgContext -ErrorAction SilentlyContinue

    if ($ctx) {
        OK "Graph connected"
        return $true
    }

    FAIL "Graph unavailable"
    return $false
}

function Get-GraphPages {
    param([string]$Uri)

    $items = New-Object System.Collections.ArrayList

    while ($Uri) {
        $page = Graph-Get $Uri

        if (-not $page) {
            break
        }

        foreach ($item in @($page.value)) {
            [void]$items.Add($item)
        }

        $Uri = $page.'@odata.nextLink'
    }

    return @($items)
}

function Get-GraphUserByUPN {
    param([string]$UPN)

    $encoded = Encode-Value $UPN
    $uri = "https://graph.microsoft.com/v1.0/users/$encoded?`$select=id,displayName,userPrincipalName,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,signInActivity,lastPasswordChangeDateTime"
    $user = Graph-Get $uri

    if ($user -and $user.id) {
        return $user
    }

    $escaped = Escape-OData $UPN
    $filter = Encode-Value "userPrincipalName eq '$escaped' or mail eq '$escaped'"
    $uri = "https://graph.microsoft.com/v1.0/users?`$filter=$filter&`$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,signInActivity,lastPasswordChangeDateTime"
    $fallback = Graph-Get $uri

    if ($fallback -and $fallback.value -and @($fallback.value).Count -gt 0) {
        return @($fallback.value)[0]
    }

    return $null
}

function Get-GraphGroupByInput {
    param([string]$InputValue)

    $escaped = Escape-OData $InputValue
    $filter = Encode-Value "displayName eq '$escaped' or mail eq '$escaped'"
    $uri = "https://graph.microsoft.com/v1.0/groups?`$filter=$filter&`$select=id,displayName,mail,securityEnabled,mailEnabled,groupTypes,onPremisesSyncEnabled"
    $result = Graph-Get $uri

    if ($result -and $result.value -and @($result.value).Count -gt 0) {
        return @($result.value)[0]
    }

    return $null
}

function Get-RiskOAuth {
    param([string]$Scope)

    if (-not $Scope) { return $false }

    $patterns = @(
        "Mail.",
        "Mailbox",
        "Files.Read",
        "Files.ReadWrite",
        "Sites.",
        "Directory.",
        "Group.",
        "User.ReadWrite",
        "User.Read.All",
        "Calendars.ReadWrite",
        "Contacts.ReadWrite",
        "offline_access",
        "full_access_as_user"
    )

    foreach ($p in $patterns) {
        if ($Scope -like "*$p*") {
            return $true
        }
    }

    return $false
}

try {
    try { $host.UI.RawUI.WindowTitle = "Tenant Admin Roles Audit" } catch {}

    Clear-Host
    Write-Host "TENANT ADMIN ROLES AUDIT"
    Write-Host "Read-only"
    Write-Host ""

    if (-not (Ensure-Graph -Scopes @("Directory.Read.All","RoleManagement.Read.Directory","User.Read.All","AuditLog.Read.All"))) {
        Pause-End
        exit 1
    }

    Section "AUDIT"

    $roles = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/directoryRoles")
    $rows = New-Object System.Collections.ArrayList

    foreach ($role in $roles) {
        INFO "Checking role: $($role.displayName)"
        $members = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/directoryRoles/$($role.id)/members?`$select=id,displayName,userPrincipalName,accountEnabled,userType,onPremisesSyncEnabled,signInActivity")

        foreach ($m in $members) {
            $last = ""
            $days = ""

            try {
                if ($m.signInActivity.lastSignInDateTime) {
                    $last = ([datetime]$m.signInActivity.lastSignInDateTime).ToLocalTime()
                    $days = [int]((Get-Date) - $last).TotalDays
                }
            } catch {}

            $finding = "Admin role assigned"
            if ($m.accountEnabled -eq $false) { $finding = "Disabled admin" }
            elseif ($days -is [int] -and $days -gt $StaleDays) { $finding = "Stale admin sign-in" }

            [void]$rows.Add([pscustomobject]@{
                Role=$role.displayName
                DisplayName=$m.displayName
                UPN=$m.userPrincipalName
                AccountEnabled=$m.accountEnabled
                UserType=$m.userType
                Hybrid=($m.onPremisesSyncEnabled -eq $true)
                LastSignIn=$last
                DaysSinceSignIn=$days
                Finding=$finding
            })
        }
    }

    Section "SUMMARY"
    Write-Host "Roles checked : $($roles.Count)"
    Write-Host "Assignments   : $($rows.Count)"
    Write-Host "Disabled admin: $(@($rows | Where-Object { $_.Finding -eq 'Disabled admin' }).Count)"
    Write-Host "Stale admin   : $(@($rows | Where-Object { $_.Finding -eq 'Stale admin sign-in' }).Count)"
    Write-Host ""

    foreach ($r in ($rows | Sort-Object Role,UPN | Select-Object -First 100)) {
        if ($r.Finding -eq "Disabled admin" -or $r.Finding -eq "Stale admin sign-in") {
            WARN "$($r.Role) | $($r.UPN) | $($r.Finding)"
        } else {
            Write-Host "$($r.Role) | $($r.UPN)"
        }
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "tenant-admin-roles-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
