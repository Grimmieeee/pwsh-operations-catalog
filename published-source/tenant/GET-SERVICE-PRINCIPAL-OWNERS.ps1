<#
tenant-service-principal-owners-audit-clean.ps1

Read-only service principal owner audit.

Purpose:
- Reviews service principals and their owners
- Flags service principals owned by normal user accounts
- Flags service principals with no owners
- Helps find persistence/ownership risk
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
    try { $host.UI.RawUI.WindowTitle = "Tenant Service Principal Owners Audit" } catch {}
Write-Host "TENANT SERVICE PRINCIPAL OWNERS AUDIT"
    Write-Host "Read-only"
    Write-Host ""

    if (-not (Ensure-Graph -Scopes @("Application.Read.All","Directory.Read.All","User.Read.All"))) {
        Pause-End
        exit 1
    }

    Section "AUDIT"

    $sps = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/servicePrincipals?`$select=id,displayName,appId,servicePrincipalType,accountEnabled,appOwnerOrganizationId&`$top=999")
    $rows = New-Object System.Collections.ArrayList

    foreach ($sp in $sps) {
        INFO "Checking: $($sp.displayName)"
        $owners = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/servicePrincipals/$($sp.id)/owners?`$select=id,displayName,userPrincipalName,mail,userType,accountEnabled")

        if ($owners.Count -eq 0) {
            [void]$rows.Add([pscustomobject]@{
                ServicePrincipal=(Clean-Name $sp.displayName)
                AppId=$sp.appId
                Owner="None"
                OwnerUPN=""
                OwnerType=""
                AccountEnabled=""
                Finding="No owner"
            })
            continue
        }

        foreach ($o in $owners) {
            $finding = "Review"
            if ($o.userPrincipalName -and $o.userType -ne "Guest") {
                $finding = "User-owned service principal"
            }
            elseif ($o.userType -eq "Guest") {
                $finding = "Guest-owned service principal"
            }
            elseif ($o.accountEnabled -eq $false) {
                $finding = "Disabled owner"
            }

            [void]$rows.Add([pscustomobject]@{
                ServicePrincipal=(Clean-Name $sp.displayName)
                AppId=$sp.appId
                Owner=$o.displayName
                OwnerUPN=$o.userPrincipalName
                OwnerType=$o.userType
                AccountEnabled=$o.accountEnabled
                Finding=$finding
            })
        }
    }


    $noOwnerCount = @($rows | Where-Object { $_.Finding -eq 'No owner' }).Count
    $userOwnedCount = @($rows | Where-Object { $_.Finding -eq 'User-owned service principal' }).Count
    $guestOwnedCount = @($rows | Where-Object { $_.Finding -eq 'Guest-owned service principal' }).Count
    $reviewRows = @($rows | Where-Object { $_.Finding -ne "Review" })

    $verdict = "NO SERVICE PRINCIPAL OWNER GAPS FLAGGED"
    $recommendation = "No owner gaps were flagged by this review"

    if ($noOwnerCount -gt 0 -or $guestOwnedCount -gt 0) {
        $verdict = "SERVICE PRINCIPAL OWNER RISK FOUND"
        $recommendation = "Review no-owner and guest-owned service principals"
    }
    elseif ($userOwnedCount -gt 0) {
        $verdict = "USER-OWNED SERVICE PRINCIPALS FOUND"
        $recommendation = "Review whether user-owned service principals need app/team ownership"
    }

    Write-Host ""

    Write-Host ""
    Write-Host ""
    Write-Host "SERVICE PRINCIPAL OWNER SUMMARY"
    Write-Host "Verdict                    : $verdict"
    Write-Host "Recommendation             : $recommendation"
    Write-Host "Service principals checked : $($sps.Count)"
    Write-Host "Owner rows                 : $($rows.Count)"
    Write-Host "No owner                   : $noOwnerCount"
    Write-Host "User-owned                 : $userOwnedCount"
    Write-Host "Guest-owned                : $guestOwnedCount"
    Write-Host ""
    Write-Host "Review items:"

    if ($reviewRows.Count -eq 0) {
        Write-Host "- None"
    } else {
        foreach ($r in ($reviewRows | Select-Object -First 20)) {
            Write-Host "- $($r.ServicePrincipal) | $($r.OwnerUPN) | $($r.Finding)"
        }
        if ($reviewRows.Count -gt 20) {
            Write-Host "- plus $($reviewRows.Count - 20) more"
        }
    }

    Write-Host ""
    Write-Host ""

    foreach ($r in ($rows | Where-Object { $_.Finding -ne "Review" } | Select-Object -First 75)) {
        WARN "$($r.ServicePrincipal) | $($r.OwnerUPN) | $($r.Finding)"
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "tenant-service-principal-owners-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete. No changes made."
    Pause-End
}
catch {
    Write-Host ""
    FAIL ("Unhandled script error: {0}" -f $_.Exception.Message)
    Pause-End
}
