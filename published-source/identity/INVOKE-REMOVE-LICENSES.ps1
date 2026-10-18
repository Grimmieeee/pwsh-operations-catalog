<#
INVOKE-REMOVE-LICENSES.ps1
.VERSION 1.0.1

User license removal for one or more users.

Purpose:
- Accepts one or more UPNs or a TXT/CSV list
- Shows current licenses
- Operator chooses one SKU or all licenses
- Removes licenses only after typed confirmation

Change-making.
#>

param(
    [Alias('UPN')]
    [string[]]$InputObject,
    [string]$InputPath,
    [string]$ExpectedTenantId
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

    return Invoke-MgGraphRequest -Method GET -Uri $Uri -ErrorAction Stop
}

function Graph-Post {
    param(
        [string]$Uri,
        [object]$Body
    )

    return Invoke-MgGraphRequest -Method POST -Uri $Uri -Body ($Body | ConvertTo-Json -Depth 20) -ContentType "application/json" -ErrorAction Stop
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
    param([string[]]$Scopes, [string]$TenantId)

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
    if ($ctx -and $ctx.TenantId -ne $TenantId) {
        throw 'Existing Graph session is for another tenant. No changes made. Open a new PowerShell window and sign in to the expected tenant.'
    }
    if ($ctx -and ($ctx.AuthType -ne 'Delegated' -or -not $ctx.Account)) {
        throw 'An interactive delegated Graph session is required. Open a new PowerShell window and sign in.'
    }
    $hasScopes=$true
    if (-not $ctx) { $hasScopes=$false }
    else {
        foreach ($scope in $Scopes) {
            if (@($ctx.Scopes) -notcontains $scope) { $hasScopes=$false; break }
        }
    }

    if ($ctx -and (-not $hasScopes -or $ctx.ContextScope -ne 'Process')) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        $ctx=$null
    }

    if (-not $ctx) {
        $command=Get-Command Connect-MgGraph -ErrorAction Stop
        if (-not $command.Parameters.ContainsKey('ContextScope')) { throw 'Update Microsoft.Graph.Authentication to a version supporting process-scoped sign-in.' }
        $parameters=@{ Scopes=$Scopes; TenantId=$TenantId; ContextScope='Process'; ErrorAction='Stop' }
        if ($command.Parameters.ContainsKey('NoWelcome')) { $parameters['NoWelcome']=$true }
        Connect-MgGraph @parameters | Out-Null
    }

    $ctx=Get-MgContext -ErrorAction Stop
    Assert-GraphContext -TenantId $TenantId
    foreach ($scope in $Scopes) {
        if (@($ctx.Scopes) -notcontains $scope) {
            FAIL "Graph token is missing required scope: $scope"
            return $false
        }
    }

    OK "Graph connected"
    return $true
}

function Assert-GraphContext {
    param([string]$TenantId, [string]$Account)
    $ctx=Get-MgContext -ErrorAction Stop
    if (-not $ctx -or $ctx.TenantId -ne $TenantId -or $ctx.AuthType -ne 'Delegated' -or
        -not $ctx.Account -or $ctx.ContextScope -ne 'Process' -or ($Account -and $ctx.Account -ne $Account)) {
        throw 'Graph tenant/account context changed or could not be validated. Stop and review the results; do not retry changes blindly.'
    }
}

function Get-AssignedLicenseIds {
    param($User)
    $hasState = $null -ne $User -and (
        ($User -is [System.Collections.IDictionary] -and $User.Contains('assignedLicenses')) -or
        $User.PSObject.Properties.Name -contains 'assignedLicenses')
    if (-not $hasState -or $null -eq $User.assignedLicenses) { throw 'Assigned-license state is unavailable; absence is not verified.' }
    foreach ($license in @($User.assignedLicenses)) {
        if (-not $license.skuId) { throw 'Assigned-license state is incomplete.' }
        [string]$license.skuId
    }
}

function Get-GraphPages {
    param([string]$Uri)

    $items = New-Object System.Collections.ArrayList

    while ($Uri) {
        $page = Graph-Get $Uri

        if (-not $page -or $null -eq $page.value) { throw 'License inventory is unavailable. No changes made.' }

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
    $uri = "https://graph.microsoft.com/v1.0/users/${encoded}?`$select=id,displayName,userPrincipalName,assignedLicenses"
    $user = Graph-Get $uri

    if (-not $user -or -not $user.id -or $user.userPrincipalName -ne $UPN) { throw "Exact UPN could not be validated: $UPN. No alias/first-match fallback is used." }
    return $user
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
    try { $host.UI.RawUI.WindowTitle = "Remove User Licenses" } catch {}

    Clear-Host
    Write-Host "REMOVE USER LICENSES"
    Write-Host "Change-making"
    Write-Host ""

    $upns = @(Get-InputUPNs -Values $InputObject -Path $InputPath)

    if ($upns.Count -eq 0) {
        Pause-End
        return
    }

    if (-not $ExpectedTenantId) { $ExpectedTenantId=(Read-Host 'Expected tenant ID (GUID; blank cancels)').Trim() }
    $tenantGuid=[guid]::Empty
    if (-not [guid]::TryParse($ExpectedTenantId, [ref]$tenantGuid) -or $tenantGuid -eq [guid]::Empty) {
        throw 'A valid expected tenant ID is required. No changes made.'
    }
    $ExpectedTenantId=$tenantGuid.ToString()
    if (-not (Ensure-Graph -Scopes @("User.ReadWrite.All","Directory.Read.All","Organization.Read.All") -TenantId $ExpectedTenantId)) {
        Pause-End
        return
    }
    $approvedAccount=(Get-MgContext -ErrorAction Stop).Account

    $skus = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/subscribedSkus")
    $skuMap = @{}

    foreach ($sku in $skus) {
        $skuMap["$($sku.skuId)"] = $sku.skuPartNumber
    }

    Section "PREVIEW"

    $users = New-Object System.Collections.ArrayList
    $heldSkus = @{}

    foreach ($upn in $upns) {
        $u = Get-GraphUserByUPN -UPN $upn

        # Resolve every supplied target before offering any change approval.
        $null = @(Get-AssignedLicenseIds -User $u)
        $licenses = @($u.assignedLicenses)

        [void]$users.Add([pscustomobject]@{
            Id=$u.id
            UPN=$u.userPrincipalName
            Licenses=$licenses
        })

        foreach ($lic in $licenses) {
            $id = "$($lic.skuId)"
            if (-not $heldSkus.ContainsKey($id)) {
                $heldSkus[$id] = 0
            }
            $heldSkus[$id]++
        }
    }

    if ($users.Count -eq 0) {
        FAIL "No valid users found"
        Pause-End
        return
    }

    Write-Host "Users found: $($users.Count)"
    Write-Host ""
    Write-Host "License options:"
    Write-Host "[ALL] Remove all licenses from listed users"

    $skuKeys = @($heldSkus.Keys | Sort-Object)
    $index = 0
    $indexMap = @{}

    foreach ($key in $skuKeys) {
        $index++
        $indexMap["$index"] = $key
        $name = if ($skuMap.ContainsKey($key)) { $skuMap[$key] } else { $key }
        Write-Host "[$index] $name - held by $($heldSkus[$key]) listed user(s)"
    }

    $choice = (Read-Host "Choose license to remove").Trim().ToUpper()

    $removeAll = ($choice -eq "ALL")
    $targetSku = $null

    if (-not $removeAll) {
        if (-not $indexMap.ContainsKey($choice)) {
            FAIL "Invalid selection"
            Pause-End
            return
        }

        $targetSku = $indexMap[$choice]
    }

    Section "PLAN"
    Assert-GraphContext -TenantId $ExpectedTenantId -Account $approvedAccount
    Write-Host "Tenant ID  : $ExpectedTenantId"
    Write-Host "Account    : $approvedAccount"
    Write-Host "Users      : $($users.Count)"
    Write-Host "Remove     : $(if ($removeAll) { 'ALL LICENSES' } else { $(if ($skuMap.ContainsKey($targetSku)) { $skuMap[$targetSku] } else { $targetSku }) })"
    Write-Host ""
    foreach ($u in $users) {
        $planned=@($u.Licenses | Where-Object { $removeAll -or [string]$_.skuId -eq $targetSku } | ForEach-Object {
            $id=[string]$_.skuId
            if ($skuMap.ContainsKey($id)) { $skuMap[$id] } else { $id }
        })
        $description=if ($planned.Count) { $planned -join ', ' } else { 'No matching license; will skip' }
        Write-Host "$($u.UPN) -> $description"
    }

    if (-not (Confirm-Type "This will remove licenses from users." "REMOVE")) {
        WARN "Cancelled"
        Pause-End
        return
    }

    $results = New-Object System.Collections.ArrayList

    Section "REMOVE"

    foreach ($u in $users) {
        $removeIds = @()

        if ($removeAll) {
            $removeIds = @($u.Licenses | ForEach-Object { "$($_.skuId)" })
        } else {
            $has = @($u.Licenses | Where-Object { "$($_.skuId)" -eq $targetSku })
            if ($has.Count -gt 0) { $removeIds = @($targetSku) }
        }

        if ($removeIds.Count -eq 0) {
            WARN "$($u.UPN) no matching license"
            [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="RemoveLicense"; Result="Skipped"; Detail="No matching license" })
            continue
        }

        $body = @{
            addLicenses = @()
            removeLicenses = $removeIds
        }

        $requestReturned=$false
        try {
            Assert-GraphContext -TenantId $ExpectedTenantId -Account $approvedAccount
            Graph-Post "https://graph.microsoft.com/v1.0/users/$($u.Id)/assignLicense" $body | Out-Null
            $requestReturned=$true
            Start-Sleep -Milliseconds 300
            $verified=Get-GraphUserByUPN -UPN $u.UPN
            if ($verified.id -ne $u.Id) { throw 'Target identity changed; final state is unverified.' }
            $remaining=@(Get-AssignedLicenseIds -User $verified | Where-Object { $removeIds -contains $_ })
            if ($remaining.Count -eq 0) {
                OK "$($u.UPN) license removal verified"
                [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="RemoveLicense"; Result="Verified"; Detail=($removeIds -join "; ") })
            }
            else {
                WARN "$($u.UPN) request returned but targeted licenses remain. Review before retrying."
                [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="RemoveLicense"; Result="FailedValidation"; Detail=($removeIds -join "; ") })
            }
        } catch {
            $state=if ($requestReturned) { 'FailedValidation' } else { 'Failed' }
            WARN "$($u.UPN): request or verification failed; final state is unverified. $($_.Exception.Message)"
            [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="RemoveLicense"; Result=$state; Detail=$_.Exception.Message })
        }
    }

    Section "SUMMARY"
    Write-Host "Users processed : $($users.Count)"
    Write-Host "Verified        : $(@($results | Where-Object { $_.Result -eq 'Verified' }).Count)"
    Write-Host "Skipped         : $(@($results | Where-Object { $_.Result -eq 'Skipped' }).Count)"
    Write-Host "Failed          : $(@($results | Where-Object { $_.Result -eq 'Failed' }).Count)"
    Write-Host "Unverified      : $(@($results | Where-Object { $_.Result -eq 'FailedValidation' }).Count)"

    Offer-ExportCsv -Rows @($results) -DefaultName "license-removal-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    $unresolved=@($results | Where-Object { $_.Result -in @('Failed','FailedValidation') }).Count
    if ($unresolved) {
        WARN 'STATUS: Incomplete - failed or unverified results remain.'
        INFO 'NEXT STEP: Review per-user results and current license state before retrying. Do not close the task as successful.'
    } elseif (@($results | Where-Object { $_.Result -eq 'Verified' }).Count) {
        OK 'STATUS: Completed - requested removals verified; review any skipped users.'
        INFO 'NEXT STEP: Record results and continue the approved offboarding process. License removal alone is not offboarding.'
    } else {
        INFO 'STATUS: No changes - no matching licenses.'
        INFO 'NEXT STEP: Review the selected users and license; no removal was verified.'
    }
    Pause-End
}
catch {
    Write-Host ""
    FAIL "STATUS: Stopped - task not completed"
    Write-Host $_.Exception.Message
    Pause-End
}
