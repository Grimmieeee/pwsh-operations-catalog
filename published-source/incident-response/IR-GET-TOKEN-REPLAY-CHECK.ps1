# .VERSION 1.0.2
#Requires -Version 5.1

<#
IR AUDIT - TOKEN REPLAY CHECK

OBJECTIVE
Review sign-ins for indicators of token replay or session theft.

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

# Embedded into standalone report scripts by tools/reporting/build.ps1.
$script:FKReportLines = New-Object 'Collections.Generic.List[string]'
$script:FKReportWarnings = @()
$script:FKReportStartedUtc = [DateTime]::UtcNow.ToString('o')

function Write-FKReportLine {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Object,
        [object]$Separator=' ',[switch]$NoNewline,
        [ConsoleColor]$ForegroundColor,[ConsoleColor]$BackgroundColor
    )
    $line=($Object | ForEach-Object {[string]$_}) -join [string]$Separator
    $script:FKReportLines.Add($line)
    Write-Host @PSBoundParameters
}

function ConvertTo-FKDesktopReport {
    param([string]$Title,[string[]]$Lines,[string]$StartedUtc,[string]$ScopeNote)
    $encode={param($Text) [Net.WebUtility]::HtmlEncode([string]$Text)}
    $blocks=New-Object 'Collections.Generic.List[string]'
    $section=New-Object 'Collections.Generic.List[string]'
    foreach($line in @($Lines)) {
        if($line -match '^\s*[A-Z][A-Z /+&:()-]{2,}\s*$' -and $line.Trim().Length -lt 90) {
            if($section.Count) {$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>');$section.Clear()}
            $blocks.Add('<h2>'+(& $encode $line.Trim())+'</h2>')
        } else {$section.Add([string]$line)}
    }
    if($section.Count){$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>')}
    $safeTitle=& $encode $Title
    return @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"><title>$safeTitle</title>
<style>body{font:16px/1.55 system-ui,sans-serif;background:#f5f7f7;color:#172524;margin:0}main{max-width:1000px;margin:32px auto;padding:32px;background:white;border-top:4px solid #168779}header{border-bottom:1px solid #d1ddda;padding-bottom:20px}small{letter-spacing:.12em;color:#52716b}h1{font-size:28px;margin:12px 0}h2{font-size:15px;letter-spacing:.1em;color:#166b60;margin:28px 0 10px;border-bottom:1px solid #d1ddda;padding-bottom:8px}pre{font:14px/1.6 ui-monospace,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;margin:0}aside{background:#eef5f2;padding:12px 16px;margin:20px 0}footer{font-size:12px;color:#52716b;margin-top:32px}@media print{body{background:white}main{margin:0;padding:0;max-width:none}h2{break-after:avoid}pre{font-size:11px}}</style></head>
<body><main><header><small>F I E L D // K I T</small><h1>$safeTitle</h1><p>Collection started (UTC): $(& $encode $StartedUtc)</p></header><aside>$(& $encode $ScopeNote) Findings, unavailable checks, and displayed limits below are preserved from this run. Absence of a finding does not establish complete coverage.</aside>$($blocks.ToArray() -join "`n")<footer>Read-only report. No remote content or executable scripts. Review findings in context before taking action.</footer></main></body></html>
"@
}

function Save-FKDesktopReport {
    param([string]$Folder,[string]$Title,[string]$Content)
    if([string]::IsNullOrWhiteSpace($Folder) -or -not [IO.Directory]::Exists($Folder)){throw 'Report folder does not exist.'}
    $stem=($Title -replace '[^a-zA-Z0-9._-]','-').Trim('-')
    if(-not $stem){$stem='field-kit-report'}
    $stem=$stem.Substring(0,[Math]::Min(80,$stem.Length))
    $name=$stem+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.html'
    $path=Join-Path $Folder $name
    $bytes=(New-Object Text.UTF8Encoding($false)).GetBytes($Content)
    $stream=New-Object IO.FileStream($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
    $actual=[IO.File]::ReadAllBytes($path)
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        if([Convert]::ToBase64String($sha.ComputeHash($bytes)) -cne [Convert]::ToBase64String($sha.ComputeHash($actual))){throw 'Report readback did not match the collected content.'}
    }finally{$sha.Dispose()}
    return $path
}

function Offer-FKDesktopReport {
    param([string]$Title,[string]$ScopeNote='Scope matches the console output; only displayed rows are included.',[string]$DesktopFolder=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory))
    if(-not $script:FKReportLines.Count){return}
    try {
        if((Read-Host 'Save report to Desktop? [Y/N]').Trim() -notmatch '^(?i)y$'){return}
        $folder=$DesktopFolder
        $reportLines=@($script:FKReportLines.ToArray())
        if(@($script:FKReportWarnings).Count){$reportLines+=@('','SERVICE WARNINGS');$reportLines+=@($script:FKReportWarnings|ForEach-Object {[string]$_})}
        $content=ConvertTo-FKDesktopReport -Title $Title -Lines $reportLines -StartedUtc $script:FKReportStartedUtc -ScopeNote $ScopeNote
        try {$saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content}
        catch {
            Write-Host '[WARN] Desktop report could not be saved. Choose another existing folder or cancel.' -ForegroundColor Yellow
            $folder=(Read-Host 'Report folder (ENTER cancels)').Trim().Trim('"')
            if(-not $folder){return}
            $saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content
        }
        Write-Host ('[OK] Report saved and readback checked: '+$saved)
    }catch{Write-Host ('[WARN] Report export failed: '+$_.Exception.Message) -ForegroundColor Yellow}
}

function OK($m)   { Write-FKReportLine "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-FKReportLine "[INFO] $m" }
function WARN($m) { Write-FKReportLine "[WARN] $m" -ForegroundColor Yellow }
function RISK($m) { Write-FKReportLine "[RISK] $m" -ForegroundColor Red }
function FAIL($m) { Write-FKReportLine "[FAIL] $m" -ForegroundColor Red }

function Section {
    param([string]$Title)

    Write-FKReportLine ""
    Write-FKReportLine (" {0} " -f $Title) `
        -ForegroundColor White `
        -BackgroundColor DarkGray
}

function Pause-End {
    Write-Host ''
    Write-Host 'SESSION COMPLETE'
    Write-FKReportLine ""
    Read-Host 'Press Enter to close session.' | Out-Null
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

    Write-FKReportLine ""
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
    $module=Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "Microsoft.Graph.Authentication is required but is not installed. Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
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

    Write-FKReportLine "Graph: Connecting..."

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

    return $items.ToArray()
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
    Write-FKReportLine 'IR: Review Token Replay'
    Write-FKReportLine 'Review sign-ins for indicators of token replay or session theft.'
    Write-FKReportLine "READ-ONLY INDICATOR REVIEW"
    Write-FKReportLine ""

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
        -Uri "https://graph.microsoft.com/v1.0/users/${encodedUPN}?`$select=displayName,userPrincipalName,lastPasswordChangeDateTime"

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

    Write-FKReportLine "Target          : $($user.userPrincipalName)"
    Write-FKReportLine "Display Name    : $($user.displayName)"
    Write-FKReportLine "Lookback        : $LookbackHours hours"
    Write-FKReportLine "Expected country: $($expectedCountries -join ', ')"
    Write-FKReportLine "Password change : $passwordChangeText"

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

            Write-FKReportLine "$time | $result | $location | $ip | $app | $device | Risk=$risk"
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

    Write-FKReportLine "TOKEN REPLAY CHECK SUMMARY"
    Write-FKReportLine "--------------------------------------"
    Write-FKReportLine "Target                    : $UPN"
    Write-FKReportLine "Timestamp                 : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-FKReportLine "Lookback                  : $LookbackHours hours"
    Write-FKReportLine "Expected country          : $($expectedCountries -join ', ')"
    Write-FKReportLine "Password change           : $passwordChangeText"
    Write-FKReportLine "Sign-ins reviewed         : $($signIns.Count)"
    Write-FKReportLine "Risk detections reviewed  : $($riskDetections.Count)"
    Write-FKReportLine "Direct token detections   : $($directTokenDetections.Count)"
    Write-FKReportLine "Supporting detections     : $($supportingDetections.Count)"
    Write-FKReportLine "Unexpected successes      : $($unexpectedSuccesses.Count)"
    Write-FKReportLine "Post-change unexpected    : $($postPasswordChangeUnexpected.Count)"
    Write-FKReportLine "Risky sign-ins            : $($riskySignIns.Count)"
    Write-FKReportLine "Limitations               : $($limitations.Count)"
    Write-FKReportLine "Verdict                   : $verdict"
    Write-FKReportLine "Recommendation            : $recommendation"

    if ($directTokenDetections.Count -gt 0) {
        Write-FKReportLine ""
        Write-FKReportLine "Direct token detections:"

        foreach ($detection in $directTokenDetections) {
            Write-FKReportLine (
                "- {0} | {1} | {2} | {3}" -f
                $detection.activityDateTime,
                $detection.riskEventType,
                $detection.riskLevel,
                $detection.ipAddress
            )
        }
    }

    if ($limitations.Count -gt 0) {
        Write-FKReportLine ""
        Write-FKReportLine "Limitations:"

        foreach ($limitation in $limitations) {
            Write-FKReportLine "- $limitation"
        }
    }
}
catch {
    Write-FKReportLine ""
    FAIL (Get-ShortError $_)
}
finally {
    Offer-FKDesktopReport -Title 'IR-GET-TOKEN-REPLAY-CHECK'

    Pause-End
}
