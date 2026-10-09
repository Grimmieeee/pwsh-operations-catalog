#Requires -Version 5.1

<#
TENANT GROUP OWNERS REVIEW

OBJECTIVE
Read-only review of owners for all current Microsoft Teams and Entra ID groups.

SCOPE
- Microsoft Teams
- Microsoft 365 Groups
- Security Groups
- Mail-enabled Groups
- Exchange Online distribution groups

OUTPUT
- Groups separated by type
- Group types and group names sorted alphabetically
- Owner lookup status remains visible
- Optional Y/N text export to Desktop
- Read-only.

RUN
Right-click > Run with PowerShell
or
Right-click > Run with PowerShell 7

Compatible with Windows PowerShell 5.1 and PowerShell 7.
#>

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

try {
    [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {
}

function Write-OK {
    param([string]$Message)
    Write-Host "[OK]   $Message"
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message"
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message"
}

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to EXIT" | Out-Null
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

    $module=Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install with: Install-Module $Name -Scope CurrentUser"
    }

    try {
        Import-Module $module.Path -Force -WarningAction SilentlyContinue -ErrorAction Stop
    }
    catch {
        throw "Unable to load $Name: $(Get-ShortError $_)"
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

function Connect-GraphReadOnly {
    $requiredScopes = @(
        "Group.Read.All",
        "User.Read.All"
    )

    Ensure-Module -Name "Microsoft.Graph.Authentication"
    Ensure-Module -Name "Microsoft.Graph.Groups"

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-ScopesPresent `
            -Context $context `
            -RequiredScopes $requiredScopes)
    ) {
        return
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

    $command = Get-Command `
        -Name Connect-MgGraph `
        -ErrorAction Stop

    $parameters = @{
        Scopes      = $requiredScopes
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ContextScope")) {
        $parameters["ContextScope"] = "Process"
    }

    if ($command.Parameters.ContainsKey("NoWelcome")) {
        $parameters["NoWelcome"] = $true
    }

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        -not $context -or
        -not (
            Test-ScopesPresent `
                -Context $context `
                -RequiredScopes $requiredScopes
        )
    ) {
        throw "Microsoft Graph connected without the required read permissions."
    }
}

function Get-ExchangeConnection {
    $command = Get-Command `
        -Name Get-ConnectionInformation `
        -ErrorAction SilentlyContinue

    if (-not $command) {
        return $null
    }

    $connections = @(
        Get-ConnectionInformation `
            -ErrorAction SilentlyContinue |
        Where-Object {
            $_.State -eq "Connected"
        }
    )

    if ($connections.Count -eq 0) {
        return $null
    }

    return $connections[0]
}

function Connect-ExchangeReadOnly {
    Ensure-Module -Name "ExchangeOnlineManagement"

    $connection = Get-ExchangeConnection

    if ($connection) {
        return
    }

    Connect-ExchangeOnline `
        -ShowBanner:$false `
        -ErrorAction Stop

    $connection = Get-ExchangeConnection

    if (-not $connection) {
        throw "Exchange Online connection could not be verified."
    }
}

function Resolve-ExchangeOwner {
    param($Identity)

    try {
        $recipient = Get-Recipient `
            -Identity $Identity `
            -ErrorAction Stop

        return [pscustomobject]@{
            id                = ""
            displayName       = [string]$recipient.DisplayName
            userPrincipalName = [string]$recipient.UserPrincipalName
            mail              = [string]$recipient.PrimarySmtpAddress
        }
    }
    catch {
        return [pscustomobject]@{
            id                = ""
            displayName       = [string]$Identity
            userPrincipalName = ""
            mail              = ""
        }
    }
}

function Get-ExchangeGroupOwners {
    param($Group)

    if (
        -not $Group.MailEnabled -or
        [string]::IsNullOrWhiteSpace([string]$Group.Mail)
    ) {
        throw "Group is not available for Exchange Online owner lookup."
    }

    if (@($Group.GroupTypes) -contains "Unified") {
        $exchangeGroup = Get-UnifiedGroup `
            -Identity $Group.Mail `
            -ErrorAction Stop
    }
    else {
        $exchangeGroup = Get-DistributionGroup `
            -Identity $Group.Mail `
            -ErrorAction Stop
    }

    $owners = @()

    foreach ($ownerIdentity in @($exchangeGroup.ManagedBy)) {
        $owners += Resolve-ExchangeOwner `
            -Identity $ownerIdentity
    }

    return @($owners)
}

function Get-GroupType {
    param($Group)

    if (
        @($Group.ResourceProvisioningOptions) -contains "Team"
    ) {
        return "TEAMS"
    }

    if (@($Group.GroupTypes) -contains "Unified") {
        return "MICROSOFT 365 GROUPS"
    }

    if ($Group.MailEnabled -and $Group.SecurityEnabled) {
        return "MAIL-ENABLED SECURITY GROUPS"
    }

    if ($Group.MailEnabled) {
        return "DISTRIBUTION GROUPS"
    }

    return "SECURITY GROUPS"
}

function Get-OwnerDisplay {
    param($Owner)

    $name = ""
    $identity = ""

    if ($Owner.displayName) {
        $name = [string]$Owner.displayName
    }

    if ($Owner.userPrincipalName) {
        $identity = [string]$Owner.userPrincipalName
    }
    elseif ($Owner.mail) {
        $identity = [string]$Owner.mail
    }

    if (
        -not [string]::IsNullOrWhiteSpace($name) -and
        -not [string]::IsNullOrWhiteSpace($identity)
    ) {
        return ("{0} <{1}>" -f $name, $identity)
    }

    if (-not [string]::IsNullOrWhiteSpace($name)) {
        return $name
    }

    if (-not [string]::IsNullOrWhiteSpace($identity)) {
        return $identity
    }

    if ($Owner.id) {
        return ("Directory object {0}" -f $Owner.id)
    }

    return "Unknown owner"
}

function Get-GroupOwners {
    param([string]$GroupId)

    $owners = @()

    $uri = (
        "https://graph.microsoft.com/v1.0/groups/{0}/owners" -f
        $GroupId
    )

    while (-not [string]::IsNullOrWhiteSpace($uri)) {
        $response = Invoke-MgGraphRequest `
            -Method GET `
            -Uri $uri `
            -ErrorAction Stop

        if ($response.value) {
            foreach ($owner in @($response.value)) {
                $owners += $owner
            }
        }

        $nextLink = $response."@odata.nextLink"

        if (
            [string]::IsNullOrWhiteSpace(
                [string]$nextLink
            )
        ) {
            $uri = ""
        }
        else {
            $uri = [string]$nextLink
        }
    }

    return @($owners)
}

function Get-AllCurrentGroups {
    return @(
        Get-MgGroup `
            -All `
            -Property @(
                "id",
                "displayName",
                "mail",
                "mailEnabled",
                "securityEnabled",
                "groupTypes",
                "resourceProvisioningOptions"
            ) `
            -ErrorAction Stop
    )
}

try {
    Connect-GraphReadOnly
    Connect-ExchangeReadOnly

    $groups = @(Get-AllCurrentGroups)
    $results = New-Object System.Collections.Generic.List[object]

    foreach ($group in $groups) {
        if (
            [string]::IsNullOrWhiteSpace(
                [string]$group.DisplayName
            )
        ) {
            $groupName = "(Unnamed Group)"
        }
        else {
            $groupName = [string]$group.DisplayName
        }

        $ownerObjects = @()
        $lookupFailed = $false

        $useExchangeFirst = (
            $group.MailEnabled -and
            -not (@($group.GroupTypes) -contains "Unified")
        )

        if ($useExchangeFirst) {
            try {
                $ownerObjects = @(
                    Get-ExchangeGroupOwners `
                        -Group $group
                )
            }
            catch {
                $lookupFailed = $true
            }
        }
        else {
            try {
                $ownerObjects = @(
                    Get-GroupOwners `
                        -GroupId $group.Id
                )
            }
            catch {
                if ($group.MailEnabled) {
                    try {
                        $ownerObjects = @(
                            Get-ExchangeGroupOwners `
                                -Group $group
                        )
                    }
                    catch {
                        $lookupFailed = $true
                    }
                }
                else {
                    $lookupFailed = $true
                }
            }
        }

        $rawOwnerCount = @($ownerObjects).Count
        $ownerNames = @()

        if (-not $lookupFailed) {
            $ownerNames = @(
                $ownerObjects |
                ForEach-Object {
                    Get-OwnerDisplay -Owner $_
                } |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace($_)
                } |
                Sort-Object -Unique
            )
        }

        $results.Add(
            [pscustomobject]@{
                GroupType     = Get-GroupType -Group $group
                GroupName     = $groupName
                LookupFailed  = $lookupFailed
                RawOwnerCount = $rawOwnerCount
                Owners        = @($ownerNames)
            }
        )
    }

    $outputLines = New-Object System.Collections.Generic.List[string]

    $headerLines = @(
        "GROUPS + OWNERS",
        ""
    )

    foreach ($line in $headerLines) {
        Write-Host $line
        $outputLines.Add($line)
    }

    $groupTypes = @(
        $results |
        Select-Object -ExpandProperty GroupType -Unique |
        Sort-Object
    )

    foreach ($groupType in $groupTypes) {
        Write-Host $groupType
        $outputLines.Add($groupType)

        $divider = "-" * $groupType.Length
        Write-Host $divider
        $outputLines.Add($divider)
        Write-Host ""
        $outputLines.Add("")

        $typeResults = @(
            $results |
            Where-Object { $_.GroupType -eq $groupType } |
            Sort-Object GroupName
        )

        foreach ($result in $typeResults) {
            Write-Host $result.GroupName
            $outputLines.Add($result.GroupName)

            if ($result.LookupFailed) {
                $line = "- LOOKUP FAILED"
                Write-Host $line
                $outputLines.Add($line)
            }
            elseif ($result.Owners.Count -gt 0) {
                foreach ($owner in $result.Owners) {
                    $line = "- {0}" -f $owner
                    Write-Host $line
                    $outputLines.Add($line)
                }
            }
            elseif ($result.RawOwnerCount -gt 0) {
                $line = "- No human owner found"
                Write-Host $line
                $outputLines.Add($line)
            }
            else {
                $line = "- No owner assigned"
                Write-Host $line
                $outputLines.Add($line)
            }

            Write-Host ""
            $outputLines.Add("")
        }
    }

    try {
        Write-Host ""
        $exportChoice = Read-Host "Export results to Desktop? (Y/N)"

        if ($exportChoice -match '^[Yy]') {
            $desktop = [Environment]::GetFolderPath('Desktop')

            if ([string]::IsNullOrWhiteSpace($desktop)) {
                throw "Desktop path could not be determined."
            }

            $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
            $exportPath = Join-Path `
                -Path $desktop `
                -ChildPath ("Tenant-Group-Owners_{0}.txt" -f $timestamp)

            $outputLines |
                Out-File `
                    -FilePath $exportPath `
                    -Encoding UTF8 `
                    -Force

            Write-Host ""
            Write-Host ("Exported: {0}" -f $exportPath)
        }
    }
    catch {
        Write-Host ""
        Write-Warn ("Export prompt unavailable: {0}" -f (Get-ShortError $_))
    }
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Write-Host ""

    try {
        Read-Host "Press ENTER to EXIT" | Out-Null
    }
    catch {
        Write-Host "Closing in 15 seconds..."
        Start-Sleep -Seconds 15
    }
}