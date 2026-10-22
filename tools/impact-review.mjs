// Source-bound Stage 1 register. No service connections or operational execution.
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';
export const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
export function impactInventory(base=root){
 const {api}=loadCatalog(base);
 return api.ITEMS.map(item=>({
  id:item.file?'file:'+item.file:'command:'+item.name,
  name:item.name,type:item.type,impact:item.access,
  safetyMetadataSha256:crypto.createHash('sha256').update(JSON.stringify({input:item.input,guards:item.guards,changeNote:item.changeNote})).digest('hex'),
  sourceSha256:crypto.createHash('sha256').update(item.publishedPath?fs.readFileSync(path.join(base,item.publishedPath)):item.code||'').digest('hex'),
 })).sort((a,b)=>a.id.localeCompare(b.id));
}
export function checkImpactReview(base=root){
 const register=JSON.parse(fs.readFileSync(path.join(base,'docs/qa/IMPACT-REVIEW.json'),'utf8'));
 const current=impactInventory(base),byId=new Map(register.entries.map(x=>[x.id,x]));
 if(byId.size!==register.entries.length)throw new Error('Duplicate impact-review IDs');
 if(current.length!==byId.size)throw new Error('Catalog membership changed: review added/removed entries and peers.');
 for(const item of current){
  const record=byId.get(item.id);
  if(!record||Object.entries(item).some(([key,value])=>record[key]!==value))throw new Error('Impact review stale: '+item.id+'. Review this change AND equivalent operations before updating the register.');
  if(!['Read-only','Change','Destructive'].includes(item.impact))throw new Error('Unknown impact: '+item.id);
  if(!record.rationale||!['screened','follow-up'].includes(record.disposition))throw new Error('Missing review disposition: '+item.id);
 }
 return {entries:current.length,followUp:register.entries.filter(x=>x.disposition==='follow-up').length};
}
if(process.argv[1]===fileURLToPath(import.meta.url))console.log(JSON.stringify(checkImpactReview()));
