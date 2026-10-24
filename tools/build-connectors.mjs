// Source-bound connector presentation. Never changes downloaded scripts or consent.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';
import {requestedScopes,declaredModules} from './permission-profiles.mjs';
const root=fileURLToPath(new URL('../',import.meta.url));
export function connectorFor(item,source,services){
 if(!services.some(x=>['GRAPH','EXO','AD'].includes(x)))return null;
 const modules=declaredModules(source).filter(x=>x!=='ActiveDirectory'&&(x.startsWith('Microsoft.Graph.')?services.includes('GRAPH'):services.includes('EXO')));
 if(services.includes('GRAPH')&&!modules.includes('Microsoft.Graph.Authentication'))modules.unshift('Microsoft.Graph.Authentication');
 if(services.includes('EXO')&&!modules.includes('ExchangeOnlineManagement'))modules.push('ExchangeOnlineManagement');
 const code=source.replace(/<#[\s\S]*?#>/g,'').replace(/^\s*#.*$/gm,'');
 const exchangeCmdlets=services.includes('EXO')?[...new Set([...code.matchAll(/\b(?:Get|Set|Add|Remove|Search|New|Start|Restore|Undo|Test)-(?:EXO[A-Za-z]+|Mailbox[A-Za-z]*|InboxRule|Recipient[A-Za-z]*|DistributionGroup[A-Za-z]*|DynamicDistributionGroup[A-Za-z]*|UnifiedGroup[A-Za-z]*|TransportRule|UnifiedAuditLog|MessageTrace[A-Za-z0-9]*|CASMailbox|OrganizationConfig|RemoteDomain|AcceptedDomain|ComplianceSearch[A-Za-z]*|RecoverableItems)\b/g)].map(x=>x[0]))].sort():[];
 const ad=services.includes('AD')&&/Import-Module\s+(?:-Name\s+)?['"]?ActiveDirectory|Ensure-Module\s+(?:-Name\s+)?['"]ActiveDirectory|Get-ADUser|Get-ADGroup/.test(code);
 if(!modules.length&&!ad)return null;
 return {modules:[...new Set(modules)],scopes:requestedScopes(source,item.file),exchangeCmdlets,ad:services.includes('AD')&&/Import-Module\s+(?:-Name\s+)?['"]?ActiveDirectory|Ensure-Module\s+(?:-Name\s+)?['"]ActiveDirectory|Get-ADUser|Get-ADGroup/.test(code),sharedSession:/^BEC-(RISK-ASSESSMENT|CONTAIN-ERADICATE|RECOVER-VALIDATE)\.ps1$/.test(item.file),conditionalAccess:item.file==='GET-MFA-SECURITY-AUDIT.ps1'};
}
export function checkConnectors(base=root){
 const {api,window}=loadCatalog(base);let count=0;
 for(const item of api.ITEMS.filter(x=>x.operatorCard)){
  const record=window.FIELD_KIT_CONNECTION_GUIDANCE[item.publishedPath];
  const expected=connectorFor(item,fs.readFileSync(base+'/'+item.publishedPath,'utf8'),record.services);
  assert.deepEqual(JSON.parse(JSON.stringify(record.connector??null)),expected,item.file+': connector metadata stale');
  count+=Boolean(expected);
 }
 return count;
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 if(!process.argv.includes('--check')){
  const {api,window}=loadCatalog(root),records=JSON.parse(JSON.stringify(window.FIELD_KIT_CONNECTION_GUIDANCE));
  for(const item of api.ITEMS.filter(x=>x.operatorCard))records[item.publishedPath].connector=connectorFor(item,fs.readFileSync(root+item.publishedPath,'utf8'),records[item.publishedPath].services);
  fs.writeFileSync(root+'connection-guidance.js','// Reviewed connection behavior and source-bound connector requirements.\nwindow.FIELD_KIT_CONNECTION_GUIDANCE = Object.freeze('+JSON.stringify(records,null,2)+');\n');
 }
 console.log('Connected workflows: '+checkConnectors(root));
}
