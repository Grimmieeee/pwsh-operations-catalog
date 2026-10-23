# Isolated function tests: no tenant connection or workflow main runs.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$file=Join-Path $Root 'published-source/incident-response/BEC-RISK-ASSESSMENT.ps1'
$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($file,[ref]$t,[ref]$e)
$fn=$ast.Find({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-ServicePrincipalInfo'},$false)
. ([scriptblock]::Create($fn.Extent.Text))
$script:requests=@();$script:mode='direct'
function GraphGet($Uri,$Headers){
 $script:requests+=([string]$Uri)
 if($script:requests.Count -eq 1){
  if($Uri -cne 'https://graph.microsoft.com/v1.0/servicePrincipals/11111111-1111-4111-8111-111111111111?$select=id,appId,displayName,publisherName,verifiedPublisher'){throw "Malformed direct lookup: $Uri"}
  if($script:mode -eq 'collection'){return [pscustomobject]@{Ok=$true;Data=[pscustomobject]@{value=@()}}}
  if($script:mode -ne 'direct'){return [pscustomobject]@{Ok=$false}}
  return [pscustomobject]@{Ok=$true;Data=[pscustomobject]@{id='11111111-1111-4111-8111-111111111111';displayName='Example app';publisherName='Example';verifiedPublisher=[pscustomobject]@{displayName='Example'}}}
 }
 if($Uri -notlike 'https://graph.microsoft.com/v1.0/servicePrincipals?*'){throw 'Missing filtered fallback.'}
 if($Uri -notmatch 'id%20eq%20%2711111111-1111-4111-8111-111111111111%27'){throw 'Fallback filter lost the exact ID.'}
 if($script:mode -eq 'failed'){return [pscustomobject]@{Ok=$false}}
 if($script:mode -eq 'empty'){return [pscustomobject]@{Ok=$true;Data=[pscustomobject]@{value=@()}}}
 return [pscustomobject]@{Ok=$true;Data=[pscustomobject]@{value=@([pscustomobject]@{id=$(if($script:mode -eq 'wrong-id'){'wrong-id'}else{'11111111-1111-4111-8111-111111111111'});displayName='Fallback app';publisherName='Example';verifiedPublisher=[pscustomobject]@{displayName='Example'}})}}
}
foreach($case in @('direct','fallback','collection','failed','empty','wrong-id')){
 $script:mode=$case;$script:requests=@();$cache=@{};$id='11111111-1111-4111-8111-111111111111'
 $result=Get-ServicePrincipalInfo $id @{} $cache
 if($case -in @('direct','fallback','collection')){if(-not $result.Ok -or $result.Name -notmatch 'app$'){throw "App did not resolve: $case"}}
 else{if($result.Ok -or $result.Name -notmatch 'Unresolved app'){throw "Failed lookup was cleared: $case"}}
 $calls=$script:requests.Count;$null=Get-ServicePrincipalInfo $id @{} $cache
 if($script:requests.Count -ne $calls){throw 'Cache repeated a service call.'}
 Write-Output "PASS: BEC app lookup / $case / exact ID and cache"
}
$script:requests=@();$empty=Get-ServicePrincipalInfo '' @{} @{}
if($empty.Ok -or $script:requests.Count){throw 'Blank ID sent a request.'}
Write-Output 'PASS: BEC blank app ID remains unresolved without a request.'
