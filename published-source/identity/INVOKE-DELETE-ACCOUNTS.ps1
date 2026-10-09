#Requires -Version 5.1

<#
IDENTITY ACCOUNT DELETION

OBJECTIVE
Delete one or more explicitly approved identity accounts from direct UPN or TXT/CSV input.

AUTHORITATIVE SOURCE
- Synced user: delete in Active Directory. Entra removal occurs through sync.
- Cloud-only Entra user: delete directly in Entra.
- Entra guest: delete directly in Entra.
- Not found in either: report ALREADY ABSENT.

SAFETY
- Exact UPN resolution only
- No UPN-prefix or sAMAccountName fallback
- Same reachable writable DC for AD lookup, deletion, and validation
- Linked-record inspection before AD deletion
- Protected AD objects are skipped
- One typed DELETE confirmation after a full plan is shown
- Cloud deletions require delegated Microsoft Graph User.ReadWrite.All
- Same-source post-delete validation
- Entra Connect delta sync only when an AD deletion command was accepted
- CSV/TXT evidence export
#>

[CmdletBinding()]
param(
    [Alias("UPN")]
    [string[]]$InputObject,
    [string]$InputPath,
    [string]$DomainName,
    [string]$DomainController,
    [string]$SyncServer,
    [string]$OutputDir
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

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
    param([System.Management.Automation.ErrorRecord]$ErrorRecord)

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
        if ($Name -eq "ActiveDirectory") {
            throw "ActiveDirectory is required for synced-user deletion but is not installed. Install the RSAT Active Directory tools before retrying."
        }

        throw "$Name is required but is not installed. Install with: Install-Module $Name -Scope CurrentUser"
    }

    try {
        if ($Name -eq "ActiveDirectory" -and $PSVersionTable.PSVersion.Major -ge 7) {
            Import-Module ActiveDirectory -UseWindowsPowerShell -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
        }
        else {
            Import-Module $module.Path -Force -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
        }
    }
    catch {
        throw "Unable to load $Name. $(Get-ShortError $_)"
    }
}

function Get-InputValues {
    param(
        [string[]]$Values,
        [string]$Path
    )

    $items=New-Object System.Collections.ArrayList
    $source="Direct input"
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
            $source=$resolved
            $extension=[System.IO.Path]::GetExtension($resolved).ToLowerInvariant()

            if ($extension -eq ".txt") {
                foreach ($line in @(Get-Content -LiteralPath $resolved -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"').Trim("'")
                    if (
                        $candidate -and
                        $candidate -notmatch "^#" -and
                        $candidate -notmatch "^(?i:UPN|UserPrincipalName|Email|Mail)$"
                    ) {
                        [void]$items.Add($candidate)
                    }
                }
            }
            elseif ($extension -eq ".csv") {
                $rows=@(Import-Csv -LiteralPath $resolved -ErrorAction Stop)
                if ($rows.Count -eq 0) { throw "CSV contains no data rows." }

                foreach ($row in $rows) {
                    $candidate=$null
                    foreach ($name in @("UPN","UserPrincipalName","Email","Mail","Address","User","Input")) {
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
                throw "Unsupported input type '$extension'. Use direct UPN input, .txt, or .csv."
            }

            continue
        }

        foreach ($candidate in @($clean -split "\s*,\s*")) {
            if ($candidate) { [void]$items.Add($candidate.Trim()) }
        }
    }

    $unique=@($items | Where-Object { $_ } | Select-Object -Unique)
    if ($unique.Count -eq 0) { throw "No UPNs were provided." }

    foreach ($upn in $unique) {
        if (-not (Test-UpnSyntax -UPN $upn)) {
            throw "Invalid UPN in input: $upn"
        }
    }

    return [pscustomobject]@{
        Values=$unique
        Path=$source
    }
}

function Test-UpnSyntax {
    param([string]$Value)

    return (
        -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -match "^[^@\s]+@[^@\s]+$"
    )
}

function Escape-ADFilterValue {
    param([string]$Value)

    return ($Value -replace "'", "''")
}

function Get-LocalADDomain {
    param([string]$RequestedDomain)

    if (-not [string]::IsNullOrWhiteSpace($RequestedDomain)) {
        try {
            $domain = Get-ADDomain `
                -Identity $RequestedDomain.Trim() `
                -ErrorAction Stop

            return [string]$domain.DNSRoot
        }
        catch {
            return ""
        }
    }

    try {
        $domain = Get-ADDomain -ErrorAction Stop
        return [string]$domain.DNSRoot
    }
    catch {
        return ""
    }
}

function Test-DCReachable {
    param([string]$Server)

    try {
        Get-ADRootDSE -Server $Server -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Get-ApprovedWritableDC {
    param(
        [string]$Domain,
        [string]$ExplicitServer
    )

    if ([string]::IsNullOrWhiteSpace($Domain)) { return "" }

    if (-not [string]::IsNullOrWhiteSpace($ExplicitServer)) {
        try {
            $dc=Get-ADDomainController -Identity $ExplicitServer.Trim() -Server $Domain -ErrorAction Stop

            if ([bool]$dc.IsReadOnly) {
                throw "The supplied domain controller is read-only."
            }

            if (-not (Test-DCReachable -Server ([string]$dc.HostName))) {
                throw "The supplied domain controller could not be reached."
            }

            return [string]$dc.HostName
        }
        catch {
            throw "Domain controller '$ExplicitServer' is not a reachable writable DC. $(Get-ShortError $_)"
        }
    }

    $candidates=@(
        Get-ADDomainController -Filter * -Server $Domain -ErrorAction Stop |
            Where-Object { -not [bool]$_.IsReadOnly } |
            Sort-Object HostName
    )

    foreach ($candidate in $candidates) {
        $hostName=[string]$candidate.HostName
        if (Test-DCReachable -Server $hostName) { return $hostName }
    }

    throw "No reachable writable domain controller could be found for $Domain."
}

function Get-ExactADUser {
    param(
        [string]$UPN,
        [string]$Server
    )

    if ([string]::IsNullOrWhiteSpace($Server)) {
        return @()
    }

    $safeUPN = Escape-ADFilterValue -Value $UPN

    return @(
        Get-ADUser `
            -Filter "UserPrincipalName -eq '$safeUPN'" `
            -Server $Server `
            -Properties @(
                "UserPrincipalName",
                "DisplayName",
                "DistinguishedName",
                "ProtectedFromAccidentalDeletion"
            ) `
            -ErrorAction Stop
    )
}

function Get-LinkedRecordReview {
    param(
        [object]$User,
        [string]$Server
    )

    $records = @(
        Get-ADObject `
            -SearchBase $User.DistinguishedName `
            -SearchScope Subtree `
            -LDAPFilter "(objectClass=*)" `
            -Server $Server `
            -Properties ProtectedFromAccidentalDeletion `
            -ErrorAction Stop |
        Where-Object {
            [string]$_.DistinguishedName -ne
            [string]$User.DistinguishedName
        }
    )

    $protected = @(
        $records |
        Where-Object {
            [bool]$_.ProtectedFromAccidentalDeletion
        }
    )

    return [pscustomobject]@{
        Count          = $records.Count
        ProtectedCount = $protected.Count
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

function Connect-GraphForDeletion {
    $requiredScopes = @(
        "User.ReadWrite.All",
        "Organization.Read.All"
    )

    Ensure-Module -Name "Microsoft.Graph.Authentication"
    Ensure-Module -Name "Microsoft.Graph.Users"
    Ensure-Module -Name "Microsoft.Graph.Identity.DirectoryManagement"

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-ScopesPresent `
            -Context $context `
            -RequiredScopes $requiredScopes)
    ) {
        Write-OK "Graph session reused"
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

    Write-Host "Graph: Connecting..."

    $command = Get-Command Connect-MgGraph -ErrorAction Stop

    $params = @{
        Scopes      = $requiredScopes
        ErrorAction = "Stop"
    }

    if ($command.Parameters.ContainsKey("ContextScope")) {
        $params.ContextScope = "Process"
    }

    if ($command.Parameters.ContainsKey("NoWelcome")) {
        $params.NoWelcome = $true
    }

    Connect-MgGraph @params | Out-Null
    Write-OK "Graph connected"
}

function Get-GraphTenantName {
    try {
        $org = Get-MgOrganization `
            -Property DisplayName `
            -ErrorAction Stop |
            Select-Object -First 1

        if ($org -and $org.DisplayName) {
            return [string]$org.DisplayName
        }
    }
    catch {
    }

    return "Not available"
}

function Get-ExactGraphUser {
    param([string]$UPN)

    try {
        return Get-MgUser `
            -UserId $UPN `
            -Property @(
                "id",
                "displayName",
                "userPrincipalName",
                "userType",
                "onPremisesSyncEnabled"
            ) `
            -ErrorAction Stop
    }
    catch {
        $message = Get-ShortError $_

        if (
            $message -match "(?i)does not exist" -or
            $message -match "(?i)Request_ResourceNotFound" -or
            $message -match "(?i)Resource .* does not exist"
        ) {
            return $null
        }

        throw
    }
}

function Test-GraphUserAbsent {
    param([string]$UserId)

    $lastError = ""

    for ($attempt = 1; $attempt -le 6; $attempt++) {
        try {
            $user = Get-MgUser `
                -UserId $UserId `
                -Property Id `
                -ErrorAction Stop

            if ($attempt -lt 6) {
                Start-Sleep -Seconds $attempt
            }
        }
        catch {
            $message = Get-ShortError $_

            if (
                $message -match "(?i)does not exist" -or
                $message -match "(?i)Request_ResourceNotFound" -or
                $message -match "(?i)Resource .* does not exist"
            ) {
                return [pscustomobject]@{
                    Validated = $true
                    Absent    = $true
                    Error     = ""
                }
            }

            $lastError = $message

            if ($attempt -lt 6) {
                Start-Sleep -Seconds $attempt
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($lastError)) {
        return [pscustomobject]@{
            Validated = $false
            Absent    = $false
            Error     = $lastError
        }
    }

    return [pscustomobject]@{
        Validated = $true
        Absent    = $false
        Error     = ""
    }
}

function Test-ADUserAbsent {
    param(
        [string]$UPN,
        [string]$Server
    )

    $lastError = ""

    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $found = @(
                Get-ExactADUser `
                    -UPN $UPN `
                    -Server $Server
            )

            if ($found.Count -eq 0) {
                return [pscustomobject]@{
                    Validated = $true
                    Absent    = $true
                    Error     = ""
                }
            }

            if ($attempt -lt 3) {
                Start-Sleep -Seconds 1
            }
        }
        catch {
            $lastError = Get-ShortError $_

            if ($attempt -lt 3) {
                Start-Sleep -Seconds 1
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($lastError)) {
        return [pscustomobject]@{
            Validated = $false
            Absent    = $false
            Error     = $lastError
        }
    }

    return [pscustomobject]@{
        Validated = $true
        Absent    = $false
        Error     = ""
    }
}

function Resolve-SyncServer {
    param([string]$ExplicitServer)

    if (-not [string]::IsNullOrWhiteSpace($ExplicitServer)) {
        return $ExplicitServer.Trim()
    }

    Write-Host ""
    $server = (
        Read-Host "Entra Connect sync server (blank = scheduled sync only)"
    ).Trim()

    return $server
}

function Start-EntraDeltaSync {
    param([string]$Server)

    if ([string]::IsNullOrWhiteSpace($Server)) {
        return [pscustomobject]@{
            Status = "ScheduledPending"
            Server = ""
            Detail = "No sync server was supplied."
        }
    }

    try {
        Invoke-Command `
            -ComputerName $Server `
            -ScriptBlock {
                Start-ADSyncSyncCycle -PolicyType Delta
            } `
            -ErrorAction Stop |
            Out-Null

        return [pscustomobject]@{
            Status = "Triggered"
            Server = $Server
            Detail = ""
        }
    }
    catch {
        return [pscustomobject]@{
            Status = "Failed"
            Server = $Server
            Detail = Get-ShortError $_
        }
    }
}

function New-Result {
    param(
        [string]$UPN,
        [string]$DisplayName,
        [string]$Authority,
        [string]$Status,
        [string]$Reason,
        [string]$TechnicalError
    )

    return [pscustomobject][ordered]@{
        UPN            = $UPN
        DisplayName    = $DisplayName
        Authority      = $Authority
        Status         = $Status
        Reason         = $Reason
        TechnicalError = $TechnicalError
        Completed      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function Write-ResultSection {
    param(
        [string]$Title,
        [object[]]$Items,
        [switch]$ShowReason
    )

    Write-Host ""
    Write-Host $Title

    if (-not $Items -or $Items.Count -eq 0) {
        Write-Host "Status: No"
        return
    }

    Write-Host ("Status: {0}" -f $Items.Count)

    $authorityGroups = @(
        $Items |
        Group-Object Authority |
        Sort-Object Name
    )

    foreach ($authorityGroup in $authorityGroups) {
        Write-Host ""
        Write-Host ([string]$authorityGroup.Name).ToUpperInvariant()

        foreach ($item in @($authorityGroup.Group)) {
            Write-Host ("- {0}" -f $item.UPN)
        }
    }
}

function Get-DefaultOutputDirectory {
    param([string]$RequestedPath)

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath)) {
        return $RequestedPath.Trim().Trim('"').Trim("'")
    }

    $desktop = [Environment]::GetFolderPath("Desktop")

    if ([string]::IsNullOrWhiteSpace($desktop)) {
        $desktop = (Get-Location).Path
    }

    return Join-Path `
        $desktop `
        ("Bulk-Identity-Deletion-{0}" -f
            (Get-Date -Format "yyyyMMdd-HHmmss"))
}

function Export-Evidence {
    param(
        [object[]]$Results,
        [string]$Destination,
        [string]$InputFile,
        [string]$TenantName,
        [string]$Domain,
        [string]$DC,
        [object]$SyncResult
    )

    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item `
            -ItemType Directory `
            -Path $Destination `
            -Force `
            -ErrorAction Stop |
            Out-Null
    }

    $csvPath = Join-Path `
        $Destination `
        "identity-deletion-results.csv"

    $txtPath = Join-Path `
        $Destination `
        "identity-deletion-summary.txt"

    @($Results) |
        Export-Csv `
            -LiteralPath $csvPath `
            -NoTypeInformation `
            -Encoding UTF8 `
            -Force `
            -ErrorAction Stop

    $lines = @()
    $lines += "IDENTITY ACCOUNT DELETION"
    $lines += "Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $lines += "Input: $InputFile"
    $lines += "Entra tenant: $TenantName"

    if ($Domain) {
        $lines += "AD domain: $Domain"
    }

    if ($DC) {
        $lines += "AD DC: $DC"
    }

    $lines += ""

    foreach ($status in @(
        "Deleted",
        "Not Validated",
        "Already Absent",
        "Skipped",
        "Failed"
    )) {
        $items = @(
            $Results |
            Where-Object { $_.Status -eq $status }
        )
        $lines += $status.ToUpperInvariant()
        $lines += "Status: $($items.Count)"

        $authorityGroups = @(
            $items |
            Group-Object Authority |
            Sort-Object Name
        )

        foreach ($authorityGroup in $authorityGroups) {
            $lines += ""
            $lines += ([string]$authorityGroup.Name).ToUpperInvariant()

            foreach ($item in @($authorityGroup.Group)) {
                $lines += "- $($item.UPN)"

                if ($item.Reason) {
                    $lines += "  Reason: $($item.Reason)"
                }

                if ($item.TechnicalError) {
                    $lines += "  Technical error: $($item.TechnicalError)"
                }
            }
        }

        $lines += ""
    }

    $lines += "ENTRA SYNC"
    $lines += "Status: $($SyncResult.Status)"

    if ($SyncResult.Server) {
        $lines += "Server: $($SyncResult.Server)"
    }

    if ($SyncResult.Detail) {
        $lines += "Detail: $($SyncResult.Detail)"
    }

    $lines |
        Out-File `
            -LiteralPath $txtPath `
            -Encoding UTF8 `
            -Force `
            -ErrorAction Stop

    return [pscustomobject]@{
        Csv = $csvPath
        Txt = $txtPath
    }
}

try {
    Write-Host ""
    Write-Host "IDENTITY ACCOUNT DELETION"
    Write-Host (
        "Delete approved AD-synced, cloud-only, or guest identities " +
        "from a TXT or CSV UPN list."
    )
    Write-Host ""
    Write-Warn (
        "This is destructive. Use only with explicit approval " +
        "and a documented ticket."
    )

    $input = Get-InputValues -Values $InputObject -Path $InputPath

    Write-Host ""
    Write-OK "Input accepted"
    Write-Host ("Source: {0}" -f $input.Path)
    Write-Host ("Users requested: {0}" -f $input.Values.Count)

    # Graph is required for classification because cloud-only and guest
    # identities may have no corresponding AD object.
    Connect-GraphForDeletion
    $tenantName = Get-GraphTenantName

    # AD is optional. Cloud-only / guest deletion can still proceed if
    # the jumpbox has no client AD line of sight.
    $adAvailable = $false
    $adDomain = ""
    $approvedDC = ""

    try {
        Ensure-Module -Name "ActiveDirectory"
        $adDomain = Get-LocalADDomain -RequestedDomain $DomainName

        if (-not [string]::IsNullOrWhiteSpace($adDomain)) {
            $approvedDC = Get-ApprovedWritableDC `
                -Domain $adDomain `
                -ExplicitServer $DomainController

            if (-not [string]::IsNullOrWhiteSpace($approvedDC)) {
                $adAvailable = $true
            }
        }
    }
    catch {
        Write-Warn (
            "Active Directory unavailable. Cloud-only and guest " +
            "identities can still be reviewed."
        )
        Write-Info (Get-ShortError $_)
    }

    Write-Host ""
    Write-Host "TARGET"
    Write-Host ("Entra tenant: {0}" -f $tenantName)

    if ($adAvailable) {
        Write-Host ("AD domain: {0}" -f $adDomain)
        Write-Host ("AD DC: {0}" -f $approvedDC)
    }
    else {
        Write-Host "AD: Not available"
    }

    $results = @()
    $plan = @()

    Write-Host ""
    Write-Host "VALIDATION"

    foreach ($requestedUPN in $input.Values) {
        if (-not (Test-UpnSyntax -Value $requestedUPN)) {
            $results += New-Result `
                -UPN $requestedUPN `
                -DisplayName "" `
                -Authority "Unknown" `
                -Status "Skipped" `
                -Reason "Input is not a valid UPN." `
                -TechnicalError ""

            continue
        }

        $adUser = $null
        $graphUser = $null
        $adLookupFailed = $false
        $graphLookupFailed = $false
        $adError = ""
        $graphError = ""

        if ($adAvailable) {
            try {
                $adMatches = @(
                    Get-ExactADUser `
                        -UPN $requestedUPN `
                        -Server $approvedDC
                )

                if ($adMatches.Count -gt 1) {
                    $results += New-Result `
                        -UPN $requestedUPN `
                        -DisplayName "" `
                        -Authority "Active Directory" `
                        -Status "Not Validated" `
                        -Reason "More than one exact AD UPN result was returned." `
                        -TechnicalError ""

                    continue
                }

                if ($adMatches.Count -eq 1) {
                    $adUser = $adMatches[0]
                }
            }
            catch {
                $adLookupFailed = $true
                $adError = Get-ShortError $_
            }
        }

        try {
            $graphUser = Get-ExactGraphUser `
                -UPN $requestedUPN
        }
        catch {
            $graphLookupFailed = $true
            $graphError = Get-ShortError $_
        }

        if ($graphLookupFailed) {
            $results += New-Result `
                -UPN $requestedUPN `
                -DisplayName "" `
                -Authority "Entra" `
                -Status "Not Validated" `
                -Reason "Entra identity could not be safely checked." `
                -TechnicalError $graphError

            continue
        }

        # Synced / AD-authoritative identity.
        if ($adUser) {
            if ([bool]$adUser.ProtectedFromAccidentalDeletion) {
                $results += New-Result `
                    -UPN ([string]$adUser.UserPrincipalName) `
                    -DisplayName ([string]$adUser.DisplayName) `
                    -Authority "Active Directory" `
                    -Status "Skipped" `
                    -Reason "The AD user is protected from accidental deletion." `
                    -TechnicalError ""

                continue
            }

            try {
                $linked = Get-LinkedRecordReview `
                    -User $adUser `
                    -Server $approvedDC
            }
            catch {
                $results += New-Result `
                    -UPN ([string]$adUser.UserPrincipalName) `
                    -DisplayName ([string]$adUser.DisplayName) `
                    -Authority "Active Directory" `
                    -Status "Not Validated" `
                    -Reason "Linked AD records could not be inspected safely." `
                    -TechnicalError (Get-ShortError $_)

                continue
            }

            if ($linked.ProtectedCount -gt 0) {
                $results += New-Result `
                    -UPN ([string]$adUser.UserPrincipalName) `
                    -DisplayName ([string]$adUser.DisplayName) `
                    -Authority "Active Directory" `
                    -Status "Skipped" `
                    -Reason (
                        "{0} linked record(s) are protected from accidental deletion." -f
                        $linked.ProtectedCount
                    ) `
                    -TechnicalError ""

                continue
            }

            $plan += [pscustomobject]@{
                UPN               = [string]$adUser.UserPrincipalName
                DisplayName       = [string]$adUser.DisplayName
                Authority         = "Active Directory"
                Action            = "Delete in AD; Entra removal via sync"
                ADUser            = $adUser
                GraphUserId       = if ($graphUser) { [string]$graphUser.Id } else { "" }
                LinkedRecords     = [int]$linked.Count
            }

            continue
        }

        # If AD lookup itself failed and Graph says the account is synced,
        # do not fall back to deleting the Entra object.
        if (
            $graphUser -and
            $graphUser.OnPremisesSyncEnabled -eq $true
        ) {
            $results += New-Result `
                -UPN ([string]$graphUser.UserPrincipalName) `
                -DisplayName ([string]$graphUser.DisplayName) `
                -Authority "Active Directory" `
                -Status "Not Validated" `
                -Reason (
                    "Entra reports this identity as AD-synced, but the " +
                    "authoritative AD object could not be safely resolved."
                ) `
                -TechnicalError $adError

            continue
        }

        # Cloud-only / guest identity.
        if ($graphUser) {
            $authority = if (
                [string]$graphUser.UserType -eq "Guest"
            ) {
                "Entra Guest"
            }
            else {
                "Entra"
            }

            $plan += [pscustomobject]@{
                UPN               = [string]$graphUser.UserPrincipalName
                DisplayName       = [string]$graphUser.DisplayName
                Authority         = $authority
                Action            = "Delete directly in Entra"
                ADUser            = $null
                GraphUserId       = [string]$graphUser.Id
                LinkedRecords     = 0
            }

            continue
        }

        # Not found in either source.
        if (
            -not $adUser -and
            -not $graphUser -and
            -not $adLookupFailed
        ) {
            $results += New-Result `
                -UPN $requestedUPN `
                -DisplayName "" `
                -Authority "AD + Entra" `
                -Status "Already Absent" `
                -Reason "Exact UPN was not found in Active Directory or Entra." `
                -TechnicalError ""

            continue
        }

        if (
            -not $graphUser -and
            $adLookupFailed
        ) {
            $results += New-Result `
                -UPN $requestedUPN `
                -DisplayName "" `
                -Authority "Active Directory" `
                -Status "Not Validated" `
                -Reason "AD lookup failed, so absence could not be safely established." `
                -TechnicalError $adError
        }
    }

    Write-Host ""
    Write-Host "PLAN"

    if ($plan.Count -eq 0) {
        Write-Warn "No accounts passed deletion validation."
    }
    else {
        Write-Host ("Status: {0}" -f $plan.Count)

        $planGroups = @(
            $plan |
            Group-Object Authority |
            Sort-Object Name
        )

        foreach ($planGroup in $planGroups) {
            Write-Host ""
            Write-Host ([string]$planGroup.Name).ToUpperInvariant()

            $groupAction = @(
                $planGroup.Group |
                Select-Object -First 1
            ).Action

            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$groupAction
                )
            ) {
                Write-Host ("Action: {0}" -f $groupAction)
            }

            foreach ($item in @($planGroup.Group)) {
                Write-Host ("- {0}" -f $item.UPN)
            }
        }
    }

    # Resolve the Entra Connect server once for any AD-backed identities.
    # Sync reachability does not block authoritative AD deletion.
    $adPlan = @(
        $plan |
        Where-Object {
            $_.Authority -eq "Active Directory"
        }
    )

    $cloudPlan = @(
        $plan |
        Where-Object {
            $_.Authority -ne "Active Directory"
        }
    )

    $syncServerResolved = ""

    if ($adPlan.Count -gt 0) {
        $syncServerResolved = Resolve-SyncServer `
            -ExplicitServer $SyncServer

        Write-Host ""
        Write-Host "AD -> ENTRA"
        Write-Host (
            "AD is authoritative for {0} synced account(s)." -f
            $adPlan.Count
        )

        if (
            [string]::IsNullOrWhiteSpace(
                $syncServerResolved
            )
        ) {
            Write-Info (
                "Immediate delta sync not configured. " +
                "Scheduled sync will carry AD deletions to Entra."
            )
        }
        else {
            Write-Host (
                "Delta sync server: {0}" -f
                $syncServerResolved
            )
        }
    }

    if ($plan.Count -gt 0) {
        Write-Host ""
        $confirmation = Read-Host (
            "Type DELETE to permanently delete the accounts in the plan"
        )

        if ($confirmation.Trim() -ine "DELETE") {
            Write-Warn "Deletion cancelled. No changes were made."

            foreach ($item in $plan) {
                $results += New-Result `
                    -UPN $item.UPN `
                    -DisplayName $item.DisplayName `
                    -Authority $item.Authority `
                    -Status "Skipped" `
                    -Reason "Operator cancelled before deletion." `
                    -TechnicalError ""
            }

            $plan = @()
            $adPlan = @()
            $cloudPlan = @()
        }
    }

    $adDeleteAccepted = 0

    if ($plan.Count -gt 0) {
        Write-Host ""
        Write-Host "DELETION"

        foreach ($item in $plan) {
            if ($item.Authority -eq "Active Directory") {
                try {
                    $current = @(
                        Get-ExactADUser `
                            -UPN $item.UPN `
                            -Server $approvedDC
                    )

                    if ($current.Count -ne 1) {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority "Active Directory" `
                            -Status "Not Validated" `
                            -Reason "The AD identity could not be uniquely revalidated immediately before deletion." `
                            -TechnicalError ""

                        continue
                    }

                    $currentUser = $current[0]

                    if ([bool]$currentUser.ProtectedFromAccidentalDeletion) {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority "Active Directory" `
                            -Status "Skipped" `
                            -Reason "The AD user became protected before execution." `
                            -TechnicalError ""

                        continue
                    }

                    $linkedNow = Get-LinkedRecordReview `
                        -User $currentUser `
                        -Server $approvedDC

                    if ($linkedNow.ProtectedCount -gt 0) {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority "Active Directory" `
                            -Status "Skipped" `
                            -Reason "A linked AD record is protected from accidental deletion." `
                            -TechnicalError ""

                        continue
                    }

                    if ($linkedNow.Count -gt 0) {
                        Remove-ADObject `
                            -Identity $currentUser.DistinguishedName `
                            -Server $approvedDC `
                            -Recursive `
                            -Confirm:$false `
                            -ErrorAction Stop
                    }
                    else {
                        Remove-ADUser `
                            -Identity $currentUser.DistinguishedName `
                            -Server $approvedDC `
                            -Confirm:$false `
                            -ErrorAction Stop
                    }

                    $adDeleteAccepted++

                    $validation = Test-ADUserAbsent `
                        -UPN $item.UPN `
                        -Server $approvedDC

                    if (
                        $validation.Validated -and
                        $validation.Absent
                    ) {
                        Write-OK ("Deleted from AD: {0}" -f $item.UPN)

                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority "Active Directory" `
                            -Status "Deleted" `
                            -Reason "AD deletion validated. Entra removal is delegated to the post-delete delta sync." `
                            -TechnicalError ""
                    }
                    elseif ($validation.Validated) {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority "Active Directory" `
                            -Status "Not Validated" `
                            -Reason "Deletion command was accepted, but the UPN still resolves on the same DC." `
                            -TechnicalError ""
                    }
                    else {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority "Active Directory" `
                            -Status "Not Validated" `
                            -Reason "AD deletion command was accepted, but same-DC validation could not be completed." `
                            -TechnicalError $validation.Error
                    }
                }
                catch {
                    $results += New-Result `
                        -UPN $item.UPN `
                        -DisplayName $item.DisplayName `
                        -Authority "Active Directory" `
                        -Status "Failed" `
                        -Reason "Active Directory deletion failed." `
                        -TechnicalError (Get-ShortError $_)
                }
            }
            else {
                try {
                    # Re-read immediately before deletion.
                    $currentGraph = Get-ExactGraphUser `
                        -UPN $item.UPN

                    if (-not $currentGraph) {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority $item.Authority `
                            -Status "Already Absent" `
                            -Reason "Identity no longer exists in Entra." `
                            -TechnicalError ""

                        continue
                    }

                    if ($currentGraph.OnPremisesSyncEnabled -eq $true) {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority "Active Directory" `
                            -Status "Not Validated" `
                            -Reason "Identity became or was discovered to be AD-synced before execution. Direct Entra deletion was blocked." `
                            -TechnicalError ""

                        continue
                    }

                    Remove-MgUser `
                        -UserId ([string]$currentGraph.Id) `
                        -Confirm:$false `
                        -ErrorAction Stop

                    $validation = Test-GraphUserAbsent `
                        -UserId ([string]$currentGraph.Id)

                    if (
                        $validation.Validated -and
                        $validation.Absent
                    ) {
                        Write-OK ("Deleted from Entra: {0}" -f $item.UPN)

                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority $item.Authority `
                            -Status "Deleted" `
                            -Reason "Entra deletion validated through Graph." `
                            -TechnicalError ""
                    }
                    elseif ($validation.Validated) {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority $item.Authority `
                            -Status "Not Validated" `
                            -Reason "Entra deletion command was accepted, but the identity still resolves." `
                            -TechnicalError ""
                    }
                    else {
                        $results += New-Result `
                            -UPN $item.UPN `
                            -DisplayName $item.DisplayName `
                            -Authority $item.Authority `
                            -Status "Not Validated" `
                            -Reason "Entra deletion command was accepted, but Graph validation could not be completed." `
                            -TechnicalError $validation.Error
                    }
                }
                catch {
                    $results += New-Result `
                        -UPN $item.UPN `
                        -DisplayName $item.DisplayName `
                        -Authority $item.Authority `
                        -Status "Failed" `
                        -Reason "Entra deletion failed." `
                        -TechnicalError (Get-ShortError $_)
                }
            }
        }
    }

    $syncResult = [pscustomobject]@{
        Status = "NotRequired"
        Server = ""
        Detail = "No AD deletion command was accepted."
    }

    if ($adDeleteAccepted -gt 0) {
        $syncResult = Start-EntraDeltaSync `
            -Server $syncServerResolved

        Write-Host ""
        Write-Host "ENTRA SYNC"

        if ($syncResult.Status -eq "Triggered") {
            Write-OK "Delta sync triggered"
            Write-Host ("Server: {0}" -f $syncResult.Server)
        }
        elseif ($syncResult.Status -eq "ScheduledPending") {
            Write-Info "Immediate delta sync skipped. Scheduled sync pending."
        }
        else {
            Write-Warn "Delta sync failed. AD deletions remain authoritative."
            Write-Host "Scheduled sync pending."

            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$syncResult.Detail
                )
            ) {
                Write-Info $syncResult.Detail
            }
        }
    }

    $deleted = @(
        $results |
        Where-Object { $_.Status -eq "Deleted" }
    )
    $notValidated = @(
        $results |
        Where-Object { $_.Status -eq "Not Validated" }
    )
    $alreadyAbsent = @(
        $results |
        Where-Object { $_.Status -eq "Already Absent" }
    )
    $skipped = @(
        $results |
        Where-Object { $_.Status -eq "Skipped" }
    )
    $failed = @(
        $results |
        Where-Object { $_.Status -eq "Failed" }
    )

    Write-Host ""
    Write-Host "RESULTS"

    Write-ResultSection `
        -Title "DELETED" `
        -Items $deleted

    Write-ResultSection `
        -Title "NOT VALIDATED" `
        -Items $notValidated `
        -ShowReason

    Write-ResultSection `
        -Title "ALREADY ABSENT" `
        -Items $alreadyAbsent

    Write-ResultSection `
        -Title "SKIPPED" `
        -Items $skipped `
        -ShowReason

    Write-ResultSection `
        -Title "FAILED" `
        -Items $failed `
        -ShowReason

    Write-Host ""
    Write-Host "ENTRA SYNC"
    Write-Host ("Status: {0}" -f $syncResult.Status)

    if ($syncResult.Server) {
        Write-Host ("Server: {0}" -f $syncResult.Server)
    }

    Write-Host ""
    $exportChoice = Read-Host "Export results to CSV/TXT? [y/N]"

    if ($exportChoice.Trim() -match '^(?i)y(?:es)?$') {
        try {
            $requestedExportPath = $OutputDir

            if ([string]::IsNullOrWhiteSpace($requestedExportPath)) {
                $requestedExportPath = Read-Host (
                    "Export folder path " +
                    "(blank = Desktop)"
                )
            }

            $destination = Get-DefaultOutputDirectory `
                -RequestedPath $requestedExportPath

            $export = Export-Evidence `
                -Results $results `
                -Destination $destination `
                -InputFile $input.Path `
                -TenantName $tenantName `
                -Domain $adDomain `
                -DC $approvedDC `
                -SyncResult $syncResult

            Write-Host ""
            Write-Host "EXPORT"
            Write-Host ("CSV: {0}" -f $export.Csv)
            Write-Host ("TXT: {0}" -f $export.Txt)
        }
        catch {
            Write-Warn "Evidence export failed."
            Write-Info (Get-ShortError $_)
        }
    }
    else {
        Write-Host "Export: No"
    }

    Write-Host ""

    if (
        $failed.Count -gt 0 -or
        $notValidated.Count -gt 0
    ) {
        Write-Warn "Complete with identities requiring engineer review."
    }
    elseif ($deleted.Count -gt 0) {
        Write-OK "Complete. Approved identity deletions were validated."

        if ($syncResult.Status -eq "Failed") {
            Write-Warn "Entra delta sync failed; scheduled sync remains pending."
        }
        elseif ($syncResult.Status -eq "ScheduledPending") {
            Write-Info "Scheduled Entra sync remains pending."
        }
    }
    else {
        Write-OK "Complete. No identities were deleted."
    }

    Write-FieldKitFooter
}
catch {
    Write-Host ""
    Write-Fail (
        "Unhandled script error: {0}" -f
        (Get-ShortError $_)
    )

    if ($_.InvocationInfo.ScriptLineNumber) {
        Write-Info (
            "Line: {0}" -f
            $_.InvocationInfo.ScriptLineNumber
        )
    }

    Write-FieldKitFooter
}
finally {
    Pause-End
}