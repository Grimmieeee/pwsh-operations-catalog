<#
.VERSION 1.0.1
#>
#Requires -Version 5.1

<#
GET-USER-GROUPS.ps1

OBJECTIVE
Find a user's direct group memberships in AD and Entra ID.

INPUT
- One UPN
- Multiple UPNs
- TXT/CSV path containing users

SOURCE BEHAVIOR
- Active Directory and Entra ID are checked independently for every user.
- A synced group may appear in both sections. This is intentional evidence, not duplication.
- Entra groups are marked [Synced] or [Cloud] and [Dynamic] when applicable.

CHANGES
Read-only. No changes are made.
#>

[CmdletBinding()]
param(
    [Alias('UPN')]
    [string[]]$InputObject
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = 'Stop'

function Write-Info { param([string]$Message) Write-Host "[INFO] $Message" }

function Write-OK {
    param([string]$Message)
    Write-Host "[OK]   $Message" -ForegroundColor Green
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
    Write-Host 'Press Enter to close session.' -NoNewline
    Read-Host | Out-Null
}

function Write-SessionComplete {
    param([string]$Status,[string]$Detail)
    Write-Host ""
    Write-Host ("SESSION COMPLETE // {0}" -f $Status)
    if ($Detail) { Write-Host $Detail }
    Write-Host "No directory changes made."
}

function Get-GraphFailureState {
    param([System.Management.Automation.ErrorRecord]$Record)
    foreach ($code in @($Record.Exception.ResponseStatusCode,
                        $Record.Exception.StatusCode,
                        $Record.Exception.Response.StatusCode)) {
        if ($null -ne $code -and [int]$code -eq 404) { return 'User not found' }
    }
    if ($Record.Exception -is [System.IO.FileNotFoundException]) { return 'Unavailable' }
    if ($Record.Exception.Message -eq 'The user was not found in the connected tenant.') {
        return 'User not found'
    }
    return 'Failed'
}

function Ensure-GraphAuthenticationModule {
    $module = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw [System.IO.FileNotFoundException]::new("Microsoft.Graph.Authentication is required but is not installed. Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser")
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
                Write-OK "Graph connected"
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
    $oldWarningPreference = $WarningPreference

    try {
        $WarningPreference = 'SilentlyContinue'
        $module = Get-Module -ListAvailable -Name ActiveDirectory -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1

        if (-not $module) {
            Write-Warn "ActiveDirectory module is not installed."
            Write-Host "Install RSAT Active Directory tools, then run the script again."
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
        $WarningPreference = $oldWarningPreference
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

    return $null
}

function Get-ADUserAndGroups {
    param(
        [string]$UserPrincipalName,
        $GraphUser
    )

    $result = [pscustomobject]@{
        Available = $false
        Status = 'Unavailable'
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
        if (-not $user) { $result.Status = 'User not found'; return $result }

        $result.Groups = @(
            Get-ADPrincipalGroupMembership -Identity $user.DistinguishedName -Server $server -ErrorAction Stop -WarningAction SilentlyContinue
        )
        $result.Status = 'Checked'
        return $result
    }
    catch {
        $result.Status = 'Failed'
        $result.Error = $_.Exception.Message
        return $result
    }
}

function Get-GroupDisplayInfo {
    param([string]$Name)

    $rawName=([string]$Name).Trim()

    return [pscustomobject]@{
        Name      = $rawName
        Protected = ($rawName -ieq 'Domain Users')
    }
}

function Get-SeparatedGroupRows {
    param(
        [object[]]$ADGroups,
        [object[]]$EntraGroups
    )

    $adRows = @()
    $entraRows = @()

    foreach ($group in @($ADGroups)) {
        $rawName = ([string]$group.Name).Trim()
        if (-not $rawName) { continue }

        $display = Get-GroupDisplayInfo -Name $rawName
        $adRows += [pscustomobject]@{
            RawName=$rawName; Name=$display.Name; Protected=[bool]$display.Protected
            Source='AD'; SyncState=''; IsDynamic=$false; IsMicrosoft365=$false
        }
    }

    foreach ($group in @($EntraGroups)) {
        $rawName = ([string]$group.Name).Trim()
        if (-not $rawName) { continue }

        $display = Get-GroupDisplayInfo -Name $rawName
        $entraRows += [pscustomobject]@{
            RawName=$rawName; Name=$display.Name; Protected=[bool]$display.Protected
            Source='Entra'
            SyncState=$(if ($group.OnPremisesSyncEnabled) { 'Synced' } else { 'Cloud' })
            IsDynamic=[bool]$group.IsDynamic
            IsMicrosoft365=[bool]$group.IsMicrosoft365
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
    param([string]$Title,[object[]]$Rows,[string]$Status,[string]$Detail)
    Write-Host ""
    Write-Host $Title
    if ($Status -ne 'Checked') {
        Write-Host $Status
        if ($Detail) { Write-Host ("Reason: {0}" -f $Detail) }
        return
    }
    if (-not $Rows -or $Rows.Count -eq 0) {
        Write-Host "Checked - no groups found"
        return
    }
    foreach ($row in $Rows) {
        Write-Host ("- {0}{1}" -f $row.Name,(Get-GroupMarkers -Row $row))
    }
}

function Get-InputUsers {
    param([string[]]$Values)

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "User UPN or TXT/CSV path").Trim().Trim('"')
        if ($entered) { $rawValues=@($entered) }
    }

    foreach ($value in $rawValues) {
        $clean=([string]$value).Trim().Trim('"')
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($clean) -ieq '.csv') {
                foreach ($row in @(Import-Csv -LiteralPath $clean -ErrorAction Stop)) {
                    $candidate=$null
                    foreach ($name in @('UPN','UserPrincipalName','Email','Address','User','Name','Input')) {
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

function Offer-VerifiedCsv {
    param([object[]]$Rows,[string]$DefaultName='user-group-memberships.csv')

    if (-not $Rows -or $Rows.Count -eq 0) { return }
    if ((Read-Host "Export results to CSV [Y/N]").Trim() -notmatch '^(?i)y$') { return }

    $desktop=[Environment]::GetFolderPath('Desktop')
    if (-not $desktop -or -not (Test-Path -LiteralPath $desktop -PathType Container)) {
        $desktop=(Get-Location).Path
    }
    $defaultPath=Join-Path $desktop $DefaultName
    $path=(Read-Host "CSV output path [blank for $defaultPath]").Trim().Trim('"')
    if (-not $path) { $path=$defaultPath }

    $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)

    if ($check.Count -ne $Rows.Count) {
        throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
    }

    $columns=@($Rows[0].PSObject.Properties.Name)
    $expected=@($Rows | ConvertTo-Csv -NoTypeInformation | ConvertFrom-Csv)
    if (Compare-Object -ReferenceObject $expected -DifferenceObject $check -Property $columns) {
        throw "CSV verification failed. Exported fields differ from the displayed results."
    }
    Write-OK "Exported and verified: $path"
}

try {
    Write-Host 'Get User Groups'
    Write-Host "Find a user's direct group memberships in AD and Entra ID."
    Write-Host "Read only. Direct membership does not establish effective access."
    Write-Host ("Started: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))
    Write-Host ""

    $usersToCheck=@(Get-InputUsers -Values $InputObject)
    if ($usersToCheck.Count -eq 0) { throw "No users were provided." }
    $exportRows=New-Object System.Collections.ArrayList
    $outcomes=New-Object System.Collections.ArrayList
    $invalid=0

    foreach ($UPN in $usersToCheck) {
        $UPN=([string]$UPN).Trim()
        if ($UPN -notmatch '^[^@\s]+@[^@\s]+$') {
            Write-Warn "Skipped invalid UPN: $UPN"
            $invalid++
            continue
        }
        $graphUser=$null
        $graphGroups=@()
        $graphStatus='Checked'
        $graphError=''
        $resolvingUser=$true
        try {
            $graphUser=Connect-GraphForUser -UserPrincipalName $UPN -Scopes @('User.Read.All','Group.Read.All')
            $resolvingUser=$false
            $graphGroups=@(Get-GraphGroups -UserId ([string]$graphUser.id))
        }
        catch {
            $graphStatus=Get-GraphFailureState -Record $_
            # A 404 during group retrieval does not mean the user was not found.
            if (-not $resolvingUser -and $graphStatus -eq 'User not found') { $graphStatus='Failed' }
            $graphError=$_.Exception.Message
        }
        $adResult=Get-ADUserAndGroups -UserPrincipalName $UPN -GraphUser $graphUser
        $groupSections=Get-SeparatedGroupRows -ADGroups @($adResult.Groups) -EntraGroups @($graphGroups)
        $displayName=$UPN
        if ($graphUser -and $graphUser.displayName) { $displayName=[string]$graphUser.displayName }
        elseif ($adResult.User -and $adResult.User.DisplayName) { $displayName=[string]$adResult.User.DisplayName }

        Write-Host ""
        Write-Host ("USER // {0}" -f $displayName)
        Write-Host $UPN
        $sources=@(
            [pscustomobject]@{Name='Active Directory';Title='ACTIVE DIRECTORY GROUPS';Status=$adResult.Status;Error=$adResult.Error;Rows=@($groupSections.AD)},
            [pscustomobject]@{Name='Entra ID';Title='ENTRA ID GROUPS';Status=$graphStatus;Error=$graphError;Rows=@($groupSections.Entra)}
        )
        foreach ($source in $sources) {
            Write-GroupSection -Title $source.Title -Rows $source.Rows -Status $source.Status -Detail $source.Error
            [void]$outcomes.Add($source.Status)
            $coverage=$source.Status
            if ($source.Status -eq 'Checked' -and $source.Rows.Count -eq 0) { $coverage='Checked - no groups found' }
            $rows=@($source.Rows)
            if ($source.Status -ne 'Checked' -or $rows.Count -eq 0) { $rows=@($null) }
            foreach ($row in $rows) {
                [void]$exportRows.Add([pscustomobject]@{
                    UserUPN=$UPN; UserName=$displayName; Source=$source.Name
                    Group=$(if ($row) { $row.Name } else { '' })
                    SyncState=$(if ($row) { $row.SyncState } else { '' })
                    Dynamic=[bool]($row -and $row.IsDynamic)
                    Microsoft365=[bool]($row -and $row.IsMicrosoft365)
                    Protected=[bool]($row -and $row.Protected)
                    Coverage=$coverage; Error=$source.Error
                })
            }
        }
    }
    $complete=@($outcomes | Where-Object { $_ -eq 'Checked' }).Count
    $notFound=@($outcomes | Where-Object { $_ -eq 'User not found' }).Count
    $status='UNSUCCESSFUL'
    $detail='No membership checks completed. Review errors above.'
    if ($outcomes.Count -gt 0 -and $complete -eq $outcomes.Count -and $invalid -eq 0) {
        $status='SUCCESS'
        $detail='AD and Entra checks complete for all supplied users.'
    }
    elseif ($complete -gt 0) {
        $status='PARTIAL'
        $detail='Some checks incomplete. Review results above.'
    }
    elseif ($outcomes.Count -gt 0 -and $notFound -eq $outcomes.Count -and $invalid -eq 0) {
        $status='USER NOT FOUND'
        $detail='No supplied users found in either directory.'
    }
    if ($invalid -gt 0) { $detail += " Invalid inputs skipped: $invalid." }
    try { Offer-VerifiedCsv -Rows @($exportRows) }
    catch {
        Write-Fail ("CSV export failed: {0}" -f $_.Exception.Message)
        $status='PARTIAL'
        $detail='CSV export failed; export is unverified. Review results above.'
    }
    Write-SessionComplete -Status $status -Detail $detail
}
catch {
    Write-Fail $_.Exception.Message
    Write-SessionComplete -Status 'UNSUCCESSFUL' -Detail 'Lookup incomplete. Review the error above.'
}
finally {
    Pause-End
}
