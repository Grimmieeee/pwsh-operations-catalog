#Requires -Version 5.1

<#
IR AUDIT - TOKEN REPLAY CHECK

OBJECTIVE
Review Entra sign-ins and Identity Protection risk detections for evidence that
supports a token-theft / token-replay concern.

READ-ONLY
No containment actions.
No tenant changes.
No export.

INTERPRETATION
Unexpected geography alone is not called token replay.
Direct token-specific risk detections such as anomalousToken or
tokenIssuerAnomaly are treated as stronger evidence.
Unavailable risk/sign-in data is reported as a limitation, never as clean.
#>

param(
    [string]$UPN,
    [ValidateRange(1,720)]
    [int]$LookbackHours = 48,
    [string]$ExpectedCountry = "US"
)

$ErrorActionPreference = "Stop"

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function RISK($m) { Write-Host "[RISK] $m" -ForegroundColor Red }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host (" {0} " -f $Title) `
        -ForegroundColor White `
        -BackgroundColor DarkGray
}

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to EXIT" | Out-Null
}

function Confirm-Yes {
    param([string]$Prompt)

    $answer = Read-Host "$Prompt [Y/N]"

    return (
        -not [string]::IsNullOrWhiteSpace($answer) -and
        $answer.Trim().ToUpperInvariant() -eq "Y"
    )
}

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    WARN $Prompt
    $answer = Read-Host "Type $Required to continue"

    return (
        -not [string]::IsNullOrWhiteSpace($answer) -and
        $answer.Trim().ToUpperInvariant() -eq $Required.ToUpperInvariant()
    )
}

function Get-ShortError {
    param($ErrorRecord)

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Get-DesktopPath {
    $desktop = [Environment]::GetFolderPath("Desktop")

    if ([string]::IsNullOrWhiteSpace($desktop)) {
        $desktop = Join-Path $env:USERPROFILE "Desktop"
    }

    return $desktop
}

function Get-ExportPath {
    param([string]$DefaultName)

    $folder = Read-Host "Output folder [Enter for Desktop]"

    if ([string]::IsNullOrWhiteSpace($folder)) {
        $folder = Get-DesktopPath
    }
    else {
        $folder = $folder.Trim().Trim('"').Trim("'")
    }

    if (-not (Test-Path -LiteralPath $folder -PathType Container)) {
        throw "Output folder not found: $folder"
    }

    return (Join-Path $folder $DefaultName)
}

function Ensure-GraphModule {
    $module = Get-Module -ListAvailable -Name "Microsoft.Graph.Authentication" |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "Microsoft.Graph.Authentication is required but is not installed. Install it first with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop
}

function Test-GraphScopes {
    param(
        $Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) {
        return $false
    }

    foreach ($scope in $RequiredScopes) {
        if (@($Context.Scopes) -notcontains $scope) {
            return $false
        }
    }

    return $true
}

function Connect-GraphAuto {
    param([string[]]$Scopes)

    Ensure-GraphModule

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-GraphScopes -Context $context -RequiredScopes $Scopes)
    ) {
        OK "Graph session reused"
        return
    }

    if ($context) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
        }
    }

    Write-Host "Graph: Connecting..."

    $command = Get-Command Connect-MgGraph -ErrorAction Stop
    $parameters = @{
        Scopes      = $Scopes
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ContextScope")) {
        $parameters["ContextScope"] = "Process"
    }

    if ($command.Parameters.ContainsKey("NoWelcome")) {
        $parameters["NoWelcome"] = $true
    }

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop

    if (
        -not (Test-GraphScopes -Context $context -RequiredScopes $Scopes)
    ) {
        throw "Graph connected without all required delegated scopes."
    }

    OK "Graph connected"
}

function Invoke-GraphGet {
    param([string]$Uri)

    return Invoke-MgGraphRequest `
        -Method GET `
        -Uri $Uri `
        -ErrorAction Stop
}

function Invoke-GraphPost {
    param(
        [string]$Uri,
        [hashtable]$Body
    )

    return Invoke-MgGraphRequest `
        -Method POST `
        -Uri $Uri `
        -Body ($Body | ConvertTo-Json -Depth 10) `
        -ContentType "application/json" `
        -ErrorAction Stop
}

function Get-GraphPaged {
    param([string]$Uri)

    $items = New-Object System.Collections.Generic.List[object]
    $next = $Uri

    while ($next) {
        $page = Invoke-GraphGet -Uri $next

        if ($null -eq $page -or $null -eq $page.value) {
            throw "Graph returned an incomplete paged response."
        }

        foreach ($item in @($page.value)) {
            $items.Add($item) | Out-Null
        }

        $next = [string]$page.'@odata.nextLink'
    }

    return @($items)
}

function Encode-UrlValue {
    param([string]$Value)

    return [System.Uri]::EscapeDataString($Value)
}

function Escape-OData {
    param([string]$Value)

    return ($Value -replace "'", "''")
}

function Test-SuccessSignIn {
    param($Event)

    try {
        return ([int]$Event.status.errorCode -eq 0)
    }
    catch {
        return $false
    }
}

function Get-Country {
    param($Event)

    try {
        if ($Event.location.countryOrRegion) {
            return [string]$Event.location.countryOrRegion
        }
    }
    catch {
    }

    return "Unknown"
}

function Get-LocationText {
    param($Event)

    $parts = New-Object System.Collections.Generic.List[string]

    foreach ($part in @(
        $Event.location.city,
        $Event.location.state,
        $Event.location.countryOrRegion
    )) {
        if ($part) {
            $parts.Add([string]$part)
        }
    }

    if ($parts.Count -eq 0) {
        return "Unknown"
    }

    return ($parts -join ", ")
}

function Get-DeviceText {
    param($Event)

    $parts = New-Object System.Collections.Generic.List[string]

    try {
        foreach ($part in @(
            $Event.deviceDetail.displayName,
            $Event.deviceDetail.operatingSystem,
            $Event.deviceDetail.browser
        )) {
            if ($part) {
                $parts.Add([string]$part)
            }
        }
    }
    catch {
    }

    if ($parts.Count -eq 0) {
        return "Unknown"
    }

    return ($parts -join " / ")
}

try {
    Write-Host "IR AUDIT - TOKEN REPLAY CHECK"
    Write-Host "READ-ONLY INDICATOR REVIEW"
    Write-Host ""

    if (-not $UPN) {
        $UPN = (Read-Host "UPN").Trim()
    }

    if (-not $UPN) {
        throw "UPN is required."
    }

    $hoursInput = Read-Host "Lookback hours [default $LookbackHours]"

    if ($hoursInput) {
        $parsedHours = 0

        if ([int]::TryParse($hoursInput, [ref]$parsedHours)) {
            if ($parsedHours -lt 1) { $parsedHours = 1 }
            if ($parsedHours -gt 720) { $parsedHours = 720 }
            $LookbackHours = $parsedHours
        }
    }

    $countryInput = Read-Host "Expected country/region [default $ExpectedCountry]"

    if ($countryInput) {
        $ExpectedCountry = $countryInput.Trim()
    }

    $expectedCountries = @(
        $ExpectedCountry -split ',' |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }
    )

    Section "CONNECT"

    Connect-GraphAuto -Scopes @(
        "User.Read.All",
        "AuditLog.Read.All",
        "IdentityRiskEvent.Read.All"
    )

    Section "TARGET"

    $encodedUPN = Encode-UrlValue $UPN
    $user = Invoke-GraphGet `
        -Uri "https://graph.microsoft.com/v1.0/users/$encodedUPN?`$select=displayName,userPrincipalName,lastPasswordChangeDateTime"

    if (-not $user -or -not $user.userPrincipalName) {
        throw "User lookup did not return the target account."
    }

    $passwordChange = $null
    $passwordChangeText = "Unknown"

    if ($user.lastPasswordChangeDateTime) {
        try {
            $passwordChange = [datetime]$user.lastPasswordChangeDateTime
            $passwordChangeText = $passwordChange.ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
        }
        catch {
        }
    }

    Write-Host "Target          : $($user.userPrincipalName)"
    Write-Host "Display Name    : $($user.displayName)"
    Write-Host "Lookback        : $LookbackHours hours"
    Write-Host "Expected country: $($expectedCountries -join ', ')"
    Write-Host "Password change : $passwordChangeText"

    $startUtc = (Get-Date).ToUniversalTime().AddHours(-1 * $LookbackHours)
    $startText = $startUtc.ToString("yyyy-MM-ddTHH:mm:ssZ")
    $escapedUPN = Escape-OData $UPN

    Section "SIGN-INS"

    $signIns = @()
    $signInGap = ""

    try {
        $filter = "userPrincipalName eq '$escapedUPN' and createdDateTime ge $startText"
        $uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$filter=$(Encode-UrlValue $filter)&`$top=100"
        $signIns = @(Get-GraphPaged -Uri $uri)

        if ($signIns.Count -eq 0) {
            WARN "No sign-in events returned."
        }
        else {
            OK "Sign-in events returned: $($signIns.Count)"
        }
    }
    catch {
        $signInGap = Get-ShortError $_
        WARN "Sign-in data unavailable: $signInGap"
    }

    Section "IDENTITY PROTECTION RISK DETECTIONS"

    $riskDetections = @()
    $riskGap = ""

    try {
        $riskFilter = "userPrincipalName eq '$escapedUPN'"
        $riskUri = "https://graph.microsoft.com/v1.0/identityProtection/riskDetections?`$filter=$(Encode-UrlValue $riskFilter)&`$top=500"
        $allRisk = @(Get-GraphPaged -Uri $riskUri)

        $riskDetections = @(
            $allRisk |
            Where-Object {
                try {
                    ([datetime]$_.activityDateTime).ToUniversalTime() -ge $startUtc
                }
                catch {
                    $false
                }
            }
        )

        if ($riskDetections.Count -eq 0) {
            INFO "No Identity Protection risk detections returned in the lookback window."
        }
        else {
            WARN "Identity Protection risk detections returned: $($riskDetections.Count)"
        }
    }
    catch {
        $riskGap = Get-ShortError $_
        WARN "Risk-detection data unavailable: $riskGap"
    }

    $directTokenTypes = @(
        "anomalousToken",
        "tokenIssuerAnomaly"
    )

    $directTokenDetections = @(
        $riskDetections |
        Where-Object { $_.riskEventType -in $directTokenTypes }
    )

    $supportingDetections = @(
        $riskDetections |
        Where-Object {
            $_.riskEventType -in @(
                "impossibleTravel",
                "unlikelyTravel",
                "unfamiliarFeatures",
                "suspiciousBrowser",
                "maliciousIPAddress",
                "suspiciousIPAddress",
                "investigationsThreatIntelligence"
            )
        }
    )

    $unexpectedSuccesses = @()
    $postPasswordChangeUnexpected = @()
    $riskySignIns = @()

    foreach ($event in $signIns) {
        $success = Test-SuccessSignIn $event
        $country = Get-Country $event
        $unexpected = $false

        if ($country -ne "Unknown" -and $expectedCountries.Count -gt 0) {
            $unexpected = $country -notin $expectedCountries
        }

        if ($success -and $unexpected) {
            $unexpectedSuccesses += $event
        }

        if (
            $success -and
            $unexpected -and
            $passwordChange
        ) {
            try {
                if (
                    ([datetime]$event.createdDateTime).ToUniversalTime() -gt
                    $passwordChange.ToUniversalTime()
                ) {
                    $postPasswordChangeUnexpected += $event
                }
            }
            catch {
            }
        }

        $riskLevel = [string]$event.riskLevelDuringSignIn
        $riskEvents = @($event.riskEventTypes_v2)

        if (
            $riskLevel -in @("medium","high") -or
            $riskEvents.Count -gt 0
        ) {
            $riskySignIns += $event
        }
    }

    Section "EVENT SAMPLE"

    if ($signIns.Count -gt 0) {
        foreach ($event in ($signIns | Sort-Object createdDateTime -Descending | Select-Object -First 10)) {
            $time = "Unknown"

            try {
                $time = ([datetime]$event.createdDateTime).ToLocalTime().ToString("yyyy-MM-dd HH:mm:ss")
            }
            catch {
            }

            $result = if (Test-SuccessSignIn $event) { "Success" } else { "Failure" }
            $location = Get-LocationText $event
            $device = Get-DeviceText $event
            $ip = if ($event.ipAddress) { [string]$event.ipAddress } else { "Unknown" }
            $app = if ($event.appDisplayName) { [string]$event.appDisplayName } else { "Unknown" }
            $risk = if ($event.riskLevelDuringSignIn) { [string]$event.riskLevelDuringSignIn } else { "unknown" }

            Write-Host "$time | $result | $location | $ip | $app | $device | Risk=$risk"
        }
    }
    else {
        INFO "No sign-in sample available."
    }

    Section "SUMMARY"

    $limitations = New-Object System.Collections.Generic.List[string]

    if ($signInGap) {
        $limitations.Add("Sign-in query unavailable: $signInGap")
    }

    if ($riskGap) {
        $limitations.Add("Identity Protection risk detections unavailable: $riskGap")
    }

    if ($directTokenDetections.Count -gt 0) {
        $verdict = "TOKEN-RELATED RISK DETECTION FOUND"
        $recommendation = "Treat as strong supporting evidence and correlate the detection with session, IP, device, and workload activity"
    }
    elseif (
        $postPasswordChangeUnexpected.Count -gt 0 -or
        $riskySignIns.Count -gt 0 -or
        $supportingDetections.Count -gt 0
    ) {
        $verdict = "SUSPICIOUS SESSION ACTIVITY FOUND - NO DIRECT TOKEN DETECTION"
        $recommendation = "Correlate sign-ins and risk detections with UAL/workload activity before attributing activity to token replay"
    }
    elseif ($signInGap -and $riskGap) {
        $verdict = "INCONCLUSIVE - REQUIRED DATA UNAVAILABLE"
        $recommendation = "Restore Graph sign-in / Identity Protection visibility and rerun"
    }
    elseif ($signIns.Count -eq 0 -and $riskDetections.Count -eq 0) {
        $verdict = "INCONCLUSIVE - NO EVENTS RETURNED"
        $recommendation = "Confirm log retention, licensing, permissions, and the selected lookback window"
    }
    elseif ($riskGap) {
        $verdict = "LIMITED - NO OBVIOUS SESSION ANOMALY IN RETURNED SIGN-INS"
        $recommendation = "Do not call the account clean until token-specific risk detections or equivalent telemetry are reviewed"
    }
    else {
        $verdict = "NO TOKEN-RELATED RISK DETECTION FOUND IN REVIEWED DATA"
        $recommendation = "No direct token-specific detection was returned; continue incident review using the broader evidence set"
    }

    Write-Host "TOKEN REPLAY CHECK SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host "Target                    : $UPN"
    Write-Host "Timestamp                 : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Lookback                  : $LookbackHours hours"
    Write-Host "Expected country          : $($expectedCountries -join ', ')"
    Write-Host "Password change           : $passwordChangeText"
    Write-Host "Sign-ins reviewed         : $($signIns.Count)"
    Write-Host "Risk detections reviewed  : $($riskDetections.Count)"
    Write-Host "Direct token detections   : $($directTokenDetections.Count)"
    Write-Host "Supporting detections     : $($supportingDetections.Count)"
    Write-Host "Unexpected successes      : $($unexpectedSuccesses.Count)"
    Write-Host "Post-change unexpected    : $($postPasswordChangeUnexpected.Count)"
    Write-Host "Risky sign-ins            : $($riskySignIns.Count)"
    Write-Host "Limitations               : $($limitations.Count)"
    Write-Host "Verdict                   : $verdict"
    Write-Host "Recommendation            : $recommendation"

    if ($directTokenDetections.Count -gt 0) {
        Write-Host ""
        Write-Host "Direct token detections:"

        foreach ($detection in $directTokenDetections) {
            Write-Host (
                "- {0} | {1} | {2} | {3}" -f
                $detection.activityDateTime,
                $detection.riskEventType,
                $detection.riskLevel,
                $detection.ipAddress
            )
        }
    }

    if ($limitations.Count -gt 0) {
        Write-Host ""
        Write-Host "Limitations:"

        foreach ($limitation in $limitations) {
            Write-Host "- $limitation"
        }
    }
}
catch {
    Write-Host ""
    FAIL (Get-ShortError $_)
}
finally {
    Pause-End
}
