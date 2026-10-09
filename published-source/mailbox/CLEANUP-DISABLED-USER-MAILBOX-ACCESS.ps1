<#
CLEANUP DISABLED USER MAILBOX ACCESS

OBJECTIVE
Find and optionally remove Full Access, Send As, and Send On Behalf permissions
held by one disabled/departing user on other Exchange Online recipients.

INPUT
One UPN.

CHANGES
Changes may be made. Disabled-state validation and confirmation are required.
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

function Invoke-GraphGet {
    param([string]$Uri)

    $command = Get-Command Invoke-MgGraphRequest -ErrorAction Stop
    $parameters = @{
        Method      = "GET"
        Uri         = $Uri
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("OutputType")) {
        $parameters["OutputType"] = "PSObject"
    }

    return Invoke-MgGraphRequest @parameters
}

function Invoke-GraphDelete {
    param([string]$Uri)

    Invoke-MgGraphRequest `
        -Method DELETE `
        -Uri $Uri `
        -ErrorAction Stop |
        Out-Null
}

function Get-GraphTenantInfo {
    try {
        $response = Invoke-GraphGet `
            -Uri "https://graph.microsoft.com/v1.0/organization?`$select=displayName,verifiedDomains"

        $organization = @($response.value) | Select-Object -First 1

        if (-not $organization) {
            return $null
        }

        return [PSCustomObject]@{
            DisplayName = [string]$organization.displayName
            Domains = @(
                $organization.verifiedDomains |
                ForEach-Object { [string]$_.name } |
                Where-Object { $_ }
            )
        }
    }
    catch {
        return $null
    }
}

function Test-GraphScopes {
    param(
        $Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) {
        return $false
    }

    foreach ($scope in $RequiredScopes) {
        if (@($Context.Scopes) -notcontains $scope) {
            return $false
        }
    }

    return $true
}

function Test-GraphTarget {
    param([string]$UPN)

    try {
        $encoded = [System.Uri]::EscapeDataString($UPN)

        Invoke-GraphGet `
            -Uri ("https://graph.microsoft.com/v1.0/users/{0}?`$select=id" -f $encoded) |
            Out-Null

        return $true
    }
    catch {
        return $false
    }
}

function Connect-GraphAuto {
    param(
        [string[]]$Scopes,
        [string]$TargetDomain,
        [string]$ValidationUPN
    )

    Ensure-Module `
        -Name "Microsoft.Graph.Authentication" `
        -Command "Connect-MgGraph"

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-GraphScopes -Context $context -RequiredScopes $Scopes) -and
        (Test-GraphTarget -UPN $ValidationUPN)
    ) {
        $tenant = Get-GraphTenantInfo

        if (
            $tenant -and
            (
                [string]::IsNullOrWhiteSpace($TargetDomain) -or
                $tenant.Domains -contains $TargetDomain
            )
        ) {
            Write-OK "Graph session reused"
            return $tenant
        }
    }

    if ($context) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
        }
    }

    Write-Host "Graph: Connecting..."

    $command = Get-Command Connect-MgGraph -ErrorAction Stop
    $parameters = @{
        Scopes      = $Scopes
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ContextScope")) {
        $parameters["ContextScope"] = "Process"
    }

    if ($command.Parameters.ContainsKey("NoWelcome")) {
        $parameters["NoWelcome"] = $true
    }

    if (
        -not [string]::IsNullOrWhiteSpace($TargetDomain) -and
        $command.Parameters.ContainsKey("TenantId")
    ) {
        $parameters["TenantId"] = $TargetDomain
    }

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop

    if (-not (Test-GraphScopes -Context $context -RequiredScopes $Scopes)) {
        throw "The Graph token is missing one or more required delegated scopes."
    }

    if (-not (Test-GraphTarget -UPN $ValidationUPN)) {
        throw "The target user did not resolve in the connected Graph tenant."
    }

    $tenant = Get-GraphTenantInfo

    if (-not $tenant) {
        throw "Graph connected, but tenant details could not be verified."
    }

    if (
        -not [string]::IsNullOrWhiteSpace($TargetDomain) -and
        $tenant.Domains -notcontains $TargetDomain
    ) {
        throw "Graph connected to the wrong tenant for domain $TargetDomain."
    }

    Write-OK "Graph connected"
    return $tenant
}

function Get-GraphUser {
    param([string]$UPN)

    $encoded = [System.Uri]::EscapeDataString($UPN)

    return Invoke-GraphGet `
        -Uri (
            "https://graph.microsoft.com/v1.0/users/{0}" +
            "?`$select=id,displayName,userPrincipalName,accountEnabled,mail," +
            "onPremisesSyncEnabled,onPremisesSamAccountName,userType"
        ) -f $encoded
}

function Get-GraphPaged {
    param([string]$Uri)

    $items = @()
    $next = $Uri

    while ($next) {
        $page = Invoke-GraphGet -Uri $next
        $items += @($page.value)
        $next = [string]$page.'@odata.nextLink'
    }

    return $items
}

function Escape-LdapFilterValue {
    param([string]$Value)

    $escaped = [string]$Value
    $escaped = $escaped.Replace('\', '\5c')
    $escaped = $escaped.Replace('*', '\2a')
    $escaped = $escaped.Replace('(', '\28')
    $escaped = $escaped.Replace(')', '\29')
    $escaped = $escaped.Replace([char]0, '\00')

    return $escaped
}

function Find-ADUser {
    param([string]$Filter)

    $searcher = New-Object System.DirectoryServices.DirectorySearcher
    $searcher.Filter = $Filter
    $searcher.PageSize = 100

    foreach ($property in @(
        "displayName",
        "userPrincipalName",
        "sAMAccountName",
        "userAccountControl",
        "distinguishedName",
        "memberOf"
    )) {
        [void]$searcher.PropertiesToLoad.Add($property)
    }

    return $searcher.FindOne()
}

function Convert-ADResult {
    param(
        $Result,
        [string]$ResolvedBy
    )

    if (-not $Result) {
        return $null
    }

    $entry = $Result.GetDirectoryEntry()
    $uac = [int]$entry.Properties["userAccountControl"].Value

    return [PSCustomObject]@{
        Path              = [string]$entry.Path
        DistinguishedName = [string]$entry.Properties["distinguishedName"].Value
        DisplayName       = [string]$entry.Properties["displayName"].Value
        UPN               = [string]$entry.Properties["userPrincipalName"].Value
        SamAccountName    = [string]$entry.Properties["sAMAccountName"].Value
        Disabled          = (($uac -band 2) -ne 0)
        MemberOf          = @($entry.Properties["memberOf"] | ForEach-Object { [string]$_ })
        ResolvedBy        = $ResolvedBy
    }
}

function Resolve-ADUser {
    param($GraphUser)

    $upn = [string]$GraphUser.userPrincipalName
    $samHint = [string]$GraphUser.onPremisesSamAccountName

    if ($samHint) {
        $safe = Escape-LdapFilterValue $samHint
        $result = Find-ADUser `
            -Filter "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$safe))"

        if ($result) {
            return Convert-ADResult `
                -Result $result `
                -ResolvedBy "Graph onPremisesSamAccountName"
        }
    }

    $safeUpn = Escape-LdapFilterValue $upn

    $result = Find-ADUser `
        -Filter "(&(objectCategory=person)(objectClass=user)(userPrincipalName=$safeUpn))"

    if ($result) {
        return Convert-ADResult -Result $result -ResolvedBy "userPrincipalName"
    }

    $result = Find-ADUser `
        -Filter "(&(objectCategory=person)(objectClass=user)(mail=$safeUpn))"

    if ($result) {
        return Convert-ADResult -Result $result -ResolvedBy "mail"
    }

    $result = Find-ADUser `
        -Filter "(&(objectCategory=person)(objectClass=user)(|(proxyAddresses=SMTP:$safeUpn)(proxyAddresses=smtp:$safeUpn)))"

    if ($result) {
        return Convert-ADResult -Result $result -ResolvedBy "proxyAddresses"
    }

    $fallback = ($upn -split "@", 2)[0]

    if ($fallback) {
        $safeFallback = Escape-LdapFilterValue $fallback
        $result = Find-ADUser `
            -Filter "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$safeFallback))"

        if ($result) {
            return Convert-ADResult `
                -Result $result `
                -ResolvedBy "sAMAccountName fallback"
        }
    }

    return $null
}

function Get-CnFromDn {
    param([string]$DN)

    if ($DN -match '^CN=((?:\\.|[^,])+)') {
        return ($Matches[1] -replace '\\,', ',')
    }

    return $DN
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

function Normalize-PrincipalValue {
    param([object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    $text = ([string]$Value).Trim()

    if ([string]::IsNullOrWhiteSpace($text)) {
        return ""
    }

    if ($text -match '^(?i:smtp:)(.+)$') {
        $text = $Matches[1]
    }

    return $text.ToLowerInvariant()
}

function Add-TargetPrincipalAlias {
    param(
        [hashtable]$Set,
        [object]$Value
    )

    $normalized = Normalize-PrincipalValue $Value

    if ($normalized) {
        $Set[$normalized] = $true
    }
}

function Add-TargetPrincipalObject {
    param(
        [hashtable]$Set,
        [object]$Principal
    )

    if ($null -eq $Principal) {
        return
    }

    Add-TargetPrincipalAlias -Set $Set -Value ([string]$Principal)

    foreach ($property in @(
        "PrimarySmtpAddress",
        "WindowsEmailAddress",
        "UserPrincipalName",
        "ExternalDirectoryObjectId",
        "Guid",
        "DistinguishedName",
        "LegacyExchangeDN",
        "Alias",
        "SamAccountName"
    )) {
        if ($Principal.PSObject.Properties.Name -contains $property) {
            Add-TargetPrincipalAlias `
                -Set $Set `
                -Value $Principal.$property
        }
    }
}

function New-TargetPrincipalSet {
    param(
        $GraphUser,
        $ADUser,
        [string]$UPN
    )

    $set = @{}

    Add-TargetPrincipalAlias -Set $set -Value $UPN

    if ($GraphUser) {
        Add-TargetPrincipalAlias -Set $set -Value $GraphUser.userPrincipalName
        Add-TargetPrincipalAlias -Set $set -Value $GraphUser.mail
        Add-TargetPrincipalAlias -Set $set -Value $GraphUser.id
        Add-TargetPrincipalAlias -Set $set -Value $GraphUser.onPremisesSamAccountName
    }

    if ($ADUser) {
        Add-TargetPrincipalAlias -Set $set -Value $ADUser.UPN
        Add-TargetPrincipalAlias -Set $set -Value $ADUser.SamAccountName
    }

    if (Get-Command Get-Recipient -ErrorAction SilentlyContinue) {
        try {
            $recipient = Get-Recipient `
                -Identity $UPN `
                -ErrorAction Stop

            Add-TargetPrincipalObject `
                -Set $set `
                -Principal $recipient
        }
        catch {
            Write-Warn (
                "Exchange principal alias expansion unavailable: {0}" -f
                (Get-ShortError $_)
            )
        }
    }

    return $set
}

function Test-PrincipalMatchesTarget {
    param(
        [object]$Principal,
        [hashtable]$TargetSet
    )

    if ($null -eq $Principal) {
        return $false
    }

    $candidates = @([string]$Principal)

    foreach ($property in @(
        "PrimarySmtpAddress",
        "WindowsEmailAddress",
        "UserPrincipalName",
        "ExternalDirectoryObjectId",
        "Guid",
        "DistinguishedName",
        "LegacyExchangeDN",
        "Alias",
        "SamAccountName"
    )) {
        if ($Principal.PSObject.Properties.Name -contains $property) {
            $candidates += [string]$Principal.$property
        }
    }

    foreach ($candidate in $candidates) {
        $normalized = Normalize-PrincipalValue $candidate

        if ($normalized -and $TargetSet.ContainsKey($normalized)) {
            return $true
        }
    }

    return $false
}

function Get-SendOnBehalfMatch {
    param(
        $Mailbox,
        [hashtable]$TargetSet
    )

    return @(
        @($Mailbox.GrantSendOnBehalfTo) |
        Where-Object {
            Test-PrincipalMatchesTarget `
                -Principal $_ `
                -TargetSet $TargetSet
        }
    )
}

function Get-FullAccessPermission {
    param(
        $Mailbox,
        [hashtable]$TargetSet
    )

    $permissions = @(
        Get-MailboxPermission `
            -Identity $Mailbox.Identity `
            -ErrorAction Stop
    )

    return @(
        $permissions |
        Where-Object {
            $_.User -ne "NT AUTHORITY\SELF" -and
            $_.IsInherited -eq $false -and
            $_.Deny -eq $false -and
            $_.AccessRights -contains "FullAccess" -and
            (
                Test-PrincipalMatchesTarget `
                    -Principal $_.User `
                    -TargetSet $TargetSet
            )
        }
    )
}

function Get-SendAsPermission {
    param(
        $Recipient,
        [hashtable]$TargetSet
    )

    $permissions = @(
        Get-RecipientPermission `
            -Identity $Recipient.Identity `
            -ErrorAction Stop
    )

    return @(
        $permissions |
        Where-Object {
            $_.Trustee -ne "NT AUTHORITY\SELF" -and
            $_.IsInherited -eq $false -and
            $_.Deny -eq $false -and
            $_.AccessRights -contains "SendAs" -and
            (
                Test-PrincipalMatchesTarget `
                    -Principal $_.Trustee `                    -TargetSet $TargetSet
            )
        }
    )
}

try {
    Write-Host "DISABLED USER MAILBOX ACCESS CLEANUP"
    Write-Host "CHANGES MAY BE MADE."
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        $UPN = (Read-Host "UPN").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        throw "UPN is required."
    }

    $targetDomain = ($UPN -split "@", 2)[1].ToLowerInvariant()

    $tenant = Connect-GraphAuto `
        -Scopes @(
            "User.Read.All",
            "Directory.Read.All"
        ) `
        -TargetDomain $targetDomain `
        -ValidationUPN $UPN

    $user = Get-GraphUser -UPN $UPN
    $accountSource = if ($user.onPremisesSyncEnabled -eq $true) { "Active Directory" } else { "Entra ID" }
    $adUser = $null
    $authoritativeDisabled = $false

    if ($accountSource -eq "Active Directory") {
        try {
            $adUser = Resolve-ADUser -GraphUser $user
        }
        catch {
            throw "Active Directory lookup failed: $(Get-ShortError $_)"
        }

        if (-not $adUser) {
            throw "Synced user could not be resolved in Active Directory."
        }

        $authoritativeDisabled = $adUser.Disabled
    }
    else {
        $authoritativeDisabled = ($user.accountEnabled -eq $false)
    }

    Write-Host ""
    Write-Section "TARGET"
    Write-Host ("Tenant         : {0}" -f $tenant.DisplayName)
    Write-Host ("Name           : {0}" -f $user.displayName)
    Write-Host ("UPN            : {0}" -f $user.userPrincipalName)
    Write-Host ("Account Source : {0}" -f $accountSource)
    Write-Host ("Status         : {0}" -f $(if ($authoritativeDisabled) { "Disabled" } else { "Enabled" }))

    if (-not $authoritativeDisabled) {
        throw "Target is not disabled at the authoritative identity source. No mailbox permission cleanup was performed."
    }

    Connect-ExchangeAuto -TargetDomain $targetDomain

    $targetPrincipalSet = New-TargetPrincipalSet `
        -GraphUser $user `
        -ADUser $adUser `
        -UPN $UPN

    $dataGaps = @()
    $findings = @()

    Write-Host ""
    Write-Info "Scanning Exchange recipients for direct Full Access, Send As, and Send On Behalf permissions..."

    $mailboxes = @(
        Get-Mailbox `
            -ResultSize Unlimited `
            -ErrorAction Stop
    )

    foreach ($mailbox in $mailboxes) {
        try {
            $full = @(
                Get-FullAccessPermission `
                    -Mailbox $mailbox `
                    -TargetSet $targetPrincipalSet
            )

            foreach ($permission in $full) {
                $findings += [PSCustomObject]@{
                    Type      = "Full Access"
                    Name      = [string]$mailbox.DisplayName
                    Address   = [string]$mailbox.PrimarySmtpAddress
                    Identity  = $mailbox.Identity
                    Principal = $permission.User
                }
            }
        }
        catch {
            $dataGaps += "Full Access query for $($mailbox.PrimarySmtpAddress): $(Get-ShortError $_)"
        }

        try {
            $sendAs = @(
                Get-SendAsPermission `
                    -Recipient $mailbox `
                    -TargetSet $targetPrincipalSet
            )

            foreach ($permission in $sendAs) {
                $findings += [PSCustomObject]@{
                    Type      = "Send As"
                    Name      = [string]$mailbox.DisplayName
                    Address   = [string]$mailbox.PrimarySmtpAddress
                    Identity  = $mailbox.Identity
                    Principal = $permission.Trustee
                }
            }
        }
        catch {
            $dataGaps += "Send As query for $($mailbox.PrimarySmtpAddress): $(Get-ShortError $_)"
        }

        try {
            $sendOnBehalf = @(
                Get-SendOnBehalfMatch `
                    -Mailbox $mailbox `
                    -TargetSet $targetPrincipalSet
            )

            foreach ($delegate in $sendOnBehalf) {
                $findings += [PSCustomObject]@{
                    Type      = "Send On Behalf"
                    Name      = [string]$mailbox.DisplayName
                    Address   = [string]$mailbox.PrimarySmtpAddress
                    Identity  = $mailbox.Identity
                    Principal = $delegate
                }
            }
        }
        catch {
            $dataGaps += "Send On Behalf query for $($mailbox.PrimarySmtpAddress): $(Get-ShortError $_)"
        }
    }

    Write-Host ""
    Write-Section "MAILBOX ACCESS DEBT"

    if ($findings.Count -eq 0) {
        Write-Host "  none found"
    }
    else {
        for ($i = 0; $i -lt $findings.Count; $i++) {
            Write-Host (
                "[{0}] {1} | {2} <{3}>" -f
                ($i + 1),
                $findings[$i].Type,
                $findings[$i].Name,
                $findings[$i].Address
            )
        }
    }

    Write-Host ""
    Write-Section "DATA GAPS"

    if ($dataGaps.Count -eq 0) {
        Write-Host "  none identified"
    }
    else {
        $uniqueGaps = @($dataGaps | Select-Object -Unique)

        Write-Host ("Count: {0}" -f $uniqueGaps.Count)

        $uniqueGaps |
            Select-Object -First 10 |
            ForEach-Object { Write-Host "  - $_" }

        if ($uniqueGaps.Count -gt 10) {
            Write-Host ("  - ... {0} additional query gap(s)" -f ($uniqueGaps.Count - 10))
        }
    }

    $selected = @()

    if ($findings.Count -gt 0) {
        Write-Host ""
        Write-Host "[A] Remove all listed permissions"
        Write-Host "[I] Review individually"
        Write-Host "[N] No changes"

        $choice = (Read-Host "Choose").Trim().ToUpperInvariant()

        if ($choice -eq "A") {
            $selected = @($findings)
        }
        elseif ($choice -eq "I") {
            foreach ($finding in $findings) {
                if (Confirm-Yes "Remove $($finding.Type) on $($finding.Address)") {
                    $selected += $finding
                }
            }
        }
    }

    $completed = @()
    $failed = @()

    if ($selected.Count -gt 0) {
        if (-not (Confirm-Type `
            -Prompt "Selected mailbox permissions will be removed." `
            -Required "REMOVE MAILBOX ACCESS $UPN")) {
            throw "OPERATOR_CANCELLED"
        }

        Write-Host ""
        Write-Section "ACTIONS"

        foreach ($finding in $selected) {
            try {
                if ($finding.Type -eq "Full Access") {
                    Remove-MailboxPermission `
                        -Identity $finding.Identity `
                        -User $finding.Principal `
                        -AccessRights FullAccess `
                        -Confirm:$false `
                        -ErrorAction Stop

                    $remaining = @(
                        Get-FullAccessPermission `
                            -Mailbox (Get-Mailbox -Identity $finding.Identity -ErrorAction Stop) `
                            -TargetSet $targetPrincipalSet
                    )

                    if ($remaining.Count -gt 0) {
                        throw "Full Access permission still present after removal."
                    }
                }
                elseif ($finding.Type -eq "Send As") {
                    Remove-RecipientPermission `
                        -Identity $finding.Identity `
                        -Trustee $finding.Principal `
                        -AccessRights SendAs `
                        -Confirm:$false `
                        -ErrorAction Stop

                    $remaining = @(
                        Get-SendAsPermission `
                            -Recipient (Get-Mailbox -Identity $finding.Identity -ErrorAction Stop) `
                            -TargetSet $targetPrincipalSet
                    )

                    if ($remaining.Count -gt 0) {
                        throw "Send As permission still present after removal."
                    }
                }
                elseif ($finding.Type -eq "Send On Behalf") {
                    Set-Mailbox `
                        -Identity $finding.Identity `
                        -GrantSendOnBehalfTo @{ Remove = $UPN } `
                        -ErrorAction Stop

                    $updatedMailbox = Get-Mailbox `
                        -Identity $finding.Identity `
                        -ErrorAction Stop

                    $remaining = @(
                        Get-SendOnBehalfMatch `
                            -Mailbox $updatedMailbox `
                            -TargetSet $targetPrincipalSet
                    )

                    if ($remaining.Count -gt 0) {
                        throw "Send On Behalf permission still present after removal."
                    }
                }
                else {
                    throw "Unsupported permission type: $($finding.Type)"
                }

                Write-OK ("Removed and verified: {0} | {1}" -f $finding.Type, $finding.Address)
                $completed += "$($finding.Type): $($finding.Address)"
            }
            catch {
                $detail = Get-ShortError $_
                Write-Warn ("Failed: {0} | {1} | {2}" -f $finding.Type, $finding.Address, $detail)
                $failed += "$($finding.Type): $($finding.Address) - $detail"
            }
        }
    }

    Write-Host ""
    Write-Section "VALIDATION"
    Write-Host ("Completed: {0}" -f $completed.Count)
    Write-Host ("Failed   : {0}" -f $failed.Count)

    Write-Host ""
    Write-Section "NEXT"
    Write-Host "- Continue offboarding/deletion review as needed."

    Write-Host ""
    Write-Host "STANDARD NOTE"

    if ($completed.Count -gt 0) {
        Write-Host ("CHANGES PERFORMED: {0} verified mailbox permission removal(s)." -f $completed.Count)
    }
    else {
        Write-Host "No mailbox permission changes were made."
    }
}
catch {
    Write-Host ""

    if ($_.Exception.Message -eq "OPERATOR_CANCELLED") {
        Write-Warn "Cancelled by operator."
    }
    else {
        Write-Fail (Get-ShortError $_)
    }
}
finally {
    Pause-End
}

