<#PSScriptInfo
.VERSION 0.1.0
.GUID 792703cf-c2ef-4f96-999a-5b56846a941b
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
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
    Close-FKConsole
}

function Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
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
    Write-FKStart -Title 'JUMPBOX SESSION RESET' -Objective 'Disconnect local Graph and Exchange sessions and clear session errors.' -Mode 'MAKES CHANGES'
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
