#Requires -Version 5.1

<#
IR AUDIT - TENANT EMAIL SEARCH

OBJECTIVE
Search Exchange Online message trace for mail matching a sender, recipient,
source IP, or combination of indicators.

READ-ONLY
No tenant changes.
Optional CSV export only.

CURRENT TRACE MODEL
Uses Get-MessageTraceV2.
Searches up to 90 days back in windows no larger than 10 days.
A query window that reaches the configured row cap is reported as incomplete.
#>

param(
    [string]$Sender,
    [string]$Recipient,
    [string]$SourceIP,
    [ValidateRange(1,90)]
    [int]$LookbackDays = 7,
    [ValidateRange(1,5000)]
    [int]$ResultSize = 5000,
    [switch]$ExportCsv
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

function Ensure-Module {
    param(
        [string]$Name,
        [string]$RequiredCommand
    )

    if (Get-Command $RequiredCommand -ErrorAction SilentlyContinue) {
        return
    }

    $module = Get-Module -ListAvailable -Name $Name |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install it first with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop

    if (-not (Get-Command $RequiredCommand -ErrorAction SilentlyContinue)) {
        throw "$Name loaded, but $RequiredCommand is unavailable."
    }
}

function Test-ExchangeRead {
    try {
        $null = Get-AcceptedDomain `
            -ResultSize 1 `
            -ErrorAction Stop

        return $true
    }
    catch {
        return $false
    }
}

function Connect-ExchangeAuto {
    Ensure-Module `
        -Name "ExchangeOnlineManagement" `
        -RequiredCommand "Connect-ExchangeOnline"

    $connectionHealthy = $false

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        try {
            $connection = Get-ConnectionInformation -ErrorAction Stop |
                Where-Object {
                    $_.State -eq "Connected" -or
                    $_.ConnectionStatus -eq "Connected"
                } |
                Select-Object -First 1

            if ($connection -and (Test-ExchangeRead)) {
                $connectionHealthy = $true
            }
        }
        catch {
            $connectionHealthy = $false
        }
    }

    if ($connectionHealthy) {
        OK "Exchange session reused"
        return
    }

    Write-Host "Exchange Online: Connecting..."

    $command = Get-Command Connect-ExchangeOnline -ErrorAction Stop
    $parameters = @{
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ShowBanner")) {
        $parameters["ShowBanner"] = $false
    }

    if ($command.Parameters.ContainsKey("ShowProgress")) {
        $parameters["ShowProgress"] = $false
    }

    Connect-ExchangeOnline @parameters | Out-Null

    if (-not (Test-ExchangeRead)) {
        throw "Exchange connected, but a read operation could not be validated."
    }

    OK "Exchange connected"
}

function Test-IP {
    param([string]$Address)

    $parsed = $null
    return [System.Net.IPAddress]::TryParse($Address, [ref]$parsed)
}

function Get-TraceChunk {
    param(
        [datetime]$StartDate,
        [datetime]$EndDate
    )

    $parameters = @{
        StartDate   = $StartDate
        EndDate     = $EndDate
        ResultSize  = $ResultSize
        ErrorAction = "Stop"
    }

    if ($Sender) {
        $parameters["SenderAddress"] = $Sender
    }

    if ($Recipient) {
        $parameters["RecipientAddress"] = $Recipient
    }

    if ($SourceIP) {
        $parameters["FromIP"] = $SourceIP
    }

    return @(Get-MessageTraceV2 @parameters)
}

try {
    Write-Host "IR AUDIT - TENANT EMAIL SEARCH"
    Write-Host "READ-ONLY"
    Write-Host ""

    if (-not $Sender) {
        $Sender = (Read-Host "Sender address [blank for any]").Trim()
    }

    if (-not $Recipient) {
        $Recipient = (Read-Host "Recipient address [blank for any]").Trim()
    }

    if (-not $SourceIP) {
        $SourceIP = (Read-Host "Source IP [blank for any]").Trim()
    }

    if (-not $Sender -and -not $Recipient -and -not $SourceIP) {
        throw "Enter at least one indicator: sender, recipient, or source IP."
    }

    if ($SourceIP -and -not (Test-IP -Address $SourceIP)) {
        throw "Source IP is not a valid IP address."
    }

    $daysInput = Read-Host "Lookback days [default $LookbackDays, max 90]"

    if ($daysInput) {
        $parsedDays = 0

        if ([int]::TryParse($daysInput, [ref]$parsedDays)) {
            if ($parsedDays -lt 1) { $parsedDays = 1 }
            if ($parsedDays -gt 90) { $parsedDays = 90 }
            $LookbackDays = $parsedDays
        }
        else {
            WARN "Invalid lookback. Using $LookbackDays day(s)."
        }
    }

    Section "CONNECT"
    Connect-ExchangeAuto

    if (-not (Get-Command Get-MessageTraceV2 -ErrorAction SilentlyContinue)) {
        throw "Get-MessageTraceV2 is unavailable. Update ExchangeOnlineManagement before using this tool."
    }

    $endUtc = (Get-Date).ToUniversalTime()
    $startUtc = $endUtc.AddDays(-1 * $LookbackDays)

    Section "SEARCH PLAN"

    Write-Host "Start UTC   : $startUtc"
    Write-Host "End UTC     : $endUtc"
    Write-Host "Sender      : $(if ($Sender) { $Sender } else { 'Any' })"
    Write-Host "Recipient   : $(if ($Recipient) { $Recipient } else { 'Any' })"
    Write-Host "Source IP   : $(if ($SourceIP) { $SourceIP } else { 'Any' })"
    Write-Host "Result cap  : $ResultSize per query window"
    Write-Host ""
    INFO "Source IP uses the server-side FromIP filter."

    if (-not (Confirm-Yes "Run tenant email search now")) {
        WARN "Cancelled"
        return
    }

    Section "SEARCH"

    $all = New-Object System.Collections.Generic.List[object]
    $dataGaps = New-Object System.Collections.Generic.List[string]
    $cursor = $startUtc

    while ($cursor -lt $endUtc) {
        $chunkStart = $cursor
        $chunkEnd = $cursor.AddDays(10)

        if ($chunkEnd -gt $endUtc) {
            $chunkEnd = $endUtc
        }

        INFO "Searching $($chunkStart.ToString('yyyy-MM-dd HH:mm')) to $($chunkEnd.ToString('yyyy-MM-dd HH:mm')) UTC..."

        try {
            $rows = @(Get-TraceChunk -StartDate $chunkStart -EndDate $chunkEnd)

            foreach ($row in $rows) {
                $all.Add([PSCustomObject]@{
                    Received      = $row.Received
                    Sender        = [string]$row.SenderAddress
                    Recipient     = [string]$row.RecipientAddress
                    Subject       = [string]$row.Subject
                    Status        = [string]$row.Status
                    Size          = $row.Size
                    MessageId     = [string]$row.MessageId
                    SourceIP      = [string]$row.FromIP
                    DestinationIP = [string]$row.ToIP
                    TraceId       = [string]$row.MessageTraceId
                }) | Out-Null
            }

            if ($rows.Count -ge $ResultSize) {
                $dataGaps.Add(
                    "Trace row cap reached for $($chunkStart.ToString('yyyy-MM-dd')) to $($chunkEnd.ToString('yyyy-MM-dd')); narrow this window for complete coverage."
                ) | Out-Null
            }
        }
        catch {
            $dataGaps.Add(
                "Trace query failed for $($chunkStart.ToString('yyyy-MM-dd')) to $($chunkEnd.ToString('yyyy-MM-dd')): $(Get-ShortError $_)"
            ) | Out-Null
        }

        $cursor = $chunkEnd
    }

    $results = @(
        $all |
        Sort-Object TraceId,Recipient,Received -Unique
    )

    Section "RESULTS"

    if ($results.Count -eq 0) {
        if ($dataGaps.Count -gt 0) {
            WARN "No matching rows returned, but coverage is incomplete."
        }
        else {
            INFO "No matching message trace rows returned."
        }
    }
    else {
        OK "Matching rows: $($results.Count)"
        Write-Host ""

        foreach ($row in ($results | Sort-Object Received -Descending | Select-Object -First 50)) {
            Write-Host (
                "{0} | {1,-12} | {2} -> {3} | {4}" -f
                $row.Received,
                $row.Status,
                $row.Sender,
                $row.Recipient,
                $row.Subject
            )
        }

        if ($results.Count -gt 50) {
            INFO "Only the 50 newest rows are shown."
        }
    }

    $delivered = @(
        $results |
        Where-Object { $_.Status -in @("Delivered","Expanded") }
    ).Count

    $blockedOrFailed = @(
        $results |
        Where-Object { $_.Status -in @("Failed","FilteredAsSpam","Quarantined") }
    ).Count

    Section "SUMMARY"

    if ($dataGaps.Count -gt 0) {
        $verdict = "INCOMPLETE - REVIEW DATA GAPS"
        $recommendation = "Narrow failed or capped windows before making a clean determination"
    }
    elseif ($delivered -gt 0) {
        $verdict = "MATCHING EMAIL FOUND - DELIVERED ITEMS PRESENT"
        $recommendation = "Review delivered messages and confirm user exposure"
    }
    elseif ($results.Count -gt 0) {
        $verdict = "MATCHING EMAIL FOUND - REVIEW TRACE STATUS"
        $recommendation = "Review returned status before closing exposure scope"
    }
    else {
        $verdict = "NO MATCHING MESSAGE TRACE ROWS RETURNED"
        $recommendation = "No matching mail flow was returned in the reviewed trace window"
    }

    Write-Host "TENANT EMAIL SEARCH SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host "Timestamp      : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Window         : $LookbackDays day(s)"
    Write-Host "Sender         : $(if ($Sender) { $Sender } else { 'Any' })"
    Write-Host "Recipient      : $(if ($Recipient) { $Recipient } else { 'Any' })"
    Write-Host "Source IP      : $(if ($SourceIP) { $SourceIP } else { 'Any' })"
    Write-Host "Matches        : $($results.Count)"
    Write-Host "Delivered      : $delivered"
    Write-Host "Failed/Filtered: $blockedOrFailed"
    Write-Host "Data gaps      : $($dataGaps.Count)"
    Write-Host "Verdict        : $verdict"
    Write-Host "Recommendation : $recommendation"

    if ($dataGaps.Count -gt 0) {
        Write-Host ""
        Write-Host "Data gaps:"

        foreach ($gap in $dataGaps) {
            Write-Host "- $gap"
        }
    }

    if ($ExportCsv -or (Confirm-Yes "Export results to CSV")) {
        $path = Get-ExportPath -DefaultName "tenant-email-search-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

        $results |
            Export-Csv `
                -LiteralPath $path `
                -NoTypeInformation `
                -Encoding UTF8 `
                -ErrorAction Stop

        OK "Exported: $path"
    }

    Write-Host ""
    OK "Tenant email search complete"
}
catch {
    Write-Host ""
    FAIL (Get-ShortError $_)
}
finally {
    Pause-End
}
