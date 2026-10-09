<#
MULTI MAILBOX PERMISSIONS AUDIT

OBJECTIVE
Review forwarding, mailbox delegates, and inbox rules for one or more mailboxes.

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

function Write-OK   { param($m) Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "[INFO] $m" }
function Write-Warn { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "[FAIL] $m" -ForegroundColor Red }

function Write-Section {
    param([string]$Title)

    try {
        Write-Host (" {0} " -f $Title) `
            -ForegroundColor White `
            -BackgroundColor DarkGray
    }
    catch {
        Write-Host $Title
    }
}

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
                -ErrorAction Stop |
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

    Write-Host "Exchange Online: Connecting..."

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

    Write-Host "Status : Not available"
    Write-Warn "$Label query failed: $Message"
}

try {
    Write-Host "MAILBOX PERMISSIONS AUDIT"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    $UPN=@(Get-MailboxInputs -Values $UPN)

    if (-not $UPN -or $UPN.Count -eq 0) {
        throw "At least one mailbox UPN is required."
    }

    Connect-ExchangeAuto -ValidationMailboxes $UPN

    foreach ($MailboxUPN in $UPN) {
        Write-Host ""
        Write-Host ("MAILBOX: {0}" -f $MailboxUPN)

        try {
            $Mailbox = Get-Mailbox `
                -Identity $MailboxUPN `
                -ErrorAction Stop
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
            Write-Host "  none"
        }
        else {
            $Forwarding | ForEach-Object {
                Write-Host "  - $_"
            }
        }

        Write-Host ""
        Write-Section "FULL ACCESS"

        try {
            $FullAccess = @(
                Get-MailboxPermission `
                    -Identity $Mailbox.Identity `
                    -ErrorAction Stop |
                Where-Object {
                    $_.User -ne "NT AUTHORITY\SELF" -and
                    $_.IsInherited -eq $false -and
                    $_.AccessRights -contains "FullAccess"
                }
            )

            if ($FullAccess.Count -eq 0) {
                Write-Host "  none"
            }
            else {
                $FullAccess | ForEach-Object {
                    Write-Host ("  - {0}" -f $_.User)
                }
            }
        }
        catch {
            Write-QueryFailure `
                -Label "Full Access" `
                -Message (Get-ShortError $_)
        }

        Write-Host ""
        Write-Section "SEND AS"

        try {
            $SendAs = @(
                Get-RecipientPermission `
                    -Identity $Mailbox.Identity `
                    -ErrorAction Stop |
                Where-Object {
                    $_.Trustee -ne "NT AUTHORITY\SELF" -and
                    $_.AccessRights -contains "SendAs"
                }
            )

            if ($SendAs.Count -eq 0) {
                Write-Host "  none"
            }
            else {
                $SendAs | ForEach-Object {
                    Write-Host ("  - {0}" -f $_.Trustee)
                }
            }
        }
        catch {
            Write-QueryFailure `
                -Label "Send As" `
                -Message (Get-ShortError $_)
        }

        Write-Host ""
        Write-Section "SEND ON BEHALF"

        try {
            $SendOnBehalf = @($Mailbox.GrantSendOnBehalfTo)

            if ($SendOnBehalf.Count -eq 0) {
                Write-Host "  none"
            }
            else {
                foreach ($Delegate in $SendOnBehalf) {
                    try {
                        $Recipient = Get-Recipient `
                            -Identity $Delegate `
                            -ErrorAction Stop

                        if ($Recipient.PrimarySmtpAddress) {
                            Write-Host (
                                "  - {0} <{1}>" -f
                                $Recipient.DisplayName,
                                $Recipient.PrimarySmtpAddress
                            )
                        }
                        else {
                            Write-Host ("  - {0}" -f $Recipient.DisplayName)
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

        Write-Host ""
        Write-Section "INBOX RULES"

        $RulesAvailable = $true
        $Rules = @()
        $RuleError = ""

        try {
            $Rules = @(
                Get-InboxRule `
                    -Mailbox $Mailbox.Identity `
                    -IncludeHidden `
                    -ErrorAction Stop
            )
        }
        catch {
            try {
                $Rules = @(
                    Get-InboxRule `
                        -Mailbox $Mailbox.Identity `
                        -ErrorAction Stop
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
            Write-Host "  none"
        }
        else {
            foreach ($Rule in $Rules) {
                $Hidden = ""

                if ($Rule.IsHidden) {
                    $Hidden = " [HIDDEN]"
                }

                Write-Host ("  - {0}{1}" -f (Clean-Name $Rule.Name), $Hidden)
                Write-Host ("    {0}" -f (Rule-Detail $Rule))
            }
        }
    }

    Write-Host ""
    Write-Host "STANDARD NOTE"
    Write-Host "Read-only mailbox permissions and forwarding audit. No changes were made."
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}