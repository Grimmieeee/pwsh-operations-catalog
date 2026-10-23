# .VERSION 1.0.1

# OBJECTIVE: Review a GitHub security-log export for unfamiliar access and activity.
#Requires -Version 5.1
<#
.SYNOPSIS
Guided GitHub security export review: JSON, JSON.GZ or ZIP, plus reviewed history.
.DESCRIPTION
Read-only triage, not a compromise detector. No API token, uploads, reports,
account changes, or integration with git-handoff. Default: concise, actionable exceptions with the time, target and next step.
Routine event types are hidden, not trusted. Console output shows actionable exceptions only.
-Details and -All remain compatible; -All affects -PassThru records only. -SetBaseline explicitly records reviewed
event fingerprints. Full reviews with no flags also save a checkpoint automatically.
Flagged, incomplete, filtered and PassThru reviews never auto-acknowledge events.
Output includes selected app/repository labels. Keep it private. No raw event dump.
Standalone sign-ins, token refreshes and unclassified events do not trigger alerts.
Rules are selective; no findings is not a full security clearance. Dates use local time.
Event definitions: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/security-log-events
Use the original log to confirm actors, devices, targets and before/after values.
.EXAMPLE
& .\git-security.ps1
.EXAMPLE
& .\git-security.ps1 -Path "$HOME\Downloads\security-log.json"
.EXAMPLE
& .\git-security.ps1 -Path "$HOME\Downloads\security-log.json" -Details -All
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)] [string] $Path,
    [switch] $Open,
    [switch] $Details,
    [switch] $All,
    [Alias('Action')] [string[]] $ActionFilter,
    [switch] $PassThru,
    [switch] $Latest,
    [switch] $SetBaseline,
    [ValidatePattern('^[A-Za-z0-9-]+$')] [string] $Account,
    [string] $DownloadFolder = (Join-Path $HOME 'Downloads'),
    [string] $BaselinePath,
    [string[]] $CommandArgs = @()
)
Write-Host 'Review GitHub Security'
Write-Host 'Review a GitHub security-log export for unfamiliar access and activity.'


Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# Command words received from the existing profile's git dispatcher.
for ($i = 0; $i -lt $CommandArgs.Count; $i++) {
    switch -Regex ($CommandArgs[$i]) {
        '^(details|-Details)$' { $Details = $true; continue }
        '^(all|-All)$' { $All = $true; continue }
        '^(latest|-Latest)$' { $Latest = $true; continue }
        '^(open|-Open)$' { $Open = $true; continue }
        '^(baseline|-SetBaseline)$' { $SetBaseline = $true; continue }
        '^-Path$' {
            $i++
            if ($i -ge $CommandArgs.Count -or $Path) { throw 'Supply one export path.' }
            $Path = $CommandArgs[$i]
            continue
        }
        default {
            if ($CommandArgs[$i].StartsWith('-') -or $Path) {
                throw 'Usage: git security [details|all|latest|open|baseline] [export-path]'
            }
            $Path = $CommandArgs[$i]
        }
    }
}
if (($Details -or $All) -and -not $Path -and -not $Open) { $Latest = $true }

if ([string]::IsNullOrWhiteSpace($BaselinePath)) {
    $localRoot = [Environment]::GetFolderPath('LocalApplicationData')
    if ([string]::IsNullOrWhiteSpace($localRoot)) { throw 'Specify -BaselinePath; no local application-data folder is available.' }
    $baselineName = if ($Account) { $Account.ToLowerInvariant() } else { 'default' }
    $BaselinePath = Join-Path $localRoot "FIELD-KIT/GitSecurity/$baselineName.reviewed.json"
}

function Read-LimitedText($Stream) {
    # Limit decompressed data to 50 MiB. No archive members are extracted to disk.
    $memory = New-Object System.IO.MemoryStream
    try {
        $buffer = New-Object byte[] 65536
        while (($count = $Stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if (($memory.Length + $count) -gt 52428800) { throw 'Export exceeds the 50 MiB decompressed limit.' }
            $memory.Write($buffer, 0, $count)
        }
        return ([Text.Encoding]::UTF8.GetString($memory.ToArray())).TrimStart([char]0xFEFF)
    } finally { $memory.Dispose() }
}

function Read-Export([string] $FilePath) {
    $file = $null; $compressed = $null; $archive = $null; $member = $null
    try {
        $file = [IO.File]::OpenRead((Resolve-Path -LiteralPath $FilePath).ProviderPath)
        $extension = [IO.Path]::GetExtension($FilePath).ToLowerInvariant()
        if ($extension -eq '.gz') {
            $compressed = New-Object IO.Compression.GZipStream($file, [IO.Compression.CompressionMode]::Decompress)
            $text = Read-LimitedText $compressed
        } elseif ($extension -eq '.zip') {
            Add-Type -AssemblyName System.IO.Compression
            $archive = New-Object IO.Compression.ZipArchive($file, [IO.Compression.ZipArchiveMode]::Read)
            $members = @($archive.Entries | Where-Object { $_.Name -match '\.json$' })
            if ($members.Count -ne 1) { throw 'ZIP must contain exactly one JSON file. Select an individual JSON/GZ export instead.' }
            $member = $members[0].Open()
            $text = Read-LimitedText $member
        } elseif ($extension -eq '.json') {
            $text = Read-LimitedText $file
        } else { throw 'Supported files: .json, .json.gz, or .zip containing one JSON file.' }
    } finally {
        if ($member) { $member.Dispose() }
        if ($archive) { $archive.Dispose() }
        if ($compressed) { $compressed.Dispose() }
        if ($file) { $file.Dispose() }
    }
    if ([string]::IsNullOrWhiteSpace($text)) { throw 'Empty export; no review performed.' }
    try { $records = @(ConvertFrom-Json -InputObject $text -ErrorAction Stop) }
    catch {
        try {
            $records = @($text -split '\r?\n' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                ForEach-Object { ConvertFrom-Json -InputObject $_ -ErrorAction Stop })
        } catch { throw 'Invalid JSON export; no review performed.' }
    }
    if ($records.Count -eq 0 -or ($records.Count -eq 1 -and $null -eq $records[0])) { throw 'No events; not an all-clear.' }
    foreach ($record in $records) {
        $name = Get-Field $record 'action'
        if ($name -isnot [string] -or $name -cnotmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') {
            throw 'An event has no valid action. Unsupported/incomplete export; no review performed.'
        }
    }
    return $records
}

function Get-CanonicalValue($Value) {
    if ($null -eq $Value) { return 'null' }
    if ($Value -is [string]) { return (ConvertTo-Json -InputObject $Value -Compress) }
    if ($Value -is [datetime]) { return (ConvertTo-Json -InputObject $Value.ToUniversalTime().ToString('o') -Compress) }
    if ($Value -is [System.Collections.IDictionary]) {
        $pairs = @(foreach ($key in ($Value.Keys | Sort-Object)) {
            (ConvertTo-Json -InputObject ([string]$key) -Compress) + ':' + (Get-CanonicalValue $Value[$key])
        })
        return '{' + ($pairs -join ',') + '}'
    }
    if ($Value -is [pscustomobject]) {
        $pairs = @(foreach ($property in ($Value.PSObject.Properties | Sort-Object Name)) {
            (ConvertTo-Json -InputObject $property.Name -Compress) + ':' + (Get-CanonicalValue $property.Value)
        })
        return '{' + ($pairs -join ',') + '}'
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $items = @(foreach ($item in $Value) { Get-CanonicalValue $item })
        return '[' + ($items -join ',') + ']'
    }
    return (ConvertTo-Json -InputObject $Value -Compress)
}

function Get-Fingerprint($Record) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes((Get-CanonicalValue $Record))
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    } finally { $sha.Dispose() }
}

function Find-LatestExport {
    if (-not $Account) { throw 'Use -Account for automatic download selection, or specify an export path.' }
    $pattern = '^export-' + [regex]::Escape($Account) + '-\d+(?:\s*\(\d+\))?\.(?:json(?:\.gz)?|zip)$'
    $files = @(Get-ChildItem -LiteralPath $DownloadFolder -File | Where-Object { $_.Name -match $pattern } |
        Sort-Object LastWriteTimeUtc -Descending)
    if ($files.Count -eq 0) { throw 'No matching GitHub export found in Downloads. Supply its full path.' }
    if ($files.Count -gt 1 -and $files[0].LastWriteTimeUtc -eq $files[1].LastWriteTimeUtc) {
        throw 'More than one export has the newest timestamp. Supply the exact path.'
    }
    return $files[0].FullName
}

function Get-Field($Record, [string] $Name) {
    if ($null -eq $Record) { return $null }
    $property = $Record.PSObject.Properties[$Name]
    if ($null -ne $property) { return $property.Value }
    return $null
}

function Get-DisplayText($Value) {
    if ($null -eq $Value) { return '(not provided)' }
    # Do not emit terminal controls from log values. This is NOT a secret scrubber.
    $text = ([string] $Value) -replace '[\p{Cc}\p{Cf}]', ' '
    if ($text.Length -gt 180) { return $text.Substring(0, 180) + '...' }
    return $text
}

function Get-EventTime($Record) {
    foreach ($name in @('created_at', '@timestamp')) {
        $value = Get-Field $Record $name
        if ($null -eq $value -or [string]::IsNullOrWhiteSpace([string] $value)) { continue }
        try {
            if ([string] $value -match '^\d+$') {
                # GitHub exports numeric timestamps as epoch milliseconds.
                return ([datetimeoffset] '1970-01-01T00:00:00Z').AddMilliseconds([double] $value)
            }
            return [datetimeoffset]::Parse([string] $value, [cultureinfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::AssumeUniversal)
        } catch { continue }
    }
    return $null
}

function Get-Triage([string] $Action) {
    switch -Regex ($Action) {
        '^oauth_access\.(regenerate|destroy|revoke)$|^oauth_authorization\.destroy$|^personal_access_token\.(destroy|access_revoked|credential_revoked|request_denied|request_cancelled)$|^integration_installation\.(suspend|destroy|repositories_removed)$' {
            return @(3, 'CONTEXT', 'Token lifecycle or access removal/update. Hidden from the default review queue, not verified safe. Inspect if unexpected or linked to another alert.')
        }
        '^user\.(login|logout|audit_log_export|two_factor_challenge_success|two_factor_requested|device_verification_success|show_private_contributions_count)$|^profile_picture\.update$|^project(_view)?\.create$|^billing\.budget_create$|^repo\.(create|archived|pages_create)$|^environment\.create$' {
            return @(3, 'CONTEXT', 'Context event without a specialized warning signal. Hidden by default, not baseline-approved. Use -All to inspect.')
        }
        '^repo\.access$' {
            return @(1, 'CHECK FIRST', 'Repository visibility changed. Confirm old/new visibility. This is not a visit or access attempt.')
        }
        '^user\.(failed_login|two_factor_challenge_failure|forgot_password|two_factor_requested)$' {
            return @(2, 'REVIEW', 'Attempt/request, not proof of entry. Check repetition and nearby successful logins or changes; ignore unsolicited prompts.')
        }
        '^personal_access_token\.request_(created|denied|cancelled)$' {
            return @(2, 'REVIEW', 'Token access request or its disposition. A request alone does not establish access; inspect status, requester and grants.')
        }
        '^user\.(new_device_used|sign_in_from_unrecognized_device(_and_location)?)$' {
            return @(2, 'LOW SIGNAL', 'Device label alone is low priority. Correlate with grants, recovery/settings changes or owner denial before recommending containment.')
        }
        '^user\.(login|two_factor_challenge_success)$' {
            return @(2, 'REVIEW', 'Authentication event. Match time/device/location to your activity. Your username as actor does not prove it was you.')
        }
        '^user\.(logout|audit_log_export)$' {
            return @(3, 'CONTEXT', 'Supporting timeline event. Confirm it fits your activity; this is not a security clearance.')
        }
        '^(two_factor_authentication|passkey|security_key|trusted_device|user_email)\.|^user\.(add_email|remove_email|change_password|reset_password|two_factor_recover|two_factor_recovery_codes_)' {
            return @(1, 'CHECK FIRST', 'Account authentication/recovery activity. Verify it was yours. Undo unauthorized changes and secure GitHub plus its recovery email.')
        }
        '^(public_key|git_signing_ssh_public_key|personal_access_token|oauth_access|oauth_authorization|integration_installation)\.' {
            return @(1, 'CHECK FIRST', 'Key/token/app activity. Inspect the exact operation, permissions and target. Revoke unfamiliar grants; replace credentials that may be exposed.')
        }
        '^(hook|protected_branch|repository_ruleset|repository_invitation|workflows|environment)\.|^repo\.(add_member|update_member|remove_member|temporary_access_granted|transfer|destroy|.*secret|.*workflow|.*actions|.*runner|.*disabled|pages_public)' {
            return @(1, 'CHECK FIRST', 'Repository access/automation/protection activity. Confirm authorization and actual before/after settings; remove unauthorized access and review commits/workflows.')
        }
        default {
            return @(2, 'REVIEW', 'No specialized rule. Read the event in GitHub and check its meaning in the event catalog. Unclassified does not mean safe.')
        }
    }
}

function Get-ReviewCategory([string] $Action, $Triage) {
    if ($Triage[1] -eq 'CONTEXT') { return 'Routine' }
    if ($Action -match '^user\.(new_device_used|sign_in_from_unrecognized_device(_and_location)?)$') { return 'Device' }
    if ($Action -match '^user\.(failed_login|two_factor_challenge_failure)$') { return 'AuthFailure' }
    if ($Action -match '^user\.(forgot_password|device_verification_requested)$|^personal_access_token\.request_created$') { return 'Request' }
    if ($Triage[1] -eq 'CHECK FIRST') { return 'Change' }
    return 'Unclassified'
}

if ($SetBaseline -and ([string]::IsNullOrWhiteSpace($Path) -or $Latest -or $ActionFilter -or $Details -or $All -or $PassThru -or $Open)) {
    throw 'Use -SetBaseline -Path <reviewed-export> alone (plus Account/BaselinePath if needed). Review the export first.'
}
if ($Latest -and $Path) { throw 'Specify -Latest or -Path, not both.' }
if ($Open -and ($Path -or $Latest)) { throw 'Use -Open alone to open the security log, or supply an export for review.' }
if ($Open -and -not $Path) {
    Write-Host 'Security log: https://github.com/settings/security-log' -ForegroundColor Cyan
    try { Start-Process 'https://github.com/settings/security-log' | Out-Null }
    catch { Write-Warning 'Could not launch the browser. Open the link above manually.' }
    return
}
if ($Latest) { $Path = Find-LatestExport }
elseif ([string]::IsNullOrWhiteSpace($Path)) {
    if ($PassThru) { throw 'Use -Path or -Latest with -PassThru.' }
	Write-Host ""
    Write-Host 'SECURITY // Export > JSON in GitHub, then return here.' -ForegroundColor Cyan
	Write-Host ""
    try { Start-Process 'https://github.com/settings/security-log' | Out-Null }
    catch { Write-Warning 'Open the URL above manually.' }
    [void](Read-Host 'Press Enter after downloading the newest export')
    $Path = Find-LatestExport
}
$events = @(Read-Export $Path)
if ($Account) {
    $accountMatch = @($events | Where-Object {
        (Get-Field $_ 'actor') -eq $Account -or (Get-Field $_ 'user') -eq $Account
    })
    if ($accountMatch.Count -eq 0) { throw 'No matching account identity found in this export. Check -Account and the selected file.' }
}

$reviewed = New-Object 'System.Collections.Generic.HashSet[string]'
$hasBaseline = Test-Path -LiteralPath $BaselinePath -PathType Leaf
if ($hasBaseline) {
    try {
        $baseline = Get-Content -LiteralPath $BaselinePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($baseline.schema -ne 1 -or [string]$baseline.account -ne [string]$Account -or $baseline.fingerprints -isnot [array]) { throw 'Mismatch' }
        foreach ($hash in $baseline.fingerprints) {
            if ($hash -isnot [string] -or $hash -cnotmatch '^[a-f0-9]{64}$') { throw 'Invalid fingerprint' }
            [void]$reviewed.Add($hash)
        }
    } catch { throw 'Reviewed-history file is invalid or belongs to a different account. No review/history update performed.' }
}

$fingerprints = @($events | ForEach-Object { Get-Fingerprint $_ })
function Save-ReviewedHistory {
    foreach ($hash in $fingerprints) { [void]$reviewed.Add($hash) }
    $destination = [IO.Path]::GetFullPath($BaselinePath)
    $parent = [IO.Path]::GetDirectoryName($destination)
    [void][IO.Directory]::CreateDirectory($parent)
    $temporary = Join-Path $parent ([IO.Path]::GetRandomFileName())
    try {
        $snapshot = [ordered]@{
            schema = 1; account = [string]$Account; updatedUtc = [datetime]::UtcNow.ToString('o')
            note = 'Acknowledged explicitly or automatically after no actionable rule matches. Not proof of identity or safety.'
            fingerprints = @($reviewed | Sort-Object)
        } | ConvertTo-Json -Depth 5
        [IO.File]::WriteAllText($temporary, $snapshot, (New-Object Text.UTF8Encoding($false)))
        if ([IO.File]::Exists($destination)) { [IO.File]::Replace($temporary, $destination, [NullString]::Value) }
        else { [IO.File]::Move($temporary, $destination) }
    } finally { if ([IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) } }
}
if ($SetBaseline) {
    Save-ReviewedHistory
    Write-Host "[OK] Reviewed-history checkpoint saved; future events remain unreviewed." -ForegroundColor Green
    return
}

$seen = New-Object 'System.Collections.Generic.HashSet[string]'
$number = 0
$rows = @(foreach ($event in $events) {
    $number++
    $fingerprint = $fingerprints[$number - 1]
    if (-not $seen.Add($fingerprint)) { continue }
    $action = Get-Field $event 'action'
    if ($action -isnot [string] -or $action -cnotmatch '^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$') {
        throw "Event $number has no valid action name. Unsupported/incomplete export; no review was completed."
    }
    $triage = Get-Triage $action
    $time = Get-EventTime $event
    $timeText = if ($null -ne $time) { $time.UtcDateTime.ToString('yyyy-MM-dd HH:mm:ss') } else { '(missing/invalid)' }
    $row = [ordered] @{
        Event = $number
        Priority = $triage[1]
        TimeUTC = $timeText
        Action = $action
        Category = Get-ReviewCategory $action $triage
        Reviewed = $reviewed.Contains($fingerprint)
        NextStep = $triage[2]
    }
    if ($Details) {
        $row.Actor = Get-DisplayText (Get-Field $event 'actor')
        $row.AffectedUser = Get-DisplayText (Get-Field $event 'user')
        $row.Repository = Get-DisplayText (Get-Field $event 'repo')
        $row.IP = Get-DisplayText (Get-Field $event 'actor_ip')
        $country = Get-Field $event 'actor_location.country_code'
        if ($null -eq $country) { $country = Get-Field (Get-Field $event 'actor_location') 'country_code' }
        $row.Country = Get-DisplayText $country
    }
    [pscustomobject] $row
})

# Keep all events. Priority sorts first, then newest known time; Event is the
# original 1-based position, useful when matching the private source export.
$orderedRows = @($rows | Sort-Object @{Expression = {
        switch ($_.Priority) { 'CHECK FIRST' { 1 } 'REVIEW' { 2 } default { 3 } }
    }; Ascending = $true},
    @{Expression = 'TimeUTC'; Descending = $true}, Event)
$scopedRows = @($orderedRows | Where-Object { -not $ActionFilter -or $_.Action -in $ActionFilter })
$newRows = @($scopedRows | Where-Object { -not $_.Reviewed })
function Has-EventValue($Value) {
    if ($null -eq $Value) { return $false }
    if ($Value -is [string]) { return $Value.Trim() -notin @('', '{}', '[]', 'null') }
    if ($Value -is [System.Collections.IDictionary]) { return $Value.Count -gt 0 }
    if ($Value -is [pscustomobject]) { return @($Value.PSObject.Properties).Count -gt 0 }
    if ($Value -is [System.Collections.IEnumerable]) { return @($Value).Count -gt 0 }
    return [bool]$Value
}

function Get-Finding($Record) {
    $action = [string](Get-Field $Record 'action')
    $level = 'VERIFY'; $what = ''; $next = ''
    switch -Regex ($action) {
        '^two_factor_authentication\.disabled$' {
            $level = 'ACTION'; $what = 'Two-factor authentication disabled'
            $next = 'Restore MFA if still disabled; secure your account if this was not you.'; break
        }
        '^integration_installation\.(create|unsuspend|repositories_added)$' {
            $what = switch ($action.Split('.')[-1]) {
                'create' { 'GitHub App installed' }
                'unsuspend' { 'GitHub App access reactivated' }
                default { 'GitHub App given access to more repositories' }
            }
            $next = 'Did you authorize this? If not, remove the app access.'; break
        }
        '^integration_installation\.version_updated$' {
            # An update alone is not evidence of expanded permissions.
            if (-not ((Has-EventValue (Get-Field $Record 'permissions_added')) -or
                      (Has-EventValue (Get-Field $Record 'permissions_upgraded')))) { return }
            $what = 'GitHub App permissions expanded'
            $next = 'Did you approve the expansion? If not, suspend the app.'; break
        }
        '^oauth_authorization\.(create|update)$' {
            $what = if ($action.EndsWith('.create')) { 'OAuth app authorized' } else { 'OAuth app authorization changed' }
            $next = 'Did you authorize this? If not, revoke the app grant.'; break
        }
        '^personal_access_token\.(create|access_granted)$' {
            $what = if ($action.EndsWith('.create')) { 'Personal access token created' } else { 'Personal access token granted access' }
            $next = 'Did you authorize this token? If not, revoke it.'; break
        }
        '^public_key\.create$' {
            $what = 'SSH access key added'; $next = 'Did you add this key? If not, remove it from SSH keys.'; break
        }
        '^two_factor_authentication\.(add_factor|remove_factor)$|^(passkey|security_key)\.(create|add|destroy|remove)$' {
            $what = 'Sign-in factor changed'; $next = 'Did you change your sign-in methods? If not, review factors and secure the account.'; break
        }
        '^user\.(two_factor_recovery_codes_downloaded|two_factor_recovery_codes_regenerated|two_factor_recovered|two_factor_recovery)$' {
            $what = 'Recovery codes downloaded, replaced or used'
            $next = 'Was this you? If not, secure the account and replace recovery codes.'; break
        }
        '^user\.(add_email|remove_email|change_password|reset_password)$|^user_email\.(add|create|remove|destroy|change_primary)$' {
            $what = 'Account password or recovery email changed'
            $next = 'Was this your change? If not, secure GitHub and your recovery email.'; break
        }
        '^repository_invitation\.create$|^repo\.(add_member|update_member|temporary_access_granted)$' {
            $what = if ($action -eq 'repository_invitation.create') { 'Repository collaborator invited' } else { 'Repository member access changed' }
            $next = 'Did you authorize this person? If not, remove their access or invitation.'; break
        }
        '^repo\.(access|transfer|destroy|pages_public)$' {
            $what = switch ($action) {
                'repo.access' { 'Repository visibility changed' }
                'repo.transfer' { 'Repository transferred' }
                'repo.destroy' { 'Repository deleted' }
                default { 'GitHub Pages made public' }
            }
            $next = 'Was this intentional? If not, restore the intended ownership, visibility or repository.'; break
        }
        '^repo\.set_default_workflow_permissions$' {
            if ([string](Get-Field $Record 'default_workflow_permissions_value') -ne 'write') { return }
            $what = 'Workflows granted default write access'
            $next = 'If write access is unnecessary, set workflow permissions back to read-only.'; break
        }
        '^repo\.set_workflow_permission_can_approve_pr$' {
            if ([string](Get-Field $Record 'workflow_permission_can_approve_pr_value') -notin @('true','1')) { return }
            $what = 'Workflows allowed to approve pull requests'
            $next = 'Disable workflow PR approval unless you intentionally need it.'; break
        }
        '^repository_ruleset\.(update|destroy)$' {
            if ($action -eq 'repository_ruleset.update' -and
                [string](Get-Field $Record 'ruleset_enforcement') -notin @('disabled','evaluate') -and
                -not (Has-EventValue (Get-Field $Record 'ruleset_rules_deleted'))) { return }
            $what = 'Repository rules removed or enforcement relaxed'
            $next = 'Was this intentional? If not, restore the required protections.'; break
        }
        '^protected_branch\.(destroy|update)$|^environment\.(remove_protection_rule|update_protection_rule)$' {
            $what = 'Repository or deployment protection changed'
            $next = 'Confirm the protection change was yours; restore removed requirements if unintended.'; break
        }
        '^hook\.(create|config_changed)$' {
            $what = 'Webhook added or changed'
            $next = 'Confirm the webhook destination is yours; disable it if unfamiliar.'; break
        }
        default { return }
    }
    # Selected labels only. Never print raw event objects, token values or IDs.
    $labels = New-Object 'System.Collections.Generic.List[string]'
    foreach ($field in @('oauth_application_name', 'name', 'user_programmatic_access_name', 'repo', 'invitee', 'ruleset_name')) {
        $value = Get-Field $Record $field
        if ($value -is [string] -and -not [string]::IsNullOrWhiteSpace($value) -and $value -notmatch '^\d+$') {
            $label = Get-DisplayText $value
            if (-not $labels.Contains($label)) { $labels.Add($label) }
        }
    }
    $target = $labels -join ' / '
    if (-not $target) { $target = 'target not named in export' }
    $time = Get-EventTime $Record
    $when = if ($null -ne $time) { $time.ToLocalTime().ToString('yyyy-MM-dd HH:mm zzz') } else { 'time unavailable' }
    [pscustomobject]@{ Level=$level; When=$when; What=$what; Target=$target; Next=$next; Action=$action }
}

$findings = @(foreach ($row in $newRows) {
    Get-Finding $events[$row.Event - 1]
})
if ($PassThru) {
    if ($All) { $scopedRows } else { $findings }
    return
}
if (-not $hasBaseline -and $findings.Count -gt 0) {
    Write-Host '[!!] No review checkpoint saved; findings may include older events.' -ForegroundColor Yellow
}
if ($findings.Count -eq 0 -and @($newRows | Where-Object TimeUTC -eq '(missing/invalid)').Count -gt 0) {
    Write-Host '[!!] REVIEW INCOMPLETE // Unreadable event times; download a fresh export.' -ForegroundColor Yellow
} elseif ($findings.Count -eq 0) {
    $checkpointSaved = $false
    if (-not $ActionFilter) {
        try { Save-ReviewedHistory; $checkpointSaved = $true }
        catch { Write-Host '[!!] Checkpoint could not be saved; this review was not recorded.' -ForegroundColor Yellow }
    }
	Write-Host ""
    Write-Host '[ALL CLEAR] No new flags for access, permissions, recovery, or security protections.' -ForegroundColor Green
	Write-Host ""
    if ($checkpointSaved) { Write-Host 'Review complete; checkpoint updated.' -ForegroundColor Cyan }
	Write-Host ""
} else {
    foreach ($finding in ($findings | Sort-Object When -Descending)) {
        $color = if ($finding.Level -eq 'ACTION') { 'Red' } else { 'Yellow' }
        $tag = if ($finding.Level -eq 'ACTION') { '[XX]' } else { '[!!]' }
        Write-Host "$tag $($finding.Level) // $($finding.When) | $($finding.What): $($finding.Target). $($finding.Next)" -ForegroundColor $color
    }
}
