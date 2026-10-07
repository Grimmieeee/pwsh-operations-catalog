#Requires -Version 5.1

<#
.SYNOPSIS
Review and install normal WinGet application updates.

.DESCRIPTION
Shows available WinGet upgrades, asks for typed confirmation, applies normally
eligible updates, then shows anything still remaining. Does not force pinned or
unknown-version packages.
#>

[CmdletBinding()]
param(
    [switch]$ReviewOnly,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

function Write-Ok   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }
function Show-Section { param([string]$Title) Write-Host ''; Write-Host (" {0} " -f $Title) -ForegroundColor White -BackgroundColor DarkGray }
function Pause-End { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to EXIT' | Out-Null } }

function Confirm-Type {
    param([string]$Required)
    $answer = Read-Host "Type $Required to continue"
    return (-not [string]::IsNullOrWhiteSpace($answer) -and $answer.Trim().ToUpperInvariant() -eq $Required)
}

try {
    Write-Host 'WINDOWS APP UPDATES'
    Write-Host 'Uses WinGet to review and update installed applications.'

    $wingetCommand = Get-Command winget -ErrorAction Stop
    $winget = if ($wingetCommand.Source) { $wingetCommand.Source } else { 'winget' }

    Show-Section 'AVAILABLE UPDATES'
    & $winget upgrade --accept-source-agreements
    if ($LASTEXITCODE -ne 0) { throw "WinGet review failed with exit code $LASTEXITCODE." }

    if ($ReviewOnly) {
        Write-Host ''
        Write-Ok 'Review complete. No updates installed.'
        return
    }

    Write-Host ''
    Write-Warn 'This will attempt to update all normally eligible WinGet packages.'
    if (-not (Confirm-Type -Required 'UPDATE')) {
        Write-Warn 'Cancelled. No updates installed.'
        return
    }

    Show-Section 'UPDATE'
    & $winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --disable-interactivity
    $updateExit = $LASTEXITCODE
    if ($updateExit -eq 0) { Write-Ok 'WinGet update command completed.' }
    else { Write-Warn "WinGet completed with exit code $updateExit." }

    Show-Section 'REMAINING UPDATES'
    & $winget upgrade --accept-source-agreements
    $verifyExit = $LASTEXITCODE
    if ($verifyExit -eq 0) { Write-Ok 'Post-update review completed.' }
    else { Write-Warn "Post-update review returned exit code $verifyExit." }

    Show-Section 'SUMMARY'
    Write-Info "Update command exit: $updateExit"
    Write-Info "Review command exit: $verifyExit"
    if ($updateExit -eq 0) { Write-Ok 'Windows app update pass complete.' }
    else { Write-Warn 'Review the WinGet output above for packages that did not update.' }
} catch {
    Write-Host ''
    Write-Fail $_.Exception.Message
} finally {
    Pause-End
}
