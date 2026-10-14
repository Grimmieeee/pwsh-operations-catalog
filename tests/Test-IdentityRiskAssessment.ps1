<# Run in a fresh pwsh -NoProfile process. All service and module calls are mocked.
No tenant connection, module installation, or production changes occur. #>
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '../published-source/incident-response/IR-GET-IDENTITY-RISK-ASSESSMENT.ps1'
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw ($errors -join "`n") }
function Assert($Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
# Stubs shadow real commands only inside this test process.
function Get-Module { param([switch]$ListAvailable, $Name)
    if ($global:Case -eq 'MissingModule') { return }
    [pscustomobject]@{ Version = [version]'99.0.0'; Path = 'fixture-module' }
}
function Import-Module { [CmdletBinding()]param($Name) }
function Connect-MgGraph { [CmdletBinding()]param($TenantId, $Scopes, $ContextScope, [switch]$NoWelcome)
    $global:Scopes = $Scopes
    Assert ($ContextScope -eq 'Process') 'Graph must use Process context'
    if ($global:Case -eq 'DeclinedGraph') { throw 'Authentication declined' }
}
function Get-MgContext {
    [pscustomobject]@{ TenantId = '11111111-1111-1111-1111-111111111111'; Account = 'operator@example.invalid';
        AuthType = 'Delegated'; Environment = 'Global'; ContextScope = 'Process';
        Scopes = $(if ($global:Case -eq 'MissingScope') { @('User.Read.All') } else { $global:Scopes }) }
}
function Disconnect-MgGraph { [CmdletBinding()]param(); $global:GraphDisconnected = $true }
function Invoke-MgGraphRequest { [CmdletBinding()]param($Method, $Uri, $OutputType)
    Assert ($Method -eq 'GET') 'Only GET requests are permitted'
    $global:Requests += $Uri
    if ($Uri -match '/domains\?') {
        if ($global:Case -eq 'DomainFailure') { throw 'Domains denied' }
        return [pscustomobject]@{ value = @([pscustomobject]@{ id = 'example.invalid'; isVerified = $true }) }
    }
    if ($Uri -match '/users\?') {
        if ($global:Case -eq 'MissingUser') { return [pscustomobject]@{value=@()} }
        return [pscustomobject]@{ value = @([pscustomobject]@{id='22222222-2222-2222-2222-222222222222';
            userPrincipalName='target@example.invalid'; accountEnabled=$true; onPremisesSyncEnabled=$false}) }
    }
    if ($Uri -match 'signInActivity') { return [pscustomobject]@{signInActivity=@{lastSignInDateTime=(Get-Date).ToUniversalTime().ToString('o')}} }
    if ($Uri -match '/authentication/methods') {
        if ($global:Case -eq 'MfaDenied') { throw '403 authentication methods denied' }
        return [pscustomobject]@{value=@([pscustomobject]@{'@odata.type'='#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'})}
    }
    if ($Uri -match '/transitiveMemberOf/') {
        if ($global:Case -eq 'HighRiskRole') { return [pscustomobject]@{value=@([pscustomobject]@{displayName='Global Administrator'})} }
        return [pscustomobject]@{value=@()}
    }
    if ($Uri -match '/oauth2PermissionGrants') {
        if ($global:Case -eq 'TruncatedOAuth') {
            return [pscustomobject]@{value=@(); '@odata.nextLink'='https://graph.microsoft.com/v1.0/oauth2PermissionGrants?$skiptoken=next'}
        }
        return [pscustomobject]@{value=@()}
    }
    if ($Uri -match '/auditLogs/signIns|/conditionalAccess/policies') { return [pscustomobject]@{value=@()} }
    throw "Unexpected request: $Uri"
}
function Get-ConnectionInformation { [CmdletBinding()]param()
    if ($global:ExoOpened) {
        [pscustomobject]@{ModulePrefix='IRAssessment'; ConnectionId='owned-fixture'; State='Connected';
            TenantID=$(if ($global:Case -eq 'WrongExoTenant') {'33333333-3333-3333-3333-333333333333'} else {'11111111-1111-1111-1111-111111111111'})}
    }
    [pscustomobject]@{ModulePrefix='Other';ConnectionId='unrelated-fixture';State='Connected';TenantID='other'}
}
function Connect-ExchangeOnline { [CmdletBinding()]param($Prefix,[switch]$ShowBanner)
    Assert ($Prefix -eq 'IRAssessment') 'Exchange prefix missing'
    if ($global:Case -eq 'ExchangeDenied') { throw 'Exchange access denied' }
    $global:ExoOpened=$true
}
function Disconnect-ExchangeOnline { [CmdletBinding(SupportsShouldProcess)]param($ConnectionId)
    Assert ($ConnectionId -eq 'owned-fixture') 'Unrelated connection disconnected'
    $global:ExoDisconnected=$true
}
function Get-IRAssessmentMailbox { [CmdletBinding()]param($Identity)
    $global:MailboxReads++
    [pscustomobject]@{ExternalDirectoryObjectId=$(if($global:Case -eq 'WrongMailbox'){'wrong'}else{'22222222-2222-2222-2222-222222222222'});
        ForwardingSmtpAddress=$null;ForwardingAddress=$null;GrantSendOnBehalfTo=@()}
}
function Get-IRAssessmentCASMailbox { [CmdletBinding()]param($Identity)
    $global:DetailReads++
    [pscustomobject]@{PopEnabled=$false;ImapEnabled=$false;SmtpClientAuthenticationDisabled=$true}
}
function Get-IRAssessmentInboxRule { [CmdletBinding()]param($Mailbox,[switch]$IncludeHidden)
    $global:DetailReads++
    Assert $IncludeHidden 'Hidden rule coverage missing'
    if ($global:Case -eq 'RuleDenied') { throw 'Rules denied' }
    if ($global:Case -eq 'HighRiskRule') {
        [pscustomobject]@{Name='Suspicious rule';Enabled=$true;DeleteMessage=$true;IsHidden=$true}
    }
}
function Get-IRAssessmentMailboxPermission { [CmdletBinding()]param($Identity); $global:DetailReads++ }
function Get-IRAssessmentRecipientPermission { [CmdletBinding()]param($Identity); $global:DetailReads++ }
$cases = @{
    Clean='SUMMARY: NO HIGH-RISK FINDINGS'; HighRiskRole='SUMMARY: HIGH RISK'; HighRiskRule='SUMMARY: HIGH RISK';
    MfaDenied='SUMMARY: REVIEW REQUIRED'; ExchangeDenied='SUMMARY: REVIEW REQUIRED'; RuleDenied='SUMMARY: REVIEW REQUIRED';
    WrongExoTenant='SUMMARY: REVIEW REQUIRED'; WrongMailbox='SUMMARY: REVIEW REQUIRED'; SkipExchange='SUMMARY: REVIEW REQUIRED';
    TruncatedOAuth='SUMMARY: REVIEW REQUIRED'; MissingUser='[FAIL]'; MissingScope='[FAIL]'; DomainFailure='[FAIL]';
    WrongGraphTenant='[FAIL]'; DeclinedGraph='[FAIL]'; MissingModule='[FAIL]'
}
foreach ($name in ($cases.Keys | Sort-Object)) {
    $global:Case=$name; $global:Requests=@(); $global:ExoOpened=$false
    $global:GraphDisconnected=$false; $global:ExoDisconnected=$false
    $global:MailboxReads=0; $global:DetailReads=0
    $tenant = if ($name -eq 'WrongGraphTenant') { '44444444-4444-4444-4444-444444444444' } else { 'example.invalid' }
    $options=@{UserPrincipalName='target@example.invalid';Tenant=$tenant;NoPause=$true;SkipExchange=($name -eq 'SkipExchange')}
    $output = (& $scriptPath @options 6>&1 | Out-String)
    Assert ($output.Contains($cases[$name])) "$name failed: $output"
    if ($name -ne 'Clean') { Assert (-not $output.Contains('SUMMARY: NO HIGH-RISK FINDINGS')) "$name reported a false clean result" }
    if ($name -in @('WrongExoTenant','WrongMailbox')) { Assert ($global:DetailReads -eq 0) "$name queried unvalidated mailbox details" }
    if ($name -eq 'WrongExoTenant') { Assert ($global:MailboxReads -eq 0) 'Wrong tenant queried mailbox' }
    if ($name -in @('WrongGraphTenant','MissingScope','DomainFailure','MissingUser','DeclinedGraph','MissingModule')) {
        Assert (-not $global:ExoOpened) "$name continued into Exchange"
    }
    if ($name -notin @('MissingModule','DeclinedGraph')) { Assert $global:GraphDisconnected "$name left Graph open" }
    if ($global:ExoOpened) { Assert $global:ExoDisconnected "$name left owned Exchange connection open" }
    Write-Host "PASS $name"
}
# Exercise pagination endpoint guard without running the assessment again.
foreach ($functionName in @('GraphError','GraphGet','GraphGetAll')) {
    $node=$ast.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $functionName},$true)
    . ([scriptblock]::Create($node.Extent.Text))
}
$global:Requests=@()
$result=GraphGet 'https://example.invalid/collect' @{}
Assert (-not $result.Ok -and $global:Requests.Count -eq 0) 'Foreign Graph endpoint was not blocked'
Write-Host 'PASS ForeignEndpoint'
Write-Host 'PASS Parser'
