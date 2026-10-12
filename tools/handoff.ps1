#requires -Version 5.1
# Compatibility entry point. Canonical implementation: git-handoff.ps1.
[CmdletBinding()]
param(
    [Parameter(Position=0)][string]$Path = (Get-Location).Path,
    [switch]$Open
)
& (Join-Path $PSScriptRoot 'git-handoff.ps1') -Path $Path -Open:$Open
