#Requires -Version 5.1

<#
IR AUDIT - TIMELINE BUILDER

OBJECTIVE
Build a local chronological incident timeline from JSON evidence, text/log/MD
sources, and optional manual analyst entries.

READ-ONLY
Source files are never modified.
Optional TXT export only.

TIME HANDLING
Parsed timestamps are preferred.
If a source does not contain a usable event timestamp, file modified time is
used and explicitly labeled FILE MODIFIED so it is not mistaken for event time.
#>

param(
    [string]$CaseFolder,
    [string]$SearchText,
    [switch]$ExportTxt
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

$script:Events = New-Object System.Collections.Generic.List[object]
$script:DataGaps = New-Object System.Collections.Generic.List[string]

function Add-Event {
    param(
        [datetime]$Time,
        [string]$TimeBasis,
        [string]$Source,
        [string]$Phase,
        [string]$Action,
        [string]$Detail
    )

    $script:Events.Add([PSCustomObject]@{
        Time      = $Time
        TimeBasis = $TimeBasis
        Source    = $Source
        Phase     = $Phase
        Action    = $Action
        Detail    = $Detail
    })
}

function Try-ParseTime {
    param([object]$Value)

    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return $null
    }

    $parsed = [datetime]::MinValue

    if ([datetime]::TryParse([string]$Value, [ref]$parsed)) {
        return $parsed
    }

    return $null
}

function Get-ShortText {
    param(
        [string]$Text,
        [int]$Max = 220
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    $clean = ($Text -replace "\s+", " ").Trim()

    if ($clean.Length -le $Max) {
        return $clean
    }

    return $clean.Substring(0, $Max) + "..."
}

function Import-JsonEvidence {
    param([string]$Folder)

    $jsonFiles = @(
        Get-ChildItem `
            -LiteralPath $Folder `
            -Recurse `
            -Filter "*.json" `
            -File `
            -ErrorAction Stop
    )

    foreach ($file in $jsonFiles) {
        try {
            $content = Get-Content `
                -LiteralPath $file.FullName `
                -Raw `
                -ErrorAction Stop |
                ConvertFrom-Json `
                    -ErrorAction Stop

            foreach ($item in @($content)) {
                $searchBlob = ""

                try {
                    $searchBlob = $item | ConvertTo-Json -Depth 8 -Compress
                }
                catch {
                    $searchBlob = [string]$item
                }

                if ($SearchText -and $searchBlob -notlike "*$SearchText*") {
                    continue
                }

                $time = $null
                $basis = "PARSED"

                foreach ($field in @(
                    "Time",
                    "Timestamp",
                    "CreationDate",
                    "CreatedDateTime",
                    "Date",
                    "Completed",
                    "Updated"
                )) {
                    if ($item.PSObject.Properties.Name -contains $field) {
                        $time = Try-ParseTime $item.$field

                        if ($time) {
                            break
                        }
                    }
                }

                if (-not $time) {
                    $time = $file.LastWriteTime
                    $basis = "FILE MODIFIED"
                }

                $phase = if ($item.Phase) { [string]$item.Phase } else { "JSON" }

                $action = if ($item.Action) {
                    [string]$item.Action
                }
                elseif ($item.Status) {
                    [string]$item.Status
                }
                elseif ($item.Operation) {
                    [string]$item.Operation
                }
                else {
                    "Log entry"
                }

                $detail = if ($item.Detail) {
                    [string]$item.Detail
                }
                elseif ($item.Result) {
                    [string]$item.Result
                }
                else {
                    Get-ShortText -Text $searchBlob
                }

                Add-Event `
                    -Time $time `
                    -TimeBasis $basis `
                    -Source $file.Name `
                    -Phase $phase `
                    -Action $action `
                    -Detail (Get-ShortText -Text $detail)
            }
        }
        catch {
            $script:DataGaps.Add(
                "JSON import failed for $($file.FullName): $(Get-ShortError $_)"
            )
        }
    }
}

function Import-TextEvidence {
    param([string]$Folder)

    $textFiles = @(
        Get-ChildItem `
            -LiteralPath $Folder `
            -Recurse `
            -File `
            -ErrorAction Stop |
        Where-Object { $_.Extension -in @(".txt",".log",".md") }
    )

    foreach ($file in $textFiles) {
        try {
            $lines = @(Get-Content -LiteralPath $file.FullName -ErrorAction Stop)

            if (-not $SearchText) {
                Add-Event `
                    -Time $file.LastWriteTime `
                    -TimeBasis "FILE MODIFIED" `
                    -Source $file.Name `
                    -Phase "Text" `
                    -Action "Source file present" `
                    -Detail "No search text supplied; file represented by modified time only"

                continue
            }

            foreach ($line in $lines) {
                if ($line -notlike "*$SearchText*") {
                    continue
                }

                $time = $null
                $basis = "FILE MODIFIED"

                if (
                    $line -match
                    '^\s*(?<ts>\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?)'
                ) {
                    $time = Try-ParseTime $Matches["ts"]

                    if ($time) {
                        $basis = "PARSED"
                    }
                }

                if (-not $time) {
                    $time = $file.LastWriteTime
                }

                Add-Event `
                    -Time $time `
                    -TimeBasis $basis `
                    -Source $file.Name `
                    -Phase "Text" `
                    -Action "Search match" `
                    -Detail (Get-ShortText -Text $line)
            }
        }
        catch {
            $script:DataGaps.Add(
                "Text import failed for $($file.FullName): $(Get-ShortError $_)"
            )
        }
    }
}

function Add-ManualEvents {
    if (-not (Confirm-Yes "Add manual timeline entries")) {
        return
    }

    while ($true) {
        Write-Host ""
        $timeInput = Read-Host "Event time [blank to stop]"

        if ([string]::IsNullOrWhiteSpace($timeInput)) {
            break
        }

        $time = Try-ParseTime $timeInput

        if (-not $time) {
            WARN "Could not parse time. Entry skipped."
            continue
        }

        $phase = Read-Host "Phase"
        $action = Read-Host "Action"
        $detail = Read-Host "Detail"

        Add-Event `
            -Time $time `
            -TimeBasis "MANUAL" `
            -Source "Manual" `
            -Phase $phase `
            -Action $action `
            -Detail $detail
    }
}

try {
    Write-Host "IR AUDIT - TIMELINE BUILDER"
    Write-Host "LOCAL / READ-ONLY"
    Write-Host ""

    if (-not $CaseFolder) {
        $CaseFolder = Read-Host "Case folder [blank for manual only]"
        $CaseFolder = $CaseFolder.Trim().Trim('"').Trim("'")
    }

    if ($CaseFolder -and -not (Test-Path -LiteralPath $CaseFolder -PathType Container)) {
        throw "Case folder not found: $CaseFolder"
    }

    if (-not $SearchText) {
        $SearchText = (Read-Host "Optional search text / ticket / UPN").Trim()
    }

    if ($CaseFolder) {
        Section "IMPORT"
        INFO "Scanning: $CaseFolder"

        Import-JsonEvidence -Folder $CaseFolder
        Import-TextEvidence -Folder $CaseFolder

        OK "Imported event candidates: $($script:Events.Count)"
    }

    Add-ManualEvents

    $events = @($script:Events | Sort-Object Time,Source,Action)

    Section "TIMELINE"

    if ($events.Count -eq 0) {
        WARN "No timeline events were built."
    }
    else {
        foreach ($event in $events) {
            Write-Host (
                "{0} | {1,-13} | {2,-12} | {3,-20} | {4}" -f
                $event.Time.ToString("yyyy-MM-dd HH:mm:ss"),
                $event.TimeBasis,
                $event.Phase,
                $event.Action,
                $event.Detail
            )
        }
    }

    $parsedCount = @($events | Where-Object { $_.TimeBasis -eq "PARSED" }).Count
    $fileModifiedCount = @($events | Where-Object { $_.TimeBasis -eq "FILE MODIFIED" }).Count
    $manualCount = @($events | Where-Object { $_.TimeBasis -eq "MANUAL" }).Count

    Section "SUMMARY"

    Write-Host "IR TIMELINE SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host "Timestamp          : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "Folder             : $(if ($CaseFolder) { $CaseFolder } else { 'Manual only' })"
    Write-Host "Search             : $(if ($SearchText) { $SearchText } else { 'None' })"
    Write-Host "Events             : $($events.Count)"
    Write-Host "Parsed timestamps  : $parsedCount"
    Write-Host "File-modified basis: $fileModifiedCount"
    Write-Host "Manual timestamps  : $manualCount"
    Write-Host "Data gaps          : $($script:DataGaps.Count)"

    if ($fileModifiedCount -gt 0) {
        Write-Host ""
        WARN "FILE MODIFIED timestamps are evidence-file timestamps, not asserted incident-event times."
    }

    if ($script:DataGaps.Count -gt 0) {
        Write-Host ""
        Write-Host "Data gaps:"

        foreach ($gap in $script:DataGaps) {
            Write-Host "- $gap"
        }
    }

    if ($ExportTxt -or (Confirm-Yes "Export timeline to TXT")) {
        $path = Get-ExportPath -DefaultName "ir-timeline-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
        $lines = New-Object System.Collections.Generic.List[string]

        $lines.Add("IR TIMELINE")
        $lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        $lines.Add("")

        foreach ($event in $events) {
            $lines.Add(
                ("{0} | {1,-13} | {2,-12} | {3,-20} | {4}" -f
                    $event.Time.ToString("yyyy-MM-dd HH:mm:ss"),
                    $event.TimeBasis,
                    $event.Phase,
                    $event.Action,
                    $event.Detail
                )
            )
        }

        $lines |
            Out-File `
                -LiteralPath $path `
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
