<#
.VERSION 1.0.0
#>
<#
tenant-secure-score-snapshot-clean.ps1

Read-only Microsoft Secure Score snapshot.

Purpose:
- Pulls Microsoft Secure Score
- Shows current score, max score, and enabled control scores
- Optionally compares against a previous JSON snapshot
- Optionally saves a new JSON snapshot when approved

No automatic history writes.
#>

param(
    [string]$PreviousSnapshotPath,
    [string]$ExpectedTenantId
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

    try { return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop }
    catch { throw "Graph read failed; review incomplete. $($_.Exception.Message)" }
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
    try { $host.UI.RawUI.WindowTitle = "Tenant Secure Score Snapshot" } catch {}
Write-Host "TENANT SECURE SCORE SNAPSHOT"
    Write-Host "Read-only"
    Write-Host ""

    if (-not $PreviousSnapshotPath) {
        $PreviousSnapshotPath = (Read-Host "Previous JSON snapshot [blank to skip comparison]").Trim().Trim('"')
    }

    Section "CONNECT"

    if (-not (Ensure-Graph -Scopes @("SecurityEvents.Read.All","SecurityActions.Read.All","Directory.Read.All") -TenantId $ExpectedTenantId)) {
        Pause-End
        exit 1
    }

    Section "SECURE SCORE"

    $scores = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/security/secureScores?`$top=1")
    $latest = $scores | Sort-Object createdDateTime -Descending | Select-Object -First 1

    if (-not $latest) {
        FAIL "No Secure Score data returned"
        Pause-End
        exit 1
    }

    $current = [double]$latest.currentScore
    $max = [double]$latest.maxScore
    $percent = if ($max -gt 0) { [math]::Round(($current / $max) * 100, 2) } else { 0 }

    Write-Host "Created     : $($latest.createdDateTime)"
    Write-Host "Current     : $current"
    Write-Host "Maximum     : $max"
    Write-Host "Percentage  : $percent%"
    Write-Host ""

    $controlRows = New-Object System.Collections.ArrayList

    foreach ($c in @($latest.controlScores)) {
        [void]$controlRows.Add([pscustomobject]@{
            Control=$c.controlName
            Score=$c.score
            MaxScore=$c.maxScore
            Category=$c.controlCategory
        })
    }

    Section "LOW / ZERO CONTROLS"

    foreach ($c in ($controlRows | Sort-Object Score | Select-Object -First 20)) {
        WARN "$($c.Control) | $($c.Score) / $($c.MaxScore) | $($c.Category)"
    }

    if ($PreviousSnapshotPath -and (Test-Path $PreviousSnapshotPath)) {
        Section "COMPARISON"

        try {
            $previous = Get-Content $PreviousSnapshotPath -Raw | ConvertFrom-Json
            $prevScore = [double]$previous.currentScore
            $delta = [math]::Round(($current - $prevScore), 2)

            Write-Host "Previous score : $prevScore"
            Write-Host "Current score  : $current"
            Write-Host "Delta          : $delta"

            if ($delta -lt 0) {
                RISK "Secure Score decreased"
            }
            elseif ($delta -gt 0) {
                OK "Secure Score increased"
            }
            else {
                OK "Secure Score unchanged"
            }
        }
        catch {
            WARN "Could not compare previous snapshot"
        }
    }

    Write-Host ""
    Write-Host "SECURE SCORE SNAPSHOT"
    Write-Host "Timestamp  : $(Now)"
    Write-Host "Created    : $($latest.createdDateTime)"
    Write-Host "Score      : $current / $max"
    Write-Host "Percentage : $percent%"
    Write-Host "Controls   : $($controlRows.Count)"
    Write-Host ""

    $snapshot = [pscustomobject]@{
        capturedAt = Now
        createdDateTime = $latest.createdDateTime
        currentScore = $current
        maxScore = $max
        percentage = $percent
        controls = $controlRows
    }

    Offer-ExportJson -Object $snapshot -DefaultName "secure-score-snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    Offer-ExportCsv -Rows @($controlRows) -DefaultName "secure-score-controls-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete. No changes made."
    Pause-End
}
catch {
    Write-Host ""
    FAIL ("Unhandled script error: {0}" -f $_.Exception.Message)
    Pause-End
}
