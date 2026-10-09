<#
user-license-provision-bulk-clean.ps1

User license assignment for one or more users.

Purpose:
- Accepts one or more UPNs or a TXT/CSV list
- Shows tenant SKUs
- Operator selects one SKU
- Assigns selected license only after typed confirmation
- Can set UsageLocation for users missing it if approved

Change-making.
#>

param(
    [Alias('UPN')]
    [string[]]$InputObject,
    [string]$InputPath,
    [string]$UsageLocation
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
                    if ($candidate -and $candidate.Trim()) { [void]$items.Add($candidate.Trim().Trim('"').Trim("'")) }
                }
            }
            else {
                foreach ($line in @(Get-Content -LiteralPath $clean -Encoding UTF8 -ErrorAction Stop)) {
                    $candidate=([string]$line).Trim().Trim('"').Trim("'")
                    if ($candidate -and $candidate -notmatch '^#') { [void]$items.Add($candidate) }
                }
            }
            continue
        }

        foreach ($candidate in @($clean -split '\s*,\s*')) {
            if ($candidate) { [void]$items.Add($candidate.Trim()) }
        }
    }

    $upns=@($items | Where-Object { $_ } | Select-Object -Unique)
    foreach ($upn in $upns) {
        if ($upn -notmatch '^[^@\s]+@[^@\s]+$') { throw "Invalid UPN: $upn" }
    }

    return $upns
}

function Offer-ExportCsv {
    param(
        [array]$Rows,
        [string]$DefaultName
    )

    if (-not $Rows -or $Rows.Count -eq 0) { return }
    if (-not (Confirm-Yes "Export results to CSV")) { return }

    $path=(Read-Host "CSV output path [blank for .\$DefaultName]").Trim().Trim('"')
    if (-not $path) { $path=Join-Path (Get-Location).Path $DefaultName }

    try {
        $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
        $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)
        if ($check.Count -ne $Rows.Count) {
            throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
        }
        OK "Exported and verified: $path"
    }
    catch {
        WARN ("CSV export failed: {0}" -f $_.Exception.Message)
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
    try { $host.UI.RawUI.WindowTitle = "Assign User Licenses" } catch {}

    Clear-Host
    Write-Host "ASSIGN USER LICENSES"
    Write-Host "Change-making"
    Write-Host ""

    $upns = @(Get-InputUPNs -Values $InputObject -Path $InputPath)

    if ($upns.Count -eq 0) {
        Pause-End
        exit 1
    }

    if (-not (Ensure-Graph -Scopes @("User.ReadWrite.All","Directory.Read.All","Organization.Read.All"))) {
        Pause-End
        exit 1
    }

    Section "TENANT SKUS"

    $skus = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/subscribedSkus")
    $available = @($skus | Where-Object { $_.prepaidUnits.enabled -gt $_.consumedUnits })

    if ($available.Count -eq 0) {
        WARN "No SKUs with available capacity found. Showing all SKUs."
        $available = $skus
    }

    $index = 0
    $indexMap = @{}

    foreach ($sku in $available | Sort-Object skuPartNumber) {
        $index++
        $indexMap["$index"] = $sku
        $free = [int]$sku.prepaidUnits.enabled - [int]$sku.consumedUnits
        Write-Host "[$index] $($sku.skuPartNumber) | Enabled: $($sku.prepaidUnits.enabled) | Consumed: $($sku.consumedUnits) | Free: $free"
    }

    $choice = (Read-Host "Choose SKU to assign").Trim()

    if (-not $indexMap.ContainsKey($choice)) {
        FAIL "Invalid selection"
        Pause-End
        exit 1
    }

    $selected = $indexMap[$choice]

    if (-not $UsageLocation) {
        $UsageLocation = (Read-Host "UsageLocation for missing users, e.g. US [blank to skip]").Trim().ToUpper()
    }

    Section "PREVIEW"

    $users = New-Object System.Collections.ArrayList

    foreach ($upn in $upns) {
        $u = Get-GraphUserByUPN -UPN $upn

        if (-not $u) {
            WARN "User not found: $upn"
            continue
        }

        $already = @($u.assignedLicenses | Where-Object { "$($_.skuId)" -eq "$($selected.skuId)" }).Count -gt 0

        [void]$users.Add([pscustomobject]@{
            Id=$u.id
            UPN=$u.userPrincipalName
            UsageLocation=$u.usageLocation
            AlreadyAssigned=$already
        })
    }

    Write-Host "Users found : $($users.Count)"
    Write-Host "SKU         : $($selected.skuPartNumber)"
    Write-Host "UsageLoc    : $(if ($UsageLocation) { $UsageLocation } else { 'No change' })"
    Write-Host "Already has : $(@($users | Where-Object { $_.AlreadyAssigned }).Count)"
    Write-Host "To assign   : $(@($users | Where-Object { -not $_.AlreadyAssigned }).Count)"
    Write-Host ""

    if (-not (Confirm-Type "This will assign licenses to users." "ASSIGN")) {
        WARN "Cancelled"
        Pause-End
        exit 0
    }

    $results = New-Object System.Collections.ArrayList

    Section "ASSIGN"

    foreach ($u in $users) {
        if ($u.AlreadyAssigned) {
            WARN "$($u.UPN) already has $($selected.skuPartNumber)"
            [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="AssignLicense"; Result="Skipped"; Detail="Already assigned" })
            continue
        }

        if (-not $u.UsageLocation -and $UsageLocation) {
            if (Graph-Patch "https://graph.microsoft.com/v1.0/users/$($u.Id)" @{ usageLocation = $UsageLocation }) {
                OK "$($u.UPN) usageLocation set to $UsageLocation"
            } else {
                WARN "$($u.UPN) usageLocation update failed"
            }
        }

        $body = @{
            addLicenses = @(
                @{
                    skuId = $selected.skuId
                    disabledPlans = @()
                }
            )
            removeLicenses = @()
        }

        $result = Graph-Post "https://graph.microsoft.com/v1.0/users/$($u.Id)/assignLicense" $body

        if ($result) {
            Start-Sleep -Milliseconds 300
            $verified=Get-GraphUserByUPN -UPN $u.UPN
            $present=$false

            if ($verified) {
                $present=@($verified.assignedLicenses | Where-Object { "$($_.skuId)" -eq "$($selected.skuId)" }).Count -gt 0
            }

            if ($present) {
                OK "$($u.UPN) assigned and verified $($selected.skuPartNumber)"
                [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="AssignLicense"; Result="Verified"; Detail=$selected.skuPartNumber })
            }
            else {
                WARN "$($u.UPN) assignment returned success but verification did not confirm the SKU"
                [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="AssignLicense"; Result="FailedValidation"; Detail=$selected.skuPartNumber })
            }
        } else {
            WARN "$($u.UPN) license assignment failed"
            [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="AssignLicense"; Result="Failed"; Detail=$selected.skuPartNumber })
        }
    }

    Section "SUMMARY"
    Write-Host "Users processed : $($users.Count)"
    Write-Host "Verified        : $(@($results | Where-Object { $_.Result -eq 'Verified' }).Count)"
    Write-Host "Skipped         : $(@($results | Where-Object { $_.Result -eq 'Skipped' }).Count)"
    Write-Host "Failed          : $(@($results | Where-Object { $_.Result -eq 'Failed' }).Count)"
    Write-Host "SKU             : $($selected.skuPartNumber)"

    Offer-ExportCsv -Rows @($results) -DefaultName "license-provision-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}