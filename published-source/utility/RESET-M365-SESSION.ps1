#Requires -Version 5.1

<#
.SYNOPSIS
Reset local Microsoft 365 PowerShell sessions.

.DESCRIPTION
Disconnects Exchange Online and Microsoft Graph, removes legacy Exchange-related
PSSessions, clears the current PowerShell error buffer, and can optionally open a
fresh PowerShell 7 window. No tenant configuration is changed.
#>

[CmdletBinding()]
param(
    [switch]$NoNewWindow,
    [switch]$NoPause
)

$ErrorActionPreference = 'Stop'

function Write-Ok   { param([string]$Message) Write-Host "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" }
function Write-Warn { param([string]$Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[FAIL] $Message" -ForegroundColor Red }
function Show-Section { param([string]$Title) Write-Host ''; Write-Host (" {0} " -f $Title) -ForegroundColor White -BackgroundColor DarkGray }
function Pause-End { if (-not $NoPause) { Write-Host ''; Read-Host 'Press Enter to EXIT' | Out-Null } }

function Confirm-Yes {
    param([string]$Prompt)
    $answer = Read-Host "$Prompt [Y/N]"
    return (-not [string]::IsNullOrWhiteSpace($answer) -and $answer.Trim().ToUpperInvariant() -eq 'Y')
}

function Get-ShortError {
    param($ErrorRecord)
    $message = $ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) { $message = [string]$ErrorRecord }
    return (($message -replace '\s+',' ').Trim())
}

function Start-FreshPowerShell {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
    if ($pwsh -and (Test-Path -LiteralPath $pwsh -PathType Leaf)) {
        Start-Process -FilePath $pwsh -ArgumentList '-NoLogo' -ErrorAction Stop
        Write-Ok 'Fresh PowerShell 7 window launched.'
    } else {
        Write-Warn 'PowerShell 7 was not found. No new window was launched.'
    }
}

try {
    Write-Host 'M365 SESSION RESET'
    Write-Host 'LOCAL SESSION CLEANUP. No tenant configuration is changed.'

    Show-Section 'PLAN'
    Write-Host '- Disconnect Exchange Online'
    Write-Host '- Disconnect Microsoft Graph'
    Write-Host '- Remove legacy Exchange-related PSSessions'
    Write-Host '- Clear the current PowerShell error buffer'
    if (-not $NoNewWindow) { Write-Host '- Optional: launch a fresh PowerShell 7 window' }

    if (-not (Confirm-Yes 'Run session reset now')) {
        Write-Warn 'Cancelled.'
        return
    }

    Show-Section 'EXCHANGE ONLINE'
    if (Get-Command Disconnect-ExchangeOnline -ErrorAction SilentlyContinue) {
        try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction Stop | Out-Null; Write-Ok 'Exchange Online disconnected.' }
        catch { Write-Warn ("Exchange disconnect: {0}" -f (Get-ShortError $_)) }
    } else { Write-Info 'Disconnect-ExchangeOnline unavailable.' }

    try {
        $sessions = @(Get-PSSession -ErrorAction Stop | Where-Object {
            $_.ConfigurationName -match '(?i)Exchange' -or $_.ComputerName -match '(?i)(outlook|office365|exchange)'
        })
        foreach ($session in $sessions) { Remove-PSSession -Session $session -ErrorAction Stop }
        if ($sessions.Count -gt 0) { Write-Ok "Legacy Exchange PSSessions cleared: $($sessions.Count)" }
        else { Write-Info 'Legacy Exchange PSSessions: none' }
    } catch { Write-Warn ("Legacy Exchange session cleanup: {0}" -f (Get-ShortError $_)) }

    Show-Section 'MICROSOFT GRAPH'
    if (Get-Command Disconnect-MgGraph -ErrorAction SilentlyContinue) {
        try { Disconnect-MgGraph -ErrorAction Stop | Out-Null; Write-Ok 'Microsoft Graph disconnected.' }
        catch { Write-Warn ("Graph disconnect: {0}" -f (Get-ShortError $_)) }
    } else { Write-Info 'Disconnect-MgGraph unavailable.' }

    Show-Section 'LOCAL SHELL'
    try { $Error.Clear(); Write-Ok 'PowerShell error buffer cleared.' }
    catch { Write-Warn ("Error buffer cleanup: {0}" -f (Get-ShortError $_)) }

    if (-not $NoNewWindow -and (Confirm-Yes 'Launch a fresh PowerShell 7 window')) {
        Start-FreshPowerShell
    }

    Show-Section 'SUMMARY'
    Write-Ok 'M365 session reset complete.'
} catch {
    Write-Host ''
    Write-Fail (Get-ShortError $_)
} finally {
    Pause-End
}
