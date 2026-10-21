# .VERSION 1.0.2
<#
MULTI MAILBOX PERMISSIONS AUDIT

OBJECTIVE
Review mailbox forwarding, delegated access, and inbox rules for selected users.

INPUT
One UPN, multiple UPNs, or a TXT/CSV path.

CHANGES
Read-only. No changes are made.

RUN
Right-click > Run with PowerShell
or
Right-click > Run with PowerShell 7
#>

param(
    [string[]]$UPN
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Embedded into standalone report scripts by tools/reporting/build.ps1.
$script:FKReportLines = New-Object 'Collections.Generic.List[string]'
$script:FKReportWarnings = @()
$script:FKReportStartedUtc = [DateTime]::UtcNow.ToString('o')

function Write-FKReportLine {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Object,
        [object]$Separator=' ',[switch]$NoNewline,
        [ConsoleColor]$ForegroundColor,[ConsoleColor]$BackgroundColor
    )
    $line=($Object | ForEach-Object {[string]$_}) -join [string]$Separator
    $script:FKReportLines.Add($line)
    Write-Host @PSBoundParameters
}

function ConvertTo-FKDesktopReport {
    param([string]$Title,[string[]]$Lines,[string]$StartedUtc,[string]$ScopeNote)
    $encode={param($Text) [Net.WebUtility]::HtmlEncode([string]$Text)}
    $blocks=New-Object 'Collections.Generic.List[string]'
    $section=New-Object 'Collections.Generic.List[string]'
    foreach($line in @($Lines)) {
        if($line -match '^\s*[A-Z][A-Z /+&:()-]{2,}\s*$' -and $line.Trim().Length -lt 90) {
            if($section.Count) {$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>');$section.Clear()}
            $blocks.Add('<h2>'+(& $encode $line.Trim())+'</h2>')
        } else {$section.Add([string]$line)}
    }
    if($section.Count){$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>')}
    $safeTitle=& $encode $Title
    return @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"><title>$safeTitle</title>
<style>body{font:16px/1.55 system-ui,sans-serif;background:#f5f7f7;color:#172524;margin:0}main{max-width:1000px;margin:32px auto;padding:32px;background:white;border-top:4px solid #168779}header{border-bottom:1px solid #d1ddda;padding-bottom:20px}small{letter-spacing:.12em;color:#52716b}h1{font-size:28px;margin:12px 0}h2{font-size:15px;letter-spacing:.1em;color:#166b60;margin:28px 0 10px;border-bottom:1px solid #d1ddda;padding-bottom:8px}pre{font:14px/1.6 ui-monospace,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;margin:0}aside{background:#eef5f2;padding:12px 16px;margin:20px 0}footer{font-size:12px;color:#52716b;margin-top:32px}@media print{body{background:white}main{margin:0;padding:0;max-width:none}h2{break-after:avoid}pre{font-size:11px}}</style></head>
<body><main><header><small>F I E L D // K I T</small><h1>$safeTitle</h1><p>Collection started (UTC): $(& $encode $StartedUtc)</p></header><aside>$(& $encode $ScopeNote) Findings, unavailable checks, and displayed limits below are preserved from this run. Absence of a finding does not establish complete coverage.</aside>$($blocks.ToArray() -join "`n")<footer>Read-only report. No remote content or executable scripts. Review findings in context before taking action.</footer></main></body></html>
"@
}

function Save-FKDesktopReport {
    param([string]$Folder,[string]$Title,[string]$Content)
    if([string]::IsNullOrWhiteSpace($Folder) -or -not [IO.Directory]::Exists($Folder)){throw 'Report folder does not exist.'}
    $stem=($Title -replace '[^a-zA-Z0-9._-]','-').Trim('-')
    if(-not $stem){$stem='field-kit-report'}
    $stem=$stem.Substring(0,[Math]::Min(80,$stem.Length))
    $name=$stem+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.html'
    $path=Join-Path $Folder $name
    $bytes=(New-Object Text.UTF8Encoding($false)).GetBytes($Content)
    $stream=New-Object IO.FileStream($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
    $actual=[IO.File]::ReadAllBytes($path)
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        if([Convert]::ToBase64String($sha.ComputeHash($bytes)) -cne [Convert]::ToBase64String($sha.ComputeHash($actual))){throw 'Report readback did not match the collected content.'}
    }finally{$sha.Dispose()}
    return $path
}

function Offer-FKDesktopReport {
    param([string]$Title,[string]$ScopeNote='Scope matches the console output; only displayed rows are included.',[string]$DesktopFolder=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory))
    if(-not $script:FKReportLines.Count){return}
    try {
        if((Read-Host 'Save report to Desktop? [Y/N]').Trim() -notmatch '^(?i)y$'){return}
        $folder=$DesktopFolder
        $reportLines=@($script:FKReportLines.ToArray())
        if(@($script:FKReportWarnings).Count){$reportLines+=@('','SERVICE WARNINGS');$reportLines+=@($script:FKReportWarnings|ForEach-Object {[string]$_})}
        $content=ConvertTo-FKDesktopReport -Title $Title -Lines $reportLines -StartedUtc $script:FKReportStartedUtc -ScopeNote $ScopeNote
        try {$saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content}
        catch {
            Write-Host '[WARN] Desktop report could not be saved. Choose another existing folder or cancel.' -ForegroundColor Yellow
            $folder=(Read-Host 'Report folder (ENTER cancels)').Trim().Trim('"')
            if(-not $folder){return}
            $saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content
        }
        Write-Host ('[OK] Report saved and readback checked: '+$saved)
    }catch{Write-Host ('[WARN] Report export failed: '+$_.Exception.Message) -ForegroundColor Yellow}
}

function Write-OK   { param($m) Write-FKReportLine "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-FKReportLine "[INFO] $m" }
function Write-Warn { param($m) Write-FKReportLine "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-FKReportLine "[FAIL] $m" -ForegroundColor Red }

function Write-Section {
    param([string]$Title)

    try {
        Write-FKReportLine (" {0} " -f $Title) `
            -ForegroundColor White `
            -BackgroundColor DarkGray
    }
    catch {
        Write-FKReportLine $Title
    }
}

function Pause-End {
    Write-Host ''
    Write-Host 'SESSION COMPLETE'
    Write-FKReportLine ""
    Write-FKReportLine 'Press Enter to close session.' -NoNewline

    try {
        do {
            $key = $Host.UI.RawUI.ReadKey(
                "NoEcho,IncludeKeyDown"
            )
        }
        until ($key.VirtualKeyCode -eq 13)

        Write-FKReportLine ""
    }
    catch {
        Write-FKReportLine ""
        Read-Host 'Press Enter to close session.' | Out-Null
    }
}

function Get-ShortError {
    param($ErrorRecord)

    $Message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = [string]$ErrorRecord
    }

    return (($Message -replace "\s+", " ").Trim())
}

function Ensure-Module {
    param([string]$Name)

    $module=Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop
}

function Test-AnyMailbox {
    param([string[]]$Mailboxes)

    foreach ($Mailbox in $Mailboxes) {
        try {
            Get-Mailbox `
                -Identity $Mailbox `
                -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                Out-Null

            return $true
        }
        catch {
        }
    }

    return $false
}

function Connect-ExchangeAuto {
    param([string[]]$ValidationMailboxes)

    Ensure-Module -Name "ExchangeOnlineManagement"

    $Connected = $false

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $Connection = Get-ConnectionInformation -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if (
            $Connection -and
            (Test-AnyMailbox -Mailboxes $ValidationMailboxes)
        ) {
            $Connected = $true
        }
    }

    if ($Connected) {
        Write-OK "Exchange session reused"
        return
    }

    Write-FKReportLine "Exchange Online: Connecting..."

    $Command = Get-Command Connect-ExchangeOnline -ErrorAction Stop
    $Parameters = @{
        ErrorAction = "Stop"
    }

    if ($Command.Parameters.ContainsKey("ShowBanner")) {
        $Parameters["ShowBanner"] = $false
    }

    Connect-ExchangeOnline @Parameters | Out-Null

    if (-not (Test-AnyMailbox -Mailboxes $ValidationMailboxes)) {
        throw "Exchange connected, but none of the supplied mailboxes resolved in the connected tenant."
    }

    Write-OK "Exchange connected"
}

function Get-MailboxInputs {
    param([string[]]$Values)

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "Mailbox UPN(s) or TXT/CSV path").Trim().Trim('"')
        if ($entered) { $rawValues=@($entered) }
    }

    foreach ($value in $rawValues) {
        $clean=([string]$value).Trim().Trim('"')
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($clean) -ieq '.csv') {
                foreach ($row in @(Import-Csv -LiteralPath $clean -ErrorAction Stop)) {
                    $candidate=$null
                    foreach ($name in @('UPN','UserPrincipalName','Email','Address','Mailbox','Name','Input')) {
                        if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                            $candidate=[string]$row.$name
                            break
                        }
                    }
                    if (-not $candidate) {
                        $first=$row.PSObject.Properties | Select-Object -First 1
                        if ($first) { $candidate=[string]$first.Value }
                    }
                    if ($candidate -and $candidate.Trim()) { [void]$items.Add($candidate.Trim().Trim('"')) }
                }
            }
            else {
                foreach ($line in @(Get-Content -LiteralPath $clean -Encoding UTF8 -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"')
                    if ($candidate -and $candidate -notmatch '^#') { [void]$items.Add($candidate) }
                }
            }
            continue
        }

        foreach ($candidate in @($clean -split '\s*,\s*')) {
            if ($candidate) { [void]$items.Add($candidate.Trim()) }
        }
    }

    return @($items | Where-Object { $_ } | Select-Object -Unique)
}

function Clean-Name {
    param($Name)

    if ($null -eq $Name) {
        return ""
    }

    return (
        [string]$Name -replace
        '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$',
        ''
    ).Trim()
}

function Rule-Detail {
    param($Rule)

    $Parts = @()

    foreach ($Property in @(
        "ForwardTo",
        "RedirectTo",
        "ForwardAsAttachmentTo",
        "DeleteMessage",
        "MoveToFolder",
        "CopyToFolder",
        "StopProcessingRules"
    )) {
        $Value = $Rule.$Property

        if ($null -ne $Value -and "$Value" -ne "") {
            if ($Value -is [array]) {
                $Parts += "$Property=$($Value -join ', ')"
            }
            else {
                $Parts += "$Property=$Value"
            }
        }
    }

    if ($Parts.Count -eq 0) {
        return "No high-risk action displayed"
    }

    return ($Parts -join "; ")
}

function Write-QueryFailure {
    param(
        [string]$Label,
        [string]$Message
    )

    Write-FKReportLine "Status : Not available"
    Write-Warn "$Label query failed: $Message"
}

try {
    Write-FKReportLine 'Get Mailbox Permissions'
    Write-FKReportLine 'Review mailbox forwarding, delegated access, and inbox rules for selected users.'
    Write-FKReportLine "READ-ONLY. NO CHANGES MADE."
    Write-FKReportLine ""

    $UPN=@(Get-MailboxInputs -Values $UPN)

    if (-not $UPN -or $UPN.Count -eq 0) {
        throw "At least one mailbox UPN is required."
    }

    Connect-ExchangeAuto -ValidationMailboxes $UPN

    foreach ($MailboxUPN in $UPN) {
        Write-FKReportLine ""
        Write-FKReportLine ("MAILBOX: {0}" -f $MailboxUPN)

        try {
            $Mailbox = Get-Mailbox `
                -Identity $MailboxUPN `
                -ErrorAction Stop -WarningVariable +script:FKReportWarnings
        }
        catch {
            Write-Warn "Mailbox lookup failed: $(Get-ShortError $_)"
            continue
        }

        Write-Section "FORWARDING"

        $Forwarding = @()

        if ($Mailbox.ForwardingSmtpAddress) {
            $Forwarding += "SMTP: $($Mailbox.ForwardingSmtpAddress)"
        }

        if ($Mailbox.ForwardingAddress) {
            $Forwarding += "Recipient: $($Mailbox.ForwardingAddress)"
        }

        if ($Mailbox.DeliverToMailboxAndForward) {
            $Forwarding += "DeliverToMailboxAndForward: True"
        }

        if ($Forwarding.Count -eq 0) {
            Write-FKReportLine "  none"
        }
        else {
            $Forwarding | ForEach-Object {
                Write-FKReportLine "  - $_"
            }
        }

        Write-FKReportLine ""
        Write-Section "FULL ACCESS"

        try {
            $FullAccess = @(
                Get-MailboxPermission `
                    -Identity $Mailbox.Identity `
                    -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                Where-Object {
                    $_.User -ne "NT AUTHORITY\SELF" -and
                    $_.IsInherited -eq $false -and
                    $_.AccessRights -contains "FullAccess"
                }
            )

            if ($FullAccess.Count -eq 0) {
                Write-FKReportLine "  none"
            }
            else {
                $FullAccess | ForEach-Object {
                    Write-FKReportLine ("  - {0}" -f $_.User)
                }
            }
        }
        catch {
            Write-QueryFailure `
                -Label "Full Access" `
                -Message (Get-ShortError $_)
        }

        Write-FKReportLine ""
        Write-Section "SEND AS"

        try {
            $SendAs = @(
                Get-RecipientPermission `
                    -Identity $Mailbox.Identity `
                    -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
                Where-Object {
                    $_.Trustee -ne "NT AUTHORITY\SELF" -and
                    $_.AccessRights -contains "SendAs"
                }
            )

            if ($SendAs.Count -eq 0) {
                Write-FKReportLine "  none"
            }
            else {
                $SendAs | ForEach-Object {
                    Write-FKReportLine ("  - {0}" -f $_.Trustee)
                }
            }
        }
        catch {
            Write-QueryFailure `
                -Label "Send As" `
                -Message (Get-ShortError $_)
        }

        Write-FKReportLine ""
        Write-Section "SEND ON BEHALF"

        try {
            $SendOnBehalf = @($Mailbox.GrantSendOnBehalfTo)

            if ($SendOnBehalf.Count -eq 0) {
                Write-FKReportLine "  none"
            }
            else {
                foreach ($Delegate in $SendOnBehalf) {
                    try {
                        $Recipient = Get-Recipient `
                            -Identity $Delegate `
                            -ErrorAction Stop -WarningVariable +script:FKReportWarnings

                        if ($Recipient.PrimarySmtpAddress) {
                            Write-FKReportLine (
                                "  - {0} <{1}>" -f
                                $Recipient.DisplayName,
                                $Recipient.PrimarySmtpAddress
                            )
                        }
                        else {
                            Write-FKReportLine ("  - {0}" -f $Recipient.DisplayName)
                        }
                    }
                    catch {
                        Write-Warn "A Send On Behalf delegate was returned but its friendly name could not be resolved."
                    }
                }
            }
        }
        catch {
            Write-QueryFailure `
                -Label "Send On Behalf" `
                -Message (Get-ShortError $_)
        }

        Write-FKReportLine ""
        Write-Section "INBOX RULES"

        $RulesAvailable = $true
        $Rules = @()
        $RuleError = ""

        try {
            $Rules = @(
                Get-InboxRule `
                    -Mailbox $Mailbox.Identity `
                    -IncludeHidden `
                    -ErrorAction Stop -WarningVariable +script:FKReportWarnings
            )
        }
        catch {
            try {
                $Rules = @(
                    Get-InboxRule `
                        -Mailbox $Mailbox.Identity `
                        -ErrorAction Stop -WarningVariable +script:FKReportWarnings
                )

                Write-Warn "Hidden-rule visibility is not available in this session."
            }
            catch {
                $RulesAvailable = $false
                $RuleError = Get-ShortError $_
            }
        }

        if (-not $RulesAvailable) {
            Write-QueryFailure `
                -Label "Inbox rules" `
                -Message $RuleError
        }
        elseif ($Rules.Count -eq 0) {
            Write-FKReportLine "  none"
        }
        else {
            foreach ($Rule in $Rules) {
                $Hidden = ""

                if ($Rule.IsHidden) {
                    $Hidden = " [HIDDEN]"
                }

                Write-FKReportLine ("  - {0}{1}" -f (Clean-Name $Rule.Name), $Hidden)
                Write-FKReportLine ("    {0}" -f (Rule-Detail $Rule))
            }
        }
    }

    Write-FKReportLine ""
    Write-FKReportLine "STANDARD NOTE"
    Write-FKReportLine "Read-only mailbox permissions and forwarding audit. No changes were made."
}
catch {
    Write-FKReportLine ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Offer-FKDesktopReport -Title 'GET-MAILBOX-PERMISSIONS'

    Pause-End
}