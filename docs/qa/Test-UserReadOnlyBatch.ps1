# Isolated fixtures only. Does not authenticate or contact a tenant.
$ErrorActionPreference='Stop'
$root=Resolve-Path (Join-Path $PSScriptRoot '../..')
$temp=Join-Path ([IO.Path]::GetTempPath()) ('field-kit-batch-fixture-'+[guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $temp)
$tenant='11111111-1111-1111-1111-111111111111'
$global:Scenario='Clean';$global:ExportFixture=$false;$global:ClosingPrompts=0;$global:ExportPrompts=0
# Reuse the existing read-only service fixtures without executing their test body.
$ast=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Test-Batch1-Formatting.ps1'),[ref]$null,[ref]$null)
foreach($node in $ast.EndBlock.Statements){if($node -is [System.Management.Automation.Language.FunctionDefinitionAst]){. ([scriptblock]::Create($node.Extent.Text))}}
. (Join-Path $PSScriptRoot 'Invoke-UserReadOnlyBatch.ps1')
$global:GraphTenant=$tenant;$global:ExchangeTenant=$tenant;$global:GraphConnected=$true;$global:ExchangeConnected=$true;$global:GraphConnects=0;$global:ExchangeConnects=0
function Get-MgContext {param($ErrorAction)
    if($global:GraphConnected){[pscustomobject]@{TenantId=$global:GraphTenant;Scopes=@('User.Read.All','Group.Read.All');AuthType='Delegated';Environment='Global';ContextScope='Process'}}
}
function Get-OrganizationConfig {param($ErrorAction) [pscustomobject]@{ExternalDirectoryOrganizationId=$global:ExchangeTenant}}
function Get-ConnectionInformation {param($ErrorAction)
    if($global:ExchangeConnected){[pscustomobject]@{State='Connected';ConnectionStatus='Connected';TenantID=$global:ExchangeTenant;ModulePrefix=''}}
}
function Connect-MgGraph {param($TenantId,$Scopes,$ContextScope,[switch]$NoWelcome,$ErrorAction) $global:GraphConnects++;$global:GraphConnected=$true}
function Connect-ExchangeOnline {param([switch]$ShowBanner,$ErrorAction) $global:ExchangeConnects++;$global:ExchangeConnected=$true}
function Read-Host {param($Prompt)
    if($Prompt -like 'Test case:*'){return 'C'}
    if($Prompt -like 'Run this read-only batch?*'){return 'Y'}
    if($Prompt -like 'Expected findings*'){return $global:Verdict}
    throw "Unexpected runner prompt: $Prompt"
}
try {
    $manifest=Join-Path $PSScriptRoot 'user-readonly-manifest.json'
    $plan=@(Get-BatchPlan -Root $root -ManifestPath $manifest -Selection All)
    Assert ($plan.Count -eq 3) 'Batch plan did not contain three tools'
    $targets=@(Get-BatchTargets -Values @('user@example.invalid','USER@example.invalid'))
    Assert ($targets.Count -eq 1) 'UPN deduplication failed'
    @('user@example.invalid','# comment','sample@example.invalid') | Set-Content (Join-Path $temp 'targets.txt')
    Assert (@(Get-BatchTargets -Values (Join-Path $temp 'targets.txt')).Count -eq 2) 'TXT list failed'
    @([pscustomobject]@{UPN='user@example.invalid'}) | Export-Csv (Join-Path $temp 'targets.csv') -NoTypeInformation
    Assert (@(Get-BatchTargets -Values (Join-Path $temp 'targets.csv')).Count -eq 1) 'CSV list failed'
    Connect-BatchServices -Targets $targets -ExpectedTenant $tenant -Plan $plan
    Assert ($global:GraphConnects -eq 0 -and $global:ExchangeConnects -eq 0) 'Healthy sessions were not reused'
    Write-Host 'PASS Input lists, pinned plan and session reuse'
    $global:GraphConnected=$false;$global:ExchangeConnected=$false
    Connect-BatchServices -Targets $targets -ExpectedTenant $tenant -Plan $plan
    Connect-BatchServices -Targets $targets -ExpectedTenant $tenant -Plan $plan
    Assert ($global:GraphConnects -eq 1 -and $global:ExchangeConnects -eq 1) 'Fresh batch did not authenticate exactly once per service'
    $global:GraphConnects=0;$global:ExchangeConnects=0
    Write-Host 'PASS Missing sessions authenticate once, then reuse'
    $global:GraphTenant='22222222-2222-2222-2222-222222222222'
    $caught=$false
    try {Connect-BatchServices -Targets $targets -ExpectedTenant $tenant -Plan $plan} catch {$caught=$true}
    Assert $caught 'Graph tenant mismatch did not stop preflight'
    $global:GraphTenant=$tenant;$global:ExchangeTenant='22222222-2222-2222-2222-222222222222';$caught=$false
    try {Connect-BatchServices -Targets $targets -ExpectedTenant $tenant -Plan $plan} catch {$caught=$true}
    Assert $caught 'Exchange tenant mismatch did not stop preflight'
    $global:ExchangeTenant=$tenant
    Write-Host 'PASS Wrong-tenant sessions fail closed'
    $results=@()
    foreach($entry in $plan){
        $result=Invoke-BatchCandidate -Entry $entry -Root $root -Targets $targets
        Assert ($result.observed -eq 'Completed') "Clean batch tool failed: $($entry.key): $($result|ConvertTo-Json -Compress)"
        Assert ($result.result -eq 'Incomplete' -and $result.operatorVerdict -eq 'Pending') 'Tool auto-passed without operator review'
        $global:Verdict='P';Set-BatchVerdict $result
        Assert ($result.result -eq 'Passed') 'Clean explicit pass failed'
        $results+=,$result
    }
    Assert ($global:GraphConnects -eq 0 -and $global:ExchangeConnects -eq 0 -and $global:ExportPrompts -eq 0 -and $global:ClosingPrompts -eq 0) 'Batch prompted for auth/export/close'
    Write-Host 'PASS Three exact candidates run without repeated export/closing prompts'
    $global:Scenario='HiddenDenied'
    $result=Invoke-BatchCandidate -Entry $plan[0] -Root $root -Targets $targets
    Assert ($result.observed -eq 'Incomplete') 'Denied read became clean'
    $global:Verdict='P';Set-BatchVerdict $result
    Assert ($result.result -eq 'Incomplete') 'Operator overrode missing coverage to pass'
    $global:Verdict='F';Set-BatchVerdict $results[0]
    Assert ($results[0].result -eq 'Failed') 'Operator failure was lost'
    Write-Host 'PASS Coverage warnings cannot be passed; operator failures retained'
    # Exercise failure adapters with a harmless local fixture; production plan
    # permits only the three paths above, never this fixture.
    $fixture=Join-Path $temp 'fixture.ps1'
    @'
param($InputObject)
Read-Host 'Do something unexpected?'
Write-Host 'COMPLETED: fixture'
'@ | Set-Content $fixture
    $entry=[pscustomobject]@{key='Forwarding';path='fixture.ps1';version='0.1.0';sha256=(Get-FileHash $fixture).Hash.ToLowerInvariant()}
    $result=Invoke-BatchCandidate -Entry $entry -Root $temp -Targets $targets
    Assert ($result.observed -eq 'Failed' -and $result.issues -contains 'UNEXPECTED_PROMPT') 'Unexpected prompt was answered'
    $entry.sha256='0'*64;$caught=$false
    try {Invoke-BatchCandidate -Entry $entry -Root $temp -Targets $targets} catch {$caught=$true}
    Assert $caught 'Changed candidate executed'
    Write-Host 'PASS Unexpected prompts and changed source fail closed'
    "param(`$InputObject);Write-Host 'Stopped without completion'" | Set-Content $fixture
    $entry.sha256=(Get-FileHash $fixture).Hash.ToLowerInvariant()
    $result=Invoke-BatchCandidate -Entry $entry -Root $temp -Targets $targets
    Assert ($result.observed -eq 'Incomplete' -and $result.issues -contains 'COMPLETION_NOT_OBSERVED') 'Missing completion became a pass'
    "param(`$InputObject);Write-Warning 'Fixture warning';Write-Host 'COMPLETED: fixture'" | Set-Content $fixture
    $entry.sha256=(Get-FileHash $fixture).Hash.ToLowerInvariant()
    $result=Invoke-BatchCandidate -Entry $entry -Root $temp -Targets $targets
    Assert ($result.observed -eq 'Incomplete') 'Warning stream was ignored'
    Write-Host 'PASS Missing completion and native warnings remain incomplete'
    $report=[pscustomobject]@{schemaVersion=1;results=$results;targetCount=1}
    $reportPath=Join-Path $temp 'report.json'
    Save-BatchReport -Report $report -Path $reportPath
    $json=Get-Content $reportPath -Raw
    Assert ($json -notmatch 'user@example|operator@example|11111111|fixture-dc|forward@example') 'Report leaked fixture identities'
    $caught=$false;try {Save-BatchReport -Report $report -Path $reportPath} catch {$caught=$true}
    Assert $caught 'Report silently overwritten'
    Write-Host 'PASS Report round-trip, privacy fields and overwrite protection'
    $global:Scenario='Clean';$global:Verdict='P'
    $fullReport=Join-Path $temp 'full-batch.json'
    & (Join-Path $PSScriptRoot 'Invoke-UserReadOnlyBatch.ps1') -InputObject $targets -TenantId $tenant -SourceRoot $root -ReportPath $fullReport -NoPause
    $full=Get-Content $fullReport -Raw | ConvertFrom-Json
    Assert ($full.preflight -eq 'Passed' -and $full.results.Count -eq 3 -and @($full.results|Where-Object {$_.result -ne 'Passed'}).Count -eq 0) 'Full entry-point run failed'
    Assert ((Get-Content $fullReport -Raw) -notmatch 'user@example|11111111') 'Full report leaked fixture identity'
    Write-Host 'PASS Full runner entry point and one checked results report'
}
finally {Remove-Item -LiteralPath $temp -Recurse -Force}
