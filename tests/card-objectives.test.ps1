# Source/objective parity and non-presentation comparisons; no live services run.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$specs=Get-Content (Join-Path $Root 'operator-card-specs.json') -Raw|ConvertFrom-Json
$records=@(Get-Content (Join-Path $Root 'docs/qa/CARD-OBJECTIVES-REVIEW.json') -Raw|ConvertFrom-Json)
$alignment=@(Get-Content (Join-Path $Root 'docs/qa/RELATIONSHIP-ALIGNMENT-REVIEW.json') -Raw|ConvertFrom-Json)
$t=$null;$e=$null
$helpers=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'operator-alignment.test.ps1'),[ref]$t,[ref]$e)
foreach($name in @('Pure-Print','NonPresentation-Tokens','Assert-ApprovedOperationalChange')){
 $fn=$helpers.Find({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$false)
 . ([scriptblock]::Create($fn.Extent.Text))
}
if($records.Count -ne 81){throw 'All 81 objectives must be reviewed.'}
foreach($r in $records){
 $objective=[string]$specs.($r.file).objective
 if($objective -cne $r.objective -or -not $objective.EndsWith('.') -or ($objective -split '\s+').Count -gt 17){throw "Objective copy mismatch: $($r.file)"}
 $path=Join-Path $Root $r.path;$text=[IO.File]::ReadAllText($path)
 $pattern=if($r.metadataReuse){'(?m)^\.DESCRIPTION (.+)\r?$'}elseif($text -match '(?m)^# OBJECTIVE: '){'(?m)^# OBJECTIVE: (.+)\r?$'}else{'(?m)^OBJECTIVE\r?\n([^\r\n]+)'}
 $match=[regex]::Match($text,$pattern)
 if(-not $match.Success -or $match.Groups[1].Value.Trim() -cne $objective){throw "Script objective differs: $($r.file)"}
 $hash=(Get-FileHash $path -Algorithm SHA256).Hash.ToLowerInvariant()
 if($hash -ne $r.newSha256){throw "Unreviewed source bytes: $($r.file)"}
 if(-not $r.changed -and $hash -ne $r.oldSha256){throw 'Preserved IR release drifted.'}
 $sha=[Security.Cryptography.SHA256]::Create()
 try{$fingerprint=([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes((NonPresentation-Tokens $text))))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
 Assert-ApprovedOperationalChange $r $text
 if($fingerprint -ne $r.nonPresentationSha256){throw "Non-presentation tokens changed: $($r.file)"}
 if($r.consoleObjective){
  $tokens=$null;$errors=$null;$a=[System.Management.Automation.Language.Parser]::ParseInput($text,[ref]$tokens,[ref]$errors)
  $matching=@($a.FindAll({param($n)$n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -in @('Write-Host','Write-FKReportLine','Write-IRLine') -and $n.CommandElements.Count -gt 1 -and $n.CommandElements[1] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $n.CommandElements[1].Value -ceq $objective},$true))
  if(-not $matching.Count){throw "Console objective differs: $($r.file)"}
  $title=$a.Find({param($n)$n -is [System.Management.Automation.Language.CommandAst] -and $n.GetCommandName() -in @('Write-Host','Write-FKReportLine','Write-IRLine') -and $n.CommandElements.Count -gt 1 -and $n.CommandElements[1] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $n.CommandElements[1].Value -ceq $r.name},$true)
  if(-not $title){throw "Console title differs: $($r.file)"}
 }
 $review=$alignment|Where-Object{$_.file -eq $r.file}|Select-Object -First 1
 if(-not $review -or $review.newSha256 -ne $hash -or $review.nonPresentationSha256 -ne $fingerprint){throw "Relationship source review is stale: $($r.file)"}
 if($r.metadataReuse){
  $workflow=$specs.($r.file).workflowReview
  if($workflow.sourceSha256 -ne $hash -or $workflow.nonPresentationSha256 -ne $fingerprint -or $workflow.baselineVerification.sha256 -ne $review.oldSha256){throw 'BEC presentation review is not bound to the compared source and accepted baseline.'}
 }
 Write-Output "PASS: card/script objective / $($r.file)"
}
Write-Output 'PASS: all 81 documented objectives match; console objectives match where present; existing non-presentation tokens unchanged except the bounded BEC app-lookup fix.'
