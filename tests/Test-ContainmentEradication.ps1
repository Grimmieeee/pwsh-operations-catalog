<# Run only in its own pwsh -NoProfile process. Every service/mutation command is a fixture. #>
[CmdletBinding()]param()
$ErrorActionPreference='Stop'
$path=Join-Path $PSScriptRoot '../published-source/incident-response/IR-INVOKE-CONTAINMENT-ERADICATION.ps1'
$errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)
if($errors.Count){throw ($errors -join "`n")}
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Get-Module {param([switch]$ListAvailable,$Name)
    if($global:Case -eq 'MissingModule'){return}
    [pscustomobject]@{Version=[version]'99.0';Path='fixture'}
}
function Import-Module {[CmdletBinding()]param($Name)}
function Read-Host {param([string]$Prompt,[switch]$AsSecureString)
    $global:Prompts += $Prompt
    if ($AsSecureString) {
        $value=if($global:Case -eq 'PasswordMismatch' -and $Prompt -like 'Confirm*'){'DifferentFixtureValue'}else{'FixtureOnlyNotARealPassword!'}
        return ConvertTo-SecureString $value -AsPlainText -Force
    }
    if($Prompt -like 'Select approved*'){return $global:Selection}
    if($Prompt -like 'Entra Connect server*'){return ''}
    if($Prompt -like 'Select rules*' -or $Prompt -like 'Select user-specific*' -or $Prompt -like 'Select mailbox access*'){return 'A'}
    if($Prompt -like 'Clear mailbox-level*'){return 'Y'}
    if($Prompt -like 'Type * to continue'){
        if($global:Case -eq 'CancelWorkflow' -and $Prompt -like 'Type RESPOND*'){return 'N'}
        if($global:Case -eq 'CancelPhase' -and $Prompt -like 'Type ERADICATE*'){return 'N'}
        if($global:Case -eq 'CancelDisable' -and $Prompt -like 'Type DISABLE *'){return 'N'}
        if($global:Case -eq 'CancelRule' -and $Prompt -like 'Type REMOVE RULES*'){return 'N'}
        return ($Prompt -replace '^Type ','') -replace ' to continue$',''
    }
    throw "Unexpected prompt: $Prompt"
}
function Connect-MgGraph {[CmdletBinding()]param($TenantId,$Scopes,$ContextScope,[switch]$NoWelcome)
    Assert ($ContextScope -eq 'Process') 'Context must be process scoped'
    $global:Scopes=$Scopes
    if($global:Case -eq 'DeclinedAuth'){throw 'Declined'}
}
function Get-MgContext {[CmdletBinding()]param()
    [pscustomobject]@{TenantId=$(if($global:Case -eq 'WrongGraphTenant'){'wrong'}else{'11111111-1111-1111-1111-111111111111'});
    Account='operator@example.invalid';AuthType='Delegated';ContextScope='Process';Environment='Global';Scopes=$global:Scopes}
}
function Disconnect-MgGraph {[CmdletBinding()]param();$global:GraphClosed=$true}
function Invoke-MgGraphRequest {[CmdletBinding()]param($Method,$Uri,$Body,$ContentType,$OutputType)
    if($Method -ne 'GET'){
        $global:Writes+= "$Method $Uri"
        if($Uri -like '*/revokeSignInSessions'){
            if($global:Case -eq 'RevokeFailed'){throw 'Revocation denied'}
            return [pscustomobject]@{value=($global:Case -ne 'RevokeFalse')}
        }
        if($Method -eq 'PATCH'){
            $data=$Body|ConvertFrom-Json
            if ($global:Case -eq 'PasswordFailure') { throw "Simulated rejected body: $Body" }
            if($null -ne $data.accountEnabled -and $global:Case -ne 'DisableUnverified'){$global:AccountEnabled=$data.accountEnabled}
        }
        if($Method -eq 'DELETE'){$global:GrantPresent=$false}
        return
    }
    if($Uri -match '/users\?'){
        if($global:Case -eq 'MissingUser'){return [pscustomobject]@{value=@()}}
        return [pscustomobject]@{value=@([pscustomobject]@{id='22222222-2222-2222-2222-222222222222';userPrincipalName='target@example.invalid';
        displayName='Test User';accountEnabled=$global:AccountEnabled;onPremisesSyncEnabled=($global:Case -eq 'HybridBlocked');onPremisesSecurityIdentifier=$null})}
    }
    if($Uri -like '*/organization?*'){return [pscustomobject]@{value=@([pscustomobject]@{id='11111111-1111-1111-1111-111111111111';displayName='Fixture'})}}
    if($Uri -match '/users/.*/oauth2PermissionGrants'){
        if($global:Case -eq 'OAuthDenied'){throw 'OAuth denied'}
        $grants=if($global:GrantPresent){@([pscustomobject]@{id='grant-fixture';principalId='22222222-2222-2222-2222-222222222222';consentType='Principal';clientId='app-fixture';scope='Mail.Read'})}else{@()}
        return [pscustomobject]@{value=$grants}
    }
    if($Uri -match '/oauth2PermissionGrants/grant-fixture'){
        return [pscustomobject]@{id='grant-fixture';consentType=$(if($global:Case -eq 'TenantWideGrant'){'AllPrincipals'}else{'Principal'});
            principalId=$(if($global:Case -eq 'OtherUsersGrant'){'other-user'}else{'22222222-2222-2222-2222-222222222222'})}
    }
    if($Uri -match '/servicePrincipals/') {return [pscustomobject]@{displayName='Test app';verifiedPublisher=@{displayName='Fixture publisher'}}}
    throw "Unexpected Graph GET: $Uri"
}
function Get-ConnectionInformation {[CmdletBinding()]param()
    if($global:ExoOpened){[pscustomobject]@{ModulePrefix='IRResponse';ConnectionId='owned';State='Connected';
        TenantID=$(if($global:Case -eq 'WrongExoTenant'){'wrong'}else{'11111111-1111-1111-1111-111111111111'})}}
}
function Connect-ExchangeOnline {[CmdletBinding()]param($Prefix,[switch]$ShowBanner)
    Assert ($Prefix -eq 'IRResponse') 'Response prefix missing'
    $global:ExoOpened=$true
}
function Disconnect-ExchangeOnline {[CmdletBinding(SupportsShouldProcess)]param($ConnectionId)
    Assert ($ConnectionId -eq 'owned') 'Unrelated EXO connection closed';$global:ExoClosed=$true
}
function Get-IRResponseMailbox {[CmdletBinding()]param($Identity)
    [pscustomobject]@{ExternalDirectoryObjectId=$(if($global:Case -eq 'WrongMailbox'){'wrong'}else{'22222222-2222-2222-2222-222222222222'});
    ForwardingSmtpAddress=$(if($global:Forwarding){'smtp:forward@example.invalid'}else{$null});ForwardingAddress=$null;
    DeliverToMailboxAndForward=$false;GrantSendOnBehalfTo=@()}
}
function Get-IRResponseInboxRule {[CmdletBinding()]param($Mailbox,[switch]$IncludeHidden)
    if($global:Case -eq 'RuleReadDenied'){throw 'Rule read denied'}
    if($global:RulePresent){[pscustomobject]@{Identity='rule-fixture';Name='Test forwarding';Enabled=$true;IsHidden=$false;Priority=1;
        ForwardTo=@('forward@example.invalid');RedirectTo=@();ForwardAsAttachmentTo=@();DeleteMessage=$false}}
}
function Get-IRResponseMailboxPermission {[CmdletBinding()]param($Identity)
    if($global:AccessPresent){[pscustomobject]@{User='delegate@example.invalid';IsInherited=$false;Deny=$false;AccessRights=@('FullAccess')}}
}
function Remove-IRResponseMailboxPermission {[CmdletBinding(SupportsShouldProcess)]param($Identity,$User,$AccessRights)
    Assert ($User -eq 'delegate@example.invalid') 'Unexpected delegate'
    $global:Writes+='RemoveAccess';$global:AccessPresent=$false
}
function Set-IRResponseCASMailbox {[CmdletBinding()]param($Identity,$ImapEnabled,$PopEnabled,$SmtpClientAuthenticationDisabled)
    Assert (-not $ImapEnabled -and -not $PopEnabled -and $SmtpClientAuthenticationDisabled) 'Protocols not disabled'
    $global:Writes+='DisableLegacy';$global:LegacyPresent=$false
}
function Get-IRResponseRecipientPermission {[CmdletBinding()]param($Identity)}
function Get-IRResponseCASMailbox {[CmdletBinding()]param($Identity)
    [pscustomobject]@{ImapEnabled=$global:LegacyPresent;PopEnabled=$false;SmtpClientAuthenticationDisabled=$true}
}
function Remove-IRResponseInboxRule {[CmdletBinding(SupportsShouldProcess)]param($Mailbox,$Identity)
    Assert ($Mailbox -eq 'target@example.invalid' -and $Identity -eq 'rule-fixture') 'Unexpected rule target'
    $global:Writes+='RemoveRule';$global:RulePresent=$false
}
function Set-IRResponseMailbox {[CmdletBinding()]param($Identity,$ForwardingAddress,$ForwardingSmtpAddress,$DeliverToMailboxAndForward)
    $global:Writes+='ClearForwarding';$global:Forwarding=$false
}
$cases=@{
    PasswordReset=@('3',1); PasswordMismatch=@('3,4',0); PasswordFailure=@('3,4',1); RemoveAccess=@('6',1); DisableLegacy=@('7',1);
    NoChange=@('N',0); CancelWorkflow=@('4',0); CancelPhase=@('4',0); CancelRule=@('4',0);
    RemoveRule=@('4',1); ClearForwarding=@('4',1); RevokeThenRule=@('1,4',2);
    RevokeFailed=@('1,4',1); RevokeFalse=@('1,4',1); CancelDisable=@('2,4',0);
    DisableUnverified=@('2,4',1); DisableThenRule=@('2,4',2);
    HybridBlocked=@('2,4',0); WrongGraphTenant=@('4',0); WrongExoTenant=@('4',0); WrongMailbox=@('4',0);
    MissingUser=@('4',0); MissingModule=@('4',0); DeclinedAuth=@('4',0); RuleReadDenied=@('4',0);
    OAuthDenied=@('5',0); RemoveGrant=@('5',1); TenantWideGrant=@('5',0); OtherUsersGrant=@('5',0)
}
foreach($name in ($cases.Keys|Sort-Object)){
    $global:Case=$name;$global:Selection=$cases[$name][0];$global:Writes=@();$global:Prompts=@()
    $global:AccessPresent=$name -eq 'RemoveAccess'; $global:LegacyPresent=$name -eq 'DisableLegacy'
    $global:AccountEnabled=$true;$global:ExoOpened=$false;$global:ExoClosed=$false;$global:GraphClosed=$false
    $global:RulePresent=$name -notin @('ClearForwarding','OAuthDenied','RemoveGrant','TenantWideGrant','OtherUsersGrant')
    $global:Forwarding=$name -eq 'ClearForwarding'
    $global:GrantPresent=$name -in @('RemoveGrant','TenantWideGrant','OtherUsersGrant')
    $out=(& $path -UPN 'target@example.invalid' -Tenant '11111111-1111-1111-1111-111111111111' -NoPause 6>&1 | Out-String)
    Assert ($global:Writes.Count -eq $cases[$name][1]) "$name mutation count wrong ($($global:Writes -join ', ')): $out"
    Assert (-not $out.Contains('FixtureOnlyNotARealPassword!')) "$name exposed password in output"
    Assert (-not $out.Contains('Unexpected')) "$name unexpected fixture call: $out"
    if($name -in @('RevokeFailed','RevokeFalse','CancelDisable','DisableUnverified','HybridBlocked','PasswordMismatch','PasswordFailure')){
        Assert (-not ($global:Prompts -like 'Type ERADICATE*')) "$name reached cleanup confirmation despite incomplete containment"
        Assert ($global:Writes -notcontains 'RemoveRule') "$name removed rule after failed containment"
    }
    if($name -eq 'RevokeThenRule'){Assert ($global:Writes[0] -like 'POST*' -and $global:Writes[1] -eq 'RemoveRule') 'Wrong phase order'}
    if($name -eq 'DisableThenRule'){Assert ($out.Contains('ACCOUNT CONTAINED - RECOVERY NOT YET AUTHORIZED')) "Disable verification failed: $out"}
    if($name -eq 'HybridBlocked'){Assert ($out.Contains('Synced SID unavailable')) "Missing SID not reported: $out"}
    if($name -in @('RuleReadDenied','OAuthDenied')){Assert ($out.Contains('RESPONSE VALIDATION INCOMPLETE')) "$name treated unavailable evidence as clear: $out"}
    if($global:ExoOpened){Assert $global:ExoClosed "$name left owned EXO session open"}
    if($name -notin @('MissingModule','DeclinedAuth')){Assert $global:GraphClosed "$name left Graph open"}
    Write-Host "PASS $name"
}
# Load helper declarations only for targeted security-boundary tests, never the operational entry point.
foreach($name in @('Assert-GraphEndpoint','Convert-SelectionToNumbers')){
    $fn=$ast.Find({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
    . ([scriptblock]::Create($fn.Extent.Text))
}
$blocked=$false;try{Assert-GraphEndpoint 'https://example.invalid/collect'}catch{$blocked=$true}
Assert $blocked 'External Graph URI accepted'
Assert ((@(Convert-SelectionToNumbers '1,1,7,99,abc' 7) -join ',') -eq '1,7') 'Selection parser failed'
Write-Host 'PASS EndpointBoundary'
Write-Host 'PASS SelectionParser'
Write-Host 'PASS PowerShellParser'

# Independently exercise sync request failure gates without any remote execution.
foreach($name in @('Add-UniqueText','Add-DataGap','Add-Action','Write-Ok','Write-Fail','Get-ShortError','Invoke-DeltaSyncOnce','Confirm-EradicationGate','Write-Warn','Confirm-Exact')){
    $fn=$ast.Find({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
    . ([scriptblock]::Create($fn.Extent.Text))
}
function Invoke-Command {[CmdletBinding()]param($ComputerName,$ScriptBlock)
    if($global:SyncCase -eq 'Exception'){throw 'Remote failure'}
    [pscustomobject]@{Result=$global:SyncCase}
}
foreach($syncCase in @('Success','Busy','Exception')){
    $global:SyncCase=$syncCase
    $script:AdChanged=$true; $script:ResolvedSyncServer='sync.example.invalid'
    $script:ActionLog=New-Object System.Collections.ArrayList
    $script:Phase='Containment';$script:ContainmentBlocked=$false
    Invoke-DeltaSyncOnce 6>$null
    Assert (($syncCase -eq 'Success') -eq (-not $script:ContainmentBlocked)) "Sync $syncCase gate wrong"
    Write-Host "PASS Sync$syncCase"
}

# Prompt regression: a partial phrase never authorizes; retry or explicit cancel only.
foreach($name in @('Confirm-Exact','Test-EntraConnectServer')){
    $fn=$ast.Find({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
    . ([scriptblock]::Create($fn.Extent.Text))
}
function Read-Host {param($Prompt)
    if($global:Answers.Count -eq 0){throw 'Unexpected extra confirmation prompt'}
    return $global:Answers.Dequeue()
}
foreach($test in @(
    @{Name='PartialThenExact';Values=@('RESPOND','RESPOND target@example.invalid');Expected=$true},
    @{Name='PartialThenCancel';Values=@('RESPOND','');Expected=$false},
    @{Name='ExplicitCancel';Values=@('N');Expected=$false}
)){
    $global:Answers=New-Object System.Collections.Queue
    foreach($answer in $test.Values){$global:Answers.Enqueue($answer)}
    $accepted=Confirm-Exact 'RESPOND target@example.invalid' 6>$null
    Assert ($accepted -eq $test.Expected -and $global:Answers.Count -eq 0) "Confirmation regression: $($test.Name)"
    Write-Host "PASS $($test.Name)"
}
function Invoke-Command {[CmdletBinding()]param($ComputerName,$ScriptBlock)
    $global:PreflightCalls++
    if($global:PreflightDenied){throw 'Fixture remoting access denied'}
}
$global:PreflightCalls=0;$global:PreflightDenied=$false
Assert (-not (Test-EntraConnectServer '') -and $global:PreflightCalls -eq 0 -and $script:SyncPreflightError -like '*No*configured*') 'Blank server diagnostic wrong'
Write-Host 'PASS BlankSyncServer'
Assert (Test-EntraConnectServer 'sync.example.invalid') 'Reachable preflight rejected'
Write-Host 'PASS SyncPreflightAvailable'
$global:PreflightDenied=$true
Assert (-not (Test-EntraConnectServer 'sync.example.invalid') -and $script:SyncPreflightError -like '*Fixture remoting access denied*') 'Preflight diagnostic lost'
Write-Host 'PASS SyncPreflightReason'

# Saved mappings must be tenant-specific; no fallback to another tenant or to the target UPN.
$name='Get-SyncServerForTarget'
$fn=$ast.Find({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
. ([scriptblock]::Create($fn.Extent.Text))
$previous=[Environment]::GetEnvironmentVariable('FIELD_KIT_SYNC_SERVERS','Process')
try {
    [Environment]::SetEnvironmentVariable('FIELD_KIT_SYNC_SERVERS','{"example.invalid":"sync.example.invalid","other.invalid":"other-sync.example.invalid"}','Process')
    Assert ((Get-SyncServerForTarget -TenantDomain 'example.invalid') -eq 'sync.example.invalid') 'Verified-domain mapping not selected'
    Assert ([string]::IsNullOrEmpty((Get-SyncServerForTarget -TenantDomain 'missing.invalid'))) 'Another tenant server was reused'
    Assert ((Get-SyncServerForTarget -TenantDomain 'example.invalid' -ExplicitServer 'override.example.invalid') -eq 'override.example.invalid') 'Explicit override not honored'
    Write-Host 'PASS TenantMappedSyncServer'
    Write-Host 'PASS UnmappedTenantBlocked'
    Write-Host 'PASS ExplicitSyncOverride'
}
finally { [Environment]::SetEnvironmentVariable('FIELD_KIT_SYNC_SERVERS',$previous,'Process') }
