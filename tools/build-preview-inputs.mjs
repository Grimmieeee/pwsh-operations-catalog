// Preview placeholders describe inputs; returned sample data and literal menu commands stay unchanged.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
export function previewInputs(item){
 const {file,operatorCard:spec}=item,fields=[];
 const add=(label,value)=>fields.push({label,value:'<'+value+'>'});
 if(spec.scope.includes('USER')||spec.scope.includes('MAILBOX'))add(spec.scope.includes('MAILBOX')?'Mailbox':'User',file==='GET-ROOM-RESOURCE-ACCESS.ps1'?'resource@domain.com':'user@domain.com');
 if(spec.scope.endsWith('GROUP'))add('Group',file==='INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1'?'group name':'group@domain.com');
 if(spec.input.includes('CSV'))add('TXT/CSV alternative','input file path');
 if(spec.input==='Tenant ID'||spec.input.includes('tenant ID'))add('Tenant ID','tenant ID (GUID)');
 if(spec.input==='Tenant domain')add('Tenant domain','tenant domain');
 if(file==='RESOLVE-NAMES-TO-UPNS.ps1'){fields.splice(0,1,{label:'Name / email',value:'<name or email>'});add('Tenant domain','tenant domain');}
 if(['BEC-RISK-ASSESSMENT.ps1','BEC-CONTAIN-ERADICATE.ps1','BEC-RECOVER-VALIDATE.ps1'].includes(file)){
  fields.splice(1);add('Tenant','tenant domain or tenant ID');
 }
 const extra={
  'INVOKE-DISABLE-ACCOUNTS.ps1':[['Sync server (optional)','sync server']],
  'INVOKE-DELETE-ACCOUNTS.ps1':[['Sync server (optional)','sync server']],
  'INVOKE-ASSIGN-LICENSES.ps1':[['License','license selection'],['UsageLocation (if missing)','country code']],
  'INVOKE-REMOVE-LICENSES.ps1':[['License','license selection']],
  'INVOKE-REMOVE-USER-GROUPS.ps1':[['Sync server (optional)','sync server']],
  'INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1':[['Mail nickname','mail nickname']],
  'INVOKE-LITIGATION-HOLD.ps1':[['Ticket','ticket number'],['Hold owner','requestor']],
  'BEC-INVOKE-EMAIL-RECOVERY.ps1':[['Source folder','source folder'],['Target folder','target folder']],
  'BEC-GET-DATA-EXFIL-ACTIVITY.ps1':[['Lookback','days'],['IP filter (optional)','IP address']],
  'BEC-GET-IP-TRACE.ps1':[['Target IP','IP address'],['Lookback','days']],
  'BEC-GET-TENANT-EMAIL-SEARCH.ps1':[['Sender (optional)','sender@domain.com'],['Recipient (optional)','recipient@domain.com'],['Source IP (optional)','IP address'],['Lookback','days']],
  'BEC-GET-THREAT-INTEL-ACTIVITY.ps1':[['Public IP / TXT','public IP or TXT path'],['Provider key','API key']],
  'BEC-GET-TIMELINE-BUILDER.ps1':[['Case folder','evidence folder'],['Manual event (optional)','event time, phase, action, detail']],
  'BEC-GET-TOKEN-DECODE.ps1':[['Token','JWT']],
  'BEC-GET-TOKEN-REPLAY-CHECK.ps1':[['Lookback','hours']],
  'GET-SHARED-MAILBOX-SIGNIN-AUDIT.ps1':[['Lookback','hours']],
  'GET-DEVICE-CODE-EXPOSURE.ps1':[['Lookback','hours']],
  'GET-SIGNIN-ANOMALIES.ps1':[['Lookback','hours'],['User filter (optional)','user@domain.com'],['Expected locations','country codes']],
  'GET-SECURE-SCORE-SNAPSHOT.ps1':[['Previous snapshot (optional)','JSON snapshot path']],
  'JOIN-COMPUTER-TO-DOMAIN.ps1':[['Domain','AD domain'],['Credentials','authorized join account'],['OU (optional)','OU distinguished name'],['Ticket','ticket number']],
  'DEPLOY-TCPIP-PRINTER.ps1':[['Printer','printer name'],['Address','printer IP or hostname'],['Driver','installed driver name']],
  'BACKUP-USER-PROFILE.ps1':[['Source','profile path'],['Destination','backup folder']],
  'GET-FOLDER-INVENTORY.ps1':[['Folder','folder path']],
  'INSTALL-M365-MODULES.ps1':[['Selection','menu option']],
  'TEST-SENSITIVE-DATA.ps1':[['Path','file or folder path']],
  'GET-TENANT-DRIFT-REVIEW.ps1':[['Baseline','baseline path']],
  'GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1':[['Drive','drive letter']],
  'PREPARE-FIELD-KIT.ps1':[['Profile','Graph / Exchange / Both']],
  'git-handoff.ps1':[['Repository','repository path']],
  'git-repo.ps1':[['Repository','repository path'],['Action','Check / Pull / Push'],['Commit message (send)','commit message']],
  'git-security.ps1':[['Account','GitHub account'],['Export','security-log export path']],
  'SIGN-FOLDER-SCRIPTS.ps1':[['Folder','script folder'],['Certificate','certificate selection']],
  'GET-TERMINAL-READINESS-CHECK.ps1':[['Kit root','toolkit folder']],
  'INVOKE-FILE-INVENTORY.ps1':[['Root','root folder']],
  'INVOKE-MAP-KIT.ps1':[['Root','root folder']],
  'MANAGE-CERT-SIGNATURES.ps1':[['Action','menu option'],['Certificate (when requested)','certificate selection'],['Name (create)','certificate name'],['File (import/export)','certificate file path'],['Password (private key)','certificate password']]
 };
 for(const [label,value]of extra[file]||[])add(label,value);
 return fields;
}
export function checkPreviewInputs(base=root){
 const {api}=loadCatalog(base),specs=JSON.parse(fs.readFileSync(path.join(base,'workflow-preview-specs.json'),'utf8'));
 let scripts=0,inputs=0,implicit=0;
 for(const item of api.ITEMS.filter(i=>i.operatorCard)){
  const record=specs[item.file],expected=previewInputs(item);
  assert.deepEqual(record.operatorInputs,expected,'Preview input coverage stale: '+item.file);
  for(const field of expected){assert(/^<[^<>]+>$/.test(field.value));assert(record.text.includes(field.label+': '+field.value),'Preview input missing: '+item.file+' / '+field.label);}
  assert.equal((record.text.match(/^OPERATOR INPUTS$/gm)||[]).length,expected.length?1:0,item.file);
  scripts++;inputs+=expected.length;if(!expected.length)implicit++;
 }
 return {scripts,inputs,implicit};
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 if(!process.argv.includes('--check')){
  const {api}=loadCatalog(root),specs=JSON.parse(fs.readFileSync(path.join(root,'workflow-preview-specs.json'),'utf8'));
  for(const item of api.ITEMS.filter(i=>i.operatorCard)){
   const record=specs[item.file],fields=previewInputs(item);
   let text=record.text.replace(/^OPERATOR INPUTS\n[\s\S]*?\n\n/,'');
   if(item.operatorCard.scope.includes('USER')||item.operatorCard.scope.includes('MAILBOX')){
    text=text.replaceAll('alex@example.com','<user@domain.com>');
    if(item.operatorCard.scope.includes('MULTI'))text=text.replaceAll('sam@example.com','<another-user@domain.com>');
    if(item.file==='GET-ROOM-RESOURCE-ACCESS.ps1')text=text.replaceAll('room@example.com','<resource@domain.com>').replace('Full Access       : <another-user@domain.com>','Full Access       : sam@example.com').replace('Resource delegates: <user@domain.com>','Resource delegates: alex@example.com');
   }
   if(item.file==='RESOLVE-NAMES-TO-UPNS.ps1')text=text.replace('Alex Example       Exact','<name>             Exact').replace('Sam                Multiple','<name>             Multiple').replace('Unknown Person     No match','<name>             No match');
   if(item.file==='GET-DISTRIBUTION-GROUP-MEMBERS.ps1')text=text.replace('Name    : Service Desk','Name    : <group name>').replace('Address : help@example.com','Address : <group@domain.com>');
   if(item.file==='GET-GROUP-MEMBERS.ps1')text=text.replace('Name    : Operations','Name    : <group name>');
   if(item.file==='INVOKE-CREATE-DYNAMIC-LICENSE-GROUP.ps1')text=text.replaceAll('Licensed Users','<group name>').replaceAll('licensed-users','<mail nickname>');
   if(['INVOKE-ASSIGN-LICENSES.ps1','INVOKE-REMOVE-LICENSES.ps1'].includes(item.file))text=text.replaceAll('Microsoft 365 Business Premium','<license selection>');
   if(item.file==='BEC-INVOKE-EMAIL-RECOVERY.ps1')text=text.replace('Source folder  : Deleted Items','Source folder  : <source folder>').replace('Target folder  : Recovered Mail','Target folder  : <target folder>');
   if(item.file==='BEC-GET-IP-TRACE.ps1')text=text.replaceAll('203.0.113.24','<IP address>');
   if(item.file==='BEC-GET-TENANT-EMAIL-SEARCH.ps1')text=text.replaceAll('sender@example.net','<sender@domain.com>');
   if(item.file==='JOIN-COMPUTER-TO-DOMAIN.ps1')text=text.replaceAll('ad.example.com','<AD domain>');
   if(item.file==='DEPLOY-TCPIP-PRINTER.ps1')text=text.replaceAll('Office Printer','<printer name>').replaceAll('192.0.2.25','<printer IP or hostname>').replaceAll('Selected installed driver','<installed driver name>');
   text=text.replaceAll('C:\\Users\\Example','<profile path>').replaceAll('D:\\Backups\\Example','<backup folder>').replaceAll('C:\\Example\\FIELD-KIT','<toolkit folder>').replaceAll('C:\\Example\\Project','<repository path>').replaceAll('C:\\Example\\Scripts','<script folder>');
   record.operatorInputs=fields;record.text=(fields.length?'OPERATOR INPUTS\n'+fields.map(f=>f.label+': '+f.value).join('\n')+'\n\n':'')+text;
  }
  fs.writeFileSync(path.join(root,'workflow-preview-specs.json'),JSON.stringify(specs,null,2)+'\n');
 }
 console.log(JSON.stringify(checkPreviewInputs(root)));
}
