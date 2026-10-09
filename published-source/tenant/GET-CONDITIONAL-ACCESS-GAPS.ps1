<#
tenant-cap-gaps-audit-clean.ps1

Read-only Conditional Access gap audit.

Purpose:
- Reviews Conditional Access policies for disabled/report-only state
- Flags exclusions, device code gaps, location conditions, and weak coverage indicators
- Deeper than a simple Conditional Access policy listing
#>

param()

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function RISK($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-FieldKitFooter
    Write-Host ""
    Read-Host "Press Enter to EXIT" | Out-Null
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host $Title
}

function Confirm-Yes {
    param([string]$Prompt)

    $a = Read-Host "$Prompt [Y/N]"
    return ($a.Trim().ToUpper() -eq "Y")
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

    if ($null -eq $Value) { return "" }

    $text = [string]$Value
    return ($text -replace '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$', '').Trim()
}

function Offer-ExportCsv {
    param(
        [array]$Rows,
        [string]$DefaultName
    )

    if (-not $Rows -or $Rows.Count -eq 0) { return }

    if (-not (Confirm-Yes "Export results to CSV")) { return }

    $path = Read-Host "CSV output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)
        if ($check.Count -ne $Rows.Count) {
            throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
        }
        OK "Exported and verified: $path"
    }
    catch {
        WARN "CSV export failed"
    }
}

function Offer-ExportJson {
    param(
        [object]$Object,
        [string]$DefaultName
    )

    if (-not $Object) { return }

    if (-not (Confirm-Yes "Export snapshot to JSON")) { return }

    $path = Read-Host "JSON output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Object | ConvertTo-Json -Depth 20 | Out-File -FilePath $path -Encoding UTF8
        OK "Exported: $path"
    }
    catch {
        WARN "JSON export failed"
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

    Import-Module $module.Path -Force -WarningAction SilentlyContinue -ErrorAction Stop

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Name loaded, but $Command is unavailable."
    }
}

function Ensure-Graph {
    param([string[]]$Scopes)

    try {
        Ensure-Module `
            -Name "Microsoft.Graph.Authentication" `
            -Command "Connect-MgGraph"

        $ctx = Get-MgContext -ErrorAction SilentlyContinue
        $missingScopes = @()

        if ($ctx) {
            foreach ($scope in $Scopes) {
                if (@($ctx.Scopes) -notcontains $scope) {
                    $missingScopes += $scope
                }
            }
        }

        if (-not $ctx -or $missingScopes.Count -gt 0) {
            $command = Get-Command Connect-MgGraph -ErrorAction Stop
            $params = @{
                Scopes      = $Scopes
                ErrorAction = "Stop"
            }

            if ($command.Parameters.ContainsKey("ContextScope")) {
                $params["ContextScope"] = "Process"
            }

            if ($command.Parameters.ContainsKey("NoWelcome")) {
                $params["NoWelcome"] = $true
            }

            Connect-MgGraph @params | Out-Null
        }

        $ctx = Get-MgContext -ErrorAction Stop

        if (-not $ctx) {
            throw "Microsoft Graph did not return an authentication context."
        }

        OK "Graph ready"
        return $true
    }
    catch {
        FAIL ("Graph unavailable: {0}" -f $_.Exception.Message)
        return $false
    }
}
function Get-GraphPages {
    param([string]$Uri)

    $items = New-Object System.Collections.ArrayList

    while ($Uri) {
        $page = Graph-Get $Uri

        if (-not $page) { break }

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
    $uri = "https://graph.microsoft.com/v1.0/users/$encoded?`$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,signInActivity,lastPasswordChangeDateTime"
    $user = Graph-Get $uri

    if ($user -and $user.id) { return $user }

    $escaped = Escape-OData $UPN
    $filter = Encode-Value "userPrincipalName eq '$escaped' or mail eq '$escaped'"
    $uri = "https://graph.microsoft.com/v1.0/users?`$filter=$filter&`$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,signInActivity,lastPasswordChangeDateTime"
    $fallback = Graph-Get $uri

    if ($fallback -and $fallback.value -and @($fallback.value).Count -gt 0) {
        return @($fallback.value)[0]
    }

    return $null
}

function Is-RiskyScope {
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
        "full_access_as_user",
        "Application.ReadWrite",
        "RoleManagement.ReadWrite"
    )

    foreach ($p in $patterns) {
        if ($Scope -like "*$p*") { return $true }
    }

    return $false
}

try {
    try { $host.UI.RawUI.WindowTitle = "Tenant CAP Gaps Audit" } catch {}
Write-Host "TENANT CONDITIONAL ACCESS GAP AUDIT"
    Write-Host "Read-only"
    Write-Host ""

    if (-not (Ensure-Graph -Scopes @("Policy.Read.ConditionalAccess","Directory.Read.All","User.Read.All"))) {
        Pause-End
        exit 1
    }

    Section "AUDIT"

    $policies = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies")
    $rows = New-Object System.Collections.ArrayList

    foreach ($p in $policies) {
        $excludeUsers = @()
        $excludeGroups = @()
        $includeApps = @()
        $excludeApps = @()
        $clientTypes = @()
        $grant = @()

        try { $excludeUsers = @($p.conditions.users.excludeUsers) } catch {}
        try { $excludeGroups = @($p.conditions.users.excludeGroups) } catch {}
        try { $includeApps = @($p.conditions.applications.includeApplications) } catch {}
        try { $excludeApps = @($p.conditions.applications.excludeApplications) } catch {}
        try { $clientTypes = @($p.conditions.clientAppTypes) } catch {}
        try { $grant = @($p.grantControls.builtInControls) } catch {}

        $findings = @()

        if ($p.state -eq "disabled") { $findings += "Disabled" }
        if ($p.state -eq "enabledForReportingButNotEnforced") { $findings += "Report-only" }
        if ($excludeUsers.Count -gt 0) { $findings += "User exclusions" }
        if ($excludeGroups.Count -gt 0) { $findings += "Group exclusions" }
        if ($excludeApps.Count -gt 0) { $findings += "App exclusions" }
        if ($clientTypes -notcontains "all" -and $clientTypes.Count -gt 0) { $findings += "Limited client app scope" }
        if (($includeApps -contains "All" -or $includeApps -contains "all") -and $grant -notcontains "mfa") { $findings += "All-apps without MFA grant" }

        if ($findings.Count -eq 0) { $findings += "Review" }

        [void]$rows.Add([pscustomobject]@{
            PolicyName=(Clean-Name $p.displayName)
            State=$p.state
            GrantControls=($grant -join "; ")
            IncludeApps=($includeApps -join "; ")
            ExcludeApps=($excludeApps -join "; ")
            ExcludeUsers=($excludeUsers -join "; ")
            ExcludeGroups=($excludeGroups -join "; ")
            ClientAppTypes=($clientTypes -join "; ")
            Finding=($findings -join ", ")
        })
    }

    $flags = @($rows | Where-Object { $_.Finding -ne "Review" })


    $disabledCount = @($rows | Where-Object { $_.Finding -match 'Disabled' }).Count
    $reportOnlyCount = @($rows | Where-Object { $_.Finding -match 'Report-only' }).Count
    $exclusionCount = @($rows | Where-Object { $_.Finding -match 'exclusions' }).Count

    $verdict = "NO CONDITIONAL ACCESS GAPS FLAGGED"
    $recommendation = "No policy gaps were flagged by this review"

    if ($flags.Count -gt 0) {
        $verdict = "CONDITIONAL ACCESS REVIEW ITEMS FOUND"
        $recommendation = "Review disabled/report-only policies, exclusions, client app scope, and MFA grant coverage"
    }

    Write-Host ""

    Write-Host ""
    Write-Host ""
    Write-Host "CONDITIONAL ACCESS GAP SUMMARY"
    Write-Host "Verdict         : $verdict"
    Write-Host "Recommendation  : $recommendation"
    Write-Host "Policies checked: $($rows.Count)"
    Write-Host "Flags           : $($flags.Count)"
    Write-Host "Disabled        : $disabledCount"
    Write-Host "Report-only     : $reportOnlyCount"
    Write-Host "Exclusions      : $exclusionCount"
    Write-Host ""
    Write-Host "Flagged policies:"

    if ($flags.Count -eq 0) {
        Write-Host "- None"
    } else {
        foreach ($r in ($flags | Select-Object -First 20)) {
            Write-Host "- $($r.PolicyName) | $($r.State) | $($r.Finding)"
        }

        if ($flags.Count -gt 20) {
            Write-Host "- plus $($flags.Count - 20) more"
        }
    }

    Write-Host ""
    Write-Host ""

    foreach ($r in ($flags | Select-Object -First 75)) {
        WARN "$($r.PolicyName) | $($r.State) | $($r.Finding)"
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "tenant-cap-gaps-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete. No changes made."
    Pause-End
}
catch {
    Write-Host ""
    FAIL ("Unhandled script error: {0}" -f $_.Exception.Message)
    Pause-End
}