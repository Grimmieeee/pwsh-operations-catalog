#Requires -Version 5.1
<#
.SYNOPSIS
Run three exact read-only candidates in one authenticated session.
.DESCRIPTION
Local JSON report only; no tenant changes, transcript or per-tool CSV export.
PASS is the operator's assessment of expected results, not an automatic VERIFIED stamp.
#>
[CmdletBinding()]
param(
    [string[]]$InputObject,
    [string]$TenantId,
    [ValidateSet('All','Forwarding','Permissions','Groups')][string[]]$Tools = @('All'),
    [string]$SourceRoot,
    [string]$ReportPath,
    [switch]$NoPause
)
$ErrorActionPreference = 'Stop'

function Get-BatchTargets {
    param([string[]]$Values)
    if (-not $Values) { $Values = @((Read-Host 'Test UPN(s), separated by commas, or TXT/CSV path')) }
    $result = New-Object 'System.Collections.Generic.List[string]'
    foreach ($value in $Values) {
        $value = $value.Trim().Trim('"')
        if (Test-Path -LiteralPath $value -PathType Leaf) {
            switch ([IO.Path]::GetExtension($value).ToLowerInvariant()) {
                '.txt' { $lines = @(Get-Content -LiteralPath $value) }
                '.csv' {
                    $lines = @(foreach ($row in (Import-Csv -LiteralPath $value)) {
                        $column = @('UPN','UserPrincipalName','Email') | Where-Object { $row.PSObject.Properties.Name -contains $_ } | Select-Object -First 1
                        if (-not $column) { throw 'CSV requires UPN, UserPrincipalName or Email.' }
                        $row.$column
                    })
                }
                default { throw 'Input files must be TXT or CSV.' }
            }
        }
        else { $lines = @($value -split '[,;]') }
        foreach ($line in $lines) {
            $target = ([string]$line).Trim().Trim('"')
            if (-not $target -or $target.StartsWith('#')) { continue }
            if ($target -notmatch '^[^@\s,;]+@[^@\s,;]+\.[^@\s,;]+$') { throw 'Invalid UPN in test inputs. Correct the list before running.' }
            if (-not $result.Contains($target.ToLowerInvariant())) { $result.Add($target.ToLowerInvariant()) }
        }
    }
    if ($result.Count -eq 0) { throw 'No test targets supplied.' }
    return $result.ToArray()
}

function Get-BatchPlan {
    param([string]$Root,[string]$ManifestPath,[string[]]$Selection)
    $allow = @{
        Forwarding = 'published-source/mailbox/GET-MAILBOX-FORWARDING.ps1'
        Permissions = 'published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1'
        Groups = 'published-source/identity/GET-USER-GROUPS.ps1'
    }
    $manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if ($manifest.schemaVersion -ne 1 -or @($manifest.scripts).Count -ne 3) { throw 'Unsupported batch manifest.' }
    $seen = @{}
    foreach ($entry in $manifest.scripts) {
        if (-not $allow.ContainsKey([string]$entry.key) -or $entry.path -cne $allow[$entry.key] -or $seen.ContainsKey([string]$entry.key)) { throw 'Manifest contains an unapproved or duplicate tool.' }
        $seen[$entry.key] = $true
        if ($entry.sha256 -notmatch '^[a-f0-9]{64}$' -or $entry.version -ne '0.1.0') { throw 'Invalid candidate hash/version.' }
        $file = Join-Path $Root $entry.path
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw ('Missing candidate: '+$entry.path) }
        if ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ine $entry.sha256) { throw ('Candidate changed; rebuild the package before testing: '+$entry.path) }
        $parseErrors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$null,[ref]$parseErrors)
        if ($parseErrors.Count) { throw ('Candidate does not parse: '+$entry.path) }
        if ($Selection -contains 'All' -or $Selection -contains $entry.key) { $entry }
    }
}

function Connect-BatchServices {
    param([string[]]$Targets,[string]$ExpectedTenant,[object[]]$Plan)
    if ($ExpectedTenant -notmatch '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$') { throw 'Supply the expected tenant GUID from Entra Overview.' }
    $needsGraph = @($Plan | Where-Object { $_.key -eq 'Groups' }).Count -gt 0
    $needsExchange = @($Plan | Where-Object { $_.key -ne 'Groups' }).Count -gt 0
    if ($needsGraph) {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        $context = Get-MgContext -ErrorAction Stop
        $scopes = @('User.Read.All','Group.Read.All')
        if ($context -and $context.TenantId -ine $ExpectedTenant) { throw 'Existing Graph session is for another tenant. Switch sessions explicitly, then retry.' }
        $missing = @($scopes | Where-Object { -not $context -or @($context.Scopes) -notcontains $_ })
        if (-not $context -or $missing.Count -or $context.AuthType -ne 'Delegated' -or $context.Environment -ne 'Global' -or $context.ContextScope -ne 'Process') {
            $parameters = @{TenantId=$ExpectedTenant;Scopes=$scopes;ContextScope='Process';ErrorAction='Stop'}
            if ((Get-Command Connect-MgGraph).Parameters.ContainsKey('NoWelcome')) { $parameters.NoWelcome=$true }
            Connect-MgGraph @parameters | Out-Null
            $context = Get-MgContext -ErrorAction Stop
        }
        if (-not $context -or $context.TenantId -ine $ExpectedTenant -or $context.AuthType -ne 'Delegated' -or $context.Environment -ne 'Global' -or $context.ContextScope -ne 'Process' -or @($scopes | Where-Object { @($context.Scopes) -notcontains $_ }).Count) { throw 'Graph tenant/scope validation failed.' }
        foreach ($target in $Targets) {
            $uri = 'https://graph.microsoft.com/v1.0/users/'+[Uri]::EscapeDataString($target)+'?$select=id,userPrincipalName'
            $user = Invoke-MgGraphRequest -Method GET -Uri $uri -OutputType PSObject -ErrorAction Stop
            if (-not $user.id -or $user.userPrincipalName -ine $target) { throw 'A test UPN did not resolve exactly in Graph.' }
        }
        Write-Host 'Graph: Connected; tenant, scopes and targets checked.'
    }
    if ($needsExchange) {
        Import-Module ExchangeOnlineManagement -ErrorAction Stop
        $connections = @(Get-ConnectionInformation -ErrorAction Stop | Where-Object { $_.State -eq 'Connected' -or $_.ConnectionStatus -eq 'Connected' })
        if ($connections.Count -gt 1) { throw 'Multiple Exchange sessions are active. Use one client tenant per test window.' }
        if ($connections.Count -eq 0) {
            $parameters = @{ErrorAction='Stop'}
            if ((Get-Command Connect-ExchangeOnline).Parameters.ContainsKey('ShowBanner')) { $parameters.ShowBanner=$false }
            Connect-ExchangeOnline @parameters | Out-Null
        }
        $connections = @(Get-ConnectionInformation -ErrorAction Stop | Where-Object { $_.State -eq 'Connected' -or $_.ConnectionStatus -eq 'Connected' })
        if ($connections.Count -ne 1 -or [string]$connections[0].TenantID -ine $ExpectedTenant) { throw 'Exchange tenant does not match the requested tenant. Switch sessions explicitly, then retry.' }
        if ($connections[0].ModulePrefix) { throw 'This batch needs unprefixed Exchange commands. Run it in a fresh test window; leave the prefixed workflow session intact.' }
        foreach ($target in $Targets) {
            $mailbox = Get-Mailbox -Identity $target -ErrorAction Stop
            if (-not $mailbox) { throw 'Test mailbox did not resolve.' }
        }
        Write-Host 'Exchange: Connected; tenant and targets checked.'
    }
}

function Invoke-BatchCandidate {
    param([object]$Entry,[string]$Root,[string[]]$Targets)
    $file = Join-Path $Root $Entry.path
    $observation = [pscustomobject]@{Failure=$false;Warning=$false;Completed=$false;UnexpectedPrompt=$false;ErrorTypes=(New-Object 'System.Collections.Generic.List[string]')}
    $started = [DateTime]::UtcNow
    $before = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($before -cne $Entry.sha256) { throw ('Candidate changed before launch: '+$Entry.path) }
    # These two adapters exist only in this invocation scope. The candidate file
    # is executed unchanged; service commands and authentication are not mocked.
    function Write-Host {
        [CmdletBinding()]
        param([Parameter(Position=0,ValueFromRemainingArguments=$true)][object[]]$Object,
            [object]$Separator=' ',[switch]$NoNewline,[ConsoleColor]$ForegroundColor,[ConsoleColor]$BackgroundColor)
        $text = ($Object | ForEach-Object { [string]$_ }) -join [string]$Separator
        if ($text -match '^\[FAIL\]') { $observation.Failure=$true }
        if ($text -match '^\[(WARN|RISK)\]' -or $text -match '^STATUS: REVIEW REQUIRED') { $observation.Warning=$true }
        if ($text -match '^COMPLETED: ') { $observation.Completed=$true }
        if ($text -ceq 'Press ESC to close') { return }
        Microsoft.PowerShell.Utility\Write-Host @PSBoundParameters
    }
    function Read-Host {
        param([Parameter(Position=0)][string]$Prompt)
        switch -Regex ($Prompt) {
            '^Export results to CSV \[Y/N\]$' { return 'N' }
            '^Type ESC then press ENTER to close$' { return 'ESC' }
            default {
                $observation.UnexpectedPrompt=$true
                throw 'Unexpected candidate prompt. Batch stopped this tool; run it directly to inspect.'
            }
        }
    }
    try {
        if ($Entry.key -eq 'Permissions') { $arguments=@{UPN=$Targets} }
        else { $arguments=@{InputObject=$Targets} }
        & $file @arguments 2>&1 3>&1 4>&1 5>&1 | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $observation.Failure=$true
                $observation.ErrorTypes.Add($_.Exception.GetType().Name)
            }
            elseif ($_ -is [System.Management.Automation.WarningRecord]) { $observation.Warning=$true }
            $_ | Out-Host
        }
    }
    catch {
        $observation.Failure=$true
        $observation.ErrorTypes.Add($_.Exception.GetType().Name)
        Microsoft.PowerShell.Utility\Write-Host ('[FAIL] '+$_.Exception.Message) -ForegroundColor Red
    }
    $after = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    $issues = New-Object 'System.Collections.Generic.List[string]'
    if ($observation.Failure) { $issues.Add('SCRIPT_REPORTED_FAILURE') }
    if ($observation.Warning) { $issues.Add('SCRIPT_REPORTED_REVIEW_REQUIRED') }
    if (-not $observation.Completed) { $issues.Add('COMPLETION_NOT_OBSERVED') }
    if ($observation.UnexpectedPrompt) { $issues.Add('UNEXPECTED_PROMPT') }
    if ($before -cne $after) { $issues.Add('SOURCE_CHANGED_DURING_RUN') }
    [pscustomobject]@{
        tool=$Entry.key;file=[IO.Path]::GetFileName($Entry.path);version=$Entry.version;sha256=$before
        seconds=[Math]::Round(([DateTime]::UtcNow-$started).TotalSeconds,1)
        observed=$(if ($observation.Failure -or $before -cne $after) {'Failed'} elseif ($issues.Count) {'Incomplete'} else {'Completed'})
        issues=@($issues.ToArray());errorTypes=@($observation.ErrorTypes.ToArray() | Sort-Object -Unique)
        operatorVerdict='Pending';result='Incomplete'
    }
}

function Set-BatchVerdict {
    param([object]$Result)
    Write-Host ('Observed: '+$Result.observed)
    if ($Result.issues.Count) { Write-Host ('Review: '+($Result.issues -join ', ')) -ForegroundColor Yellow }
    do { $verdict = (Read-Host 'Expected findings and coverage correct? [P]ass / [F]ail / [I]ncomplete').Trim().ToUpperInvariant() } until ($verdict -in @('P','F','I'))
    $Result.operatorVerdict = @{P='Passed';F='Failed';I='Incomplete'}[$verdict]
    if ($Result.observed -eq 'Failed' -or $verdict -eq 'F') { $Result.result='Failed' }
    elseif ($Result.observed -eq 'Completed' -and $verdict -eq 'P') { $Result.result='Passed' }
    else { $Result.result='Incomplete' }
}

function Save-BatchReport {
    param([object]$Report,[string]$Path)
    $parent = Split-Path -Parent ([IO.Path]::GetFullPath($Path))
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    if (Test-Path -LiteralPath $Path) { throw 'Report already exists; choose a new ReportPath.' }
    $json = $Report | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($Path),$json,(New-Object Text.UTF8Encoding($false)))
    $readback = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if (($readback | ConvertTo-Json -Depth 8 -Compress) -cne ($Report | ConvertTo-Json -Depth 8 -Compress)) { throw 'Report readback did not match.' }
}

# Dot-source to load helpers for isolated QA; launching the file runs the batch.
if ($MyInvocation.InvocationName -eq '.') { return }
$report = $null
try {
    if (-not $SourceRoot) {
        if (Test-Path (Join-Path $PSScriptRoot 'published-source')) { $SourceRoot=$PSScriptRoot }
        else { $SourceRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')) }
    }
    $plan = @(Get-BatchPlan -Root $SourceRoot -ManifestPath (Join-Path $PSScriptRoot 'user-readonly-manifest.json') -Selection $Tools)
    if ($plan.Count -eq 0) { throw 'No tools selected.' }
    $targets = @(Get-BatchTargets -Values $InputObject)
    if (-not $TenantId) { $TenantId=(Read-Host 'Expected tenant ID (GUID from Entra Overview)').Trim() }
    $id = [Guid]::NewGuid().ToString()
    if (-not $ReportPath) {
        $folder = [Environment]::GetFolderPath('MyDocuments')
        if (-not $folder) { $folder=[IO.Path]::GetTempPath() }
        $ReportPath = Join-Path (Join-Path $folder 'FIELD-KIT-TESTS') ('user-readonly-'+$id+'.json')
    }
    $report = [pscustomobject]@{
        schemaVersion=1;batchVersion='0.1.0';batchId=$id;batch='User read-only';startedUtc=[DateTime]::UtcNow.ToString('o');completedUtc=$null
        powershell=$PSVersionTable.PSVersion.ToString();edition=$PSVersionTable.PSEdition;targetCount=$targets.Count
        testCase=$null;preflight='Pending';batchIssue=$null;modules=@();results=@()
        note='Operator assessment of batch output; not a VERIFIED stamp. Interactive pauses and CSV prompts are adapted; standalone launch remains a separate check.'
    }
    Write-Host 'FIELD // KIT - USER READ-ONLY TEST BATCH'
    Write-Host 'Runs the selected candidates in this session. Writes one local results report.'
    Write-Host ('Tenant: '+$TenantId)
    Write-Host ('Targets: '+($targets -join ', '))
    Write-Host ('Tools: '+(($plan | ForEach-Object {$_.key}) -join ', '))
    Write-Host 'Detailed errors stay on screen. The report excludes target identities and raw output.'
    do { $case=(Read-Host 'Test case: [C]lean / [F]indings present / [U]navailable source / [M]ixed').Trim().ToUpperInvariant() } until ($case -in @('C','F','U','M'))
    $report.testCase=@{C='Clean';F='Known findings';U='Unavailable source';M='Mixed'}[$case]
    if ((Read-Host 'Run this read-only batch? [Y/N]').Trim() -ine 'Y') { $report.preflight='Skipped';return }
    Connect-BatchServices -Targets $targets -ExpectedTenant $TenantId -Plan $plan
    $report.preflight='Passed'
    $report.modules=@(Get-Module Microsoft.Graph.Authentication,ExchangeOnlineManagement,ActiveDirectory | ForEach-Object { [pscustomobject]@{name=$_.Name;version=$_.Version.ToString()} })
    foreach ($entry in $plan) {
        Write-Host ''
        Write-Host ('----- '+$entry.key.ToUpperInvariant()+' -----')
        $result=Invoke-BatchCandidate -Entry $entry -Root $SourceRoot -Targets $targets
        $report.results+=,$result
        Set-BatchVerdict -Result $result
    }
}
catch {
    Write-Host ('[FAIL] '+$_.Exception.Message) -ForegroundColor Red
    if ($report) {
        if ($report.preflight -eq 'Pending') { $report.preflight='Failed';$report.batchIssue='PREFLIGHT_FAILED' }
        else { $report.batchIssue='BATCH_INTERRUPTED' }
    }
}
finally {
    if ($report) {
        foreach ($entry in $plan) {
            if (-not @($report.results | Where-Object {$_.tool -eq $entry.key}).Count) {
                $report.results+=,[pscustomobject]@{tool=$entry.key;file=[IO.Path]::GetFileName($entry.path);version=$entry.version;sha256=$entry.sha256;observed='Not run';issues=@();errorTypes=@();operatorVerdict='Not assessed';result='Skipped';seconds=0}
            }
        }
        $report.completedUtc=[DateTime]::UtcNow.ToString('o')
        Write-Host ''
        Write-Host '----- BATCH RESULTS -----'
        $report.results | Select-Object file,result,seconds | Format-Table -AutoSize | Out-Host
        try { Save-BatchReport -Report $report -Path $ReportPath;Write-Host ('Report checked: '+[IO.Path]::GetFullPath($ReportPath)) }
        catch { Write-Host ('[FAIL] Report could not be saved: '+$_.Exception.Message) -ForegroundColor Red }
    }
    Write-Host 'Batch finished. Sessions remain available in this window.'
    if (-not $NoPause) { [void](Read-Host 'Press ENTER to close the batch') }
}
