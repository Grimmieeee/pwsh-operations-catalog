# Execute only reviewed command examples with offline service/prompt fixtures.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$commands=@((& node (Join-Path $Root 'tools/catalog-commands.mjs')) | ConvertFrom-Json)
function Invoke-ImpactFixture {
 param([string]$Name,[string[]]$Answers,[string]$Mode='cancel')
 $example=$commands|Where-Object name -eq $Name|Select-Object -First 1
 if(-not $example){throw "Missing command: $Name"}
 & {
  $script:ImpactAnswers=[Collections.Generic.Queue[string]]::new()
  foreach($answer in $Answers){$script:ImpactAnswers.Enqueue($answer)}
  $script:ImpactWrites=0;$script:ImpactReads=0
  $script:ImpactRules=@([pscustomobject]@{Name='one';Identity='rule-1';Enabled=$true},[pscustomobject]@{Name='two';Identity='rule-2';Enabled=$true})
  function Read-Host {param($Prompt)if(-not $script:ImpactAnswers.Count){throw "Unexpected prompt: $Prompt"};return $script:ImpactAnswers.Dequeue()}
  function Get-InboxRule {[CmdletBinding()]param($Mailbox,[switch]$IncludeHidden)$script:ImpactReads++;return $script:ImpactRules}
  function Get-MgUser {[CmdletBinding()]param($UserId)[pscustomobject]@{Id='fixture-id';DisplayName='Fixture';UserPrincipalName=$UserId}}
  function Get-LocalUser {[CmdletBinding()]param($Name)[pscustomobject]@{Name=$Name;SID='S-1-5-21-1-2-3-1001';Enabled=$true}}
  function Get-ComplianceSearch {[CmdletBinding()]param($Identity)[pscustomobject]@{Name=$Identity;Status='Completed';Items=2;ExchangeLocation='fixture';ContentMatchQuery='subject:fixture'}}
  function Remove-InboxRule {[CmdletBinding()]param($Mailbox,$Identity,[switch]$Confirm)
   $script:ImpactWrites++
   if($Mode -eq 'partial' -and $Identity -eq 'rule-2'){throw 'Synthetic second-rule failure'}
   $script:ImpactRules=@($script:ImpactRules|Where-Object Identity -ne $Identity)
  }
  foreach($mutation in @('Remove-MgUser','Remove-LocalUser','New-ComplianceSearchAction','Restart-Computer','Stop-Process','Restart-NetAdapter','Restart-Service','Suspend-BitLocker','Disable-NetAdapter','ipconfig','netsh','winget')){
   Set-Item ('Function:'+ $mutation) { $script:ImpactWrites++;throw 'Unexpected mutation in cancellation fixture' }
  }
  $failed=$false
  try { & ([scriptblock]::Create($example.code)) | Out-Null }catch{if($Mode -ne 'partial'){throw};$failed=$true}
  if($script:ImpactAnswers.Count){throw "Unused fixture input: $Name"}
  if($Mode -eq 'cancel' -and $script:ImpactWrites){throw "Cancellation performed writes: $Name"}
  if($Mode -eq 'success' -and ($script:ImpactWrites -ne 2 -or $script:ImpactRules.Count -ne 0 -or $script:ImpactReads -ne 2)){throw 'Rule removal did not execute and recheck exactly the selected set.'}
  if($Mode -eq 'partial' -and (-not $failed -or $script:ImpactRules.Count -ne 1)){throw 'Partial failure was hidden or prior changes were implied rolled back.'}
 }
 Write-Output "PASS: impact authorization / $Name / $Mode"
}
foreach($name in @('Remove All Inbox Rules','Delete Cloud User','Delete Local User','Hard-Delete Search Results')){
 Invoke-ImpactFixture $name @('')
 Invoke-ImpactFixture $name @('fixture@example.invalid','WRONG')
}
foreach($name in @('Reboot Computer','Stop Process By Name','Release And Renew Dhcp','Reset Tcp/Ip Stack','Reset Winsock','Restart Adapter','Restart Service','Suspend For One Reboot','Update All Eligible WinGet Packages','Disable Network Adapter','Restart Network Adapter','Isolate Device - Disable Enabled Adapters')){
 Invoke-ImpactFixture $name @('NO')
}
foreach($name in @('Remove All Inbox Rules')){
 Invoke-ImpactFixture $name @('fixture@example.invalid','DELETE fixture@example.invalid') 'success'
 Invoke-ImpactFixture $name @('fixture@example.invalid','DELETE fixture@example.invalid') 'partial'
}
