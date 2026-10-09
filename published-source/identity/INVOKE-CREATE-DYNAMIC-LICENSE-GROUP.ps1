<#
INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1

Create dynamic Entra group for licensed users.

Purpose:
- Creates a dynamic security group for enabled users with at least one active license/service plan
- Prompts for display name and mail nickname
- Does not assign licenses by itself

Change-making.
Requires Graph write permissions.
#>

param(
    [string]$DisplayName = "Dynamic-Group-AnyLicense",
    [string]$MailNickname = "DG_AnyLicense"
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

    if ($null -eq $Value) { return "" }

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

                foreach ($name in @("UPN","UserPrincipalName","Email","Address","Group","GroupName","DisplayName","Name","Input")) {
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

    if (-not $Rows -or $Rows.Count -eq 0) { return }

    if (-not (Confirm-Yes "Export results to CSV")) { return }

    $path = Read-Host "CSV output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
        OK "Exported: $path"
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

function Graph-Post {
    param(
        [string]$Uri,
        [object]$Body
    )

    try {
        return Invoke-MgGraphRequest -Method POST -Uri $Uri -Body ($Body | ConvertTo-Json -Depth 20) -ContentType "application/json" -ErrorAction Stop
    } catch {
        return $null
    }
}

function Graph-Patch {
    param(
        [string]$Uri,
        [object]$Body
    )

    try {
        Invoke-MgGraphRequest -Method PATCH -Uri $Uri -Body ($Body | ConvertTo-Json -Depth 20) -ContentType "application/json" -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Graph-Delete {
    param([string]$Uri)

    try {
        Invoke-MgGraphRequest -Method DELETE -Uri $Uri -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Ensure-Graph {
    param([string[]]$Scopes)

    $module=Get-Module -ListAvailable -Name Microsoft.Graph.Authentication -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        FAIL "Microsoft.Graph.Authentication module not available"
        Write-Host "Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
        return $false
    }

    Import-Module $module.Path -Force -ErrorAction Stop | Out-Null

    $ctx=Get-MgContext -ErrorAction SilentlyContinue
    $hasScopes=$true
    if (-not $ctx) { $hasScopes=$false }
    else {
        foreach ($scope in $Scopes) {
            if (@($ctx.Scopes) -notcontains $scope) { $hasScopes=$false; break }
        }
    }

    if ($ctx -and -not $hasScopes) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        $ctx=$null
    }

    if (-not $ctx) {
        $command=Get-Command Connect-MgGraph -ErrorAction Stop
        $parameters=@{ Scopes=$Scopes; ErrorAction='Stop' }
        if ($command.Parameters.ContainsKey('ContextScope')) { $parameters['ContextScope']='Process' }
        if ($command.Parameters.ContainsKey('NoWelcome')) { $parameters['NoWelcome']=$true }
        Connect-MgGraph @parameters | Out-Null
    }

    $ctx=Get-MgContext -ErrorAction Stop
    foreach ($scope in $Scopes) {
        if (@($ctx.Scopes) -notcontains $scope) {
            FAIL "Graph token is missing required scope: $scope"
            return $false
        }
    }

    OK "Graph connected"
    return $true
}

function Get-GraphPages {
    param([string]$Uri)

    $items = New-Object System.Collections.ArrayList

    while ($Uri) {
        $page = Graph-Get $Uri

        if (-not $page) { break }

        foreach ($item in @($page.value)) {
            [void]$items.Add($item)
        }

        $Uri = $page.'@odata.nextLink'
    }

    return @($items)
}

function Get-GraphUserByUPN {
    param([string]$UPN)

    $encoded = Encode-Value $UPN
    $uri = "https://graph.microsoft.com/v1.0/users/$encoded?`$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,usageLocation,signInActivity,lastPasswordChangeDateTime"
    $user = Graph-Get $uri

    if ($user -and $user.id) { return $user }

    $escaped = Escape-OData $UPN
    $filter = Encode-Value "userPrincipalName eq '$escaped' or mail eq '$escaped'"
    $uri = "https://graph.microsoft.com/v1.0/users?`$filter=$filter&`$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,usageLocation,signInActivity,lastPasswordChangeDateTime"
    $fallback = Graph-Get $uri

    if ($fallback -and $fallback.value -and @($fallback.value).Count -gt 0) {
        return @($fallback.value)[0]
    }

    return $null
}

function Get-GraphGroupByInput {
    param([string]$InputValue)

    $escaped = Escape-OData $InputValue
    $filter = Encode-Value "displayName eq '$escaped' or mail eq '$escaped'"
    $uri = "https://graph.microsoft.com/v1.0/groups?`$filter=$filter&`$select=id,displayName,mail,securityEnabled,mailEnabled,groupTypes,onPremisesSyncEnabled,membershipRule,membershipRuleProcessingState"
    $result = Graph-Get $uri

    if ($result -and $result.value -and @($result.value).Count -gt 0) {
        return @($result.value)[0]
    }

    return $null
}

try {
    try { $host.UI.RawUI.WindowTitle = "Create Dynamic Licensed Users Group" } catch {}

    Clear-Host
    Write-Host "CREATE DYNAMIC LICENSED USERS GROUP"
    Write-Host "Change-making"
    Write-Host ""

    $inputName = Read-Host "Display name [default: $DisplayName]"
    if ($inputName) { $DisplayName = $inputName.Trim() }

    $inputNick = Read-Host "Mail nickname [default: $MailNickname]"
    if ($inputNick) { $MailNickname = $inputNick.Trim() }

    if (-not (Ensure-Graph -Scopes @("Group.ReadWrite.All","Directory.ReadWrite.All"))) {
        Pause-End
        exit 1
    }

    $rule = '(user.accountEnabled -eq true) -and (user.assignedPlans -any (assignedPlan.servicePlanId -ne null -and assignedPlan.capabilityStatus -eq "Enabled"))'

    Section "PREVIEW"
    Write-Host "Display name : $DisplayName"
    Write-Host "Mail nickname: $MailNickname"
    Write-Host "Rule         : $rule"
    Write-Host ""

    $existing = Get-GraphGroupByInput -InputValue $DisplayName

    if ($existing) {
        WARN "Group already exists: $($existing.displayName)"
        Pause-End
        exit 0
    }

    if (-not (Confirm-Type "This will create a dynamic Entra security group." "CREATE")) {
        WARN "Cancelled"
        Pause-End
        exit 0
    }

    $body = @{
        displayName = $DisplayName
        mailEnabled = $false
        mailNickname = $MailNickname
        securityEnabled = $true
        groupTypes = @("DynamicMembership")
        membershipRule = $rule
        membershipRuleProcessingState = "On"
    }

    Section "CREATE"

    $created = Graph-Post "https://graph.microsoft.com/v1.0/groups" $body

    if ($created -and $created.id) {
        Start-Sleep -Milliseconds 300
        $verified=Get-GraphGroupByInput -InputValue $DisplayName

        if (
            $verified -and
            [string]$verified.id -eq [string]$created.id -and
            @($verified.groupTypes) -contains "DynamicMembership" -and
            [string]$verified.membershipRule -eq [string]$rule -and
            [string]$verified.membershipRuleProcessingState -eq "On"
        ) {
            OK "Group created and verified: $DisplayName"
        }
        else {
            throw "Group creation returned success, but the dynamic membership configuration could not be verified."
        }
    } else {
        throw "Group creation failed."
    }

    Section "SUMMARY"
    Write-Host "Display name : $DisplayName"
    Write-Host "Mail nickname: $MailNickname"
    Write-Host "Rule         : $rule"
    Write-Host "Operator     : $env:USERDOMAIN\$env:USERNAME"
    Write-Host "Time         : $(Now)"

    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}

