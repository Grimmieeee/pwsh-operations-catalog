// Release gate: requirements, setup, role/consent copy AND source bytes are reviewed together.
import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';import assert from 'node:assert/strict';import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';import {graphProfiles,requestedScopes} from './permission-profiles.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sha=value=>crypto.createHash('sha256').update(value).digest('hex');
export function permissionsInventory(base=root){
 const {api}=loadCatalog(base);
 return Array.from(api.ITEMS,item=>({
  id:item.file?'file:'+item.file:'command:'+item.name,
  sourceSha256:sha(item.publishedPath?fs.readFileSync(path.join(base,item.publishedPath)):item.code||''),
  permissionMetadataSha256:sha(JSON.stringify({requires:item.requires,connect:item.connect,permissionNotes:item.permissionNotes||[],preparation:item.operatorCard?.preparation||[]})),
  requestedScopes:item.publishedPath?.endsWith('.ps1')?requestedScopes(fs.readFileSync(path.join(base,item.publishedPath),'utf8'),item.file):graphProfiles[item.name]?.scopes||[],
  disposition:/^BEC-(RISK-ASSESSMENT|CONTAIN-ERADICATE|RECOVER-VALIDATE)\.ps1$/.test(item.file)?'shared-session-exception':'screened',
 })).sort((a,b)=>a.id.localeCompare(b.id));
}
export function checkPermissionsReview(base=root){
 const register=JSON.parse(fs.readFileSync(path.join(base,'docs/qa/PERMISSIONS-REVIEW.json'),'utf8'));
 assert.deepEqual(permissionsInventory(base),register.entries,'Permissions review stale: review the changed task AND equivalent peers before updating the register.');
 const {api}=loadCatalog(base);
 for(const [name,p] of Object.entries(graphProfiles)){
  const item=api.ITEMS.find(x=>x.name===name);assert(item,'Missing permission profile target: '+name);
  assert.equal(item.connect.length,1,name);
  const actual=[...item.connect[0].matchAll(/"([^"]+)"/g)].map(x=>x[1]);assert.deepEqual(actual,p.scopes,name);
  for(const scope of p.scopes)assert(item.requires.includes(scope),name+': invisible scope '+scope);
  if(item.access==='Read-only')assert(p.scopes.every(x=>!/Write|EnableDisable|RevokeSessions/i.test(x)),name+': read-only task requests write scopes');
 }
 return {entries:register.entries.length,graphCommands:Object.keys(graphProfiles).length,exceptions:register.entries.filter(x=>x.disposition==='shared-session-exception').length};
}
if(process.argv[1]===fileURLToPath(import.meta.url))console.log(JSON.stringify(checkPermissionsReview()));
