param([Parameter(Mandatory=$true)][string]$BaselineRoot)
$ErrorActionPreference='Stop'
$root=Resolve-Path (Join-Path $PSScriptRoot '../..')
$report=Get-Content (Join-Path $root 'docs/qa/CONSOLE-ALIGNMENT-REPORT.json') -Raw | ConvertFrom-Json
$presentation=@('Write-Host','Write-Progress','Write-OK','Write-Info','Write-Warn','Write-Fail','OK','INFO','WARN','RISK','FAIL','Section','Write-Section','Show-Section','Pause-End','Write-GroupSection','Write-FKStart','Write-FKHeading','Write-FKStatus','Close-FKConsole')
function Assert($Value,$Message){if(-not $Value){throw $Message}}
function Is-Presentation($Node){
    $parent=$Node
    while($parent){
        if($parent -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $presentation -contains $parent.Name){return $true}
        if($parent -is [System.Management.Automation.Language.CommandAst] -and $presentation -contains $parent.GetCommandName()){return $true}
        $parent=$parent.Parent
    }
    return $false
}
function Fingerprint($Ast){
    @($Ast.FindAll({param($n)$n -is [System.Management.Automation.Language.CommandAst] -or $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst]},$true) |
        Where-Object {-not (Is-Presentation $_)} | ForEach-Object {$_.Extent.Text -replace '\s+',' '}) -join "`n"
}
$passed=0;$retained=0
foreach($entry in $report){
    $before=Join-Path $BaselineRoot $entry.path;$after=Join-Path $root $entry.path
    if($entry.sha256){Assert ((Get-FileHash $after -Algorithm SHA256).Hash -ieq $entry.sha256) "Report hash is stale: $($entry.path)"}
    if($entry.state -eq 'Unchanged'){
        Assert ((Get-FileHash $before).Hash -eq (Get-FileHash $after).Hash) "Retained file changed: $($entry.path)"
        $retained++;continue
    }
    $errors=$null
    $old=[System.Management.Automation.Language.Parser]::ParseFile($before,[ref]$null,[ref]$null)
    $new=[System.Management.Automation.Language.Parser]::ParseFile($after,[ref]$null,[ref]$errors)
    Assert ($errors.Count -eq 0) "Parser failed: $($entry.path): $errors"
    Assert ($old.ParamBlock.Extent.Text -ceq $new.ParamBlock.Extent.Text) "Entry parameters changed: $($entry.path)"
    $oldCommands=Fingerprint $old;$newCommands=Fingerprint $new
    if($oldCommands -cne $newCommands){
        Compare-Object ($oldCommands -split "`n") ($newCommands -split "`n") | Format-Table | Out-String | Write-Host
        throw "Non-presentation commands/methods changed: $($entry.path)"
    }
    $oldText=Get-Content $before -Raw;$newText=Get-Content $after -Raw
    $oldRequires=($oldText -split "`n" | Where-Object {$_ -match '^#Requires\b'}) -join "`n"
    $newRequires=($newText -split "`n" | Where-Object {$_ -match '^#Requires\b'}) -join "`n"
    Assert ($oldRequires -ceq $newRequires) "Required host changed: $($entry.path)"
    Assert ($newText -match '\.VERSION 0\.1\.0' -and $newText.Contains('Press ESC to close')) "Version/closing contract missing: $($entry.path)"
    $passed++
}
Write-Host "PASS: $passed candidate parsers, unchanged entry parameters and non-presentation command/method fingerprints."
Write-Host "PASS: $retained retained/held sources are byte-identical."
