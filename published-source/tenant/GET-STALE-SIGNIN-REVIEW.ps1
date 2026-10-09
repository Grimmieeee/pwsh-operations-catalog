#Requires -Version 5.1

<#
GET-STALE-SIGNIN-REVIEW.ps1

STALE LOGIN STATUS

OBJECTIVE
Read-only tenant-wide review of enabled Entra member accounts.

Shows:
- Accounts whose recorded Entra sign-in is older than the selected threshold
- Accounts where Entra sign-in activity is not available

Default threshold: 90 days

Guests and disabled accounts are excluded.
Missing sign-in data is NOT classified as inactive.
No changes are made.
No export is created.
#>

param(
    [ValidateRange(1,3650)]
    [int]$Days = 90
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function Write-OK   { param($m) Write-Host "[OK]   $m" -ForegroundColor Green }
function Write-Info { param($m) Write-Host "[INFO] $m" }
function Write-Warn { param($m) Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "[FAIL] $m" -ForegroundColor Red }

function Pause-End {
    Write-FieldKitFooter
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
    param($ErrorRecord)

    $message = $ErrorRecord.Exception.Message

    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$ErrorRecord
    }

    return (($message -replace "\s+", " ").Trim())
}

function Ensure-GraphAuthenticationModule {
    $moduleName="Microsoft.Graph.Authentication"
    $module=Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$moduleName is required but is not installed. Install with: Install-Module $moduleName -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop

    if (-not (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue)) {
        throw "$moduleName loaded, but Connect-MgGraph is unavailable."
    }
}

function Test-RequiredScopes {
    param(
        [object]$Context,
        [string[]]$RequiredScopes
    )

    if (-not $Context) {
        return $false
    }

    $granted = @($Context.Scopes)

    foreach ($scope in $RequiredScopes) {
        if ($granted -notcontains $scope) {
            return $false
        }
    }

    return $true
}

function Test-GraphRead {
    try {
        $null = Invoke-MgGraphRequest `
            -Method GET `
            -Uri "https://graph.microsoft.com/v1.0/organization?`$select=displayName,verifiedDomains" `
            -ErrorAction Stop

        return $true
    }
    catch {
        return $false
    }
}

function Connect-GraphAuto {
    param([string[]]$Scopes)

    Ensure-GraphAuthenticationModule

    $context = Get-MgContext -ErrorAction SilentlyContinue

    if (
        $context -and
        (Test-RequiredScopes -Context $context -RequiredScopes $Scopes) -and
        (Test-GraphRead)
    ) {
        Write-OK "Graph session reused"
        return
    }

    Write-Host "Graph: Connecting..."

    $command = Get-Command Connect-MgGraph -ErrorAction Stop
    $parameters = @{
        Scopes       = $Scopes
        ContextScope = "Process"
        ErrorAction  = "Stop"
    }

    if ($command.Parameters.ContainsKey("NoWelcome")) {
        $parameters["NoWelcome"] = $true
    }

    Connect-MgGraph @parameters | Out-Null

    $context = Get-MgContext -ErrorAction Stop

    if (
        -not (Test-RequiredScopes -Context $context -RequiredScopes $Scopes) -or
        -not (Test-GraphRead)
    ) {
        throw "Graph connected, but the required access could not be validated."
    }

    Write-OK "Graph connected"
}

function Invoke-GraphGet {
    param([string]$Uri)

    return Invoke-MgGraphRequest `
        -Method GET `
        -Uri $Uri `
        -ErrorAction Stop
}

function Get-AllEnabledMemberUsers {
    $users = @()
    $uri = (
        "https://graph.microsoft.com/v1.0/users?" +
        "`$select=displayName,userPrincipalName,accountEnabled,userType,signInActivity" +
        "&`$top=999"
    )

    while ($uri) {
        $page = Invoke-GraphGet -Uri $uri

        if ($null -eq $page -or $null -eq $page.value) {
            throw "Graph user enumeration returned an incomplete response."
        }

        $users += @(
            $page.value |
            Where-Object {
                $_.accountEnabled -eq $true -and
                $_.userType -ne "Guest"
            }
        )

        $uri = $page.'@odata.nextLink'
    }

    return $users
}

function Offer-VerifiedCsv {
    param(
        [array]$Rows,
        [string]$DefaultName
    )

    if (-not $Rows -or $Rows.Count -eq 0) { return }
    if ((Read-Host "Export review to CSV [Y/N]").Trim() -notmatch '^(?i)y$') { return }

    $path=(Read-Host "CSV output path [blank for .\$DefaultName]").Trim().Trim('"')
    if (-not $path) { $path=Join-Path (Get-Location).Path $DefaultName }

    $Rows | Export-Csv -LiteralPath $path -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
    $check=@(Import-Csv -LiteralPath $path -ErrorAction Stop)

    if ($check.Count -ne $Rows.Count) {
        throw "CSV verification failed. Expected $($Rows.Count) row(s); read back $($check.Count)."
    }

    Write-OK "Exported and verified: $path"
}

try {
    Write-Host "TENANT STALE SIGN-IN REVIEW"
    Write-Host "READ-ONLY. ENABLED ENTRA MEMBER ACCOUNTS."
    Write-Host ""

    Write-Host ("Threshold : {0} days" -f $Days)
    Write-Host ("Date      : {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm"))

    Write-Host ""
    Connect-GraphAuto `
        -Scopes @(
            "User.Read.All",
            "Directory.Read.All",
            "AuditLog.Read.All"
        )

    Write-Host ""
    Write-Info "Reviewing enabled Entra member accounts..."

    $users = @(Get-AllEnabledMemberUsers)

    $stale = @()
    $activityUnavailable = @()
    $current = @()
    $now = Get-Date

    foreach ($user in $users) {
        $upn = [string]$user.userPrincipalName
        $name = [string]$user.displayName

        if (
            $user.signInActivity -and
            $user.signInActivity.lastSignInDateTime
        ) {
            try {
                $last = [datetime]$user.signInActivity.lastSignInDateTime
                $age = [int]($now - $last).TotalDays

                $row = [PSCustomObject]@{
                    Name       = $name
                    UPN        = $upn
                    LastSignIn = $last.ToLocalTime()
                    Days       = $age
                }

                if ($age -ge $Days) {
                    $stale += $row
                }
                else {
                    $current += $row
                }
            }
            catch {
                $activityUnavailable += [PSCustomObject]@{
                    Name   = $name
                    UPN    = $upn
                    Reason = "Sign-in timestamp could not be parsed"
                }
            }
        }
        else {
            $activityUnavailable += [PSCustomObject]@{
                Name   = $name
                UPN    = $upn
                Reason = "No Entra sign-in activity returned"
            }
        }
    }

    Write-Host ""
    Write-Host "STALE ENABLED USERS ($($stale.Count))"

    if ($stale.Count -eq 0) {
        Write-Host "  none"
    }
    else {
        foreach ($row in ($stale | Sort-Object Days -Descending)) {
            Write-Host (
                "  - {0} <{1}> | {2} | {3} days" -f
                $row.Name,
                $row.UPN,
                $row.LastSignIn.ToString("yyyy-MM-dd"),
                $row.Days
            )
        }
    }

    Write-Host ""
    Write-Host "ACTIVITY NOT AVAILABLE ($($activityUnavailable.Count))"

    if ($activityUnavailable.Count -eq 0) {
        Write-Host "  none"
    }
    else {
        foreach ($row in ($activityUnavailable | Sort-Object Name,UPN)) {
            Write-Host (
                "  - {0} <{1}> | {2}" -f
                $row.Name,
                $row.UPN,
                $row.Reason
            )
        }
    }

    Write-Host ""
    Write-Host "SUMMARY"
    Write-Host ("Enabled member accounts reviewed : {0}" -f $users.Count)
    Write-Host ("Stale {0}+ days               : {1}" -f $Days, $stale.Count)
    Write-Host ("Activity not available          : {0}" -f $activityUnavailable.Count)
    Write-Host ("Within threshold                 : {0}" -f $current.Count)

    $exportRows=@()
    $exportRows += @($stale | ForEach-Object {
        [pscustomobject]@{
            Name=$_.Name; UPN=$_.UPN; Status="Stale"; LastSignIn=$_.LastSignIn
            Days=$_.Days; Reason=""
        }
    })
    $exportRows += @($activityUnavailable | ForEach-Object {
        [pscustomobject]@{
            Name=$_.Name; UPN=$_.UPN; Status="ActivityUnavailable"; LastSignIn=""
            Days=""; Reason=$_.Reason
        }
    })
    $exportRows += @($current | ForEach-Object {
        [pscustomobject]@{
            Name=$_.Name; UPN=$_.UPN; Status="WithinThreshold"; LastSignIn=$_.LastSignIn
            Days=$_.Days; Reason=""
        }
    })

    Offer-VerifiedCsv -Rows $exportRows -DefaultName ("tenant-stale-signin-review-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

    Write-Host ""
    Write-Host "STANDARD NOTE"
    Write-Host "Read-only Entra sign-in review. Missing sign-in data was not classified as inactive."

    Write-Host ""
    Write-OK "Complete. No changes made"
}
catch {
    Write-Host ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Pause-End
}