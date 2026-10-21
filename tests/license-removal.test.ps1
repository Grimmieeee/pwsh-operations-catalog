# Offline regression tests: all module, authentication, Graph and prompt operations are mocked.
param([string]$Root = (Split-Path $PSScriptRoot -Parent), [ValidateSet('Remove','Assign')][string]$Mode='Remove')
$ErrorActionPreference='Stop'
$tokens=$null; $errors=$null
$sourceFile=if ($Mode -eq 'Assign') { 'published-source/identity/INVOKE-ASSIGN-LICENSES.ps1' } else { 'published-source/identity/INVOKE-REMOVE-LICENSES.ps1' }
$ast=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $Root $sourceFile), [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors.Message -join '; ') }
foreach ($definition in $ast.FindAll({param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $false)) {
    . ([scriptblock]::Create($definition.Extent.Text))
}
$mainAst=@($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.TryStatementAst] })[-1]
$main=[scriptblock]::Create($mainAst.Extent.Text)
$script:tenant='11111111-1111-4111-8111-111111111111'
$script:otherTenant='22222222-2222-4222-8222-222222222222'
$script:sku='33333333-3333-4333-8333-333333333333'
$script:scopes=@('User.ReadWrite.All','Directory.Read.All','Organization.Read.All')

function New-TestContext {
    @{ TenantId=$script:tenant; Account='operator@example.invalid'; AuthType='Delegated'; ContextScope='Process'; Scopes=$script:scopes }
}
function Get-Module { [CmdletBinding()]param([switch]$ListAvailable,[string]$Name) @{ Version=[version]'2.0'; Path='mock-only' } }
function Import-Module { [CmdletBinding()]param($Name,[switch]$Force) }
function Get-MgContext { [CmdletBinding()]param() $script:ctx }
function Disconnect-MgGraph { [CmdletBinding()]param() $script:disconnects++; $script:ctx=$null }
function Connect-MgGraph {
    [CmdletBinding()]param($Scopes,$TenantId,$ContextScope,[switch]$NoWelcome)
    if ($TenantId -ne $script:tenant -or $ContextScope -ne 'Process') { throw 'Unsafe sign-in parameters.' }
    $script:connects++; $script:ctx=New-TestContext
    if ($script:case -eq 'signin-mismatch') { $script:ctx.TenantId=$script:otherTenant }
}
function Invoke-MgGraphRequest {
    [CmdletBinding()]param($Method,$Uri,$Body,$ContentType)
    $script:requests++
    if ($Method -eq 'POST') {
        $script:posts++
        if ($script:case -eq 'request-failure' -or ($script:case -eq 'mixed-results' -and $Uri -match '/target-a/')) { throw 'Simulated request failure; outcome unknown.' }
        return @{ id='target-a' }
    }
    if ($Method -eq 'PATCH' -and $Mode -eq 'Assign') {
        $script:patches++
        if ($script:case -eq 'location-failed') { throw 'Simulated UsageLocation update failed.' }
        return
    }
    if ($Method -ne 'GET') { throw 'Unexpected method in offline test.' }
    if ($Uri -match '/subscribedSkus$') {
        if ($script:case -eq 'inventory-failure') { throw 'Simulated inventory denied.' }
        return @{ value=@(@{ skuId=$script:sku; skuPartNumber='TEST_PRODUCT'; prepaidUnits=@{enabled=100};consumedUnits=1 }) }
    }
    if ($Uri -match '/users/([^?]+)\?') {
        $upn=[uri]::UnescapeDataString($Matches[1])
        if ($script:case -eq 'unresolved-user' -and $upn -eq 'second@example.invalid') { throw 'Simulated user lookup denied.' }
        $licenses=@(@{skuId=$script:sku})
        if (($script:posts -and $script:case -ne 'remaining-license') -or $script:case -eq 'no-match') { $licenses=@() }
        if ($Mode -eq 'Assign') {
            $licenses=@()
            if (($script:posts -and $script:case -ne 'remaining-license') -or $script:case -eq 'no-match') { $licenses=@(@{skuId=$script:sku}) }
        }
        $id=if ($upn -eq 'first@example.invalid') { 'target-a' } else { 'target-b' }
        $location=if ($script:case -like 'location-*' -and -not $script:patches) { $null } else { 'US' }
        $user=@{ id=$id; userPrincipalName=$upn; assignedLicenses=$licenses; usageLocation=$location }
        if ($script:case -eq 'missing-before' -or ($script:posts -and $script:case -eq 'missing-after')) { $user.Remove('assignedLicenses') }
        if ($script:posts -and $script:case -eq 'changed-id') { $user.id='different-target' }
        if ($script:case -eq 'wrong-upn') { $user.userPrincipalName='different@example.invalid' }
        return $user
    }
    throw "Unexpected offline route: $Uri"
}
function Read-Host {
    param([string]$Prompt)
    if ($Prompt -eq 'Choose license to remove') { return 'ALL' }
    if ($Prompt -eq 'Choose SKU to assign') { return '1' }
    if ($Prompt -like 'UsageLocation for missing users*') { if ($script:case -eq 'location-skip') { return '' }; return 'US' }
    if ($Prompt -in @('Type REMOVE to continue','Type ASSIGN to continue')) {
        $script:approvals++
        if ($script:case -eq 'cancel') { return 'CANCEL' }
        if ($script:case -eq 'context-changed') { $script:ctx.TenantId=$script:otherTenant }
        if ($Mode -eq 'Assign') { return 'ASSIGN' }; return 'REMOVE'
    }
    if ($Prompt -like 'Export results to CSV*') { return 'N' }
    if ($Prompt -eq 'Press Enter to close session.') { return '' }
    throw "Unexpected offline prompt: $Prompt"
}
function Clear-Host {}
function Start-Sleep { param($Milliseconds) }
function Assert-Test { param([bool]$Condition,[string]$Message) if (-not $Condition) { throw $Message } }
function Run-Case {
    param([string]$Name)
    $script:case=$Name; $script:ctx=New-TestContext
    $script:posts=0; $script:patches=0; $script:requests=0; $script:approvals=0; $script:connects=0; $script:disconnects=0
    $InputObject=@('first@example.invalid'); $InputPath=''; $ExpectedTenantId=$script:tenant; $UsageLocation=''
    if ($Name -in @('unresolved-user','mixed-results')) { $InputObject+= 'second@example.invalid' }
    if ($Name -eq 'wrong-tenant') { $script:ctx.TenantId=$script:otherTenant }
    if ($Name -eq 'signin-mismatch' -or $Name -eq 'new-session') { $script:ctx=$null }
    if ($Name -eq 'current-user-session') { $script:ctx.ContextScope='CurrentUser' }
    if ($Name -eq 'missing-scope') { $script:ctx.Scopes=@('User.Read.All') }
    if ($Name -eq 'invalid-tenant') { $ExpectedTenantId='not-a-tenant' }
    $script:lastOutput=(& $main 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
    $planName=Get-LicenseProductName -SkuId $script:sku -SkuPartNumber 'TEST_PRODUCT'
    $planText=if ($Mode -eq 'Assign') { '-> Assign '+$planName } else { '-> '+$planName }
    if ($Name -in @('success','new-session','current-user-session','missing-scope','location-write')) {
        Assert-Test ($script:posts -eq 1) "$Name must make one mocked request. Output: $script:lastOutput"
        Assert-Test ($script:lastOutput -match 'STATUS: Completed' -and $script:lastOutput -match 'Verified\s+: 1') "$Name must verify completion."
        Assert-Test ($script:lastOutput.Contains("first@example.invalid $planText") -and $script:lastOutput.IndexOf("first@example.invalid $planText") -lt $script:lastOutput.IndexOf('This will')) 'Target plan must precede approval.'
        Assert-Test ($script:lastOutput -match "Tenant ID\s+: $script:tenant") 'Plan must identify tenant.'
        Assert-Test ($script:approvals -eq 1) 'Only one change approval is allowed.'
        if ($Name -eq 'success') { Assert-Test ($script:connects -eq 0) 'Healthy session must be reused.' }
        if ($Name -eq 'location-write') { Assert-Test ($script:patches -eq 1) 'Approved UsageLocation must be set once.' }
    } elseif ($Name -in @('remaining-license','missing-after','changed-id','request-failure','context-changed','mixed-results','location-failed')) {
        Assert-Test ($script:lastOutput -match 'STATUS: Incomplete') "$Name must remain incomplete."
        Assert-Test ($script:lastOutput -notmatch '\[OK\].*STATUS: Completed') "$Name must not claim completion."
        if ($Name -eq 'context-changed') { Assert-Test ($script:posts -eq 0) 'Changed context must block writes.' }
        elseif ($Name -eq 'mixed-results') {
            Assert-Test ($script:posts -eq 2 -and $script:lastOutput -match 'Verified\s+: 1' -and $script:lastOutput -match 'Failed\s+: 1') 'Mixed results must retain successful and failed targets.'
            Assert-Test ($script:lastOutput.Contains("second@example.invalid $planText")) 'Every bulk target must appear in the plan.'
        }
        elseif ($Name -eq 'location-failed') { Assert-Test ($script:posts -eq 0 -and $script:patches -eq 1) 'Failed location update must block license assignment.' }
        elseif ($Name -eq 'request-failure') { Assert-Test ($script:lastOutput -match 'Failed\s+: 1') 'Request failure must be counted.' }
        else { Assert-Test ($script:lastOutput -match 'Unverified\s+: 1') "$Name must count unverified state." }
    } elseif ($Name -in @('no-match','location-skip')) {
        Assert-Test ($script:posts -eq 0 -and $script:lastOutput -match 'STATUS: No changes') 'No matching licenses must not imply a verified removal.'
    } elseif ($Name -eq 'cancel') {
        Assert-Test ($script:posts -eq 0 -and $script:lastOutput -match 'Cancelled') 'Cancellation must make no writes.'
    } else {
        Assert-Test ($script:posts -eq 0 -and $script:approvals -eq 0) "$Name must stop before approval and writes."
        Assert-Test ($script:lastOutput -match 'STATUS: Stopped') "$Name must report stopped."
        if ($Name -in @('wrong-tenant','invalid-tenant','signin-mismatch')) { Assert-Test ($script:requests -eq 0) "$Name must block tenant data requests." }
        if ($Name -eq 'wrong-tenant') { Assert-Test ($script:disconnects -eq 0) 'Do not silently replace another client session.' }
    }
    Write-Output "PASS: $Mode / $Name"
}
foreach ($caseName in @('success','remaining-license','missing-after','changed-id','request-failure','context-changed','mixed-results','no-match','cancel','wrong-tenant','invalid-tenant','signin-mismatch','new-session','current-user-session','missing-scope','missing-before','inventory-failure','unresolved-user','wrong-upn')) {
    Run-Case $caseName
}
if ($Mode -eq 'Assign') { foreach ($caseName in @('location-write','location-skip','location-failed')) { Run-Case $caseName } }
Write-Output "PASS: Offline $Mode regressions. No real modules, credentials or network calls used."
