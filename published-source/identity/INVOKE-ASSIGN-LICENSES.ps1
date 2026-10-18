<#
INVOKE-ASSIGN-LICENSES.ps1
.VERSION 1.0.1
Assign one selected tenant license to approved exact UPNs.
Requires expected tenant GUID; previews every user and any UsageLocation change.
#>
param(
    [Alias('UPN')][string[]]$InputObject,
    [string]$InputPath,
    [string]$UsageLocation,
    [string]$ExpectedTenantId
)
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12 }

function OK($m)   { Write-Host "[OK]   $m" -ForegroundColor Green }

function INFO($m) { Write-Host "[INFO] $m" }

function WARN($m) { Write-Host "[WARN] $m" -ForegroundColor Yellow }

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
    $uri = "https://graph.microsoft.com/v1.0/users/${encoded}?`$select=id,displayName,userPrincipalName,assignedLicenses,usageLocation"
    $user = Graph-Get $uri

    if (-not $user -or -not $user.id -or $user.userPrincipalName -ne $UPN) { throw "Exact UPN could not be validated: $UPN. No alias/first-match fallback is used." }
    return $user
}

try {
    try { $host.UI.RawUI.WindowTitle='Assign User Licenses' } catch {}
    Write-Host 'ASSIGN USER LICENSES'
    Write-Host 'Assign one approved license to exact users after tenant and target review.'
    $upns=@(Get-InputUPNs -Values $InputObject -Path $InputPath)
    if (-not $upns.Count) { throw 'At least one exact UPN is required.' }
    if (-not $ExpectedTenantId) { $ExpectedTenantId=(Read-Host 'Expected tenant ID (GUID; blank cancels)').Trim() }
    $tenantGuid=[guid]::Empty
    if (-not [guid]::TryParse($ExpectedTenantId,[ref]$tenantGuid) -or $tenantGuid -eq [guid]::Empty) { throw 'A valid expected tenant ID is required. No changes made.' }
    $ExpectedTenantId=$tenantGuid.ToString()
    if (-not (Ensure-Graph -Scopes @('User.ReadWrite.All','Directory.Read.All','Organization.Read.All') -TenantId $ExpectedTenantId)) { return }
    $approvedAccount=(Get-MgContext -ErrorAction Stop).Account
    Section 'TENANT LICENSES'
    $skus=@(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/subscribedSkus')
    if (-not $skus.Count) { throw 'No tenant license inventory returned. No changes made.' }
    $available=@($skus | Where-Object { $_.prepaidUnits.enabled -gt $_.consumedUnits })
    if (-not $available.Count) { WARN 'No SKUs with available capacity. Showing all; availability is not guaranteed.'; $available=$skus }
    $indexMap=@{}; $index=0
    foreach ($sku in $available | Sort-Object skuPartNumber) {
        $index++; $indexMap[[string]$index]=$sku
        Write-Host "[$index] $($sku.skuPartNumber) | Free: $([int]$sku.prepaidUnits.enabled - [int]$sku.consumedUnits)"
    }
    $choice=(Read-Host 'Choose SKU to assign').Trim()
    if (-not $indexMap.ContainsKey($choice)) { throw 'Invalid license selection. No changes made.' }
    $selected=$indexMap[$choice]
    if (-not $selected.skuId) { throw 'Selected license ID is unavailable.' }
    if (-not $UsageLocation) { $UsageLocation=(Read-Host 'UsageLocation for missing users, e.g. US [blank to skip]').Trim().ToUpperInvariant() }
    if ($UsageLocation -and $UsageLocation -notmatch '^[A-Za-z]{2}$') { throw 'UsageLocation must be a two-letter country/region code. No changes made.' }
    $targets=New-Object System.Collections.ArrayList
    foreach ($upn in $upns) {
        $user=Get-GraphUserByUPN -UPN $upn
        $ids=@(Get-AssignedLicenseIds -User $user)
        [void]$targets.Add([pscustomobject]@{Id=$user.id;UPN=$user.userPrincipalName;UsageLocation=$user.usageLocation;AlreadyAssigned=($ids -contains [string]$selected.skuId)})
    }
    Section 'PLAN'
    Assert-GraphContext -TenantId $ExpectedTenantId -Account $approvedAccount
    Write-Host "Tenant ID  : $ExpectedTenantId"
    Write-Host "Account    : $approvedAccount"
    foreach ($target in $targets) {
        $action=if ($target.AlreadyAssigned) { 'Already assigned; skip' } elseif (-not $target.UsageLocation -and -not $UsageLocation) { 'Missing UsageLocation; skip' } else { "Assign $($selected.skuPartNumber)" }
        $location=if (-not $target.AlreadyAssigned -and -not $target.UsageLocation -and $UsageLocation) { "; set UsageLocation=$UsageLocation" } else { '' }
        Write-Host "$($target.UPN) -> $action$location"
    }
    if (-not (Confirm-Type 'This will assign licenses to the listed users.' 'ASSIGN')) { WARN 'Cancelled'; return }
    $results=New-Object System.Collections.ArrayList
    foreach ($target in $targets) {
        if ($target.AlreadyAssigned -or (-not $target.UsageLocation -and -not $UsageLocation)) {
            [void]$results.Add([pscustomobject]@{UPN=$target.UPN;Result='Skipped';Detail='Already assigned or missing UsageLocation'})
            continue
        }
        $requestReturned=$false
        try {
            Assert-GraphContext -TenantId $ExpectedTenantId -Account $approvedAccount
            if (-not $target.UsageLocation) {
                $locationBody=@{usageLocation=$UsageLocation} | ConvertTo-Json -Compress
                Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/v1.0/users/$($target.Id)" -Body $locationBody -ContentType 'application/json' -ErrorAction Stop | Out-Null
            }
            Assert-GraphContext -TenantId $ExpectedTenantId -Account $approvedAccount
            $body=@{addLicenses=@(@{skuId=$selected.skuId;disabledPlans=@()});removeLicenses=@()}
            Graph-Post "https://graph.microsoft.com/v1.0/users/$($target.Id)/assignLicense" $body | Out-Null
            $requestReturned=$true
            Start-Sleep -Milliseconds 300
            $after=Get-GraphUserByUPN -UPN $target.UPN
            if ($after.id -ne $target.Id) { throw 'Target identity changed; final state is unverified.' }
            $present=@(Get-AssignedLicenseIds -User $after) -contains [string]$selected.skuId
            if (-not $target.UsageLocation -and $after.usageLocation -ne $UsageLocation) { $present=$false }
            if (-not $present) { throw 'License or approved UsageLocation did not verify. Review current state before retrying.' }
            OK "$($target.UPN) assignment verified"
            [void]$results.Add([pscustomobject]@{UPN=$target.UPN;Result='Verified';Detail=$selected.skuPartNumber})
        } catch {
            $state=if ($requestReturned) { 'FailedValidation' } else { 'Failed' }
            WARN "$($target.UPN): request or verification failed; final state is unverified. $($_.Exception.Message)"
            [void]$results.Add([pscustomobject]@{UPN=$target.UPN;Result=$state;Detail=$_.Exception.Message})
        }
    }
    Section 'SUMMARY'
    Write-Host "Verified   : $(@($results | Where-Object { $_.Result -eq 'Verified' }).Count)"
    Write-Host "Skipped    : $(@($results | Where-Object { $_.Result -eq 'Skipped' }).Count)"
    Write-Host "Failed     : $(@($results | Where-Object { $_.Result -eq 'Failed' }).Count)"
    Write-Host "Unverified : $(@($results | Where-Object { $_.Result -eq 'FailedValidation' }).Count)"
    Offer-ExportCsv -Rows @($results) -DefaultName ("license-assignment-{0}.csv" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    if (@($results | Where-Object { $_.Result -in @('Failed','FailedValidation') }).Count) {
        WARN 'STATUS: Incomplete - failed or unverified results remain.'
        INFO 'NEXT STEP: Review current licenses and UsageLocation before retrying.'
    } elseif (@($results | Where-Object { $_.Result -eq 'Verified' }).Count) {
        OK 'STATUS: Completed - requested assignments verified; review skipped users.'
        INFO 'NEXT STEP: Record per-user results.'
    } else {
        INFO 'STATUS: No changes - users were skipped.'
        INFO 'NEXT STEP: Review existing assignments and missing UsageLocation.'
    }
} catch {
    FAIL 'STATUS: Stopped - task not completed'
    Write-Host $_.Exception.Message
} finally {
    Pause-End
}
