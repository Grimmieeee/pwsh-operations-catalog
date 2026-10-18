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
if ($failures.Count) { throw ($failures -join [Environment]::NewLine) }
Write-Output "PASS: $($files.Count) PowerShell files parsed. No scripts were executed."
