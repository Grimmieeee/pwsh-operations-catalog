#requires -Version 5.1

<#
.SYNOPSIS
Read-only pre-delete dependency check for a single hybrid AD / Microsoft 365 user.

.DESCRIPTION
Checks common identity, Exchange Online, and Entra dependencies that may need
review before deleting an on-premises AD user object.

Checks:
- AD status, direct group membership, managed groups, direct reports, SPNs
- Exchange mailbox state, forwarding, hidden/visible forwarding rules
- Mailbox delegation: Full Access, Send As, Send on Behalf
- Distribution/mail-enabled group ownership
- Transport rules that directly reference the user's known addresses
- Entra/M365/Teams ownership
- Direct enterprise app role assignments
- Licenses
- Mailbox retention/hold status and mailbox statistics

Notes:
- Read-only. No user/group/mailbox changes are made.
- OneDrive/SharePoint ownership is NOT queried by this script.
- Local Windows services, scheduled tasks, application configs, and third-party
  systems using the account cannot be proven safe from this check alone.

Requires as applicable:
- ActiveDirectory module
- ExchangeOnlineManagement module
- Microsoft.Graph.Authentication module
#>

$ErrorActionPreference = 'Stop'

$script:Findings = New-Object System.Collections.Generic.List[string]
$script:Gaps     = New-Object System.Collections.Generic.List[string]

$GraphConnectedHere = $false
$ExoConnectedHere   = $false

function Add-Finding {
    param([string]$Text)
    if (-not [string]::IsNullOrWhiteSpace($Text)) {
        $script:Findings.Add($Text)
    }
}

function Add-Gap {
    param([string]$Text)
    if (-not [string]::IsNullOrWhiteSpace($Text)) {
        $script:Gaps.Add($Text)
    }
}

function Write-Section {
    param([string]$Title)

    Write-Host ""
    Write-Host $Title
    Write-Host ('-' * $Title.Length)
}

function Write-List {
    param(
        [AllowNull()]
        [object[]]$Items,
        [string]$NoneText = 'None'
    )

    $clean = @($Items | Where-Object { $null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($clean.Count -eq 0) {
        Write-Host "- $NoneText"
        return
    }

    foreach ($item in $clean) {
        Write-Host "- $item"
    }
}

function Get-GraphPaged {
    param([Parameter(Mandatory=$true)][string]$Uri)

    $results = @()
    $next = $Uri

    while ($next) {
        $response = Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop

        if ($response.value) {
            $results += @($response.value)
        }
        elseif ($response.Value) {
            $results += @($response.Value)
        }

        $next = $response.'@odata.nextLink'
    }

    return @($results)
}

function Get-ObjectPropertyText {
    param(
        [object]$Object,
        [string]$Property
    )

    if ($null -eq $Object) { return $null }

    $p = $Object.PSObject.Properties[$Property]
    if ($p) {
        return $p.Value
    }

    return $null
}

function Test-ExoIdentityMatch {
    param(
        [object]$Value,
        [string[]]$Tokens
    )

    if ($null -eq $Value) { return $false }

    $candidates = New-Object System.Collections.Generic.List[string]

    foreach ($v in @($Value)) {
        if ($null -eq $v) { continue }

        $candidates.Add([string]$v)

        foreach ($property in @(
            'Name',
            'DisplayName',
            'Alias',
            'PrimarySmtpAddress',
            'UserPrincipalName',
            'DistinguishedName',
            'Guid',
            'ObjectGuid',
            'ExternalDirectoryObjectId'
        )) {
            $propValue = Get-ObjectPropertyText -Object $v -Property $property
            if ($propValue) {
                $candidates.Add([string]$propValue)
            }
        }
    }

    $normalizedTokens = @(
        $Tokens |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { $_.Trim().ToLowerInvariant() } |
        Select-Object -Unique
    )

    foreach ($candidate in $candidates) {
        if ([string]::IsNullOrWhiteSpace($candidate)) { continue }

        if ($normalizedTokens -contains $candidate.Trim().ToLowerInvariant()) {
            return $true
        }
    }

    return $false
}

function Pause-End {
    Write-Host ""

    try {
        Read-Host "Press ENTER to EXIT" | Out-Null
        return
    }
    catch {}

    try {
        Write-Host "Press ENTER to EXIT..."
        [Console]::ReadLine() | Out-Null
        return
    }
    catch {}

    Start-Sleep -Seconds 15
}

try {
    $UPN = Read-Host "Enter UPN"

    if ([string]::IsNullOrWhiteSpace($UPN)) {
        throw "UPN is required."
    }

    $UPN = $UPN.Trim()

    Write-Host ""
    Write-Host "USER PRE-DELETE CHECK"
    Write-Host "---------------------"
    Write-Host "Target: $UPN"
    Write-Host "Mode:   READ-ONLY"

    # -------------------------------------------------------------------------
    # ACTIVE DIRECTORY
    # -------------------------------------------------------------------------

    $adUser = $null
    $adGroups = @()
    $adManagedGroups = @()
    $directReports = @()
    $spns = @()
    $proxyAddresses = @()

    Write-Section "ACTIVE DIRECTORY"

    if (Get-Module -ListAvailable -Name ActiveDirectory) {
        try {
            Import-Module ActiveDirectory -ErrorAction Stop

            $escapedUPN = $UPN.Replace("'", "''")
            $adUser = Get-ADUser -Filter "UserPrincipalName -eq '$escapedUPN'" -Properties `
                DisplayName, Enabled, MemberOf, ManagedObjects, Manager, DirectReports, `
                mail, proxyAddresses, servicePrincipalName, DistinguishedName, ObjectGUID, `
                SamAccountName -ErrorAction Stop

            if ($adUser) {
                Write-Host "Found:   $($adUser.DisplayName)"
                Write-Host "Enabled: $($adUser.Enabled)"
                Write-Host "SAM:     $($adUser.SamAccountName)"

                $proxyAddresses = @($adUser.proxyAddresses)

                $adGroups = @(
                    $adUser.MemberOf |
                    ForEach-Object {
                        try {
                            (Get-ADGroup -Identity $_ -ErrorAction Stop).Name
                        }
                        catch {
                            [string]$_
                        }
                    } |
                    Sort-Object -Unique
                )

                $directReports = @(
                    $adUser.DirectReports |
                    ForEach-Object {
                        try {
                            $r = Get-ADUser -Identity $_ -Properties UserPrincipalName,DisplayName -ErrorAction Stop
                            if ($r.UserPrincipalName) {
                                "$($r.DisplayName) <$($r.UserPrincipalName)>"
                            }
                            else {
                                $r.DisplayName
                            }
                        }
                        catch {
                            [string]$_
                        }
                    } |
                    Sort-Object -Unique
                )

                $spns = @($adUser.servicePrincipalName | Sort-Object -Unique)

                try {
                    $adManagedGroups = @(
                        Get-ADGroup -Filter * -Properties ManagedBy -ErrorAction Stop |
                        Where-Object { $_.ManagedBy -eq $adUser.DistinguishedName } |
                        Select-Object -ExpandProperty Name |
                        Sort-Object -Unique
                    )
                }
                catch {
                    Add-Gap "AD managed-group lookup failed: $($_.Exception.Message)"
                }

                Write-Host ""
                Write-Host "Direct group memberships: $($adGroups.Count)"
                Write-List -Items $adGroups -NoneText "No direct AD group memberships"

                Write-Host ""
                Write-Host "Groups managed by user: $($adManagedGroups.Count)"
                Write-List -Items $adManagedGroups -NoneText "No AD groups managed by user"

                Write-Host ""
                Write-Host "Direct reports: $($directReports.Count)"
                Write-List -Items $directReports -NoneText "No direct reports"

                Write-Host ""
                Write-Host "Service Principal Names: $($spns.Count)"
                Write-List -Items $spns -NoneText "No SPNs assigned"

                if ($adManagedGroups.Count -gt 0) {
                    Add-Finding "$($adManagedGroups.Count) AD group(s) are managed by this user."
                }

                if ($directReports.Count -gt 0) {
                    Add-Finding "$($directReports.Count) AD user(s) reference this account as manager."
                }

                if ($spns.Count -gt 0) {
                    Add-Finding "$($spns.Count) SPN(s) are assigned to this account."
                }
            }
            else {
                Write-Host "- User not found in Active Directory"
                Add-Gap "User was not found in Active Directory."
            }
        }
        catch {
            Write-Host "- AD lookup failed: $($_.Exception.Message)"
            Add-Gap "Active Directory lookup failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "- ActiveDirectory module not installed"
        Add-Gap "ActiveDirectory module is unavailable."
    }

    # -------------------------------------------------------------------------
    # EXCHANGE ONLINE
    # -------------------------------------------------------------------------

    $mailbox = $null
    $exoRecipient = $null
    $exoIdentityTokens = @($UPN)

    Write-Section "EXCHANGE ONLINE"

    if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
        try {
            Import-Module ExchangeOnlineManagement -ErrorAction Stop

            $existingExo = @()
            try {
                $existingExo = @(
                    Get-ConnectionInformation -ErrorAction SilentlyContinue |
                    Where-Object { $_.State -eq 'Connected' }
                )
            }
            catch {}

            if ($existingExo.Count -eq 0) {
                Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
                $ExoConnectedHere = $true
            }

            try {
                $exoRecipient = Get-Recipient -Identity $UPN -ErrorAction Stop
            }
            catch {}

            if ($exoRecipient) {
                $exoIdentityTokens += @(
                    [string]$exoRecipient.Name,
                    [string]$exoRecipient.DisplayName,
                    [string]$exoRecipient.Alias,
                    [string]$exoRecipient.PrimarySmtpAddress,
                    [string]$exoRecipient.DistinguishedName,
                    [string]$exoRecipient.Guid,
                    [string]$exoRecipient.ExternalDirectoryObjectId
                )
            }

            if ($adUser) {
                $exoIdentityTokens += @(
                    [string]$adUser.DisplayName,
                    [string]$adUser.SamAccountName,
                    [string]$adUser.DistinguishedName,
                    [string]$adUser.ObjectGUID
                )
            }

            $smtpAliases = @(
                $proxyAddresses |
                Where-Object { $_ -match '^(?i)smtp:' } |
                ForEach-Object { ($_ -replace '^(?i)smtp:', '').Trim() }
            )

            $exoIdentityTokens += $smtpAliases
            $exoIdentityTokens = @(
                $exoIdentityTokens |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
            )

            try {
                $mailbox = Get-Mailbox -Identity $UPN -ErrorAction Stop
                Write-Host "Mailbox: $($mailbox.DisplayName) <$($mailbox.PrimarySmtpAddress)>"
                Write-Host "Type:    $($mailbox.RecipientTypeDetails)"
            }
            catch {
                Write-Host "- No Exchange Online mailbox found"
            }

            if ($mailbox) {
                # Mailbox-level forwarding
                Write-Host ""
                Write-Host "MAILBOX FORWARDING"

                $mailboxForwarding = @()

                if ($mailbox.ForwardingAddress) {
                    $resolved = [string]$mailbox.ForwardingAddress
                    try {
                        $forwardRecipient = Get-Recipient -Identity $mailbox.ForwardingAddress -ErrorAction Stop
                        if ($forwardRecipient.PrimarySmtpAddress) {
                            $resolved = [string]$forwardRecipient.PrimarySmtpAddress
                        }
                    }
                    catch {}

                    $mailboxForwarding += "ForwardingAddress: $resolved"
                }

                if ($mailbox.ForwardingSmtpAddress) {
                    $mailboxForwarding += "ForwardingSmtpAddress: $($mailbox.ForwardingSmtpAddress)"
                }

                if ($mailboxForwarding.Count -gt 0) {
                    Write-List -Items $mailboxForwarding
                    Write-Host "- DeliverToMailboxAndForward: $($mailbox.DeliverToMailboxAndForward)"
                    Add-Finding "Mailbox-level forwarding is configured."
                }
                else {
                    Write-Host "- No mailbox-level forwarding"
                }

                # Inbox forwarding/redirect rules
                Write-Host ""
                Write-Host "FORWARDING / REDIRECT INBOX RULES"

                try {
                    $forwardRules = @(
                        Get-InboxRule -Mailbox $UPN -IncludeHidden -ErrorAction Stop |
                        Where-Object {
                            $_.ForwardTo -or
                            $_.ForwardAsAttachmentTo -or
                            $_.RedirectTo
                        }
                    )

                    if ($forwardRules.Count -eq 0) {
                        Write-Host "- None"
                    }
                    else {
                        foreach ($rule in $forwardRules) {
                            $targets = @()

                            foreach ($target in @($rule.ForwardTo)) {
                                if ($target) { $targets += "ForwardTo=$target" }
                            }
                            foreach ($target in @($rule.ForwardAsAttachmentTo)) {
                                if ($target) { $targets += "ForwardAsAttachmentTo=$target" }
                            }
                            foreach ($target in @($rule.RedirectTo)) {
                                if ($target) { $targets += "RedirectTo=$target" }
                            }

                            Write-Host "- $($rule.Name) | Enabled=$($rule.Enabled)"
                            foreach ($target in $targets) {
                                Write-Host "  $target"
                            }
                        }

                        Add-Finding "$($forwardRules.Count) forwarding/redirect inbox rule(s) exist."
                    }
                }
                catch {
                    Write-Host "- Lookup failed: $($_.Exception.Message)"
                    Add-Gap "Inbox rule lookup failed: $($_.Exception.Message)"
                }

                # Delegates ON the target mailbox
                Write-Host ""
                Write-Host "DELEGATES ON THIS MAILBOX"

                try {
                    $fullAccessOnTarget = @(
                        Get-MailboxPermission -Identity $UPN -ErrorAction Stop |
                        Where-Object {
                            -not $_.IsInherited -and
                            -not $_.Deny -and
                            ($_.AccessRights -contains 'FullAccess') -and
                            ([string]$_.User -notmatch 'NT AUTHORITY\\SELF')
                        } |
                        ForEach-Object {
                            "Full Access: $($_.User)"
                        }
                    )

                    $sendAsOnTarget = @(
                        Get-RecipientPermission -Identity $UPN -ErrorAction Stop |
                        Where-Object {
                            ($_.AccessRights -contains 'SendAs') -and
                            ([string]$_.Trustee -notmatch 'NT AUTHORITY\\SELF')
                        } |
                        ForEach-Object {
                            "Send As: $($_.Trustee)"
                        }
                    )

                    $sendOnBehalfOnTarget = @(
                        $mailbox.GrantSendOnBehalfTo |
                        ForEach-Object {
                            if ($_){ "Send on Behalf: $_" }
                        }
                    )

                    $delegatesOnTarget = @(
                        $fullAccessOnTarget +
                        $sendAsOnTarget +
                        $sendOnBehalfOnTarget
                    ) | Sort-Object -Unique

                    Write-List -Items $delegatesOnTarget -NoneText "No direct delegates found"

                    if ($delegatesOnTarget.Count -gt 0) {
                        Add-Finding "$($delegatesOnTarget.Count) direct mailbox delegate permission(s) depend on this mailbox."
                    }
                }
                catch {
                    Write-Host "- Delegate lookup failed: $($_.Exception.Message)"
                    Add-Gap "Delegate lookup on target mailbox failed: $($_.Exception.Message)"
                }

                # Distribution / mail-enabled group ownership
                Write-Host ""
                Write-Host "EXCHANGE GROUP OWNERSHIP"

                try {
                    $ownedDgs = @(
                        Get-DistributionGroup -ResultSize Unlimited -ErrorAction Stop |
                        Where-Object {
                            Test-ExoIdentityMatch -Value $_.ManagedBy -Tokens $exoIdentityTokens
                        } |
                        Select-Object -ExpandProperty DisplayName |
                        Sort-Object -Unique
                    )

                    Write-List -Items $ownedDgs -NoneText "No Exchange distribution/mail-enabled groups owned"

                    if ($ownedDgs.Count -gt 0) {
                        Add-Finding "$($ownedDgs.Count) Exchange distribution/mail-enabled group(s) are owned by this user."
                    }
                }
                catch {
                    Write-Host "- Lookup failed: $($_.Exception.Message)"
                    Add-Gap "Exchange group ownership lookup failed: $($_.Exception.Message)"
                }

                # Permissions the user holds on other recipients/mailboxes
                Write-Host ""
                Write-Host "ACCESS HELD BY THIS USER"

                $heldAccess = @()

                try {
                    $sendAsHeld = @(
                        Get-RecipientPermission -Trustee $UPN -ResultSize Unlimited -ErrorAction Stop |
                        Where-Object { $_.AccessRights -contains 'SendAs' } |
                        ForEach-Object {
                            "Send As: $($_.Identity)"
                        }
                    )

                    $heldAccess += $sendAsHeld
                }
                catch {
                    Add-Gap "Global Send As lookup failed: $($_.Exception.Message)"
                }

                try {
                    $allMailboxes = @(
                        Get-Mailbox -ResultSize Unlimited -ErrorAction Stop
                    )

                    $index = 0
                    foreach ($mbx in $allMailboxes) {
                        $index++

                        Write-Progress `
                            -Activity "Checking mailbox delegation" `
                            -Status "$index of $($allMailboxes.Count): $($mbx.DisplayName)" `
                            -PercentComplete (($index / [math]::Max($allMailboxes.Count,1)) * 100)

                        if ([string]$mbx.PrimarySmtpAddress -ieq [string]$mailbox.PrimarySmtpAddress) {
                            continue
                        }

                        try {
                            $fa = @(
                                Get-MailboxPermission -Identity $mbx.Identity -User $UPN -ErrorAction Stop |
                                Where-Object {
                                    -not $_.IsInherited -and
                                    -not $_.Deny -and
                                    ($_.AccessRights -contains 'FullAccess')
                                }
                            )

                            if ($fa.Count -gt 0) {
                                $heldAccess += "Full Access: $($mbx.DisplayName) <$($mbx.PrimarySmtpAddress)>"
                            }
                        }
                        catch {
                            # No matching direct permission is normal for most mailboxes.
                        }

                        if (Test-ExoIdentityMatch -Value $mbx.GrantSendOnBehalfTo -Tokens $exoIdentityTokens) {
                            $heldAccess += "Send on Behalf: $($mbx.DisplayName) <$($mbx.PrimarySmtpAddress)>"
                        }
                    }

                    Write-Progress -Activity "Checking mailbox delegation" -Completed
                }
                catch {
                    Write-Progress -Activity "Checking mailbox delegation" -Completed
                    Add-Gap "Cross-mailbox delegation scan failed: $($_.Exception.Message)"
                }

                $heldAccess = @($heldAccess | Sort-Object -Unique)

                Write-List -Items $heldAccess -NoneText "No direct Full Access / Send As / Send on Behalf dependencies found"

                if ($heldAccess.Count -gt 0) {
                    Add-Finding "$($heldAccess.Count) direct permission(s) are held by this user on other Exchange recipients."
                }

                # Transport rule references
                Write-Host ""
                Write-Host "TRANSPORT RULE REFERENCES"

                try {
                    $needles = @(
                        @($UPN) +
                        @($smtpAliases) +
                        @([string]$mailbox.PrimarySmtpAddress)
                    ) |
                    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                    Select-Object -Unique

                    $transportHits = @()

                    foreach ($rule in @(Get-TransportRule -ErrorAction Stop)) {
                        $ruleText = ($rule | Format-List * | Out-String)

                        foreach ($needle in $needles) {
                            if ($ruleText -match [regex]::Escape($needle)) {
                                $transportHits += $rule.Name
                                break
                            }
                        }
                    }

                    $transportHits = @($transportHits | Sort-Object -Unique)

                    Write-List -Items $transportHits -NoneText "No direct address references found"

                    if ($transportHits.Count -gt 0) {
                        Add-Finding "$($transportHits.Count) transport rule(s) reference this user's known email address."
                    }
                }
                catch {
                    Write-Host "- Lookup failed: $($_.Exception.Message)"
                    Add-Gap "Transport rule scan failed: $($_.Exception.Message)"
                }

                # Data / retention
                Write-Host ""
                Write-Host "MAILBOX DATA / RETENTION"

                try {
                    $stats = Get-MailboxStatistics -Identity $UPN -ErrorAction Stop

                    Write-Host "- Item count: $($stats.ItemCount)"
                    Write-Host "- Total size: $($stats.TotalItemSize)"
                    Write-Host "- Last logon: $($stats.LastLogonTime)"
                }
                catch {
                    Write-Host "- Mailbox statistics unavailable: $($_.Exception.Message)"
                    Add-Gap "Mailbox statistics lookup failed: $($_.Exception.Message)"
                }

                Write-Host "- Archive status: $($mailbox.ArchiveStatus)"
                Write-Host "- Litigation hold: $($mailbox.LitigationHoldEnabled)"
                Write-Host "- Retention hold: $($mailbox.RetentionHoldEnabled)"
                Write-Host "- Retention policy: $($mailbox.RetentionPolicy)"

                $inPlaceHolds = @($mailbox.InPlaceHolds | Where-Object { $_ })

                if ($inPlaceHolds.Count -gt 0) {
                    Write-Host "- In-place holds:"
                    foreach ($hold in $inPlaceHolds) {
                        Write-Host "  $hold"
                    }
                }
                else {
                    Write-Host "- In-place holds: None"
                }

                if ($mailbox.LitigationHoldEnabled -or
                    $mailbox.RetentionHoldEnabled -or
                    $inPlaceHolds.Count -gt 0) {

                    Add-Finding "Mailbox retention/hold configuration requires review before deletion."
                }
            }
        }
        catch {
            Write-Host "- Exchange Online check failed: $($_.Exception.Message)"
            Add-Gap "Exchange Online check failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "- ExchangeOnlineManagement module not installed"
        Add-Gap "ExchangeOnlineManagement module is unavailable."
    }

    # -------------------------------------------------------------------------
    # MICROSOFT GRAPH / ENTRA
    # -------------------------------------------------------------------------

    Write-Section "ENTRA / MICROSOFT 365"

    if (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication) {
        try {
            Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

            $requiredScopes = @(
                'User.Read.All',
                'Group.Read.All',
                'Directory.Read.All'
            )

            $existingGraph = Get-MgContext -ErrorAction SilentlyContinue
            $needGraphConnect = $false

            if (-not $existingGraph) {
                $needGraphConnect = $true
                $GraphConnectedHere = $true
            }
            else {
                foreach ($scope in $requiredScopes) {
                    if ($existingGraph.Scopes -notcontains $scope) {
                        $needGraphConnect = $true
                        break
                    }
                }
            }

            if ($needGraphConnect) {
                Connect-MgGraph -Scopes $requiredScopes -NoWelcome -ErrorAction Stop
            }

            $encodedUPN = [uri]::EscapeDataString($UPN)
            $userUri = "https://graph.microsoft.com/v1.0/users/$encodedUPN?`$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSyncEnabled,onPremisesImmutableId,mail"

            $graphUser = Invoke-MgGraphRequest -Method GET -Uri $userUri -ErrorAction Stop

            Write-Host "Found:   $($graphUser.displayName)"
            Write-Host "Enabled: $($graphUser.accountEnabled)"
            Write-Host "Synced:  $($graphUser.onPremisesSyncEnabled)"

            if ($graphUser.onPremisesSyncEnabled -eq $true) {
                Write-Host "- This is an on-premises-synchronized Entra object."
            }

            $graphId = [string]$graphUser.id

            # Direct cloud group membership
            Write-Host ""
            Write-Host "CLOUD GROUP MEMBERSHIPS"

            try {
                $memberUri = "https://graph.microsoft.com/v1.0/users/$graphId/memberOf/microsoft.graph.group?`$select=id,displayName,mail,groupTypes,mailEnabled,securityEnabled"
                $cloudMemberships = @(Get-GraphPaged -Uri $memberUri)

                $cloudMembershipText = @(
                    $cloudMemberships |
                    ForEach-Object {
                        $type = 'Entra Group'
                        if (@($_.groupTypes) -contains 'Unified') {
                            $type = 'Microsoft 365 Group'
                        }

                        if ($_.mail) {
                            "$($_.displayName) [$type] <$($_.mail)>"
                        }
                        else {
                            "$($_.displayName) [$type]"
                        }
                    } |
                    Sort-Object -Unique
                )

                Write-List -Items $cloudMembershipText -NoneText "No direct cloud group memberships"
            }
            catch {
                Write-Host "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "Cloud group membership lookup failed: $($_.Exception.Message)"
            }

            # Owned M365 / Teams / Entra groups
            Write-Host ""
            Write-Host "GROUP / TEAM OWNERSHIP"

            try {
                $ownedGroupsUri = "https://graph.microsoft.com/v1.0/users/$graphId/ownedObjects/microsoft.graph.group?`$select=id,displayName,mail,groupTypes,resourceProvisioningOptions,mailEnabled,securityEnabled"
                $ownedGroups = @(Get-GraphPaged -Uri $ownedGroupsUri)

                $ownedGroupText = @()

                foreach ($group in $ownedGroups) {
                    $type = 'Entra Group'

                    if (@($group.resourceProvisioningOptions) -contains 'Team') {
                        $type = 'Team'
                    }
                    elseif (@($group.groupTypes) -contains 'Unified') {
                        $type = 'Microsoft 365 Group'
                    }
                    elseif ($group.mailEnabled -and $group.securityEnabled) {
                        $type = 'Mail-enabled Security Group'
                    }
                    elseif ($group.securityEnabled) {
                        $type = 'Security Group'
                    }

                    if ($group.mail) {
                        $ownedGroupText += "$($group.displayName) [$type] <$($group.mail)>"
                    }
                    else {
                        $ownedGroupText += "$($group.displayName) [$type]"
                    }
                }

                $ownedGroupText = @($ownedGroupText | Sort-Object -Unique)

                Write-List -Items $ownedGroupText -NoneText "No Graph-visible groups or Teams owned"

                if ($ownedGroupText.Count -gt 0) {
                    Add-Finding "$($ownedGroupText.Count) Graph-visible group/Team ownership assignment(s) exist."
                }
            }
            catch {
                Write-Host "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "Graph group ownership lookup failed: $($_.Exception.Message)"
            }

            # Owned apps/service principals
            Write-Host ""
            Write-Host "APPLICATION OWNERSHIP"

            try {
                $ownedObjectsUri = "https://graph.microsoft.com/v1.0/users/$graphId/ownedObjects?`$select=id,displayName"
                $ownedObjects = @(Get-GraphPaged -Uri $ownedObjectsUri)

                $ownedApps = @(
                    $ownedObjects |
                    Where-Object {
                        $_.'@odata.type' -eq '#microsoft.graph.application' -or
                        $_.'@odata.type' -eq '#microsoft.graph.servicePrincipal'
                    } |
                    ForEach-Object {
                        $kind = if ($_.'@odata.type' -eq '#microsoft.graph.application') {
                            'App Registration'
                        }
                        else {
                            'Service Principal'
                        }

                        "$($_.displayName) [$kind]"
                    } |
                    Sort-Object -Unique
                )

                Write-List -Items $ownedApps -NoneText "No app registrations or service principals owned"

                if ($ownedApps.Count -gt 0) {
                    Add-Finding "$($ownedApps.Count) application/service-principal ownership assignment(s) exist."
                }
            }
            catch {
                Write-Host "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "Application ownership lookup failed: $($_.Exception.Message)"
            }

            # Direct enterprise app assignments
            Write-Host ""
            Write-Host "DIRECT ENTERPRISE APP ASSIGNMENTS"

            try {
                $appRoleUri = "https://graph.microsoft.com/v1.0/users/$graphId/appRoleAssignments?`$select=principalId,resourceDisplayName,resourceId,appRoleId"
                $appAssignments = @(Get-GraphPaged -Uri $appRoleUri)

                $directAppAssignments = @(
                    $appAssignments |
                    Where-Object { [string]$_.principalId -eq $graphId } |
                    ForEach-Object {
                        "$($_.resourceDisplayName) | AppRoleId=$($_.appRoleId)"
                    } |
                    Sort-Object -Unique
                )

                Write-List -Items $directAppAssignments -NoneText "No direct enterprise app role assignments"

                if ($directAppAssignments.Count -gt 0) {
                    Add-Finding "$($directAppAssignments.Count) direct enterprise app assignment(s) exist."
                }
            }
            catch {
                Write-Host "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "Enterprise app assignment lookup failed: $($_.Exception.Message)"
            }

            # Licenses
            Write-Host ""
            Write-Host "LICENSES"

            try {
                $licenseUri = "https://graph.microsoft.com/v1.0/users/$graphId/licenseDetails?`$select=skuPartNumber,skuId"
                $licenses = @(Get-GraphPaged -Uri $licenseUri)

                $licenseText = @(
                    $licenses |
                    ForEach-Object {
                        if ($_.skuPartNumber) {
                            [string]$_.skuPartNumber
                        }
                        else {
                            [string]$_.skuId
                        }
                    } |
                    Sort-Object -Unique
                )

                Write-List -Items $licenseText -NoneText "No licenses assigned"
            }
            catch {
                Write-Host "- Lookup failed: $($_.Exception.Message)"
                Add-Gap "License lookup failed: $($_.Exception.Message)"
            }
        }
        catch {
            Write-Host "- Microsoft Graph check failed: $($_.Exception.Message)"
            Add-Gap "Microsoft Graph check failed: $($_.Exception.Message)"
        }
    }
    else {
        Write-Host "- Microsoft.Graph.Authentication module not installed"
        Add-Gap "Microsoft.Graph.Authentication module is unavailable."
    }

    # -------------------------------------------------------------------------
    # LIMITATIONS / RESULT
    # -------------------------------------------------------------------------

    Write-Section "NOT CHECKED"
    Write-Host "- OneDrive / SharePoint site ownership or file sharing"
    Write-Host "- Local Windows services or scheduled tasks using this account"
    Write-Host "- Third-party applications, SaaS integrations, scripts, or stored credentials"
    Write-Host "- Indirect mailbox access inherited through security groups"

    Write-Section "RESULT"

    if ($script:Findings.Count -eq 0 -and $script:Gaps.Count -eq 0) {
        Write-Host "CLEAN IN CHECKED AREAS"
        Write-Host "No dependency requiring review was found by this script."
    }
    else {
        Write-Host "REVIEW BEFORE DELETE"

        if ($script:Findings.Count -gt 0) {
            Write-Host ""
            Write-Host "Dependencies found:"
            foreach ($finding in $script:Findings) {
                Write-Host "- $finding"
            }
        }

        if ($script:Gaps.Count -gt 0) {
            Write-Host ""
            Write-Host "Checks incomplete:"
            foreach ($gap in $script:Gaps) {
                Write-Host "- $gap"
            }
        }
    }
}
catch {
    Write-Host ""
    Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Write-Progress -Activity "Checking mailbox delegation" -Completed -ErrorAction SilentlyContinue

    # Pause before cleanup so the console cannot disappear immediately after
    # the RESULT section if a module cleanup call behaves unexpectedly.
    Pause-End

    if ($ExoConnectedHere) {
        try {
            Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue
        }
        catch {}
    }

    if ($GraphConnectedHere) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {}
    }
}
