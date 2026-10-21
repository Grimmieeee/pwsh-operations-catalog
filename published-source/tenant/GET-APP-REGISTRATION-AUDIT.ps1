<#
.VERSION 1.0.1
#>
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
    [int]$ExpiringDays = 30,
    [string]$ExpectedTenantId
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
    Write-Host ''
    Write-Host 'SESSION COMPLETE'
    Write-Host ""
    Read-Host 'Press Enter to close session.' | Out-Null
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

function Get-CredentialExpiryFinding {
    param($EndDate, [datetime]$Now, [datetime]$Soon, [ValidateSet('Secret','Certificate')][string]$Kind)
    if (-not $EndDate) { return "$Kind expiry unavailable" }
    try { $end=[datetime]$EndDate } catch { return "$Kind expiry unavailable" }
    if ($end -lt $Now) { return "Expired $($Kind.ToLowerInvariant())" }
    if ($end -lt $Soon) { return "$Kind expiring soon" }
    return "$Kind OK"
}

function Graph-Get {
    param([string]$Uri)

    try { return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop }
    catch { throw "Graph read failed; review incomplete. $($_.Exception.Message)" }
}

function Ensure-Graph {
    param([string[]]$Scopes, [string]$TenantId)
    if (-not $TenantId) { $TenantId=(Read-Host "Expected tenant ID (GUID; blank cancels)").Trim() }
    $expectedGuid=[guid]::Empty
    if (-not [guid]::TryParse($TenantId,[ref]$expectedGuid) -or $expectedGuid -eq [guid]::Empty) { throw "A valid expected tenant ID is required. No audit was completed." }
    $TenantId=$expectedGuid.ToString()

    $module=Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        FAIL "Microsoft.Graph.Authentication module not available"
        Write-Host "Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
        return $false
    }

    Import-Module $module.Path -Force -ErrorAction Stop | Out-Null

    $ctx=Get-MgContext -ErrorAction SilentlyContinue
    if ($ctx -and $ctx.TenantId -ne $TenantId) {
        throw 'Existing Graph session is for another tenant. No changes made. Open a new PowerShell window and sign in to the expected tenant.'
    }
    if ($ctx -and ($ctx.AuthType -ne 'Delegated' -or -not $ctx.Account)) {
        throw 'An interactive delegated Graph session is required. Open a new PowerShell window and sign in.'
    }
    $hasScopes=$true
    if (-not $ctx) { $hasScopes=$false }
    else {
        foreach ($scope in $Scopes) {
            if (@($ctx.Scopes) -notcontains $scope) { $hasScopes=$false; break }
        }
    }

    if ($ctx -and (-not $hasScopes -or $ctx.ContextScope -ne 'Process')) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        $ctx=$null
    }

    if (-not $ctx) {
        $command=Get-Command Connect-MgGraph -ErrorAction Stop
        if (-not $command.Parameters.ContainsKey('ContextScope')) { throw 'Update Microsoft.Graph.Authentication to a version supporting process-scoped sign-in.' }
        $parameters=@{ Scopes=$Scopes; TenantId=$TenantId; ContextScope='Process'; ErrorAction='Stop' }
        if ($command.Parameters.ContainsKey('NoWelcome')) { $parameters['NoWelcome']=$true }
        Connect-MgGraph @parameters | Out-Null
    }

    $ctx=Get-MgContext -ErrorAction Stop
    Assert-GraphContext -TenantId $TenantId
    foreach ($scope in $Scopes) {
        if (@($ctx.Scopes) -notcontains $scope) {
            FAIL "Graph token is missing required scope: $scope"
            return $false
        }
    }

    OK "Graph connected"
    INFO "Tenant ID: $TenantId | Account: $($ctx.Account)"
    return $true
}

function Assert-GraphContext {
    param([string]$TenantId, [string]$Account)
    $ctx=Get-MgContext -ErrorAction Stop
    if (-not $ctx -or $ctx.TenantId -ne $TenantId -or $ctx.AuthType -ne 'Delegated' -or
        -not $ctx.Account -or $ctx.ContextScope -ne 'Process' -or ($Account -and $ctx.Account -ne $Account)) {
        throw 'Graph tenant/account context changed or could not be validated. Stop and review the results; do not retry changes blindly.'
    }
}

function Get-GraphPages {
    param([string]$Uri)

    $items = New-Object System.Collections.ArrayList

    while ($Uri) {
        $page = Graph-Get $Uri

        if (-not $page -or $null -eq $page.value) { throw "Graph collection data is unavailable; review incomplete." }

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
    $uri = "https://graph.microsoft.com/v1.0/users/${encoded}?`$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,signInActivity,lastPasswordChangeDateTime"
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
    Write-Host 'Audit App Registrations'
    Write-Host 'Finds app registrations with risky permissions, expiring credentials, or missing owners.'
    Write-Host "Read-only"
    Write-Host ""

    if (-not (Ensure-Graph -Scopes @("Application.Read.All","Directory.Read.All") -TenantId $ExpectedTenantId)) {
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

        foreach ($secret in @($app.passwordCredentials | Where-Object { $_ })) {
            $finding=Get-CredentialExpiryFinding -EndDate $secret.endDateTime -Now $now -Soon $soon -Kind Secret

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

        foreach ($cert in @($app.keyCredentials | Where-Object { $_ })) {
            $finding=Get-CredentialExpiryFinding -EndDate $cert.endDateTime -Now $now -Soon $soon -Kind Certificate

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
    Write-Host "Expiry unavailable   : $(@($rows | Where-Object { $_.Finding -match 'expiry unavailable' }).Count)"
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
