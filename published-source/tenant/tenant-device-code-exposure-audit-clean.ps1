<#
tenant-device-code-exposure-audit-clean.ps1

Read-only device code exposure audit.

Purpose:
- Checks Conditional Access policies for device code flow blocking indicators
- Reviews recent sign-ins for device code activity where available
- Helps assess exposure to device code phishing
#>

param(
    [int]$LookbackHours = 72
)

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
        $Rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        OK "Exported: $path"
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
    try { $host.UI.RawUI.WindowTitle = "Tenant Device Code Exposure Audit" } catch {}
Write-Host "TENANT DEVICE CODE EXPOSURE AUDIT"
    Write-Host "Read-only"
    Write-Host ""

    $inputHours = Read-Host "Lookback hours [default $LookbackHours]"
    if ($inputHours) { try { $LookbackHours = [int]$inputHours } catch {} }

    if (-not (Ensure-Graph -Scopes @("Policy.Read.ConditionalAccess","AuditLog.Read.All","Directory.Read.All"))) {
        Pause-End
        exit 1
    }

    Section "CONDITIONAL ACCESS"

    $policies = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies")
    $capRows = New-Object System.Collections.ArrayList

    foreach ($p in $policies) {
        $clientTypes = ""
        $conditionsText = ($p | ConvertTo-Json -Depth 20)

        try { $clientTypes = @($p.conditions.clientAppTypes) -join "; " } catch {}

        $finding = "Review"
        if ($conditionsText -match "deviceCode") { $finding = "Device code condition/reference present" }
        elseif ($p.state -eq "disabled") { $finding = "Disabled policy" }
        elseif ($p.state -eq "enabledForReportingButNotEnforced") { $finding = "Report-only policy" }

        [void]$capRows.Add([pscustomobject]@{
            PolicyName=(Clean-Name $p.displayName)
            State=$p.state
            ClientAppTypes=$clientTypes
            Finding=$finding
        })
    }

    $devicePolicies = @($capRows | Where-Object { $_.Finding -eq "Device code condition/reference present" })

    if ($devicePolicies.Count -gt 0) {
        OK "Device code policy reference found"
    } else {
        WARN "No obvious device code policy reference found"
    }

    Section "SIGN-IN REVIEW"

    $since = (Get-Date).AddHours(-1 * $LookbackHours).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $filter = Encode-Value "createdDateTime ge $since"
    $uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$top=100&`$filter=$filter"
    $logs = @(Get-GraphPages -Uri $uri)

    $deviceRows = New-Object System.Collections.ArrayList

    foreach ($log in $logs) {
        $text = ($log | ConvertTo-Json -Depth 10)

        if ($text -match "deviceCode|Device Code|device code") {
            [void]$deviceRows.Add([pscustomobject]@{
                Time=$log.createdDateTime
                UPN=$log.userPrincipalName
                App=$log.appDisplayName
                ClientApp=$log.clientAppUsed
                IP=$log.ipAddress
                Country=$log.location.countryOrRegion
                Result=$(if ($log.status.errorCode -eq 0) { "Success" } else { "Failed" })
            })
        }
    }

    Write-Host "Policies reviewed      : $($capRows.Count)"
    Write-Host "Device policy refs     : $($devicePolicies.Count)"
    Write-Host "Sign-ins reviewed      : $($logs.Count)"
    Write-Host "Device code sign-ins   : $($deviceRows.Count)"
    Write-Host ""

    foreach ($r in ($deviceRows | Select-Object -First 50)) {
        if ($r.Result -eq "Success") {
            RISK "$($r.Time) | $($r.UPN) | $($r.Result) | $($r.IP) | $($r.App)"
        } else {
            WARN "$($r.Time) | $($r.UPN) | $($r.Result) | $($r.IP) | $($r.App)"
        }
    }

    Offer-ExportCsv -Rows @($deviceRows) -DefaultName "tenant-device-code-exposure-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete. No changes made."
    Pause-End
}
catch {
    Write-Host ""
    FAIL ("Unhandled script error: {0}" -f $_.Exception.Message)
    Pause-End
}
