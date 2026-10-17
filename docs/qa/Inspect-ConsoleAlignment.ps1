param([string]$OutputPath)
$ErrorActionPreference='Stop'
$root=Resolve-Path (Join-Path $PSScriptRoot '../..')
$inventory=Get-Content (Join-Path $root 'docs/qa/CATALOG-REVIEW-INVENTORY.json') -Raw | ConvertFrom-Json
$out=@()
foreach($entry in $inventory.entries | Where-Object {$_.publishedPath -and $_.file -like '*.ps1'}){
    $path=Join-Path $root $entry.publishedPath
    $errors=$null;$ast=[System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$errors)
    $functions=@($ast.FindAll({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst]},$true) | ForEach-Object {
        $params=if($_.Parameters){@($_.Parameters.Name.VariablePath.UserPath)}elseif($_.Body.ParamBlock){@($_.Body.ParamBlock.Parameters.Name.VariablePath.UserPath)}else{@()}
        @{name=$_.Name;start=$_.Extent.StartOffset;end=$_.Extent.EndOffset;parameters=$params;text=$_.Extent.Text}
    })
    $commands=@($ast.FindAll({param($n)$n -is [System.Management.Automation.Language.CommandAst]},$true) | ForEach-Object {
        $command=$_;$parent=$_.Parent;$function=$null
        while($parent){if($parent -is [System.Management.Automation.Language.FunctionDefinitionAst]){$function=$parent.Name;break};$parent=$parent.Parent}
        $arg=if($_.CommandElements.Count -gt 1){$_.CommandElements[1]}else{$null}
        @{name=$_.GetCommandName();function=$function;start=$_.Extent.StartOffset;end=$_.Extent.EndOffset;text=$_.Extent.Text;value=$(if($arg -is [System.Management.Automation.Language.StringConstantExpressionAst]){$arg.Value}else{$null})}
    })
    $out+=@{path=$entry.publishedPath;name=$entry.name;batch=$entry.batch;access=$entry.access;version=$entry.version;parseErrors=@($errors|ForEach-Object {$_.Message});functions=$functions;commands=$commands;params=$(if($ast.ParamBlock){$ast.ParamBlock.Extent.Text}else{''})}
}
$out | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $OutputPath -Encoding utf8
Write-Host "Inspected $($out.Count) canonical PowerShell files."
