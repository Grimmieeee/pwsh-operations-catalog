# Isolated review reproductions only. All service calls are mocked.
$ErrorActionPreference='Stop'
$root=Resolve-Path (Join-Path $PSScriptRoot '../..')
function Assert($Value,$Message){if(-not $Value){throw $Message}}
function Load-Functions($Path,$Names){
    $ast=[System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$null,[ref]$null)
    foreach($name in $Names){
        $fn=$ast.Find({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name},$true)
        Set-Item -Path "function:global:$name" -Value ([scriptblock]::Create($fn.Body.Extent.Text.TrimStart('{').TrimEnd('}')))
    }
    return $ast
}
$null=Load-Functions (Join-Path $root 'published-source/identity/GET-ACCOUNT-STATUS.ps1') @('Get-UserStatus','Encode-Value','Escape-OData')
function Invoke-MgGraphRequest {param($Method,$Uri,$ErrorAction) @{value=@(@{displayName='Example User';userPrincipalName='user@example.invalid';accountEnabled=$null})}}
$row=Get-UserStatus 'user@example.invalid'
Assert ($row.AccountStatus -eq 'Disabled') 'Missing-state reproduction changed'
Write-Host 'REPRODUCED: missing accountEnabled is reported as Disabled'

$path=Join-Path $root 'published-source/identity/GET-GROUP-MEMBERS.ps1'
$ast=[System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$null,[ref]$null)
foreach($fn in $ast.FindAll({param($n)$n -is [System.Management.Automation.Language.FunctionDefinitionAst]},$true)){
    Set-Item -Path "function:global:$($fn.Name)" -Value ([scriptblock]::Create($fn.Body.Extent.Text.TrimStart('{').TrimEnd('}')))
}
function Ensure-Module {param($Name) $true}
function Pause-End {}
function Get-ConnectionInformation {param($ErrorAction) @{State='Connected'}}
function Get-DistributionGroup {param($Identity,$ErrorAction) @{DisplayName='Example Group';PrimarySmtpAddress='group@example.invalid';Identity='fixture-group'}}
function Get-DistributionGroupMember {param($Identity,$ResultSize,$ErrorAction) throw 'Fixture membership read denied'}
function Read-Host {param($Prompt) 'N'}
$InputObject=@('group@example.invalid')
$try=$ast.EndBlock.Statements | Where-Object {$_ -is [System.Management.Automation.Language.TryStatementAst]} | Select-Object -Last 1
$output=(& ([scriptblock]::Create($try.Extent.Text)) 6>&1 | Out-String)
Assert ($output -match 'Members\s*:\s*0' -and $output -match 'none' -and $output -notmatch 'Fixture membership read denied') 'Failed-member-query reproduction changed'
Write-Host 'REPRODUCED: denied group-member read is displayed as zero members / none'

function Get-MgGroup {param($Filter,$ErrorAction) @([pscustomobject]@{Id='one';DisplayName='Shared Name'},[pscustomobject]@{Id='two';DisplayName='Shared Name'})}
$match=Get-GraphGroupByInput 'Shared Name'
Assert ($match.Id -eq 'one') 'Duplicate-name reproduction changed'
Write-Host 'REPRODUCED: duplicate Entra group names silently select the first match'
