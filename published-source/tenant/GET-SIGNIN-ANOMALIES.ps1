<#
tenant-signin-anomalies-audit-clean.ps1

Read-only tenant sign-in anomaly audit.

Purpose:
- Reviews recent sign-ins for suspicious indicators
- Flags foreign success, impossible-travel-like country changes, device code activity, and non-interactive success from new IPs
- Optional UPN filter
- Optional CSV export only when approved

Notes:
- This is a broad audit and may take time on large tenants.
#>

param(
    [int]$LookbackHours = 24,
    [string]$FilterUPN,
    [ValidateRange(1,10000)][int]$MaxPages = 5,
    [string[]]$ExpectedCountry = @('US'),
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

function Get-ResultLabel {
    param($Log)

    if ($Log.status -and $Log.status.errorCode -eq 0) { return "Success" }
    return "Failed"
}

function Get-EventType {
    param($Log)

    $raw = ""
    try { $raw = "$($Log.signInEventTypes -join ',')" } catch {}

    if ($raw -match "nonInteractive") { return "Non-interactive" }
    if ($raw -match "interactive") { return "Interactive" }
    return "Unknown"
}

try {
    try { $host.UI.RawUI.WindowTitle = "Tenant Sign-in Anomalies Audit" } catch {}
Write-Host "TENANT SIGN-IN ANOMALIES AUDIT"
    Write-Host "Read-only"
    Write-Host ""

    $inputHours = Read-Host "Lookback hours [default $LookbackHours]"
    if ($inputHours) { try { $LookbackHours = [int]$inputHours } catch {} }

    if (-not $FilterUPN) {
        $FilterUPN = (Read-Host "Filter UPN [blank for tenant-wide]").Trim()
    }

    $countryInput=Read-Host "Expected country/region codes, comma-separated [default $($ExpectedCountry -join ',')]"
    if ($countryInput) { $ExpectedCountry=@($countryInput -split ',' | ForEach-Object { $_.Trim().ToUpperInvariant() } | Where-Object { $_ }) }
    if (-not $ExpectedCountry.Count -or @($ExpectedCountry | Where-Object { $_ -notmatch '^[A-Za-z]{2}$' }).Count) { throw 'Use two-letter country/region codes, e.g. US,CA. No audit was completed.' }

    Section "CONNECT"

    if (-not (Ensure-Graph -Scopes @("AuditLog.Read.All","User.Read.All","Directory.Read.All") -TenantId $ExpectedTenantId)) {
        Pause-End
        exit 1
    }

    Section "SEARCH"

    WARN "This may take a while on large tenants."

    $since = (Get-Date).AddHours(-1 * $LookbackHours).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $filter = "createdDateTime ge $since"

    if ($FilterUPN) {
        $escaped = Escape-OData $FilterUPN
        $filter = "$filter and userPrincipalName eq '$escaped'"
    }

    $encodedFilter = Encode-Value $filter
    $uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$top=100&`$filter=$encodedFilter"
    $page = 0
    $events = New-Object System.Collections.ArrayList

    while ($uri -and $page -lt $MaxPages) {
        $page++
        INFO "Reading sign-in page $page..."
        $data = Graph-Get $uri

        if (-not $data -or $null -eq $data.value) { throw 'Sign-in data is unavailable; review incomplete.' }

        foreach ($log in @($data.value)) {
            $time = $null
            try { $time = ([datetime]$log.createdDateTime).ToLocalTime() } catch {}

            [void]$events.Add([pscustomobject]@{
                Time=$time
                UPN=$log.userPrincipalName
                Result=(Get-ResultLabel $log)
                EventType=(Get-EventType $log)
                App=$log.appDisplayName
                ClientApp=$log.clientAppUsed
                IP=$log.ipAddress
                Country=$log.location.countryOrRegion
                City=$log.location.city
                AuthRequirement=$log.authenticationRequirement
                ErrorCode=$log.status.errorCode
                Failure=$log.status.failureReason
                CorrelationId=$log.correlationId
                Finding="Review"
            })
        }

        $uri = $data.'@odata.nextLink'
    }

    foreach ($e in $events) {
        if ($e.Result -eq "Success" -and $e.Country -and $ExpectedCountry -notcontains $e.Country) {
            $e.Finding = "Foreign successful sign-in"
        }
        elseif ($e.ClientApp -match "Device Code|deviceCode" -or $e.App -match "Device Code") {
            $e.Finding = "Device code activity"
        }
        elseif ($e.Result -eq "Failed" -and $e.Country -and $ExpectedCountry -notcontains $e.Country) {
            $e.Finding = "Foreign failed sign-in"
        }
    }

    $byUser = $events | Where-Object { $_.Result -eq "Success" -and $_.Country } | Group-Object UPN

    foreach ($group in $byUser) {
        $ordered = @($group.Group | Sort-Object Time)

        for ($i = 1; $i -lt $ordered.Count; $i++) {
            $prev = $ordered[$i - 1]
            $curr = $ordered[$i]

            if ($prev.Country -and $curr.Country -and $prev.Country -ne $curr.Country) {
                $minutes = [math]::Abs((New-TimeSpan -Start $prev.Time -End $curr.Time).TotalMinutes)

                if ($minutes -le 180) {
                    $curr.Finding = "Possible impossible travel"
                }
            }
        }
    }

    Section "FINDINGS"

    $findings = @($events | Where-Object { $_.Finding -ne "Review" })

    if ($findings.Count -eq 0) {
        if ($uri) { WARN "No direct anomaly findings in returned events; additional pages remain unread." }
        else { OK "No direct anomaly findings in returned events" }
    } else {
        foreach ($f in ($findings | Sort-Object Time -Descending | Select-Object -First 75)) {
            if ($f.Finding -match "Foreign successful|impossible|Device code") {
                RISK "$($f.Time) | $($f.UPN) | $($f.Finding) | $($f.Country) | $($f.IP) | $($f.App)"
            } else {
                WARN "$($f.Time) | $($f.UPN) | $($f.Finding) | $($f.Country) | $($f.IP) | $($f.App)"
            }
        }
    }


    $foreignSuccessCount = @($findings | Where-Object { $_.Finding -eq 'Foreign successful sign-in' }).Count
    $impossibleTravelCount = @($findings | Where-Object { $_.Finding -eq 'Possible impossible travel' }).Count
    $deviceCodeCount = @($findings | Where-Object { $_.Finding -eq 'Device code activity' }).Count

    $verdict = "NO DIRECT SIGN-IN ANOMALIES FOUND"
    $recommendation = "No direct anomaly findings in returned sign-in data"

    if ($foreignSuccessCount -gt 0 -or $impossibleTravelCount -gt 0 -or $deviceCodeCount -gt 0) {
        $verdict = "HIGH-RISK SIGN-IN ANOMALY FOUND"
        $recommendation = "Review affected users and consider IR discovery/containment based on context"
    }
    elseif ($findings.Count -gt 0) {
        $verdict = "SIGN-IN REVIEW ITEMS FOUND"
        $recommendation = "Review returned sign-in findings and validate expected activity"
    }

    Write-Host ""

    Write-Host ""
    Write-Host ""
    Write-Host "SIGN-IN ANOMALY SUMMARY"
    Write-Host "Verdict             : $verdict"
    Write-Host "Recommendation      : $recommendation"
    Write-Host "Events reviewed     : $($events.Count)"
    Write-Host "Expected regions    : $($ExpectedCountry -join ', ')"
    Write-Host "Coverage            : $(if ($uri) { 'Partial - page limit reached; more events remain' } else { 'Returned query pages complete' })"
    Write-Host "Findings            : $($findings.Count)"
    Write-Host "Foreign success     : $foreignSuccessCount"
    Write-Host "Possible impossible : $impossibleTravelCount"
    Write-Host "Device code activity: $deviceCodeCount"
    Write-Host ""
    Write-Host "Top findings:"
    if ($findings.Count -eq 0) {
        Write-Host "- None"
    } else {
        foreach ($f in ($findings | Sort-Object Time -Descending | Select-Object -First 20)) {
            Write-Host "- $($f.Time) | $($f.UPN) | $($f.Finding) | $($f.Country) | $($f.IP) | $($f.App)"
        }
        if ($findings.Count -gt 20) {
            Write-Host "- plus $($findings.Count - 20) more"
        }
    }
    Write-Host ""
    Write-Host ""

    Offer-ExportCsv -Rows @($events) -DefaultName "tenant-signin-anomalies-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    if ($uri) { WARN 'STATUS: Partial review - raise MaxPages or narrow the period and review remaining sign-ins. No changes made.' }
    else { OK 'Returned sign-in review complete. No changes made.' }
    Pause-End
}
catch {
    Write-Host ""
    FAIL ("Unhandled script error: {0}" -f $_.Exception.Message)
    Pause-End
}
