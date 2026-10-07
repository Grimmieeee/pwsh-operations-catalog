#Requires -Version 5.1

<#
.SYNOPSIS
Read-only PowerShell workstation readiness check.

.DESCRIPTION
Checks the local shell and common MSP PowerShell prerequisites without changing
anything. Reviews PowerShell, execution policy, elevation, Git, WinGet,
PowerShellGet, Microsoft Graph, Exchange Online, optional AD tooling, and active
Microsoft 365 sessions.
#>

[CmdletBinding()]
param([switch]$NoPause)

$ErrorActionPreference = 'Stop'
$script:Ok = 0
$script:Warn = 0
$script:Fail = 0

function Write-Ok   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green; $script:Ok++ }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow; $script:Warn++ }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red; $script:Fail++ }
function Show-Section { param([string]$Title) Write-Host ''; Write-Host (" {0} " -f $Title) -ForegroundColor White -BackgroundColor DarkGray }
function Pause-End { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to EXIT' | Out-Null } }

function Get-LatestModule {
    param([string]$Name)
    return Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending | Select-Object -First 1
}

try {
    Write-Host 'POWERSHELL READINESS CHECK'
    Write-Host 'READ ONLY. No settings or modules are changed.'

    Show-Section 'POWERSHELL'
    $version = $PSVersionTable.PSVersion
    if ($version.Major -ge 7) { Write-Ok "PowerShell $version" }
    elseif ($version.Major -eq 5 -and $version.Minor -ge 1) { Write-Ok "Windows PowerShell $version"; Write-Info 'PowerShell 7 is optional but useful for newer modules.' }
    else { Write-Fail "PowerShell $version is below the supported baseline." }

    $policy = Get-ExecutionPolicy -ErrorAction SilentlyContinue
    $userPolicy = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue
    Write-Info "Effective execution policy: $policy"
    Write-Info "CurrentUser policy: $userPolicy"
    if ($policy -in @('RemoteSigned','AllSigned','Bypass','Unrestricted')) { Write-Ok 'Execution policy permits normal script use.' }
    else { Write-Warn 'Execution policy may block locally downloaded scripts.' }

    if ($PSVersionTable.PSVersion.Major -lt 7) {
        $tls12 = ([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) -ne 0
        if ($tls12) { Write-Ok 'TLS 1.2 is enabled for this process.' }
        else { Write-Warn 'TLS 1.2 is not currently enabled for this Windows PowerShell process.' }
    }

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) { Write-Info 'Shell is elevated (Administrator).' } else { Write-Info 'Shell is not elevated.' }

    Show-Section 'LOCAL TOOLS'
    foreach ($tool in @('git','winget')) {
        $cmd = Get-Command $tool -ErrorAction SilentlyContinue
        if ($cmd) { Write-Ok "$tool available - $($cmd.Source)" }
        else { Write-Warn "$tool not found" }
    }

    if (Get-Command Install-Module -ErrorAction SilentlyContinue) { Write-Ok 'Install-Module available.' }
    else { Write-Fail 'Install-Module is unavailable.' }

    $psGet = Get-LatestModule -Name 'PowerShellGet'
    if ($psGet) { Write-Info "PowerShellGet $($psGet.Version)" } else { Write-Warn 'PowerShellGet not found.' }

    try {
        $gallery = Get-PSRepository -Name PSGallery -ErrorAction Stop
        Write-Info "PSGallery policy: $($gallery.InstallationPolicy)"
    } catch {
        Write-Warn 'PSGallery is not registered or could not be read.'
    }

    Show-Section 'MICROSOFT 365 MODULES'
    foreach ($moduleName in @('Microsoft.Graph.Authentication','ExchangeOnlineManagement')) {
        $module = Get-LatestModule -Name $moduleName
        if ($module) { Write-Ok "$moduleName $($module.Version)" }
        else { Write-Warn "$moduleName not installed" }
    }

    $ad = Get-LatestModule -Name 'ActiveDirectory'
    if ($ad) { Write-Info "ActiveDirectory $($ad.Version)" } else { Write-Info 'ActiveDirectory module not installed (optional).' }

    Show-Section 'ACTIVE M365 SESSIONS'
    if (Get-Command Get-MgContext -ErrorAction SilentlyContinue) {
        try {
            $ctx = Get-MgContext -ErrorAction Stop
            if ($ctx) { Write-Info "Graph: connected as $($ctx.Account)" } else { Write-Info 'Graph: not connected' }
        } catch { Write-Warn 'Graph session state could not be read.' }
    } else { Write-Info 'Graph session: module not loaded' }

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        try {
            $exo = Get-ConnectionInformation -ErrorAction Stop | Select-Object -First 1
            if ($exo) {
                $target = if ($exo.Organization) { $exo.Organization } elseif ($exo.DelegatedOrganization) { $exo.DelegatedOrganization } else { 'connected tenant' }
                Write-Info "Exchange Online: connected to $target"
            } else { Write-Info 'Exchange Online: not connected' }
        } catch { Write-Warn 'Exchange Online session state could not be read.' }
    } else { Write-Info 'Exchange Online session: module not loaded' }

    Show-Section 'SUMMARY'
    $result = if ($script:Fail -gt 0) { 'NOT READY' } elseif ($script:Warn -gt 0) { 'READY WITH WARNINGS' } else { 'READY' }
    Write-Host "Result   : $result"
    Write-Host "OK       : $script:Ok"
    Write-Host "Warnings : $script:Warn"
    Write-Host "Failures : $script:Fail"
    Write-Host ''
    Write-Ok 'Readiness check complete.'
} catch {
    Write-Host ''
    Write-Fail $_.Exception.Message
} finally {
    Pause-End
}
