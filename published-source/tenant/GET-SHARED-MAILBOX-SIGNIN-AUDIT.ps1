<#PSScriptInfo
.VERSION 0.1.0
.GUID d2b47970-1324-34b9-5fa2-e0b9acecc92c
.AUTHOR FIELD // KIT
.DESCRIPTION Console alignment candidate; operator validation pending.
#>
<#
shared-mailbox-signin-audit-clean.ps1

Read-only shared mailbox sign-in audit.

Purpose:
- Lists shared mailboxes
- Checks recent sign-ins for shared mailbox accounts through Graph
- Flags successful sign-ins to shared mailbox accounts
- Useful because shared mailboxes should generally not be directly signed into
#>

param(
    [int]$LookbackHours = 72
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

function Ensure-Graph {
    param([string[]]$Scopes)

    Import-Module Microsoft.Graph.Authentication -ErrorAction SilentlyContinue | Out-Null

    if (-not (Get-Command Connect-MgGraph -ErrorAction SilentlyContinue)) {
        FAIL "Microsoft.Graph.Authentication module not available"
        Write-Host "Install with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
        return $false
    }

    $ctx = Get-MgContext -ErrorAction SilentlyContinue

    if (-not $ctx) {
        WARN "Graph not connected"

        if (-not (Confirm-Yes "Connect to Graph now")) {
            return $false
        }

        try {
            Connect-MgGraph -Scopes $Scopes -ContextScope Process -NoWelcome -ErrorAction Stop | Out-Null
        }
        catch {
            try {
                Connect-MgGraph -Scopes $Scopes -ContextScope Process -ErrorAction Stop | Out-Null
            }
            catch {
                FAIL "Graph connection failed"
                return $false
            }
        }
    }

    $ctx = Get-MgContext -ErrorAction SilentlyContinue

    if ($ctx) {
        OK "Graph connected"
        return $true
    }

    FAIL "Graph unavailable"
    return $false
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

function Ensure-EXO {
    Import-Module ExchangeOnlineManagement -ErrorAction SilentlyContinue | Out-Null

    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
        FAIL "ExchangeOnlineManagement module not available"
        Write-Host "Install with: Install-Module ExchangeOnlineManagement -Scope CurrentUser"
        return $false
    }

    $connected = $false

    if (Get-Command Get-ConnectionInformation -ErrorAction SilentlyContinue) {
        $conn = Get-ConnectionInformation -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($conn) { $connected = $true }
    }

    if (-not $connected) {
        WARN "Exchange Online not connected"

        if (-not (Confirm-Yes "Connect to Exchange Online now")) {
            WARN "Exchange skipped"
            return $false
        }

        try {
            Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop | Out-Null
        }
        catch {
            try {
                Connect-ExchangeOnline -ErrorAction Stop | Out-Null
            }
            catch {
                FAIL "Exchange connection failed"
                return $false
            }
        }
    }

    OK "Exchange connected"
    return $true
}

try {
    try { $host.UI.RawUI.WindowTitle = "Shared Mailbox Sign-in Audit" } catch {}

    Clear-Host
    Write-FKStart -Title 'SHARED MAILBOX SIGN-IN AUDIT' -Objective 'Shows whether shared mailboxes are being signed into directly.' -Mode ''
    Write-Host ''
    Write-Host ""

    $inputHours = Read-Host "Lookback hours [default $LookbackHours]"
    if ($inputHours) { try { $LookbackHours = [int]$inputHours } catch {} }

    Section "CONNECT"

    if (-not (Ensure-EXO)) {
        Pause-End
        exit 1
    }

    if (-not (Ensure-Graph -Scopes @("AuditLog.Read.All","User.Read.All","Directory.Read.All"))) {
        Pause-End
        exit 1
    }

    Section "MAILBOXES"

    $shared = @(Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize Unlimited -ErrorAction SilentlyContinue)
    Write-Host "Shared mailboxes: $($shared.Count)"

    $rows = New-Object System.Collections.ArrayList
    $since = (Get-Date).AddHours(-1 * $LookbackHours).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    foreach ($mbx in $shared) {
        $upn = "$($mbx.UserPrincipalName)"
        if (-not $upn) { $upn = "$($mbx.PrimarySmtpAddress)" }

        INFO "Checking: $upn"

        $escaped = Escape-OData $upn
        $filter = Encode-Value "userPrincipalName eq '$escaped' and createdDateTime ge $since"
        $uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?`$top=20&`$filter=$filter"
        $logs = @(Get-GraphPages -Uri $uri)

        foreach ($log in $logs) {
            $success = ($log.status.errorCode -eq 0)

            [void]$rows.Add([pscustomobject]@{
                Mailbox=$mbx.PrimarySmtpAddress
                Time=$log.createdDateTime
                Result=$(if ($success) { "Success" } else { "Failed" })
                IP=$log.ipAddress
                Country=$log.location.countryOrRegion
                App=$log.appDisplayName
                ClientApp=$log.clientAppUsed
                Finding=$(if ($success) { "Shared mailbox successful sign-in" } else { "Shared mailbox failed sign-in" })
            })
        }
    }

    Section "SUMMARY"
    Write-Host "Shared mailboxes checked : $($shared.Count)"
    Write-Host "Sign-in rows             : $($rows.Count)"
    Write-Host "Successful sign-ins      : $(@($rows | Where-Object { $_.Result -eq 'Success' }).Count)"
    Write-Host ""

    foreach ($r in ($rows | Sort-Object Time -Descending | Select-Object -First 75)) {
        if ($r.Result -eq "Success") {
            RISK "$($r.Time) | $($r.Mailbox) | $($r.IP) | $($r.Country) | $($r.App)"
        } else {
            WARN "$($r.Time) | $($r.Mailbox) | Failed | $($r.IP) | $($r.Country)"
        }
    }

    Offer-ExportCsv -Rows @($rows) -DefaultName "shared-mailbox-signin-audit-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"

    OK "Complete"
    Pause-End
}
catch {
    Write-Host ""
    FAIL "Unhandled script error"
    Write-Host $_.Exception.Message
    Pause-End
}
