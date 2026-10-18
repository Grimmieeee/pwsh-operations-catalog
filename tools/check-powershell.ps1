param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
$files = @(& git -C $Root ls-files -- '*.ps1')
if (-not $files.Count) { throw 'No tracked PowerShell sources found.' }
$failures = @()
foreach ($relative in $files) {
    $tokens = $null; $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $Root $relative), [ref]$tokens, [ref]$parseErrors)
    foreach ($problem in $parseErrors) {
        $failures += "${relative}:$($problem.Extent.StartLineNumber): $($problem.Message)"
    }
}
$commandJson = & node (Join-Path $PSScriptRoot 'catalog-commands.mjs')
if ($LASTEXITCODE -ne 0) { throw 'Unable to load effective catalog commands.' }
$commands = @($commandJson | ConvertFrom-Json)
if (-not $commands.Count) { throw 'No inline catalog commands found.' }
foreach ($command in $commands) {
    $tokens = $null; $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput(
        $command.code, [ref]$tokens, [ref]$parseErrors)
    foreach ($problem in $parseErrors) {
        $failures += "Inline command '$($command.name)': $($problem.Message)"
    }
    if ($command.code -match '(?m)^\s*={8,}\s*$') {
        $failures += "Inline command '$($command.name)' includes a decorative separator."
    }
}
if ($failures.Count) { throw ($failures -join [Environment]::NewLine) }
Write-Output "PASS: $($files.Count) PowerShell files and $($commands.Count) catalog command blocks parsed. Nothing was executed."
