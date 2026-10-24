import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import {fileURLToPath} from 'node:url';
import {loadCatalog} from '../tools/site-test-harness.mjs';import {checkPermissionsReview} from '../tools/permissions-review.mjs';import {graphProfiles,requestedScopes,declaredModules} from '../tools/permission-profiles.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
test('whole-catalog permission review covers source and effective preparation',()=>assert.deepEqual(checkPermissionsReview(root),{entries:326,graphCommands:33,exceptions:3}));
test('all task Graph preparations match reviewed scopes and use no write access for reads',()=>{
 const {api}=loadCatalog(root);
 for(const [name,p] of Object.entries(graphProfiles)){
  const item=api.ITEMS.find(x=>x.name===name);assert.equal(item.connect.length,1);
  for(const scope of p.scopes)assert(item.connect[0].includes(JSON.stringify(scope)),name);
  assert(item.permissionNotes.some(x=>/consent/i.test(x)));assert(item.permissionNotes.some(x=>/Role \/ target/.test(x)));
  if(item.access==='Read-only')assert(!/Write|EnableDisable|RevokeSessions/i.test(item.connect[0]),name);
 }
 assert(!api.ITEMS.find(x=>x.name==='Show Entra User Group Memberships').connect.join(' ').includes('ActiveDirectory'));
 for(const name of ['Show Graph Context','Disconnect Microsoft Graph','Connect Microsoft Graph'])assert.equal(api.ITEMS.find(x=>x.name===name).connect.length,0);
});
test('connected workflows render source-declared scopes and module setup without repeated requirement prose',()=>{
 const {api,document,window}=loadCatalog(root);
 for(const item of api.ITEMS.filter(x=>x.operatorCard)){
  api.openItem(item);const html=document.getElementById('drawerBody').innerHTML;
  const profile=window.FIELD_KIT_CONNECTION_GUIDANCE[item.publishedPath].connector;
  assert.equal(html.includes('<h3>Connector</h3>'),Boolean(profile),item.file);
  for(const scope of profile?.scopes || [])assert(html.includes('<code>'+scope+'</code>'),item.file+': '+scope);
  for(const mod of profile?.modules || [])assert(html.includes('Install-Module '+mod+' -Scope CurrentUser'),item.file+': '+mod);
  assert(!html.includes('Sign-in: use the approved customer account'),item.file);
  if(profile?.sharedSession)assert(html.includes('assessment also requests the response permissions'),item.file);
 }
});
test('script scope declarations match DETAILS and BEC write-capable tokens are explicit',()=>{
 const {api}=loadCatalog(root);let graph=0;
 for(const item of api.ITEMS.filter(x=>x.publishedPath?.endsWith('.ps1'))){
  const source=fs.readFileSync(path.join(root,item.publishedPath),'utf8'),scopes=requestedScopes(source,item.file);if(!scopes.length)continue;graph++;
  for(const module of declaredModules(source))assert(item.requires.includes(module),item.file+': '+module);
  for(const scope of scopes)assert(item.requires.includes(scope),item.file+': '+scope);
  if(item.access==='Read-only'&&scopes.some(x=>/Write|RevokeSessions|EnableDisable/.test(x)))assert(item.permissionNotes.some(x=>/Shared-session exception/.test(x)),item.file);
 }
 assert.equal(graph,38);
 const recovery=api.ITEMS.find(x=>x.file==='BEC-RECOVER-VALIDATE.ps1');assert.equal(recovery.access,'Change');
 assert(recovery.permissionNotes.some(x=>/recovery can make approved changes/.test(x)));
});
test('MFA permission patch inversely reconstructs exact prior bytes',()=>{
 const file='published-source/tenant/GET-MFA-SECURITY-AUDIT.ps1';let current=fs.readFileSync(path.join(root,file),'utf8');
 assert(current.includes('.VERSION 1.0.3'));assert(current.includes('"AuditLog.Read.All"'));assert(!current.includes('"Reports.Read.All"'));
 current=current.replace('.VERSION 1.0.3','.VERSION 1.0.2').replace('"AuditLog.Read.All"','"Reports.Read.All"');
 assert.equal(crypto.createHash('sha256').update(current).digest('hex'),'f7a9db6339cac2c6725261c00908713e7fb4017f4441c66c6118bc0cc360a5eb');
});

test('Quick Commands show every reviewed task scope and connect in step one before execution',()=>{
 const {api,document}=loadCatalog(root);
 for(const [name,p] of Object.entries(graphProfiles)){
  const item=api.ITEMS.find(x=>x.name===name);api.openItem(item);
  const html=document.getElementById('drawerBody').innerHTML;
  assert(html.indexOf('<li>Connect first.')<html.indexOf('class="command-block"'),name);
  assert(html.includes('data-copy="Connect-MgGraph'),name);
  for(const scope of p.scopes)assert(html.includes('<code>'+scope+'</code>'),name+': '+scope);
 }
 for(const name of ['Show Graph Context','Disconnect Microsoft Graph']){
  api.openItem(api.ITEMS.find(x=>x.name===name));
  assert(!document.getElementById('drawerBody').innerHTML.includes('<h3>Connector</h3>'),name);
 }
});
