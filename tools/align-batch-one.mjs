// Reviewed presentation refinements on top of the common console candidate.
import fs from 'node:fs';
const files={account:'published-source/identity/GET-ACCOUNT-STATUS.ps1',forward:'published-source/mailbox/GET-MAILBOX-FORWARDING.ps1',users:'published-source/identity/GET-USER-GROUPS.ps1',members:'published-source/identity/GET-GROUP-MEMBERS.ps1',permissions:'published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1'};
function edit(key,fn){const p=files[key],old=fs.readFileSync(p,'utf8'),next=fn(old);if(old===next)throw Error('No edit: '+key);fs.writeFileSync(p,next);}
function replace(s,a,b){if(!s.includes(a))throw Error('Missing reviewed text: '+a);return s.replace(a,b);}
function finishBeforeExport(s,command,status){
 s=replace(s,command,`Write-FKStatus ${status}\n    Close-FKConsole -SkipPause $true\n\n    ${command}`);
 return s;
}
edit('account',s=>{
 s=replace(s,'Write-Host ("  {0,-42} {1,-11} {2}" -f $row.UPN,$row.AccountStatus,$age)',`Write-FKHeading 'TARGET'
        Write-Host ("UPN: {0}" -f $row.UPN)
        Write-Host ("Account Status: {0}" -f $row.AccountStatus)
        Write-Host ("Recorded Entra Sign-In: {0}" -f $(if ($row.LastSignIn) { $row.LastSignIn } else { $row.SignInStatus }))`);
 s=finishBeforeExport(s,'Offer-VerifiedCsv -Rows @($results) -DefaultName ("account-status-{0}.csv" -f (Get-Date -Format \'yyyyMMdd-HHmmss\'))',"$(if (@($results | Where-Object { $_.AccountStatus -in @('QueryFailed','NotFound','Ambiguous') -or $_.SignInStatus -eq 'Unavailable' }).Count) { 'REVIEW REQUIRED' } else { 'REVIEW COMPLETE' })");
 return replace(s,'Write-OK "Complete. Missing sign-in data was not classified as inactivity."',"Write-Host ''");
});
edit('forward',s=>{
 s=replace(s,"$resolvedForwardingAddress=''","$resolvedForwardingAddress=''\n            Write-FKHeading 'MAILBOX FORWARDING'");
 s=s.replace('Write-Host "Mailbox-level forwarding   : None"',"Write-Host 'Status: None found'").replace('Write-Host "None found"',"Write-Host 'Status: None found'");
 s=finishBeforeExport(s,'Offer-VerifiedCsv -Rows @($rows)',"$(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } elseif (@($rows | Where-Object { $_.Status -eq 'Found' }).Count) { 'FORWARDING CONFIGURED' } else { 'NO FORWARDING FOUND' })");
 return replace(s,'Write-OK "Complete. No changes made."',"Write-Host ''");
});
edit('users',s=>{
 s=s.replace("-Title 'USER GROUP LOOKUP'","-Title 'USER GROUP MEMBERSHIPS'");
 s=replace(s,'param([string]$Title,[object[]]$Rows)', 'param([string]$Title,[object[]]$Rows,[bool]$Available=$true)');
 s=replace(s,'    if (-not $Rows -or $Rows.Count -eq 0) {',"    if (-not $Available) { Write-Host 'Status: Not available' -ForegroundColor Yellow; return }\n\n    if (-not $Rows -or $Rows.Count -eq 0) {");
 s=replace(s,'Write-GroupSection -Title "ACTIVE DIRECTORY GROUPS" -Rows $adRows','Write-GroupSection -Title "ACTIVE DIRECTORY GROUPS" -Rows $adRows -Available ($adResult.Available -and -not $adResult.Error)');
 s=replace(s,'Write-GroupSection -Title "ENTRA ID GROUPS" -Rows $entraRows','Write-GroupSection -Title "ENTRA ID GROUPS" -Rows $entraRows -Available $graphAvailable');
 s=finishBeforeExport(s,'Offer-VerifiedCsv -Rows @($exportRows)',"$(if ($graphFailures -gt 0 -or $adFailures -gt 0) { 'REVIEW REQUIRED' } else { 'LOOKUP COMPLETE' })");
 return replace(s,'Write-OK "Complete. No changes made."',"Write-Host ''");
});
edit('members',s=>{
 s=s.replace("-Title 'GROUP MEMBERS LOOKUP'","-Title 'GROUP MEMBERS'");
 s=finishBeforeExport(s,'Offer-VerifiedCsv -Rows @($detailRows)',"'RUN FINISHED'");
 // This candidate stays held: do not convert the existing failed-read defect
 // into a new successful-coverage claim while doing presentation-only work.
 return replace(s,'Write-Ok "Complete. No changes made."',"Write-Host ''");
});
edit('permissions',s=>{
 s=s.replace("-Title 'MAILBOX PERMISSIONS AUDIT'","-Title 'MAILBOX PERMISSIONS REVIEW'");
 s=s.replaceAll('Write-Host "  none"',"Write-Host 'Status: None found'");
 s=replace(s,"Write-FKHeading -Title 'STATUS'", "Write-FKStatus $(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } else { 'REVIEW COMPLETE' })");
 return replace(s,'Write-Host "Read-only mailbox permissions and forwarding audit. No changes were made."',"Write-Host ''");
});
