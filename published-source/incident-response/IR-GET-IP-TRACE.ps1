#Requires -Version 5.1

<#
IR AUDIT - IP TRACE / UNIFIED AUDIT LOG

OBJECTIVE
Search the Microsoft 365 Unified Audit Log for tenant activity associated with
a suspect source IP.

READ-ONLY
No tenant changes.
Optional CSV export only.

SEARCH MODEL
Uses the Search-UnifiedAuditLog IPAddresses filter.
Searches one day at a time.
Failed windows and 50,000-record session caps are reported as data gaps.
#>

param(
    [string]$TargetIP,
    [ValidateRange(1,90)]
    [int]$Days = 7,
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

function Search-UALWindow {
    param(
        [datetime]$StartDate,
        [datetime]$EndDate,
        [string[]]$Operations,
        [string]$UserId,
        [string]$IPAddress
    )

    $sessionId = [guid]::NewGuid().ToString()
    $items = New-Object System.Collections.Generic.List[object]
    $pageSize = 5000
    $maxPages = 10
    $hitCap = $false

    try {
        for ($page = 1; $page -le $maxPages; $page++) {
            $parameters = @{
                StartDate      = $StartDate
                EndDate        = $EndDate
                ResultSize     = $pageSize
                SessionId      = $sessionId
                SessionCommand = "ReturnLargeSet"
                ErrorAction    = "Stop"
            }

            if ($Operations -and $Operations.Count -gt 0) {
                $parameters["Operations"] = $Operations
            }

            if (-not [string]::IsNullOrWhiteSpace($UserId)) {
                $parameters["UserIds"] = $UserId
            }

            if (-not [string]::IsNullOrWhiteSpace($IPAddress)) {
                $parameters["IPAddresses"] = @($IPAddress)
            }

            $rows = @(Search-UnifiedAuditLog @parameters)

            foreach ($row in $rows) {
                $items.Add($row) | Out-Null
            }

            if ($rows.Count -eq 0 -or $rows.Count -lt $pageSize) {
                break
            }

            if ($page -eq $maxPages) {
                $hitCap = $true
            }
        }

        return [PSCustomObject]@{
            Success = $true
            Items   = @($items)
            HitCap  = $hitCap
            Error   = ""
        }
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Items   = @($items)
            HitCap  = $false
            Error   = Get-ShortError $_
        }
    }
}

function Convert-UALRecord {
    param($Row)

    $data = $null

    try {
        $data = $Row.AuditData | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
    }

    $clientIP = ""

    if ($data) {
        foreach ($property in @(
            "ClientIP",
            "ClientIPAddress",
            "ActorIpAddress"
        )) {
            if ($data.$property) {
                $clientIP = [string]$data.$property
                break
            }
        }
    }

    $recordId = ""

    if ($data -and $data.Id) {
        $recordId = [string]$data.Id
    }
    elseif ($Row.Identity) {
        $recordId = [string]$Row.Identity
    }

    $creationDate = $Row.CreationDate

    if ($data -and $data.CreationTime) {
        try {
            $creationDate = [datetime]$data.CreationTime
        }
        catch {
        }
    }

    return [PSCustomObject]@{
        RecordId     = $recordId
        CreationDate = $creationDate
        UserId       = if ($data -and $data.UserId) {
            [string]$data.UserId
        }
        else {
            [string]$Row.UserIds
        }
        Operation    = if ($data -and $data.Operation) {
            [string]$data.Operation
        }
        else {
            [string]$Row.Operations
        }
        Workload     = if ($data -and $data.Workload) {
            [string]$data.Workload
        }
        else {
            [string]$Row.Workload
        }
        ClientIP     = $clientIP
        ObjectId     = if ($data) { [string]$data.ObjectId } else { "" }
        SiteUrl      = if ($data) { [string]$data.SiteUrl } else { "" }
        SourceFile   = if ($data) { [string]$data.SourceFileName } else { "" }
        SourceFolder = if ($data) { [string]$data.SourceRelativeUrl } else { "" }
        Raw           = $data
    }
}

function Test-IP {
    param([string]$Address)

    $parsed = $null
    return [System.Net.IPAddress]::TryParse($Address, [ref]$parsed)
}

try {
    Write-Host "IR AUDIT - IP TRACE / UNIFIED AUDIT LOG"
    Write-Host "READ-ONLY"
    Write-Host ""

    if (-not $TargetIP) {
        $TargetIP = (Read-Host "Target IP").Trim()
    }

    if (-not $TargetIP) {
        throw "Target IP is required."
    }

    if (-not (Test-IP -Address $TargetIP)) {
        throw "Target IP is not a valid IP address."
    }

    $daysInput = Read-Host "Days to search back [default $Days, max 90]"

    if ($daysInput) {
        $parsedDays = 0

        if ([int]::TryParse($daysInput, [ref]$parsedDays)) {
            if ($parsedDays -lt 1) { $parsedDays = 1 }
            if ($parsedDays -gt 90) { $parsedDays = 90 }
            $Days = $parsedDays
        }
    }

    Section "CONNECT"
    Connect-ExchangeAuto

    if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
        throw "Search-UnifiedAuditLog is unavailable in the current Exchange session."
    }

    $endUtc = (Get-Date).ToUniversalTime()
    $startUtc = $endUtc.AddDays(-1 * $Days)

    Section "SEARCH PLAN"

    Write-Host "Target IP : $TargetIP"
    Write-Host "Start UTC : $startUtc"
    Write-Host "End UTC   : $endUtc"
    Write-Host ""
    INFO "The IP is passed to Search-UnifiedAuditLog using the IPAddresses filter."

    if (-not (Confirm-Yes "Run tenant-wide UAL IP trace now")) {
        WARN "Cancelled"
        return
    }

    Section "SEARCH"

    $rawRows = New-Object System.Collections.Generic.List[object]
    $dataGaps = New-Object System.Collections.Generic.List[string]
    $cursor = $startUtc

    while ($cursor -lt $endUtc) {
        $chunkStart = $cursor
        $chunkEnd = $cursor.AddDays(1)

        if ($chunkEnd -gt $endUtc) {
            $chunkEnd = $endUtc
        }

        INFO "Searching $($chunkStart.ToString('yyyy-MM-dd')) UTC..."

        $result = Search-UALWindow `
            -StartDate $chunkStart `
            -EndDate $chunkEnd `
            -Operations @() `
            -UserId "" `
            -IPAddress $TargetIP

        foreach ($row in $result.Items) {
            $rawRows.Add($row)
        }

        if (-not $result.Success) {
            $dataGaps.Add(
                "$($chunkStart.ToString('yyyy-MM-dd')) query failed: $($result.Error)"
            )
        }
        elseif ($result.HitCap) {
            $dataGaps.Add(
                "$($chunkStart.ToString('yyyy-MM-dd')) reached the 50,000-record UAL session cap."
            )
        }

        $cursor = $chunkEnd
    }

    $recordsByKey = @{}

    foreach ($row in $rawRows) {
        $record = Convert-UALRecord $row

        $key = if ($record.RecordId) {
            $record.RecordId
        }
        else {
            "$($record.CreationDate)|$($record.UserId)|$($record.Operation)|$($record.ObjectId)|$($record.ClientIP)"
        }

        if (-not $recordsByKey.ContainsKey($key)) {
            $recordsByKey[$key] = $record
        }
    }

    $records = @($recordsByKey.Values)

    Section "RESULTS"

    if ($records.Count -eq 0) {
        if ($dataGaps.Count -gt 0) {
            WARN "No matching UAL rows returned, but coverage is incomplete."
        }
        else {
            INFO "No matching UAL rows returned for the target IP."
        }
    }
    else {
        foreach ($record in ($records | Sort-Object CreationDate -Descending | Select-Object -First 75)) {
            Write-Host (
                "{0} | {1,-30} | {2,-28} | {3} | {4}" -f
                $record.CreationDate,
                $record.UserId,
                $record.Operation,
                $record.Workload,
                $record.ObjectId
            )
        }

        if ($records.Count -gt 75) {
            INFO "Only the 75 newest records are shown."
        }
    }

    $affectedUsers = @(
        $records |
        Where-Object { $_.UserId } |
        Select-Object -ExpandProperty UserId -Unique
    )

    $topOperations = @(
        $records |
        Group-Object Operation |
        Sort-Object Count -Descending |
        Select-Object -First 10
    )

    $topWorkloads = @(
        $records |
        Group-Object Workload |
        Sort-Object Count -Descending |
        Select-Object -First 10
    )

    Section "SUMMARY"

    if ($dataGaps.Count -gt 0) {
        $verdict = "INCOMPLETE - UAL COVERAGE HAS DATA GAPS"
        $recommendation = "Resolve failed or capped windows before making a clean scope determination"
    }
    elseif ($records.Count -gt 0 -and $affectedUsers.Count -gt 1) {
        $verdict = "TARGET IP ACTIVITY FOUND ACROSS MULTIPLE USERS"
        $recommendation = "Review affected users, operations, workloads, and timing for compromise scope"
    }
    elseif ($records.Count -gt 0) {
        $verdict = "TARGET IP ACTIVITY FOUND"
        $recommendation = "Review returned UAL activity in incident context"
    }
    else {
        $verdict = "NO MATCHING UAL RECORDS RETURNED"
        $recommendation = "No activity for the target IP was returned in the reviewed UAL window"
    }

    Write-Host "UAL IP TRACE SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host "Target IP      : $TargetIP"
    Write-Host "Timestamp      : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Window         : $Days day(s)"
    Write-Host "Records        : $($records.Count)"
    Write-Host "Affected Users : $($affectedUsers.Count)"
    Write-Host "Data gaps      : $($dataGaps.Count)"
    Write-Host "Verdict        : $verdict"
    Write-Host "Recommendation : $recommendation"

    if ($affectedUsers.Count -gt 0) {
        Write-Host ""
        Write-Host "Affected users:"

        foreach ($user in ($affectedUsers | Select-Object -First 20)) {
            Write-Host "- $user"
        }

        if ($affectedUsers.Count -gt 20) {
            Write-Host "- plus $($affectedUsers.Count - 20) more"
        }
    }

    if ($topOperations.Count -gt 0) {
        Write-Host ""
        Write-Host "Top operations:"

        foreach ($group in $topOperations) {
            Write-Host "- $($group.Name): $($group.Count)"
        }
    }

    if ($topWorkloads.Count -gt 0) {
        Write-Host ""
        Write-Host "Top workloads:"

        foreach ($group in $topWorkloads) {
            Write-Host "- $($group.Name): $($group.Count)"
        }
    }

    if ($dataGaps.Count -gt 0) {
        Write-Host ""
        Write-Host "Data gaps:"

        foreach ($gap in $dataGaps) {
            Write-Host "- $gap"
        }
    }

    if ($ExportCsv -or (Confirm-Yes "Export records to CSV")) {
        $safe = $TargetIP -replace '[^\w\.-]', '_'
        $path = Get-ExportPath -DefaultName "ual-ip-trace-$safe-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

        $records |
            Select-Object CreationDate,UserId,Operation,Workload,ClientIP,ObjectId,SiteUrl,SourceFile,SourceFolder |
            Export-Csv `
                -LiteralPath $path `
                -NoTypeInformation `
                -Encoding UTF8 `
                -ErrorAction Stop

        OK "Exported: $path"
    }
}
catch {
    Write-Host ""
    FAIL (Get-ShortError $_)
}
finally {
    Pause-End
}
