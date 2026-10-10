#Requires -Version 5.1

<#
GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1

OBJECTIVE
Read-only storage review for a local or remote Windows endpoint.

REPORTS
- OS and drive utilization.
- Known Windows cleanup candidate sizes.
- Top N largest files on the selected drive.
- Summary block with measured cleanup candidates and scan status.

NOTES
- Largest files are review evidence only. They are not automatically safe to delete.
- Remote targets require PowerShell remoting / WinRM.
- Full-drive scanning can take several minutes and may create noticeable disk I/O.
- No files are deleted and no settings are changed.
#>

[CmdletBinding()]
param(
    [string]$ComputerName = $env:COMPUTERNAME,

    [ValidatePattern('^[A-Za-z]$')]
    [string]$DriveLetter = 'C',

    [ValidateRange(1,50)]
    [int]$TopFiles = 10,

    [switch]$SkipLargestFiles
)

$ErrorActionPreference = 'Stop'

function Write-OK   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function Pause-End {
    Write-FieldKitFooter
    Read-Host "Press Enter to EXIT" | Out-Null
}

function Format-Bytes {
    param([double]$Bytes)

    if ($Bytes -ge 1TB) { return ("{0:N2} TB" -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ("{0:N2} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N2} KB" -f ($Bytes / 1KB)) }
    return ("{0:N0} B" -f $Bytes)
}

function Get-StorageData {
    param(
        [string]$TargetComputer,
        [string]$TargetDriveLetter,
        [int]$TargetTopFiles,
        [bool]$TargetSkipLargestFiles
    )

    $collector = {
        param(
            [string]$DriveLetter,
            [int]$TopFiles,
            [bool]$SkipLargestFiles
        )

        $ErrorActionPreference = 'Stop'

        function Measure-Folder {
            param(
                [string]$Label,
                [string]$Path
            )

            if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
                return [pscustomobject]@{
                    Label = $Label
                    Path = $Path
                    Present = $false
                    SizeBytes = [double]0
                    Status = 'Not present'
                }
            }

            $scanErrors = @()
            [double]$sum = 0

            Get-ChildItem -LiteralPath $Path -File -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable +scanErrors |
                ForEach-Object {
                    $sum += [double]$_.Length
                }

            return [pscustomobject]@{
                Label = $Label
                Path = $Path
                Present = $true
                SizeBytes = $sum
                Status = $(if ($scanErrors.Count -gt 0) { 'Measured with access gaps' } else { 'Measured' })
            }
        }

        $driveRoot = ("{0}:\" -f $DriveLetter)
        $driveId = ("{0}:" -f $DriveLetter)

        $drive = Get-CimInstance Win32_LogicalDisk -Filter ("DeviceID='{0}'" -f $driveId) -ErrorAction Stop
        if (-not $drive) {
            throw "Drive not found: $driveId"
        }

        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

        $candidatePaths = @(
            [pscustomobject]@{ Label='Previous Windows install'; Path=(Join-Path $driveRoot 'Windows.old') },
            [pscustomobject]@{ Label='Windows setup cache'; Path=(Join-Path $driveRoot '$WINDOWS.~BT') },
            [pscustomobject]@{ Label='Windows setup workspace'; Path=(Join-Path $driveRoot '$WINDOWS.~WS') },
            [pscustomobject]@{ Label='Windows Update download cache'; Path=(Join-Path $env:SystemRoot 'SoftwareDistribution\Download') },
            [pscustomobject]@{ Label='Delivery Optimization cache'; Path=(Join-Path $env:SystemRoot 'ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache') },
            [pscustomobject]@{ Label='Windows temp'; Path=(Join-Path $env:SystemRoot 'Temp') }
        )

        $cleanup = @(
            foreach ($candidate in $candidatePaths) {
                Measure-Folder -Label $candidate.Label -Path $candidate.Path
            }
        )

        $largest = @()
        $largestScanErrors = @()
        $scanSeconds = 0.0

        if (-not $SkipLargestFiles) {
            $watch = [System.Diagnostics.Stopwatch]::StartNew()

            Get-ChildItem -LiteralPath $driveRoot -File -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable +largestScanErrors |
                ForEach-Object {
                    $row = [pscustomobject]@{
                        Path = $_.FullName
                        SizeBytes = [double]$_.Length
                    }

                    if ($largest.Count -lt $TopFiles) {
                        $largest += $row
                    }
                    else {
                        $smallestIndex = 0
                        for ($i = 1; $i -lt $largest.Count; $i++) {
                            if ($largest[$i].SizeBytes -lt $largest[$smallestIndex].SizeBytes) {
                                $smallestIndex = $i
                            }
                        }

                        if ($row.SizeBytes -gt $largest[$smallestIndex].SizeBytes) {
                            $largest[$smallestIndex] = $row
                        }
                    }
                }

            $watch.Stop()
            $scanSeconds = [math]::Round($watch.Elapsed.TotalSeconds,1)
            $largest = @($largest | Sort-Object SizeBytes -Descending)
        }

        [double]$candidateTotal = 0
        foreach ($item in $cleanup) {
            if ($item.Present) {
                $candidateTotal += [double]$item.SizeBytes
            }
        }

        return [pscustomobject]@{
            ComputerName = $env:COMPUTERNAME
            OSCaption = $os.Caption
            OSVersion = $os.Version
            LastBootUpTime = $os.LastBootUpTime
            Drive = $drive.DeviceID
            SizeBytes = [double]$drive.Size
            FreeBytes = [double]$drive.FreeSpace
            CleanupCandidates = @($cleanup)
            CleanupCandidateBytes = $candidateTotal
            LargestFiles = @($largest)
            LargestFilesSkipped = $SkipLargestFiles
            LargestFileScanSeconds = $scanSeconds
            LargestFileAccessGaps = $largestScanErrors.Count
        }
    }

    $isLocal = (
        [string]::IsNullOrWhiteSpace($TargetComputer) -or
        $TargetComputer -eq '.' -or
        $TargetComputer -eq 'localhost' -or
        $TargetComputer -eq $env:COMPUTERNAME
    )

    if ($isLocal) {
        return (& $collector $TargetDriveLetter $TargetTopFiles $TargetSkipLargestFiles)
    }

    return Invoke-Command -ComputerName $TargetComputer -ScriptBlock $collector -ArgumentList $TargetDriveLetter,$TargetTopFiles,$TargetSkipLargestFiles -ErrorAction Stop
}

try {
    Write-Host "WINDOWS STORAGE CLEANUP REVIEW"
    Write-Host "READ-ONLY. NO FILES WILL BE DELETED."
    Write-Host ""

    if (-not $SkipLargestFiles) {
        Write-Info "Scanning the full drive for the $TopFiles largest files. This can take several minutes."
    }

    $data = Get-StorageData -TargetComputer $ComputerName -TargetDriveLetter $DriveLetter -TargetTopFiles $TopFiles -TargetSkipLargestFiles ([bool]$SkipLargestFiles)

    [double]$usedBytes = $data.SizeBytes - $data.FreeBytes
    [double]$freePct = if ($data.SizeBytes -gt 0) { ($data.FreeBytes / $data.SizeBytes) * 100 } else { 0 }

    Write-Host ""
    Write-Host "ENDPOINT"
    Write-Host ("Computer      : {0}" -f $data.ComputerName)
    Write-Host ("OS            : {0}" -f $data.OSCaption)
    Write-Host ("OS Version    : {0}" -f $data.OSVersion)
    Write-Host ("Last Boot     : {0}" -f $data.LastBootUpTime)

    Write-Host ""
    Write-Host "DRIVE"
    Write-Host ("Drive         : {0}" -f $data.Drive)
    Write-Host ("Total         : {0}" -f (Format-Bytes $data.SizeBytes))
    Write-Host ("Used          : {0}" -f (Format-Bytes $usedBytes))
    Write-Host ("Free          : {0} ({1:N1}%)" -f (Format-Bytes $data.FreeBytes),$freePct)

    Write-Host ""
    Write-Host "CLEANUP CANDIDATES"
    foreach ($item in @($data.CleanupCandidates)) {
        if ($item.Present) {
            Write-Host ("- {0,-31} {1,12}  {2}" -f $item.Label,(Format-Bytes $item.SizeBytes),$item.Status)
        }
        else {
            Write-Host ("- {0,-31} {1}" -f $item.Label,'Not present')
        }
    }

    Write-Host ""
    Write-Host ("TOP {0} LARGEST FILES" -f $TopFiles)

    if ($data.LargestFilesSkipped) {
        Write-Host "- Skipped by request"
    }
    elseif (@($data.LargestFiles).Count -eq 0) {
        Write-Host "- None returned"
    }
    else {
        $rank = 0
        foreach ($file in @($data.LargestFiles)) {
            $rank++
            Write-Host ("{0,2}. {1,12}  {2}" -f $rank,(Format-Bytes $file.SizeBytes),$file.Path)
        }
    }

    Write-Host ""
    Write-Host "SUMMARY"
    Write-Host ("Endpoint                    : {0}" -f $data.ComputerName)
    Write-Host ("Free space                  : {0}" -f (Format-Bytes $data.FreeBytes))
    Write-Host ("Measured cleanup candidates : {0}" -f (Format-Bytes $data.CleanupCandidateBytes))

    if ($data.LargestFilesSkipped) {
        Write-Host "Largest-file scan           : Skipped"
    }
    else {
        $scanState = if ($data.LargestFileAccessGaps -gt 0) { "Completed with access gaps" } else { "Completed" }
        Write-Host ("Largest-file scan           : {0} in {1:N1}s" -f $scanState,$data.LargestFileScanSeconds)
        Write-Host ("Largest files returned      : {0}" -f @($data.LargestFiles).Count)
    }

    Write-Host ""
    Write-Warn "Largest files are review evidence only and are not included in the cleanup estimate."
    Write-Warn "Cleanup-candidate sizes are informational; validate before deleting caches or prior Windows data."
    Write-OK "Complete. No changes made."
}
catch {
    Write-Fail $_.Exception.Message
}
finally {
    Pause-End
}
