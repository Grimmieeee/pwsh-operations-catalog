#Requires -Version 5.1

<#
.SYNOPSIS
Read-only folder and repository inventory.

.DESCRIPTION
Shows the structure and basic health of a selected folder or Git repository.
Reports folders, files, PowerShell script counts, common script naming patterns,
Authenticode signature state, and Git working-tree status when available.

No files are created, changed, moved, signed, or deleted.
#>

[CmdletBinding()]
param(
    [string]$Path,
    [ValidateRange(1,50)]
    [int]$MaxDepth = 10,
    [switch]$FoldersOnly,
    [switch]$SkipSignatureCheck,
    [switch]$NoFileMap,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

function Write-Ok   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }

function Show-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host (" {0} " -f $Title) -ForegroundColor White -BackgroundColor DarkGray
}

function Show-Field {
    param([string]$Label,[object]$Value,[string]$Color = 'White')
    $left = '{0,-22}' -f $Label
    Write-Host "$left : " -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor $Color
}

function Pause-End {
    if (-not $NoPause) {
        Write-Host ''
        Read-Host 'Press Enter to EXIT' | Out-Null
    }
}

function Get-RelativePath {
    param([string]$FullName,[string]$Root)
    if ($FullName.StartsWith($Root,[System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullName.Substring($Root.Length).TrimStart('\')
    }
    return $FullName
}

function Find-GitRoot {
    param([string]$StartPath)
    if ([string]::IsNullOrWhiteSpace($StartPath)) { return $null }

    try { $cursor = (Get-Item -LiteralPath $StartPath -ErrorAction Stop).FullName }
    catch { return $null }

    for ($i = 0; $i -lt 20 -and $cursor; $i++) {
        if (Test-Path -LiteralPath (Join-Path $cursor '.git')) {
            return $cursor.TrimEnd('\')
        }
        $parent = Split-Path -Path $cursor -Parent
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) { break }
        $cursor = $parent
    }
    return $null
}

function Resolve-InventoryRoot {
    param([string]$InputPath)

    if ($InputPath) {
        if (-not (Test-Path -LiteralPath $InputPath -PathType Container)) {
            throw "Folder not found: $InputPath"
        }
        return (Get-Item -LiteralPath $InputPath -ErrorAction Stop).FullName.TrimEnd('\')
    }

    $candidate = $null
    if ($PSScriptRoot) { $candidate = Find-GitRoot -StartPath $PSScriptRoot }
    if (-not $candidate) {
        try { $candidate = Find-GitRoot -StartPath (Get-Location).Path } catch {}
    }
    if (-not $candidate) {
        try { $candidate = (Get-Location).Path } catch {}
    }

    Write-Host ''
    if ($candidate) { Write-Host "Detected folder: $candidate" }
    $typed = Read-Host 'Folder to inventory [Enter = detected folder]'
    if (-not [string]::IsNullOrWhiteSpace($typed)) { $candidate = $typed.Trim().Trim('"') }

    if (-not $candidate -or -not (Test-Path -LiteralPath $candidate -PathType Container)) {
        throw 'A valid folder path is required.'
    }

    return (Get-Item -LiteralPath $candidate -ErrorAction Stop).FullName.TrimEnd('\')
}

function Show-Tree {
    param([string]$CurrentPath,[int]$Level,[int]$Limit)
    if ($Level -ge $Limit) { return }

    $indent = '  ' * $Level
    $dirs = @(Get-ChildItem -LiteralPath $CurrentPath -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne '.git' } | Sort-Object Name)

    foreach ($dir in $dirs) {
        Write-Host "$indent[$($dir.Name)]" -ForegroundColor White
        Show-Tree -CurrentPath $dir.FullName -Level ($Level + 1) -Limit $Limit
    }

    if (-not $FoldersOnly) {
        $files = @(Get-ChildItem -LiteralPath $CurrentPath -File -ErrorAction SilentlyContinue | Sort-Object Name)
        foreach ($file in $files) {
            $color = if ($file.Extension -ieq '.ps1') { 'White' } else { 'DarkGray' }
            Write-Host "$indent$($file.Name)" -ForegroundColor $color
        }
    }
}

function Get-GitSummary {
    param([string]$Root)
    $result = [ordered]@{ Repository=$false; Branch=''; Changes=0; Untracked=0 }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return [pscustomobject]$result }
    if (-not (Test-Path -LiteralPath (Join-Path $Root '.git'))) { return [pscustomobject]$result }

    $result.Repository = $true
    try {
        $branch = (& git -C $Root branch --show-current 2>$null | Select-Object -First 1)
        if ($branch) { $result.Branch = ([string]$branch).Trim() }
        $status = @(& git -C $Root status --porcelain 2>$null)
        $result.Changes = $status.Count
        $result.Untracked = @($status | Where-Object { $_ -match '^\?\?' }).Count
    } catch {}

    return [pscustomobject]$result
}

try {
    Write-Host 'FOLDER INVENTORY'
    Write-Host 'READ ONLY. No files are changed.'

    $root = Resolve-InventoryRoot -InputPath $Path
    $git = Get-GitSummary -Root $root

    $topFolders = @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction Stop |
        Where-Object { $_.Name -ne '.git' } | Sort-Object Name)
    $folders = @(Get-ChildItem -LiteralPath $root -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\.git(\\|$)' })
    $files = @(Get-ChildItem -LiteralPath $root -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '\\.git(\\|$)' } | Sort-Object FullName)
    $scripts = @($files | Where-Object { $_.Extension -ieq '.ps1' })
    $docs = @($files | Where-Object { $_.Extension -in @('.md','.txt','.docx','.pdf') })

    Show-Section 'SUMMARY'
    Show-Field 'Root' $root
    Show-Field 'Folders' $folders.Count
    Show-Field 'Files' $files.Count
    Show-Field 'PowerShell files' $scripts.Count 'Cyan'
    Show-Field 'Documents' $docs.Count
    Show-Field 'Max depth' $MaxDepth

    if ($git.Repository) {
        Show-Field 'Git repository' 'Yes' 'Green'
        Show-Field 'Git branch' $(if ($git.Branch) { $git.Branch } else { 'detached / unknown' })
        Show-Field 'Git changes' $git.Changes $(if ($git.Changes -gt 0) { 'Yellow' } else { 'Green' })
        Show-Field 'Git untracked' $git.Untracked $(if ($git.Untracked -gt 0) { 'Yellow' } else { 'Green' })
    } else {
        Show-Field 'Git repository' 'No'
    }

    Show-Section 'TOP-LEVEL FOLDERS'
    if ($topFolders.Count -eq 0) { Write-Info 'No subfolders found.' }
    foreach ($folder in $topFolders) { Write-Host "  $($folder.Name)" }

    Show-Section 'TREE'
    Write-Host "[$((Get-Item -LiteralPath $root).Name)]" -ForegroundColor White
    Show-Tree -CurrentPath $root -Level 1 -Limit $MaxDepth

    if (-not $NoFileMap) {
        Show-Section 'FILE MAP'
        if ($files.Count -eq 0) { Write-Info 'No files found.' }
        foreach ($file in $files) {
            Write-Host ('  ' + (Get-RelativePath -FullName $file.FullName -Root $root)) -ForegroundColor $(if ($file.Extension -ieq '.ps1') { 'White' } else { 'Gray' })
        }
    }

    Show-Section 'FOLDER COUNTS'
    foreach ($folder in $topFolders) {
        $folderFiles = @(Get-ChildItem -LiteralPath $folder.FullName -File -Recurse -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\.git(\\|$)' })
        $folderScripts = @($folderFiles | Where-Object { $_.Extension -ieq '.ps1' })
        Show-Field $folder.Name ("{0} .ps1 / {1} files" -f $folderScripts.Count,$folderFiles.Count)
    }

    Show-Section 'SCRIPT TYPES'
    $patterns = [ordered]@{
        'GET-*'='^(?:\d+-)?GET-'; 'INVOKE-*'='^(?:\d+-)?INVOKE-'; 'SET-*'='^(?:\d+-)?SET-';
        'TEST-*'='^(?:\d+-)?TEST-'; 'INSTALL-*'='^(?:\d+-)?INSTALL-'; 'UPDATE-*'='^(?:\d+-)?UPDATE-';
        'RESET-*'='^(?:\d+-)?RESET-'; 'IR-*'='^(?:\d+-)?IR-'; 'TENANT-*'='^TENANT-'; 'RMM-*'='^RMM-'
    }
    foreach ($label in $patterns.Keys) {
        $count = @($scripts | Where-Object { $_.Name -match $patterns[$label] }).Count
        if ($count -gt 0) { Show-Field $label $count }
    }

    Show-Section 'SIGNATURES'
    if ($SkipSignatureCheck) {
        Write-Warn 'Signature check skipped.'
    } elseif ($scripts.Count -eq 0) {
        Write-Info 'No PowerShell scripts found.'
    } else {
        $valid = 0
        $notValid = New-Object System.Collections.ArrayList
        foreach ($file in $scripts) {
            try {
                $sig = Get-AuthenticodeSignature -LiteralPath $file.FullName -ErrorAction Stop
                if ($sig.Status -eq 'Valid') { $valid++ }
                else { [void]$notValid.Add([pscustomobject]@{File=(Get-RelativePath $file.FullName $root);Status=[string]$sig.Status}) }
            } catch {
                [void]$notValid.Add([pscustomobject]@{File=(Get-RelativePath $file.FullName $root);Status='Unknown'})
            }
        }
        Show-Field 'Valid' $valid 'Green'
        Show-Field 'Unsigned / invalid' $notValid.Count $(if ($notValid.Count -gt 0) { 'Yellow' } else { 'Green' })
        foreach ($item in $notValid) { Write-Host ("  {0} | {1}" -f $item.Status,$item.File) -ForegroundColor Yellow }
    }

    Write-Host ''
    Write-Ok 'Complete. No changes made.'
} catch {
    Write-Host ''
    Write-Fail $_.Exception.Message
} finally {
    Pause-End
}
