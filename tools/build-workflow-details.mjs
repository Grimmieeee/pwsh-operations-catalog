// Troubleshooting suggestions are tied to reviewed source branches, not observed failure rates.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const rules=[
 ['Existing Graph session is for another tenant.', 'Wrong tenant session', 'Open a new PowerShell window and sign in to the intended tenant. Confirm its tenant ID before continuing.'],
 ['Next script not found:', 'Next workflow script is missing', 'Extract all three BEC files into the same folder with their original filenames. Keep the workflow in one PowerShell window.'],
 ['Next script is from a different release.', 'BEC files are from different releases', 'Replace all three files with one matching workflow package before continuing.'],
 ['Exchange tenant does not match Graph.', 'Graph and Exchange tenants differ', 'Stop. Use a fresh workflow window and sign in to the same customer tenant for both services.'],
 ['The baseline belongs to a different Entra tenant.', 'Baseline belongs to another tenant', 'Select the saved baseline for this tenant. Do not overwrite another tenant’s baseline to get past the check.'],
 ['Group lookup is ambiguous.', 'More than one group matches', 'Resolve the duplicate names in Entra before creating another group.'],
 ['No reputation provider API key was supplied.', 'No reputation API key', 'Supply an authorized key for a supported provider when prompted.'],
 ['No public IP addresses remain', 'No eligible public IPs', 'Use public IP addresses from the incident evidence; private or invalid addresses are excluded.'],
 ['Expected a three-part JWT', 'Token format is unsupported', 'Paste only the three-part JWT. Encrypted JWE tokens cannot be decoded by this tool.'],
 ['JWT header or payload could not be base64url-decoded.', 'Token could not be decoded', 'Copy the complete token again without extra text or whitespace. Do not upload it to an online decoder.'],
 ['Get-MessageTraceV2 is unavailable.', 'Message-trace command is unavailable', 'Update ExchangeOnlineManagement through your approved module setup, then reopen PowerShell and reconnect.'],
 ['Search-UnifiedAuditLog is unavailable', 'Audit search is unavailable', 'Check the Exchange connection and the account’s audit-search access. Reconnect with the approved account before retrying the lookup.'],
 ['Case folder not found:', 'Case folder was not found', 'Enter the full path to the existing folder containing the incident evidence.'],
 ['Input file not found:', 'Input file was not found', 'Use the full path to an existing local input file. Check the filename and extension.'],
 ['Column not found:', 'CSV column was not found', 'Check the CSV header and choose the column containing the intended targets.'],
 ['Invalid UPN', 'User address is invalid', 'Enter the full sign-in name, such as <name>@domain.com. Remove blank entries and display names from the target list.'],
 ['Every target must be a valid user UPN.', 'User address is invalid', 'Use full sign-in names such as <name>@domain.com, one tenant at a time.'],
 ['Group was not found in Exchange, Entra ID, or Active Directory.', 'Group was not found', 'Check the exact group name or email address and the connected customer tenant. Confirm access to the directory that owns the group.'],
 ['The user was not found in the connected tenant.', 'User was not found', 'Check the full sign-in name and that the session is connected to the customer tenant containing that account.'],
 ['Mailbox lookup failed:', 'Mailbox lookup failed', 'Check the mailbox address, connected tenant, and the account’s Exchange read access.'],
 ['A valid expected tenant ID is required.', 'Tenant ID is invalid', 'Copy the tenant ID (GUID) from Entra Overview. A domain name does not replace the ID for this workflow.'],
 ['Graph collection data is unavailable', 'Review is incomplete', 'Read the reported API error, check the required access in Permissions, and retry the read after the connection or service issue is resolved.'],
 ['No reachable writable domain controller', 'No writable domain controller is reachable', 'Check domain connectivity and DNS from the support computer, and confirm the supplied controller is reachable and writable.'],
 ['CSV contains no data rows.', 'CSV has no targets', 'Keep the header row and add at least one target below it. Check the selected input column.'],
 ['Output folder not found:', 'Output folder was not found', 'Choose an existing folder you can write to. Check the saved output path before rerunning any action.'],
 ['Report folder does not exist.', 'HTML report could not be saved', 'Choose another existing, writable folder at the save prompt. Cancelling the export does not erase the displayed findings.'],
 ['CSV verification failed.', 'CSV could not be verified', 'Check the displayed export error and output path. Do not use the file as verified evidence; review the on-screen results before retrying.'],
 ['Root not found:', 'Root folder was not found', 'Enter the full path to an existing folder on this computer.'],
 ['Root path not found:', 'Root folder was not found', 'Enter the full path to an existing folder on this computer.'],
 ['Folder not found:', 'Folder was not found', 'Check the complete folder path and that the running account can open it.'],
 ['Path not found:', 'Path was not found', 'Check that the supplied file or folder exists and is accessible to the running account.'],
 ['Drive not found:', 'Drive was not found', 'Choose a drive letter mounted on this computer.'],
 ['Install-Module is unavailable.', 'Module installer is unavailable', 'Repair PowerShellGet using the approved workstation setup, then reopen PowerShell.'],
 ['PSGallery does not point to the official HTTPS source.', 'Module repository is not approved', 'Have the workstation’s repository configuration corrected to the official HTTPS source. Do not bypass the source check.'],
 ['No matching GitHub export found', 'Security export was not found', 'Supply the full path to the GitHub security-log export for the account being reviewed.'],
 ['Invalid JSON export;', 'Security export is invalid', 'Download a fresh security-log export. Use JSON, JSON.GZ, or a ZIP containing exactly one JSON file.'],
 ['Snapshot directory is tracked.', 'Handoff folder is tracked by Git', 'Review the tracked .handoff files and repository exclusions before trying again. Do not publish a snapshot just to clear the warning.'],
 ['No upstream branch configured.', 'No upstream branch', 'Check the intended remote and branch, then configure their tracking relationship before pulling or pushing.'],
 ['WinGet review failed with exit code', 'WinGet review failed', 'Read the exit code, check WinGet availability and configured sources, then retry the review before approving updates.'],
 ['Execution policy remains', 'Execution policy did not change', 'Inspect Get-ExecutionPolicy -List. If organization policy controls execution, ask its owner to approve the required setup.'],
 ['Cert:\\CurrentUser\\My', 'Signing certificate is missing', 'Use a valid code-signing certificate in the running user’s certificate store, including its private key.'],
 ['Graph token is missing', 'Required Graph access is missing', 'Check the scopes listed under Permissions and reconnect using the approved account and consent process.'],
 ['required delegated scopes', 'Required Graph access is missing', 'Check Permissions and the connection error. Reconnect using the approved account with the required delegated consent.'],
 ['is required but is not installed', 'Required module is missing', 'Install the module named in the error through your approved setup. Reopen the same PowerShell version and retry.'],
 ['is required. Install it with:', 'Required module is missing', 'Install the module named in the error through your approved setup. Reopen the same PowerShell version and retry.'],
 ['is not installed. Install', 'Required module is missing', 'Install the module named in the error through your approved setup. Reopen the same PowerShell version and retry.']
];
function notesFor(item,source){
 const results=[],issues=[];
 const add=(issue,fix,evidence)=>{if(source.includes(evidence)&&!issues.some(x=>x.issue===issue))issues.push({issue,fix,evidence:[evidence]});};
 if(item.file==='GET-DISTRIBUTION-GROUP-MEMBERS.ps1'){
  results.push({text:'Optional CSV export saves member details. Blank output path uses distribution-group-members.csv in the current folder; the script checks the saved row count before confirming export.',evidence:['distribution-group-members.csv','Export member detail to CSV [Y/N]','if ($check.Count -ne $Rows.Count)']});
  add('Exchange module is missing','Install ExchangeOnlineManagement through your approved setup, reopen PowerShell, and run the lookup again.','is required but is not installed');
  add('Group lookup failed','Check the group’s exact name or primary email address, the connected tenant, and the account’s permission to read distribution groups.','Lookup failed:');
  add('CSV export failed or could not be verified','Close the destination file if it is open, choose an existing writable folder, and retry the export. Check the on-screen results before using the CSV.','CSV verification failed.');
 }else{
  if(item.file==='BEC-RISK-ASSESSMENT.ps1')add('Account or tenant could not be verified','Check the exact UPN and tenant, then reconnect with the access listed in Permissions. Unavailable checks must be resolved before clearing the account.','Graph connection failed. Target user and tenant context could not be resolved.');
  if(item.file==='BEC-CONTAIN-ERADICATE.ps1')add('Rule remains after removal','Recheck the mailbox’s current rules and the failed action. Keep the account contained and get the incident owner’s approval before retrying the affected action.','Rule still present after removal.');
  if(item.file==='BEC-RECOVER-VALIDATE.ps1')add('Account enablement did not verify','Check the current AD/Entra state and any pending synchronization. Stop and return to the incident owner rather than repeatedly enabling the account.','Entra account enable was not verified.');
  for(const [evidence,issue,fix] of rules){
   if(issue==='Signing certificate is missing'&&!['SIGN-FOLDER-SCRIPTS.ps1','MANAGE-CERT-SIGNATURES.ps1'].includes(item.file))continue;
   add(issue,fix,evidence);
  }
  if(source.includes('Save-FKDesktopReport')&&source.includes('Desktop report could not be saved.'))results.push({text:'An optional HTML report preserves the captured findings and unavailable checks. The save prompt offers another existing folder if the Desktop export fails.',evidence:['Save-FKDesktopReport','Desktop report could not be saved.']});
  if(item.file==='INVOKE-FILE-INVENTORY.ps1')results.push({text:'CSV exports go to the folder you choose (Desktop by default), with separate files for inventory, signatures, duplicates, and cleanup flags.',evidence:['Output folder [Enter for Desktop]','jumpbox-file-inventory-','jumpbox-signatures-','jumpbox-duplicates-','jumpbox-cleanup-flags-']});
 }
 for(const r of [...results,...issues])for(const quote of r.evidence)assert(source.includes(quote),'Detail evidence missing: '+item.file+' / '+quote);
 return {results,issues:issues.slice(0,3)};
}
export function checkWorkflowDetails(base=root){
 const fixture=loadCatalog(base),specs=JSON.parse(fs.readFileSync(path.join(base,'operator-card-specs.json'),'utf8'));
 let scripts=0,issues=0,results=0;
 for(const item of fixture.api.ITEMS.filter(i=>i.operatorCard)){
  const source=fs.readFileSync(path.join(base,item.publishedPath),'utf8'),spec=specs[item.file];
  assert.equal(spec.sourceSha256,crypto.createHash('sha256').update(source).digest('hex'),'Detail source stale: '+item.file);
  const expected=notesFor(item,source);
  assert.deepEqual(spec.workflowDetails,expected,'Authored detail notes stale: '+item.file);
  assert.deepEqual(JSON.parse(JSON.stringify(item.operatorCard.workflowDetails)),expected,'Shipped detail notes stale: '+item.file);
  scripts++;issues+=expected.issues.length;results+=expected.results.length;
 }
 return {scripts,issues,results};
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 if(!process.argv.includes('--check')){
  const {api}=loadCatalog(root),specs=JSON.parse(fs.readFileSync(path.join(root,'operator-card-specs.json'),'utf8'));
  for(const item of api.ITEMS.filter(i=>i.operatorCard)){
   const source=fs.readFileSync(path.join(root,item.publishedPath),'utf8');
   assert.equal(specs[item.file].sourceSha256,crypto.createHash('sha256').update(source).digest('hex'),'Review changed source before rebuilding details: '+item.file);
   specs[item.file].workflowDetails=notesFor(item,source);
  }
  fs.writeFileSync(path.join(root,'operator-card-specs.json'),JSON.stringify(specs,null,2)+'\n');
  const file=path.join(root,'card-guidance.js'),old=fs.readFileSync(file,'utf8'),marker='\n// Approved compact operator cards.';
  assert(old.includes(marker));
  fs.writeFileSync(file,old.slice(0,old.indexOf(marker))+marker+' Generated from operator-card-specs.json.\nwindow.FIELD_KIT_OPERATOR_CARDS = Object.freeze('+JSON.stringify(specs,null,2)+');\n');
 }
 console.log(JSON.stringify(checkWorkflowDetails(root)));
}
