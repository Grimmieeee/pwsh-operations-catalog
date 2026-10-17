<#PSScriptInfo
.VERSION 0.1.0
.GUID 695b0723-22f0-08a1-6771-3dc2cf78aaee
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
GET-TENANT-INBOX-RULES-AUDIT.ps1

Read-only tenant mailbox inbox rules audit.

Purpose:
- Reviews inbox rules across tenant mailboxes
- Filters Microsoft/system rule noise
- Flags forwarding, redirect, delete, move-to-junk/deleted, and hidden rules
- Optional CSV export only when approved
#>

param(
    [switch]$IncludeShared,
    [switch]$SuspiciousOnly
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

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    WARN $Prompt
    $a = Read-Host "Type $Required to continue"

    return ($a.Trim().ToUpper() -eq $Required.ToUpper())
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

    if ($null -eq $Value) {
        return ""
    }

    $text = [string]$Value
    return ($text -replace '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$', '').Trim()
}

function Get-InputLines {
    param([string]$Path)

    if (-not $Path) {
        $Path = (Read-Host "Input TXT/CSV path").Trim().Trim('"')
    }

    if (-not $Path -or -not (Test-Path $Path)) {
        FAIL "Input file not found"
        return @()
    }

    $items = New-Object System.Collections.ArrayList

    try {
        if ($Path.ToLower().EndsWith(".csv")) {
            $rows = Import-Csv -Path $Path -ErrorAction Stop

            foreach ($row in $rows) {
                $value = $null

                foreach ($name in @("UPN","UserPrincipalName","Email","Address","Group","GroupName","Name","Input")) {
                    if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                        $value = "$($row.$name)"
                        break
                    }
                }

                if (-not $value) {
                    $first = $row.PSObject.Properties | Select-Object -First 1
                    if ($first) { $value = "$($first.Value)" }
                }

                if ($value -and $value.Trim()) {
                    [void]$items.Add($value.Trim().Trim('"'))
                }
            }
        }
        else {
            $lines = Get-Content -Path $Path -Encoding UTF8 -ErrorAction Stop

            foreach ($line in $lines) {
                $clean = $line.Trim().Trim('"')

                if ($clean -and $clean -notmatch '^#') {
                    [void]$items.Add($clean)
                }
            }
        }
    }
    catch {
        FAIL "Could not read input file"
        return @()
    }

    return @($items | Select-Object -Unique)
}

function Offer-ExportCsv {
    param(
        [array]$Rows,
        [string]$DefaultName
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return
    }

    if (-not (Confirm-Yes "Export results to CSV")) {
        return
    }

    $path = Read-Host "CSV output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        OK "Exported: $path"
    }
    catch {
        WARN "CSV export failed"
    }
}

function Ensure-EXO {
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue | Out-Null

    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
        FAIL "ExchangeOnlineManagement module not available"
        Write-Host "Install with: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
        return $false
    }

    $connected = $false

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $conn = Get-ConnectionInformation -ErrorAction SilentlyContinue | Select-Object -First 1

        if ($conn) {
            $connected = $true
        }
    }

    if (-not $connected) {
        WARN "Exchange Online not connected"

        if (-not (Confirm-Yes "Connect to Exchange Online now")) {
            WARN "Exchange skipped"
            return $false
        }

        try {
            Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null
        }
        catch {
            try {
                Connect-ExchangeOnline -ErrorAction Stop | Out-Null
            }
            catch {
                FAIL "Exchange connection failed"
                return $false
            }
        }
    }

    OK "Exchange connected"
    return $true
}

function Is-SystemRule {
    param([string]$RuleName)

    if (-not $RuleName) { return $true }
    if ($RuleName -eq "Junk E-mail Rule") { return $true }
    if ($RuleName -like "Microsoft.Exchange.*") { return $true }
    if ($RuleName -like "Microsoft Outlook*") { return $true }
    if ($RuleName -like "Outlook Rules Organizer*") { return $true }
    return $false
}

function Get-RuleRisk {
    param($Rule)

    $flags = @()
    if ($Rule.ForwardTo) { $flags += "ForwardTo" }
    if ($Rule.RedirectTo) { $flags += "RedirectTo" }
    if ($Rule.ForwardAsAttachmentTo) { $flags += "ForwardAsAttachmentTo" }
    if ($Rule.DeleteMessage) { $flags += "DeleteMessage" }
    if ($Rule.PermanentDelete) { $flags += "PermanentDelete" }
    if ($Rule.MoveToFolder -match "Deleted|Junk|Trash") { $flags += "MoveToFolder" }
    if ($Rule.IsHidden) { $flags += "Hidden" }

    if ($flags.Count -eq 0) { return "Review" }
    return ($flags -join ", ")
}

try {
    try { $host.UI.RawUI.WindowTitle = "Tenant Mail Rules Audit" } catch {}

    Clear-Host
    Write-FKStart -Title 'TENANT MAIL RULES AUDIT' -Objective 'Finds inbox rules across the tenant that forward, redirect, delete, hide, or move mail in suspicious ways.' -Mode ''
    Write-Host ''
    Write-Host ""

    if (-not $IncludeShared) {
        $IncludeShared = Confirm-Yes "Include shared mailboxes"
    }

    if (-not $SuspiciousOnly) {
        $SuspiciousOnly = Confirm-Yes "Show/export suspicious rules only"
    }

    if (-not (Ensure-EXO)) {
        Pause-End
        exit 1
    }

    Section "MAILBOXES"

    $types = @("UserMailbox")
    if ($IncludeShared) { $types += "SharedMailbox" }

    $mailboxes = @(Get-Mailbox -ResultSize Unlimited -RecipientTypeDetails $types -ErrorAction SilentlyContinue)

    Write-Host "Mailboxes in scope: $($mailboxes.Count)"

    $rows = New-Object System.Collections.ArrayList

    foreach ($mbx in $mailboxes) {
        INFO "Checking $($mbx.PrimarySmtpAddress)"

        try {
            $rules = @()
            try {
                $rules = @(Get-InboxRule -Mailbox $mbx.PrimarySmtpAddress -IncludeHidden -ErrorAction Stop)
            } catch {
                $rules = @(Get-InboxRule -Mailbox $mbx.PrimarySmtpAddress -ErrorAction Stop)
            }

            foreach ($rule in $rules) {
                $name = Clean-Name $rule.Name
                if (Is-SystemRule $name) { continue }

                $risk = Get-RuleRisk $rule
                if ($SuspiciousOnly -and $risk -eq "Review") { continue }

                [void]$rows.Add([pscustomobject]@{
                    Mailbox=$mbx.PrimarySmtpAddress
                    RuleName=$name
                    Enabled=$rule.Enabled
                    Priority=$rule.Priority
                    Risk=$risk
                    ForwardTo=($rule.ForwardTo -join "; ")
                    RedirectTo=($rule.RedirectTo -join "; ")
                    MoveToFolder="$($rule.MoveToFolder)"
                })
            }
        } catch {
            WARN "Rule lookup failed: $($mbx.PrimarySmtpAddress)"
        }
    }

    Section "SUMMARY"
    Write-Host "Mailboxes checked : $($mailboxes.Count)"
    Write-Host "Rules found       : $($rows.Count)"
    Write-Host "Flagged           : $(@($rows | Where-Object { $_.Risk -ne 'Review' }).Count)"
    Write-Host ""

    foreach ($r in ($rows | Select-Object -First 75)) {
        if ($r.Risk -eq "Review") {
            WARN "$($r.Mailbox) | $($r.RuleName) | Review"
        } else {
            RISK "$($r.Mailbox) | $($r.RuleName) | $($r.Risk)"
        }
    }

    if ($rows.Count -gt 75) {
        WARN "Only first 75 rules shown"
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "tenant-mail-rules-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
