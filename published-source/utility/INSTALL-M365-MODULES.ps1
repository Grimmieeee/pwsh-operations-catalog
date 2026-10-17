<#PSScriptInfo
.VERSION 0.1.0
.GUID c8b18e55-67ac-71b7-9932-959c4b1c743d
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
#Requires -Version 5.1

<#
.SYNOPSIS
Install or update Microsoft 365 PowerShell modules for the current user.

.DESCRIPTION
Installs Microsoft Graph, Exchange Online Management, or both from PSGallery.
Uses CurrentUser scope and does not connect to a tenant.
#>

[CmdletBinding()]
param(
    [ValidateSet('Graph','Exchange','Both')]
    [string]$ModuleSet,
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

function Get-LatestModule {
    param([string]$Name)
    return Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1
}

try {
    Write-FKStart -Title 'M365 MODULE SETUP' -Objective 'Installs or updates the Graph and Exchange PowerShell modules you choose.' -Mode 'MAKES CHANGES'
    Write-Host 'Installs or updates PowerShell modules for the current user.'
    Write-Host 'No tenant connection is made.'

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    if (-not (Get-Command Install-Module -ErrorAction SilentlyContinue)) {
        throw 'Install-Module is unavailable. Install or repair PowerShellGet first.'
    }

    if (-not $ModuleSet) {
        Write-Host ''
        Write-Host '[1] Microsoft Graph'
        Write-Host '[2] Exchange Online'
        Write-Host '[3] Both'
        switch ((Read-Host 'Choose').Trim()) {
            '1' { $ModuleSet = 'Graph' }
            '2' { $ModuleSet = 'Exchange' }
            '3' { $ModuleSet = 'Both' }
            default { throw 'Invalid selection.' }
        }
    }

    $targets = New-Object System.Collections.ArrayList
    if ($ModuleSet -in @('Graph','Both')) { [void]$targets.Add('Microsoft.Graph') }
    if ($ModuleSet -in @('Exchange','Both')) { [void]$targets.Add('ExchangeOnlineManagement') }

    Show-Section 'PLAN'
    foreach ($name in $targets) {
        $installed = Get-LatestModule -Name $name
        if ($installed) { Write-Info "$name currently installed: $($installed.Version)" }
        else { Write-Info "$name currently installed: No" }
    }
    Write-Warn 'This changes modules installed in your CurrentUser PowerShell scope.'

    if (-not (Confirm-Type -Required 'INSTALL')) {
        Write-Warn 'Cancelled. No modules changed.'
        return
    }

    Show-Section 'INSTALL / UPDATE'
    foreach ($name in $targets) {
        Write-Info "Installing or updating $name..."
        Install-Module -Name $name -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -ErrorAction Stop
        $installed = Get-LatestModule -Name $name
        if ($installed) { Write-Ok "$name $($installed.Version)" }
        else { throw "$name installation completed but the module could not be found afterward." }
    }

    Show-Section 'SUMMARY'
    Write-Ok 'M365 module setup complete.'
    Write-Info 'Open a fresh PowerShell window before troubleshooting loaded-module version conflicts.'
} catch {
    Write-Host ''
    Write-Fail $_.Exception.Message
} finally {
    Pause-End
}
