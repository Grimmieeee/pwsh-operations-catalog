<#
.VERSION 1.0.2
#>
# OBJECTIVE: Show the folder structure and files beneath a selected location.

<#
.SYNOPSIS
Read-only Jumpbox map reporter.

.DESCRIPTION
Maps a selected folder, usually C:\Field-Kit, without enforcing a fixed expected folder structure.

This is intentionally a reporter, not a validator.
It does not create, move, delete, rename, sign, export, or change files.
It reports folder counts, file map, script categories, signature status, and obvious cleanup/Git red flags.

Active name:
map-kit.ps1
#>

[CmdletBinding()]
param(
    [string]$RootPath,
    [int]$MaxDepth = 10,
    [switch]$FoldersOnly,
    [switch]$SkipSignatureCheck,
    [switch]$AutoAcceptRoot,
    [switch]$NoFileMap,
    [switch]$NoPause
)
Write-Host 'Map Folder Structure'
Write-Host 'Show the folder structure and files beneath a selected location.'


$ErrorActionPreference = "Stop"

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    if (-not $NoPause) {

    Write-Host 'SESSION COMPLETE'
    Write-Host ""
        Read-Host 'Press Enter to close session.' | Out-Null
    }
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host (" {0} " -f $Title) `
        -ForegroundColor White `
        -BackgroundColor DarkGray
}

function Field {
    param(
        [string]$Label,
        [object]$Value,
        [string]$Color = "White"
    )

    $left = "{0,-24}" -f $Label

    switch ($Color) {
        "Green"  { Write-Host "$left : " -NoNewline -ForegroundColor DarkGray; Write-Host $Value -ForegroundColor Green }
        "Yellow" { Write-Host "$left : " -NoNewline -ForegroundColor DarkGray; Write-Host $Value -ForegroundColor Yellow }
        "Red"    { Write-Host "$left : " -NoNewline -ForegroundColor DarkGray; Write-Host $Value -ForegroundColor Red }
        "Cyan"   { Write-Host "$left : " -NoNewline -ForegroundColor DarkGray; Write-Host $Value -ForegroundColor White }
        default  { Write-Host "$left : " -NoNewline -ForegroundColor DarkGray; Write-Host $Value }
    }
}

function Get-RelativePath {
    param(
        [string]$FullName,
        [string]$Root
    )

    return $FullName.Replace($Root, "").TrimStart("\")
}

function Test-UsefulRoot {
    param([string]$Path)

    if (-not $Path) {
        return $false
    }

    if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
        return $false
    }

    if ((Split-Path -Leaf $Path) -ieq "Field-Kit") {
        return $true
    }

    $markers = @(
        "README.md",
        ".git",
        "Documentation",
        "PWSH",
        "IR",
        "Identity",
        "Licensing",
        "Groups",
        "Mailbox",
        "Tenant",
        "Lifecycle",
        "Endpoint",
        "Utility"
    )

    foreach ($marker in $markers) {
        if (Test-Path -LiteralPath (Join-Path $Path $marker)) {
            return $true
        }
    }

    return $false
}

function Resolve-MapRoot {
    param([string]$InputRoot)

    if ($InputRoot) {
        if (-not (Test-Path -LiteralPath $InputRoot -PathType Container)) {
            throw "Root path not found: $InputRoot"
        }

        return (Get-Item -LiteralPath $InputRoot -ErrorAction Stop).FullName.TrimEnd("\")
    }

    $candidates = New-Object System.Collections.ArrayList

    if ($PSScriptRoot) {
        $cursor = $PSScriptRoot

        for ($i = 0; $i -lt 5 -and $cursor; $i++) {
            [void]$candidates.Add($cursor)
            $cursor = Split-Path -Path $cursor -Parent
        }
    }

    [void]$candidates.Add("C:\Field-Kit")

    try {
        $cursor = (Get-Location).Path

        for ($i = 0; $i -lt 4 -and $cursor; $i++) {
            [void]$candidates.Add($cursor)
            $cursor = Split-Path -Path $cursor -Parent
        }
    }
    catch {
    }

    foreach ($candidate in ($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-UsefulRoot -Path $candidate) {
            return (Get-Item -LiteralPath $candidate -ErrorAction Stop).FullName.TrimEnd("\")
        }
    }

    return $null
}

function Show-Tree {
    param(
        [string]$Path,
        [int]$Level,
        [int]$MaxDepth
    )

    if ($Level -ge $MaxDepth) {
        return
    }

    $indent = "  " * $Level

    $dirs = @(Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -ne ".git"
    } | Sort-Object Name)

    foreach ($dir in $dirs) {
        Write-Host "$indent[$($dir.Name)]" -ForegroundColor White
        Show-Tree -Path $dir.FullName -Level ($Level + 1) -MaxDepth $MaxDepth
    }

    if (-not $FoldersOnly) {
        $files = @(Get-ChildItem -LiteralPath $Path -File -ErrorAction SilentlyContinue | Sort-Object Name)

        foreach ($file in $files) {
            if ($file.Extension -eq ".ps1") {
                Write-Host "$indent$($file.Name)" -ForegroundColor White
            }
            elseif ($file.Extension -in @(".txt",".md",".json",".csv",".xlsx",".html",".cer")) {
                Write-Host "$indent$($file.Name)" -ForegroundColor Gray
            }
            else {
                Write-Host "$indent$($file.Name)" -ForegroundColor DarkGray
            }
        }
    }
}

function Get-TopLevelName {
    param(
        [string]$FullName,
        [string]$Root
    )

    $rel = Get-RelativePath -FullName $FullName -Root $Root
    if ([string]::IsNullOrWhiteSpace($rel)) { return "" }

    return ($rel -split "\\")[0]
}

function Add-RedFlag {
    param(
        [System.Collections.ArrayList]$List,
        [string]$Severity,
        [string]$Item,
        [string]$Reason
    )

    [void]$List.Add([pscustomobject]@{
        Severity = $Severity
        Item = $Item
        Reason = $Reason
    })
}

try {
    $resolvedRoot = Resolve-MapRoot -InputRoot $RootPath

    Section "JUMPBOX MAP REPORTER"
    Write-Host "Read-only reporter. No baseline enforcement. No changes made." -ForegroundColor Gray

    if ($resolvedRoot) {
        Write-Host ""
        Write-Host "Detected root:" -ForegroundColor Gray
        Write-Host $resolvedRoot -ForegroundColor White
    }

    if (-not $AutoAcceptRoot) {
        Write-Host ""
        Write-Host "[ENTER] Use detected root"
        Write-Host "[P]     Type a different path"
        Write-Host "[Q]     Quit"
        Write-Host "Or paste a full path directly"
        $rootChoice = (Read-Host "Choose").Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($rootChoice)) {
            # use detected root
        }
        elseif ($rootChoice -ieq "P") {
            $typed = (Read-Host "Root folder path").Trim().Trim('"')
            if ($typed -and (Test-Path -LiteralPath $typed)) {
                $resolvedRoot = (Get-Item -LiteralPath $typed).FullName.TrimEnd("\")
            }
            else {
                FAIL "Path not found: $typed"
                Pause-End
                return
            }
        }
        elseif ($rootChoice -ieq "Q") {
            INFO "Quit selected"
            Pause-End
            return
        }
        elseif (Test-Path -LiteralPath $rootChoice) {
            $resolvedRoot = (Get-Item -LiteralPath $rootChoice).FullName.TrimEnd("\")
        }
        else {
            FAIL "Invalid selection or path not found: $rootChoice"
            Pause-End
            return
        }
    }

    if (-not $resolvedRoot -or -not (Test-Path -LiteralPath $resolvedRoot)) {
        FAIL "Root folder not found"
        Pause-End
        return
    }

    $root = Get-Item -LiteralPath $resolvedRoot -ErrorAction Stop
    $rootPathClean = $root.FullName.TrimEnd("\")

    $actualTopFolders = @(Get-ChildItem -LiteralPath $rootPathClean -Directory -ErrorAction Stop | Where-Object {
        $_.Name -ne ".git"
    } | Sort-Object Name)

    $folders = @(Get-ChildItem -LiteralPath $rootPathClean -Directory -Recurse -ErrorAction Stop | Where-Object {
        $_.FullName -notmatch "\\\.git(\\|$)"
    } | Sort-Object FullName)

    $files = @(Get-ChildItem -LiteralPath $rootPathClean -File -Recurse -ErrorAction Stop | Where-Object {
        $_.FullName -notmatch "\\\.git(\\|$)"
    } | Sort-Object FullName)

    $ps1s = @($files | Where-Object { $_.Extension -ieq ".ps1" })

    Section "ROOT"
    Field "Root" $rootPathClean "White"
    Field "Operator" "$env:USERDOMAIN\$env:USERNAME" "White"
    Field "Generated" (Now) "White"
    Field "PowerShell" "$($PSVersionTable.PSVersion)" "White"
    Field "Mode" "Read-only reporter" "Green"

    Section "TOP-LEVEL FOLDERS"
    Field "Detected root folders" $actualTopFolders.Count "Cyan"

    foreach ($folder in $actualTopFolders) {
        Write-Host "  $($folder.Name)" -ForegroundColor White
    }

    Section "TREE"
    Write-Host "[$($root.Name)]" -ForegroundColor White
    Show-Tree -Path $rootPathClean -Level 1 -MaxDepth $MaxDepth

    Section "FILE MAP"

    if ($NoFileMap) {
        WARN "Skipped by -NoFileMap"
    }
    elseif ($files.Count -eq 0) {
        WARN "No files found"
    }
    else {
        foreach ($f in $files) {
            $rel = Get-RelativePath -FullName $f.FullName -Root $rootPathClean

            if ($f.Extension -ieq ".ps1") {
                Write-Host "  $rel" -ForegroundColor White
            }
            elseif ($f.Extension -in @(".log",".pfx",".p12",".key",".pem",".env")) {
                Write-Host "  $rel" -ForegroundColor Yellow
            }
            else {
                Write-Host "  $rel" -ForegroundColor Gray
            }
        }
    }

    Section "FOLDER COUNTS"

    foreach ($folder in $actualTopFolders) {
        $folderFiles = @(Get-ChildItem -LiteralPath $folder.FullName -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
            $_.FullName -notmatch "\\\.git(\\|$)"
        })
        $folderPs1s = @($folderFiles | Where-Object { $_.Extension -ieq ".ps1" })

        Field $folder.Name "$($folderPs1s.Count) .ps1 / $($folderFiles.Count) files" "White"
    }

    Section "SCRIPT CATEGORIES"

    $patterns = [ordered]@{
        "_STEP*"      = "_STEP*"
        "ir-*"        = "ir-*"
        "tenant-*"    = "tenant-*"
        "get-*"       = "get-*"
        "invoke-*"    = "invoke-*"
        "bulk-*"      = "bulk-*"
        "set-*"       = "set-*"
        "sign-*"      = "sign-*"
        "map-*"       = "map-*"
        "kit-*"       = "kit-*"
        "reset-*"     = "reset-*"
        "new-client*" = "new-client*"
        "hybrid-*"    = "hybrid-*"
        "shared-*"    = "shared-*"
    }

    $knownMatched = New-Object System.Collections.ArrayList

    foreach ($label in $patterns.Keys) {
        $matched = @($ps1s | Where-Object { $_.Name -like $patterns[$label] })
        $count = $matched.Count

        if ($count -gt 0) {
            Field $label $count "White"

            foreach ($p in $matched) {
                [void]$knownMatched.Add($p.FullName)
            }
        }
    }

    $otherCount = @($ps1s | Where-Object { $_.FullName -notin @($knownMatched) }).Count

    if ($otherCount -gt 0) {
        Field "other" $otherCount "Yellow"
    }

    Field "total .ps1" $ps1s.Count "Cyan"
    Field "total files" $files.Count "White"
    Field "total folders" $folders.Count "White"

    $invalid = New-Object System.Collections.ArrayList
    $valid = 0

    if (-not $SkipSignatureCheck) {
        Section "SIGNATURE CHECK"

        if ($ps1s.Count -eq 0) {
            WARN "No .ps1 files found"
        }
        else {
            foreach ($f in $ps1s) {
                try {
                    $sig = Get-AuthenticodeSignature -LiteralPath $f.FullName -ErrorAction Stop

                    if ($sig.Status -eq "Valid") {
                        $valid++
                    }
                    else {
                        [void]$invalid.Add([pscustomobject]@{
                            RelativePath = (Get-RelativePath -FullName $f.FullName -Root $rootPathClean)
                            Status = $sig.Status
                        })
                    }
                }
                catch {
                    [void]$invalid.Add([pscustomobject]@{
                        RelativePath = (Get-RelativePath -FullName $f.FullName -Root $rootPathClean)
                        Status = "Unknown"
                    })
                }
            }

            Field "Valid signatures" $valid "Green"

            if ($invalid.Count -gt 0) {
                Field "Invalid/unsigned" $invalid.Count "Yellow"
                Write-Host ""
                WARN "Unsigned or invalid scripts:"

                foreach ($i in $invalid) {
                    Write-Host "  $($i.Status) | $($i.RelativePath)" -ForegroundColor Yellow
                }
            }
            else {
                Field "Invalid/unsigned" 0 "Green"
                OK "All .ps1 files have valid signatures"
            }
        }
    }
    else {
        Section "SIGNATURE CHECK"
        WARN "Skipped by parameter"
    }

    Section "OBVIOUS RED FLAGS"

    $redFlags = New-Object System.Collections.ArrayList

    foreach ($i in $invalid) {
        Add-RedFlag -List $redFlags -Severity "WARN" -Item $i.RelativePath -Reason "PowerShell signature is $($i.Status). Sign it, archive it, or exclude it before Git/deployment."
    }

    $sensitiveFiles = @(
        $files |
        Where-Object {
            $_.Extension -in @(".pfx",".p12",".key",".pem",".env") -or
            (
                $_.Extension -notin @(".ps1",".md") -and
                $_.BaseName -match '(?i)(secret|password|token)'
            )
        }
    )

    foreach ($f in $sensitiveFiles) {
        $rel = Get-RelativePath -FullName $f.FullName -Root $rootPathClean
        Add-RedFlag -List $redFlags -Severity "HIGH" -Item $rel -Reason "Potential secret/private-key/token material. Do not commit unless explicitly intentional and safe."
    }

    foreach ($f in @($files | Where-Object { $_.Extension -ieq ".log" })) {
        $rel = Get-RelativePath -FullName $f.FullName -Root $rootPathClean
        Add-RedFlag -List $redFlags -Severity "WARN" -Item $rel -Reason "Log file. Review for sensitive output and normally exclude from Git."
    }

    foreach ($f in @($files | Where-Object { $_.Name -match "\.bak|\.old|\.tmp|\.disabled|\.broken" })) {
        $rel = Get-RelativePath -FullName $f.FullName -Root $rootPathClean
        Add-RedFlag -List $redFlags -Severity "INFO" -Item $rel -Reason "Backup/temp/disabled file. Usually archive or exclude from active deployment."
    }

    foreach ($f in @($files | Where-Object {
        $_.Extension -ieq ".ps1" -and
        $_.FullName -notmatch "\\ARCHIVE\\|\\Archive\\|\\TESTING\\|\\Testing\\" -and
        $_.Name -match "^(final-|in-prog-|NO-|no-|noo-|OK-|ok-|YES-|WORKS-|GOOD-)"
    })) {
        $rel = Get-RelativePath -FullName $f.FullName -Root $rootPathClean
        Add-RedFlag -List $redFlags -Severity "INFO" -Item $rel -Reason "Active script name still looks like iteration/test naming. Keep only if intentional."
    }

    foreach ($f in @($files | Where-Object {
        $_.Extension -ieq ".ps1" -and
        (Get-RelativePath -FullName $_.FullName -Root $rootPathClean) -notmatch "\\" -and
        $true
    })) {
        $rel = Get-RelativePath -FullName $f.FullName -Root $rootPathClean
        Add-RedFlag -List $redFlags -Severity "INFO" -Item $rel -Reason "PowerShell script is sitting at the selected root. Confirm this is intentional."
    }

    $archiveFolder = @($actualTopFolders | Where-Object { $_.Name -ieq "Archive" -or $_.Name -ieq "_Archive" } | Select-Object -First 1)
    if ($archiveFolder) {
        $archiveFiles = @(Get-ChildItem -LiteralPath $archiveFolder.FullName -File -Recurse -ErrorAction SilentlyContinue)
        Add-RedFlag -List $redFlags -Severity "INFO" -Item $archiveFolder.Name -Reason "Archive contains $($archiveFiles.Count) files. Good for history, but normally exclude from Git/deployment."
    }

    if ($redFlags.Count -eq 0) {
        OK "No obvious red flags found by reporter rules"
    }
    else {
        foreach ($flag in $redFlags) {
            if ($flag.Severity -eq "HIGH") {
                Write-Host "[HIGH] $($flag.Item)" -ForegroundColor Red
            }
            elseif ($flag.Severity -eq "WARN") {
                Write-Host "[WARN] $($flag.Item)" -ForegroundColor Yellow
            }
            else {
                Write-Host "[INFO] $($flag.Item)" -ForegroundColor White
            }

            Write-Host "       $($flag.Reason)" -ForegroundColor Gray
        }
    }

    Section "SUMMARY"
    Field "Root" $rootPathClean "White"
    Field "Root folders" $actualTopFolders.Count "White"
    Field "Nested folders" $folders.Count "White"
    Field "Files" $files.Count "White"
    Field "PowerShell files" $ps1s.Count "Cyan"
    Field "Invalid/unsigned" $invalid.Count $(if ($invalid.Count -gt 0) { "Yellow" } else { "Green" })
    Field "Red flags" $redFlags.Count $(if ($redFlags.Count -gt 0) { "Yellow" } else { "Green" })
    Field "Max depth" $MaxDepth "White"
    Field "Folders only" $FoldersOnly "White"
    Field "Completed" (Now) "White"

    Write-Host ""
    OK "Complete. No changes made"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
