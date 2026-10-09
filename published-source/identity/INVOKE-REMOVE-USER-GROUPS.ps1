<#
INVOKE-REMOVE-USER-GROUPS.ps1

Shows Active Directory and Entra ID groups for one or more users and removes
all removable memberships after a reviewed plan and typed confirmation.
#>

# PowerShell 5.1 and PowerShell 7+
# Standalone. No Exchange Online connection required.

param(
    [Alias("UPN")]
    [string[]]$InputObject,
    [string]$InputPath,
    [string]$SyncServer
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

function Write-OK {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
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


function Get-InputUPNs {
    param(
        [string[]]$Values,
        [string]$Path
    )

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($Path) { $rawValues += $Path }

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "User UPN or TXT/CSV path").Trim().Trim('"').Trim("'")
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
            $extension=[System.IO.Path]::GetExtension($resolved).ToLowerInvariant()

            if ($extension -eq ".txt") {
                foreach ($line in @(Get-Content -LiteralPath $resolved -Encoding UTF8 -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"').Trim("'")
                    if ($candidate -and $candidate -notmatch "^#") { [void]$items.Add($candidate) }
                }
            }
            elseif ($extension -eq ".csv") {
                $rows=@(Import-Csv -LiteralPath $resolved -ErrorAction Stop)
                if ($rows.Count -eq 0) { throw "CSV contains no data rows." }

                foreach ($row in $rows) {
                    $candidate=$null
                    foreach ($name in @("UPN","UserPrincipalName","Email","Address","User","Name","Input")) {
                        if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                            $candidate=[string]$row.$name
                            break
                        }
                    }
                    if (-not $candidate) {
                        $first=$row.PSObject.Properties | Select-Object -First 1
                        if ($first) { $candidate=[string]$first.Value }
                    }
                    if ($candidate -and $candidate.Trim()) { [void]$items.Add($candidate.Trim().Trim('"').Trim("'")) }
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
    if ($upns.Count -eq 0) { throw "No user UPNs were provided." }

    foreach ($upn in $upns) {
        if ($upn -notmatch '^[^@\s]+@[^@\s]+$') { throw "Invalid UPN: $upn" }
    }

    return $upns
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

function Test-OneTenantDomain {
    param([string[]]$UPNs)

    $domains = @(
        $UPNs |
        ForEach-Object {
            ($_ -split '@')[-1].ToLowerInvariant()
        } |
        Sort-Object -Unique
    )

    if ($domains.Count -ne 1) {
        throw "Run one Microsoft 365 tenant/domain at a time."
    }

    return $domains[0]
}

function Ensure-GraphAuthenticationModule {
    $module=Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "Microsoft.Graph.Authentication is required but is not installed. Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop
}

function Test-GraphScopes {
    param(
        [object]$Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) {
        return $false
    }

    $currentScopes = @($Context.Scopes)

    foreach ($scope in $RequiredScopes) {
        if ($currentScopes -notcontains $scope) {
            return $false
        }
    }

    return $true
}

function Invoke-GraphGet {
    param([string]$Uri)

    return Invoke-MgGraphRequest `
        -Method GET `
        -Uri $Uri `
        -OutputType PSObject `
        -ErrorAction Stop
}

function Resolve-GraphUser {
    param([string]$UserPrincipalName)

    $encodedUPN = [System.Uri]::EscapeDataString($UserPrincipalName)

    $uri = (
        "https://graph.microsoft.com/v1.0/users/{0}?`$select=id,displayName,userPrincipalName,mail,proxyAddresses,onPremisesSyncEnabled,onPremisesSamAccountName" -f
        $encodedUPN
    )

    return Invoke-GraphGet -Uri $uri
}

function Connect-GraphForUser {
    param(
        [string]$UserPrincipalName,
        [string[]]$Scopes
    )

    Ensure-GraphAuthenticationModule

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if ($context -and (Test-GraphScopes -Context $context -RequiredScopes $Scopes)) {
        try {
            $user = Resolve-GraphUser -UserPrincipalName $UserPrincipalName

            if ($user -and $user.id) {
                Write-OK "Graph session reused"
                return $user
            }
        }
        catch {
            # Reconnect below.
        }
    }

    if ($context) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    Write-Host "Graph: Connecting..."

    $domain = ($UserPrincipalName -split '@')[-1]

    $parameters = @{
        TenantId     = $domain
        Scopes       = $Scopes
        ContextScope = 'Process'
        ErrorAction  = 'Stop'
    }

    $command = Get-Command Connect-MgGraph -ErrorAction Stop

    if ($command.Parameters.ContainsKey('NoWelcome')) {
        $parameters.NoWelcome = $true
    }

    Connect-MgGraph @parameters | Out-Null

    $user = Resolve-GraphUser -UserPrincipalName $UserPrincipalName

    if (-not $user -or -not $user.id) {
        throw "The user was not found in the connected tenant."
    }

    Write-OK "Graph connected"
    return $user
}

function Get-GraphGroups {
    param([string]$UserId)

    $groups = @()
    $uri = "https://graph.microsoft.com/v1.0/users/$UserId/memberOf"

    while ($uri) {
        $page = Invoke-GraphGet -Uri $uri

        foreach ($membership in @($page.value)) {
            if ([string]$membership.'@odata.type' -ne '#microsoft.graph.group') {
                continue
            }

            $groupId = [string]$membership.id

            if (-not $groupId) {
                continue
            }

            $detailUri = (
                "https://graph.microsoft.com/v1.0/groups/{0}?`$select=id,displayName,mailEnabled,securityEnabled,groupTypes,isAssignableToRole,onPremisesSyncEnabled" -f
                $groupId
            )

            $group = Invoke-GraphGet -Uri $detailUri

            if (-not $group.displayName) {
                continue
            }

            $groupTypes = @($group.groupTypes)

            $groups += [pscustomobject]@{
                Id                    = [string]$group.id
                Name                  = ([string]$group.displayName).Trim()
                IsDynamic             = ($groupTypes -contains 'DynamicMembership')
                IsMicrosoft365        = ($groupTypes -contains 'Unified')
                IsRoleAssignable      = [bool]$group.isAssignableToRole
                IsMailEnabled         = [bool]$group.mailEnabled
                OnPremisesSyncEnabled = [bool]$group.onPremisesSyncEnabled
            }
        }

        $uri = [string]$page.'@odata.nextLink'
    }

    return @($groups)
}

function Import-ActiveDirectoryTools {
    $oldWarningPreference=$WarningPreference
    try {
        $WarningPreference='SilentlyContinue'
        $module=Get-Module -ListAvailable -Name ActiveDirectory -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1

        if (-not $module) {
            Write-Warn "ActiveDirectory module is not installed. Synced memberships cannot be changed from this workstation."
            return $false
        }

        if ($PSVersionTable.PSVersion.Major -ge 7) {
            Import-Module ActiveDirectory -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
        }
        else {
            Import-Module ActiveDirectory -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
        }

        return $true
    }
    catch {
        Write-Warn ("ActiveDirectory module could not be loaded: {0}" -f $_.Exception.Message)
        return $false
    }
    finally {
        $WarningPreference=$oldWarningPreference
    }
}

function Get-OnPremDomainController {
    $candidates=@()
    $logonServer=([string]$env:LOGONSERVER).Trim().TrimStart('\')
    if ($logonServer) { $candidates += $logonServer }

    try {
        $domain=Get-ADDomain -ErrorAction Stop -WarningAction SilentlyContinue
        if ($domain.PDCEmulator) { $candidates += [string]$domain.PDCEmulator }
    }
    catch {}

    try {
        $candidates += @(
            Get-ADDomainController -Filter * -ErrorAction Stop -WarningAction SilentlyContinue |
                Where-Object { -not [bool]$_.IsReadOnly } |
                ForEach-Object { [string]$_.HostName }
        )
    }
    catch {}

    foreach ($candidate in @($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        try {
            $dc=Get-ADDomainController -Identity $candidate -ErrorAction Stop -WarningAction SilentlyContinue
            if (-not [bool]$dc.IsReadOnly) { return [string]$dc.HostName }
        }
        catch {}
    }

    return $null
}

function Escape-ADFilterValue {
    param([string]$Value)
    return ($Value -replace "'", "''")
}


function Get-UniqueADUserMatch {
    param(
        [string]$Filter,
        [string]$Server,
        [string[]]$Properties,
        [string]$Method
    )

    $matches = @(
        Get-ADUser `
            -Filter $Filter `
            -Server $Server `
            -Properties $Properties `
            -ErrorAction Stop `
            -WarningAction SilentlyContinue
    )

    if ($matches.Count -gt 1) {
        throw ("AD identity resolution was ambiguous during {0}." -f $Method)
    }

    if ($matches.Count -eq 1) { return $matches[0] }
    return $null
}

function Resolve-AuthoritativeADUser {
    param(
        [string]$UserPrincipalName,
        [string]$Server,
        $GraphUser
    )

    $properties = @(
        'UserPrincipalName','DisplayName','DistinguishedName',
        'mail','proxyAddresses','sAMAccountName'
    )

    if ($GraphUser -and -not [string]::IsNullOrWhiteSpace([string]$GraphUser.onPremisesSamAccountName)) {
        $safeSam = Escape-ADFilterValue -Value ([string]$GraphUser.onPremisesSamAccountName)
        $user = Get-UniqueADUserMatch -Filter "SamAccountName -eq '$safeSam'" -Server $Server -Properties $properties -Method 'Graph onPremisesSamAccountName'
        if ($user) { return $user }
    }

    $upnCandidates = @($UserPrincipalName,$(if ($GraphUser) { [string]$GraphUser.userPrincipalName })) | Where-Object { $_ } | Sort-Object -Unique
    foreach ($candidate in $upnCandidates) {
        $safe = Escape-ADFilterValue -Value $candidate
        $user = Get-UniqueADUserMatch -Filter "UserPrincipalName -eq '$safe'" -Server $Server -Properties $properties -Method 'exact userPrincipalName'
        if ($user) { return $user }
    }

    $mailCandidates = @($(if ($GraphUser) { [string]$GraphUser.mail }),$UserPrincipalName,$(if ($GraphUser) { [string]$GraphUser.userPrincipalName })) | Where-Object { $_ } | Sort-Object -Unique
    foreach ($candidate in $mailCandidates) {
        $safe = Escape-ADFilterValue -Value $candidate
        $user = Get-UniqueADUserMatch -Filter "mail -eq '$safe'" -Server $Server -Properties $properties -Method 'exact mail'
        if ($user) { return $user }
    }

    $proxyCandidates = @()
    if ($GraphUser -and $GraphUser.proxyAddresses) { $proxyCandidates += @($GraphUser.proxyAddresses) }
    foreach ($candidate in $mailCandidates) {
        $proxyCandidates += "SMTP:$candidate"
        $proxyCandidates += "smtp:$candidate"
    }
    foreach ($candidate in @($proxyCandidates | Where-Object { $_ } | Sort-Object -Unique)) {
        $safe = Escape-ADFilterValue -Value ([string]$candidate)
        $user = Get-UniqueADUserMatch -Filter "proxyAddresses -eq '$safe'" -Server $Server -Properties $properties -Method 'exact proxyAddresses'
        if ($user) { return $user }
    }

    if ($UserPrincipalName -match '^([^@]+)@') {
        $fallbackSam = [string]$Matches[1]
        $safe = Escape-ADFilterValue -Value $fallbackSam
        $user = Get-UniqueADUserMatch -Filter "SamAccountName -eq '$safe'" -Server $Server -Properties $properties -Method 'sAMAccountName fallback'
        if ($user) { return $user }
    }

    return $null
}

function Get-ADUserAndGroups {
    param(
        [string]$UserPrincipalName,
        $GraphUser
    )

    $result = [pscustomobject]@{
        Available = $false
        DomainController = ''
        User = $null
        Groups = @()
        Error = ''
    }

    if (-not (Import-ActiveDirectoryTools)) {
        $result.Error = 'Active Directory tools are not available.'
        return $result
    }

    $server = Get-OnPremDomainController
    if (-not $server) {
        $result.Error = 'No approved writable domain controller could be reached.'
        return $result
    }

    try {
        $user = Resolve-AuthoritativeADUser -UserPrincipalName $UserPrincipalName -Server $server -GraphUser $GraphUser
        $result.Available = $true
        $result.DomainController = $server
        $result.User = $user
        if (-not $user) { return $result }
        $result.Groups = @(Get-ADPrincipalGroupMembership -Identity $user.DistinguishedName -Server $server -ErrorAction Stop -WarningAction SilentlyContinue)
        return $result
    }
    catch {
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Get-GroupDisplayInfo {
    param([string]$Name)

    $rawName=([string]$Name).Trim()
    return [pscustomobject]@{
        Name=$rawName
        Protected=($rawName -ieq 'Domain Users')
    }
}

function Get-SeparatedGroupRows {
    param(
        [object[]]$ADGroups,
        [object[]]$EntraGroups
    )

    $adRows=@()
    $entraRows=@()

    foreach ($group in @($ADGroups)) {
        $rawName=([string]$group.Name).Trim()
        if (-not $rawName) { continue }

        $display=Get-GroupDisplayInfo -Name $rawName
        $adRows += [pscustomobject]@{
            RawName=$rawName; Name=$display.Name; Protected=[bool]$display.Protected
            Source='AD'; SyncState=''; IsDynamic=$false; IsMicrosoft365=$false
            ADGroup=$group; EntraGroup=$null
        }
    }

    foreach ($group in @($EntraGroups)) {
        $rawName=([string]$group.Name).Trim()
        if (-not $rawName) { continue }

        $display=Get-GroupDisplayInfo -Name $rawName
        $entraRows += [pscustomobject]@{
            RawName=$rawName; Name=$display.Name; Protected=[bool]$display.Protected
            Source='Entra'
            SyncState=$(if ($group.OnPremisesSyncEnabled) { 'Synced' } else { 'Cloud' })
            IsDynamic=[bool]$group.IsDynamic
            IsMicrosoft365=[bool]$group.IsMicrosoft365
            ADGroup=$null; EntraGroup=$group
        }
    }

    $adRows=@($adRows | Sort-Object @{Expression={$_.Protected};Descending=$true},@{Expression={$_.Name};Descending=$false})
    $entraRows=@($entraRows | Sort-Object @{Expression={$_.Protected};Descending=$true},@{Expression={$_.Name};Descending=$false})

    return [pscustomobject]@{ AD=$adRows; Entra=$entraRows }
}

function Get-GroupMarkers {
    param($Row)

    $markers=@()
    if ($Row.Protected) { $markers += 'Protected' }
    if ($Row.Source -eq 'Entra' -and $Row.SyncState) { $markers += [string]$Row.SyncState }
    if ($Row.IsDynamic) { $markers += 'Dynamic' }
    if ($Row.IsMicrosoft365) { $markers += 'M365' }

    if ($markers.Count -eq 0) { return '' }
    return ' [' + ($markers -join '] [') + ']'
}

function Write-GroupSection {
    param([string]$Title,[object[]]$Rows)

    Write-Host ""
    Write-Host $Title

    if (-not $Rows -or $Rows.Count -eq 0) {
        Write-Host "None found"
        return
    }

    foreach ($row in $Rows) {
        Write-Host ("- {0}{1}" -f $row.Name,(Get-GroupMarkers -Row $row))
    }
}

function Get-GraphFailureAction {
    param([string]$Domain)

    return (
        "Sign in with an account that can read users and groups in {0}, then run the script again." -f
        $Domain
    )
}


function Resolve-SyncServer {
    param([string]$ExplicitServer)
    if (-not [string]::IsNullOrWhiteSpace($ExplicitServer)) { return $ExplicitServer.Trim() }
    return ''
}

function Start-EntraDeltaSync {
    param([string]$Server)

    if ([string]::IsNullOrWhiteSpace($Server)) {
        return [pscustomobject]@{ Status='ScheduledPending'; Server=''; Detail='' }
    }

    try {
        Invoke-Command -ComputerName $Server -ScriptBlock {
            Start-ADSyncSyncCycle -PolicyType Delta
        } -ErrorAction Stop | Out-Null
        return [pscustomobject]@{ Status='Triggered'; Server=$Server; Detail='' }
    }
    catch {
        return [pscustomobject]@{ Status='Failed'; Server=$Server; Detail=$_.Exception.Message }
    }
}

function Remove-ADGroup {
    param(
        [object]$User,
        [object]$Group,
        [string]$Server
    )

    Remove-ADGroupMember `
        -Identity $Group.DistinguishedName `
        -Members $User.DistinguishedName `
        -Server $Server `
        -Confirm:$false `
        -ErrorAction Stop `
        -WarningAction SilentlyContinue
}

function Remove-EntraGroup {
    param(
        [string]$UserId,
        [string]$GroupId
    )

    $uri = (
        "https://graph.microsoft.com/v1.0/groups/{0}/members/{1}/`$ref" -f
        $GroupId,
        $UserId
    )

    Invoke-MgGraphRequest `
        -Method DELETE `
        -Uri $uri `
        -ErrorAction Stop |
        Out-Null
}


function Wait-EntraGroupRemoval {
    param(
        [string]$UserId,
        [string]$GroupId
    )

    $delays = @(0,2,3,4,5,6)

    foreach ($delay in $delays) {
        if ($delay -gt 0) { Start-Sleep -Seconds $delay }

        $groups = @(Get-GraphGroups -UserId $UserId)
        $stillPresent = @(
            $groups |
            Where-Object { [string]$_.Id -eq $GroupId }
        ).Count -gt 0

        if (-not $stillPresent) { return $true }
    }

    return $false
}

function Get-RemovalPlan {
    param(
        [object[]]$Rows,
        [bool]$ADUserAvailable
    )

    $plan=@()
    $adNameMap=@{}

    foreach ($row in @($Rows | Where-Object { $_.Source -eq 'AD' })) {
        $adNameMap[([string]$row.RawName).ToLowerInvariant()]=$true
    }

    foreach ($row in @($Rows)) {
        if ($row.Protected) { continue }

        if ($row.Source -eq 'AD') {
            if ($row.ADGroup -and $ADUserAvailable) {
                $plan += [pscustomobject]@{
                    Name=$row.Name; Method='AD'; ADGroup=$row.ADGroup; EntraGroup=$null
                    CanRemove=$true; Reason=''; Action=''
                }
            }
            elseif (-not $row.ADGroup) {
                $plan += [pscustomobject]@{
                    Name=$row.Name; Method='AD'; ADGroup=$null; EntraGroup=$null
                    CanRemove=$false
                    Reason='This group is managed in Active Directory, but the matching AD group was not found.'
                    Action='Find the matching group in Active Directory and remove the user there.'
                }
            }
            else {
                $plan += [pscustomobject]@{
                    Name=$row.Name; Method='AD'; ADGroup=$row.ADGroup; EntraGroup=$null
                    CanRemove=$false
                    Reason='The Active Directory account could not be reached.'
                    Action='Run the script from a domain-connected computer and try again.'
                }
            }
            continue
        }

        $entra=$row.EntraGroup
        if (-not $entra) { continue }

        if ($entra.OnPremisesSyncEnabled) {
            $key=([string]$row.RawName).ToLowerInvariant()

            if ($adNameMap.ContainsKey($key)) {
                continue
            }

            $plan += [pscustomobject]@{
                Name=$row.Name; Method='AD'; ADGroup=$null; EntraGroup=$entra
                CanRemove=$false
                Reason='This synced membership is managed in Active Directory, but the matching AD group was not found.'
                Action='Resolve the matching Active Directory group and remove the membership at the authoritative source.'
            }
            continue
        }

        if ($entra.IsDynamic) {
            $plan += [pscustomobject]@{
                Name=$row.Name; Method='Entra'; ADGroup=$null; EntraGroup=$entra
                CanRemove=$false
                Reason='This membership is assigned automatically by a dynamic group rule.'
                Action='Update the user attributes or group rule that controls membership.'
            }
            continue
        }

        if ($entra.IsRoleAssignable) {
            $plan += [pscustomobject]@{
                Name=$row.Name; Method='Entra'; ADGroup=$null; EntraGroup=$entra
                CanRemove=$false
                Reason='This group is role-assignable and is not changed by the generic cleanup workflow.'
                Action='Review the group and privileged-access impact before changing membership.'
            }
            continue
        }

        if ($entra.IsMailEnabled -and -not $entra.IsMicrosoft365) {
            $plan += [pscustomobject]@{
                Name=$row.Name; Method='Exchange'; ADGroup=$null; EntraGroup=$entra
                CanRemove=$false
                Reason='This mail-enabled group is managed through Exchange.'
                Action='Remove the user from the group through the approved Exchange workflow.'
            }
            continue
        }

        $plan += [pscustomobject]@{
            Name=$row.Name; Method='Entra'; ADGroup=$null; EntraGroup=$entra
            CanRemove=$true; Reason=''; Action=''
        }
    }

    return @($plan)
}

function Get-FriendlyRemovalFailure {
    param(
        [string]$GroupName,
        [string]$Method,
        [string]$TechnicalError
    )

    if ($TechnicalError -match '(?i)access.*denied|forbidden|insufficient.*privilege|authorization') {
        return [pscustomobject]@{
            Reason = 'The signed-in account does not have permission to remove this membership.'
            Action = 'Use an approved account with group membership permissions and run the script again.'
        }
    }

    if ($Method -eq 'AD') {
        return [pscustomobject]@{
            Reason = 'Active Directory could not remove this membership.'
            Action = 'Confirm the user and group still exist in AD, then remove the membership manually or rerun the script.'
        }
    }

    return [pscustomobject]@{
        Reason = 'Entra could not remove this membership.'
        Action = 'Open the group in Entra Admin Center, remove the user manually, and confirm the change.'
    }
}

try {
    Write-Host "USER GROUP MEMBERSHIP CLEANUP"
    Write-Host "Shows AD and Entra groups for one or more users and removes all removable memberships after review."
    Write-Host ""

    $UPNs = @(Get-InputUPNs -Values $InputObject -Path $InputPath)
    $domain = Test-OneTenantDomain -UPNs $UPNs

    Write-Host ""
    Write-Host "TARGETS"
    Write-Host ("Tenant domain: {0}" -f $domain)
    Write-Host ("Users: {0}" -f $UPNs.Count)
$firstUser = Connect-GraphForUser `
        -UserPrincipalName $UPNs[0] `
        -Scopes @(
            'User.Read.All',
            'Group.Read.All',
            'GroupMember.ReadWrite.All'
        )

    $userPlans = @()
    $batchNeedsAttention = @()
    $anyADRemovalPlanned = $false

    foreach ($UPN in $UPNs) {
        Write-Host ""
        Write-Host ("USER: {0}" -f $UPN)
        Write-Host "--------------------------------------"

        try {
            if ($UPN -eq $UPNs[0]) {
                $graphUser = $firstUser
            }
            else {
                $graphUser = Resolve-GraphUser -UserPrincipalName $UPN
            }

            if (-not $graphUser -or -not $graphUser.id) {
                throw "The user was not found in the connected tenant."
            }

            $graphGroups = @(
                Get-GraphGroups -UserId ([string]$graphUser.id)
            )
        }
        catch {
            Write-Warn "Entra groups could not be checked."
            Write-Host ("Action: {0}" -f (Get-GraphFailureAction -Domain $domain))

            $batchNeedsAttention += [pscustomobject]@{
                UPN    = $UPN
                Name   = "User lookup"
                Reason = $_.Exception.Message
                Action = "Verify the user in Entra ID and rerun the script."
            }

            continue
        }

        $adResult = Get-ADUserAndGroups -UserPrincipalName $UPN -GraphUser $graphUser

        if (
            [bool]$graphUser.onPremisesSyncEnabled -and
            (-not $adResult.User)
        ) {
            Write-Warn "The user is synced from AD, but the AD account could not be reached."

            $action = if ($adResult.Error) {
                $adResult.Error
            }
            else {
                "Run the script from a domain-connected computer and try again."
            }

            Write-Host ("Action: {0}" -f $action)

            $batchNeedsAttention += [pscustomobject]@{
                UPN    = $UPN
                Name   = "Active Directory"
                Reason = "Synced user could not be resolved in AD."
                Action = $action
            }

            continue
        }

        $groupSections = Get-SeparatedGroupRows `
            -ADGroups @($adResult.Groups) `
            -EntraGroups @($graphGroups)

        $adRows = @($groupSections.AD)
        $entraRows = @($groupSections.Entra)
        $allRows = @($adRows + $entraRows)

        $displayName = $UPN

        if ($graphUser.displayName) {
            $displayName = [string]$graphUser.displayName
        }
        elseif ($adResult.User -and $adResult.User.DisplayName) {
            $displayName = [string]$adResult.User.DisplayName
        }

        Write-Host ("Name: {0}" -f $displayName)

        if ($allRows.Count -eq 0) {
            Write-Host "ACTIVE DIRECTORY GROUPS"
            Write-Host "None found"
            Write-Host ""
            Write-Host "ENTRA ID GROUPS"
            Write-Host "None found"

            $userPlans += [pscustomobject]@{
                UPN        = $UPN
                GraphUser  = $graphUser
                ADResult   = $adResult
                AllRows    = @()
                Plan       = @()
            }

            continue
        }

        Write-GroupSection `
            -Title "ACTIVE DIRECTORY GROUPS" `
            -Rows $adRows

        Write-GroupSection `
            -Title "ENTRA ID GROUPS" `
            -Rows $entraRows

        $plan = @(
            Get-RemovalPlan `
                -Rows $allRows `
                -ADUserAvailable ([bool]$adResult.User)
        )

        if (
            @(
                $plan |
                Where-Object {
                    $_.CanRemove -and
                    $_.Method -eq 'AD'
                }
            ).Count -gt 0
        ) {
            $anyADRemovalPlanned = $true
        }

        $userPlans += [pscustomobject]@{
            UPN        = $UPN
            GraphUser  = $graphUser
            ADResult   = $adResult
            AllRows    = @($allRows)
            Plan       = @($plan)
        }
    }

    $removableCount = 0

    foreach ($userPlan in $userPlans) {
        $removableCount += @(
            $userPlan.Plan |
            Where-Object { $_.CanRemove }
        ).Count
    }

    Write-Host ""
    Write-Host "BATCH PLAN"
    Write-Host ("Users loaded: {0}" -f $UPNs.Count)
    Write-Host ("Users with review results: {0}" -f $userPlans.Count)
    Write-Host ("Removable memberships: {0}" -f $removableCount)
    Write-Host ("Pre-existing review items: {0}" -f $batchNeedsAttention.Count)

    if ($removableCount -eq 0) {
        Write-Host ""
        Write-OK "No removable group memberships were found."

        if ($batchNeedsAttention.Count -gt 0) {
            Write-Warn "Some users still need manual review."
        }

        Pause-End
        return
    }

    if (-not (Confirm-Type `
        -Prompt "This will remove every removable, unprotected membership shown above for all listed users." `
        -Required "REMOVE GROUPS")) {
        Write-OK "No changes made."
        Pause-End
        return
    }

    $removedAD = @()
    $removedEntra = @()
    $needsAttention = @($batchNeedsAttention)

    Write-Host ""
    Write-Host "REMOVING GROUPS"

    foreach ($userPlan in $userPlans) {
        foreach ($item in $userPlan.Plan) {
            if (-not $item.CanRemove) {
                $needsAttention += [pscustomobject]@{
                    UPN    = $userPlan.UPN
                    Name   = $item.Name
                    Reason = $item.Reason
                    Action = $item.Action
                }

                continue
            }

            try {
                if ($item.Method -eq 'AD') {
                    Remove-ADGroup `
                        -User $userPlan.ADResult.User `
                        -Group $item.ADGroup `
                        -Server $userPlan.ADResult.DomainController

                    $remaining = @(
                        Get-ADPrincipalGroupMembership `
                            -Identity $userPlan.ADResult.User.DistinguishedName `
                            -Server $userPlan.ADResult.DomainController `
                            -ErrorAction Stop `
                            -WarningAction SilentlyContinue |
                        Where-Object {
                            [string]$_.DistinguishedName -eq
                            [string]$item.ADGroup.DistinguishedName
                        }
                    )

                    if ($remaining.Count -gt 0) {
                        throw 'AD membership still present after removal.'
                    }

                    $removedAD += [pscustomobject]@{
                        UPN  = $userPlan.UPN
                        Name = $item.Name
                    }
                }
                else {
                    Remove-EntraGroup `
                        -UserId ([string]$userPlan.GraphUser.id) `
                        -GroupId ([string]$item.EntraGroup.Id)

                    if (-not (Wait-EntraGroupRemoval `
                        -UserId ([string]$userPlan.GraphUser.id) `
                        -GroupId ([string]$item.EntraGroup.Id))) {
                        throw 'Entra membership still present after removal.'
                    }

                    $removedEntra += [pscustomobject]@{
                        UPN  = $userPlan.UPN
                        Name = $item.Name
                    }
                }

                Write-OK (
                    "Removed: {0} | {1}" -f
                    $userPlan.UPN,
                    $item.Name
                )
            }
            catch {
                $friendly = Get-FriendlyRemovalFailure `
                    -GroupName $item.Name `
                    -Method $item.Method `
                    -TechnicalError $_.Exception.Message

                $needsAttention += [pscustomobject]@{
                    UPN    = $userPlan.UPN
                    Name   = $item.Name
                    Reason = $friendly.Reason
                    Action = $friendly.Action
                }

                Write-Warn (
                    "Could not remove: {0} | {1}" -f
                    $userPlan.UPN,
                    $item.Name
                )
            }
        }
    }
    $syncResult = [pscustomobject]@{ Status='NotNeeded'; Server=''; Detail='' }

    if ($removedAD.Count -gt 0) {
        Write-Host ""
        Write-Host "ENTRA SYNC"

        if ([string]::IsNullOrWhiteSpace($SyncServer)) {
            $SyncServer = (Read-Host "Entra Connect sync server (blank = scheduled sync only)").Trim()
        }

        $syncResult = Start-EntraDeltaSync -Server $SyncServer

        if ($syncResult.Status -eq 'Triggered') {
            Write-OK "Delta sync triggered"
        }
        elseif ($syncResult.Status -eq 'ScheduledPending') {
            Write-Info "Delta sync not triggered."
        }
        else {
            Write-Warn "Delta sync failed; AD group changes remain authoritative."
        }
    }

    $protectedCount = 0

    foreach ($userPlan in $userPlans) {
        $protectedCount += @(
            $userPlan.AllRows |
            Where-Object { $_.Protected }
        ).Count
    }

    Write-Host ""
    Write-Host "SUMMARY"
    Write-Host ("Users processed: {0}" -f $userPlans.Count)
    Write-Host ("Active Directory groups removed: {0}" -f $removedAD.Count)
    Write-Host ("Entra ID groups removed: {0}" -f $removedEntra.Count)
    Write-Host ("Protected groups kept: {0}" -f $protectedCount)
    Write-Host ("Needs attention: {0}" -f $needsAttention.Count)

    if ($removedAD.Count -gt 0) {
        Write-Host ("Entra sync: {0}" -f $syncResult.Status)
    }

    Write-Host ""
    if ($needsAttention.Count -gt 0) {
        Write-Warn ("{0} membership(s) were not removed." -f $needsAttention.Count)
    }
    else {
        Write-OK "Group removal complete."
    }

    Write-Host ""
    Write-Host "TICKET NOTE"

    if (($removedAD.Count + $removedEntra.Count) -eq 0) {
        Write-Host "- No changes made."
    }
    else {
        foreach ($item in $removedAD) {
            Write-Host ("- Removed AD group: {0} | {1}" -f $item.UPN, $item.Name)
        }
        foreach ($item in $removedEntra) {
            Write-Host ("- Removed Entra group: {0} | {1}" -f $item.UPN, $item.Name)
        }
        if ($syncResult.Status -eq 'Triggered') {
            Write-Host "- Entra delta sync triggered"
        }
    }

    Pause-End
}
catch {
    Write-Host ""
    Write-Fail $_.Exception.Message
    Pause-End
}