<#PSScriptInfo
.VERSION 0.1.0
.GUID d20a3a48-6dfc-c966-492b-37c0da6ae6d9
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
GET-TRANSPORT-RULES-AUDIT.ps1

Read-only Exchange transport rule audit.

Purpose:
- Reviews tenant-wide transport rules
- Flags BCC, redirect, forwarding, delete, quarantine, and external recipient actions
- Useful because transport rules survive individual mailbox remediation
#>

param()

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
function RISK {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[RISK] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}
function FAIL {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function Pause-End {
    Close-FKConsole
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
}

function Confirm-Yes {
    param([string]$Prompt)

    $a = Read-Host "$Prompt [Y/N]"
    return ($a.Trim().ToUpper() -eq "Y")
}

function Encode-Value {
    param([string]$Value)
    return [System.Uri]::EscapeDataString($Value)
}

function Escape-OData {
    param([string]$Value)
    return ($Value -replace "'", "''")
}

function Clean-Name {
    param([object]$Value)

    if ($null -eq $Value) { return "" }

    $text = [string]$Value
    return ($text -replace '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$', '').Trim()
}

function Offer-ExportCsv {
    param(
        [array]$Rows,
        [string]$DefaultName
    )

    if (-not $Rows -or $Rows.Count -eq 0) { return }

    if (-not (Confirm-Yes "Export results to CSV")) { return }

    $path = Read-Host "CSV output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)

        if ($check.Count -ne $Rows.Count) {
            throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
        }

        OK "Exported and verified: $path"
    }
    catch {
        WARN ("CSV export failed: {0}" -f $_.Exception.Message)
    }
}

function Offer-ExportJson {
    param(
        [object]$Object,
        [string]$DefaultName
    )

    if (-not $Object) { return }

    if (-not (Confirm-Yes "Export snapshot to JSON")) { return }

    $path = Read-Host "JSON output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Object | ConvertTo-Json -Depth 20 | Out-File -FilePath $path -Encoding UTF8
        OK "Exported: $path"
    }
    catch {
        WARN "JSON export failed"
    }
}

function Ensure-EXO {
    $moduleName='ExchangeOnlineManagement'
    $module=Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$moduleName is required but is not installed. Install with: Install-Module $moduleName -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop | Out-Null

    $connected=$false
    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $conn=Get-ConnectionInformation -ErrorAction SilentlyContinue |
            Where-Object {
                $_.State -eq 'Connected' -or
                $_.ConnectionStatus -eq 'Connected'
            } |
            Select-Object -First 1
        if ($conn) { $connected=$true }
    }

    if (-not $connected) {
        INFO 'Exchange: Connecting...'
        $command=Get-Command Connect-ExchangeOnline -ErrorAction Stop
        $parameters=@{ ErrorAction='Stop' }
        if ($command.Parameters.ContainsKey('ShowBanner')) { $parameters.ShowBanner=$false }
        if ($command.Parameters.ContainsKey('ShowProgress')) { $parameters.ShowProgress=$false }
        Connect-ExchangeOnline @parameters | Out-Null
    }

    $null=Get-AcceptedDomain -ResultSize 1 -ErrorAction Stop
    OK 'Exchange connected'
    return $true
}

function Get-RuleRisk {
    param($Rule)

    $flags = @()

    foreach ($prop in @("BlindCopyTo","RedirectMessageTo","ApplyHtmlDisclaimerLocation","DeleteMessage","RejectMessageReasonText","Quarantine","ModerateMessageByUser")) {
        try {
            if ($Rule.$prop) { $flags += $prop }
        } catch {}
    }

    try {
        if ($Rule.State -eq "Disabled") { $flags += "Disabled" }
    } catch {}

    if ($flags.Count -eq 0) { return "Review" }
    return ($flags -join ", ")
}

try {
    try { $host.UI.RawUI.WindowTitle = "Tenant Transport Rules Audit" } catch {}

    Write-FKStart -Title 'TENANT TRANSPORT RULES AUDIT' -Objective 'Reviews tenant-wide mail-flow rules and highlights actions that warrant operator review.' -Mode ''
    Write-Host ''
    Write-Host ""

    if (-not (Ensure-EXO)) {
        Pause-End
        exit 1
    }

    Section "AUDIT"

    $rules = @(Get-TransportRule -ErrorAction Stop)
    $rows = New-Object System.Collections.ArrayList

    foreach ($r in $rules) {
        $risk = Get-RuleRisk $r

        [void]$rows.Add([pscustomobject]@{
            RuleName=(Clean-Name $r.Name)
            State=$r.State
            Mode=$r.Mode
            Priority=$r.Priority
            Risk=$risk
            BlindCopyTo=($r.BlindCopyTo -join "; ")
            RedirectMessageTo=($r.RedirectMessageTo -join "; ")
            DeleteMessage=$r.DeleteMessage
            RejectMessageReasonText=$r.RejectMessageReasonText
        })
    }

    Section "SUMMARY"
    Write-Host "Rules checked : $($rows.Count)"
    Write-Host "Flagged       : $(@($rows | Where-Object { $_.Risk -ne 'Review' }).Count)"
    Write-Host ""

    foreach ($r in ($rows | Sort-Object Priority)) {
        if ($r.Risk -ne "Review") {
            RISK "$($r.RuleName) | $($r.State) | $($r.Risk)"
        } else {
            Write-Host "$($r.RuleName) | $($r.State)"
        }
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "tenant-transport-rules-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete. No changes made."
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}