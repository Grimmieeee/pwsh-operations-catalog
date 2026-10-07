#Requires -Version 5.1

<#
GROUP MEMBERS LOOKUP

OBJECTIVE
Show members of one group.

LOOKUP ORDER
1. Exchange Online distribution group
2. Entra ID group
3. Active Directory group

INPUT
Group display name or email address.

CHANGES
Read-only. No changes are made.

RUN
Right-click > Run with PowerShell
or
Right-click > Run with PowerShell 7

Compatible with Windows PowerShell 5.1 and PowerShell 7.
#>


if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-Ok   { param($Msg) Write-Host "[OK]   $Msg" }
function Write-Info { param($Msg) Write-Host "[INFO] $Msg" }
function Write-Warn { param($Msg) Write-Host "[WARN] $Msg" }
function Write-Fail { param($Msg) Write-Host "[FAIL] $Msg" }

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

function Get-ShortError {
    param($ErrorRecord)

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Ensure-Module {
    param([string]$Name)

    $module = Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        Write-Fail "$Name is required but is not installed."
        Write-Host "Install with: Install-Module $Name -Scope CurrentUser"
        return $false
    }

    try {
        Import-Module $module.Path -Force -ErrorAction Stop
        return $true
    }
    catch {
        Write-Fail "Unable to load ${Name}: $(Get-ShortError $_)"
        return $false
    }
}

function Test-ScopesPresent {
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

function Escape-ODataValue {
    param([string]$Value)

    return ([string]$Value).Replace("'", "''")
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

function Get-GraphGroupByInput {
    param([string]$GroupInput)

    $escaped = Escape-ODataValue -Value $GroupInput
    $group = $null

    try {
        $group = Get-MgGroup `
            -Filter "displayName eq '$escaped'" `
            -ErrorAction Stop |
            Select-Object -First 1
    }
    catch {
    }

    if (-not $group -and $GroupInput -match '@') {
        try {
            $group = Get-MgGroup `
                -Filter "mail eq '$escaped'" `
                -ErrorAction Stop |
                Select-Object -First 1
        }
        catch {
        }
    }

    if (-not $group -and $GroupInput -notmatch '@') {
        try {
            $group = Get-MgGroup `
                -Filter "mailNickname eq '$escaped'" `
                -ErrorAction Stop |
                Select-Object -First 1
        }
        catch {
        }
    }

    return $group
}

function Test-GraphSessionForGroup {
    param(
        [string]$GroupInput,
        [string[]]$RequiredScopes
    )

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        -not $context -or
        -not (Test-ScopesPresent `
            -Context $context `
            -RequiredScopes $RequiredScopes)
    ) {
        return $null
    }

    try {
        $group = Get-GraphGroupByInput -GroupInput $GroupInput

        if ($group) {
            Write-Ok "Existing Microsoft Graph session detected"
            Write-Host ("Account : {0}" -f $context.Account)
            return $group
        }
    }
    catch {
    }

    return $null
}

function Connect-GraphForGroup {
    param([string]$GroupInput)

    $requiredScopes = @(
        'Group.Read.All',
        'User.Read.All'
    )

    if (-not (Ensure-Module -Name 'Microsoft.Graph.Authentication')) {
        return $null
    }

    if (-not (Ensure-Module -Name 'Microsoft.Graph.Groups')) {
        return $null
    }

    $existingGroup = Test-GraphSessionForGroup `
        -GroupInput $GroupInput `
        -RequiredScopes $requiredScopes

    if ($existingGroup) {
        return $existingGroup
    }

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if ($context) {
        Write-Info "Cached Graph session does not resolve this group. Reconnecting."
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
        }
    }
    else {
        Write-Info "No usable Microsoft Graph session detected."
    }

    try {
        Write-Info "Opening Microsoft sign-in..."

        $command = Get-Command Connect-MgGraph -ErrorAction Stop
        $parameters = @{
            Scopes      = $requiredScopes
            ErrorAction = 'Stop'
        }

        if ($command.Parameters.ContainsKey('ContextScope')) {
            $parameters['ContextScope'] = 'Process'
        }

        if ($command.Parameters.ContainsKey('NoWelcome')) {
            $parameters['NoWelcome'] = $true
        }

        if (
            $GroupInput -match '^[^@]+@(.+)$' -and
            $command.Parameters.ContainsKey('TenantId')
        ) {
            $parameters['TenantId'] = $Matches[1]
        }

        Connect-MgGraph @parameters | Out-Null

        $group = Get-GraphGroupByInput -GroupInput $GroupInput

        if (-not $group) {
            Write-Warn "Graph connected, but the group was not found in the connected tenant."
            return $null
        }

        $context = Get-MgContext -ErrorAction SilentlyContinue

        Write-Ok "Microsoft Graph connected"

        if ($context -and $context.Account) {
            Write-Host ("Account : {0}" -f $context.Account)
        }

        return $group
    }
    catch {
        Write-Warn "Graph unavailable: $(Get-ShortError $_)"
        return $null
    }
}

function Get-AdGroupByInput {
    param([string]$GroupInput)

    try {
        $escaped = Escape-LdapFilterValue -Value $GroupInput

        if ($GroupInput -match '@') {
            $filter = "(&(objectCategory=group)(|(mail=$escaped)(proxyAddresses=SMTP:$escaped)(proxyAddresses=smtp:$escaped)))"
        }
        else {
            $filter = "(&(objectCategory=group)(|(cn=$escaped)(sAMAccountName=$escaped)(mail=$escaped)))"
        }

        $searcher = New-Object System.DirectoryServices.DirectorySearcher
        $searcher.Filter = $filter
        $searcher.PageSize = 100
        [void]$searcher.PropertiesToLoad.Add('member')

        return $searcher.FindOne()
    }
    catch {
        return $null
    }
}

function Get-AdMemberNames {
    param($SearchResult)

    $members = @()

    if (
        -not $SearchResult -or
        -not $SearchResult.Properties['member']
    ) {
        return $members
    }

    foreach ($dn in @($SearchResult.Properties['member'])) {
        $name = ""

        try {
            $entry = New-Object System.DirectoryServices.DirectoryEntry(
                "LDAP://$dn"
            )

            $name = [string]$entry.Properties['displayName'].Value

            if ([string]::IsNullOrWhiteSpace($name)) {
                $name = [string]$entry.Properties['name'].Value
            }
        }
        catch {
        }

        if ([string]::IsNullOrWhiteSpace($name)) {
            if ($dn -match '^CN=([^,]+)') {
                $name = $Matches[1]
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($name)) {
            $members += $name
        }
    }

    return @($members | Sort-Object -Unique)
}

try {
    Write-Host ""
    Write-Host "GROUP MEMBERS LOOKUP"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    $inputGroup = (Read-Host "Group name or email").Trim()

    if ([string]::IsNullOrWhiteSpace($inputGroup)) {
        throw "Group name or email is required."
    }

    Write-Host ""

    $members = @()
    $source = ""
    $groupResolved = $false

    # Exchange Online distribution group.
    $exoOk = $false

    if (Ensure-Module -Name 'ExchangeOnlineManagement') {
        try {
            $connection = Get-ConnectionInformation -ErrorAction SilentlyContinue

            if (-not $connection) {
                $exoCommand = Get-Command Connect-ExchangeOnline -ErrorAction Stop
                $exoParameters = @{
                    ErrorAction = 'Stop'
                }

                if ($exoCommand.Parameters.ContainsKey('ShowBanner')) {
                    $exoParameters['ShowBanner'] = $false
                }

                Connect-ExchangeOnline @exoParameters
            }

            $exoOk = $true
            Write-Ok "Exchange connected"
        }
        catch {
            Write-Warn "Exchange unavailable -- distribution group lookup skipped"
        }
    }

    if ($exoOk) {
        try {
            $dl = Get-DistributionGroup `
                -Identity $inputGroup `
                -ErrorAction Stop

            if ($dl) {
                $groupResolved = $true

                $members = @(
                    Get-DistributionGroupMember `
                        -Identity $dl.Identity `
                        -ResultSize Unlimited `
                        -ErrorAction Stop |
                    ForEach-Object {
                        if ($_.DisplayName) {
                            $_.DisplayName
                        }
                        elseif ($_.Name) {
                            $_.Name
                        }
                    } |
                    Where-Object {
                        -not [string]::IsNullOrWhiteSpace($_)
                    } |
                    Sort-Object -Unique
                )

                $source = 'Exchange Distribution Group'
            }
        }
        catch {
        }
    }

    # Entra ID group.
    if (-not $groupResolved) {
        $graphGroup = Connect-GraphForGroup -GroupInput $inputGroup

        if ($graphGroup) {
            try {
                $groupResolved = $true

                $members = @(
                    Get-MgGroupMember `
                        -GroupId $graphGroup.Id `
                        -All `
                        -ErrorAction Stop |
                    ForEach-Object {
                        $name = [string]$_.AdditionalProperties['displayName']

                        if ([string]::IsNullOrWhiteSpace($name)) {
                            $name = [string]$_.AdditionalProperties['userPrincipalName']
                        }

                        $name
                    } |
                    Where-Object {
                        -not [string]::IsNullOrWhiteSpace($_)
                    } |
                    Sort-Object -Unique
                )

                $source = 'Entra ID'
            }
            catch {
                Write-Warn "Entra group resolved, but members could not be read."
            }
        }
    }

    # Active Directory group.
    if (-not $groupResolved) {
        $adGroup = Get-AdGroupByInput -GroupInput $inputGroup

        if ($adGroup) {
            $groupResolved = $true
            $members = @(Get-AdMemberNames -SearchResult $adGroup)
            $source = 'Active Directory'
        }
    }

    Write-Host ""
    Write-Host "RESULT"
    Write-Host "--------------------------------------"

    if ($groupResolved) {
        Write-Host ("Source  : {0}" -f $source)

        if ($members.Count -gt 0) {
            Write-Host ("Members : {0}" -f $members.Count)
            Write-Host ""

            foreach ($member in $members) {
                Write-Host ("  {0}" -f $member)
            }
        }
        else {
            Write-Host "Members : 0"
            Write-Warn "Group resolved but contains no readable members."
        }
    }
    else {
        Write-Host "Source  : Not resolved"
        Write-Host "Members : 0"
        Write-Warn "Group was not found in Exchange, Entra ID, or Active Directory."
    }
    Write-Host ""
    Write-Ok "Complete. No changes made."
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}
