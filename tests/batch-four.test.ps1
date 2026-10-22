#Requires -Version 5.1
param([string]$Root=(Split-Path $PSScriptRoot -Parent),[Parameter(Mandatory)][string]$Focus)
$ErrorActionPreference='Stop'
function Assert-FK([bool]$Condition,[string]$Message) { if(-not $Condition){throw $Message} }
function Get-FKAst([string]$Relative){
 $e=$null;$t=$null;$a=[Management.Automation.Language.Parser]::ParseFile((Join-Path $Root $Relative),[ref]$t,[ref]$e)
 if($e.Count){throw "Parse failed: $Relative"};return $a
}
# Dot-source this loader so the actual source functions occupy the test scope.
function Import-FKFunctions([string]$Relative){
 $a=Get-FKAst $Relative
 foreach($f in $a.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)){. ([scriptblock]::Create($f.Extent.Text))}
 $main=@($a.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.TryStatementAst]})
 if($main.Count){$script:FKMain=[scriptblock]::Create($main[-1].Extent.Text)}
}
function Pass-FK([string]$Case){Write-Output ('PASS: '+$Focus+' / '+$Case)}
function Capture-FK([scriptblock]$Block){return ((& $Block 6>&1|ForEach-Object {[string]$_}) -join "`n")}
# Network boundaries fail closed unless a particular suite installs its fixture.
function Invoke-MgGraphRequest {throw 'Unexpected Graph call blocked by offline suite.'}
function Invoke-WebRequest {throw 'Network blocked by offline suite.'}
function Invoke-RestMethod {throw 'Network blocked by offline suite.'}
function Import-Module {throw 'Module import blocked by offline suite.'}
function Start-Sleep {}

switch($Focus){
 'Disable' { & {
  . Import-FKFunctions 'published-source/identity/INVOKE-DISABLE-ACCOUNTS.ps1'
  function Connect-GraphAuto {}
  function Pause-End {}
  function Resolve-ADUser {return $null}
  function Offer-ExportCsv {param($Rows)$script:FKRows=@($Rows)}
  function Get-GraphUser {param($UPN)
   if($script:FKCase -eq 'lookup-failed' -or ($script:FKCase -eq 'readback-failed' -and $script:FKWrites)){throw 'Synthetic read unavailable'}
   @{id='fixture-user';userPrincipalName='user@example.invalid';accountEnabled=($script:FKCase -ne 'already-disabled' -and (-not $script:FKWrites -or $script:FKCase -eq 'unchanged'));onPremisesSyncEnabled=($script:FKCase -eq 'unresolved-hybrid')}
  }
  function Invoke-GraphPatch {param($Uri,$Body)
   $script:FKWrites++;Assert-FK ($Uri.EndsWith('/fixture-user') -and $Body.accountEnabled -eq $false) 'Wrong disable mutation.'
   if($script:FKCase -eq 'write-failed'){throw 'Synthetic write denied'}
  }
  function Read-Host {param($Prompt)
   if($Prompt -like 'Type DISABLE*'){if($script:FKCase -eq 'cancel'){return 'CANCEL'};return 'DISABLE'}
   if($Prompt -like '*[Y/N]*'){return 'N'}
   throw "Unexpected prompt: $Prompt"
  }
  foreach($case in @('success','cancel','already-disabled','lookup-failed','write-failed','unchanged','readback-failed','unresolved-hybrid')){
   $script:FKCase=$case;$script:FKWrites=0;$script:FKRows=@();$InputObject=@('user@example.invalid');$InputPath=$null;$RevokeSessions=$false
   $text=Capture-FK $script:FKMain
   if($case -eq 'success'){Assert-FK ($script:FKWrites -eq 1 -and $script:FKRows[0].Result -eq 'Complete') "Disable success failed: $text"}
   elseif($case -in @('write-failed','unchanged','readback-failed')){Assert-FK ($script:FKWrites -eq 1 -and $script:FKRows[0].Result -eq 'Failed') "Disable false success: $case / $text"}
   else {Assert-FK ($script:FKWrites -eq 0) "Unsafe disable: $case"}
   Pass-FK $case
  }
 } }
 'MFA' { & {
  . Import-FKFunctions 'published-source/identity/INVOKE-ENFORCE-PER-USER-MFA.ps1'
  function Ensure-Graph {}
  function Pause-End {}
  function Offer-VerifiedCsv {param($Rows,$DefaultName)$script:FKRows=@($Rows)}
  function Get-UserRecord {param($UPN)if($script:FKCase -eq 'lookup-failed'){throw 'Synthetic lookup denied'};@{id='fixture-user';displayName='Fixture';userPrincipalName='user@example.invalid';accountEnabled=$true}}
  function Get-MfaState {param($UserId)
   if($script:FKCase -eq 'readback-failed' -and $script:FKWrites){throw 'Synthetic read denied'}
   @{perUserMfaState=$(if($script:FKCase -eq 'already-enforced' -or ($script:FKWrites -and $script:FKCase -notin @('unchanged','write-failed'))){'enforced'}else{'disabled'})}
  }
  function Get-AuthenticationMethods {@('Authenticator')}
  function Invoke-MgGraphRequest {[CmdletBinding()]param($Method,$Uri,$Body,$ContentType)
   $script:FKWrites++;Assert-FK ($Method -eq 'PATCH' -and $Uri.EndsWith('/fixture-user/authentication/requirements') -and ($Body|ConvertFrom-Json).perUserMfaState -eq 'enforced') 'Wrong MFA mutation.'
   if($script:FKCase -eq 'write-failed'){throw 'Synthetic write denied'}
  }
  function Read-Host {param($Prompt)if($Prompt -like 'Type ENFORCE*'){if($script:FKCase -eq 'cancel'){return 'CANCEL'};return 'ENFORCE'};throw "Unexpected prompt: $Prompt"}
  foreach($case in @('success','cancel','already-enforced','lookup-failed','write-failed','unchanged','readback-failed')){
   $script:FKCase=$case;$script:FKWrites=0;$script:FKRows=@();$InputObject=@('user@example.invalid');$InputPath=$null;$TenantDomain='example.invalid'
   $text=Capture-FK $script:FKMain
   if($case -eq 'success'){Assert-FK ($script:FKWrites -eq 1 -and $script:FKRows[0].Result -eq 'Changed') "MFA success failed: $text"}
   elseif($case -in @('write-failed','unchanged','readback-failed')){Assert-FK ($script:FKWrites -eq 1 -and $script:FKRows[0].Result -match 'Failed') "MFA false success: $case / $text"}
   else{Assert-FK ($script:FKWrites -eq 0) "Unsafe MFA change: $case"}
   Pass-FK $case
  }
 } }
 'Hold' { & {
  . Import-FKFunctions 'published-source/mailbox/INVOKE-LITIGATION-HOLD.ps1'
  function Connect-ExchangeAuto {}
  function Pause-End {}
  function Offer-ExportCsv {param($Rows,$DefaultName)$script:FKRows=@($Rows)}
  function Get-HoldState {param($UPN)
   if($script:FKCase -eq 'lookup-failed' -or ($script:FKCase -eq 'readback-failed' -and $script:FKWrites)){throw 'Synthetic mailbox read denied'}
   $ready=$script:FKCase -eq 'compliant' -or ($script:FKWrites -and $script:FKCase -notin @('unchanged','write-failed'))
   @{UPN='user@example.invalid';DisplayName='Fixture';Enabled=$ready;Unlimited=$ready;Duration=$(if($ready){'Unlimited'}else{'30'});HoldOwner='Fixture';Action=$(if($ready){'Compliant'}elseif($script:FKCase -eq 'duration-only'){'SetUnlimited'}else{'EnableUnlimited'})}
  }
  function Set-Mailbox {[CmdletBinding()]param($Identity,$LitigationHoldEnabled,$LitigationHoldDuration,$LitigationHoldOwner)
   $script:FKWrites++;Assert-FK ($Identity -eq 'user@example.invalid' -and $LitigationHoldDuration -eq 'Unlimited') 'Wrong hold mutation.'
   if($script:FKCase -eq 'write-failed'){throw 'Synthetic hold denied'}
  }
  function Read-Host {param($Prompt)if($Prompt -like 'Type HOLD*'){if($script:FKCase -eq 'cancel'){return 'CANCEL'};return 'HOLD'};throw "Unexpected prompt: $Prompt"}
  foreach($case in @('success','duration-only','cancel','compliant','lookup-failed','write-failed','unchanged','readback-failed')){
   $script:FKCase=$case;$script:FKWrites=0;$script:FKRows=@();$InputObject=@('user@example.invalid');$InputPath=$null;$TicketNumber='SYNTHETIC';$HoldOwner='Fixture'
   $text=Capture-FK $script:FKMain
   if($case -in @('success','duration-only')){Assert-FK ($script:FKWrites -eq 1 -and $script:FKRows[0].Result -eq 'Complete') "Hold success failed: $text"}
   elseif($case -in @('write-failed','unchanged','readback-failed')){Assert-FK ($script:FKWrites -eq 1 -and $script:FKRows[0].Result -eq 'Failed') "Hold false success: $case / $text"}
   else {Assert-FK ($script:FKWrites -eq 0) "Unsafe hold change: $case"}
   Pass-FK $case
  }
 } }
 'Delete' { & {
  . Import-FKFunctions 'published-source/identity/INVOKE-DELETE-ACCOUNTS.ps1'
  function Get-MgUser {[CmdletBinding()]param($UserId,$Property)
   $script:FKReads++;Assert-FK ($UserId -eq 'exact@example.invalid') 'Deletion lookup changed the exact target.'
   switch($script:FKCase){'absent'{throw 'Request_ResourceNotFound'};'denied'{throw 'Authorization_RequestDenied'};'transient'{if($script:FKReads -lt 3){throw 'Synthetic throttling'};throw 'Request_ResourceNotFound'};default{@{id='fixture';userPrincipalName=$UserId}}}
  }
  foreach($case in @('present','absent','denied','transient')){
   $script:FKCase=$case;$script:FKReads=0;$state=Test-GraphUserAbsent -UserId 'exact@example.invalid'
   Assert-FK ($state.Absent -eq ($case -in @('absent','transient'))) "Wrong deletion absence: $case"
   Assert-FK ($state.Validated -eq ($case -ne 'denied')) "Denied read became verified: $case"
   Assert-FK ($script:FKReads -le 6) 'Unbounded absence polling.';Pass-FK $case
  }
  foreach($case in @('present','absent','denied')){
   $script:FKCase=$case;$script:FKReads=0;$threw=$false;$found=$null
   try{$found=Get-ExactGraphUser -UPN 'exact@example.invalid'}catch{$threw=$true}
   Assert-FK ($threw -eq ($case -eq 'denied')) 'Access denied treated as absent.'
   if($case -eq 'absent'){Assert-FK ($null -eq $found) 'Not-found lookup returned a user.'};Pass-FK ('lookup-'+$case)
  }
 } }
 'Groups' { & {
  . Import-FKFunctions 'published-source/identity/INVOKE-REMOVE-USER-GROUPS.ps1'
  function Invoke-MgGraphRequest {[CmdletBinding()]param($Method,$Uri)
   $script:FKWrites++;Assert-FK ($Method -eq 'DELETE' -and $Uri -ceq 'https://graph.microsoft.com/v1.0/groups/group-id/members/user-id/$ref') 'Group membership DELETE could target the object.'
   if($script:FKCase -eq 'denied'){throw 'Synthetic permission denied'}
  }
  function Get-GraphGroups {param($UserId)$script:FKReads++;if($script:FKCase -eq 'read-denied'){throw 'Synthetic read denied'};if($script:FKCase -eq 'present' -or ($script:FKCase -eq 'eventual' -and $script:FKReads -lt 3)){[pscustomobject]@{Id='group-id'}}}
  foreach($case in @('removed','present','eventual','read-denied')){
   $script:FKCase=$case;$script:FKReads=0;$threw=$false;$result=$false
   try{$result=Wait-EntraGroupRemoval -UserId 'user-id' -GroupId 'group-id'}catch{$threw=$true}
   Assert-FK ($threw -eq ($case -eq 'read-denied')) 'Group read error became absent.'
   Assert-FK ($result -eq ($case -in @('removed','eventual'))) "Wrong removal state: $case";Assert-FK ($script:FKReads -le 6) 'Unbounded group polling.';Pass-FK $case
  }
  foreach($case in @('write','denied')){$script:FKCase=$case;$script:FKWrites=0;$threw=$false;try{Remove-EntraGroup -UserId 'user-id' -GroupId 'group-id'}catch{$threw=$true};Assert-FK ($script:FKWrites -eq 1 -and $threw -eq ($case -eq 'denied')) 'Removal write failure hidden.';Pass-FK $case}
 } }
 'Cleanup' { & {
  . Import-FKFunctions 'published-source/mailbox/CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1'
  $set=@{};Add-TargetPrincipalAlias -Set $set -Value 'SMTP:User@Example.Invalid'
  foreach($case in @(@('user@example.invalid',$true),@(' SMTP:USER@example.invalid ',$true),@('other@example.invalid',$false),@('user@example.invalid.evil',$false),@('user',$false),@('',$false))){Assert-FK ((Test-PrincipalMatchesTarget -Principal $case[0] -TargetSet $set) -eq $case[1]) 'Principal match mismatch.';Pass-FK ('principal-'+$case[0])}
  $object=[pscustomobject]@{PrimarySmtpAddress='user@example.invalid';Alias='unrelated'}
  Assert-FK (Test-PrincipalMatchesTarget -Principal $object -TargetSet $set) 'Structured recipient not matched.';Pass-FK 'recipient-object'
  $mailbox=[pscustomobject]@{GrantSendOnBehalfTo=@('user@example.invalid','other@example.invalid')}
  Assert-FK (@(Get-SendOnBehalfMatch -Mailbox $mailbox -TargetSet $set).Count -eq 1) 'SendOnBehalf selected unrelated principal.';Pass-FK 'send-on-behalf-isolation'
 } }
 'Recovery' { & {
  . Import-FKFunctions 'published-source/incident-response/IR-INVOKE-EMAIL-RECOVERY.ps1'
  function Invoke-GraphPost {param($Uri,$Body)$script:FKUri=$Uri;$script:FKBody=$Body;$script:FKWrites++;if($script:FKCase -eq 'denied'){throw 'Synthetic write denied'};@{id='new-message'}}
  foreach($case in @('success','denied')){
   $script:FKCase=$case;$script:FKWrites=0;$threw=$false
   try{Move-MailMessage -MailboxUPN 'user+test@example.invalid' -MessageId 'a/b+=' -DestinationId 'target-id'|Out-Null}catch{$threw=$true}
   Assert-FK ($threw -eq ($case -eq 'denied') -and $script:FKWrites -eq 1) 'Recovery write failure hidden.'
   Assert-FK ($script:FKUri -match 'messages/a%2Fb%2B%3D/move$' -and $script:FKBody.destinationId -eq 'target-id') 'Message route or destination changed.';Pass-FK ('move-'+$case)
  }
  foreach($name in @('Recovered','nested/folder','nested\folder')){$script:FKCase='success';$script:FKWrites=0;$threw=$false;try{New-RootMailFolder -MailboxUPN 'user@example.invalid' -FolderName $name|Out-Null}catch{$threw=$true};Assert-FK ($threw -eq ($name -ne 'Recovered')) 'Unsupported folder creation accepted.';Assert-FK ($script:FKWrites -eq $(if($name -eq 'Recovered'){1}else{0})) 'Invalid path caused a write.';Pass-FK ('folder-'+$name)}
 } }
 'Drift' { & {
  . Import-FKFunctions 'published-source/tenant/GET-TENANT-DRIFT-REVIEW.ps1'
  $a=[pscustomobject]@{Key='a';Hash='one'};$b=[pscustomobject]@{Key='b';Hash='two'};$changed=[pscustomobject]@{Key='a';Hash='changed'}
  foreach($case in @('same','added','removed','changed','empty')){
   $before=@($a);$after=@($a);$expected=@(0,0,0)
   switch($case){'added'{$after=@($a,$b);$expected=@(1,0,0)};'removed'{$after=@();$expected=@(0,1,0)};'changed'{$after=@($changed);$expected=@(0,0,1)};'empty'{$before=@();$after=@()}}
   $result=Compare-KeyedSection -Name 'fixture' -Baseline $before -Current $after -HashProperty Hash
   Assert-FK ($result.Added.Count -eq $expected[0] -and $result.Removed.Count -eq $expected[1] -and $result.Changed.Count -eq $expected[2]) "Wrong drift classification: $case";Pass-FK $case
  }
  $path=Join-Path ([IO.Path]::GetTempPath()) ('fk-baseline-'+[guid]::NewGuid().ToString('N')+'.json')
  try{$snapshot=[pscustomobject]@{Metadata=@{TenantId='fixture-tenant'};Items=@('fixture')};$round=Write-VerifiedBaseline -Snapshot $snapshot -Path $path;Assert-FK ($round.Metadata.TenantId -eq 'fixture-tenant') 'Baseline roundtrip failed.';Pass-FK 'baseline-write-read'}finally{Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}
 } }
 'Modules' { & {
  . Import-FKFunctions 'published-source/utility/INSTALL-M365-MODULES.ps1'
  function Pause-End {}
  function Get-Command {[CmdletBinding()]param($Name)@{Name=$Name}}
  function Get-LatestModule {param($Name)if($script:FKCase -ne 'missing-after' -or -not $script:FKWrites){@{Version='1.0'}}}
  function Install-Module {[CmdletBinding()]param($Name,$Scope,$Repository,[switch]$Force,[switch]$AllowClobber)
   $script:FKWrites++;Assert-FK ($Scope -eq 'CurrentUser' -and $Repository -eq 'PSGallery') 'Module install scope changed.'
   if($script:FKCase -eq 'denied'){throw 'Synthetic installation denied'}
  }
  function Read-Host {param($Prompt)if($Prompt -like 'Type INSTALL*'){if($script:FKCase -eq 'cancel'){return 'CANCEL'};return 'INSTALL'};throw 'Unexpected module prompt.'}
  foreach($case in @('success','cancel','denied','missing-after')){
   $script:FKCase=$case;$script:FKWrites=0;$ModuleSet='Both';$NoPause=$true;$text=Capture-FK $script:FKMain
   if($case -eq 'success'){Assert-FK ($script:FKWrites -eq 2 -and $text -match 'module setup complete') "Module success failed: $text"}
   elseif($case -eq 'cancel'){Assert-FK ($script:FKWrites -eq 0) 'Cancelled module install executed.'}
   else {Assert-FK ($script:FKWrites -eq 1 -and $text -notmatch '\[OK\].*setup complete') "Module false success: $text"};Pass-FK $case
  }
 } }
 {$_ -in @('Session','JumpboxSession')} { & {
  $path=if($Focus -eq 'Session'){'published-source/utility/RESET-M365-SESSION.ps1'}else{'tools/INVOKE-SESSION-RESET.ps1'}
  . Import-FKFunctions $path
  function Pause-End {}
  function Get-Command {[CmdletBinding()]param($Name)@{Name=$Name}}
  function Read-Host {param($Prompt)if($Prompt -like 'Run session reset*'){if($script:FKCase -eq 'cancel'){return 'N'};return 'Y'};return 'N'}
  function Disconnect-ExchangeOnline {[CmdletBinding()]param([switch]$Confirm)$script:FKWrites++;if($script:FKCase -eq 'disconnect-failed'){throw 'Synthetic disconnect failed'}}
  function Disconnect-MgGraph {[CmdletBinding()]param()$script:FKWrites++}
  function Get-PSSession {[CmdletBinding()]param()@([pscustomobject]@{Id=1;ConfigurationName='Microsoft.Exchange';ComputerName='outlook.example.invalid'},[pscustomobject]@{Id=2;ConfigurationName='Microsoft.PowerShell';ComputerName='unrelated.example.invalid'})}
  function Remove-PSSession {[CmdletBinding()]param($Session)Assert-FK ($Session.Id -eq 1) 'Unrelated session removed.';$script:FKRemoved++}
  function Start-Process {throw 'Unexpected new window blocked.'}
  foreach($case in @('success','cancel','disconnect-failed')){
   $script:FKCase=$case;$script:FKWrites=0;$script:FKRemoved=0;$NoNewWindow=$true;$NoPause=$true;$ClearVariables=$false
   $text=Capture-FK $script:FKMain
   if($case -eq 'cancel'){Assert-FK ($script:FKWrites -eq 0 -and $script:FKRemoved -eq 0) 'Cancelled session reset changed sessions.'}
   else{Assert-FK ($script:FKWrites -eq 2 -and $script:FKRemoved -eq 1) "Session isolation failed: $text";if($case -eq 'disconnect-failed'){Assert-FK ($text -match 'disconnect.*failed') 'Disconnect error hidden.'}}
   Pass-FK $case
  }
 } }
 'Execution' { & {
  $a=Get-FKAst 'tools/set-execution.ps1';$main=[scriptblock]::Create(@($a.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.TryStatementAst]})[-1].Extent.Text)
  function Get-ExecutionPolicy {[CmdletBinding()]param([switch]$List)
   if($List){if($script:FKCase -eq 'managed') {[pscustomobject]@{Scope='MachinePolicy';ExecutionPolicy='AllSigned'}};return}
   if($script:FKCase -eq 'already' -or ($script:FKCase -eq 'success' -and $script:FKWrites)){'RemoteSigned'}else{'Restricted'}
  }
  function Set-ExecutionPolicy {[CmdletBinding()]param($ExecutionPolicy,$Scope,[switch]$Force)$script:FKWrites++;Assert-FK ($Scope -eq 'CurrentUser' -and $ExecutionPolicy -eq 'RemoteSigned') 'Policy scope drift.'}
  function Get-ChildItem {[CmdletBinding()]param($LiteralPath,$Filter,[switch]$File)@{Name='fixture.ps1';FullName='fixture.ps1'}}
  function Unblock-File {[CmdletBinding()]param($LiteralPath)$script:FKUnblocks++;if($script:FKCase -eq 'unblock-denied'){throw 'Synthetic access denied'}}
  function Read-Host {param($Prompt)if($Prompt -like 'Type SETUP*' -and $script:FKCase -ne 'cancel'){return 'SETUP'};return ''}
  foreach($case in @('cancel','success','already','managed','policy-unchanged','unblock-denied')){
   $script:FKCase=$case;$script:FKWrites=0;$script:FKUnblocks=0;$failures=New-Object 'Collections.Generic.List[string]';$notices=New-Object 'Collections.Generic.List[string]';$oldProgressPreference=$ProgressPreference
   $text=Capture-FK $main
   if($case -eq 'cancel'){Assert-FK ($script:FKWrites -eq 0 -and $script:FKUnblocks -eq 0) 'Cancelled setup changed policy/files.';Assert-FK ($text -match 'CANCELLED' -and $text -notmatch 'SETUP VERIFIED') 'Cancellation reported as success.';Pass-FK $case;continue}
   if($case -in @('already','managed')){Assert-FK ($script:FKWrites -eq 0) 'Managed/usable policy rewritten.'}
   else{Assert-FK ($script:FKWrites -eq 1) 'Expected scoped policy request.'}
   Assert-FK ($script:FKUnblocks -eq 1) 'Wrong unblock scope.'
   if($case -in @('policy-unchanged','unblock-denied')){Assert-FK ($text -match 'SETUP INCOMPLETE' -and $text -notmatch 'SETUP VERIFIED') 'Setup failure hidden.'}
   elseif($case -eq 'managed'){Assert-FK ($text -match 'FOLLOW UP') 'Managed policy warning missing.'}
   else{Assert-FK ($text -match 'SETUP VERIFIED') "Expected setup success: $text"};Pass-FK $case
  }
 } }
 'ThreatIntel' { & {
  . Import-FKFunctions 'published-source/incident-response/IR-GET-THREAT-INTEL-ACTIVITY.ps1'
  foreach($case in @(@('8.8.8.8',$true),@('1.1.1.1',$true),@('10.1.2.3',$false),@('127.0.0.1',$false),@('172.16.1.1',$false),@('192.168.1.1',$false),@('169.254.1.1',$false),@('100.64.0.1',$false),@('224.0.0.1',$false),@('::1',$false),@('fc00::1',$false),@('fe80::1',$false),@('2606:4700:4700::1111',$true),@('not-an-ip',$false))){$ip=Convert-ToIPAddress $case[0];Assert-FK ((Test-PublicIPAddress $ip) -eq $case[1]) ('IP input guard failed: '+$case[0]);Pass-FK $case[0]}
 } }
 'GitSecurity' { & {
  . Import-FKFunctions 'tools/git-security.ps1'
  foreach($case in @(@('repo.access',1),@('user.failed_login',2),@('user.login',3),@('personal_access_token.create',1),@('repository_ruleset.destroy',1),@('oauth_access.revoke',3),@('unknown.event',2))){$triage=Get-Triage $case[0];Assert-FK ($triage[0] -eq $case[1]) 'Git security event misclassified.';Pass-FK ('triage-'+$case[0])}
  $path=Join-Path ([IO.Path]::GetTempPath()) ('fk-export-'+[guid]::NewGuid().ToString('N')+'.json')
  try{foreach($case in @('valid','empty','invalid','no-action','no-events','json-lines')){
   $text=switch($case){'valid'{'[{"action":"repo.access","actor":"fixture"}]'};'empty'{''};'invalid'{'not json'};'no-action'{'[{"actor":"fixture"}]'};'no-events'{'[]'};'json-lines'{'{"action":"repo.access"}'+"`n"+'{"action":"user.login"}'}}
   [IO.File]::WriteAllText($path,$text);$threw=$false;$records=@();try{$records=@(Read-Export $path)}catch{$threw=$true}
   Assert-FK ($threw -eq ($case -notin @('valid','json-lines'))) "Invalid export accepted: $case"
   if(-not $threw){Assert-FK ($records.Count -eq $(if($case -eq 'json-lines'){2}else{1})) 'Export event count changed.'};Pass-FK ('read-'+$case)
  }}finally{Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue}
 } }
 'MapKit' { & {
  . Import-FKFunctions 'tools/INVOKE-MAP-KIT.ps1'
  function Clear-Host {}
  function Pause-End {}
  function Read-Host {throw 'Unexpected map prompt blocked.'}
  $fixture=Join-Path ([IO.Path]::GetTempPath()) ('fk-map-'+[guid]::NewGuid().ToString('N'))
  try{
   [void](New-Item -ItemType Directory -Path (Join-Path $fixture 'Scripts') -Force)
   [IO.File]::WriteAllText((Join-Path $fixture 'Scripts/sample.ps1'),'# synthetic fixture')
   [IO.File]::WriteAllText((Join-Path $fixture 'sample.pfx'),'not a certificate; synthetic name only')
   foreach($case in @('files','folders','missing')){
    $RootPath=$fixture;if($case -eq 'missing'){$RootPath=Join-Path $fixture 'absent'}
    $MaxDepth=3;$FoldersOnly=$case -eq 'folders';$SkipSignatureCheck=$true;$AutoAcceptRoot=$true;$NoFileMap=$false;$NoPause=$true
    $text=Capture-FK $script:FKMain
    if($case -eq 'missing'){Assert-FK ($text -match '\[FAIL\]' -and $text -notmatch '\[OK\].*Complete') "Missing map root accepted: $text"}
    else{Assert-FK ($text -match 'Complete. No changes made') "Map did not complete: $text";if($case -eq 'files'){Assert-FK ($text -match 'sample.pfx') 'Private-key filename warning missing.'}}
    Assert-FK ([IO.File]::ReadAllText((Join-Path $fixture 'Scripts/sample.ps1')) -eq '# synthetic fixture') 'Map altered fixture.';Pass-FK $case
   }
  }finally{Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue}
 } }
 'Storage' { & {
  . Import-FKFunctions 'published-source/endpoint/GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1'
  function Get-CimInstance {[CmdletBinding()]param($ClassName,$Filter)
   if($ClassName -eq 'Win32_LogicalDisk'){if($script:FKCase -eq 'missing-drive'){return};@{DeviceID='C:';Size=100000;FreeSpace=25000}}
   else{@{Caption='Synthetic';Version='Fixture';LastBootUpTime=[datetime]'2026-01-01'}}
  }
  function Join-Path {param($Path,$ChildPath)return ([string]$Path+'/'+$ChildPath)}
  function Test-Path {[CmdletBinding()]param($LiteralPath,$PathType)return $false}
  function Get-ChildItem {[CmdletBinding()]param($LiteralPath,[switch]$File,[switch]$Force,[switch]$Recurse)
   $script:FKScans++;foreach($size in @(10,50,20,40,30)){[pscustomobject]@{FullName='fixture-'+$size;Length=$size}}
  }
  foreach($case in @('largest','skip-largest','missing-drive')){
   $script:FKCase=$case;$script:FKScans=0;$threw=$false;$result=$null
   try{$result=Get-StorageData -TargetComputer '.' -TargetDriveLetter C -TargetTopFiles 2 -TargetSkipLargestFiles ($case -eq 'skip-largest')}catch{$threw=$true}
   Assert-FK ($threw -eq ($case -eq 'missing-drive')) 'Missing drive hidden.'
   if($case -eq 'largest'){Assert-FK ($result.LargestFiles.Count -eq 2 -and $result.LargestFiles[0].SizeBytes -eq 50 -and $result.LargestFiles[1].SizeBytes -eq 40) 'Top files ranking failed.';Assert-FK ($result.CleanupCandidateBytes -eq 0) 'Largest files counted as deletable candidates.'}
   if($case -eq 'skip-largest'){Assert-FK ($script:FKScans -eq 0 -and $result.LargestFilesSkipped) 'Skipped scan still walked disk.'};Pass-FK $case
  }
 } }
 default {throw "Unknown suite: $Focus"}
}
