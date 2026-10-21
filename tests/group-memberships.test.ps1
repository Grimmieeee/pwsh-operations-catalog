# Offline regression checks. No live directory calls or authentication.
param([string]$Root=(Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference='Stop'
$tokens=$null;$errors=$null
$ast=[System.Management.Automation.Language.Parser]::ParseFile((Join-Path $Root 'published-source/identity/GET-USER-GROUPS.ps1'),[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw $errors[0] }
function Assert-Case([bool]$Ok,[string]$Message) { if (-not $Ok) { throw $Message } }
foreach ($f in $ast.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]},$false)) {
    . ([scriptblock]::Create($f.Extent.Text))
}
$main=[scriptblock]::Create(@($ast.EndBlock.Statements | Where-Object { $_ -is [System.Management.Automation.Language.TryStatementAst] })[-1].Extent.Text)
& {
    function Connect-GraphForUser {
        if ($script:graphState -eq 'User not found') { throw 'The user was not found in the connected tenant.' }
        if ($script:graphState -eq 'Unavailable') { throw [IO.FileNotFoundException]::new('Graph module missing') }
        if ($script:graphState -eq 'Failed') { throw 'Access denied' }
        [pscustomobject]@{id='synthetic';displayName='Test User'}
    }
    function Get-GraphGroups {
        if ($script:graphState -eq 'Group404') { throw [System.Net.Http.HttpRequestException]::new('Group disappeared',$null,[System.Net.HttpStatusCode]::NotFound) }
        if ($script:graphState -eq 'Empty') { return @() }
        [pscustomobject]@{Name='Cloud Group';OnPremisesSyncEnabled=$false;IsDynamic=$false;IsMicrosoft365=$true}
    }
    function Get-ADUserAndGroups {
        $groups=@();$user=$null
        if ($script:adState -eq 'Checked') { $groups=@([pscustomobject]@{Name='AD Group'}) }
        if ($script:adState -in @('Checked','Empty')) { $user=[pscustomobject]@{DisplayName='Test User'} }
        [pscustomobject]@{Status=$(if ($script:adState -eq 'Empty') {'Checked'} else {$script:adState});Groups=$groups;User=$user;Error=$(if ($script:adState -eq 'Failed') {'AD query denied'} else {''})}
    }
    function Offer-VerifiedCsv { param($Rows) $script:exported=@($Rows);if ($script:exportFails) { throw 'Disk full' } }
    function Pause-End { $script:pauses++ }
    foreach ($case in @(
        @('Checked','Checked','SUCCESS'),@('Empty','Empty','SUCCESS'),
        @('Unavailable','Checked','PARTIAL'),@('Failed','Checked','PARTIAL'),
        @('User not found','User not found','USER NOT FOUND'),
        @('Unavailable','User not found','UNSUCCESSFUL'),
        @('Failed','Failed','UNSUCCESSFUL'),@('Checked','Group404','PARTIAL')
    )) {
        $script:adState=$case[0];$script:graphState=$case[1];$script:pauses=0;$script:exportFails=$false
        $InputObject=@('user@contoso.com')
        $text=(& $main 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
        Assert-Case ($text -match "SESSION COMPLETE // $($case[2])") "Wrong final state: $($case -join '/')"
        Assert-Case ($script:pauses -eq 1) 'Expected exactly one final pause'
        if ($case[0] -notin @('Empty') -and $case[1] -notin @('Empty')) {
            Assert-Case ($text -notmatch 'no groups found') 'Failure shown as empty memberships'
        }
        if ($case[1] -eq 'Group404') { Assert-Case ($script:exported[-1].Coverage -eq 'Failed') 'Group 404 misreported as missing user' }
        Write-Output "PASS: $($case -join '/')"
    }
    $script:adState='Checked';$script:graphState='Checked'
    $InputObject=@('invalid','user@contoso.com')
    $text=(& $main 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-Case ($text -match 'SESSION COMPLETE // PARTIAL' -and $text -match 'Invalid inputs skipped: 1') 'Invalid input hidden'
    $InputObject=@('invalid')
    $text=(& $main 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-Case ($text -match 'SESSION COMPLETE // UNSUCCESSFUL') 'All-invalid input reported successful'
    $InputObject=@('user@contoso.com');$script:exportFails=$true
    $text=(& $main 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-Case ($text -match 'SESSION COMPLETE // PARTIAL' -and $text -match 'export is unverified') 'Failed export hidden'
    $script:exportFails=$false;$InputObject=@('first@contoso.com','second@contoso.com')
    $text=(& $main 6>&1 | ForEach-Object { [string]$_ }) -join "`n"
    Assert-Case ($script:exported.Count -eq 4) 'Bulk results lost'
    Write-Output 'PASS: invalid, bulk and export-failure outcomes'
}
& {
    function Import-ActiveDirectoryTools { $script:moduleAvailable }
    function Get-OnPremDomainController { 'synthetic-dc' }
    function Resolve-AuthoritativeADUser { if ($script:userFound) { [pscustomobject]@{DistinguishedName='synthetic'} } }
    function Get-ADPrincipalGroupMembership { [CmdletBinding()]param($Identity,$Server) if ($script:adDenied) { throw 'Access denied' };@() }
    $script:moduleAvailable=$true;$script:userFound=$false
    Assert-Case ((Get-ADUserAndGroups 'user@contoso.com').Status -eq 'User not found') 'Missing AD identity reported empty'
    $script:userFound=$true;$script:adDenied=$true
    Assert-Case ((Get-ADUserAndGroups 'user@contoso.com').Status -eq 'Failed') 'AD lookup error lost'
    $script:adDenied=$false
    Assert-Case ((Get-ADUserAndGroups 'user@contoso.com').Status -eq 'Checked') 'Successful empty query not checked'
    $script:moduleAvailable=$false
    Assert-Case ((Get-ADUserAndGroups 'user@contoso.com').Status -eq 'Unavailable') 'Missing AD module reported failed/empty'
    Write-Output 'PASS: AD identity, empty, failed and unavailable states'
}
& {
    function Get-UniqueADUserMatch { param($Filter,$Server,$Properties,$Method) $script:filters+=@($Filter);return $null }
    $script:filters=@()
    $result=Resolve-AuthoritativeADUser -UserPrincipalName 'user@contoso.com' -Server 'synthetic' -GraphUser ([pscustomobject]@{onPremisesSamAccountName='user'})
    Assert-Case ($null -eq $result -and ($script:filters -join ' ') -notmatch 'SamAccountName') 'Uncorroborated username lookup remains'
    Write-Output 'PASS: exact identity resolution does not fall back to local username'
}
& {
    $temp=Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString())
    New-Item -ItemType Directory $temp | Out-Null
    try {
        Set-Content (Join-Path $temp 'users.txt') "# comment`nuser@contoso.com`nuser@contoso.com`nsecond@contoso.com"
        Set-Content (Join-Path $temp 'users.csv') "UPN`nuser@contoso.com`nsecond@contoso.com"
        foreach ($file in @('users.txt','users.csv')) { Assert-Case (@(Get-InputUsers -Values (Join-Path $temp $file)).Count -eq 2) "Input failed: $file" }
        $script:csvPath=Join-Path $temp 'result.csv'
        function Read-Host { param($Prompt) if ($Prompt -like 'Export*') { 'Y' } else { $script:csvPath } }
        $rows=@([pscustomobject]@{UserUPN='user@contoso.com';Group='Example, Group';Dynamic=$false;Coverage='Checked'},[pscustomobject]@{UserUPN='second@contoso.com';Group='';Dynamic=$false;Coverage='User not found'})
        $text=(Offer-VerifiedCsv -Rows $rows 6>&1 | ForEach-Object {[string]$_}) -join "`n"
        Assert-Case ($text -match 'Exported and verified' -and @(Import-Csv $script:csvPath).Count -eq 2) 'CSV roundtrip failed'
        function Import-Csv { [CmdletBinding()]param($LiteralPath) @([pscustomobject]@{UserUPN='user@contoso.com';Group='WRONG';Dynamic=$false;Coverage='Checked'},[pscustomobject]@{UserUPN='second@contoso.com';Group='';Dynamic=$false;Coverage='User not found'}) }
        $threw=$false;try { Offer-VerifiedCsv -Rows $rows } catch { $threw=$true }
        Assert-Case $threw 'CSV field corruption passed verification'
        Write-Output 'PASS: TXT/CSV inputs and real CSV roundtrip; altered fields rejected'
    }
    finally { Remove-Item -LiteralPath $temp -Recurse -Force }
}
Write-Output 'PASS: Group Memberships offline regressions. Live AD/Entra and Explorer launch are not tested here.'
