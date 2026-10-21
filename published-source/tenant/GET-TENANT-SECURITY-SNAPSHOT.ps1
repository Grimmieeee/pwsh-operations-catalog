# .VERSION 1.0.1
<#
GET-TENANT-SECURITY-SNAPSHOT.ps1

Read-only tenant security overview.

Purpose:
- Gives a fast tenant-level view before deeper focused audits
- Summarizes users and stale enabled accounts
- Summarizes Conditional Access policy state
- Summarizes active Entra admin roles
- Counts delegated OAuth grants

Read-only. No changes are made.
#>

param(
    [int]$StaleDays = 90
)

$ErrorActionPreference = "Stop"

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}

# Embedded into standalone report scripts by tools/reporting/build.ps1.
$script:FKReportLines = New-Object 'Collections.Generic.List[string]'
$script:FKReportWarnings = @()
$script:FKReportStartedUtc = [DateTime]::UtcNow.ToString('o')

function Write-FKReportLine {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Object,
        [object]$Separator=' ',[switch]$NoNewline,
        [ConsoleColor]$ForegroundColor,[ConsoleColor]$BackgroundColor
    )
    $line=($Object | ForEach-Object {[string]$_}) -join [string]$Separator
    $script:FKReportLines.Add($line)
    Write-Host @PSBoundParameters
}

function ConvertTo-FKDesktopReport {
    param([string]$Title,[string[]]$Lines,[string]$StartedUtc,[string]$ScopeNote)
    $encode={param($Text) [Net.WebUtility]::HtmlEncode([string]$Text)}
    $blocks=New-Object 'Collections.Generic.List[string]'
    $section=New-Object 'Collections.Generic.List[string]'
    foreach($line in @($Lines)) {
        if($line -match '^\s*[A-Z][A-Z /+&:()-]{2,}\s*$' -and $line.Trim().Length -lt 90) {
            if($section.Count) {$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>');$section.Clear()}
            $blocks.Add('<h2>'+(& $encode $line.Trim())+'</h2>')
        } else {$section.Add([string]$line)}
    }
    if($section.Count){$blocks.Add('<pre>'+(& $encode ($section.ToArray() -join "`n"))+'</pre>')}
    $safeTitle=& $encode $Title
    return @"
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"><title>$safeTitle</title>
<style>body{font:16px/1.55 system-ui,sans-serif;background:#f5f7f7;color:#172524;margin:0}main{max-width:1000px;margin:32px auto;padding:32px;background:white;border-top:4px solid #168779}header{border-bottom:1px solid #d1ddda;padding-bottom:20px}small{letter-spacing:.12em;color:#52716b}h1{font-size:28px;margin:12px 0}h2{font-size:15px;letter-spacing:.1em;color:#166b60;margin:28px 0 10px;border-bottom:1px solid #d1ddda;padding-bottom:8px}pre{font:14px/1.6 ui-monospace,Consolas,monospace;white-space:pre-wrap;overflow-wrap:anywhere;margin:0}aside{background:#eef5f2;padding:12px 16px;margin:20px 0}footer{font-size:12px;color:#52716b;margin-top:32px}@media print{body{background:white}main{margin:0;padding:0;max-width:none}h2{break-after:avoid}pre{font-size:11px}}</style></head>
<body><main><header><small>F I E L D // K I T</small><h1>$safeTitle</h1><p>Collection started (UTC): $(& $encode $StartedUtc)</p></header><aside>$(& $encode $ScopeNote) Findings, unavailable checks, and displayed limits below are preserved from this run. Absence of a finding does not establish complete coverage.</aside>$($blocks.ToArray() -join "`n")<footer>Read-only report. No remote content or executable scripts. Review findings in context before taking action.</footer></main></body></html>
"@
}

function Save-FKDesktopReport {
    param([string]$Folder,[string]$Title,[string]$Content)
    if([string]::IsNullOrWhiteSpace($Folder) -or -not [IO.Directory]::Exists($Folder)){throw 'Report folder does not exist.'}
    $stem=($Title -replace '[^a-zA-Z0-9._-]','-').Trim('-')
    if(-not $stem){$stem='field-kit-report'}
    $stem=$stem.Substring(0,[Math]::Min(80,$stem.Length))
    $name=$stem+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff')+'-'+[guid]::NewGuid().ToString('N').Substring(0,8)+'.html'
    $path=Join-Path $Folder $name
    $bytes=(New-Object Text.UTF8Encoding($false)).GetBytes($Content)
    $stream=New-Object IO.FileStream($path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {$stream.Write($bytes,0,$bytes.Length)}finally{$stream.Dispose()}
    $actual=[IO.File]::ReadAllBytes($path)
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        if([Convert]::ToBase64String($sha.ComputeHash($bytes)) -cne [Convert]::ToBase64String($sha.ComputeHash($actual))){throw 'Report readback did not match the collected content.'}
    }finally{$sha.Dispose()}
    return $path
}

function Offer-FKDesktopReport {
    param([string]$Title,[string]$ScopeNote='Scope matches the console output; only displayed rows are included.',[string]$DesktopFolder=[Environment]::GetFolderPath([Environment+SpecialFolder]::DesktopDirectory))
    if(-not $script:FKReportLines.Count){return}
    try {
        if((Read-Host 'Save report to Desktop? [Y/N]').Trim() -notmatch '^(?i)y$'){return}
        $folder=$DesktopFolder
        $reportLines=@($script:FKReportLines.ToArray())
        if(@($script:FKReportWarnings).Count){$reportLines+=@('','SERVICE WARNINGS');$reportLines+=@($script:FKReportWarnings|ForEach-Object {[string]$_})}
        $content=ConvertTo-FKDesktopReport -Title $Title -Lines $reportLines -StartedUtc $script:FKReportStartedUtc -ScopeNote $ScopeNote
        try {$saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content}
        catch {
            Write-Host '[WARN] Desktop report could not be saved. Choose another existing folder or cancel.' -ForegroundColor Yellow
            $folder=(Read-Host 'Report folder (ENTER cancels)').Trim().Trim('"')
            if(-not $folder){return}
            $saved=Save-FKDesktopReport -Folder $folder -Title $Title -Content $content
        }
        Write-Host ('[OK] Report saved and readback checked: '+$saved)
    }catch{Write-Host ('[WARN] Report export failed: '+$_.Exception.Message) -ForegroundColor Yellow}
}

function Write-OK   { param($Message) Write-FKReportLine "[OK]   $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-FKReportLine "[INFO] $Message" }
function Write-Warn { param($Message) Write-FKReportLine "[WARN] $Message" -ForegroundColor Yellow }
function Write-Fail { param($Message) Write-FKReportLine "[FAIL] $Message" -ForegroundColor Red }

function Pause-End {
    Write-Host ''
    Write-Host 'SESSION COMPLETE'
    Write-FKReportLine ""
    Read-Host 'Press Enter to close session.' | Out-Null
}

function Get-ShortError {
    param($ErrorRecord)

    $Message = $ErrorRecord.Exception.Message
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = [string]$ErrorRecord
    }

    return (($Message -replace "\s+", " ").Trim())
}

function Ensure-Graph {
    param([string[]]$Scopes)

    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.Authentication)) {
        throw "Microsoft.Graph.Authentication is not installed. Install it with: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser"
    }

    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop | Out-Null

    $Context = Get-MgContext -ErrorAction SilentlyContinue
    $NeedsConnect = $true

    if ($Context) {
        $NeedsConnect = $false
        foreach ($Scope in $Scopes) {
            if (@($Context.Scopes) -notcontains $Scope) {
                $NeedsConnect = $true
                break
            }
        }
    }

    if (-not $NeedsConnect) {
        Write-OK "Graph session reused"
        return
    }

    if ($Context) {
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    }

    $Parameters = @{
        Scopes       = $Scopes
        ContextScope = 'Process'
        ErrorAction  = 'Stop'
    }

    $Command = Get-Command Connect-MgGraph -ErrorAction Stop
    if ($Command.Parameters.ContainsKey('NoWelcome')) {
        $Parameters.NoWelcome = $true
    }

    Write-Info "Connecting to Microsoft Graph..."
    Connect-MgGraph @Parameters | Out-Null

    if (-not (Get-MgContext -ErrorAction SilentlyContinue)) {
        throw "Microsoft Graph connection could not be validated."
    }

    Write-OK "Graph connected"
}

function Invoke-GraphGet {
    param([string]$Uri)

    return Invoke-MgGraphRequest `
        -Method GET `
        -Uri $Uri `
        -OutputType PSObject `
        -ErrorAction Stop
}

function Get-GraphPages {
    param([string]$Uri)

    $Items = New-Object System.Collections.ArrayList

    while ($Uri) {
        $Page = Invoke-GraphGet -Uri $Uri

        foreach ($Item in @($Page.value)) {
            [void]$Items.Add($Item)
        }

        $Uri = [string]$Page.'@odata.nextLink'
    }

    return @($Items)
}

function Write-Section {
    param([string]$Title)

    Write-FKReportLine ""
    Write-FKReportLine $Title -ForegroundColor Cyan
    Write-FKReportLine ("-" * $Title.Length) -ForegroundColor Cyan
}

function Write-Unavailable {
    param(
        [string]$Label,
        $ErrorRecord
    )

    Write-FKReportLine ("{0}: Not available" -f $Label)
    Write-Warn (Get-ShortError $ErrorRecord)
}

try {
    try { $Host.UI.RawUI.WindowTitle = "Tenant Security Snapshot" } catch {}

    Clear-Host
    Write-FKReportLine 'Get Tenant Security'
    Write-FKReportLine 'Gives a fast tenant security overview before you open the deeper focused audits.'
    Write-FKReportLine "READ-ONLY. NO CHANGES MADE."
    Write-FKReportLine "Fast overview only. Use focused audits for deeper review."
    Write-FKReportLine ""

    $Scopes = @(
        "Organization.Read.All",
        "User.Read.All",
        "AuditLog.Read.All",
        "Directory.Read.All",
        "RoleManagement.Read.Directory",
        "Policy.Read.ConditionalAccess",
        "DelegatedPermissionGrant.Read.All"
    )

    Ensure-Graph -Scopes $Scopes

    Write-Section "ORGANIZATION"
    try {
        $Organizations = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/organization?`$select=id,displayName,verifiedDomains")
        $Organization = $Organizations | Select-Object -First 1

        if ($Organization) {
            Write-FKReportLine "Name    : $($Organization.displayName)"

            $DefaultDomain = @($Organization.verifiedDomains | Where-Object { $_.isDefault -eq $true } | Select-Object -First 1)
            if ($DefaultDomain.Count -gt 0) {
                Write-FKReportLine "Domain  : $($DefaultDomain[0].name)"
            }
        }
        else {
            Write-FKReportLine "Organization: Not available"
        }
    }
    catch {
        Write-Unavailable -Label "Organization" -ErrorRecord $_
    }

    Write-Section "USERS"
    try {
        $UsersUri = "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,accountEnabled,userType,signInActivity&`$top=999"
        $Users = @(Get-GraphPages -Uri $UsersUri)

        $Enabled = @($Users | Where-Object { $_.accountEnabled -eq $true })
        $Disabled = @($Users | Where-Object { $_.accountEnabled -eq $false })
        $Guests = @($Users | Where-Object { $_.userType -eq "Guest" })
        $Stale = New-Object System.Collections.ArrayList

        foreach ($User in $Enabled) {
            $Last = $null
            try {
                if ($User.signInActivity.lastSignInDateTime) {
                    $Last = [datetime]$User.signInActivity.lastSignInDateTime
                }
            }
            catch {
                $Last = $null
            }

            if ($Last -and ((Get-Date) - $Last.ToLocalTime()).TotalDays -gt $StaleDays) {
                [void]$Stale.Add($User)
            }
        }

        Write-FKReportLine "Total users          : $($Users.Count)"
        Write-FKReportLine "Enabled users        : $($Enabled.Count)"
        Write-FKReportLine "Disabled users       : $($Disabled.Count)"
        Write-FKReportLine "Guest users          : $($Guests.Count)"
        Write-FKReportLine "Stale enabled > $StaleDays d: $($Stale.Count)"

        if ($Stale.Count -gt 0) {
            Write-FKReportLine ""
            Write-FKReportLine "Oldest stale enabled accounts (first 15):"
            $Stale |
                Sort-Object { [datetime]$_.signInActivity.lastSignInDateTime } |
                Select-Object -First 15 |
                ForEach-Object {
                    Write-FKReportLine ("- {0} | {1}" -f $_.userPrincipalName, $_.signInActivity.lastSignInDateTime)
                }
        }
    }
    catch {
        Write-Unavailable -Label "Users" -ErrorRecord $_
    }

    Write-Section "CONDITIONAL ACCESS"
    try {
        $Policies = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?`$select=id,displayName,state")
        Write-FKReportLine "Policies    : $($Policies.Count)"
        Write-FKReportLine "Enabled     : $(@($Policies | Where-Object { $_.state -eq 'enabled' }).Count)"
        Write-FKReportLine "Report-only : $(@($Policies | Where-Object { $_.state -eq 'enabledForReportingButNotEnforced' }).Count)"
        Write-FKReportLine "Disabled    : $(@($Policies | Where-Object { $_.state -eq 'disabled' }).Count)"
    }
    catch {
        Write-Unavailable -Label "Conditional Access" -ErrorRecord $_
    }

    Write-Section "ACTIVE ADMIN ROLES"
    try {
        $Roles = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/directoryRoles?`$select=id,displayName")
        $AssignmentCount = 0

        foreach ($Role in ($Roles | Sort-Object displayName)) {
            try {
                $Members = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/directoryRoles/$($Role.id)/members?`$select=id")
                $AssignmentCount += $Members.Count
                Write-FKReportLine ("- {0}: {1}" -f $Role.displayName, $Members.Count)
            }
            catch {
                Write-Warn ("{0}: member count unavailable" -f $Role.displayName)
            }
        }

        Write-FKReportLine ""
        Write-FKReportLine "Active assignments: $AssignmentCount"
    }
    catch {
        Write-Unavailable -Label "Admin roles" -ErrorRecord $_
    }

    Write-Section "DELEGATED OAUTH CONSENT"
    try {
        $Grants = @(Get-GraphPages -Uri "https://graph.microsoft.com/v1.0/oauth2PermissionGrants?`$select=id,clientId,resourceId,consentType,scope")
        Write-FKReportLine "Delegated grants: $($Grants.Count)"
        Write-FKReportLine "All-principals grants: $(@($Grants | Where-Object { $_.consentType -eq 'AllPrincipals' }).Count)"
    }
    catch {
        Write-Unavailable -Label "OAuth consent" -ErrorRecord $_
    }

    Write-FKReportLine ""
    Write-OK "Snapshot complete"
}
catch {
    Write-FKReportLine ""
    Write-Fail (Get-ShortError $_)
}
finally {
    Offer-FKDesktopReport -Title 'GET-TENANT-SECURITY-SNAPSHOT'

    Pause-End
}
