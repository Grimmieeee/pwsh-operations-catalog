param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$path=Join-Path $Root 'published-source/utility/PREPARE-FIELD-KIT.ps1'
$tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
if($errors.Count){throw $errors[0]}
foreach($fn in $ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst]},$false)){. ([scriptblock]::Create($fn.Extent.Text))}
function Assert-Setup($Ok,$Message){if(-not $Ok){throw $Message}}
function Pass-Setup($Name){Write-Output "PASS: first-run setup / $Name"}

# Block real service, package and host changes throughout the isolated fixtures.
function Connect-MgGraph {throw 'Unexpected customer sign-in.'}
function Connect-ExchangeOnline {throw 'Unexpected customer sign-in.'}
function Set-ExecutionPolicy {throw 'Unexpected policy change.'}
function Set-PSRepository {throw 'Unexpected repository trust change.'}
function Invoke-WebRequest {throw 'Unexpected raw download.'}
function Read-Host {throw 'Unexpected interactive prompt.'}

& {
 function Get-Module {[CmdletBinding()]param([switch]$ListAvailable,$Name)
  foreach($v in $script:Versions){[pscustomobject]@{Name=$Name;Version=[version]$v}}
 }
 $requirement=@(Get-FKRequirements Graph)[0]
 foreach($case in @(@('2.4.0',$true,$false),@('1.9.0',$false,$false),@('3.0.0',$false,$true))){
  $script:Versions=@($case[0]);$state=Get-FKModuleState $requirement
  Assert-Setup ($state.Ready -eq $case[1] -and $state.Conflict -eq $case[2]) 'Module compatibility result is incorrect.'
 }
 $script:Versions=@('3.0.0','2.4.0');$state=Get-FKModuleState $requirement
 Assert-Setup (-not $state.Ready -and $state.Conflict) 'Side-by-side unsupported major was treated as ready.'
 Pass-Setup 'compatible, missing, old and conflicting module versions'
}

& {
 function Get-ItemProperty {[CmdletBinding()]param($LiteralPath,$Name)[pscustomobject]@{Release=461808}}
 function Get-CimInstance {[CmdletBinding()]param($ClassName)[pscustomobject]@{PartOfDomain=$script:Domain}}
 function Get-Module {[CmdletBinding()]param([switch]$ListAvailable,$Name)if($script:AD){[pscustomobject]@{Name='ActiveDirectory'}}}
 $script:Domain=$true;$script:AD=$true
 Assert-Setup (@(Test-FKHost Both $false -PowerShellVersion '5.1' -OperatingSystem 'Windows_NT').Count -eq 0) 'Supported Windows host failed.'
 Assert-Setup (@(Test-FKHost Both $false -PowerShellVersion '7.2' -OperatingSystem 'Windows_NT').Count -gt 0) 'Unsupported PowerShell was accepted.'
 Assert-Setup (@(Test-FKHost Both $false -PowerShellVersion '7.4.0' -OperatingSystem 'Linux').Count -gt 0) 'Non-Windows host was accepted.'
 $script:Domain=$false;$script:AD=$false
 Assert-Setup (@(Test-FKHost Both $true -PowerShellVersion '7.4.0' -OperatingSystem 'Windows_NT').Count -eq 2) 'Missing hybrid prerequisites were lost.'
 Pass-Setup 'host baseline and optional AD requirements'
}

& {
 function Test-FKHost {param($Selection,$Hybrid)@()}
 function Get-FKModuleState {param($Requirement)[pscustomobject]@{Name=$Requirement.Name;Ready=$script:Ready;Conflict=$script:Conflict;Module=[pscustomobject]@{Version=[version]'2.4.0'};InstallName=$Requirement.InstallName}}
 function Install-FKMissingModules {param($Requirements,$States)$script:Installs++;if($script:FailInstall){throw 'Synthetic install failure.'};$script:Ready=$true}
 function Test-FKModuleImports {param($States,$Hybrid)$script:Imports++;if($script:FailImport){throw 'Synthetic module import failure.'}}
 foreach($case in @('ready','check-only','unattended','approved','conflict','install-failed','import-failed','cancelled')){
  $script:Ready=$case -in @('ready','import-failed');$script:Conflict=$case -eq 'conflict';$script:FailInstall=$case -eq 'install-failed';$script:FailImport=$case -eq 'import-failed';$script:Installs=0;$script:Imports=0
  function Read-Host {param($Prompt)if($case -eq 'cancelled'){return 'NO'};throw 'Unexpected prompt.'}
  $threw=$false;$result=$null
  try{$result=Invoke-FKPreparation Graph $false ($case -eq 'check-only') ($case -in @('approved','install-failed')) ($case -ne 'cancelled') 6>$null}catch{$threw=$true}
  if($case -in @('install-failed','import-failed')){Assert-Setup $threw 'A failed install/import was accepted.'}
  elseif($case -in @('ready','approved')){Assert-Setup ($result -eq 'READY') 'Ready result missing.'}
  elseif($case -eq 'cancelled'){Assert-Setup ($result -eq 'CANCELLED' -and $script:Installs -eq 0) 'Cancellation changed prerequisites.'}
  else{Assert-Setup ($result -eq 'NOT READY' -and $script:Installs -eq 0) 'Unapproved checks changed prerequisites.'}
  if($case -eq 'ready'){Assert-Setup ($script:Installs -eq 0 -and $script:Imports -eq 1) 'Compatible modules were reinstalled or not checked.'}
  if($case -eq 'approved'){Assert-Setup ($script:Installs -eq 1 -and $script:Imports -eq 1) 'Approved installation did not recheck imports.'}
  Pass-Setup $case
 }
}

& {
 function Get-PSRepository {[CmdletBinding()]param($Name)if($script:Repository){[pscustomobject]@{SourceLocation=$script:Repository}}}
 function Register-PSRepository {[CmdletBinding()]param([switch]$Default)$script:Registrations++;$script:Repository='https://www.powershellgallery.com/api/v2'}
 $script:Repository=$null;$script:Registrations=0;$threw=$false
 try{Test-FKGallery}catch{$threw=$true}
 Assert-Setup ($threw -and $script:Registrations -eq 0) 'A check registered a repository.'
 Test-FKGallery -AllowRegistration
 Assert-Setup ($script:Registrations -eq 1) 'Approved default repository registration failed.'
 $script:Repository='https://example.invalid/api/v2';$threw=$false
 try{Test-FKGallery -AllowRegistration}catch{$threw=$true}
 Assert-Setup $threw 'A substituted PSGallery was accepted.'
 Pass-Setup 'repository registration requires approval and official source'
}

& {
 function Get-Command {[CmdletBinding()]param($Name)[pscustomobject]@{Name=$Name}}
 function Test-FKGallery {param([switch]$AllowRegistration)}
 function Get-PackageProvider {[CmdletBinding()]param($Name,[switch]$ListAvailable)[pscustomobject]@{Version=[version]'2.8.5.201'}}
 function Install-PackageProvider {throw 'Existing provider was unnecessarily reinstalled.'}
 function Install-Module {[CmdletBinding()]param($Name,$MinimumVersion,$MaximumVersion,$Scope,$Repository,[switch]$Force,[switch]$AllowClobber)
  Assert-Setup ($Name -eq 'Microsoft.Graph' -and $Scope -eq 'CurrentUser' -and $Repository -eq 'PSGallery' -and $MinimumVersion -eq '2.0.0' -and $MaximumVersion -eq '2.999.999') 'Package source, scope or version bounds changed.'
  $script:ModuleInstalls++
 }
 $requirements=@(Get-FKRequirements Graph);$states=@($requirements|ForEach-Object{[pscustomobject]@{Ready=$false;InstallName=$_.InstallName}});$script:ModuleInstalls=0
 Install-FKMissingModules $requirements $states 6>$null
 Assert-Setup ($script:ModuleInstalls -eq 1) 'Graph dependency caused duplicate installations.'
 Pass-Setup 'approved installation uses CurrentUser, pinned family and no duplicate package'
}

# The actual unattended entry point must fail, without waiting, on an unsupported host.
if($env:OS -ne 'Windows_NT'){
 $threw=$false
 try{& $path -CheckOnly -NoPause *> $null}catch{$threw=$true}
 Assert-Setup $threw 'Unattended NOT READY did not fail the job.'
 Pass-Setup 'actual unattended entry point reports failure without prompts'
}
