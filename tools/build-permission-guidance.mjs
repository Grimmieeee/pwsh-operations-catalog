// Mechanical materialization of reviewed profiles. Does not refresh the approval register.
import fs from 'node:fs';import vm from 'node:vm';
import {loadCatalog} from './site-test-harness.mjs';
import {graphProfiles,graphConsent,requestedScopes,declaredModules} from './permission-profiles.mjs';
const context={window:{}};let text=fs.readFileSync('card-guidance.js','utf8');vm.runInNewContext(text,context);
const {api,window}=loadCatalog(process.cwd());
const commands=context.window.FIELD_KIT_COMMAND_GUIDANCE,reviews=context.window.FIELD_KIT_CARD_GUIDANCE;
for(const item of api.ITEMS){
 const review=item.type==='Quick Command'?commands[item.name]:reviews[item.file];if(!review)continue;
 review.permissionNotes=[];
 const p=graphProfiles[item.name];
 if(item.type==='Quick Command'&&p){
  // Keep existing context-lifetime behavior for the separate lifecycle wave.
  const processScope=item.connect.some(x=>/-ContextScope Process/.test(x));
  review.connectFirst=['Connect-MgGraph -Scopes '+p.scopes.map(x=>JSON.stringify(x)).join(',')+(processScope?' -ContextScope Process':'')];
  review.requires=`Modules: ${[...new Set(['Microsoft.Graph.Authentication',...p.module.split(' + ')])].join(' + ')}. Delegated Graph scopes: ${p.scopes.join(', ')}.`;
  review.permissionNotes=[graphConsent,'Role / target authority: '+p.authority,...(p.note?[p.note]:[])];
 }else if(item.type==='Quick Command'){
  if(item.name==='Connect Microsoft Graph')review.permissionNotes.push('This generic connection requests only User.Read for your own profile. It does not prepare tenant-wide tasks; use the selected task’s DETAILS for its exact scopes, roles and consent.');
  if(/ExchangeOnlineManagement/.test(review.requires))review.permissionNotes.push('Exchange / Purview authority: assigned RBAC roles must permit this exact cmdlet, its parameters and the target objects. Graph consent does not grant these rights; Global Administrator is not a default requirement.');
  if(/ActiveDirectory/.test(review.requires))review.permissionNotes.push('AD authority: use Windows RSAT / ActiveDirectory and delegated rights to the selected objects. Domain Administrator is not a default requirement; Graph consent does not grant AD rights.');
 }else if(item.publishedPath?.endsWith('.ps1')){
  const source=fs.readFileSync(item.publishedPath,'utf8'),scopes=requestedScopes(source,item.file);
  review.requires=review.requires.replace('Microsoft Graph PowerShell and an account allowed to read or change the listed data. Technical requirements: ','');
  if(scopes.length){
   // Preserve platform/module requirements, but replace stale permission prose with source truth.
   const services=window.FIELD_KIT_CONNECTION_GUIDANCE[item.publishedPath]?.services||[];
   const modules=[...new Set(['Microsoft.Graph.Authentication',...declaredModules(source),...(services.includes('EXO')?['ExchangeOnlineManagement']:[]),...(services.includes('AD')?['ActiveDirectory']:[])])];
   review.requires='Modules used (depending on selected branch): '+modules.join(' + ')+'. Requested delegated Graph scopes: '+scopes.join(', ')+'.';
   review.permissionNotes.push(graphConsent,'Role / target authority: use supported Entra roles for the selected APIs and target accounts. Role restrictions, licensing and tenant policy can still deny access; an unavailable check is not a clean result.');
   if(/^BEC-(RISK-ASSESSMENT|CONTAIN-ERADICATE|RECOVER-VALIDATE)\.ps1$/.test(item.file))review.permissionNotes.push('Shared-session exception: all three BEC phases request the same read AND response scopes at the first sign-in. Assessment is read-only but its token is write-capable; containment and recovery can make approved changes. Approve the whole response scope set before starting; authentication separation is deferred to the lifecycle wave.','BEC platform: approved Windows jumpbox, Microsoft.Graph.Authentication 2.x and ExchangeOnlineManagement 3.2+; AD actions require delegated Windows AD rights.');
   if(item.file==='GET-MFA-SECURITY-AUDIT.ps1')review.permissionNotes.push('Policy.Read.ConditionalAccess is requested only when Conditional Access review is selected. Registration reporting requires a supported Reports Reader / Security Reader role (or equivalent); the beta report excludes disabled users and can change.');
  }
  const services=window.FIELD_KIT_CONNECTION_GUIDANCE[item.publishedPath]?.services||[];
  if(services.includes('EXO'))review.permissionNotes.push('Exchange authority: ExchangeOnlineManagement and tenant RBAC access to the cmdlets, parameters and target mailboxes used by this task. Check assigned management roles; Graph consent does not grant Exchange rights.');
  if(services.includes('AD'))review.permissionNotes.push('AD authority: Windows ActiveDirectory module / RSAT and delegated rights to the target objects. Domain Administrator is not a default prerequisite; cloud consent does not grant AD rights.');
 }
}
for(const [key,value] of [['FIELD_KIT_CARD_GUIDANCE',reviews],['FIELD_KIT_COMMAND_GUIDANCE',commands]]){
 const marker=`window.${key} = Object.freeze(`,start=text.indexOf(marker)+marker.length,end=text.indexOf('\n});',start)+2;
 if(start<marker.length||end<start)throw Error('Missing guidance section '+key);
 text=text.slice(0,start)+JSON.stringify(value,null,2)+text.slice(end);
}
fs.writeFileSync('card-guidance.js',text);
console.log('Materialized reviewed task-scoped preparation and source-declared script scopes.');
