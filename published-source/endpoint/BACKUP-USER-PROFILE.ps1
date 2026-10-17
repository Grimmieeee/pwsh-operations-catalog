<#PSScriptInfo
.VERSION 0.1.0
.GUID 6685eb1e-d514-0576-1655-7819cd4da521
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
BACKUP-USER-PROFILE.ps1

Endpoint profile backup helper.

Purpose:
- Backs up common user profile folders to a selected destination
- Creates a dated folder per run
- Includes Desktop, Documents, Pictures, Favorites, Signatures, Templates
- Downloads optional
- Produces a local log file in the backup folder

Local file-write tool.
#>

param(
    [string]$UserProfilePath,
    [string]$DestinationRoot,
    [switch]$IncludeDownloads
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}


# Console presentation only. Does not request scopes, query services or write data.
$script:FKEndWritten = $false
$script:FKStatusWritten = $false
$script:FKHasIssue = $false
function Write-FKStatus {
    param([string]$Status)
    Write-Host ''
    if ($Status -eq 'REVIEW REQUIRED') { Write-Host ('STATUS: '+$Status) -ForegroundColor Yellow }
    else { Write-Host ('STATUS: '+$Status) }
    $script:FKStatusWritten = $true
}
function Write-FKStart {
    param([string]$Title,[string]$Objective,[string]$Mode)
    Write-Host $Title
    Write-Host $Objective
    if ($Mode) { Write-Host $Mode }
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Host ''
}
function Write-FKHeading {
    param([string]$Title)
    Write-Host ''
    switch ($Title.Trim().ToUpperInvariant()) {
        'SUMMARY' { Write-Host 'TICKET SUMMARY'; break }
        'FOLLOW-UP' { Write-Host 'NEXT STEP'; break }
        'NEXT' { Write-Host 'NEXT STEP'; break }
        default { Write-Host $Title }
    }
}
function Close-FKConsole {
    param([bool]$SkipPause = $false)
    if (-not $script:FKEndWritten) {
        Write-Host ''
        if (-not $script:FKStatusWritten) {
            Write-FKStatus $(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } else { 'RUN FINISHED' })
        }
        Write-Host ("COMPLETED: {0}" -f (Get-Date).ToString('MM/dd/yyyy HH:mm'))
        $script:FKEndWritten = $true
    }
    if ($SkipPause) { return }
    Write-Host ''
    Write-Host 'Press ESC to close'
    if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and
        (Get-Command Read-Host).CommandType -ne 'Function') {
        try {
            while ($true) {
                $key=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                if ($key.VirtualKeyCode -eq 27 -or $key.VirtualKeyCode -eq 13) { return }
            }
        }
        catch { Write-Host 'Key input unavailable here.' }
    }
    while ($true) {
        $answer=Read-Host 'Type ESC then press ENTER to close'
        if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -ieq 'ESC' -or $answer -eq [string][char]27) { return }
    }
}

function OK {
    param([string]$m)
    Write-Host '[OK] ' -ForegroundColor Green -NoNewline
    Write-Host $m
}
function INFO {
    param([string]$m)
    Write-Host '[INFO] ' -NoNewline
    Write-Host $m
}
function WARN {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
    Write-Host $m
}
function RISK {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[RISK] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}
function FAIL {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}

function Pause-End {
    Close-FKConsole
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
}

function Confirm-Yes {
    param([string]$Prompt)

    $a = Read-Host "$Prompt [Y/N]"
    return ($a.Trim().ToUpper() -eq "Y")
}

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    WARN $Prompt
    $a = Read-Host "Type $Required to continue"

    return ($a.Trim().ToUpper() -eq $Required.ToUpper())
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

function Get-InputLines {
    param([string]$Path)

    if (-not $Path) {
        $Path = (Read-Host "Input TXT/CSV path").Trim().Trim('"')
    }

    if (-not $Path -or -not (Test-Path $Path)) {
        FAIL "Input file not found"
        return @()
    }

    $items = New-Object System.Collections.ArrayList

    try {
        if ($Path.ToLower().EndsWith(".csv")) {
            $rows = Import-Csv -Path $Path -ErrorAction Stop

            foreach ($row in $rows) {
                $value = $null

                foreach ($name in @("UPN","UserPrincipalName","Email","Address","Group","GroupName","DisplayName","Name","Input")) {
                    if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                        $value = "$($row.$name)"
                        break
                    }
                }

                if (-not $value) {
                    $first = $row.PSObject.Properties | Select-Object -First 1
                    if ($first) { $value = "$($first.Value)" }
                }

                if ($value -and $value.Trim()) {
                    [void]$items.Add($value.Trim().Trim('"'))
                }
            }
        }
        else {
            $lines = Get-Content -Path $Path -Encoding UTF8 -ErrorAction Stop

            foreach ($line in $lines) {
                $clean = $line.Trim().Trim('"')

                if ($clean -and $clean -notmatch '^#') {
                    [void]$items.Add($clean)
                }
            }
        }
    }
    catch {
        FAIL "Could not read input file"
        return @()
    }

    return @($items | Select-Object -Unique)
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

function Copy-FolderSafe {
    param(
        [string]$Source,
        [string]$Destination,
        [System.Collections.ArrayList]$Log
    )

    if (-not (Test-Path $Source)) {
        WARN "Missing: $Source"
        [void]$Log.Add("SKIP | Missing | $Source")
        return
    }

    try {
        if (-not (Test-Path $Destination)) {
            New-Item -Path $Destination -ItemType Directory -Force | Out-Null
        }

        $cmd = "robocopy `"$Source`" `"$Destination`" /E /R:1 /W:1 /NFL /NDL /NP"
        INFO "Copying: $Source"
        cmd.exe /c $cmd | Out-Null
        $code = $LASTEXITCODE

        if ($code -le 7) {
            OK "Copied: $Source"
            [void]$Log.Add("OK | Copied | $Source -> $Destination")
        } else {
            WARN "Robocopy warning/failure code $code for $Source"
            [void]$Log.Add("WARN | Code $code | $Source -> $Destination")
        }
    }
    catch {
        WARN "Copy failed: $Source"
        [void]$Log.Add("FAIL | $($_.Exception.Message) | $Source")
    }
}

try {
    try { $host.UI.RawUI.WindowTitle = "Endpoint Profile Backup" } catch {}

    Clear-Host
    Write-FKStart -Title 'ENDPOINT PROFILE BACKUP' -Objective 'Copies common Windows profile folders to a dated backup location and writes a local backup log.' -Mode 'MAKES CHANGES'
    Write-Host "Local file-write tool"
    Write-Host ""

    if (-not $UserProfilePath) {
        $UserProfilePath = (Read-Host "User profile path [blank for current user]").Trim().Trim('"')
    }

    if (-not $UserProfilePath) {
        $UserProfilePath = $env:USERPROFILE
    }

    if (-not (Test-Path $UserProfilePath)) {
        FAIL "Profile path not found: $UserProfilePath"
        Pause-End
        exit 1
    }

    if (-not $DestinationRoot) {
        $DestinationRoot = (Read-Host "Backup destination root").Trim().Trim('"')
    }

    if (-not $DestinationRoot) {
        FAIL "Destination required"
        Pause-End
        exit 1
    }

    if (-not (Test-Path $DestinationRoot)) {
        if (Confirm-Yes "Destination does not exist. Create it") {
            New-Item -Path $DestinationRoot -ItemType Directory -Force | Out-Null
        }
    }

    if (-not (Test-Path $DestinationRoot)) {
        FAIL "Destination unavailable"
        Pause-End
        exit 1
    }

    if (-not $IncludeDownloads) {
        $IncludeDownloads = Confirm-Yes "Include Downloads folder"
    }

    $profileName = Split-Path $UserProfilePath -Leaf
    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRoot = Join-Path $DestinationRoot "$profileName-profile-backup-$stamp"
    $log = New-Object System.Collections.ArrayList

    Section "PLAN"
    Write-Host "Source      : $UserProfilePath"
    Write-Host "Destination : $backupRoot"
    Write-Host "Downloads   : $IncludeDownloads"
    Write-Host ""

    if (-not (Confirm-Type "This will copy profile data to the destination." "BACKUP")) {
        WARN "Cancelled"
        Pause-End
        exit 0
    }

    New-Item -Path $backupRoot -ItemType Directory -Force | Out-Null

    $folders = @(
        @{ Name="Desktop"; Path="Desktop" },
        @{ Name="Documents"; Path="Documents" },
        @{ Name="Pictures"; Path="Pictures" },
        @{ Name="Favorites"; Path="Favorites" },
        @{ Name="Signatures"; Path="AppData\Roaming\Microsoft\Signatures" },
        @{ Name="Templates"; Path="AppData\Roaming\Microsoft\Templates" }
    )

    if ($IncludeDownloads) {
        $folders += @{ Name="Downloads"; Path="Downloads" }
    }

    Section "BACKUP"

    foreach ($f in $folders) {
        $src = Join-Path $UserProfilePath $f.Path
        $dst = Join-Path $backupRoot $f.Name
        Copy-FolderSafe -Source $src -Destination $dst -Log $log
    }

    $logPath = Join-Path $backupRoot "profile-backup-log.txt"
    $log | Out-File -FilePath $logPath -Encoding UTF8

    Section "SUMMARY"
    Write-Host "Profile     : $UserProfilePath"
    Write-Host "Backup      : $backupRoot"
    Write-Host "Log         : $logPath"
    Write-Host "Operator    : $env:USERDOMAIN\$env:USERNAME"
    Write-Host "Time        : $(Now)"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
