# Presentation-only regression checks; no service calls or workflow bodies run.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
function Pure-Print($Node){
 if($Node -isnot [System.Management.Automation.Language.CommandAst] -or $Node.GetCommandName() -notin @('Write-Host','Write-FKReportLine')){return $false}
 foreach($element in @($Node.CommandElements|Select-Object -Skip 1)){
  if($element -is [System.Management.Automation.Language.CommandParameterAst]){continue}
  if($element -isnot [System.Management.Automation.Language.StringConstantExpressionAst] -and $element -isnot [System.Management.Automation.Language.ConstantExpressionAst]){return $false}
 };return $true
}
function NonPresentation-Tokens($Text){
 $t=$null;$e=$null;$a=[System.Management.Automation.Language.Parser]::ParseInput($Text,[ref]$t,[ref]$e)
 if($e.Count){throw $e[0]}
 $ranges=@($a.FindAll({param($n) Pure-Print $n},$true)|ForEach-Object{,@($_.Extent.StartOffset,$_.Extent.EndOffset)})
 $prompts=@($a.FindAll({param($n)$n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Read-Host'},$true)|ForEach-Object{$_.CommandElements}|Where-Object{$_ -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $_.Value -match '^Press (?:Enter|ENTER) to (?:EXIT|exit session\.|close.*|return to PowerShell)$'}|ForEach-Object{,@($_.Extent.StartOffset,$_.Extent.EndOffset)})
 $parts=@();foreach($token in $t){
  if($token.Kind -in @('Comment','NewLine','EndOfInput')){continue}
  $skip=$false;foreach($range in @($ranges)+@($prompts)){if($token.Extent.StartOffset -ge $range[0] -and $token.Extent.EndOffset -le $range[1]){$skip=$true;break}}
  if(-not $skip){$parts+=($token.Kind.ToString()+':'+$token.Text)}
 };return $parts -join "`n"
}

$rows=Get-Content (Join-Path $Root 'docs/qa/OPERATOR-SCRIPT-ALIGNMENT.json') -Raw|ConvertFrom-Json
$changed=@($rows|Where-Object{$_.changed})
if($rows.Count -ne 80 -or $changed.Count -ne 65){throw 'Unexpected alignment scope.'}
foreach($row in $rows){
 $path=Join-Path $Root $row.path
 $hash=(Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()
 if($hash -ne $row.newSha256){throw "Unrecorded source changes: $($row.file)"}
 if(-not $row.changed){if($hash -ne $row.oldSha256){throw 'Preserved source drifted.'};continue}
 $text=[IO.File]::ReadAllText($path)
 $sha=[Security.Cryptography.SHA256]::Create()
 try{$actual=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes((NonPresentation-Tokens $text))))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
 if($actual -ne $row.nonPresentationSha256){throw "Non-presentation tokens changed: $($row.file)"}
 if($row.changes -contains 'Consistent Enter completion prompt' -and $text -notmatch 'Press Enter to close session\.'){throw 'Completion prompt missing.'}
 $t=$null;$e=$null;$a=[System.Management.Automation.Language.Parser]::ParseInput($text,[ref]$t,[ref]$e)
 $pause=$a.Find({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Pause-End'},$false)
 if($pause -and $pause.Extent.Text -match '\$NoPause'){
  & {
   . ([scriptblock]::Create($pause.Extent.Text))
   function Read-Host {throw 'NoPause attempted to read input.'}
   function Write-Host {throw 'NoPause emitted completion UI.'}
   $NoPause=$true
   Pause-End
  }
 }
 Write-Output "PASS: presentation-only fingerprint / $($row.file)"
}
Write-Output 'PASS: 65 presentation-only comparisons, 15 preserved specialized sources; NoPause remains noninteractive where supported.'
