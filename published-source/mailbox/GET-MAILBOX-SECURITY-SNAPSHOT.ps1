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


function Write-OK   { param($m) Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "[INFO] $m" }
function Write-Warn { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Write-Host "Press Enter to EXIT" -NoNewline

    try {
        do {
            $key = $Host.UI.RawUI.ReadKey(
                "NoEcho,IncludeKeyDown"
            )
        }
        until ($key.VirtualKeyCode -eq 13)

        Write-Host ""
    }
    catch {
        Write-Host ""
        Read-Host "Press Enter to EXIT" | Out-Null
    }
}

function Write-Section {
    param([string]$Title)

    Write-Host $Title
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

    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Write-Info "Installing $Name..."

        Install-Module `
            -Name $Name `
            -Scope CurrentUser `
            -Force `
            -AllowClobber `
            -ErrorAction Stop
    }

    Import-Module $Name -ErrorAction Stop

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
            Get-OrganizationConfig -ErrorAction Stop | Out-Null
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

    Write-Host "Exchange Online: Connecting..."

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

    Write-Host ("Rule: {0}" -f $name)
    Write-Host ("Action: {0}" -f (Rule-Detail $Rule))
}

try {
    Write-Host "MAILBOX SNAPSHOT"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

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
        -ErrorAction Stop

    $dataGaps = @()

    Write-Host ""
    Write-Section "MAILBOX"
    Write-Host (
        "User: {0} <{1}>" -f
        $mailbox.DisplayName,
        $mailbox.PrimarySmtpAddress
    )
    Write-Host ("Type: {0}" -f $mailbox.RecipientTypeDetails)

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
                -ErrorAction Stop
        }
        else {
            throw "Mailbox statistics command unavailable."
        }

        if ($stats -and $stats.LastLogonTime) {
            $lastLogon = [datetime]$stats.LastLogonTime
            $ageDays = [int]((Get-Date) - $lastLogon).TotalDays

            Write-Host (
                "Last Logon: {0} ({1} days ago)" -f
                $lastLogon.ToLocalTime().ToString("yyyy-MM-dd HH:mm"),
                $ageDays
            )
        }
        else {
            Write-Host "Last Logon: Not available"
            $dataGaps += "Mailbox statistics returned no LastLogonTime."
        }
    }
    catch {
        Write-Host "Last Logon: Not available"
        $dataGaps += "Mailbox activity: $(Get-ShortError $_)"
    }


    Write-Host ""
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
                -ErrorAction Stop

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
        Write-Host "Status: No"
    }
    else {
        Write-Host "Status: Yes"

        foreach ($target in $forwardingTargets) {
            Write-Host ("Target: {0}" -f $target)
        }

        Write-Host (
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
                    -ErrorAction Stop
            )

            $hiddenRuleCoverage = $true
            $ruleQueryAvailable = $true
        }
        catch {
            $hiddenError = Get-ShortError $_

            $rules = @(
                Get-InboxRule `
                    -Mailbox $mailbox.PrimarySmtpAddress `
                    -ErrorAction Stop
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

    Write-Host ""
    Write-Section "INBOX RULES"

    if (-not $ruleQueryAvailable) {
        Write-Host "Status: Not available"
    }
    elseif ($visibleRules.Count -eq 0) {
        Write-Host "Status: No"
    }
    else {
        Write-Host "Status: Yes"

        for ($index = 0; $index -lt $visibleRules.Count; $index++) {
            if ($index -gt 0) {
                Write-Host ""
            }

            Show-InboxRule $visibleRules[$index]
        }
    }

    Write-Host ""
    Write-Section "HIDDEN INBOX RULES"

    if (-not $ruleQueryAvailable -or -not $hiddenRuleCoverage) {
        Write-Host "Status: Not available"
    }
    elseif ($hiddenRules.Count -eq 0) {
        Write-Host "Status: No"
    }
    else {
        Write-Host "Status: Yes"

        for ($index = 0; $index -lt $hiddenRules.Count; $index++) {
            if ($index -gt 0) {
                Write-Host ""
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
                -ErrorAction Stop |
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
                -ErrorAction Stop |
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
                    -ErrorAction Stop

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

    Write-Host ""
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
        Write-Host "Status: Yes"
    }
    elseif ($permissionCoverageComplete) {
        Write-Host "Status: No"
    }
    else {
        Write-Host "Status: Review"
    }

    if ($fullAccessAvailable) {
        if ($fullAccess.Count -gt 0) {
            Write-Host ("Full Access: {0}" -f ($fullAccess -join "; "))
        }
        else {
            Write-Host "Full Access: No"
        }
    }
    else {
        Write-Host "Full Access: Not available"
    }

    if ($sendAsAvailable) {
        if ($sendAs.Count -gt 0) {
            Write-Host ("Send As: {0}" -f ($sendAs -join "; "))
        }
        else {
            Write-Host "Send As: No"
        }
    }
    else {
        Write-Host "Send As: Not available"
    }

    if ($sendOnBehalfAvailable) {
        if ($sendOnBehalfDisplay.Count -gt 0) {
            Write-Host (
                "Send On Behalf: {0}" -f
                ($sendOnBehalfDisplay -join "; ")
            )
        }
        else {
            Write-Host "Send On Behalf: No"
        }
    }
    else {
        Write-Host "Send On Behalf: Not available"
    }


    Write-Host ""
    Write-Section "LEGACY AUTH"

    try {
        $cas = Get-CASMailbox `
            -Identity $mailbox.Identity `
            -ErrorAction Stop

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
            Write-Host "Status: No"
        }
        else {
            Write-Host "Status: Yes"
            $legacy | ForEach-Object { Write-Host $_ }
        }
    }
    catch {
        Write-Host "Status: Not available"
        $dataGaps += "Legacy authentication: $(Get-ShortError $_)"
    }

    Write-Host ""
    Write-Section "DATA GAPS"

    $uniqueDataGaps = @(
        $dataGaps |
        Select-Object -Unique
    )

    if ($uniqueDataGaps.Count -eq 0) {
        Write-Host "Status: No"
    }
    else {
        Write-Host "Status: Yes"
        $uniqueDataGaps | ForEach-Object { Write-Host ("- {0}" -f $_) }
    }

    Write-Host ""
    Write-OK "Complete. No changes made."
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
