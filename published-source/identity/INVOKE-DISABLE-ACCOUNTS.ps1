<#PSScriptInfo
.VERSION 0.1.0
.GUID f3faca6e-9629-7299-5aac-4dba3f678d1d
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
DISABLE USER ACCOUNTS

OBJECTIVE
Disable one or more Microsoft 365 user accounts from a direct UPN or TXT/CSV input.

IDENTITY AUTHORITY
- Synced user: Active Directory
- Cloud-only user: Entra ID

OPTIONAL
- Revoke Microsoft 365 sessions
- Run Entra Connect delta sync after synced-user changes

CHANGES
Changes may be made. Typed confirmation is required.

RUN
Right-click > Run with PowerShell
or
Right-click > Run with PowerShell 7
#>

param(
    [Alias('UPN')]
    [string[]]$InputObject,
    [string]$InputPath,
    [switch]$RevokeSessions
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}


# Console presentation only. Does not request scopes, query services or write data.
$script:FKEndWritten = $false
$script:FKStatusWritten = $false
$script:FKHasIssue = $false
function Write-FKStatus {
    param([string]$Status)
    Write-Host ''
    if ($Status -eq 'REVIEW REQUIRED') { Write-Host ('STATUS: '+$Status) -ForegroundColor Yellow }
    else { Write-Host ('STATUS: '+$Status) }
    $script:FKStatusWritten = $true
}
function Write-FKStart {
    param([string]$Title,[string]$Objective,[string]$Mode)
    Write-Host $Title
    Write-Host $Objective
    if ($Mode) { Write-Host $Mode }
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Host ''
}
function Write-FKHeading {
    param([string]$Title)
    Write-Host ''
    switch ($Title.Trim().ToUpperInvariant()) {
        'SUMMARY' { Write-Host 'TICKET SUMMARY'; break }
        'FOLLOW-UP' { Write-Host 'NEXT STEP'; break }
        'NEXT' { Write-Host 'NEXT STEP'; break }
        default { Write-Host $Title }
    }
}
function Close-FKConsole {
    param([bool]$SkipPause = $false)
    if (-not $script:FKEndWritten) {
        Write-Host ''
        if (-not $script:FKStatusWritten) {
            Write-FKStatus $(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } else { 'RUN FINISHED' })
        }
        Write-Host ("COMPLETED: {0}" -f (Get-Date).ToString('MM/dd/yyyy HH:mm'))
        $script:FKEndWritten = $true
    }
    if ($SkipPause) { return }
    Write-Host ''
    Write-Host 'Press ESC to close'
    if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and
        (Get-Command Read-Host).CommandType -ne 'Function') {
        try {
            while ($true) {
                $key=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                if ($key.VirtualKeyCode -eq 27 -or $key.VirtualKeyCode -eq 13) { return }
            }
        }
        catch { Write-Host 'Key input unavailable here.' }
    }
    while ($true) {
        $answer=Read-Host 'Type ESC then press ENTER to close'
        if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -ieq 'ESC' -or $answer -eq [string][char]27) { return }
    }
}

function Write-OK {
    param([string]$m)
    Write-Host '[OK] ' -ForegroundColor Green -NoNewline
    Write-Host $m
}
function Write-Info {
    param([string]$m)
    Write-Host '[INFO] ' -NoNewline
    Write-Host $m
}
function Write-Warn {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
    Write-Host $m
}
function Write-Fail {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function Pause-End {
    Close-FKConsole
}

function Get-ShortError {
    param($ErrorRecord)

    $Message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = [string]$ErrorRecord
    }

    return (($Message -replace "\s+", " ").Trim())
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
    $Answer = Read-Host "Type $Required to continue"

    return (
        -not [string]::IsNullOrWhiteSpace($Answer) -and
        $Answer.Trim().ToUpperInvariant() -eq $Required.ToUpperInvariant()
    )
}

function Ensure-GraphModule {
    $ModuleName = "Microsoft.Graph.Authentication"
    $Module = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $Module) {
        throw "$ModuleName is required but is not installed. Install with: Install-Module $ModuleName -Scope CurrentUser"
    }

    Import-Module $Module.Path -Force -ErrorAction Stop
}

function Invoke-GraphGet {
    param([string]$Uri)

    $Command = Get-Command Invoke-MgGraphRequest -ErrorAction Stop
    $Parameters = @{
        Method      = "GET"
        Uri         = $Uri
        ErrorAction = "Stop"
    }

    if ($Command.Parameters.ContainsKey("OutputType")) {
        $Parameters["OutputType"] = "PSObject"
    }

    return Invoke-MgGraphRequest @Parameters
}

function Invoke-GraphPost {
    param(
        [string]$Uri,
        [hashtable]$Body
    )

    $Command = Get-Command Invoke-MgGraphRequest -ErrorAction Stop
    $Parameters = @{
        Method      = "POST"
        Uri         = $Uri
        Body        = ($Body | ConvertTo-Json -Depth 10 -Compress)
        ContentType = "application/json"
        ErrorAction = "Stop"
    }

    if ($Command.Parameters.ContainsKey("OutputType")) {
        $Parameters["OutputType"] = "PSObject"
    }

    return Invoke-MgGraphRequest @Parameters
}

function Invoke-GraphPatch {
    param(
        [string]$Uri,
        [hashtable]$Body
    )

    $Command = Get-Command Invoke-MgGraphRequest -ErrorAction Stop
    $Parameters = @{
        Method      = "PATCH"
        Uri         = $Uri
        Body        = ($Body | ConvertTo-Json -Depth 10 -Compress)
        ContentType = "application/json"
        ErrorAction = "Stop"
    }

    if ($Command.Parameters.ContainsKey("OutputType")) {
        $Parameters["OutputType"] = "PSObject"
    }

    return Invoke-MgGraphRequest @Parameters
}

function Test-GraphScopes {
    param(
        $Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) {
        return $false
    }

    foreach ($Scope in $RequiredScopes) {
        if (@($Context.Scopes) -notcontains $Scope) {
            return $false
        }
    }

    return $true
}

function Test-GraphTarget {
    param([string]$UPN)

    try {
        $Encoded = [System.Uri]::EscapeDataString($UPN)

        Invoke-GraphGet `
            -Uri ("https://graph.microsoft.com/v1.0/users/{0}?`$select=id" -f $Encoded) |
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
        [string]$TenantDomain,
        [string]$ValidationUPN
    )

    Ensure-GraphModule

    $Context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $Context -and
        (Test-GraphScopes -Context $Context -RequiredScopes $Scopes) -and
        (Test-GraphTarget -UPN $ValidationUPN)
    ) {
        Write-OK "Graph session reused"

        if ($Context.Account) {
            Write-Info ("Account: {0}" -f $Context.Account)
        }

        Write-Info ("Tenant : {0}" -f $TenantDomain)
        return
    }

    if ($Context) {
        try {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
        }
    }

    Write-Host "Graph: Connecting..."

    $Command = Get-Command Connect-MgGraph -ErrorAction Stop
    $Parameters = @{
        Scopes      = $Scopes
        ErrorAction = "Stop"
    }

    if ($Command.Parameters.ContainsKey("ContextScope")) {
        $Parameters["ContextScope"] = "Process"
    }

    if ($Command.Parameters.ContainsKey("NoWelcome")) {
        $Parameters["NoWelcome"] = $true
    }

    if (
        $TenantDomain -and
        $Command.Parameters.ContainsKey("TenantId")
    ) {
        $Parameters["TenantId"] = $TenantDomain
    }

    Connect-MgGraph @Parameters | Out-Null

    $Context = Get-MgContext -ErrorAction Stop

    if (-not (Test-GraphScopes -Context $Context -RequiredScopes $Scopes)) {
        throw "The Graph token is missing one or more required delegated scopes."
    }

    if (-not (Test-GraphTarget -UPN $ValidationUPN)) {
        throw "The target user did not resolve in the connected Graph tenant."
    }

    Write-OK "Graph connected"

    if ($Context.Account) {
        Write-Info ("Account: {0}" -f $Context.Account)
    }

    Write-Info ("Tenant : {0}" -f $TenantDomain)
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
            $resolvedPath=(Resolve-Path -LiteralPath $clean -ErrorAction Stop).Path
            Write-OK "Input file found"
            Write-Host ("Path    : {0}" -f $resolvedPath)

            $extension=[System.IO.Path]::GetExtension($resolvedPath).ToLowerInvariant()

            if ($extension -eq '.txt') {
                foreach ($line in @(Get-Content -LiteralPath $resolvedPath -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"').Trim("'")
                    if ($candidate -and $candidate -notmatch '^#') { [void]$items.Add($candidate) }
                }
            }
            elseif ($extension -eq '.csv') {
                $rows=@(Import-Csv -LiteralPath $resolvedPath -ErrorAction Stop)
                if ($rows.Count -eq 0) { throw "CSV contains no data rows." }

                foreach ($row in $rows) {
                    $candidate=$null
                    foreach ($column in @('UPN','UserPrincipalName','Email','Address','User','Name','Input')) {
                        if ($row.PSObject.Properties.Name -contains $column -and $row.$column) {
                            $candidate=[string]$row.$column
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
                throw "Unsupported input file type: $extension"
            }

            continue
        }

        foreach ($candidate in @($clean -split '\s*,\s*')) {
            if ($candidate) { [void]$items.Add($candidate.Trim()) }
        }
    }

    $upns=@($items | Where-Object { $_ } | Select-Object -Unique)
    foreach ($upn in $upns) {
        if ($upn -notmatch '^[^@\s]+@[^@\s]+$') { throw "Invalid UPN in input: $upn" }
    }

    return $upns
}

function Get-TenantDomainFromUPNs {
    param([string[]]$UPNs)

    $Domains = @(
        $UPNs |
        ForEach-Object {
            if ($_ -match "@") {
                ($_ -split "@", 2)[1].ToLowerInvariant()
            }
        } |
        Where-Object { $_ } |
        Sort-Object -Unique
    )

    if ($Domains.Count -ne 1) {
        throw "Input must contain users from one tenant domain at a time."
    }

    return $Domains[0]
}

function Get-GraphUser {
    param([string]$UPN)

    $Encoded = [System.Uri]::EscapeDataString($UPN)
    $Uri = (
        "https://graph.microsoft.com/v1.0/users/{0}" +
        "?`$select=id,displayName,userPrincipalName,accountEnabled,onPremisesSyncEnabled,onPremisesSamAccountName"
    ) -f $Encoded

    return Invoke-GraphGet -Uri $Uri
}

function Escape-LdapFilterValue {
    param([string]$Value)

    $Escaped = [string]$Value
    $Escaped = $Escaped.Replace('\', '\5c')
    $Escaped = $Escaped.Replace('*', '\2a')
    $Escaped = $Escaped.Replace('(', '\28')
    $Escaped = $Escaped.Replace(')', '\29')
    $Escaped = $Escaped.Replace([char]0, '\00')

    return $Escaped
}

function Find-ADUser {
    param([string]$Filter)

    try {
        $Searcher = New-Object System.DirectoryServices.DirectorySearcher
        $Searcher.Filter = $Filter
        $Searcher.PageSize = 100
        [void]$Searcher.PropertiesToLoad.Add("displayName")
        [void]$Searcher.PropertiesToLoad.Add("userPrincipalName")
        [void]$Searcher.PropertiesToLoad.Add("sAMAccountName")
        [void]$Searcher.PropertiesToLoad.Add("userAccountControl")

        return $Searcher.FindOne()
    }
    catch {
        throw "Active Directory lookup failed: $(Get-ShortError $_)"
    }
}

function Convert-ADResult {
    param(
        $Result,
        [string]$ResolvedBy
    )

    if (-not $Result) {
        return $null
    }

    $Entry = $Result.GetDirectoryEntry()
    $UAC = [int]$Entry.Properties["userAccountControl"].Value

    return [PSCustomObject]@{
        Path           = [string]$Entry.Path
        DisplayName    = [string]$Entry.Properties["displayName"].Value
        UPN            = [string]$Entry.Properties["userPrincipalName"].Value
        SamAccountName = [string]$Entry.Properties["sAMAccountName"].Value
        Disabled       = (($UAC -band 2) -ne 0)
        ResolvedBy     = $ResolvedBy
    }
}

function Resolve-ADUser {
    param($GraphUser)

    $UPN = [string]$GraphUser.userPrincipalName
    $SamHint = [string]$GraphUser.onPremisesSamAccountName

    if ($SamHint) {
        $Escaped = Escape-LdapFilterValue $SamHint
        $Result = Find-ADUser `
            -Filter "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$Escaped))"

        if ($Result) {
            return Convert-ADResult -Result $Result -ResolvedBy "Graph onPremisesSamAccountName"
        }
    }

    $EscapedUPN = Escape-LdapFilterValue $UPN

    $Result = Find-ADUser `
        -Filter "(&(objectCategory=person)(objectClass=user)(userPrincipalName=$EscapedUPN))"

    if ($Result) {
        return Convert-ADResult -Result $Result -ResolvedBy "userPrincipalName"
    }

    $Result = Find-ADUser `
        -Filter "(&(objectCategory=person)(objectClass=user)(mail=$EscapedUPN))"

    if ($Result) {
        return Convert-ADResult -Result $Result -ResolvedBy "mail"
    }

    $Result = Find-ADUser `
        -Filter "(&(objectCategory=person)(objectClass=user)(|(proxyAddresses=SMTP:$EscapedUPN)(proxyAddresses=smtp:$EscapedUPN)))"

    if ($Result) {
        return Convert-ADResult -Result $Result -ResolvedBy "proxyAddresses"
    }

    $FallbackSam = ($UPN -split "@", 2)[0]

    if ($FallbackSam) {
        $EscapedSam = Escape-LdapFilterValue $FallbackSam
        $Result = Find-ADUser `
            -Filter "(&(objectCategory=person)(objectClass=user)(sAMAccountName=$EscapedSam))"

        if ($Result) {
            return Convert-ADResult -Result $Result -ResolvedBy "sAMAccountName fallback"
        }
    }

    return $null
}

function Disable-ADUser {
    param($ADUser)

    $Entry = New-Object System.DirectoryServices.DirectoryEntry($ADUser.Path)
    $UAC = [int]$Entry.Properties["userAccountControl"].Value
    $Entry.Properties["userAccountControl"].Value = ($UAC -bor 2)
    $Entry.CommitChanges()
    $Entry.RefreshCache(@("userAccountControl"))

    $VerifiedUAC = [int]$Entry.Properties["userAccountControl"].Value
    return (($VerifiedUAC -band 2) -ne 0)
}

function Revoke-UserSessions {
    param([string]$UserId)

    Invoke-GraphPost `
        -Uri "https://graph.microsoft.com/v1.0/users/$UserId/revokeSignInSessions" `
        -Body @{} |
        Out-Null
}

function Run-Sync {
    $Server = (Read-Host "Sync server [blank to skip]").Trim()

    if (-not $Server) {
        return [PSCustomObject]@{
            Result = "Skipped"
            Detail = "Scheduled sync pending"
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

        Write-OK "Delta sync requested on $Server"

        return [PSCustomObject]@{
            Result = "Complete"
            Detail = $Server
        }
    }
    catch {
        $ErrorText = Get-ShortError $_
        Write-Warn "Delta sync failed: $ErrorText"

        return [PSCustomObject]@{
            Result = "Failed"
            Detail = $ErrorText
        }
    }
}

function Offer-ExportCsv {
    param([array]$Rows)

    if (-not $Rows -or $Rows.Count -eq 0) {
        return
    }

    if (-not (Confirm-Yes "Export results to CSV")) {
        return
    }

    $DesktopPath = [Environment]::GetFolderPath("Desktop")

    if (-not $DesktopPath) {
        $DesktopPath = Join-Path $env:USERPROFILE "Desktop"
    }

    $DefaultPath = Join-Path `
        $DesktopPath `
        ("account-disable-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

    $Path = Read-Host "Enter CSV path or press Enter to save to Desktop"

    if ([string]::IsNullOrWhiteSpace($Path)) {
        $Path = $DefaultPath
    }
    else {
        $Path = ([string]$Path).Trim().Trim('"').Trim("'")
        $Path = [Environment]::ExpandEnvironmentVariables($Path)
    }

    $ExportRows = @(
        $Rows |
        Select-Object UPN,AccountSource,CurrentStatus,Action,Result,Detail
    )

    $ExportRows |
        Export-Csv `
            -LiteralPath $Path `
            -NoTypeInformation `
            -Encoding UTF8 `
            -Force `
            -ErrorAction Stop

    $Check = @(Import-Csv -LiteralPath $Path -ErrorAction Stop)

    if ($Check.Count -ne $ExportRows.Count) {
        throw "CSV verification failed. Expected $($ExportRows.Count) row(s); read back $($Check.Count)."
    }

    $Expected=@(
        $ExportRows | ForEach-Object {
            "{0}|{1}|{2}|{3}|{4}" -f $_.UPN,$_.Source,$_.Before,$_.Action,$_.Result
        }
    )
    $Actual=@(
        $Check | ForEach-Object {
            "{0}|{1}|{2}|{3}|{4}" -f $_.UPN,$_.Source,$_.Before,$_.Action,$_.Result
        }
    )

    if (@(Compare-Object -ReferenceObject $Expected -DifferenceObject $Actual -SyncWindow 0).Count -gt 0) {
        throw "CSV verification failed. Exported content did not match the in-memory results."
    }

    Write-OK "CSV export saved and verified"
    Write-Host ("Path    : {0}" -f $Path)
}

try {
    Write-FKStart -Title 'DISABLE USER ACCOUNTS' -Objective 'Disables one or more approved users at the authoritative identity source and verifies the resulting account state.' -Mode 'MAKES CHANGES'
    Write-Host ''
    Write-Host "Synced users are changed in Active Directory. Cloud-only users are changed in Entra ID."
    Write-Host ""

    $UPNs = @(Get-InputUPNs -Values $InputObject -Path $InputPath)

    if ($UPNs.Count -eq 0) {
        throw "No valid UPNs were loaded."
    }

    if (-not $RevokeSessions) {
        $RevokeSessions = Confirm-Yes "Also revoke sessions for accounts disabled by this run"
    }

    $TenantDomain = Get-TenantDomainFromUPNs -UPNs $UPNs

    Connect-GraphAuto `
        -Scopes @(
            "User.ReadWrite.All",
            "Directory.Read.All"
        ) `
        -TenantDomain $TenantDomain `
        -ValidationUPN $UPNs[0]

    $Rows = @()

    Write-Host ""
    Write-Host "PREVIEW"
    Write-Host "--------------------------------------"

    foreach ($UPN in $UPNs) {
        try {
            $GraphUser = Get-GraphUser -UPN $UPN
            $Hybrid = ($GraphUser.onPremisesSyncEnabled -eq $true)
            $AccountSource = if ($Hybrid) { "Active Directory" } else { "Entra ID" }
            $CurrentStatus = if ($GraphUser.accountEnabled) { "Enabled" } else { "Disabled" }
            $Action = if ($GraphUser.accountEnabled) { "Disable" } else { "AlreadyDisabled" }

            $ADUser = $null
            $ADDetail = ""

            if ($Hybrid -and $Action -eq "Disable") {
                try {
                    $ADUser = Resolve-ADUser -GraphUser $GraphUser

                    if ($ADUser) {
                        $ADDetail = (
                            "AD: {0} | UPN: {1} | sAMAccountName: {2} | Resolved by: {3}" -f
                            $ADUser.DisplayName,
                            $ADUser.UPN,
                            $ADUser.SamAccountName,
                            $ADUser.ResolvedBy
                        )
                    }
                    else {
                        $ADDetail = "AD user not resolved"
                    }
                }
                catch {
                    $ADDetail = Get-ShortError $_
                }
            }

            $Rows += [PSCustomObject]@{
                UPN           = [string]$GraphUser.userPrincipalName
                AccountSource = $AccountSource
                CurrentStatus = $CurrentStatus
                Action        = $Action
                Result        = "Pending"
                Detail        = $ADDetail
                GraphId       = [string]$GraphUser.id
                ADUser        = $ADUser
            }

            if ($Action -eq "Disable") {
                Write-Warn ("{0} | {1} | disable" -f $GraphUser.userPrincipalName, $AccountSource)

                if ($Hybrid) {
                    if ($ADUser) {
                        Write-Host ("  AD User : {0}" -f $ADUser.DisplayName)
                        Write-Host ("  AD UPN  : {0}" -f $ADUser.UPN)
                        Write-Host ("  AD Logon: {0}" -f $ADUser.SamAccountName)
                    }
                    else {
                        Write-Warn "  AD user could not be resolved. This user will not be changed."
                    }
                }
            }
            else {
                Write-Info ("{0} | already disabled" -f $GraphUser.userPrincipalName)
            }
        }
        catch {
            $ErrorText = Get-ShortError $_
            Write-Warn "$UPN lookup failed: $ErrorText"

            $Rows += [PSCustomObject]@{
                UPN           = $UPN
                AccountSource = ""
                CurrentStatus = "NotFound"
                Action        = "Skip"
                Result        = "Failed"
                Detail        = "User lookup failed: $ErrorText"
                GraphId       = ""
                ADUser        = $null
            }
        }
    }

    Write-Host ""
    Write-Host ("Input users : {0}" -f $UPNs.Count)
    Write-Host ("To disable  : {0}" -f @($Rows | Where-Object { $_.Action -eq "Disable" }).Count)
    Write-Host ("Already off : {0}" -f @($Rows | Where-Object { $_.Action -eq "AlreadyDisabled" }).Count)
    Write-Host ("Revoke      : {0}" -f $RevokeSessions)

    if (-not (Confirm-Type `
        -Prompt "This will disable listed enabled accounts at the authoritative source." `
        -Required "DISABLE")) {
        throw "OPERATOR_CANCELLED"
    }

    Write-Host ""
    Write-Host "DISABLE"
    Write-Host "--------------------------------------"

    foreach ($Row in $Rows | Where-Object { $_.Action -eq "Disable" }) {
        if ($Row.AccountSource -eq "Active Directory") {
            if (-not $Row.ADUser) {
                $Row.Result = "Failed"
                $Row.Detail = "AD user not resolved. No identity change was made."
                Write-Warn "$($Row.UPN) skipped: AD user not resolved"
                continue
            }

            try {
                if (-not (Disable-ADUser -ADUser $Row.ADUser)) {
                    throw "AD validation did not show the disabled flag."
                }

                $Row.Result = "Complete - Sync Pending"
                $Row.Detail = "Active Directory disabled and verified; Entra sync pending"
                Write-OK "$($Row.UPN) disabled and verified in Active Directory"
            }
            catch {
                $Row.Result = "Failed"
                $Row.Detail = "AD disable failed: $(Get-ShortError $_)"
                Write-Warn "$($Row.UPN) AD disable failed"
                continue
            }
        }
        else {
            try {
                Invoke-GraphPatch `
                    -Uri "https://graph.microsoft.com/v1.0/users/$($Row.GraphId)" `
                    -Body @{ accountEnabled = $false } |
                    Out-Null

                $Verified = Get-GraphUser -UPN $Row.UPN

                if ($Verified.accountEnabled -ne $false) {
                    throw "Post-change validation still shows the account enabled."
                }

                $Row.Result = "Complete"
                $Row.Detail = "Entra account disabled and verified"
                Write-OK "$($Row.UPN) disabled and verified in Entra ID"
            }
            catch {
                $Row.Result = "Failed"
                $Row.Detail = "Entra disable failed: $(Get-ShortError $_)"
                Write-Warn "$($Row.UPN) Entra disable failed"
                continue
            }
        }

        if ($RevokeSessions -and $Row.GraphId) {
            try {
                Revoke-UserSessions -UserId $Row.GraphId
                $Row.Detail += "; sessions revoked"
                Write-OK "$($Row.UPN) sessions revoked"
            }
            catch {
                $Row.Detail += "; session revoke failed: $(Get-ShortError $_)"
                Write-Warn "$($Row.UPN) session revoke failed"
            }
        }
    }

    $HybridCompleted = @(
        $Rows |
        Where-Object {
            $_.AccountSource -eq "Active Directory" -and
            $_.Result -like "Complete*"
        }
    )

    $SyncResult = [PSCustomObject]@{
        Result = "Not needed"
        Detail = ""
    }

    if ($HybridCompleted.Count -gt 0) {
        if (Confirm-Yes "Run Entra Connect delta sync now") {
            $SyncResult = Run-Sync
        }
        else {
            $SyncResult = [PSCustomObject]@{
                Result = "Skipped"
                Detail = "Scheduled sync pending"
            }
        }

        Write-Host ""
        Write-Host "VALIDATION"
        Write-Host "--------------------------------------"

        foreach ($Row in $HybridCompleted) {
            try {
                $VerifiedGraph = Get-GraphUser -UPN $Row.UPN

                if ($VerifiedGraph.accountEnabled -eq $false) {
                    $Row.Result = "Complete"
                    $Row.Detail += "; Entra state verified disabled"
                    Write-OK "$($Row.UPN) Entra state: Disabled"
                }
                elseif ($SyncResult.Result -eq "Skipped") {
                    $Row.Result = "Complete - Sync Pending"
                    $Row.Detail += "; Entra still enabled; scheduled sync pending"
                    Write-Info "$($Row.UPN) Entra state still enabled; sync pending"
                }
                else {
                    $Row.Result = "Review"
                    $Row.Detail += "; Entra still enabled after sync request"
                    Write-Warn "$($Row.UPN) Entra state still enabled - verify sync propagation"
                }
            }
            catch {
                $Row.Result = "Review"
                $Row.Detail += "; Entra validation unavailable: $(Get-ShortError $_)"
                Write-Warn "$($Row.UPN) Entra validation unavailable"
            }
        }
    }

    Write-Host ""
    Write-FKHeading -Title 'TICKET SUMMARY'
    Write-Host "--------------------------------------"
    Write-Host ("Complete              : {0}" -f @($Rows | Where-Object { $_.Result -eq "Complete" }).Count)
    Write-Host ("Complete - sync pending: {0}" -f @($Rows | Where-Object { $_.Result -eq "Complete - Sync Pending" }).Count)
    Write-Host ("Review                : {0}" -f @($Rows | Where-Object { $_.Result -eq "Review" }).Count)
    Write-Host ("Failed                : {0}" -f @($Rows | Where-Object { $_.Result -eq "Failed" }).Count)
    Write-Host ("Already disabled      : {0}" -f @($Rows | Where-Object { $_.Action -eq "AlreadyDisabled" }).Count)

    Offer-ExportCsv -Rows $Rows

    Write-Host ""
    Write-Host "TICKET NOTE"

    $changedRows = @(
        $Rows |
        Where-Object {
            $_.Action -eq 'Disable' -and
            $_.Result -like 'Complete*'
        }
    )

    if ($changedRows.Count -eq 0) {
        Write-Host "- No changes made."
    }
    else {
        foreach ($Row in $changedRows) {
            Write-Host ("- Disabled account: {0} ({1})" -f $Row.UPN, $Row.AccountSource)
            if ([string]$Row.Detail -like '*sessions revoked*') {
                Write-Host ("- Revoked active sessions: {0}" -f $Row.UPN)
            }
        }

        if ($SyncResult.Result -eq 'Complete') {
            Write-Host "- Entra delta sync triggered"
        }
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