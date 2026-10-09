<#
ENFORCE LITIGATION HOLD

OBJECTIVE
Review one or more Exchange Online mailboxes from direct input or TXT/CSV and enforce
Litigation Hold with Unlimited duration.

COMPLIANT STATE
LitigationHoldEnabled  : True
LitigationHoldDuration : Unlimited

CHANGES
Changes may be made. Typed confirmation is required.

RUN
Right-click > Run with PowerShell
or
Right-click > Run with PowerShell 7
#>

param(
    [Alias("UPN","Mailbox")]
    [string[]]$InputObject,
    [string]$InputPath,
    [string]$TicketNumber,
    [string]$HoldOwner
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

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Confirm-Yes {
    param([string]$Prompt)

    return (
        (Read-Host "$Prompt [Y/N]").Trim().ToUpperInvariant() -eq "Y"
    )
}

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    Write-Warn $Prompt
    $answer = Read-Host "Type $Required to continue"

    return (
        -not [string]::IsNullOrWhiteSpace($answer) -and
        $answer.Trim().ToUpperInvariant() -eq $Required.ToUpperInvariant()
    )
}

function Get-InputUPNs {
    param(
        [string[]]$Values,
        [string]$Path
    )

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($Path) { $rawValues += $Path }

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "Mailbox UPN or TXT/CSV path").Trim().Trim('"').Trim("'")
        if ($entered) { $rawValues=@($entered) }
    }

    foreach ($value in $rawValues) {
        $clean=[Environment]::ExpandEnvironmentVariables(([string]$value).Trim().Trim('"').Trim("'"))
        if (-not $clean) { continue }

        if (-not [System.IO.Path]::GetExtension($clean)) {
            foreach ($candidatePath in @("$clean.txt","$clean.csv")) {
                if (Test-Path -LiteralPath $candidatePath -PathType Leaf) {
                    $clean=$candidatePath
                    break
                }
            }
        }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            $resolved=(Resolve-Path -LiteralPath $clean -ErrorAction Stop).Path
            Write-OK "Input file found"
            Write-Host ("Path    : {0}" -f $resolved)
            $extension=[System.IO.Path]::GetExtension($resolved).ToLowerInvariant()

            if ($extension -eq ".txt") {
                foreach ($line in @(Get-Content -LiteralPath $resolved -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"').Trim("'")
                    if ($candidate -and $candidate -notmatch "^#") { [void]$items.Add($candidate) }
                }
            }
            elseif ($extension -eq ".csv") {
                $rows=@(Import-Csv -LiteralPath $resolved -ErrorAction Stop)
                if ($rows.Count -eq 0) { throw "CSV contains no data rows." }

                foreach ($row in $rows) {
                    $candidate=$null
                    foreach ($name in @("UPN","UserPrincipalName","Email","Mail","Address","Mailbox","Input")) {
                        if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                            $candidate=[string]$row.$name
                            break
                        }
                    }
                    if (-not $candidate) {
                        $first=$row.PSObject.Properties | Select-Object -First 1
                        if ($first) { $candidate=[string]$first.Value }
                    }
                    if ($candidate -and $candidate.Trim()) {
                        [void]$items.Add($candidate.Trim().Trim('"').Trim("'"))
                    }
                }
            }
            else {
                throw "Only direct UPN, TXT, and CSV input are supported."
            }

            continue
        }

        foreach ($candidate in @($clean -split "\s*,\s*")) {
            if ($candidate) { [void]$items.Add($candidate.Trim()) }
        }
    }

    $upns=@($items | Where-Object { $_ } | Select-Object -Unique)
    if ($upns.Count -eq 0) { throw "No mailbox UPNs were provided." }

    foreach ($upn in $upns) {
        if ($upn -notmatch '^[^@\s]+@[^@\s]+$') { throw "Invalid mailbox UPN: $upn" }
    }

    return $upns
}

function Get-OneTenantDomain {
    param([string[]]$UPNs)

    $domains = @(
        $UPNs |
        ForEach-Object {
            ($_ -split "@", 2)[1].ToLowerInvariant()
        } |
        Sort-Object -Unique
    )

    if ($domains.Count -ne 1) {
        throw "Run one Microsoft 365 tenant/domain at a time."
    }

    return $domains[0]
}

function Ensure-ExchangeModule {
    $module=Get-Module -ListAvailable -Name ExchangeOnlineManagement -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "ExchangeOnlineManagement is required but is not installed. Install with: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop

    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
        throw "ExchangeOnlineManagement loaded, but Connect-ExchangeOnline is unavailable."
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
        $command.Parameters.ContainsKey("DelegatedOrganization")
    ) {
        $parameters["DelegatedOrganization"] = $TargetDomain
    }

    Connect-ExchangeOnline @parameters | Out-Null
}

function Connect-ExchangeAuto {
    param(
        [string]$TargetDomain
    )

    Ensure-ExchangeModule

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

            $errors += "Connected, but the expected tenant/target did not validate."
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

function Test-UnlimitedDuration {
    param([object]$Duration)

    if ($null -eq $Duration) {
        return $false
    }

    return (
        ([string]$Duration).Trim().Equals(
            "Unlimited",
            [System.StringComparison]::OrdinalIgnoreCase
        )
    )
}

function Get-HoldState {
    param([string]$UPN)

    $mailbox = Get-Mailbox `
        -Identity $UPN `
        -ErrorAction Stop

    $enabled = [bool]$mailbox.LitigationHoldEnabled
    $durationText = [string]$mailbox.LitigationHoldDuration
    $unlimited = Test-UnlimitedDuration -Duration $mailbox.LitigationHoldDuration

    $action = if (-not $enabled) {
        "EnableUnlimited"
    }
    elseif (-not $unlimited) {
        "SetUnlimited"
    }
    else {
        "Compliant"
    }

    return [PSCustomObject]@{
        Mailbox     = $mailbox
        UPN         = $UPN
        DisplayName = [string]$mailbox.DisplayName
        Enabled     = $enabled
        Duration    = $durationText
        HoldOwner   = [string]$mailbox.LitigationHoldOwner
        Unlimited   = $unlimited
        Action      = $action
    }
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

    $desktop = [Environment]::GetFolderPath("Desktop")

    if ([string]::IsNullOrWhiteSpace($desktop)) {
        $desktop = Join-Path $env:USERPROFILE "Desktop"
    }

    $defaultPath = Join-Path $desktop $DefaultName
    $path = Read-Host "Enter CSV path or press Enter to save to Desktop"

    if ([string]::IsNullOrWhiteSpace($path)) {
        $path = $defaultPath
    }
    else {
        $path = [Environment]::ExpandEnvironmentVariables(
            $path.Trim().Trim('"').Trim("'")
        )
    }

    $parent = Split-Path -Parent $path

    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        throw "CSV output folder was not found: $parent"
    }

    $Rows |
        Export-Csv `
            -LiteralPath $path `
            -NoTypeInformation `
            -Encoding UTF8 `
            -Force `
            -ErrorAction Stop

    $check = @(Import-Csv -LiteralPath $path -ErrorAction Stop)

    if ($check.Count -ne $Rows.Count) {
        throw "CSV verification failed."
    }

    Write-OK "CSV export saved"
    Write-Host ("Path    : {0}" -f $path)
}

try {
    Write-Host "ENFORCE LITIGATION HOLD"
    Write-Host "CHANGES MAY BE MADE."
    Write-Host "Target state: Litigation Hold enabled with Unlimited duration."
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($TicketNumber)) {
        $TicketNumber = (Read-Host "Ticket number").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($HoldOwner)) {
        $HoldOwner = (
            Read-Host "Hold owner / requestor [blank for operator]"
        ).Trim()

        if ([string]::IsNullOrWhiteSpace($HoldOwner)) {
            $HoldOwner = "$env:USERDOMAIN\$env:USERNAME"
        }
    }

    $upns = @(Get-InputUPNs -Values $InputObject -Path $InputPath)
    $tenantDomain = Get-OneTenantDomain -UPNs $upns

    Write-Host ""
    Write-Section "CONNECT"

    Connect-ExchangeAuto `
        -TargetDomain $tenantDomain

    Write-Host ""
    Write-Section "PREVIEW"

    $rows = @()

    foreach ($upn in $upns) {
        Write-Info "Reviewing mailbox: $upn"

        try {
            $state = Get-HoldState -UPN $upn

            $rows += [PSCustomObject]@{
                UPN             = $state.UPN
                DisplayName     = $state.DisplayName
                CurrentHold     = $state.Enabled
                CurrentDuration = $state.Duration
                CurrentOwner    = $state.HoldOwner
                Action          = $state.Action
                Result          = "Pending"
                FinalHold       = ""
                FinalDuration   = ""
                FinalOwner      = ""
                Detail          = ""
            }
        }
        catch {
            $errorText = Get-ShortError $_

            Write-Warn ("Mailbox review failed: {0}" -f $upn)

            $rows += [PSCustomObject]@{
                UPN             = $upn
                DisplayName     = ""
                CurrentHold     = ""
                CurrentDuration = ""
                CurrentOwner    = ""
                Action          = "ReviewUnavailable"
                Result          = "Failed"
                FinalHold       = ""
                FinalDuration   = ""
                FinalOwner      = ""
                Detail          = $errorText
            }
        }
    }

    $toEnable = @(
        $rows |
        Where-Object { $_.Action -eq "EnableUnlimited" }
    )

    $toCorrect = @(
        $rows |
        Where-Object { $_.Action -eq "SetUnlimited" }
    )

    $compliant = @(
        $rows |
        Where-Object { $_.Action -eq "Compliant" }
    )

    $toChange = @($toEnable + $toCorrect)

    foreach ($row in $compliant) {
        $row.Result = "AlreadyCompliant"
        $row.FinalHold = $row.CurrentHold
        $row.FinalDuration = $row.CurrentDuration
        $row.FinalOwner = $row.CurrentOwner
        $row.Detail = "No change required"
    }

    Write-Host ""
    Write-Host ("Tenant            : {0}" -f $tenantDomain)
    Write-Host ("Ticket            : {0}" -f $TicketNumber)
    Write-Host ("Hold owner        : {0}" -f $HoldOwner)
    Write-Host ("Input users       : {0}" -f $upns.Count)
    Write-Host ("Enable Unlimited  : {0}" -f $toEnable.Count)
    Write-Host ("Correct to Unlimited: {0}" -f $toCorrect.Count)
    Write-Host ("Already compliant : {0}" -f $compliant.Count)
    Write-Host ("Review failed     : {0}" -f @($rows | Where-Object { $_.Result -eq "Failed" }).Count)

    Write-Host ""

    foreach ($row in $rows) {
        switch ($row.Action) {
            "EnableUnlimited" {
                Write-Warn (
                    "{0} | hold disabled -> enable Unlimited" -f
                    $row.UPN
                )
            }
            "SetUnlimited" {
                Write-Warn (
                    "{0} | hold enabled, duration {1} -> Unlimited" -f
                    $row.UPN,
                    $row.CurrentDuration
                )
            }
            "Compliant" {
                Write-OK (
                    "{0} | already compliant | Unlimited" -f
                    $row.UPN
                )
            }
            default {
                Write-Warn (
                    "{0} | review unavailable | {1}" -f
                    $row.UPN,
                    $row.Detail
                )
            }
        }
    }

    if ($toChange.Count -eq 0) {
        Write-Host ""
        Write-OK "No Litigation Hold changes needed"

        Offer-ExportCsv `
            -Rows $rows `
            -DefaultName (
                "litigation-hold-review-{0}.csv" -f
                (Get-Date -Format "yyyyMMdd-HHmmss")
            )

        return
    }

    if (-not (Confirm-Type `
        -Prompt (
            "This will enforce Unlimited Litigation Hold on {0} mailbox(es)." -f
            $toChange.Count
        ) `
        -Required "HOLD")) {
        Write-Warn "Cancelled by operator."
        return
    }

    Write-Host ""
    Write-Section "ENFORCE"

    foreach ($row in $toChange) {
        try {
            if ($row.Action -eq "EnableUnlimited") {
                Set-Mailbox `
                    -Identity $row.UPN `
                    -LitigationHoldEnabled $true `
                    -LitigationHoldDuration Unlimited `
                    -LitigationHoldOwner $HoldOwner `
                    -ErrorAction Stop
            }
            elseif ($row.Action -eq "SetUnlimited") {
                Set-Mailbox `
                    -Identity $row.UPN `
                    -LitigationHoldDuration Unlimited `
                    -ErrorAction Stop
            }
            else {
                throw "Unsupported enforcement action: $($row.Action)"
            }

            $verify = Get-HoldState -UPN $row.UPN

            $row.FinalHold = $verify.Enabled
            $row.FinalDuration = $verify.Duration
            $row.FinalOwner = $verify.HoldOwner

            if (
                $verify.Enabled -eq $true -and
                $verify.Unlimited -eq $true
            ) {
                $row.Result = "Complete"
                $row.Detail = "Litigation Hold enabled with Unlimited duration"
                Write-OK ("Verified Unlimited hold: {0}" -f $row.UPN)
            }
            else {
                $row.Result = "Failed"
                $row.Detail = (
                    "Post-change validation did not show Enabled=True and Duration=Unlimited"
                )
                Write-Warn ("Validation failed: {0}" -f $row.UPN)
            }
        }
        catch {
            $row.Result = "Failed"
            $row.Detail = Get-ShortError $_
            Write-Warn ("Failed: {0}" -f $row.UPN)
        }
    }

    Write-Host ""
    Write-Section "VALIDATION"

    Write-Host ("Complete          : {0}" -f @($rows | Where-Object { $_.Result -eq "Complete" }).Count)
    Write-Host ("Already compliant : {0}" -f @($rows | Where-Object { $_.Result -eq "AlreadyCompliant" }).Count)
    Write-Host ("Failed            : {0}" -f @($rows | Where-Object { $_.Result -eq "Failed" }).Count)

    Write-Host ""
    Write-Section "TICKET SUMMARY"

    Write-Host "LITIGATION HOLD SUMMARY"
    Write-Host ("Ticket            : {0}" -f $TicketNumber)
    Write-Host ("Hold owner        : {0}" -f $HoldOwner)
    Write-Host ("Operator          : {0}\{1}" -f $env:USERDOMAIN, $env:USERNAME)
    Write-Host ("Timestamp         : {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    Write-Host ("Input users       : {0}" -f $upns.Count)
    Write-Host ("Enabled Unlimited : {0}" -f @($rows | Where-Object { $_.Action -eq "EnableUnlimited" -and $_.Result -eq "Complete" }).Count)
    Write-Host ("Corrected Unlimited: {0}" -f @($rows | Where-Object { $_.Action -eq "SetUnlimited" -and $_.Result -eq "Complete" }).Count)
    Write-Host ("Already compliant : {0}" -f @($rows | Where-Object { $_.Result -eq "AlreadyCompliant" }).Count)
    Write-Host ("Failed            : {0}" -f @($rows | Where-Object { $_.Result -eq "Failed" }).Count)

    Offer-ExportCsv `
        -Rows $rows `
        -DefaultName (
            "litigation-hold-{0}-{1}.csv" -f
            $TicketNumber,
            (Get-Date -Format "yyyyMMdd-HHmmss")
        )

    Write-Host ""
    Write-Host "STANDARD NOTE"
    Write-Host "Changed mailboxes were re-read and validated for LitigationHoldEnabled=True and LitigationHoldDuration=Unlimited."
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}

