<#PSScriptInfo
.VERSION 0.1.0
.GUID 31b0a19f-81e9-9734-d471-941254290308
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
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

function Write-Ok {
    param([string]$Message)
    Write-Host '[OK] ' -ForegroundColor Green -NoNewline
    Write-Host $Message
}
function Write-Info {
    param([string]$Message)
    Write-Host '[INFO] ' -NoNewline
    Write-Host $Message
}
function Write-Warn {
    param([string]$Message)
    $script:FKHasIssue = $true
    Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}
function Write-Fail {
    param([string]$Message)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $Message
}
function Show-Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
}
function Pause-End {
    Close-FKConsole -SkipPause ([bool]$NoPause)
}

function Confirm-Type {
    param([string]$Required)
    $answer = Read-Host "Type $Required to continue"
    return (-not [string]::IsNullOrWhiteSpace($answer) -and $answer.Trim().ToUpperInvariant() -eq $Required)
}

try {
    Write-FKStart -Title 'WINDOWS APP UPDATES' -Objective 'Shows available app updates and installs them after confirmation.' -Mode 'MAKES CHANGES'
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
