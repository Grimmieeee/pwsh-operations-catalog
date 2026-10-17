# Run in a fresh process. Service commands are fixtures; local exports use fake data.
$ErrorActionPreference='Stop'
$root=Resolve-Path (Join-Path $PSScriptRoot '../..')
$global:Scenario='Clean';$global:ExportFixture=$false;$global:ClosingPrompts=0;$global:ExportPrompts=0
$temp=Join-Path ([IO.Path]::GetTempPath()) ('field-kit-format-'+[guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path $temp)
function Assert($Value,$Message){if(-not $Value){throw $Message}}
function Get-Module {param($Name,[switch]$ListAvailable,$ErrorAction)
    if($Name -eq 'ActiveDirectory' -and $global:Scenario -eq 'ADUnavailable'){return}
    [pscustomobject]@{Path='fixture';Name=$Name;Version=[version]'99.0'}
}
function Import-Module {param($Name,[switch]$Force,[switch]$UseWindowsPowerShell,$WarningAction,$ErrorAction)}
function Get-MgContext {param($ErrorAction) [pscustomobject]@{Account='operator@example.invalid';TenantId='fixture';Scopes=@('User.Read.All','Group.Read.All','Directory.Read.All','AuditLog.Read.All')}}
function Connect-MgGraph {param($TenantId,$Scopes,$ContextScope,[switch]$NoWelcome,$ErrorAction) throw 'Unexpected extra sign-in'}
function Get-ConnectionInformation {param($ErrorAction) [pscustomobject]@{State='Connected';ConnectionStatus='Connected'}}
function Connect-ExchangeOnline {param([switch]$ShowBanner,$ErrorAction) throw 'Unexpected extra sign-in'}
function Invoke-MgGraphRequest {param($Method,$Uri,$OutputType,$ErrorAction)
    Assert ($Method -eq 'GET') 'Non-read Graph request during formatting test'
    if($Uri -match '/organization'){return @{value=@(@{verifiedDomains=@(@{name='example.invalid'})})}}
    if($Uri -match '/memberOf'){return @{value=@(@{id='sync';'@odata.type'='#microsoft.graph.group'},@{id='cloud';'@odata.type'='#microsoft.graph.group'})}}
    if($Uri -match '/groups/sync'){return @{id='sync';displayName='Finance';onPremisesSyncEnabled=$true;groupTypes=@()}}
    if($Uri -match '/groups/cloud'){return @{id='cloud';displayName='Microsoft 365 Users';onPremisesSyncEnabled=$false;groupTypes=@('DynamicMembership')}}
    if($Uri -match '/users\?'){
        if($global:Scenario -eq 'QueryDenied'){throw 'Fixture user query denied'}
        return @{value=@(@{displayName='Example User';userPrincipalName='user@example.invalid';accountEnabled=$true;signInActivity=@{lastSignInDateTime='2026-10-16T15:42:00Z'}})}
    }
    if($Uri -match '/users/'){return @{id='fixture-user';displayName='Example User';userPrincipalName='user@example.invalid';mail='user@example.invalid';onPremisesSamAccountName='fixture-user'}}
    throw "Unexpected Graph query: $Uri"
}
function Get-Mailbox {param($Identity,$ErrorAction)
    [pscustomobject]@{Identity='fixture-mailbox';DisplayName='Example User';PrimarySmtpAddress='user@example.invalid';ForwardingAddress=$null;ForwardingSmtpAddress=$(if($global:Scenario -eq 'Forwarding'){'smtp:forward@example.invalid'}else{$null});DeliverToMailboxAndForward=$false;GrantSendOnBehalfTo=@()}
}
function Get-InboxRule {param($Mailbox,[switch]$IncludeHidden,$ErrorAction)
    if($global:Scenario -eq 'HiddenDenied' -and $IncludeHidden){throw 'Fixture hidden-rule read denied'}
    return @()
}
function Get-MailboxPermission {param($Identity,$ErrorAction)
    if($global:Scenario -eq 'Delegated'){[pscustomobject]@{User='delegate@example.invalid';IsInherited=$false;AccessRights=@('FullAccess')}}
}
function Get-RecipientPermission {param($Identity,$ErrorAction) @()}
function Get-DistributionGroup {param($Identity,$ErrorAction) [pscustomobject]@{Identity='fixture-group';DisplayName='Finance';PrimarySmtpAddress='finance@example.invalid'}}
function Get-DistributionGroupMember {param($Identity,$ResultSize,$ErrorAction)
    @([pscustomobject]@{DisplayName='Example User';PrimarySmtpAddress='user@example.invalid'},[pscustomobject]@{DisplayName='Sample User';PrimarySmtpAddress='sample@example.invalid'})
}
function Get-ADDomain {param($ErrorAction,$WarningAction) @{PDCEmulator='fixture-dc'}}
function Get-ADDomainController {param($Identity,$Filter,$ErrorAction,$WarningAction) @{HostName='fixture-dc';IsReadOnly=$false}}
function Get-ADUser {param($Filter,$Server,$Properties,$ErrorAction,$WarningAction) [pscustomobject]@{DisplayName='Example User';DistinguishedName='CN=Fixture';UserPrincipalName='user@example.invalid'}}
function Get-ADPrincipalGroupMembership {param($Identity,$Server,$ErrorAction,$WarningAction) @([pscustomobject]@{Name='Domain Users'},[pscustomobject]@{Name='Finance'})}
function Read-Host {param($Prompt)
    if($Prompt -like 'Type ESC*'){$global:ClosingPrompts++;return 'ESC'}
    if($Prompt -like 'Export *'){$global:ExportPrompts++;return $(if($global:ExportFixture){'Y'}else{'N'})}
    if($Prompt -like 'CSV output path*'){return (Join-Path $temp 'results.csv')}
    throw "Unexpected prompt: $Prompt"
}
try {
    $account=Join-Path $root 'published-source/identity/GET-ACCOUNT-STATUS.ps1'
    $forward=Join-Path $root 'published-source/mailbox/GET-MAILBOX-FORWARDING.ps1'
    $users=Join-Path $root 'published-source/identity/GET-USER-GROUPS.ps1'
    $members=Join-Path $root 'published-source/identity/GET-GROUP-MEMBERS.ps1'
    $permissions=Join-Path $root 'published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1'
    $output=(& $account -InputObject 'user@example.invalid' -TenantDomain 'example.invalid' 6>&1|Out-String)
    Assert ($output.Contains('TARGET') -and $output.Contains('Recorded Entra Sign-In:') -and $output.Contains('STATUS: REVIEW COMPLETE') -and -not $output.Contains('[FAIL]')) "Account presentation failed: $output"
    Write-Host 'PASS AccountDateAndReviewOutput'
    $global:Scenario='QueryDenied'
    $output=(& $account -InputObject 'user@example.invalid' -TenantDomain 'example.invalid' 6>&1|Out-String)
    Assert ($output.Contains('QueryFailed') -and $output.Contains('STATUS: REVIEW REQUIRED')) "Denied query was hidden: $output"
    Write-Host 'PASS AccountDeniedIsReviewRequired'
    $global:Scenario='Clean';$global:ExportFixture=$true
    @('user@example.invalid','user@example.invalid')|Set-Content (Join-Path $temp 'inputs.txt')
    $output=(& $account -InputPath (Join-Path $temp 'inputs.txt') -TenantDomain 'example.invalid' 6>&1|Out-String)
    $export=@(Import-Csv (Join-Path $temp 'results.csv'))
    Assert ($export.Count -eq 1 -and $export[0].UPN -eq 'user@example.invalid' -and $export[0].PSObject.Properties.Name -contains 'DaysSince') 'Input deduplication/export schema changed'
    Write-Host 'PASS BulkInputAndVerifiedExportPreserved'
    $global:ExportFixture=$false
    foreach($scenario in @('Clean','Forwarding','HiddenDenied')){
        $global:Scenario=$scenario
        $output=(& $forward -InputObject 'user@example.invalid' 6>&1|Out-String)
        $status=@{Clean='NO FORWARDING FOUND';Forwarding='FORWARDING CONFIGURED';HiddenDenied='REVIEW REQUIRED'}[$scenario]
        Assert ($output.Contains("STATUS: $status")) "Forwarding $scenario failed: $output"
        if($scenario -eq 'Forwarding'){Assert ($output.Contains('forward@example.invalid')) 'Forwarding target hidden'}
        Write-Host "PASS Forwarding-$scenario"
    }
    foreach($scenario in @('Clean','ADUnavailable')){
        $global:Scenario=$scenario
        $output=(& $users -InputObject 'user@example.invalid' 6>&1|Out-String)
        Assert ($output.Contains('[Synced]') -and $output.Contains('[Cloud] [Dynamic]')) "Source markers lost: $output"
        if($scenario -eq 'ADUnavailable'){
            Assert ($output -match 'ACTIVE DIRECTORY GROUPS\s+Status: Not available' -and $output.Contains('STATUS: REVIEW REQUIRED')) "Unavailable AD shown as empty: $output"
        }else{Assert (($output -split 'Finance').Count -ge 3) 'AD/Entra overlap was deduplicated'}
        Write-Host "PASS UserGroups-$scenario"
    }
    $global:Scenario='Clean'
    $output=(& $members -InputObject 'finance@example.invalid' 6>&1|Out-String)
    Assert ($output.Contains('Example User <user@example.invalid>') -and $output.Contains('Source  : Exchange Distribution Group')) "Member output changed: $output"
    Write-Host 'PASS GroupMemberDetailPreserved'
    foreach($scenario in @('Delegated','HiddenDenied')){
        $global:Scenario=$scenario;$global:ExportPrompts=0
        $output=(& $permissions -UPN 'user@example.invalid' 6>&1|Out-String)
        Assert ($global:ExportPrompts -eq 0) 'Mailbox Permissions gained an export prompt'
        if($scenario -eq 'Delegated'){Assert ($output.Contains('delegate@example.invalid')) 'Delegate not shown'}
        else{Assert ($output.Contains('Hidden-rule visibility is not available') -and $output.Contains('STATUS: REVIEW REQUIRED')) 'Visible-only coverage warning lost'}
        Write-Host "PASS MailboxPermissions-$scenario"
    }
    Assert ($global:ClosingPrompts -eq 11) "Wrong number of end prompts: $global:ClosingPrompts"
    Write-Host 'PASS OneClosingPromptPerRun'
}
finally {Remove-Item -LiteralPath $temp -Recurse -Force}
