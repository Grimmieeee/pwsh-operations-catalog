<#PSScriptInfo
.VERSION 0.1.0
.GUID 211fbbce-a71e-fb21-017f-200324222a65
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
tenant-mfa-security-audit-clean.ps1

Read-only MFA security audit.

Purpose:
- Reviews tenant MFA registration details
- Classifies phishing-resistant methods vs standard MFA
- Flags users with no MFA, weak-only MFA, or no phishing-resistant method
- Supports optional Conditional Access policy coverage review
- Consolidates old mfa-coverage.ps1 and mfa-gap-report.ps1

Notes:
- Authenticator push/number matching and TOTP are still AiTM-bypassable.
- FIDO2 and Windows Hello for Business are treated as phishing-resistant.
#>

param(
    [switch]$IncludeConditionalAccess
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

function Write-FieldKitFooter {
    Write-Host ""
    Write-Host "F I E L D  //  K I T"
    Write-Host ""
}

function OK {
    param([string]$m)
    Write-Host '[OK] ' -ForegroundColor Green -NoNewline
    Write-Host $m
}
function INFO {
    param([string]$m)
    Write-Host '[INFO] ' -NoNewline
    Write-Host $m
}
function WARN {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[WARN] ' -ForegroundColor Yellow -NoNewline
    Write-Host $m
}
function RISK {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[RISK] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}
function FAIL {
    param([string]$m)
    $script:FKHasIssue = $true
    Write-Host '[FAIL] ' -ForegroundColor Red -NoNewline
    Write-Host $m
}

function Pause-End {
    Close-FKConsole
}

function Now {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

function Section {
    param([string]$Title)
    Write-FKHeading -Title $Title
}

function Confirm-Yes {
    param([string]$Prompt)

    $a = Read-Host "$Prompt [Y/N]"
    return ($a.Trim().ToUpper() -eq "Y")
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

function Offer-ExportJson {
    param(
        [object]$Object,
        [string]$DefaultName
    )

    if (-not $Object) { return }

    if (-not (Confirm-Yes "Export snapshot to JSON")) { return }

    $path = Read-Host "JSON output path [blank for .\$DefaultName]"

    if (-not $path) {
        $path = Join-Path (Get-Location).Path $DefaultName
    }

    try {
        $Object | ConvertTo-Json -Depth 20 | Out-File -FilePath $path -Encoding UTF8
        OK "Exported: $path"
    }
    catch {
        WARN "JSON export failed"
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

function Ensure-Module {
    param(
        [string]$Name,
        [string]$Command
    )

    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        return
    }

    $module = Get-Module -ListAvailable -Name $Name |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if (-not $module) {
        throw "$Name is required but is not installed. Install it first with: Install-Module $Name -Scope CurrentUser"
    }

    Import-Module $module.Path -Force -ErrorAction Stop

    if (-not (Get-Command $Command -ErrorAction SilentlyContinue)) {
        throw "$Name loaded, but $Command is unavailable."
    }
}

function Ensure-Graph {
    param([string[]]$Scopes)

    try {
        Ensure-Module `
            -Name "Microsoft.Graph.Authentication" `
            -Command "Connect-MgGraph"

        $ctx = Get-MgContext -ErrorAction SilentlyContinue
        $missingScopes = @()

        if ($ctx) {
            foreach ($scope in $Scopes) {
                if (@($ctx.Scopes) -notcontains $scope) {
                    $missingScopes += $scope
                }
            }
        }

        if (-not $ctx -or $missingScopes.Count -gt 0) {
            $command = Get-Command Connect-MgGraph -ErrorAction Stop
            $params = @{
                Scopes      = $Scopes
                ErrorAction = "Stop"
            }

            if ($command.Parameters.ContainsKey("ContextScope")) {
                $params["ContextScope"] = "Process"
            }

            if ($command.Parameters.ContainsKey("NoWelcome")) {
                $params["NoWelcome"] = $true
            }

            Connect-MgGraph @params | Out-Null
        }

        $ctx = Get-MgContext -ErrorAction Stop

        if (-not $ctx) {
            throw "Microsoft Graph did not return an authentication context."
        }

        OK "Graph ready"
        return $true
    }
    catch {
        FAIL ("Graph unavailable: {0}" -f $_.Exception.Message)
        return $false
    }
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
    $uri = "https://graph.microsoft.com/v1.0/users/$encoded?`$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,signInActivity,lastPasswordChangeDateTime"
    $user = Graph-Get $uri

    if ($user -and $user.id) { return $user }

    $escaped = Escape-OData $UPN
    $filter = Encode-Value "userPrincipalName eq '$escaped' or mail eq '$escaped'"
    $uri = "https://graph.microsoft.com/v1.0/users?`$filter=$filter&`$select=id,displayName,userPrincipalName,mail,accountEnabled,userType,onPremisesSyncEnabled,assignedLicenses,signInActivity,lastPasswordChangeDateTime"
    $fallback = Graph-Get $uri

    if ($fallback -and $fallback.value -and @($fallback.value).Count -gt 0) {
        return @($fallback.value)[0]
    }

    return $null
}

function Is-RiskyScope {
    param([string]$Scope)

    if (-not $Scope) { return $false }

    $patterns = @(
        "Mail.",
        "Mailbox",
        "Files.Read",
        "Files.ReadWrite",
        "Sites.",
        "Directory.",
        "Group.",
        "User.ReadWrite",
        "User.Read.All",
        "Calendars.ReadWrite",
        "Contacts.ReadWrite",
        "offline_access",
        "full_access_as_user",
        "Application.ReadWrite",
        "RoleManagement.ReadWrite"
    )

    foreach ($p in $patterns) {
        if ($Scope -like "*$p*") { return $true }
    }

    return $false
}

function Classify-Methods {
    param([string[]]$Methods)

    $joined = (($Methods | ForEach-Object { "$_" }) -join "; ").ToLower()
    $resistant = $false
    $standard = $false
    $weak = $false

    if ($joined -match "fido|passkey|windowshello|windows hello|softwareoath") {
        if ($joined -match "fido|passkey|windowshello|windows hello") {
            $resistant = $true
        }
    }

    if ($joined -match "microsoft authenticator|authenticator|softwareoath|totp") {
        $standard = $true
    }

    if ($joined -match "sms|voice|email") {
        $weak = $true
    }

    if ($resistant) { return "Phishing-resistant" }
    if ($standard -and $weak) { return "Standard + weak" }
    if ($standard) { return "Standard MFA" }
    if ($weak) { return "Weak-only MFA" }

    return "No MFA registered"
}

try {
    try { $host.UI.RawUI.WindowTitle = "Tenant MFA Security Audit" } catch {}
Write-FKStart -Title 'TENANT MFA SECURITY AUDIT' -Objective 'Shows where MFA coverage or registered methods may leave gaps.' -Mode ''
    Write-Host ''
    Write-Host ""

    if (-not $IncludeConditionalAccess) {
        $IncludeConditionalAccess = Confirm-Yes "Include basic Conditional Access MFA policy review"
    }

    Section "CONNECT"

    $scopes = @("User.Read.All","Directory.Read.All","Reports.Read.All","UserAuthenticationMethod.Read.All")
    if ($IncludeConditionalAccess) { $scopes += "Policy.Read.ConditionalAccess" }

    if (-not (Ensure-Graph -Scopes $scopes)) {
        Pause-End
        exit 1
    }

    Section "MFA REGISTRATION"

    $details = @(Get-GraphPages -Uri "https://graph.microsoft.com/beta/reports/authenticationMethods/userRegistrationDetails")

    if ($details.Count -eq 0) {
        WARN "No MFA registration details returned. Check permissions/licensing."
    }

    $rows = New-Object System.Collections.ArrayList

    foreach ($d in $details) {
        $methods = @($d.methodsRegistered)
        $class = Classify-Methods -Methods $methods
        $finding = "OK"

        if ($d.isMfaRegistered -ne $true -or $d.isMfaCapable -ne $true -or $class -eq "No MFA registered") {
            $finding = "MFA gap"
        }
        elseif ($class -eq "Weak-only MFA") {
            $finding = "Weak-only MFA"
        }
        elseif ($class -ne "Phishing-resistant") {
            $finding = "No phishing-resistant MFA"
        }

        [void]$rows.Add([pscustomobject]@{
            UPN=$d.userPrincipalName
            DisplayName=$d.userDisplayName
            IsAdmin=$d.isAdmin
            IsMfaRegistered=$d.isMfaRegistered
            IsMfaCapable=$d.isMfaCapable
            IsPasswordlessCapable=$d.isPasswordlessCapable
            MethodClass=$class
            Methods=($methods -join "; ")
            SystemPreferred=(@($d.systemPreferredAuthenticationMethods) -join "; ")
            UserPreferred=[string]$d.userPreferredMethodForSecondaryAuthentication
            Finding=$finding
        })
    }

    $capRows = New-Object System.Collections.ArrayList

    if ($IncludeConditionalAccess) {
        Section "CONDITIONAL ACCESS REVIEW"

        $policies = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies")

        foreach ($p in $policies) {
            $grant = ""
            try { $grant = @($p.grantControls.builtInControls) -join "; " } catch {}

            $session = ""
            try { $session = @($p.sessionControls.PSObject.Properties.Name) -join "; " } catch {}

            $finding = "Review"
            if ($p.state -eq "disabled") { $finding = "Disabled policy" }
            elseif ($p.state -eq "enabledForReportingButNotEnforced") { $finding = "Report-only policy" }
            elseif ($grant -match "mfa") { $finding = "MFA grant control present" }

            [void]$capRows.Add([pscustomobject]@{
                PolicyName=(Clean-Name $p.displayName)
                State=$p.state
                GrantControls=$grant
                SessionControls=$session
                Finding=$finding
            })
        }

        $mfaPolicies = @($capRows | Where-Object { $_.Finding -eq "MFA grant control present" })
        Write-Host "Policies reviewed: $($capRows.Count)"
        Write-Host "MFA policies     : $($mfaPolicies.Count)"
    }


    $mfaGapCount = @($rows | Where-Object { $_.Finding -eq 'MFA gap' }).Count
    $weakOnlyCount = @($rows | Where-Object { $_.Finding -eq 'Weak-only MFA' }).Count
    $noPhishingResistantCount = @($rows | Where-Object { $_.Finding -eq 'No phishing-resistant MFA' }).Count
    $phishingResistantCount = @($rows | Where-Object { $_.MethodClass -eq 'Phishing-resistant' }).Count
    $reviewRows = @($rows | Where-Object { $_.Finding -ne "OK" })

    $verdict = "MFA POSTURE LOOKS CLEAN FROM RETURNED DATA"
    $recommendation = "No MFA gaps were flagged by this review"

    if ($mfaGapCount -gt 0) {
        $verdict = "MFA GAPS FOUND"
        $recommendation = "Prioritize users with no MFA or not MFA capable"
    }
    elseif ($weakOnlyCount -gt 0) {
        $verdict = "WEAK-ONLY MFA FOUND"
        $recommendation = "Move weak-only users toward stronger MFA methods"
    }
    elseif ($noPhishingResistantCount -gt 0) {
        $verdict = "NO PHISHING-RESISTANT MFA FOR SOME USERS"
        $recommendation = "Review stronger MFA options for privileged and high-risk users"
    }

    Write-Host ""

    Write-Host ""
    Write-Host ""
    Write-Host "MFA SECURITY SUMMARY"
    Write-Host "Verdict                      : $verdict"
    Write-Host "Recommendation               : $recommendation"
    Write-Host "Users checked                : $($rows.Count)"
    Write-Host "MFA gaps                     : $mfaGapCount"
    Write-Host "Weak-only MFA                : $weakOnlyCount"
    Write-Host "No phishing-resistant MFA    : $noPhishingResistantCount"
    Write-Host "Phishing-resistant present   : $phishingResistantCount"
    Write-Host ""
    Write-Host "Review users:"

    if ($reviewRows.Count -eq 0) {
        Write-Host "- None"
    } else {
        foreach ($r in ($reviewRows | Select-Object -First 20)) {
            $preferred = if ($r.UserPreferred) { $r.UserPreferred } elseif ($r.SystemPreferred) { $r.SystemPreferred } else { 'not returned' }
            Write-Host "- $($r.UPN) | $($r.Finding) | $($r.Methods) | Preferred: $preferred"
        }
        if ($reviewRows.Count -gt 20) {
            Write-Host "- plus $($reviewRows.Count - 20) more"
        }
    }

    Write-Host ""
    Write-Host ""

    foreach ($r in ($rows | Where-Object { $_.Finding -ne "OK" } | Select-Object -First 75)) {
        $preferred = if ($r.UserPreferred) { $r.UserPreferred } elseif ($r.SystemPreferred) { $r.SystemPreferred } else { 'not returned' }
        WARN "$($r.UPN) | $($r.Finding) | $($r.Methods) | Preferred: $preferred"
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "tenant-mfa-security-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete. No changes made."
    Pause-End
}
catch {
    Write-Host ""
    FAIL ("Unhandled script error: {0}" -f $_.Exception.Message)
    Pause-End
}
