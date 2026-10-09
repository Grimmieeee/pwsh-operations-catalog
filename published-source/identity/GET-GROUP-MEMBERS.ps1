#Requires -Version 5.1

<#
GROUP MEMBERS LOOKUP

OBJECTIVE
Show direct members of one or more groups.

LOOKUP ORDER
1. Exchange Online distribution group
2. Entra ID group
3. Active Directory group

INPUT
One group name/email, multiple group values, or a TXT/CSV path.

CHANGES
Read-only. No changes are made.

RUN
Right-click > Run with PowerShell
or
Right-click > Run with PowerShell 7

Compatible with Windows PowerShell 5.1 and PowerShell 7.
#>


[CmdletBinding()]
param(
    [Alias('Group')]
    [string[]]$InputObject
)

$ErrorActionPreference = 'Stop'

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

function Get-InputGroups {
    param([string[]]$Values)

    $items=New-Object System.Collections.ArrayList
    $rawValues=@($Values | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

    if ($rawValues.Count -eq 0) {
        $entered=(Read-Host "Group name/email or TXT/CSV path").Trim().Trim('"')
        if ($entered) { $rawValues=@($entered) }
    }

    foreach ($value in $rawValues) {
        $clean=([string]$value).Trim().Trim('"')
        if (-not $clean) { continue }

        if (Test-Path -LiteralPath $clean -PathType Leaf) {
            if ([System.IO.Path]::GetExtension($clean) -ieq '.csv') {
                foreach ($row in @(Import-Csv -LiteralPath $clean -ErrorAction Stop)) {
                    $candidate=$null
                    foreach ($name in @('Group','GroupName','Name','Email','Address','Mail','Input')) {
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
    param([object[]]$Rows,[string]$DefaultName='group-members.csv')

    if (-not $Rows -or $Rows.Count -eq 0) { return }
    if ((Read-Host "Export member detail to CSV [Y/N]").Trim() -notmatch '^(?i)y$') { return }

    $path=(Read-Host "CSV output path [blank for .\$DefaultName]").Trim().Trim('"')
    if (-not $path) { $path=Join-Path (Get-Location).Path $DefaultName }

    $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)
    if ($check.Count -ne $Rows.Count) {
        throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
    }

    $expected=@($Rows | ForEach-Object { "{0}|{1}|{2}|{3}|{4}" -f $_.GroupInput,$_.Source,$_.GroupName,$_.MemberName,$_.MemberAddress })
    $actual=@($check | ForEach-Object { "{0}|{1}|{2}|{3}|{4}" -f $_.GroupInput,$_.Source,$_.GroupName,$_.MemberName,$_.MemberAddress })

    if (@(Compare-Object -ReferenceObject $expected -DifferenceObject $actual -SyncWindow 0).Count -gt 0) {
        throw "CSV verification failed. Exported content did not match the in-memory results."
    }

    Write-Ok "Exported and verified: $path"
}

try {
    Write-Host ""
    Write-Host "GROUP MEMBERS LOOKUP"
    Write-Host "READ-ONLY. NO CHANGES MADE."
    Write-Host ""

    $groupsToCheck=@(Get-InputGroups -Values $InputObject)
    if ($groupsToCheck.Count -eq 0) { throw "At least one group is required." }

    $detailRows=New-Object System.Collections.ArrayList
    $summaryRows=New-Object System.Collections.ArrayList

    $exoOk=$false
    if (Ensure-Module -Name 'ExchangeOnlineManagement') {
        try {
            $connection=Get-ConnectionInformation -ErrorAction SilentlyContinue
            if (-not $connection) {
                $exoCommand=Get-Command Connect-ExchangeOnline -ErrorAction Stop
                $exoParameters=@{ ErrorAction='Stop' }
                if ($exoCommand.Parameters.ContainsKey('ShowBanner')) { $exoParameters['ShowBanner']=$false }
                Connect-ExchangeOnline @exoParameters | Out-Null
            }
            $exoOk=$true
            Write-Ok "Exchange connected"
        }
        catch {
            Write-Warn "Exchange unavailable -- distribution group lookup skipped"
        }
    }

    foreach ($inputGroup in $groupsToCheck) {
        Write-Host ""
        Write-Host "GROUP"
        Write-Host ("Input   : {0}" -f $inputGroup)

        $groupResolved=$false
        $source=''
        $groupName=''
        $groupMail=''
        $members=@()

        if ($exoOk) {
            try {
                $dl=Get-DistributionGroup -Identity $inputGroup -ErrorAction Stop
                if ($dl) {
                    $groupResolved=$true
                    $source='Exchange Distribution Group'
                    $groupName=[string]$dl.DisplayName
                    $groupMail=[string]$dl.PrimarySmtpAddress
                    $members=@(Get-DistributionGroupMember -Identity $dl.Identity -ResultSize Unlimited -ErrorAction Stop | Sort-Object DisplayName)

                    foreach ($m in $members) {
                        $memberName=[string]$m.DisplayName
                        if (-not $memberName) { $memberName=[string]$m.Name }
                        $address=[string]$m.PrimarySmtpAddress
                        if (-not $address) { $address=[string]$m.WindowsEmailAddress }

                        [void]$detailRows.Add([pscustomobject]@{
                            GroupInput=$inputGroup; Source=$source; GroupName=$groupName; GroupMail=$groupMail
                            MemberName=$memberName; MemberAddress=$address; MemberType=[string]$m.RecipientType
                        })
                    }
                }
            }
            catch {}
        }

        if (-not $groupResolved) {
            $graphGroup=Connect-GraphForGroup -GroupInput $inputGroup

            if ($graphGroup) {
                try {
                    $graphMembers=@(
                        Get-MgGroupMember -GroupId $graphGroup.Id -All -ErrorAction Stop
                    )

                    $groupResolved=$true
                    $source='Entra ID'
                    $groupName=[string]$graphGroup.DisplayName
                    $groupMail=[string]$graphGroup.Mail
                    $members=$graphMembers

                    foreach ($m in $graphMembers) {
                        $memberName=[string]$m.AdditionalProperties['displayName']
                        if (-not $memberName) { $memberName=[string]$m.AdditionalProperties['userPrincipalName'] }

                        $address=[string]$m.AdditionalProperties['userPrincipalName']
                        if (-not $address) { $address=[string]$m.AdditionalProperties['mail'] }

                        $memberType=[string]$m.AdditionalProperties['@odata.type']
                        if ($memberType) { $memberType=$memberType -replace '^#microsoft\.graph\.','' }

                        [void]$detailRows.Add([pscustomobject]@{
                            GroupInput=$inputGroup; Source=$source; GroupName=$groupName; GroupMail=$groupMail
                            MemberName=$memberName; MemberAddress=$address; MemberType=$memberType
                        })
                    }
                }
                catch {
                    Write-Warn "Entra group resolved, but members could not be read."
                }
            }
        }

        if (-not $groupResolved) {
            $adGroup=Get-AdGroupByInput -GroupInput $inputGroup

            if ($adGroup) {
                $groupResolved=$true
                $source='Active Directory'
                $groupName=$inputGroup
                $members=@(Get-AdMemberNames -SearchResult $adGroup)

                foreach ($memberName in $members) {
                    [void]$detailRows.Add([pscustomobject]@{
                        GroupInput=$inputGroup; Source=$source; GroupName=$groupName; GroupMail=''
                        MemberName=$memberName; MemberAddress=''; MemberType='Directory object'
                    })
                }
            }
        }

        if ($groupResolved) {
            Write-Host ("Source  : {0}" -f $source)
            Write-Host ("Name    : {0}" -f $groupName)
            if ($groupMail) { Write-Host ("Email   : {0}" -f $groupMail) }
            Write-Host ("Members : {0}" -f $members.Count)
            Write-Host ""

            if ($members.Count -eq 0) {
                Write-Host "  none"
            }
            else {
                foreach ($row in @($detailRows | Where-Object { $_.GroupInput -eq $inputGroup })) {
                    if ($row.MemberAddress) { Write-Host ("  - {0} <{1}>" -f $row.MemberName,$row.MemberAddress) }
                    else { Write-Host ("  - {0}" -f $row.MemberName) }
                }
            }

            [void]$summaryRows.Add([pscustomobject]@{
                GroupInput=$inputGroup; Source=$source; GroupName=$groupName; Members=$members.Count; Status='Found'
            })
        }
        else {
            Write-Host "Source  : Not resolved"
            Write-Host "Members : 0"
            Write-Warn "Group was not found in Exchange, Entra ID, or Active Directory."

            [void]$summaryRows.Add([pscustomobject]@{
                GroupInput=$inputGroup; Source=''; GroupName=''; Members=0; Status='NotFound'
            })
        }
    }

    Write-Host ""
    Write-Host "TICKET SUMMARY"
    Write-Host ("Groups checked : {0}" -f $groupsToCheck.Count)
    Write-Host ("Found          : {0}" -f @($summaryRows | Where-Object { $_.Status -eq 'Found' }).Count)
    Write-Host ("Not found      : {0}" -f @($summaryRows | Where-Object { $_.Status -eq 'NotFound' }).Count)
    Write-Host ("Member rows    : {0}" -f $detailRows.Count)

    Offer-VerifiedCsv -Rows @($detailRows)

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
