# Offline tests for group creation and accepted-password-reset verification.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
function Get-TestAst([string]$Path) {
    $t=$null;$e=$null;$a=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $Root $Path),[ref]$t,[ref]$e)
    if ($e.Count) { throw 'Source does not parse.' };return $a
}
function Assert-Change([bool]$Ok,[string]$Message) { if (-not $Ok) { throw $Message } }
& {
    $a=Get-TestAst 'published-source/identity/INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1'
    foreach ($f in $a.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]},$false)) { . ([scriptblock]::Create($f.Extent.Text)) }
    $main=[scriptblock]::Create(@($a.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.TryStatementAst] })[-1].Extent.Text)
    $script:groupTenant='11111111-1111-4111-8111-111111111111'
    function New-GroupContext { @{TenantId=$script:groupTenant;Account='operator@example.invalid';AuthType='Delegated';ContextScope='Process';Scopes=@('Group.ReadWrite.All','Directory.Read.All')} }
    function Get-Module { [CmdletBinding()]param($Name,[switch]$ListAvailable) @{Path='offline';Version=[version]'2.0'} }
    function Import-Module { [CmdletBinding()]param($Name,[switch]$Force) }
    function Get-MgContext { [CmdletBinding()]param() $script:groupContext }
    function Disconnect-MgGraph { [CmdletBinding()]param() $script:groupContext=$null }
    function Connect-MgGraph {
        [CmdletBinding()]param($Scopes,$TenantId,$ContextScope,[switch]$NoWelcome)
        Assert-Change ($TenantId -eq $script:groupTenant -and $ContextScope -eq 'Process') 'Unsafe group sign-in parameters.'
        $script:groupContext=New-GroupContext
        if ($script:groupCase -eq 'signin-mismatch') { $script:groupContext.TenantId='22222222-2222-4222-8222-222222222222' }
    }
    function Invoke-MgGraphRequest {
        [CmdletBinding()]param($Method,$Uri,$Body,$ContentType)
        $script:groupCalls++
        if ($Method -eq 'POST') {
            $script:groupPosts++
            if ($script:groupCase -eq 'request-failed') { throw 'Offline unknown request outcome.' }
            $script:createdGroup=$Body | ConvertFrom-Json;$script:createdGroup | Add-Member NoteProperty id 'created-id'
            return @{id='created-id'}
        }
        if ($Method -ne 'GET' -or $Uri -notmatch '/groups\?') { throw 'Unexpected offline group route.' }
        if ($script:groupCase -eq 'read-denied') { throw 'Offline access denied.' }
        if ($script:groupCase -eq 'malformed') { return @{} }
        if ($script:groupCase -eq 'ambiguous') { return @{value=@(@{id='one'},@{id='two'})} }
        if ($script:groupCase -eq 'existing') { return @{value=@(@{id='existing';displayName='Audit group'})} }
        if ($script:groupPosts) {
            if ($script:groupCase -eq 'verification-failed') { $script:createdGroup.membershipRule='different' }
            return @{value=@($script:createdGroup)}
        }
        return @{value=@()}
    }
    function Read-Host {
        param($Prompt)
        if ($Prompt -like 'Display name*' -or $Prompt -like 'Mail nickname*') { return '' }
        if ($Prompt -eq 'Type CREATE to continue') {
            $script:groupApprovals++
            if ($script:groupCase -eq 'cancel') { return 'CANCEL' }
            if ($script:groupCase -eq 'context-changed') { $script:groupContext.TenantId='22222222-2222-4222-8222-222222222222' }
            return 'CREATE'
        }
        if ($Prompt -eq 'Press Enter to close') { return '' }
        throw "Unexpected group prompt: $Prompt"
    }
    function Clear-Host {}
    function Start-Sleep { param($Milliseconds) }
    foreach ($case in @('success','cancel','wrong-tenant','invalid-tenant','signin-mismatch','new-session','current-user','missing-scope','read-denied','malformed','ambiguous','existing','request-failed','context-changed','verification-failed')) {
        $script:groupCase=$case;$script:groupContext=New-GroupContext;$script:groupCalls=0;$script:groupPosts=0;$script:groupApprovals=0
        $DisplayName='Audit group';$MailNickname='AuditGroup';$ExpectedTenantId=$script:groupTenant
        if ($case -eq 'wrong-tenant') { $script:groupContext.TenantId='22222222-2222-4222-8222-222222222222' }
        if ($case -eq 'invalid-tenant') { $ExpectedTenantId='invalid' }
        if ($case -in @('new-session','signin-mismatch')) { $script:groupContext=$null }
        if ($case -eq 'current-user') { $script:groupContext.ContextScope='CurrentUser' }
        if ($case -eq 'missing-scope') { $script:groupContext.Scopes=@() }
        $text=(& $main 6>&1 | ForEach-Object {[string]$_}) -join "`n"
        if ($case -in @('success','new-session','current-user','missing-scope')) {
            Assert-Change ($script:groupPosts -eq 1 -and $script:groupApprovals -eq 1 -and $text -match 'Group created and verified') "Group success failed: $case / $text"
        } else {
            Assert-Change ($text -notmatch 'Group created and verified') "False group success: $case"
            if ($case -in @('request-failed','verification-failed')) { Assert-Change ($script:groupPosts -eq 1) 'Expected one attempted group request.' }
            else { Assert-Change ($script:groupPosts -eq 0) "Unexpected group mutation: $case" }
            if ($case -in @('wrong-tenant','invalid-tenant','signin-mismatch')) { Assert-Change ($script:groupCalls -eq 0) 'Wrong tenant allowed Graph data access.' }
        }
        Write-Output "PASS: group $case"
    }
}
& {
    $a=Get-TestAst 'published-source/identity/INVOKE-RESET-CLOUD-USER-PASSWORD.ps1'
    $f=$a.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Test-ResetTimestamp'},$false)
    . ([scriptblock]::Create($f.Extent.Text))
    function Start-Sleep { param($Seconds) }
    function Get-GraphUser {
        param($UPN)
        if ($script:resetCase -eq 'denied') { throw 'Offline read denied after an accepted reset.' }
        if ($script:resetCase -eq 'missing') { return @{} }
        @{lastPasswordChangeDateTime=$(if ($script:resetCase -eq 'changed') {'new'} else {'old'})}
    }
    foreach ($case in @('changed','same','missing','denied')) {
        $script:resetCase=$case;$verified=Test-ResetTimestamp -UPN 'user@example.invalid' -Before 'old'
        Assert-Change ($verified -eq ($case -eq 'changed')) "Wrong reset verification: $case"
        Write-Output "PASS: reset verification $case"
    }
}
& {
    $a=Get-TestAst 'published-source/tenant/GET-APP-REGISTRATION-AUDIT.ps1'
    $f=$a.Find({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-CredentialExpiryFinding'},$false)
    . ([scriptblock]::Create($f.Extent.Text))
    $now=[datetime]'2026-01-01';$soon=$now.AddDays(30)
    foreach ($kind in @('Secret','Certificate')) {
        foreach ($case in @(@{Value=$null;Expected='expiry unavailable'},@{Value='not-a-date';Expected='expiry unavailable'},@{Value='2025-12-01';Expected='Expired'},@{Value='2026-01-10';Expected='expiring soon'},@{Value='2027-01-01';Expected=' OK'})) {
            $finding=Get-CredentialExpiryFinding -EndDate $case.Value -Now $now -Soon $soon -Kind $kind
            Assert-Change ($finding -match $case.Expected) "Incorrect credential expiry classification: $kind / $finding"
        }
    }
    Write-Output 'PASS: 10 credential-expiry cases'
}
Write-Output 'PASS: 29 offline group/reset/expiry cases. No credentials generated or service writes executed.'
