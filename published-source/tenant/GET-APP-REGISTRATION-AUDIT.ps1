<#
tenant-app-registrations-audit-clean.ps1

Read-only app registration security audit.

Purpose:
- Reviews app registrations
- Flags expired/expiring secrets and certificates
- Flags risky application permissions
- Reviews owners
#>

param(
    [int]$ExpiringDays = 30
)

$ErrorActionPreference = "SilentlyContinue"

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
    Read-Host "Press Enter to EXIT" | Out-Null
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host (" {0} " -f $Title) `
        -ForegroundColor White `
        -BackgroundColor DarkGray
    Write-Host "Timestamp: $(Now)" -ForegroundColor DarkGray
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
    try { $host.UI.RawUI.WindowTitle = "Tenant App Registrations Audit" } catch {}

    Clear-Host
    Write-Host "TENANT APP REGISTRATIONS AUDIT"
    Write-Host "Read-only"
    Write-Host ""

    if (-not (Ensure-Graph -Scopes @("Application.Read.All","Directory.Read.All"))) {
        Pause-End
        exit 1
    }

    Section "AUDIT"

    $apps = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/applications?`$select=id,appId,displayName,passwordCredentials,keyCredentials,requiredResourceAccess,createdDateTime&`$top=999")
    $rows = New-Object System.Collections.ArrayList
    $now = Get-Date
    $soon = $now.AddDays($ExpiringDays)

    foreach ($app in $apps) {
        INFO "Checking: $($app.displayName)"

        $owners = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/applications/$($app.id)/owners?`$select=id,displayName,userPrincipalName,userType,accountEnabled")
        $ownerText = if ($owners.Count -gt 0) { (@($owners | ForEach-Object { if ($_.userPrincipalName) { $_.userPrincipalName } else { $_.displayName } }) -join "; ") } else { "None" }

        foreach ($secret in @($app.passwordCredentials)) {
            $end = $null
            try { $end = [datetime]$secret.endDateTime } catch {}

            $finding = "Secret OK"
            if ($end -and $end -lt $now) { $finding = "Expired secret" }
            elseif ($end -and $end -lt $soon) { $finding = "Secret expiring soon" }

            [void]$rows.Add([pscustomobject]@{
                AppName=(Clean-Name $app.displayName)
                AppId=$app.appId
                ItemType="Secret"
                ItemName=$secret.displayName
                EndDate=$secret.endDateTime
                Finding=$finding
                Owners=$ownerText
            })
        }

        foreach ($cert in @($app.keyCredentials)) {
            $end = $null
            try { $end = [datetime]$cert.endDateTime } catch {}

            $finding = "Certificate OK"
            if ($end -and $end -lt $now) { $finding = "Expired certificate" }
            elseif ($end -and $end -lt $soon) { $finding = "Certificate expiring soon" }

            [void]$rows.Add([pscustomobject]@{
                AppName=(Clean-Name $app.displayName)
                AppId=$app.appId
                ItemType="Certificate"
                ItemName=$cert.displayName
                EndDate=$cert.endDateTime
                Finding=$finding
                Owners=$ownerText
            })
        }

        if ($owners.Count -eq 0) {
            [void]$rows.Add([pscustomobject]@{
                AppName=(Clean-Name $app.displayName)
                AppId=$app.appId
                ItemType="Owner"
                ItemName="None"
                EndDate=""
                Finding="No owner"
                Owners="None"
            })
        }

        foreach ($resource in @($app.requiredResourceAccess)) {
            foreach ($perm in @($resource.resourceAccess)) {
                $finding = "Permission review"

                if ($perm.type -eq "Role") {
                    $finding = "Application permission present"
                }

                [void]$rows.Add([pscustomobject]@{
                    AppName=(Clean-Name $app.displayName)
                    AppId=$app.appId
                    ItemType="Permission"
                    ItemName="$($perm.id)"
                    EndDate=""
                    Finding=$finding
                    Owners=$ownerText
                })
            }
        }
    }

    Section "SUMMARY"
    Write-Host "Applications checked : $($apps.Count)"
    Write-Host "Rows                 : $($rows.Count)"
    Write-Host "Expired secrets/certs: $(@($rows | Where-Object { $_.Finding -match '^Expired' }).Count)"
    Write-Host "Expiring soon        : $(@($rows | Where-Object { $_.Finding -match 'expiring soon' }).Count)"
    Write-Host "No owner             : $(@($rows | Where-Object { $_.Finding -eq 'No owner' }).Count)"
    Write-Host "App permissions      : $(@($rows | Where-Object { $_.Finding -eq 'Application permission present' }).Count)"
    Write-Host ""

    foreach ($r in ($rows | Where-Object { $_.Finding -ne "Secret OK" -and $_.Finding -ne "Certificate OK" -and $_.Finding -ne "Permission review" } | Select-Object -First 75)) {
        WARN "$($r.AppName) | $($r.ItemType) | $($r.Finding) | $($r.EndDate)"
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "tenant-app-registrations-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
