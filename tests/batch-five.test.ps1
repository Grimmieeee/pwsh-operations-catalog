#Requires -Version 5.1
param([string]$Root=(Split-Path $PSScriptRoot -Parent),[Parameter(Mandatory)][string]$Focus)
$ErrorActionPreference='Stop'
function Assert-F5([bool]$Ok,[string]$Message){if(-not $Ok){throw $Message}}
function Load-F5([string]$Path){
 $e=$null;$t=$null;$script:F5Ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $Root $Path),[ref]$t,[ref]$e)
 if($e.Count){throw 'Source parse failed.'}
 foreach($f in $script:F5Ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)){. ([scriptblock]::Create($f.Extent.Text))}
}
function Pass-F5([string]$Name){Write-Output ('PASS: '+$Focus+' / '+$Name)}
function Invoke-WebRequest {throw 'Unexpected network request blocked.'}
function Invoke-RestMethod {throw 'Unexpected network request blocked.'}
function Import-Module {throw 'Unexpected module import blocked.'}
switch($Focus){
 'Cert' { & {
  . Load-F5 'tools/MANAGE-CERT-SIGNATURES.ps1'
  foreach($pair in @(@('','CN=Local Script Signing'),@('Fixture','CN=Fixture'),@('CN=Fixture','CN=Fixture'))){Assert-F5 ((Normalize-Subject $pair[0]) -eq $pair[1]) 'Certificate subject mismatch.';Pass-F5 'subject'}
  function Show-CodeSigningCerts {return @([pscustomobject]@{Thumbprint='FIXTURE'})}
  function Read-Host {param($Prompt)return $script:F5Choice}
  foreach($choice in @('1','0','bad')){$script:F5Choice=$choice;$c=Select-CodeSigningCert;Assert-F5 (($null -ne $c) -eq ($choice -eq '1')) 'Unsafe certificate selection.';Pass-F5 ('selection-'+$choice)}
 } }
 'Sign' { & {
  . Load-F5 'tools/SIGN-FOLDER-SCRIPTS.ps1'
  function Get-ChildItem {[CmdletBinding()]param($Path,[switch]$CodeSigningCert)@([pscustomobject]@{Thumbprint='AABB';Subject='CN=Fixture';NotAfter=[datetime]'2030-01-01'})}
  function Read-Host {param($Prompt)return $script:F5Choice}
  foreach($choice in @('1','0','bad')){$script:F5Choice=$choice;$c=Select-CodeSigningCert;Assert-F5 (($null -ne $c) -eq ($choice -eq '1')) 'Signing selected wrong cert.';Pass-F5 ('selection-'+$choice)}
  $c=Select-CodeSigningCert -Thumbprint 'aa bb';Assert-F5 ($c.Thumbprint -eq 'AABB') 'Thumbprint normalization failed.';Pass-F5 'thumbprint'
 } }
 'GitRepo' { & {
  . Load-F5 'tools/git-repo.ps1'
  function Get-FieldKitGitChanges {param($Repo)return @($script:F5Changes)}
  function Test-Path {[CmdletBinding()]param($LiteralPath,$PathType)return $false}
  foreach($case in @(@('?? fixture.pfx','BLOCK'),@('?? .env','BLOCK'),@('?? report.csv','REVIEW'),@('?? script.ps1',''),@(' D fixture.pfx',''),@('R  old.ps1 -> fixture.key','BLOCK'))){$script:F5Changes=@($case[0]);$hits=@(Get-FieldKitGitSafetyHits -Repo ([IO.Path]::GetTempPath()));if($case[1]){Assert-F5 ($hits.Count -eq 1 -and $hits[0].Level -eq $case[1]) 'Git filename risk missed.'}else{Assert-F5 ($hits.Count -eq 0) 'Unexpected filename risk.'};Pass-F5 $case[0]}
 } }
 'Handoff' { & {
  . Load-F5 'tools/git-handoff.ps1'
  foreach($text in @('password=synthetic-value','Bearer synthetic-value','fixture@example.invalid','https://example.invalid/path','192.0.2.1')){$r=Protect-Text $text;Assert-F5 ($r -match 'REDACTED' -and $r -notmatch 'synthetic-value|fixture@example|example.invalid|192\.0\.2\.1') 'Metadata screening missed fixture.';Pass-F5 'redaction'}
  foreach($value in @(('a'*40),('b'*64),'not-an-id')){$threw=$false;try{$null=Get-Hash $value}catch{$threw=$true};Assert-F5 ($threw -eq ($value -eq 'not-an-id')) 'Invalid Git object ID accepted.';Pass-F5 'object-id'}
 } }
 'Preflight' { & {
  . Load-F5 'tools/GET-TERMINAL-READINESS-CHECK.ps1'
  foreach($pair in @(@('C:\Kit\Scripts\x.ps1','Scripts\x.ps1'),@('C:\Other\x.ps1','C:\Other\x.ps1'),@('c:\kit\x.ps1','x.ps1'))){Assert-F5 ((Get-RelativePath -FullName $pair[0] -Root 'C:\Kit') -eq $pair[1]) 'Preflight path presentation failed.';Pass-F5 'relative-path'}
 } }
 'Join' { & {
  . Load-F5 'published-source/endpoint/JOIN-COMPUTER-TO-DOMAIN.ps1'
  $main=[scriptblock]::Create(@($script:F5Ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.TryStatementAst]})[-1].Extent.Text)
  function Clear-Host {}
  function Pause-End {}
  function Test-IsAdmin {return $true}
  function Get-CimInstance {[CmdletBinding()]param($ClassName)@{PartOfDomain=$false;Domain='WORKGROUP'}}
  function Resolve-DnsName {[CmdletBinding()]param($Name)@{Name=$Name}}
  function Test-Connection {[CmdletBinding()]param($ComputerName,$Count,[switch]$Quiet)return $true}
  function Get-Credential {param($Message)return 'fixture credential object'}
  function Add-Computer {[CmdletBinding()]param($DomainName,$OUPath,$Credential)$script:F5Writes++;Assert-F5 ($DomainName -eq 'example.invalid') 'Wrong domain target.';if($script:F5Case -eq 'denied'){throw 'Synthetic join denied'}}
  function Restart-Computer {throw 'Unexpected reboot blocked.'}
  function Read-Host {param($Prompt)if($Prompt -like 'Type JOIN*'){return 'JOIN'};if($Prompt -like 'Restart now*'){return 'N'};throw "Unexpected join prompt: $Prompt"}
  foreach($case in @('success','denied')){$script:F5Case=$case;$script:F5Writes=0;$Domain='example.invalid';$OUPath='OU=Fixture';$TicketNumber='FIXTURE';$text=(& $main 6>&1|ForEach-Object {[string]$_}) -join "`n";Assert-F5 ($script:F5Writes -eq 1) 'Join request not exercised.';if($case -eq 'denied'){Assert-F5 ($text -match 'Domain join failed' -and $text -notmatch 'Domain join command completed') 'Join failure hidden.'}else{Assert-F5 ($text -match 'Restart is required') 'Pending reboot not reported.'};Pass-F5 $case}
 } }
 'Basic' { & {
  . Load-F5 'toys/SET-THEME-BASIC.ps1'
  foreach($case in @('Write-Ok','Write-Warn','Write-Fail','Write-Field')){$out=(& $case 'Fixture' 'Value' 6>&1|ForEach-Object {[string]$_}) -join '' ;Assert-F5 ($out -match 'Fixture' -and $out -notmatch ([regex]::Escape([string][char]27))) 'Plain theme output mismatch.';Pass-F5 $case}
 } }
 {$_ -in @('SeaGlass','Silicon')} { & {
  $file=if($Focus -eq 'SeaGlass'){'SET-THEME-SEAGLASS.ps1'}else{'SET-THEME-SILICON-VALLEY.ps1'}
  . Load-F5 ('toys/'+$file)
  $assignment=$script:F5Ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -eq '$profileBlock'}|Select-Object -First 1
  Assert-F5 ($null -ne $assignment) 'Persisted profile block not found.'
  $esc=[char]27;. ([scriptblock]::Create($assignment.Extent.Text))
  Assert-F5 ($profileBlock -match '# - - - MSSP FIELD KIT' -and $profileBlock -match '# - - - END') 'Theme block boundaries missing.';Pass-F5 'profile-boundaries'
  $e=$null;[void][Management.Automation.Language.Parser]::ParseInput($profileBlock,[ref]$null,[ref]$e);Assert-F5 ($e.Count -eq 0) 'Generated profile block does not parse.';Pass-F5 'profile-syntax'
  Assert-F5 ($profileBlock -match 'Set-PSReadLineOption') 'Persisted highlighting missing.';Pass-F5 'highlighting-block'
 } }
 'Cobalt' { & {
  . Load-F5 'toys/SET-THEME-COBALT.ps1'
  foreach($a in $script:F5Ast.EndBlock.Statements|Where-Object {$_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -match '^\$(esc|c[A-Za-z0-9]+)$'}){. ([scriptblock]::Create($a.Extent.Text))}
  foreach($name in @('cT1','cT2','cR')){$v=Get-Variable $name -ValueOnly;Assert-F5 ($v.StartsWith([string][char]27+'[') -and $v.EndsWith('m')) 'Palette ANSI value invalid.';Pass-F5 $name}
 } }
 'Rain' { & {
  . Load-F5 'toys/rain.ps1';$esc=[char]27
  Assert-F5 ((MoveTo -Row 2 -Col 3) -eq "$esc[2;3H") 'Rain cursor command mismatch.';Pass-F5 'cursor'
  Assert-F5 ((CenterX -Text 'Fixture' -Width 4) -ge 1) 'Rain centering became negative.';Pass-F5 'narrow-width'
  Assert-F5 ((Get-ClockText) -match '^\d{2}:\d{2}$') 'Clock format changed.';Pass-F5 'clock'
 } }
 'Static' { & {
  . Load-F5 'toys/static.ps1';$script:esc=[char]27
  Assert-F5 ((MoveTo -Row -4 -Col -2) -eq "$([char]27)[1;1H") 'Static cursor escaped bounds.';Pass-F5 'cursor-clamp'
  foreach($width in @(20,100)){$p=Get-FloatPosition -Frame 3000 -Width $width -Height 30 -Text 'Fixture';Assert-F5 ($p.Row -ge 1 -and $p.Row -le 28 -and $p.Col -ge 2 -and $p.Col -le ($width-10)) 'Floating label out of bounds.';Pass-F5 ('float-'+$width)}
 } }
 'Attractor' { & {
  . Load-F5 'toys/attractor.ps1';$script:esc=[char]27;$script:reset="$([char]27)[0m"
  Assert-F5 ((M -r -2 -c -3) -eq "$([char]27)[1;1H") 'Attractor cursor escaped bounds.';Pass-F5 'cursor-clamp'
  $sb=New-Object Text.StringBuilder;Put $sb -1 3 'Fixture' '97';Assert-F5 ($sb.Length -eq 0) 'Negative draw was emitted.';Pass-F5 'negative-draw'
  Put $sb 2 3 'Fixture' '97';Assert-F5 ($sb.ToString().Contains('Fixture') -and $sb.ToString().EndsWith($script:reset)) 'Draw did not reset color.';Pass-F5 'draw-reset'
 } }
 default {throw 'Unknown batch 5 suite.'}
}
