<#
group-members-audit-bulk-clean.ps1

Read-only bulk group membership audit.

Purpose:
- Reads a TXT/CSV list of group names or email addresses
- Resolves each group in Entra ID
- Lists direct members
- Prints ticket-ready summary
- Optional CSV export only when approved
#>

param(
    [string]$InputPath,
    [string]$TenantDomain
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }
function INFO($m) { Write-Host "[INFO] $m" }
function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }
function RISK($m) { Write-Host "[RISK] $m" -ForegroundColor Red }
function FAIL($m) { Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host "--------------------------------------" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "Timestamp: $(Now)" -ForegroundColor Cyan
    Write-Host "--------------------------------------" -ForegroundColor Cyan
}

function Confirm-Yes {
    param([string]$Prompt)

    $a = Read-Host "$Prompt [Y/N]"
    return ($a.Trim().ToUpper() -eq "Y")
}

function Confirm-Type {
    param(
        [string]$Prompt,
        [string]$Required
    )

    Write-Host ""
    WARN $Prompt
    $a = Read-Host "Type $Required to continue"

    return ($a.Trim().ToUpper() -eq $Required.ToUpper())
}

function Encode-Value {
    param([string]$Value)
    return [System.Uri]::EscapeDataString($Value)
}

function Escape-OData {
    param([string]$Value)
    return ($Value -replace "'", "''")
}

function Clean-Name {
    param([object]$Value)

    if ($null -eq $Value) {
        return ""
    }

    $text = [string]$Value
    return ($text -replace '\s*\([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\)\s*$', '').Trim()
}

function Get-InputLines {
    param([string]$Path)

    if (-not $Path) {
        $Path = (Read-Host "Input TXT/CSV path").Trim().Trim('"')
    }

    if (-not $Path -or -not (Test-Path $Path)) {
        FAIL "Input file not found"
        return @()
    }

    $items = New-Object System.Collections.ArrayList

    try {
        if ($Path.ToLower().EndsWith(".csv")) {
            $rows = Import-Csv -Path $Path -ErrorAction Stop

            foreach ($row in $rows) {
                $value = $null

                foreach ($name in @("UPN","UserPrincipalName","Email","Address","Group","GroupName","Name","Input")) {
                    if ($row.PSObject.Properties.Name -contains $name -and $row.$name) {
                        $value = "$($row.$name)"
                        break
                    }
                }

                if (-not $value) {
                    $first = $row.PSObject.Properties | Select-Object -First 1
                    if ($first) { $value = "$($first.Value)" }
                }

                if ($value -and $value.Trim()) {
                    [void]$items.Add($value.Trim().Trim('"'))
                }
            }
        }
        else {
            $lines = Get-Content -Path $Path -Encoding UTF8 -ErrorAction Stop

            foreach ($line in $lines) {
                $clean = $line.Trim().Trim('"')

                if ($clean -and $clean -notmatch '^#') {
                    [void]$items.Add($clean)
                }
            }
        }
    }
    catch {
        FAIL "Could not read input file"
        return @()
    }

    return @($items | Select-Object -Unique)
}

function Offer-ExportCsv {
    param(
        [array]$Rows,
        [string]$DefaultName
    )

    if (-not $Rows -or $Rows.Count -eq 0) {
        return
    }

    if (-not (Confirm-Yes "Export results to CSV")) {
        return
    }

    $path = Read-Host "CSV output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        $check = @(Import-Csv -LiteralPath $path -ErrorAction Stop)
        if ($check.Count -ne $Rows.Count) { throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)." }
        $expected = @($Rows | ForEach-Object { "{0}|{1}|{2}|{3}|{4}|{5}" -f $_.GroupName,$_.GroupMail,$_.MemberName,$_.MemberUPN,$_.MemberMail,$_.UserType })
        $actual = @($check | ForEach-Object { "{0}|{1}|{2}|{3}|{4}|{5}" -f $_.GroupName,$_.GroupMail,$_.MemberName,$_.MemberUPN,$_.MemberMail,$_.UserType })
        $difference = @(Compare-Object -ReferenceObject $expected -DifferenceObject $actual -SyncWindow 0)
        if ($difference.Count -gt 0) { throw "CSV verification failed. Exported content did not match the in-memory results." }
        OK "Exported and verified: $path"
    }
    catch {
        WARN "CSV export failed"
    }
}

function Graph-Get {
    param([string]$Uri)

    try {
        return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop
    } catch {
        return $null
    }
}

function Ensure-Graph {
    param(
        [string[]]$Scopes,
        [string]$TenantDomain
    )

    $module = Get-Module -ListAvailable -Name Microsoft.Graph.Authentication |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        FAIL "Microsoft.Graph.Authentication module not available"
        Write-Host "Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
        return $false
    }

    try {
        Import-Module $module.Path -Force -ErrorAction Stop
        $ctx = Get-MgContext -ErrorAction SilentlyContinue
        $hasScopes = $true
        if (-not $ctx) { $hasScopes = $false }
        else {
            foreach ($scope in $Scopes) {
                if (@($ctx.Scopes) -notcontains $scope) { $hasScopes = $false; break }
            }
        }

        if ($ctx -and (-not $hasScopes -or $TenantDomain)) {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
            $ctx = $null
        }

        if (-not $ctx) {
            $command = Get-Command Connect-MgGraph -ErrorAction Stop
            $parameters = @{ Scopes=$Scopes; ErrorAction="Stop" }
            if ($command.Parameters.ContainsKey("ContextScope")) { $parameters["ContextScope"] = "Process" }
            if ($command.Parameters.ContainsKey("NoWelcome")) { $parameters["NoWelcome"] = $true }
            if ($TenantDomain -and $command.Parameters.ContainsKey("TenantId")) { $parameters["TenantId"] = $TenantDomain }
            Connect-MgGraph @parameters | Out-Null
            $ctx = Get-MgContext -ErrorAction Stop
        }

        foreach ($scope in $Scopes) {
            if (@($ctx.Scopes) -notcontains $scope) { throw "Graph token is missing required scope: $scope" }
        }

        OK "Graph connected"
        if ($ctx.TenantId) { INFO "Tenant ID: $($ctx.TenantId)" }
        if ($TenantDomain) { INFO "Requested tenant: $TenantDomain" }
        return $true
    }
    catch {
        FAIL "Graph connection failed: $($_.Exception.Message)"
        return $false
    }
}
function Get-GraphPages {
    param([string]$Uri)

    $items = New-Object System.Collections.ArrayList

    while ($Uri) {
        $page = Graph-Get $Uri

        if (-not $page) {
            break
        }

        foreach ($item in @($page.value)) {
            [void]$items.Add($item)
        }

        $Uri = $page.'@odata.nextLink'
    }

    return @($items)
}

function Get-GraphGroupByInput {
    param([string]$InputValue)

    $escaped = Escape-OData $InputValue
    $filter = Encode-Value "displayName eq '$escaped' or mail eq '$escaped' or mailNickname eq '$escaped'"
    $uri = "https://graph.microsoft.com/v1.0/groups?`$filter=$filter&`$select=id,displayName,mail,mailNickname,securityEnabled,mailEnabled,groupTypes,onPremisesSyncEnabled&`$top=10"
    $result = Graph-Get $uri

    if (-not $result -or -not $result.value) { return $null }
    $matches = @($result.value)
    if ($matches.Count -eq 1) { return $matches[0] }
    if ($matches.Count -gt 1) { WARN "Ambiguous group input: $InputValue matched $($matches.Count) Entra groups" }
    return $null
}
try {
    try { $host.UI.RawUI.WindowTitle = "Bulk Entra Group Members Review" } catch {}

    Clear-Host
    Write-Host "BULK ENTRA GROUP MEMBERS REVIEW"
    Write-Host "Read-only"
    Write-Host ""

    $groupsToCheck = @(Get-InputLines -Path $InputPath)

    if ($groupsToCheck.Count -eq 0) {
        Pause-End
        exit 1
    }

    Section "CONNECT"

    if (-not $TenantDomain) {
        $TenantDomain = (Read-Host "Tenant domain (example: contoso.com)").Trim()
    }

    if (-not (Ensure-Graph -Scopes @("Group.Read.All","User.Read.All","Directory.Read.All") -TenantDomain $TenantDomain)) {
        Pause-End
        exit 1
    }

    Section "AUDIT"

    $rows = New-Object System.Collections.ArrayList
    $summary = New-Object System.Collections.ArrayList

    foreach ($g in $groupsToCheck) {
        INFO "Checking group: $g"
        $group = Get-GraphGroupByInput -InputValue $g

        if (-not $group) {
            WARN "Group not found: $g"
            [void]$summary.Add([pscustomobject]@{ GroupInput=$g; GroupName=""; Mail=""; Members=0; Status="NotFound" })
            continue
        }

        $uri = "https://graph.microsoft.com/v1.0/groups/$($group.id)/members?`$select=id,displayName,userPrincipalName,mail,userType,accountEnabled"
        $members = @(Get-GraphPages -Uri $uri)

        [void]$summary.Add([pscustomobject]@{
            GroupInput=$g
            GroupName=$group.displayName
            Mail=$group.mail
            Members=$members.Count
            Status="Found"
        })

        if ($members.Count -eq 0) {
            WARN "No direct members: $($group.displayName)"
        }

        foreach ($m in $members) {
            [void]$rows.Add([pscustomobject]@{
                GroupName=$group.displayName
                GroupMail=$group.mail
                MemberName=$m.displayName
                MemberUPN=$m.userPrincipalName
                MemberMail=$m.mail
                UserType=$m.userType
                AccountEnabled=$m.accountEnabled
            })
        }
    }

    Section "SUMMARY"
    Write-Host "Groups checked : $($groupsToCheck.Count)"
    Write-Host "Groups found   : $(@($summary | Where-Object { $_.Status -eq 'Found' }).Count)"
    Write-Host "Not found      : $(@($summary | Where-Object { $_.Status -eq 'NotFound' }).Count)"
    Write-Host "Member rows    : $($rows.Count)"
    Write-Host ""
    Write-Host ". . . . COPY THIS SUMMARY TO TICKET . . . ."
    Write-Host ""
    Write-Host "BULK ENTRA GROUP MEMBERS REVIEW"
    Write-Host "--------------------------------------"
    Write-Host ("Timestamp      : {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
    Write-Host ("Tenant target  : {0}" -f $TenantDomain)
    Write-Host ("Groups checked : {0}" -f $groupsToCheck.Count)
    Write-Host ("Groups found   : {0}" -f @($summary | Where-Object { $_.Status -eq "Found" }).Count)
    Write-Host ("Not found      : {0}" -f @($summary | Where-Object { $_.Status -eq "NotFound" }).Count)
    Write-Host ("Member rows    : {0}" -f $rows.Count)
    Write-Host "Direct Entra members only. Read-only. No changes made."
    Write-Host ""
    Write-Host ". . . . END SUMMARY . . . ."
    Write-Host ""

    foreach ($s in $summary) {
        Write-Host ("{0,-40} {1,5} {2}" -f $s.GroupName, $s.Members, $s.Status)
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "group-members-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}