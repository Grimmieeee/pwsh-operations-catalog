<#
user-license-removal-bulk-clean.ps1

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
    [string]$InputPath
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
    try { $host.UI.RawUI.WindowTitle = "Remove User Licenses" } catch {}

    Clear-Host
    Write-Host "REMOVE USER LICENSES"
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

        if (-not $u) {
            WARN "User not found: $upn"
            continue
        }

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
        exit 1
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
            exit 1
        }

        $targetSku = $indexMap[$choice]
    }

    Section "PLAN"
    Write-Host "Users      : $($users.Count)"
    Write-Host "Remove     : $(if ($removeAll) { 'ALL LICENSES' } else { $(if ($skuMap.ContainsKey($targetSku)) { $skuMap[$targetSku] } else { $targetSku }) })"
    Write-Host ""

    if (-not (Confirm-Type "This will remove licenses from users." "REMOVE")) {
        WARN "Cancelled"
        Pause-End
        exit 0
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

        $result = Graph-Post "https://graph.microsoft.com/v1.0/users/$($u.Id)/assignLicense" $body

        if ($result) {
            Start-Sleep -Milliseconds 300
            $verified=Get-GraphUserByUPN -UPN $u.UPN
            $remaining=@()

            if ($verified) {
                $remaining=@(
                    $verified.assignedLicenses |
                    ForEach-Object { "$($_.skuId)" } |
                    Where-Object { $removeIds -contains $_ }
                )
            }

            if ($verified -and $remaining.Count -eq 0) {
                OK "$($u.UPN) license removal verified"
                [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="RemoveLicense"; Result="Verified"; Detail=($removeIds -join "; ") })
            }
            else {
                WARN "$($u.UPN) removal returned success but verification still found targeted license state"
                [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="RemoveLicense"; Result="FailedValidation"; Detail=($removeIds -join "; ") })
            }
        } else {
            WARN "$($u.UPN) license removal failed"
            [void]$results.Add([pscustomobject]@{ UPN=$u.UPN; Action="RemoveLicense"; Result="Failed"; Detail=($removeIds -join "; ") })
        }
    }

    Section "SUMMARY"
    Write-Host "Users processed : $($users.Count)"
    Write-Host "Verified        : $(@($results | Where-Object { $_.Result -eq 'Verified' }).Count)"
    Write-Host "Skipped         : $(@($results | Where-Object { $_.Result -eq 'Skipped' }).Count)"
    Write-Host "Failed          : $(@($results | Where-Object { $_.Result -eq 'Failed' }).Count)"

    Offer-ExportCsv -Rows @($results) -DefaultName "license-removal-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}