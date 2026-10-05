#Requires -Version 5.1

<#
IR AUDIT - FILE ACTIVITY / EXFIL REVIEW

OBJECTIVE
Review SharePoint and OneDrive audit activity for a target user with emphasis on
downloads, sharing, and suspicious source IPs.

READ-ONLY
No tenant changes.
Optional CSV export only.

INTERPRETATION
This tool surfaces activity that may warrant exfiltration review.
It does not label file activity as confirmed exfiltration.
#>

param(
    [string]$UPN,
    [ValidateRange(1,90)]
    [int]$Days = 30,
    [string]$FilterIP,
    [ValidateRange(1,10000)]
    [int]$DownloadBurstThreshold = 25,
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

function Get-RiskLabel {
    param($Record)

    $operation = [string]$Record.Operation

    if ($operation -match '(?i)(AnonymousLink|SharingInvitation|AddedToSecureLink|SecureLinkCreated|SharingSet)') {
        return "SHARING"
    }

    if ($operation -match '^(?i)(FileDownloaded|FileSyncDownloadedFull)$') {
        return "DOWNLOAD"
    }

    return "REVIEW"
}

try {
    Write-Host "IR AUDIT - FILE ACTIVITY / EXFIL REVIEW"
    Write-Host "READ-ONLY"
    Write-Host ""

    if (-not $UPN) {
        $UPN = (Read-Host "Target user UPN").Trim()
    }

    if (-not $UPN) {
        throw "Target user UPN is required."
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

    if (-not $FilterIP) {
        $FilterIP = (Read-Host "Filter by IP [blank for all]").Trim()
    }

    if ($FilterIP -and -not (Test-IP -Address $FilterIP)) {
        throw "Filter IP is not a valid IP address."
    }

    Section "CONNECT"
    Connect-ExchangeAuto

    if (-not (Get-Command Search-UnifiedAuditLog -ErrorAction SilentlyContinue)) {
        throw "Search-UnifiedAuditLog is unavailable in the current Exchange session."
    }

    $operations = @(
        "FileAccessed",
        "FilePreviewed",
        "FileDownloaded",
        "FileSyncDownloadedFull",
        "FileUploaded",
        "FileCopied",
        "FileMoved",
        "SharingSet",
        "SharingInvitationCreated",
        "AnonymousLinkCreated",
        "AnonymousLinkUsed",
        "AddedToSecureLink",
        "SecureLinkCreated"
    )

    $endUtc = (Get-Date).ToUniversalTime()
    $startUtc = $endUtc.AddDays(-1 * $Days)

    Section "SEARCH PLAN"

    Write-Host "Target     : $UPN"
    Write-Host "Start UTC  : $startUtc"
    Write-Host "End UTC    : $endUtc"
    Write-Host "IP filter  : $(if ($FilterIP) { $FilterIP } else { 'Any' })"
    Write-Host "Burst flag : $DownloadBurstThreshold download event(s) in one clock hour"
    Write-Host ""
    INFO "UAL can be delayed. Search failures or result caps are reported as data gaps."

    if (-not (Confirm-Yes "Run file activity audit now")) {
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
            -Operations $operations `
            -UserId $UPN `
            -IPAddress $FilterIP

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
        $record | Add-Member `
            -NotePropertyName Risk `
            -NotePropertyValue (Get-RiskLabel $record) `
            -Force

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
            WARN "No matching file activity returned, but search coverage is incomplete."
        }
        else {
            INFO "No matching file activity returned."
        }
    }
    else {
        foreach ($record in ($records | Sort-Object CreationDate -Descending | Select-Object -First 50)) {
            $line = (
                "{0} | {1,-8} | {2,-28} | {3} | {4}" -f
                $record.CreationDate,
                $record.Risk,
                $record.Operation,
                $record.ClientIP,
                $record.ObjectId
            )

            if ($record.Risk -eq "SHARING") {
                RISK $line
            }
            elseif ($record.Risk -eq "DOWNLOAD") {
                WARN $line
            }
            else {
                Write-Host $line
            }
        }

        if ($records.Count -gt 50) {
            INFO "Only the 50 newest records are shown."
        }
    }

    $downloads = @($records | Where-Object { $_.Risk -eq "DOWNLOAD" })
    $sharing = @($records | Where-Object { $_.Risk -eq "SHARING" })
    $uniqueIPs = @(
        $records |
        Where-Object { $_.ClientIP } |
        Select-Object -ExpandProperty ClientIP -Unique
    )

    $downloadHourGroups = @(
        $downloads |
        Group-Object {
            try {
                ([datetime]$_.CreationDate).ToUniversalTime().ToString("yyyy-MM-dd HH")
            }
            catch {
                "Unknown"
            }
        } |
        Sort-Object Count -Descending
    )

    $maxHourlyDownloads = 0
    $maxHour = "None"

    if ($downloadHourGroups.Count -gt 0) {
        $maxHourlyDownloads = [int]$downloadHourGroups[0].Count
        $maxHour = [string]$downloadHourGroups[0].Name + " UTC"
    }

    Section "SUMMARY"

    if ($dataGaps.Count -gt 0) {
        $verdict = "INCOMPLETE - FILE ACTIVITY COVERAGE HAS DATA GAPS"
        $recommendation = "Resolve failed or capped UAL windows before making a clean exfiltration determination"
    }
    elseif ($sharing.Count -gt 0) {
        $verdict = "SHARING ACTIVITY FOUND - REVIEW"
        $recommendation = "Review sharing targets, link type, object, timing, and source IP"
    }
    elseif ($maxHourlyDownloads -ge $DownloadBurstThreshold) {
        $verdict = "DOWNLOAD BURST FOUND - REVIEW"
        $recommendation = "Review download volume, objects, IPs, and endpoint context"
    }
    elseif ($records.Count -gt 0) {
        $verdict = "FILE ACTIVITY FOUND"
        $recommendation = "Review returned operations in incident context"
    }
    else {
        $verdict = "NO MATCHING FILE ACTIVITY RETURNED"
        $recommendation = "No matching activity was returned in the reviewed UAL window"
    }

    Write-Host "FILE ACTIVITY / EXFIL REVIEW SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host "Target              : $UPN"
    Write-Host "Timestamp           : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Window              : $Days day(s)"
    Write-Host "IP filter           : $(if ($FilterIP) { $FilterIP } else { 'Any' })"
    Write-Host "Records             : $($records.Count)"
    Write-Host "Downloads           : $($downloads.Count)"
    Write-Host "Sharing             : $($sharing.Count)"
    Write-Host "Unique IPs          : $($uniqueIPs.Count)"
    Write-Host "Max hourly downloads: $maxHourlyDownloads"
    Write-Host "Max download hour   : $maxHour"
    Write-Host "Data gaps           : $($dataGaps.Count)"
    Write-Host "Verdict             : $verdict"
    Write-Host "Recommendation      : $recommendation"

    if ($dataGaps.Count -gt 0) {
        Write-Host ""
        Write-Host "Data gaps:"

        foreach ($gap in $dataGaps) {
            Write-Host "- $gap"
        }
    }

    if ($ExportCsv -or (Confirm-Yes "Export records to CSV")) {
        $safe = $UPN -replace '[^\w\.-]', '_'
        $path = Get-ExportPath -DefaultName "file-activity-$safe-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

        $records |
            Select-Object CreationDate,UserId,Operation,Workload,ClientIP,ObjectId,SiteUrl,SourceFile,SourceFolder,Risk |
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
