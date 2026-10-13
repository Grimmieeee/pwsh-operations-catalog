#Requires -Version 5.1

<#
JUMPBOX SESSION RESET

OBJECTIVE
Reset local Microsoft 365 PowerShell authentication state.

ACTIONS
- Disconnect Exchange Online
- Disconnect Microsoft Graph
- Remove legacy Exchange-related PSSessions only
- Clear the current PowerShell error buffer
- Optionally reset the Jumpbox session password variable
- Optionally launch a fresh PowerShell 7 window

SAFETY
Local session cleanup only.
No tenant configuration is changed.
Unrelated PowerShell remoting sessions and arbitrary global variables are not removed.
#>

param(
    [switch]$NoNewWindow,
    [switch]$ClearVariables
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to EXIT" | Out-Null
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host (" {0} " -f $Title) `
        -ForegroundColor White `
        -BackgroundColor DarkGray
}

function Confirm-Yes {
    param([string]$Prompt)

    $answer = Read-Host "$Prompt [Y/N]"

    return (
        -not [string]::IsNullOrWhiteSpace($answer) -and
        $answer.Trim().ToUpperInvariant() -eq "Y"
    )
}

function Get-ShortError {
    param($ErrorRecord)

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Start-FreshShell {
    $pwsh = $null

    try {
        $pwsh = Get-Command pwsh -ErrorAction Stop |
            Select-Object -ExpandProperty Source -First 1
    }
    catch {
    }

    if (
        -not $pwsh -and
        (Test-Path -LiteralPath "C:\Program Files\PowerShell\7\pwsh.exe")
    ) {
        $pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
    }

    if ($pwsh -and (Test-Path -LiteralPath $pwsh -PathType Leaf)) {
        Start-Process `
            -FilePath $pwsh `
            -ArgumentList "-NoLogo" `
            -ErrorAction Stop

        OK "New PowerShell 7 window launched"
        return
    }

    WARN "PowerShell 7 was not found. No new window was launched."
}

try {
    Write-Host "JUMPBOX SESSION RESET"
    Write-Host "LOCAL SESSION CLEANUP"
    Write-Host ""

    Section "PLAN"

    Write-Host "- Disconnect Exchange Online"
    Write-Host "- Disconnect Microsoft Graph"
    Write-Host "- Remove legacy Exchange-related PSSessions only"
    Write-Host "- Clear PowerShell error buffer"
    Write-Host "- Optional: reset current Jumpbox session password"
    Write-Host "- Optional: launch fresh PowerShell 7 window"

    if (-not (Confirm-Yes "Run session reset now")) {
        WARN "Cancelled"
        return
    }

    Section "EXCHANGE ONLINE"

    if (Get-Command Disconnect-ExchangeOnline -ErrorAction SilentlyContinue) {
        try {
            Disconnect-ExchangeOnline `
                -Confirm:$false `
                -ErrorAction Stop |
                Out-Null

            OK "Exchange Online disconnected"
        }
        catch {
            WARN ("Exchange disconnect: {0}" -f (Get-ShortError $_))
        }
    }
    else {
        INFO "Disconnect-ExchangeOnline unavailable"
    }

    try {
        $exchangeSessions = @(
            Get-PSSession -ErrorAction Stop |
            Where-Object {
                $_.ConfigurationName -match '(?i)Exchange' -or
                $_.ComputerName -match '(?i)(outlook|office365|exchange)'
            }
        )

        foreach ($sessionItem in $exchangeSessions) {
            Remove-PSSession `
                -Session $sessionItem `
                -ErrorAction Stop
        }

        if ($exchangeSessions.Count -gt 0) {
            OK "Legacy Exchange PSSessions cleared: $($exchangeSessions.Count)"
        }
        else {
            INFO "Legacy Exchange PSSessions: none"
        }
    }
    catch {
        WARN ("Legacy Exchange session cleanup: {0}" -f (Get-ShortError $_))
    }

    Section "MICROSOFT GRAPH"

    if (Get-Command Disconnect-MgGraph -ErrorAction SilentlyContinue) {
        try {
            Disconnect-MgGraph -ErrorAction Stop | Out-Null
            OK "Graph disconnected"
        }
        catch {
            WARN ("Graph disconnect: {0}" -f (Get-ShortError $_))
        }
    }
    else {
        INFO "Disconnect-MgGraph unavailable"
    }

    Section "ERROR BUFFER"

    try {
        $Error.Clear()
        OK "PowerShell error buffer cleared"
    }
    catch {
        WARN ("Error buffer cleanup: {0}" -f (Get-ShortError $_))
    }

    if (-not $ClearVariables) {
        $ClearVariables = Confirm-Yes "Reset current Jumpbox session password"
    }

    if ($ClearVariables) {
        Section "JUMPBOX SESSION PASSWORD"

        Remove-Variable `
            -Name "JumpboxSessionPassword" `
            -Scope Global `
            -Force `
            -ErrorAction SilentlyContinue

        OK "Jumpbox session password variable cleared"
        INFO "The profile will generate a new value when the banner requests it again."
    }

    if (-not $NoNewWindow) {
        if (Confirm-Yes "Launch a fresh PowerShell 7 window") {
            Section "FRESH WINDOW"
            Start-FreshShell
        }
    }

    Section "SUMMARY"

    INFO "Session reset completed"
    INFO "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ""
    OK "Done"
}
catch {
    Write-Host ""
    FAIL (Get-ShortError $_)
}
finally {
    Pause-End
}
