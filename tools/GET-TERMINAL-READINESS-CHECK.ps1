<#
.VERSION 1.0.0
#>
#Requires -Version 5.1

<#
KIT PREFLIGHT

OBJECTIVE
Confirm the local Jumpbox package and PowerShell environment are ready for use.

REVIEWS
- PowerShell version and execution policy
- Current Jumpbox root and core folder structure
- Code-signing certificate availability
- Active production script signatures
- Required cloud modules
- Optional hybrid modules
- Existing Graph / Exchange sessions
- Core anchor files

DEFAULT ROOT
C:\Field-Kit

SAFETY
Read-only.
No tenant changes.
No export.
#>

param(
    [string]$KitRoot = "C:\Field-Kit",
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"

$script:OkCount = 0
$script:WarnCount = 0
$script:FailCount = 0

function OK($m) {
    Write-Host "[OK]   $m" -ForegroundColor Green
    $script:OkCount++
}

function INFO($m) {
    Write-Host "[INFO] $m"
}

function WARN($m) {
    Write-Host "[WARN] $m" -ForegroundColor Yellow
    $script:WarnCount++
}

function FAIL($m) {
    Write-Host "[FAIL] $m" -ForegroundColor Red
    $script:FailCount++
}

function Pause-End {
    if (-not $NoPause) {
        Write-Host ""
        Read-Host "Press Enter to EXIT" | Out-Null
    }
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)

    Write-Host ""
    Write-Host (" {0} " -f $Title) `
        -ForegroundColor White `
        -BackgroundColor DarkGray
}

function Get-RelativePath {
    param(
        [string]$FullName,
        [string]$Root
    )

    $rootClean = $Root.TrimEnd("\")

    if (
        $FullName.StartsWith(
            $rootClean,
            [System.StringComparison]::OrdinalIgnoreCase
        )
    ) {
        return $FullName.Substring($rootClean.Length).TrimStart("\")
    }

    return $FullName
}

try {
    Write-Host "JUMPBOX PREFLIGHT"
    Write-Host "READ-ONLY LOCAL READINESS CHECK"
    Write-Host ""

    $typedRoot = Read-Host "Kit root [$KitRoot]"

    if (-not [string]::IsNullOrWhiteSpace($typedRoot)) {
        $KitRoot = $typedRoot.Trim().Trim('"').Trim("'")
    }

    $ExpectedFolders = @(
        "Archive",
        "Documentation",
        "Endpoint",
        "Groups",
        "Identity",
        "IR",
        "Licensing",
        "Lifecycle",
        "Mailbox",
        "PWSH",
        "Tenant",
        "Testing",
        "Utility"
    )

    $ExpectedFiles = @(
        "README.md",
        "Documentation\POWERSHELL-TOOLKIT-STANDARD.md",
        "Documentation\JUMPBOX-ORGANIZATION.md",
        "PWSH\jumpbox-fieldkit-profile.ps1",
        "Utility\set-execution.ps1",
        "Groups\group-members-lookup.ps1",
        "Identity\get-user-snapshot.ps1",
        "Licensing\account-status-license-audit.ps1",
        "Mailbox\get-user-mailbox-snapshot.ps1",
        "Tenant\get-tenant-snapshot.ps1",
        "Tenant\quarterly-cleanup-review.ps1",
        "Lifecycle\multi-user-offboarding-audit.ps1",
        "IR\BEC\01-ir-user-discovery-v1.3.ps1",
        "IR\BEC\02-ir-revoke-active-sessions-v1.0.ps1",
        "IR\BEC\03-ir-account-response-v1.0.ps1",
        "IR\BEC\04-ir-account-recovery-v1.0.ps1"
    )

    Section "POWERSHELL"

    $psVer = $PSVersionTable.PSVersion

    if ($psVer.Major -ge 7) {
        OK "PowerShell $($psVer.ToString())"
    }
    elseif ($psVer.Major -ge 5) {
        WARN "PowerShell $($psVer.ToString()) - PowerShell 7 recommended"
    }
    else {
        FAIL "PowerShell $($psVer.ToString()) - unsupported"
    }

    try {
        $currentUserPolicy = Get-ExecutionPolicy `
            -Scope CurrentUser `
            -ErrorAction Stop

        $effectivePolicy = Get-ExecutionPolicy -ErrorAction Stop

        INFO "CurrentUser policy : $currentUserPolicy"
        INFO "Effective policy   : $effectivePolicy"

        if ($effectivePolicy -in @("RemoteSigned","Bypass","Unrestricted","AllSigned")) {
            OK "Execution policy permits script use"
        }
        else {
            WARN "Execution policy may block script use"
        }
    }
    catch {
        WARN "Execution policy could not be read"
    }

    Section "KIT ROOT"

    if (Test-Path -LiteralPath $KitRoot -PathType Container) {
        $KitRoot = (Get-Item -LiteralPath $KitRoot -ErrorAction Stop).FullName.TrimEnd("\")
        OK "Kit root found - $KitRoot"
    }
    else {
        FAIL "Kit root not found - $KitRoot"
    }

    Section "FOLDER STRUCTURE"

    if (Test-Path -LiteralPath $KitRoot -PathType Container) {
        $actualFolders = @(
            Get-ChildItem `
                -LiteralPath $KitRoot `
                -Directory `
                -ErrorAction Stop |
            Select-Object -ExpandProperty Name
        )

        foreach ($folder in $ExpectedFolders) {
            if ($folder -in $actualFolders) {
                OK "Folder present - $folder"
            }
            else {
                FAIL "Folder missing - $folder"
            }
        }

        $extraFolders = @(
            $actualFolders |
            Where-Object { $_ -notin $ExpectedFolders }
        )

        if ($extraFolders.Count -gt 0) {
            INFO "Additional root folders - $($extraFolders -join ', ')"
        }
        else {
            INFO "Additional root folders - none"
        }
    }

    Section "CODE SIGNING CERTIFICATE"

    try {
        $certs = @(
            Get-ChildItem `
                Cert:\CurrentUser\My `
                -CodeSigningCert `
                -ErrorAction Stop |
            Where-Object { $_.NotAfter -gt (Get-Date) } |
            Sort-Object NotAfter -Descending
        )

        if ($certs.Count -eq 0) {
            WARN "Code-signing certificate not found"
        }
        else {
            $cert = $certs | Select-Object -First 1
            $daysLeft = [int](($cert.NotAfter - (Get-Date)).TotalDays)

            OK "Code-signing certificate available - $daysLeft day(s) remaining"
            INFO "Signer : $($cert.Subject)"
        }
    }
    catch {
        WARN "Code-signing certificate store could not be reviewed"
    }

    Section "ACTIVE SCRIPT SIGNATURES"

    if (Test-Path -LiteralPath $KitRoot -PathType Container) {
        try {
            $ps1s = @(
                Get-ChildItem `
                    -LiteralPath $KitRoot `
                    -Filter "*.ps1" `
                    -File `
                    -Recurse `
                    -ErrorAction Stop |
                Where-Object {
                    $_.FullName -notmatch '[\\/]+Archive[\\/]' -and
                    $_.FullName -notmatch '[\\/]+Testing[\\/]'
                }
            )

            if ($ps1s.Count -eq 0) {
                WARN "No active PowerShell scripts found"
            }
            else {
                $invalid = @()
                $signatureGaps = @()

                foreach ($file in $ps1s) {
                    try {
                        $sig = Get-AuthenticodeSignature `
                            -LiteralPath $file.FullName `
                            -ErrorAction Stop

                        if ($sig.Status -ne "Valid") {
                            $invalid += [PSCustomObject]@{
                                File = Get-RelativePath -FullName $file.FullName -Root $KitRoot
                                Status = [string]$sig.Status
                            }
                        }
                    }
                    catch {
                        $signatureGaps += [PSCustomObject]@{
                            File = Get-RelativePath -FullName $file.FullName -Root $KitRoot
                            Error = $_.Exception.Message
                        }
                    }
                }

                if ($signatureGaps.Count -gt 0) {
                    FAIL "Signature review incomplete for $($signatureGaps.Count) active script(s)"
                }

                if ($invalid.Count -eq 0 -and $signatureGaps.Count -eq 0) {
                    OK "All $($ps1s.Count) active script signature(s) valid"
                }
                elseif ($invalid.Count -gt 0) {
                    FAIL "$($invalid.Count) active script(s) are unsigned or invalid"

                    foreach ($item in $invalid) {
                        Write-Host (
                            "  - {0} | {1}" -f
                            $item.Status,
                            $item.File
                        )
                    }
                }
            }
        }
        catch {
            FAIL "Active script signature inventory failed"
            INFO $_.Exception.Message
        }
    }

    Section "MODULES"

    foreach ($module in @(
        "Microsoft.Graph.Authentication",
        "ExchangeOnlineManagement"
    )) {
        $installed = @(
            Get-Module `
                -ListAvailable `
                -Name $module `
                -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1
        )

        if ($installed.Count -gt 0) {
            OK "$module $($installed[0].Version)"
        }
        else {
            WARN "$module - not installed"
        }
    }

    foreach ($module in @(
        "ActiveDirectory",
        "ADSync"
    )) {
        $installed = @(
            Get-Module `
                -ListAvailable `
                -Name $module `
                -ErrorAction SilentlyContinue |
            Sort-Object Version -Descending |
            Select-Object -First 1
        )

        if ($installed.Count -gt 0) {
            INFO "$module $($installed[0].Version)"
        }
        else {
            INFO "$module - optional / not installed"
        }
    }

    if (Get-Command Install-Module -ErrorAction SilentlyContinue) {
        OK "Install-Module available"
    }
    else {
        WARN "Install-Module unavailable"
    }

    Section "ACTIVE SESSIONS"

    if (Get-Command Get-MgContext -ErrorAction SilentlyContinue) {
        try {
            $mgContext = Get-MgContext -ErrorAction Stop

            if ($mgContext) {
                INFO "Graph session - Connected as $($mgContext.Account)"
            }
            else {
                INFO "Graph session - Not connected"
            }
        }
        catch {
            INFO "Graph session - Status unavailable"
        }
    }
    else {
        INFO "Graph session - Module not loaded"
    }

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        try {
            $exoConnection = Get-ConnectionInformation -ErrorAction Stop |
                Where-Object {
                    $_.State -eq "Connected" -or
                    $_.ConnectionStatus -eq "Connected"
                } |
                Select-Object -First 1

            if ($exoConnection) {
                $org = if ($exoConnection.Organization) {
                    $exoConnection.Organization
                }
                elseif ($exoConnection.DelegatedOrganization) {
                    $exoConnection.DelegatedOrganization
                }
                else {
                    "connected tenant"
                }

                INFO "Exchange session - Connected to $org"
            }
            else {
                INFO "Exchange session - Not connected"
            }
        }
        catch {
            INFO "Exchange session - Status unavailable"
        }
    }
    else {
        INFO "Exchange session - Module not loaded"
    }

    Section "CORE FILES"

    if (Test-Path -LiteralPath $KitRoot -PathType Container) {
        foreach ($file in $ExpectedFiles) {
            $fullPath = Join-Path $KitRoot $file

            if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                OK "$file"
            }
            else {
                FAIL "$file - not found"
            }
        }
    }

    Section "SUMMARY"

    $result = if ($script:FailCount -gt 0) {
        "FAIL"
    }
    elseif ($script:WarnCount -gt 0) {
        "WARN"
    }
    else {
        "READY"
    }

    Write-Host ("Result   : {0}" -f $result)
    Write-Host ("OK       : {0}" -f $script:OkCount)
    Write-Host ("Warnings : {0}" -f $script:WarnCount)
    Write-Host ("Failures : {0}" -f $script:FailCount)
    Write-Host ("Root     : {0}" -f $KitRoot)
    Write-Host ("Operator : {0}\{1}" -f $env:USERDOMAIN, $env:USERNAME)
    Write-Host ("Checked  : {0}" -f (Now))

    Write-Host ""
    Write-Host "TICKET SUMMARY"
    Write-Host "--------------------------------------"
    Write-Host ("Jumpbox preflight : {0}" -f $result)
    Write-Host ("Root              : {0}" -f $KitRoot)
    Write-Host ("OK                : {0}" -f $script:OkCount)
    Write-Host ("Warnings          : {0}" -f $script:WarnCount)
    Write-Host ("Failures          : {0}" -f $script:FailCount)
    Write-Host ("Checked           : {0}" -f (Now))
}
catch {
    Write-Host ""
    FAIL "Unhandled preflight error"
    INFO $_.Exception.Message
}
finally {
    Pause-End
}
