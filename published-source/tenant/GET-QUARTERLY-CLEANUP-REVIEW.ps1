#Requires -Version 5.1

<#
QUARTERLY CLEANUP REVIEW

OBJECTIVE
Provide a read-only Microsoft 365 hygiene/debt review for periodic maintenance.

REVIEWS
- Enabled Entra member accounts with recorded sign-in activity older than the threshold
- Enabled Entra member accounts where sign-in activity is unavailable
- Active Entra admin role membership counts
- Cloud-manageable Entra groups without owners
- Exchange Online mailboxes with EXTERNAL forwarding enabled

DEFAULT STALE THRESHOLD
90 days

SAFETY
Read-only.
No changes are made.
No export is created.
Query failures are reported as data gaps and are never treated as clean results.
#>

param(
    [ValidateRange(1,3650)]
    [int]$StaleDays = 90,

    [string]$TenantDomain
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function Write-OK   { param($m) Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "[INFO] $m" }
function Write-Warn { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "[FAIL] $m" -ForegroundColor Red }

function Write-Section {
    param([string]$Title)

    Write-Host $Title
}

function Pause-End {
    Write-FieldKitFooter
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

function Clean-Name {
    param([object]$Name)

    if ($null -eq $Name) {
        return ""
    }

    return (
        [string]$Name -replace
        '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$',
        ''
    ).Trim()
}

function Test-GuidString {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    return (
        $Value -match
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    )
}

function Ensure-Module {
    param(
        [string]$Name,
        [string]$Command
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        return
    }

    $module = Get-Module -ListAvailable -Name $Name |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install it first with: Install-Module $Name -Scope CurrentUser"
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

function Get-GraphPaged {
    param(
        [string]$Uri,
        [int]$MaxPages = 200
    )

    $items = @()
    $next = $Uri
    $pageCount = 0

    while ($next) {
        if ($pageCount -ge $MaxPages) {
            throw (
                "Graph pagination exceeded the safety limit of {0} pages. " +
                "Incomplete results were not accepted."
            ) -f $MaxPages
        }

        $page = Invoke-GraphGet -Uri $next

        if (
            $null -eq $page -or
            $page.PSObject.Properties.Name -notcontains "value"
        ) {
            throw "Graph returned an unexpected paged response. Incomplete results were not accepted."
        }

        $items += @(
            $page.value |
            Where-Object { $null -ne $_ }
        )

        $pageCount++
        $next = [string]$page.'@odata.nextLink'
    }

    return @($items)
}

function Get-GraphTenantInfo {
    $response = Invoke-GraphGet `
        -Uri "https://graph.microsoft.com/v1.0/organization?`$select=displayName,verifiedDomains"

    $organization = @($response.value) | Select-Object -First 1

    if (-not $organization) {
        throw "Graph did not return organization details."
    }

    $defaultDomain = @(
        $organization.verifiedDomains |
        Where-Object { $_.isDefault -eq $true } |
        Select-Object -First 1
    )

    return [PSCustomObject]@{
        DisplayName   = [string]$organization.displayName
        DefaultDomain = if ($defaultDomain) {
            [string]$defaultDomain.name
        }
        else {
            ""
        }
        Domains = @(
            $organization.verifiedDomains |
            ForEach-Object { [string]$_.name } |
            Where-Object { $_ }
        )
    }
}

function Test-GraphScopes {
    param(
        [object]$Context,
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

function Connect-GraphAuto {
    param(
        [string[]]$Scopes,
        [string]$TargetDomain
    )

    Ensure-Module `
        -Name "Microsoft.Graph.Authentication" `
        -Command "Connect-MgGraph"

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-GraphScopes -Context $context -RequiredScopes $Scopes)
    ) {
        try {
            $tenant = Get-GraphTenantInfo

            if ($tenant.Domains -contains $TargetDomain) {
                Write-OK "Graph session reused"
                return $tenant
            }
        }
        catch {
        }
    }

    if ($context) {
        try {
            Disconnect-MgGraph `
                -ErrorAction SilentlyContinue |
                Out-Null
        }
        catch {
        }
    }

    Write-Host "Graph: Connecting..."

    $command = Get-Command `
        Connect-MgGraph `
        -ErrorAction Stop

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

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop

    if (
        -not (
            Test-GraphScopes `
                -Context $context `
                -RequiredScopes $Scopes
        )
    ) {
        throw "Graph token is missing one or more required scopes."
    }

    $tenant = Get-GraphTenantInfo

    if ($tenant.Domains -notcontains $TargetDomain) {
        throw (
            "Graph connected to a different tenant. " +
            "Expected domain: $TargetDomain"
        )
    }

    Write-OK "Graph connected"
    return $tenant
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

function Test-ExchangeRead {
    try {
        $null = Get-AcceptedDomain `
            -ResultSize 1 `
            -ErrorAction Stop

        return $true
    }
    catch {
        return $false
    }
}

function Test-ExchangeTenant {
    param([string]$TargetDomain)

    try {
        $domains = @(
            Get-AcceptedDomain `
                -ResultSize Unlimited `
                -ErrorAction Stop
        )

        return (
            @(
                $domains |
                Where-Object {
                    [string]$_.DomainName -eq $TargetDomain
                }
            ).Count -gt 0
        )
    }
    catch {
        return $false
    }
}

function Connect-ExchangeAuto {
    param([string]$TargetDomain)

    Ensure-Module `
        -Name "ExchangeOnlineManagement" `
        -Command "Connect-ExchangeOnline"

    if (
        (Get-ActiveExchangeConnection) -and
        (Test-ExchangeRead) -and
        (Test-ExchangeTenant -TargetDomain $TargetDomain)
    ) {
        Write-OK "Exchange session reused"
        return
    }

    Write-Host "Exchange Online: Connecting..."

    $command = Get-Command `
        Connect-ExchangeOnline `
        -ErrorAction Stop

    $parameters = @{
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ShowBanner")) {
        $parameters["ShowBanner"] = $false
    }

    if ($command.Parameters.ContainsKey("ShowProgress")) {
        $parameters["ShowProgress"] = $false
    }

    Connect-ExchangeOnline @parameters | Out-Null

    if (-not (Test-ExchangeRead)) {
        throw "Exchange connected, but read access could not be validated."
    }

    if (-not (Test-ExchangeTenant -TargetDomain $TargetDomain)) {
        throw (
            "Exchange connected to a different tenant. " +
            "Expected domain: $TargetDomain"
        )
    }

    Write-OK "Exchange connected"
}

function Get-StaleLoginReview {
    param([int]$Days)

    # Graph pages containing signInActivity are limited to 500 users.
    $users = @(
        Get-GraphPaged `
            -Uri (
                "https://graph.microsoft.com/v1.0/users?" +
                "`$select=userPrincipalName,accountEnabled,userType,signInActivity" +
                "&`$top=500"
            )
    )

    $enabledMembers = @(
        $users |
        Where-Object {
            $_.accountEnabled -eq $true -and
            $_.userType -ne "Guest"
        }
    )

    $stale = @()
    $unavailable = @()
    $now = Get-Date

    foreach ($user in $enabledMembers) {
        $upn = [string]$user.userPrincipalName

        if (
            $user.signInActivity -and
            $user.signInActivity.lastSignInDateTime
        ) {
            try {
                $last = [datetime]$user.signInActivity.lastSignInDateTime
                $age = [int]($now - $last).TotalDays

                if ($age -ge $Days) {
                    $stale += [PSCustomObject]@{
                        UPN        = $upn
                        LastSignIn = $last.ToLocalTime()
                        Days       = $age
                    }
                }
            }
            catch {
                $unavailable += [PSCustomObject]@{
                    UPN    = $upn
                    Reason = "Sign-in timestamp could not be parsed"
                }
            }
        }
        else {
            $unavailable += [PSCustomObject]@{
                UPN    = $upn
                Reason = "No Entra sign-in activity returned"
            }
        }
    }

    return [PSCustomObject]@{
        Reviewed    = $enabledMembers.Count
        Stale       = @($stale)
        Unavailable = @($unavailable)
    }
}

function Get-AdminRoleReview {
    $rows = @()
    $gaps = @()

    $roles = @(
        Get-GraphPaged `
            -Uri "https://graph.microsoft.com/v1.0/directoryRoles?`$select=id,displayName&`$top=999"
    )

    foreach ($role in $roles) {
        try {
            $members = @(
                Get-GraphPaged `
                    -Uri (
                        "https://graph.microsoft.com/v1.0/directoryRoles/" +
                        "$($role.id)/members?`$select=displayName,userPrincipalName&`$top=999"
                    )
            )

            if ($members.Count -gt 0) {
                $rows += [PSCustomObject]@{
                    Role  = Clean-Name $role.displayName
                    Count = $members.Count
                }
            }
        }
        catch {
            $gaps += (
                "Admin role member lookup failed for " +
                "$(Clean-Name $role.displayName): $(Get-ShortError $_)"
            )
        }
    }

    return [PSCustomObject]@{
        Rows = @($rows)
        Gaps = @($gaps)
    }
}

function Test-GraphOwnerReviewSupported {
    param($Group)

    if ($Group.onPremisesSyncEnabled -eq $true) {
        return $false
    }

    $groupTypes = @($Group.groupTypes)

    if ($groupTypes -contains "Unified") {
        return $true
    }

    if (
        $Group.securityEnabled -eq $true -and
        $Group.mailEnabled -ne $true
    ) {
        return $true
    }

    return $false
}

function Get-OwnerlessGroupReview {
    $ownerless = @()
    $gaps = @()
    $skipped = 0

    $groups = @(
        Get-GraphPaged `
            -Uri (
                "https://graph.microsoft.com/v1.0/groups?" +
                "`$select=id,displayName,groupTypes,mailEnabled,securityEnabled,onPremisesSyncEnabled" +
                "&`$top=999"
            )
    )

    foreach ($group in $groups) {
        if (-not (Test-GraphOwnerReviewSupported -Group $group)) {
            $skipped++
            continue
        }

        try {
            $owners = Invoke-GraphGet `
                -Uri (
                    "https://graph.microsoft.com/v1.0/groups/" +
                    "$($group.id)/owners?`$select=id,displayName,userPrincipalName&`$top=1"
                )

            if ($null -eq $owners -or $null -eq $owners.value) {
                throw "Graph returned an incomplete owner response."
            }

            if (@($owners.value).Count -eq 0) {
                $ownerless += Clean-Name $group.displayName
            }
        }
        catch {
            $gaps += (
                "Group owner lookup failed for " +
                "$(Clean-Name $group.displayName): $(Get-ShortError $_)"
            )
        }
    }

    return [PSCustomObject]@{
        Ownerless = @($ownerless | Sort-Object -Unique)
        Skipped   = $skipped
        Gaps      = @($gaps)
    }
}

function Get-FriendlyForwardingDestination {
    param(
        $Mailbox,
        [System.Collections.Generic.List[string]]$Gaps
    )

    if ($Mailbox.ForwardingSmtpAddress) {
        return (
            ([string]$Mailbox.ForwardingSmtpAddress) -replace
            '^(?i)smtp:',
            ''
        ).Trim()
    }

    if ($Mailbox.ForwardingAddress) {
        try {
            $recipient = Get-Recipient `
                -Identity $Mailbox.ForwardingAddress `
                -ErrorAction Stop

            if ($recipient.PrimarySmtpAddress) {
                return [string]$recipient.PrimarySmtpAddress
            }

            if (
                $recipient.PSObject.Properties.Name -contains
                "ExternalEmailAddress" -and
                $recipient.ExternalEmailAddress
            ) {
                return (
                    ([string]$recipient.ExternalEmailAddress) -replace
                    '^(?i)smtp:',
                    ''
                ).Trim()
            }

            return [string]$recipient.DisplayName
        }
        catch {
            $Gaps.Add(
                "Forwarding destination could not be resolved for " +
                ([string]$Mailbox.UserPrincipalName)
            )

            return [string]$Mailbox.ForwardingAddress
        }
    }

    return ""
}

function Get-MailboxForwardingReview {
    $gaps = New-Object System.Collections.Generic.List[string]
    $rows = @()

    try {
        $acceptedDomains = @(
            Get-AcceptedDomain `
                -ResultSize Unlimited `
                -ErrorAction Stop
        )

        $internalDomains = @(
            $acceptedDomains |
            ForEach-Object {
                ([string]$_.DomainName).Trim().ToLowerInvariant()
            } |
            Where-Object { $_ } |
            Sort-Object -Unique
        )
    }
    catch {
        throw (
            "Accepted-domain enumeration failed: " +
            (Get-ShortError $_)
        )
    }

    try {
        $mailboxes = @(
            Get-Mailbox `
                -ResultSize Unlimited `
                -ErrorAction Stop
        )
    }
    catch {
        throw (
            "Mailbox enumeration failed: " +
            (Get-ShortError $_)
        )
    }

    foreach ($mailbox in $mailboxes) {
        if (
            -not $mailbox.ForwardingSmtpAddress -and
            -not $mailbox.ForwardingAddress
        ) {
            continue
        }

        $destination = Get-FriendlyForwardingDestination `
            -Mailbox $mailbox `
            -Gaps $gaps

        if ([string]::IsNullOrWhiteSpace($destination)) {
            $gaps.Add(
                "Forwarding destination was empty for " +
                ([string]$mailbox.UserPrincipalName)
            )
            continue
        }

        $external = $false
        $destinationDomain = ""

        if (
            $destination -match
            '(?i)([A-Z0-9._%+\-]+@([A-Z0-9.\-]+\.[A-Z]{2,}))'
        ) {
            $destination = $Matches[1]
            $destinationDomain = $Matches[2].ToLowerInvariant()

            if ($internalDomains -notcontains $destinationDomain) {
                $external = $true
            }
        }
        else {
            $gaps.Add(
                "Forwarding destination could not be classified as internal/external for " +
                ([string]$mailbox.UserPrincipalName) +
                ": " +
                $destination
            )
            continue
        }

        if (-not $external) {
            continue
        }

        $upn = [string]$mailbox.UserPrincipalName

        if ([string]::IsNullOrWhiteSpace($upn)) {
            $upn = [string]$mailbox.PrimarySmtpAddress
        }

        $rows += [PSCustomObject]@{
            UPN               = $upn
            Destination       = $destination
            DeliverAndForward = [bool]$mailbox.DeliverToMailboxAndForward
        }
    }

    return [PSCustomObject]@{
        Rows = @($rows)
        Gaps = @($gaps)
    }
}

try {
    Write-Host "QUARTERLY CLEANUP REVIEW"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    if ([string]::IsNullOrWhiteSpace($TenantDomain)) {
        $TenantDomain = (Read-Host "Tenant domain").Trim()
    }

    if ([string]::IsNullOrWhiteSpace($TenantDomain)) {
        throw "Tenant domain is required."
    }

    $TenantDomain = $TenantDomain.ToLowerInvariant()

    $dataGaps = New-Object System.Collections.Generic.List[string]
    $graphAvailable = $false
    $exchangeAvailable = $false
    $tenant = $null

    try {
        $tenant = Connect-GraphAuto `
            -Scopes @(
                "User.Read.All",
                "Directory.Read.All",
                "AuditLog.Read.All",
                "Group.Read.All"
            ) `
            -TargetDomain $TenantDomain

        $graphAvailable = $true
    }
    catch {
        Write-Warn "Graph review unavailable"
        $dataGaps.Add(
            "Graph: $(Get-ShortError $_)"
        )
    }

    try {
        Connect-ExchangeAuto `
            -TargetDomain $TenantDomain

        $exchangeAvailable = $true
    }
    catch {
        Write-Warn "Exchange review unavailable"
        $dataGaps.Add(
            "Exchange: $(Get-ShortError $_)"
        )
    }

    Write-Host ""
    Write-Section "TENANT"

    if ($tenant) {
        Write-Host ("Name: {0}" -f $tenant.DisplayName)
    }
    else {
        Write-Host "Name: Not available"
    }

    Write-Host ("Domain: {0}" -f $TenantDomain)
    Write-Host ("Stale Threshold: {0} days" -f $StaleDays)

    $staleReview = $null
    $adminReview = $null
    $ownerReview = $null
    $forwardingReview = $null

    Write-Host ""
    Write-Section "STALE ENABLED USERS"

    if ($graphAvailable) {
        try {
            $staleReview = Get-StaleLoginReview `
                -Days $StaleDays

            if ($staleReview.Stale.Count -eq 0) {
                Write-Host "Status: No"
            }
            else {
                Write-Host (
                    "Status: Yes | {0} user(s)" -f
                    $staleReview.Stale.Count
                )

                foreach (
                    $row in
                    ($staleReview.Stale |
                        Sort-Object Days -Descending)
                ) {
                    Write-Host (
                        "{0} | Last Sign-In: {1} | Age: {2} days" -f
                        $row.UPN,
                        $row.LastSignIn.ToString("yyyy-MM-dd"),
                        $row.Days
                    )
                }
            }
        }
        catch {
            Write-Host "Status: Not available"
            $dataGaps.Add(
                "Stale users: $(Get-ShortError $_)"
            )
        }
    }
    else {
        Write-Host "Status: Not available"
    }

    Write-Host ""
    Write-Section "ACTIVITY NOT AVAILABLE"

    if ($staleReview) {
        if ($staleReview.Unavailable.Count -eq 0) {
            Write-Host "Status: No"
        }
        else {
            Write-Host (
                "Status: Yes | {0} user(s)" -f
                $staleReview.Unavailable.Count
            )

            foreach (
                $row in
                ($staleReview.Unavailable |
                    Sort-Object UPN)
            ) {
                Write-Host (
                    "{0} | {1}" -f
                    $row.UPN,
                    $row.Reason
                )
            }
        }
    }
    else {
        Write-Host "Status: Not available"
    }

    Write-Host ""
    Write-Section "ADMIN ROLES"

    if ($graphAvailable) {
        try {
            $adminReview = Get-AdminRoleReview

            if ($adminReview.Rows.Count -eq 0) {
                Write-Host "Status: No"
            }
            else {
                Write-Host (
                    "Status: {0} active role(s)" -f
                    $adminReview.Rows.Count
                )

                foreach (
                    $row in
                    ($adminReview.Rows |
                        Sort-Object Role)
                ) {
                    Write-Host (
                        "Role: {0} | Members: {1}" -f
                        $row.Role,
                        $row.Count
                    )
                }
            }

            foreach ($gap in $adminReview.Gaps) {
                $dataGaps.Add($gap)
            }
        }
        catch {
            Write-Host "Status: Not available"
            $dataGaps.Add(
                "Admin roles: $(Get-ShortError $_)"
            )
        }
    }
    else {
        Write-Host "Status: Not available"
    }

    Write-Host ""
    Write-Section "OWNERLESS ENTRA GROUPS"

    if ($graphAvailable) {
        try {
            $ownerReview = Get-OwnerlessGroupReview

            if ($ownerReview.Ownerless.Count -eq 0) {
                Write-Host "Status: No"
            }
            else {
                Write-Host (
                    "Status: Yes | {0} group(s)" -f
                    $ownerReview.Ownerless.Count
                )

                foreach ($name in $ownerReview.Ownerless) {
                    Write-Host $name
                }
            }

            foreach ($gap in $ownerReview.Gaps) {
                $dataGaps.Add($gap)
            }
        }
        catch {
            Write-Host "Status: Not available"
            $dataGaps.Add(
                "Ownerless groups: $(Get-ShortError $_)"
            )
        }
    }
    else {
        Write-Host "Status: Not available"
    }

    Write-Host ""
    Write-Section "EXTERNAL MAILBOX FORWARDING"

    if ($exchangeAvailable) {
        try {
            $forwardingReview = Get-MailboxForwardingReview

            if ($forwardingReview.Rows.Count -eq 0) {
                Write-Host "Status: No"
            }
            else {
                Write-Host (
                    "Status: Yes | {0} mailbox(es)" -f
                    $forwardingReview.Rows.Count
                )

                foreach (
                    $row in
                    ($forwardingReview.Rows |
                        Sort-Object UPN)
                ) {
                    $copy = if ($row.DeliverAndForward) {
                        "Yes"
                    }
                    else {
                        "No"
                    }

                    Write-Host (
                        "{0} -> {1} | Deliver Copy: {2}" -f
                        $row.UPN,
                        $row.Destination,
                        $copy
                    )
                }
            }

            foreach ($gap in $forwardingReview.Gaps) {
                $dataGaps.Add($gap)
            }
        }
        catch {
            Write-Host "Status: Not available"
            $dataGaps.Add(
                "External forwarding: $(Get-ShortError $_)"
            )
        }
    }
    else {
        Write-Host "Status: Not available"
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

        foreach ($gap in $uniqueDataGaps) {
            Write-Host ("- {0}" -f $gap)
        }
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
