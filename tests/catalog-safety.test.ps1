# Source-only screening and isolated helper fixtures; no workflow main or service actions run.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$inventory=Get-Content (Join-Path $Root 'docs/qa/CATALOG-REVIEW-INVENTORY.json') -Raw | ConvertFrom-Json
$exceptions=@(Get-Content (Join-Path $Root 'docs/qa/KNOWN-SAFETY-EXCEPTIONS.json') -Raw | ConvertFrom-Json)
$seen=@{};$scriptCount=0;$helperCount=0;$uriCount=0;$readCases=0;$authCases=0
foreach ($entry in @($inventory.entries | Where-Object { $_.publishedPath -and $_.file -match '\.ps1$' })) {
    $file=Join-Path $Root $entry.publishedPath;$tokens=$null;$errors=$null
    $ast=[System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw "Parse failed: $($entry.file)" };$scriptCount++
    foreach ($string in @($ast.FindAll({param($n) $n -is [System.Management.Automation.Language.ExpandableStringExpressionAst]},$true))) {
        if ($string.Extent.Text -notmatch 'https://graph\.microsoft\.com/') { continue };$uriCount++
        $bad=@($string.NestedExpressions | Where-Object { $_ -is [System.Management.Automation.Language.VariableExpressionAst] -and $_.VariablePath.UserPath.EndsWith('?') })
        if (-not $bad.Count) { continue }
        $allowed=@($exceptions | Where-Object { $_.path -eq $entry.publishedPath -and $_.rule -eq 'URI_VARIABLE_QUESTION' -and $_.line -eq $string.Extent.StartLineNumber })
        $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($allowed.Count -ne 1 -or $allowed[0].sha256 -ne $hash) { throw "Unbraced Graph URI variable: $($entry.publishedPath):$($string.Extent.StartLineNumber)" }
        $seen[$entry.publishedPath]=$true
        Write-Output "KNOWN OPEN FINDING: $($entry.file):$($string.Extent.StartLineNumber) - app-name lookup requires revision/retest."
    }
    $resolver=$ast.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-GraphUserByUPN'},$false)
    $reader=$ast.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Graph-Get'},$false)
    $pages=$ast.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-GraphPages'},$false)
    if ($entry.publishedPath -like 'published-source/tenant/*' -and $reader -and $reader.Extent.Text -match 'review incomplete') {
        $ensure=$ast.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Ensure-Graph'},$false)
        $guard=$ast.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Assert-GraphContext'},$false)
        & {
            . ([scriptblock]::Create($ensure.Extent.Text));. ([scriptblock]::Create($guard.Extent.Text))
            function INFO { param($Message) }
            function OK { param($Message) }
            function FAIL { param($Message) }
            function Get-Module { [CmdletBinding()]param($Name,[switch]$ListAvailable) @{Path='offline';Version=[version]'2.0'} }
            function Import-Module { [CmdletBinding()]param($Name,[switch]$Force) }
            function Get-MgContext { [CmdletBinding()]param() $script:auditContext }
            function Disconnect-MgGraph { [CmdletBinding()]param() $script:auditContext=$null }
            function New-AuditContext { @{TenantId='11111111-1111-4111-8111-111111111111';Account='operator@example.invalid';AuthType='Delegated';ContextScope='Process';Scopes=@('scope.one')} }
            function Connect-MgGraph {
                [CmdletBinding()]param($Scopes,$TenantId,$ContextScope,[switch]$NoWelcome)
                if ($TenantId -ne '11111111-1111-4111-8111-111111111111' -or $ContextScope -ne 'Process') { throw 'Unsafe audit connection parameters.' }
                $script:auditConnections++;$script:auditContext=New-AuditContext
                if ($script:auditCase -eq 'signin-mismatch') { $script:auditContext.TenantId='22222222-2222-4222-8222-222222222222' }
            }
            foreach ($case in @('reuse','wrong-tenant','new','signin-mismatch','invalid-tenant','current-user','missing-scope')) {
                $script:auditCase=$case;$script:auditConnections=0;$script:auditContext=New-AuditContext;$threw=$false
                $expected='11111111-1111-4111-8111-111111111111'
                if ($case -in @('new','signin-mismatch')) { $script:auditContext=$null }
                if ($case -eq 'wrong-tenant') { $script:auditContext.TenantId='22222222-2222-4222-8222-222222222222' }
                if ($case -eq 'invalid-tenant') { $expected='invalid' }
                if ($case -eq 'current-user') { $script:auditContext.ContextScope='CurrentUser' }
                if ($case -eq 'missing-scope') { $script:auditContext.Scopes=@() }
                try { $null=Ensure-Graph -Scopes @('scope.one') -TenantId $expected } catch { $threw=$true }
                if ($threw -ne ($case -in @('wrong-tenant','signin-mismatch','invalid-tenant'))) { throw "Audit tenant validation wrong: $($entry.file) / $case" }
                if ($case -in @('reuse','wrong-tenant','invalid-tenant') -and $script:auditConnections) { throw 'Existing tenant context was replaced unexpectedly.' }
            }
        };$authCases+=7
    }
    if ($reader -and $reader.Extent.Text -notmatch 'return\s+\$null' -and $pages) {
        & {
            . ([scriptblock]::Create($reader.Extent.Text));. ([scriptblock]::Create($pages.Extent.Text))
            function Invoke-MgGraphRequest {
                [CmdletBinding()]param($Method,$Uri)
                $script:pageCalls++
                switch ($script:pageCase) {
                    'empty' { return @{value=@()} }
                    'malformed' { return @{} }
                    'denied' { throw 'Offline simulated access denied.' }
                    'interrupted' { if ($script:pageCalls -eq 1) { return @{value=@(@{id='one'});'@odata.nextLink'='https://graph.microsoft.com/v1.0/offline-next'} };throw 'Offline interrupted pagination.' }
                }
            }
            foreach ($case in @('empty','malformed','denied','interrupted')) {
                $script:pageCase=$case;$script:pageCalls=0;$threw=$false;$rows=@()
                try { $rows=@(Get-GraphPages -Uri 'https://graph.microsoft.com/v1.0/offline-fixture') } catch { $threw=$true }
                if ($case -eq 'empty') { if ($threw -or $rows.Count) { throw "Empty success failed: $($entry.file)" } }
                elseif (-not $threw) { throw "Unavailable data became an empty/partial success: $($entry.file) / $case" }
            }
        };$readCases+=4
    }
    if ($resolver) {
        $encoder=$ast.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Encode-Value'},$false)
        if (-not $encoder) { throw "Missing encoder fixture: $($entry.file)" }
        & {
            . ([scriptblock]::Create($encoder.Extent.Text));. ([scriptblock]::Create($resolver.Extent.Text))
            function Graph-Get {
                param([string]$Uri)
                if ($Uri -notmatch '/users/audit%2Bmarker%40example\.invalid\?\$select=') { throw "Incorrect resolver URI: $Uri" }
                @{id='offline-only';userPrincipalName='audit+marker@example.invalid';assignedLicenses=@()}
            }
            $null=Get-GraphUserByUPN -UPN 'audit+marker@example.invalid'
        };$helperCount++
    }
}
foreach ($exception in $exceptions) { if (-not $seen.ContainsKey($exception.path)) { throw "Stale exception: $($exception.path). Review the changed release before removing the finding." } }
$commands=@((& node (Join-Path $Root 'tools/catalog-commands.mjs')) | ConvertFrom-Json)
if ($LASTEXITCODE -ne 0) { throw 'Unable to read inline commands.' }
foreach ($command in $commands) {
    $t=$null;$e=$null;$tree=[System.Management.Automation.Language.Parser]::ParseInput($command.code,[ref]$t,[ref]$e)
    if ($e.Count) { throw "Inline parse error: $($command.name)" }
    foreach ($string in @($tree.FindAll({param($n) $n -is [System.Management.Automation.Language.ExpandableStringExpressionAst]},$true))) {
        if ($string.Extent.Text -notmatch 'https://graph\.microsoft\.com/') { continue }
        if (@($string.NestedExpressions | Where-Object { $_ -is [System.Management.Automation.Language.VariableExpressionAst] -and $_.VariablePath.UserPath.EndsWith('?') }).Count) { throw "Unbraced inline URI variable: $($command.name)" }
    }
}
& {
    $t=$null;$e=$null;$audit=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $Root 'published-source/tenant/GET-SIGNIN-ANOMALIES.ps1'),[ref]$t,[ref]$e)
    $classification=$audit.Find({param($n) $n -is [System.Management.Automation.Language.ForEachStatementAst] -and $n.Variable.VariablePath.UserPath -eq 'e' -and $n.Condition.Extent.Text -eq '$events'},$true)
    if (-not $classification) { throw 'Sign-in classification changed; update its fixture.' }
    foreach ($case in @('expected','foreign','unknown','device-code')) {
        $ExpectedCountry=@('CA');$country=if ($case -eq 'foreign') {'US'} elseif ($case -eq 'unknown') {''} else {'CA'}
        $events=@([pscustomobject]@{Result='Success';Country=$country;ClientApp=$(if ($case -eq 'device-code') {'Device Code'} else {'Browser'});App='Offline';Finding='Review'})
        . ([scriptblock]::Create($classification.Extent.Text))
        $expected=if ($case -eq 'foreign') {'Foreign successful sign-in'} elseif ($case -eq 'device-code') {'Device code activity'} else {'Review'}
        if ($events[0].Finding -ne $expected) { throw "Country context classification wrong: $case" }
    }
    $loop=$audit.Find({param($n) $n -is [System.Management.Automation.Language.WhileStatementAst] -and $n.Condition.Extent.Text -match 'MaxPages'},$true)
    function INFO { param($Message) }
    function Graph-Get { param($Uri) if ($script:signInCase -eq 'malformed') { return @{} };@{value=@();'@odata.nextLink'='https://graph.microsoft.com/v1.0/offline-more'} }
    foreach ($case in @('capped','malformed')) {
        $script:signInCase=$case;$uri='https://graph.microsoft.com/v1.0/offline';$page=0;$MaxPages=1;$events=New-Object System.Collections.ArrayList;$threw=$false
        try { . ([scriptblock]::Create($loop.Extent.Text)) } catch { $threw=$true }
        if ($case -eq 'malformed' -and -not $threw) { throw 'Malformed sign-in page became a successful empty review.' }
        if ($case -eq 'capped' -and ($threw -or -not $uri -or $page -ne 1)) { throw 'Remaining sign-in coverage was lost at the page limit.' }
    }
}
& {
    $t=$null;$e=$null
    $risk=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $Root 'published-source/incident-response/BEC-RISK-ASSESSMENT.ps1'),[ref]$t,[ref]$e)
    $fn=$risk.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-ServicePrincipalInfo'},$false)
    $candidate=$fn.Extent.Text
    . ([scriptblock]::Create($candidate))
    function GraphGet {
        param($Uri,$Headers)
        if ($script:appCase -eq 'collection-first' -and $Uri -notmatch '/servicePrincipals\?') { return @{Ok=$true;Data=@{value=@()}} }
        if ($script:appCase -eq 'unavailable') { return @{Ok=$false} }
        $data=@{id='fixture-id';displayName='Offline app';publisherName='Offline publisher';verifiedPublisher=@{displayName=''}}
        if ($Uri -match '/servicePrincipals\?') { return @{Ok=$true;Data=@{value=@($data)}} }
        if ($Uri -notmatch '/servicePrincipals/fixture-id\?') { throw 'App lookup lost the service-principal identifier.' }
        return @{Ok=$true;Data=$data}
    }
    foreach ($case in @('direct','collection-first','unavailable')) {
        $script:appCase=$case;$info=Get-ServicePrincipalInfo 'fixture-id' @{} @{}
        if ($case -eq 'unavailable') { if ($info.Ok) { throw 'Unavailable app lookup was reported resolved.' } }
        elseif (-not $info.Ok -or $info.Name -ne 'Offline app') { throw "App lookup failed: $case" }
    }
}
Write-Output "PASS: $scriptCount script ASTs, $($commands.Count) command ASTs, $uriCount Graph URI strings, $helperCount resolver fixtures, $readCases collection/error cases, $authCases tenant-context cases, 6 sign-in context cases, 3 current-source IR fixtures. Known open findings: $($seen.Count)."
