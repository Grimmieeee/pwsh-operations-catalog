# Route actual workflow handoff functions to harmless disposable companion scripts.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('fieldkit-bec-'+[guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $fixture)
$priorSession=$global:FieldKitIRSession
$targets=@('BEC-RISK-ASSESSMENT','BEC-CONTAIN-ERADICATE','BEC-RECOVER-VALIDATE')
$fixtureSource=@'
[CmdletBinding()]
param([string]$Tenant,[string]$UPN,[string]$UserPrincipalName,[int]$OutputDelayMs,[switch]$FinalReview)
[pscustomobject]@{Tenant=$Tenant;UPN=$UPN;UserPrincipalName=$UserPrincipalName;Delay=$OutputDelayMs;FinalReview=[bool]$FinalReview}
'@
try {
 foreach($target in $targets){[IO.File]::WriteAllText((Join-Path $fixture ($target+'.ps1')),$fixtureSource)}
 foreach($source in $targets){
  & {
   $t=$null;$e=$null;$a=[Management.Automation.Language.Parser]::ParseFile((Join-Path $Root ('published-source/incident-response/'+$source+'.ps1')),[ref]$t,[ref]$e)
   if($e.Count){throw $e[0]}
   $fn=$a.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Invoke-IRNextStep'},$false)
   . ([scriptblock]::Create($fn.Extent.Text))
   # Redirect only the filesystem boundary. The tested handoff body is unchanged.
   function Join-Path {param($Path,$ChildPath)
    if($ChildPath -notin @($targets|ForEach-Object{$_+'.ps1'})){throw "Unexpected companion path: $ChildPath"}
    Microsoft.PowerShell.Management\Join-Path $fixture $ChildPath
   }
   function Read-IRNavigation {param($Label)return $script:BecApprove}
   function Write-IRLine {param($Object,$ForegroundColor)$script:BecMessages+=@([string]$Object)}
   function Close-IRWorkflow {param($Message,[switch]$Wait)$script:BecMessages+=@([string]$Message)}
   $NoPause=$false;$OutputDelayMs=0;$script:BecApprove=$true
   $global:FieldKitIRSession=@{UPN='fixture@example.invalid';TenantId='11111111-1111-4111-8111-111111111111'}
   foreach($target in $targets){
    $script:BecMessages=@();$result=@(Invoke-IRNextStep -FileName $target -Objective 'fixture')
    if($result.Count -ne 1 -or $result[0].Tenant -ne $global:FieldKitIRSession.TenantId -or $result[0].Delay -ne 0){throw "Handoff did not reach renamed companion: $source -> $target"}
    if($target -eq 'BEC-RISK-ASSESSMENT'){
     if(-not $result[0].FinalReview -or $result[0].UserPrincipalName -ne $global:FieldKitIRSession.UPN){throw 'Final assessment lost its target or final-review flag.'}
    }elseif($result[0].UPN -ne $global:FieldKitIRSession.UPN){throw 'Response/recovery lost its target.'}
    Write-Output "PASS: BEC companion / $source -> $target"
   }
   $script:BecApprove=$false;$result=@(Invoke-IRNextStep -FileName 'BEC-CONTAIN-ERADICATE')
   if($result.Count){throw 'Declined handoff launched a companion.'}
   $script:BecApprove=$true;$NoPause=$true;$result=@(Invoke-IRNextStep -FileName 'BEC-CONTAIN-ERADICATE')
   if($result.Count){throw 'NoPause launched a companion.'};$NoPause=$false
   $missing=$fixture+'/BEC-CONTAIN-ERADICATE.ps1';[IO.File]::Delete($missing);$script:BecMessages=@()
   $result=@(Invoke-IRNextStep -FileName 'BEC-CONTAIN-ERADICATE')
   if($result.Count -or ($script:BecMessages -join ' ') -notmatch 'Next script not found'){throw 'Missing companion was not blocked.'}
   [IO.File]::WriteAllText($missing,$fixtureSource)
   $global:FieldKitIRSession=$null;$script:BecMessages=@();$result=@(Invoke-IRNextStep -FileName 'BEC-CONTAIN-ERADICATE')
   if($result.Count -or ($script:BecMessages -join ' ') -notmatch 'Verified target context unavailable'){throw 'Missing context was not blocked.'}
   Write-Output "PASS: BEC companion / $source / decline, NoPause, missing companion, missing context"
  }
 }
}finally{
 $global:FieldKitIRSession=$priorSession
 Remove-Item -LiteralPath $fixture -Recurse -Force -ErrorAction SilentlyContinue
}
