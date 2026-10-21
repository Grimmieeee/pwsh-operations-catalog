# .VERSION 1.0.2
#Requires -Version 5.1

<#
TENANT GROUP OWNERS REVIEW

OBJECTIVE
List group owners and identify groups without an assigned owner.

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

# Embedded into standalone report scripts by tools/reporting/build.ps1.
$script:FKReportLines = New-Object 'Collections.Generic.List[string]'
$script:FKReportWarnings = @()
$script:FKReportStartedUtc = [DateTime]::UtcNow.ToString('o')

function Write-FKReportLine {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Object,
        [object]$Separator=' ',[switch]$NoNewline,
        [ConsoleColor]$ForegroundColor,[ConsoleColor]$BackgroundColor
    )
    $line=($Object | ForEach-Object {[string]$_}) -join [string]$Separator
    $script:FKReportLines.Add($line)
    Write-Host @PSBoundParameters
}

function ConvertTo-FKDesktopReport {
    param([string]$Title,[string[]]$Lines,[string]$StartedUtc,[string]$ScopeNote)
    $encode={param($Text) [Net.WebUtility]::HtmlEncode([string]$Text)}
    $blocks=New-Object 'Collections.Generic.List[string]'
    $section=New-Object 'Collections.Generic.List[string]'
    foreach($line in @($Lines)) {
        if($line -match '^\s*[A-Z][A-Z /+&:()-]{2,}\s*$' -and $line.Trim().Length -lt 90) {
            if($section.Count) {$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>');$section.Clear()}
            $blocks.Add('<h2>'+(& $encode $line.Trim())+'</h2>')
        } else {$section.Add([string]$line)}
    }
    if($section.Count){$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>')}
    $safeTitle=& $encode $Title
    return @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"><title>$safeTitle</title>
<style>body{font:16px/1.55 system-ui,sans-serif;background:#f5f7f7;color:#172524;margin:0}main{max-width:1000px;margin:32px auto;padding:32px;background:white;border-top:4px solid #168779}header{border-bottom:1px solid #d1ddda;padding-bottom:20px}small{letter-spacing:.12em;color:#52716b}h1{font-size:28px;margin:12px 0}h2{font-size:15px;letter-spacing:.1em;color:#166b60;margin:28px 0 10px;border-bottom:1px solid #d1ddda;padding-bottom:8px}pre{font:14px/1.6 ui-monospace,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;margin:0}aside{background:#eef5f2;padding:12px 16px;margin:20px 0}footer{font-size:12px;color:#52716b;margin-top:32px}@media print{body{background:white}main{margin:0;padding:0;max-width:none}h2{break-after:avoid}pre{font-size:11px}}</style></head>
<body><main><header><small>F I E L D // K I T</small><h1>$safeTitle</h1><p>Collection started (UTC): $(& $encode $StartedUtc)</p></header><aside>$(& $encode $ScopeNote) Findings, unavailable checks, and displayed limits below are preserved from this run. Absence of a finding does not establish complete coverage.</aside>$($blocks.ToArray() -join "`n")<footer>Read-only report. No remote content or executable scripts. Review findings in context before taking action.</footer></main></body></html>
"@
}

function Save-FKDesktopReport {
    param([string]$Folder,[string]$Title,[string]$Content)
    if([string]::IsNullOrWhiteSpace($Folder) -or -not [IO.Directory]::Exists($Folder)){throw 'Report folder does not exist.'}
    $stem=($Title -replace '[^a-zA-Z0-9._-]','-').Trim('-')
    if(-not $stem){$stem='field-kit-report'}
    $stem=$stem.Substring(0,[Math]::Min(80,$stem.Length))
    $name=$stem+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.html'
    $path=Join-Path $Folder $name
    $bytes=(New-Object Text.UTF8Encoding($false)).GetBytes($Content)
    $stream=New-Object IO.FileStream($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
    $actual=[IO.File]::ReadAllBytes($path)
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        if([Convert]::ToBase64String($sha.ComputeHash($bytes)) -cne [Convert]::ToBase64String($sha.ComputeHash($actual))){throw 'Report readback did not match the collected content.'}
    }finally{$sha.Dispose()}
    return $path
}

function Offer-FKDesktopReport {
    param([string]$Title,[string]$ScopeNote='Scope matches the console output; only displayed rows are included.',[string]$DesktopFolder=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory))
    if(-not $script:FKReportLines.Count){return}
    try {
        if((Read-Host 'Save report to Desktop? [Y/N]').Trim() -notmatch '^(?i)y$'){return}
        $folder=$DesktopFolder
        $reportLines=@($script:FKReportLines.ToArray())
        if(@($script:FKReportWarnings).Count){$reportLines+=@('','SERVICE WARNINGS');$reportLines+=@($script:FKReportWarnings|ForEach-Object {[string]$_})}
        $content=ConvertTo-FKDesktopReport -Title $Title -Lines $reportLines -StartedUtc $script:FKReportStartedUtc -ScopeNote $ScopeNote
        try {$saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content}
        catch {
            Write-Host '[WARN] Desktop report could not be saved. Choose another existing folder or cancel.' -ForegroundColor Yellow
            $folder=(Read-Host 'Report folder (ENTER cancels)').Trim().Trim('"')
            if(-not $folder){return}
            $saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content
        }
        Write-Host ('[OK] Report saved and readback checked: '+$saved)
    }catch{Write-Host ('[WARN] Report export failed: '+$_.Exception.Message) -ForegroundColor Yellow}
}

function Write-OK {
    param([string]$Message)
    Write-FKReportLine "[OK]   $Message"
}

function Write-Info {
    param([string]$Message)
    Write-FKReportLine "[INFO] $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-FKReportLine "[WARN] $Message"
}

function Write-Fail {
    param([string]$Message)
    Write-FKReportLine "[FAIL] $Message"
}

function Write-FieldKitFooter {
    Write-FKReportLine ""
    Write-FKReportLine "F I E L D  //  K I T"
    Write-FKReportLine ""
}

function Pause-End {
    Write-Host ''
    Write-Host 'SESSION COMPLETE'
    Write-FKReportLine ""
    Read-Host 'Press Enter to close session.' | Out-Null
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
        throw "Unable to load ${Name}: $(Get-ShortError $_)"
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
            -ErrorAction Stop -WarningVariable +script:FKReportWarnings

        return [pscustomobject]@{
            id                = ""
            displayName       = [string]$recipient.DisplayName
            userPrincipalName = [string]$recipient.UserPrincipalName
            mail              = [string]$recipient.PrimarySmtpAddress
        }
    }
    catch {
        # ManagedBy may identify a non-mail-enabled Exchange role group.
        if ($_.CategoryInfo.Category -ne 'ObjectNotFound' -and $_.Exception.Message -notmatch "object .*couldn't be found") {
            Write-Warning "Owner lookup failed; owner details are incomplete."
        }
        try {
            $group = Get-Group -Identity $Identity -ErrorAction Stop -WarningVariable +script:FKReportWarnings
            if (-not $group) { throw "Owner group not returned." }
            return [pscustomobject]@{
                id = ""
                displayName = [string]$group.DisplayName
                userPrincipalName = ""
                mail = ""
            }
        }
        catch {
            Write-Warning "Owner could not be resolved; displaying the original identity."
            return [pscustomobject]@{
                id = ""
                displayName = [string]$Identity
                userPrincipalName = ""
                mail = ""
            }
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
            -ErrorAction Stop -WarningVariable +script:FKReportWarnings
    }
    else {
        $exchangeGroup = Get-DistributionGroup `
            -Identity $Group.Mail `
            -ErrorAction Stop -WarningVariable +script:FKReportWarnings
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
            -ErrorAction Stop -WarningVariable +script:FKReportWarnings
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
        Write-FKReportLine $line
        $outputLines.Add($line)
    }

    $groupTypes = @(
        $results |
        Select-Object -ExpandProperty GroupType -Unique |
        Sort-Object
    )

    foreach ($groupType in $groupTypes) {
        Write-FKReportLine $groupType
        $outputLines.Add($groupType)

        $divider = "-" * $groupType.Length
        Write-FKReportLine $divider
        $outputLines.Add($divider)
        Write-FKReportLine ""
        $outputLines.Add("")

        $typeResults = @(
            $results |
            Where-Object { $_.GroupType -eq $groupType } |
            Sort-Object GroupName
        )

        foreach ($result in $typeResults) {
            Write-FKReportLine $result.GroupName
            $outputLines.Add($result.GroupName)

            if ($result.LookupFailed) {
                $line = "- LOOKUP FAILED"
                Write-FKReportLine $line
                $outputLines.Add($line)
            }
            elseif ($result.Owners.Count -gt 0) {
                foreach ($owner in $result.Owners) {
                    $line = "- {0}" -f $owner
                    Write-FKReportLine $line
                    $outputLines.Add($line)
                }
            }
            elseif ($result.RawOwnerCount -gt 0) {
                $line = "- No human owner found"
                Write-FKReportLine $line
                $outputLines.Add($line)
            }
            else {
                $line = "- No owner assigned"
                Write-FKReportLine $line
                $outputLines.Add($line)
            }

            Write-FKReportLine ""
            $outputLines.Add("")
        }
    }

    # Desktop HTML report is offered once in finally.
}
catch {
    Write-FKReportLine ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Offer-FKDesktopReport -Title 'GET-TENANT-GROUP-OWNERS'

    Write-FKReportLine ""

    try {
        Write-Host ''
        Write-Host 'SESSION COMPLETE'
        Read-Host 'Press Enter to close session.' | Out-Null
    }
    catch {
        Write-FKReportLine "Closing in 15 seconds..."
        Start-Sleep -Seconds 15
    }
}
