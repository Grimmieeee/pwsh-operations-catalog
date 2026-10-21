# .VERSION 1.0.1
<#
GET USER MAILBOX SNAPSHOT

OBJECTIVE
Provide a fast, read-only mailbox posture snapshot for one Microsoft 365 user.

INPUT
One UPN.

CHANGES
Read-only. No changes are made.
#>

param([string]$UPN)

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

function Write-Section {
    param([string]$Title)

    Write-FKReportLine $Title
}

function Get-ShortError {
    param($ErrorRecord)

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Ensure-Module {
    param(
        [string]$Name,
        [string]$Command
    )

    $module=Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Name loaded, but $Command is unavailable."
    }
}

function Get-ActiveExchangeConnection {
    if (-not (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue)) {
        return $null
    }

    try {
        return Get-ConnectionInformation -ErrorAction SilentlyContinue |
            Where-Object {
                $_.State -eq "Connected" -or
                $_.ConnectionStatus -eq "Connected"
            } |
            Select-Object -First 1
    }
    catch {
        return $null
    }
}

function Test-ExchangeTenant {
    param([string]$TargetDomain)

    try {
        if ([string]::IsNullOrWhiteSpace($TargetDomain)) {
            Get-OrganizationConfig -ErrorAction Stop -WarningVariable +script:FKReportWarnings | Out-Null
            return $true
        }

        $domains = @(
            Get-AcceptedDomain `
                -ResultSize Unlimited `
                -ErrorAction Stop |
            ForEach-Object {
                ([string]$_.DomainName).ToLowerInvariant()
            }
        )

        return ($domains -contains $TargetDomain.ToLowerInvariant())
    }
    catch {
        return $false
    }
}

function Connect-ExchangeAttempt {
    param(
        [string]$TargetDomain,
        [switch]$Delegated
    )

    $command = Get-Command Connect-ExchangeOnline -ErrorAction Stop
    $parameters = @{
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ShowBanner")) {
        $parameters["ShowBanner"] = $false
    }

    if ($command.Parameters.ContainsKey("ShowProgress")) {
        $parameters["ShowProgress"] = $false
    }

    if ($command.Parameters.ContainsKey("DisableWAM")) {
        $parameters["DisableWAM"] = $true
    }

    if (
        $Delegated -and
        -not [string]::IsNullOrWhiteSpace($TargetDomain) -and
        $command.Parameters.ContainsKey("DelegatedOrganization")
    ) {
        $parameters["DelegatedOrganization"] = $TargetDomain
    }

    Connect-ExchangeOnline @parameters | Out-Null
}

function Connect-ExchangeAuto {
    param([string]$TargetDomain)

    Ensure-Module `
        -Name "ExchangeOnlineManagement" `
        -Command "Connect-ExchangeOnline"

    if (
        (Get-ActiveExchangeConnection) -and
        (Test-ExchangeTenant -TargetDomain $TargetDomain)
    ) {
        Write-OK "Exchange session reused"
        return
    }

    try {
        Disconnect-ExchangeOnline `
            -Confirm:$false `
            -ErrorAction SilentlyContinue |
            Out-Null
    }
    catch {
    }

    Write-FKReportLine "Exchange Online: Connecting..."

    $errors = @()

    foreach ($delegated in @($false, $true)) {
        try {
            Connect-ExchangeAttempt `
                -TargetDomain $TargetDomain `
                -Delegated:$delegated

            if (Test-ExchangeTenant -TargetDomain $TargetDomain) {
                Write-OK "Exchange connected"
                return
            }

            $errors += "Connected, but the expected tenant domain was not present."
        }
        catch {
            $errors += Get-ShortError $_
        }

        try {
            Disconnect-ExchangeOnline `
                -Confirm:$false `
                -ErrorAction SilentlyContinue |
                Out-Null
        }
        catch {
        }
    }

    throw (
        "Exchange connection failed: " +
        (@($errors | Where-Object { $_ } | Select-Object -Unique) -join " | ")
    )
}

function Test-ExchangeNotFoundError {
    param([string]$Message)

    if ([string]::IsNullOrWhiteSpace($Message)) {
        return $false
    }

    return (
        $Message -match
        "(?i)(couldn'?t be found|could not be found|not found|does not exist|doesn't exist|matches no entries|cannot be found)"
    )
}

function Test-ExchangeBooleanFalse {
    param($Value)

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [bool]) {
        return (-not $Value)
    }

    $parsed = $false

    if ([bool]::TryParse(([string]$Value).Trim(), [ref]$parsed)) {
        return (-not $parsed)
    }

    return $false
}

function Test-ExplicitFullAccessRow {
    param($Permission)

    if ($null -eq $Permission) {
        return $false
    }

    $rights = @(
        $Permission.AccessRights |
        ForEach-Object { [string]$_ }
    )

    return (
        $rights -contains "FullAccess" -and
        (Test-ExchangeBooleanFalse $Permission.Deny) -and
        (Test-ExchangeBooleanFalse $Permission.IsInherited)
    )
}

function Test-SendAsAllowRow {
    param($Permission)

    if ($null -eq $Permission) {
        return $false
    }

    $rights = @(
        $Permission.AccessRights |
        ForEach-Object { [string]$_ }
    )

    if ($rights -notcontains "SendAs") {
        return $false
    }

    if ($Permission.PSObject.Properties.Name -contains "Deny") {
        if (([string]$Permission.Deny).Trim() -match "^(?i:true)$") {
            return $false
        }
    }

    return $true
}

function Format-RuleTarget {
    param($Value)

    $text = ([string]$Value).Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    if (
        $text -match
        '(?i)SMTP:([A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,})'
    ) {
        return $Matches[1]
    }

    if (
        $text -match
        '(?i)([A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,})'
    ) {
        return $Matches[1]
    }

    return $text.Trim('"')
}

function Add-RuleAction {
    param(
        [System.Collections.Generic.List[string]]$List,
        [string]$Label,
        $Value
    )

    if ($null -eq $Value) {
        return
    }

    $items = @(
        $Value |
        ForEach-Object { Format-RuleTarget $_ } |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
    )

    if ($items.Count -gt 0) {
        $List.Add(("{0}: {1}" -f $Label, ($items -join ", ")))
    }
}

function Rule-Detail {
    param($Rule)

    $parts = New-Object System.Collections.Generic.List[string]

    Add-RuleAction -List $parts -Label "Forward to" -Value $Rule.ForwardTo
    Add-RuleAction -List $parts -Label "Redirect to" -Value $Rule.RedirectTo
    Add-RuleAction -List $parts -Label "Forward as attachment" -Value $Rule.ForwardAsAttachmentTo

    if ($Rule.DeleteMessage -eq $true) {
        $parts.Add("Delete message")
    }

    if (
        $Rule.PSObject.Properties.Name -contains "PermanentDelete" -and
        $Rule.PermanentDelete -eq $true
    ) {
        $parts.Add("Permanently delete message")
    }

    if ($Rule.MoveToFolder) {
        $parts.Add("Move to: $($Rule.MoveToFolder)")
    }

    if ($Rule.CopyToFolder) {
        $parts.Add("Copy to: $($Rule.CopyToFolder)")
    }

    if (
        $Rule.PSObject.Properties.Name -contains "MarkAsRead" -and
        $Rule.MarkAsRead -eq $true
    ) {
        $parts.Add("Mark as read")
    }

    if ($Rule.StopProcessingRules -eq $true) {
        $parts.Add("Stop processing rules")
    }

    if ($parts.Count -eq 0) {
        return "No common BEC-style action returned"
    }

    return ($parts -join "; ")
}

function Test-KnownSystemInboxRule {
    param($Rule)

    # Exchange does not expose a reliable "created by user" flag.
    # Suppress only narrowly identified default noise.
    if ([string]$Rule.Name -ne "Junk E-mail Rule") {
        return $false
    }

    return ((Rule-Detail $Rule) -eq "No common BEC-style action returned")
}

function Show-InboxRule {
    param($Rule)

    $name = [string]$Rule.Name

    if ($Rule.Enabled -eq $false) {
        $name = "$name [Disabled]"
    }
    elseif ($null -eq $Rule.Enabled) {
        $name = "$name [Status unknown]"
    }

    Write-FKReportLine ("Rule: {0}" -f $name)
    Write-FKReportLine ("Action: {0}" -f (Rule-Detail $Rule))
}

try {
    Write-FKReportLine 'Get Mailbox Security'
    Write-FKReportLine 'Checks a mailbox for forwarding, rules, delegates, and other access that may matter during an investigation.'
    Write-FKReportLine "READ-ONLY. NO CHANGES MADE."
    Write-FKReportLine ""

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        $UPN = (Read-Host "UPN").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        throw "UPN is required."
    }

    $targetDomain = ($UPN -split "@", 2)[1].ToLowerInvariant()
    Connect-ExchangeAuto -TargetDomain $targetDomain

    $mailbox = Get-Mailbox `
        -Identity $UPN `
        -ErrorAction Stop -WarningVariable +script:FKReportWarnings

    $dataGaps = @()

    Write-FKReportLine ""
    Write-Section "MAILBOX"
    Write-FKReportLine (
        "User: {0} <{1}>" -f
        $mailbox.DisplayName,
        $mailbox.PrimarySmtpAddress
    )
    Write-FKReportLine ("Type: {0}" -f $mailbox.RecipientTypeDetails)

    try {
        $stats = $null

        if (Get-Command Get-EXOMailboxStatistics -ErrorAction SilentlyContinue) {
            try {
                $stats = Get-EXOMailboxStatistics `
                    -Identity $mailbox.PrimarySmtpAddress `
                    -Properties LastLogonTime `
                    -ErrorAction Stop
            }
            catch {
                $stats = Get-EXOMailboxStatistics `
                    -Identity $mailbox.PrimarySmtpAddress `
                    -ErrorAction Stop
            }
        }
        elseif (Get-Command Get-MailboxStatistics -ErrorAction SilentlyContinue) {
            $stats = Get-MailboxStatistics `
                -Identity $mailbox.PrimarySmtpAddress `
                -ErrorAction Stop -WarningVariable +script:FKReportWarnings
        }
        else {
            throw "Mailbox statistics command unavailable."
        }

        if ($stats -and $stats.LastLogonTime) {
            $lastLogon = [datetime]$stats.LastLogonTime
            $ageDays = [int]((Get-Date) - $lastLogon).TotalDays

            Write-FKReportLine (
                "Last Logon: {0} ({1} days ago)" -f
                $lastLogon.ToLocalTime().ToString("yyyy-MM-dd HH:mm"),
                $ageDays
            )
        }
        else {
            Write-FKReportLine "Last Logon: Not available"
            $dataGaps += "Mailbox statistics returned no LastLogonTime."
        }
    }
    catch {
        Write-FKReportLine "Last Logon: Not available"
        $dataGaps += "Mailbox activity: $(Get-ShortError $_)"
    }


    Write-FKReportLine ""
    Write-Section "FORWARDING"

    $forwardingTargets = New-Object System.Collections.Generic.List[string]

    if ($mailbox.ForwardingSmtpAddress) {
        $target = ([string]$mailbox.ForwardingSmtpAddress) -replace '^(?i)smtp:', ''

        if (-not [string]::IsNullOrWhiteSpace($target)) {
            $forwardingTargets.Add($target)
        }
    }

    if ($mailbox.ForwardingAddress) {
        $resolvedTarget = $null

        try {
            $recipient = Get-Recipient `
                -Identity $mailbox.ForwardingAddress `
                -ErrorAction Stop -WarningVariable +script:FKReportWarnings

            if ($recipient.PrimarySmtpAddress) {
                $resolvedTarget = [string]$recipient.PrimarySmtpAddress
            }
            elseif ($recipient.DisplayName) {
                $resolvedTarget = [string]$recipient.DisplayName
            }
        }
        catch {
            $resolvedTarget = [string]$mailbox.ForwardingAddress
        }

        if (-not [string]::IsNullOrWhiteSpace($resolvedTarget)) {
            $forwardingTargets.Add($resolvedTarget)
        }
    }

    $forwardingTargets = @(
        $forwardingTargets |
        Sort-Object -Unique
    )

    if ($forwardingTargets.Count -eq 0) {
        Write-FKReportLine "Status: No"
    }
    else {
        Write-FKReportLine "Status: Yes"

        foreach ($target in $forwardingTargets) {
            Write-FKReportLine ("Target: {0}" -f $target)
        }

        Write-FKReportLine (
            "Deliver copy: {0}" -f
            $(if ($mailbox.DeliverToMailboxAndForward) { "Yes" } else { "No" })
        )
    }


    $visibleRules = @()
    $hiddenRules = @()
    $hiddenRuleCoverage = $false
    $knownSystemRuleCount = 0
    $ruleQueryAvailable = $false

    try {
        $rules = @()

        try {
            $rules = @(
                Get-InboxRule `
                    -Mailbox $mailbox.PrimarySmtpAddress `
                    -IncludeHidden `
                    -ErrorAction Stop -WarningVariable +script:FKReportWarnings
            )

            $hiddenRuleCoverage = $true
            $ruleQueryAvailable = $true
        }
        catch {
            $hiddenError = Get-ShortError $_

            $rules = @(
                Get-InboxRule `
                    -Mailbox $mailbox.PrimarySmtpAddress `
                    -ErrorAction Stop -WarningVariable +script:FKReportWarnings
            )

            $ruleQueryAvailable = $true
            $dataGaps += "Hidden inbox-rule visibility unavailable: $hiddenError"
        }

        $knownSystemRuleCount = @(
            $rules |
            Where-Object { Test-KnownSystemInboxRule $_ }
        ).Count

        $visibleRules = @(
            $rules |
            Where-Object {
                $_.IsHidden -ne $true -and
                -not (Test-KnownSystemInboxRule $_)
            } |
            Sort-Object Priority,Name
        )

        if ($hiddenRuleCoverage) {
            $hiddenRules = @(
                $rules |
                Where-Object {
                    $_.IsHidden -eq $true -and
                    -not (Test-KnownSystemInboxRule $_)
                } |
                Sort-Object Priority,Name
            )
        }
    }
    catch {
        $dataGaps += "Inbox rules: $(Get-ShortError $_)"
    }

    Write-FKReportLine ""
    Write-Section "INBOX RULES"

    if (-not $ruleQueryAvailable) {
        Write-FKReportLine "Status: Not available"
    }
    elseif ($visibleRules.Count -eq 0) {
        Write-FKReportLine "Status: No"
    }
    else {
        Write-FKReportLine "Status: Yes"

        for ($index = 0; $index -lt $visibleRules.Count; $index++) {
            if ($index -gt 0) {
                Write-FKReportLine ""
            }

            Show-InboxRule $visibleRules[$index]
        }
    }

    Write-FKReportLine ""
    Write-Section "HIDDEN INBOX RULES"

    if (-not $ruleQueryAvailable -or -not $hiddenRuleCoverage) {
        Write-FKReportLine "Status: Not available"
    }
    elseif ($hiddenRules.Count -eq 0) {
        Write-FKReportLine "Status: No"
    }
    else {
        Write-FKReportLine "Status: Yes"

        for ($index = 0; $index -lt $hiddenRules.Count; $index++) {
            if ($index -gt 0) {
                Write-FKReportLine ""
            }

            Show-InboxRule $hiddenRules[$index]
        }
    }


    $fullAccess = @()
    $sendAs = @()
    $sendOnBehalfDisplay = @()

    $fullAccessAvailable = $true
    $sendAsAvailable = $true
    $sendOnBehalfAvailable = $true

    try {
        $fullAccess = @(
            Get-MailboxPermission `
                -Identity $mailbox.Identity `
                -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
            Where-Object {
                ([string]$_.User -notmatch "NT AUTHORITY\\SELF|S-1-5-10") -and
                (Test-ExplicitFullAccessRow $_)
            } |
            ForEach-Object { [string]$_.User } |
            Where-Object { $_ } |
            Sort-Object -Unique
        )
    }
    catch {
        $fullAccessAvailable = $false
        $dataGaps += "Full Access: $(Get-ShortError $_)"
    }

    try {
        $sendAs = @(
            Get-RecipientPermission `
                -Identity $mailbox.Identity `
                -ErrorAction Stop -WarningVariable +script:FKReportWarnings |
            Where-Object {
                ([string]$_.Trustee -notmatch "NT AUTHORITY\\SELF|S-1-5-10") -and
                (Test-SendAsAllowRow $_)
            } |
            ForEach-Object { [string]$_.Trustee } |
            Where-Object { $_ } |
            Sort-Object -Unique
        )
    }
    catch {
        $sendAsAvailable = $false
        $dataGaps += "Send As: $(Get-ShortError $_)"
    }

    try {
        $sendOnBehalf = @($mailbox.GrantSendOnBehalfTo)

        foreach ($delegate in $sendOnBehalf) {
            try {
                $recipient = Get-Recipient `
                    -Identity $delegate `
                    -ErrorAction Stop -WarningVariable +script:FKReportWarnings

                if ($recipient.PrimarySmtpAddress) {
                    $sendOnBehalfDisplay += [string]$recipient.PrimarySmtpAddress
                }
                elseif ($recipient.DisplayName) {
                    $sendOnBehalfDisplay += [string]$recipient.DisplayName
                }
            }
            catch {
                $sendOnBehalfAvailable = $false
                $dataGaps += "One Send On Behalf delegate could not be resolved to a friendly name."
            }
        }

        $sendOnBehalfDisplay = @(
            $sendOnBehalfDisplay |
            Where-Object { $_ } |
            Sort-Object -Unique
        )
    }
    catch {
        $sendOnBehalfAvailable = $false
        $dataGaps += "Send On Behalf: $(Get-ShortError $_)"
    }

    Write-FKReportLine ""
    Write-Section "MAILBOX PERMISSIONS"

    $permissionCount = (
        $fullAccess.Count +
        $sendAs.Count +
        $sendOnBehalfDisplay.Count
    )

    $permissionCoverageComplete = (
        $fullAccessAvailable -and
        $sendAsAvailable -and
        $sendOnBehalfAvailable
    )

    if ($permissionCount -gt 0) {
        Write-FKReportLine "Status: Yes"
    }
    elseif ($permissionCoverageComplete) {
        Write-FKReportLine "Status: No"
    }
    else {
        Write-FKReportLine "Status: Review"
    }

    if ($fullAccessAvailable) {
        if ($fullAccess.Count -gt 0) {
            Write-FKReportLine ("Full Access: {0}" -f ($fullAccess -join "; "))
        }
        else {
            Write-FKReportLine "Full Access: No"
        }
    }
    else {
        Write-FKReportLine "Full Access: Not available"
    }

    if ($sendAsAvailable) {
        if ($sendAs.Count -gt 0) {
            Write-FKReportLine ("Send As: {0}" -f ($sendAs -join "; "))
        }
        else {
            Write-FKReportLine "Send As: No"
        }
    }
    else {
        Write-FKReportLine "Send As: Not available"
    }

    if ($sendOnBehalfAvailable) {
        if ($sendOnBehalfDisplay.Count -gt 0) {
            Write-FKReportLine (
                "Send On Behalf: {0}" -f
                ($sendOnBehalfDisplay -join "; ")
            )
        }
        else {
            Write-FKReportLine "Send On Behalf: No"
        }
    }
    else {
        Write-FKReportLine "Send On Behalf: Not available"
    }


    Write-FKReportLine ""
    Write-Section "LEGACY AUTH"

    try {
        $cas = Get-CASMailbox `
            -Identity $mailbox.Identity `
            -ErrorAction Stop -WarningVariable +script:FKReportWarnings

        $legacy = @()

        if ($cas.ImapEnabled) {
            $legacy += "IMAP enabled"
        }

        if ($cas.PopEnabled) {
            $legacy += "POP enabled"
        }

        if ($cas.SmtpClientAuthenticationDisabled -eq $false) {
            $legacy += "SMTP AUTH enabled"
        }

        if ($legacy.Count -eq 0) {
            Write-FKReportLine "Status: No"
        }
        else {
            Write-FKReportLine "Status: Yes"
            $legacy | ForEach-Object { Write-FKReportLine $_ }
        }
    }
    catch {
        Write-FKReportLine "Status: Not available"
        $dataGaps += "Legacy authentication: $(Get-ShortError $_)"
    }

    Write-FKReportLine ""
    Write-Section "DATA GAPS"

    $uniqueDataGaps = @(
        $dataGaps |
        Select-Object -Unique
    )

    if ($uniqueDataGaps.Count -eq 0) {
        Write-FKReportLine "Status: No"
    }
    else {
        Write-FKReportLine "Status: Yes"
        $uniqueDataGaps | ForEach-Object { Write-FKReportLine ("- {0}" -f $_) }
    }

    Write-FKReportLine ""
    Write-OK "Complete. No changes made."
}
catch {
    Write-FKReportLine ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Offer-FKDesktopReport -Title 'GET-MAILBOX-SECURITY-SNAPSHOT'

    Pause-End
}
