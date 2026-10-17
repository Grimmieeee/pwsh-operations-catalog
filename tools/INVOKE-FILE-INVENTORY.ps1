<#PSScriptInfo
.VERSION 0.1.0
.GUID 57460d80-0182-1add-68dc-77e561176276
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
#Requires -Version 5.1

<#
JUMPBOX FILE INVENTORY

OBJECTIVE
Read-only inventory and version-sanity review for the current Jumpbox tree.

REVIEWS
- Active / Testing / Archive PowerShell counts
- Newest active scripts
- Active-script Authenticode signature status
- Duplicate active filenames and hash differences
- Backup / iteration naming left in active folders
- Root-level PowerShell scripts
- Optional CSV export

DEFAULT ROOT
C:\Field-Kit

SAFETY
No toolkit changes are made.
CSV export is optional.
#>

param(
    [string]$RootPath = "C:\Field-Kit",
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"


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
function FAIL {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}

function Pause-End {
    Close-FKConsole -SkipPause ([bool]$NoPause)
}

function Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
}

function ShortHash {
    param([string]$Hash)

    if ([string]::IsNullOrWhiteSpace($Hash)) {
        return ""
    }

    if ($Hash.Length -le 12) {
        return $Hash
    }

    return $Hash.Substring(0,12)
}

function Get-RelativePath {
    param(
        [string]$FullName,
        [string]$Root
    )

    $rootClean = $Root.TrimEnd("\")

    if (
        $FullName.StartsWith(
            $rootClean,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {
        return $FullName.Substring($rootClean.Length).TrimStart("\")
    }

    return $FullName
}

function Get-Scope {
    param(
        [string]$FullName,
        [string]$Root
    )

    $relative = Get-RelativePath -FullName $FullName -Root $Root

    if ($relative -match '^(?i:Archive)\\') {
        return "Archive"
    }

    if ($relative -match '^(?i:Testing)\\') {
        return "Testing"
    }

    return "Active"
}

try {
    Write-FKStart -Title 'JUMPBOX FILE INVENTORY' -Objective 'Find duplicate scripts, signature problems, and leftover working copies.' -Mode ''
    Write-Host "READ-ONLY VERSION SANITY REVIEW"
    Write-Host ""

    $typedRoot = Read-Host "Working root [$RootPath]"

    if (-not [string]::IsNullOrWhiteSpace($typedRoot)) {
        $RootPath = $typedRoot.Trim().Trim('"').Trim("'")
    }

    if (-not (Test-Path -LiteralPath $RootPath -PathType Container)) {
        throw "Root not found: $RootPath"
    }

    $root = (Get-Item -LiteralPath $RootPath -ErrorAction Stop).FullName.TrimEnd("\")
    $generated = Get-Date

    Section "ROOT"

    INFO "Working root : $root"
    INFO "Operator     : $env:USERDOMAIN\$env:USERNAME"
    INFO "Generated    : $($generated.ToString('yyyy-MM-dd HH:mm:ss'))"

    Section "INVENTORY"

    $allPs1 = @(
        Get-ChildItem `
            -LiteralPath $root `
            -Filter "*.ps1" `
            -File `
            -Recurse `
            -ErrorAction Stop
    )

    $inventoryRows = foreach ($file in $allPs1) {
        [PSCustomObject]@{
            Scope        = Get-Scope -FullName $file.FullName -Root $root
            File         = $file.Name
            RelativePath = Get-RelativePath -FullName $file.FullName -Root $root
            Modified     = $file.LastWriteTime
            Length       = $file.Length
            FullName     = $file.FullName
        }
    }

    $active = @($inventoryRows | Where-Object { $_.Scope -eq "Active" })
    $testing = @($inventoryRows | Where-Object { $_.Scope -eq "Testing" })
    $archive = @($inventoryRows | Where-Object { $_.Scope -eq "Archive" })

    INFO "Active .ps1  : $($active.Count)"
    INFO "Testing .ps1 : $($testing.Count)"
    INFO "Archive .ps1 : $($archive.Count)"
    INFO "Total .ps1   : $($inventoryRows.Count)"

    Section "NEWEST ACTIVE SCRIPTS"

    if ($active.Count -eq 0) {
        WARN "No active PowerShell scripts found"
    }
    else {
        $active |
            Sort-Object Modified -Descending |
            Select-Object -First 20 `
                @{n='Modified';e={$_.Modified.ToString('yyyy-MM-dd HH:mm:ss')}},
                File,
                RelativePath |
            Format-Table -AutoSize
    }

    Section "ACTIVE SIGNATURE STATUS"

    $signatureRows = @()
    $signatureGaps = @()

    foreach ($row in $active) {
        try {
            $sig = Get-AuthenticodeSignature `
                -LiteralPath $row.FullName `
                -ErrorAction Stop

            $signatureRows += [PSCustomObject]@{
                File         = $row.File
                RelativePath = $row.RelativePath
                Status       = [string]$sig.Status
                Signer       = if ($sig.SignerCertificate) {
                    [string]$sig.SignerCertificate.Subject
                }
                else {
                    ""
                }
            }
        }
        catch {
            $signatureGaps += [PSCustomObject]@{
                File         = $row.File
                RelativePath = $row.RelativePath
                Error        = $_.Exception.Message
            }
        }
    }

    $invalidSignatures = @(
        $signatureRows |
        Where-Object { $_.Status -ne "Valid" }
    )

    if ($signatureGaps.Count -gt 0) {
        WARN "Signature review incomplete for $($signatureGaps.Count) active script(s)"
    }

    if ($invalidSignatures.Count -eq 0 -and $signatureGaps.Count -eq 0) {
        OK "All active scripts have valid signatures"
    }
    elseif ($invalidSignatures.Count -gt 0) {
        WARN "$($invalidSignatures.Count) active script(s) are unsigned or invalid"

        $invalidSignatures |
            Sort-Object RelativePath |
            Select-Object Status, RelativePath |
            Format-Table -AutoSize
    }

    Section "DUPLICATE ACTIVE FILENAMES"

    $duplicateRows = @()

    foreach ($group in ($active | Group-Object File | Where-Object { $_.Count -gt 1 })) {
        $items = @($group.Group)
        $hashes = @()

        foreach ($item in $items) {
            $hash = Get-FileHash `
                -LiteralPath $item.FullName `
                -Algorithm SHA256 `
                -ErrorAction Stop

            $hashes += [PSCustomObject]@{
                File         = $item.File
                RelativePath = $item.RelativePath
                Hash         = $hash.Hash
            }
        }

        $uniqueHashes = @($hashes.Hash | Sort-Object -Unique)
        $status = if ($uniqueHashes.Count -eq 1) {
            "SAME HASH"
        }
        else {
            "HASH DIFF"
        }

        foreach ($hashRow in $hashes) {
            $duplicateRows += [PSCustomObject]@{
                Status       = $status
                File         = $hashRow.File
                RelativePath = $hashRow.RelativePath
                Hash         = ShortHash $hashRow.Hash
            }
        }
    }

    if ($duplicateRows.Count -eq 0) {
        OK "No duplicate active filenames found"
    }
    else {
        WARN "Duplicate active filenames found"

        $duplicateRows |
            Sort-Object File,RelativePath |
            Format-Table Status,File,Hash,RelativePath -AutoSize
    }

    Section "ACTIVE CLEANUP FLAGS"

    $cleanupRows = @()

    foreach ($row in $active) {
        $reason = $null

        if (
            $row.File -match '\([0-9]+\)\.ps1$' -or
            $row.File -match '(?i)\.(bak|old|tmp|disabled|broken)\b' -or
            $row.File -match '^(?i:final-|in-prog-|NO-|noo-|OK-|YES-|WORKS-|GOOD-)'
        ) {
            $reason = "Iteration / backup-style filename"
        }
        elseif ($row.RelativePath -notmatch "\\") {
            $reason = "PowerShell script at Jumpbox root"
        }

        if ($reason) {
            $cleanupRows += [PSCustomObject]@{
                File         = $row.File
                RelativePath = $row.RelativePath
                Reason       = $reason
            }
        }
    }

    if ($cleanupRows.Count -eq 0) {
        OK "No obvious active cleanup flags found"
    }
    else {
        WARN "$($cleanupRows.Count) active cleanup flag(s) found"

        $cleanupRows |
            Sort-Object Reason,RelativePath |
            Format-Table File,Reason,RelativePath -AutoSize
    }

    Section "SUMMARY"

    $verdict = "OK"

    if (
        $invalidSignatures.Count -gt 0 -or
        $signatureGaps.Count -gt 0 -or
        $duplicateRows.Count -gt 0 -or
        $cleanupRows.Count -gt 0
    ) {
        $verdict = "REVIEW"
    }

    Write-Host ("Verdict            : {0}" -f $verdict)
    INFO "Invalid signatures : $($invalidSignatures.Count)"
    INFO "Signature gaps     : $($signatureGaps.Count)"
    INFO "Duplicate rows     : $($duplicateRows.Count)"
    INFO "Cleanup flags      : $($cleanupRows.Count)"

    Write-Host ""
    $export = Read-Host "Export inventory CSVs [Y/N]"

    if ($export -match '^(?i:Y)$') {
        $desktop = [Environment]::GetFolderPath("Desktop")

        if ([string]::IsNullOrWhiteSpace($desktop)) {
            $desktop = Join-Path $env:USERPROFILE "Desktop"
        }

        $outputFolder = Read-Host "Output folder [Enter for Desktop]"

        if ([string]::IsNullOrWhiteSpace($outputFolder)) {
            $outputFolder = $desktop
        }
        else {
            $outputFolder = $outputFolder.Trim().Trim('"').Trim("'")
        }

        if (-not (Test-Path -LiteralPath $outputFolder -PathType Container)) {
            throw "Output folder not found: $outputFolder"
        }

        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"

        $inventoryRows |
            Select-Object Scope,File,RelativePath,Modified,Length |
            Export-Csv `
                -LiteralPath (Join-Path $outputFolder "jumpbox-file-inventory-$stamp.csv") `
                -NoTypeInformation `
                -Encoding UTF8 `
                -ErrorAction Stop

        $signatureRows |
            Export-Csv `
                -LiteralPath (Join-Path $outputFolder "jumpbox-signatures-$stamp.csv") `
                -NoTypeInformation `
                -Encoding UTF8 `
                -ErrorAction Stop

        $duplicateRows |
            Export-Csv `
                -LiteralPath (Join-Path $outputFolder "jumpbox-duplicates-$stamp.csv") `
                -NoTypeInformation `
                -Encoding UTF8 `
                -ErrorAction Stop

        $cleanupRows |
            Export-Csv `
                -LiteralPath (Join-Path $outputFolder "jumpbox-cleanup-flags-$stamp.csv") `
                -NoTypeInformation `
                -Encoding UTF8 `
                -ErrorAction Stop

        OK "Inventory CSVs exported to $outputFolder"
    }

    Write-Host ""
    OK "Complete. No toolkit changes made"
}
catch {
    Write-Host ""
    FAIL $_.Exception.Message
}
finally {
    Pause-End
}
