# Presentation-only regression checks; no service calls or workflow bodies run.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
function Pure-Print($Node){
 if($Node -isnot [System.Management.Automation.Language.CommandAst] -or $Node.GetCommandName() -notin @('Write-Host','Write-FKReportLine','Write-IRLine')){return $false}
 foreach($element in @($Node.CommandElements|Select-Object -Skip 1)){
  if($element -is [System.Management.Automation.Language.CommandParameterAst]){continue}
  if($element -isnot [System.Management.Automation.Language.StringConstantExpressionAst] -and $element -isnot [System.Management.Automation.Language.ConstantExpressionAst]){return $false}
 };return $true
}
function Remove-SetupApprovalGate($Text){
 $gate=@'
    # BEGIN IMPACT APPROVAL
    Write-Host "PLAN // CurrentUser execution policy may change to RemoteSigned."
    Write-Host "PLAN // Unblock every .ps1 file directly beside this script: $PSScriptRoot"
    Write-Warning 'Only continue if every script in this folder has been reviewed.'
    if ((Read-Host 'Type SETUP to approve; anything else cancels').Trim() -cne 'SETUP') {
        Write-Host 'CANCELLED // No execution policy or file unblock changes requested.'
        return
    }
    # END IMPACT APPROVAL
'@
 $gate=$gate.Replace("`r`n","`n")+"`n"
 $normalized=$Text.Replace("`r`n","`n")
 if(($normalized.Split(@($gate),[StringSplitOptions]::None).Count-1) -ne 1){throw 'Expected exactly the approved setup gate.'}
 return $normalized.Replace($gate,'').Replace('.VERSION 1.0.3','.VERSION 1.0.2')
}

function NonPresentation-Tokens($Text){
 if($Text -match '# BEGIN IMPACT APPROVAL'){$Text=Remove-SetupApprovalGate $Text}

 $t=$null;$e=$null;$a=[System.Management.Automation.Language.Parser]::ParseInput($Text,[ref]$t,[ref]$e)
 if($e.Count){throw $e[0]}
 $ranges=@($a.FindAll({param($n) Pure-Print $n},$true)|ForEach-Object{,@($_.Extent.StartOffset,$_.Extent.EndOffset)})
 # A literal console window title is presentation; keep its assignment and all dynamic values in the comparison.
 $ranges+=@($a.FindAll({param($n)$n -is [System.Management.Automation.Language.AssignmentStatementAst] -and $n.Left.Extent.Text -ceq '$Host.UI.RawUI.WindowTitle' -and $n.Right.Extent.Text -match "^'[^']*'$"},$true)|ForEach-Object{,@($_.Right.Extent.StartOffset,$_.Right.Extent.EndOffset)})
 $prompts=@($a.FindAll({param($n)$n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -eq 'Read-Host'},$true)|ForEach-Object{$_.CommandElements}|Where-Object{$_ -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $_.Value -match '^\s*Press (?:Enter|ENTER) to (?:EXIT|exit session\.|close.*|return to PowerShell)$'}|ForEach-Object{,@($_.Extent.StartOffset,$_.Extent.EndOffset)})
 $parts=@();foreach($token in $t){
  if($token.Kind -in @('Comment','NewLine','EndOfInput')){continue}
  $skip=$false;foreach($range in @($ranges)+@($prompts)){if($token.Extent.StartOffset -ge $range[0] -and $token.Extent.EndOffset -le $range[1]){$skip=$true;break}}
  if(-not $skip){$parts+=($token.Kind.ToString()+':'+$token.Text)}
 };return $parts -join "`n"
}

function Assert-ApprovedOperationalChange($Row,$Text){
 if(-not $Row.operationalChange){return}
 if($Row.operationalChange.kind -eq 'bec-naming'){
  $record=@((Get-Content (Join-Path $Root 'docs/qa/BEC-NAMING-REVIEW.json') -Raw|ConvertFrom-Json).entries|Where-Object file -eq $Row.file)
  if($record.Count -ne 1){throw 'Missing unique BEC naming source review.'}
  $baseline=$Text
  $pairs=@($record[0].replacements)
  for($i=$pairs.Count-1;$i -ge 0;$i--){$baseline=$baseline.Replace([string]$pairs[$i].new,[string]$pairs[$i].old)}
  $sha=[Security.Cryptography.SHA256]::Create()
  try{$bytes=[Text.Encoding]::UTF8.GetBytes($baseline);if($record[0].utf8Bom){$bytes=[byte[]](@(239,187,191)+$bytes)};$hash=([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
  if($hash -ne $record[0].priorSourceSha256 -or $hash -ne $Row.operationalChange.priorSourceSha256){throw 'BEC rename includes unreviewed operational changes.'}
  return
 }

 if($Row.file -eq 'set-execution.ps1' -and $Row.operationalChange.kind -eq 'setup-approval-gate'){
  $baseline=Remove-SetupApprovalGate $Text
  $sha=[Security.Cryptography.SHA256]::Create()
  try{$hash=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($baseline)))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
  if($hash -ne $Row.operationalChange.priorSourceSha256){throw 'Setup gate includes unreviewed operational changes.'}
  return
 }
 if($Row.file -ne 'BEC-RISK-ASSESSMENT.ps1'  -or $Row.operationalChange.kind -ne 'uri-boundary-fix'){throw 'Unknown approved operational change.'}
 $new='servicePrincipals/${ServicePrincipalId}?`$select';$old='servicePrincipals/$ServicePrincipalId?`$select'
 if(($Text.Split(@($new),[StringSplitOptions]::None).Count-1) -ne 1){throw 'Expected one corrected app lookup boundary.'}
 $baseline=$Text.Replace($new,$old).Replace('if (-not $Result.Ok -or $Result.Data.id -ne $ServicePrincipalId) {','if (-not $Result.Ok) {').Replace('if (-not $Result.Ok -or @($Result.Data.value).Count -ne 1 -or @($Result.Data.value)[0].id -ne $ServicePrincipalId) {','if (-not $Result.Ok -or @($Result.Data.value).Count -lt 1) {')
 $sha=[Security.Cryptography.SHA256]::Create()
 try{$fingerprint=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes((NonPresentation-Tokens $baseline))))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
 if($fingerprint -ne $Row.operationalChange.priorNonPresentationSha256){throw 'App lookup fix includes unreviewed operational changes.'}
}

$rows=Get-Content (Join-Path $Root 'docs/qa/OPERATOR-SCRIPT-ALIGNMENT.json') -Raw|ConvertFrom-Json
$changed=@($rows|Where-Object{$_.changed})
if($rows.Count -ne 81 -or $changed.Count -ne 81){throw 'Unexpected alignment scope.'}
foreach($row in $rows){
 $path=Join-Path $Root $row.path
 $hash=(Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()
 if($hash -ne $row.newSha256){throw "Unrecorded source changes: $($row.file)"}
 if(-not $row.changed){if($hash -ne $row.oldSha256){throw 'Preserved source drifted.'};continue}
 $text=[IO.File]::ReadAllText($path)
 $sha=[Security.Cryptography.SHA256]::Create()
 try{$actual=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes((NonPresentation-Tokens $text))))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
 Assert-ApprovedOperationalChange $row $text
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
 Write-Output "PASS: reviewed source fingerprint / $($row.file)"
}
Write-Output 'PASS: 81 reviewed source comparisons, including the setup documentation-only revision; the setup gate, BEC URI fix and BEC naming migration are explicitly bounded; NoPause remains noninteractive where supported.'
