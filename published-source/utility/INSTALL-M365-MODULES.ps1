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

function Get-LatestModule {
    param([string]$Name)
    return Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1
}

try {
    Write-Host 'M365 MODULE SETUP'
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
