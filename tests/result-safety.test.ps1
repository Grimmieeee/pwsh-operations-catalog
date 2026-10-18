# Offline endpoint tests. Native calls, printer operations and paths are mocked.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
function Read-SourceAst([string]$Relative) {
    $t=$null;$e=$null;$a=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $Root $Relative),[ref]$t,[ref]$e)
    if ($e.Count) { throw "Parse failed: $Relative" };return $a
}
function Assert-Case([bool]$Ok,[string]$Message) { if (-not $Ok) { throw $Message } }
& {
    $a=Read-SourceAst 'published-source/endpoint/BACKUP-USER-PROFILE.ps1'
    foreach ($f in $a.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]},$false)) { . ([scriptblock]::Create($f.Extent.Text)) }
    function Test-Path { param($Path) return $true }
    function robocopy.exe { $global:LASTEXITCODE=$script:copyCode }
    foreach ($code in @(0,7,8,-1)) {
        $script:copyCode=$code;$log=New-Object System.Collections.ArrayList
        $text=(& { Copy-FolderSafe -Source 'synthetic source & literal' -Destination 'synthetic destination' -Log $log;Show-BackupOutcome -Log $log } 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
        if ($code -in @(0,7)) { Assert-Case ($text -match 'without reported Robocopy errors') "Wrong copy status: $code" }
        else { Assert-Case ($text -match 'STATUS: Incomplete') "Copy failure reported complete: $code" }
        Write-Output "PASS: backup $code"
    }
    foreach ($items in @(@('SKIP | Missing | source'),@('OK | Copied | source','SKIP | Missing | other'))) {
        $log=New-Object System.Collections.ArrayList;foreach ($item in $items) { [void]$log.Add($item) }
        $text=(Show-BackupOutcome -Log $log 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
        Assert-Case ($text -match 'STATUS: (Incomplete|Partial)') 'Missing backup coverage hidden.'
        Write-Output 'PASS: backup coverage'
    }
}
& {
    $a=Read-SourceAst 'published-source/utility/UPDATE-WINDOWS-APPS.ps1'
    foreach ($f in $a.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]},$false)) { . ([scriptblock]::Create($f.Extent.Text)) }
    $main=[scriptblock]::Create(@($a.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.TryStatementAst] })[-1].Extent.Text)
    function Get-Command { [CmdletBinding()]param($Name) @{Source='Invoke-TestWinGet'} }
    function Invoke-TestWinGet { $script:calls++;$global:LASTEXITCODE=if ($script:calls -eq 2) { $script:updateCode } elseif ($script:calls -eq 3) { $script:reviewCode } else { 0 } }
    function Read-Host { param($Prompt) if ($script:cancel) { return 'CANCEL' };return 'UPDATE' }
    foreach ($codes in @(@(0,0),@(1,0),@(0,1))) {
        $script:calls=0;$script:cancel=$false;$script:updateCode=$codes[0];$script:reviewCode=$codes[1];$NoPause=$true;$ReviewOnly=$false
        $text=(& $main 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
        if ($codes[0] -or $codes[1]) { Assert-Case ($text -match 'STATUS: Incomplete') 'WinGet review failure hidden.' }
        else { Assert-Case ($text -match 'does not prove every application is current') 'Blanket update assurance.' }
        Write-Output "PASS: WinGet $($codes -join '/')"
    }
    $script:calls=0;$script:cancel=$true
    $text=(& $main 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-Case ($script:calls -eq 1 -and $text -match 'Cancelled') 'Cancelled update executed.'
    Write-Output 'PASS: WinGet cancellation'
}
& {
    $a=Read-SourceAst 'published-source/endpoint/DEPLOY-TCPIP-PRINTER.ps1'
    $f=$a.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Invoke-PrinterMethodChecked'},$false)
    . ([scriptblock]::Create($f.Extent.Text))
    function Get-CimInstance { [CmdletBinding()]param($ClassName) if ($script:printerCase -eq 'missing') { return };@{Name="Tech's Printer";Default=$script:defaultState} }
    function Invoke-CimMethod {
        [CmdletBinding()]param($InputObject,$MethodName)
        if ($script:printerCase -eq 'method-failed') { return @{ReturnValue=5} }
        if ($script:printerCase -eq 'missing-return') { return @{} }
        if ($script:printerCase -ne 'not-default') { $script:defaultState=$true };@{ReturnValue=0}
    }
    foreach ($case in @('success','missing','method-failed','missing-return','not-default')) {
        $script:printerCase=$case;$script:defaultState=$false;$threw=$false
        try { Invoke-PrinterMethodChecked -Name "Tech's Printer" -Method SetDefaultPrinter } catch { $threw=$true }
        Assert-Case ($threw -eq ($case -ne 'success')) "Wrong printer status: $case"
        Write-Output "PASS: printer $case"
    }
}
Write-Output 'PASS: 15 offline endpoint-result cases. Real Windows/native-device testing remains required.'
