// Taxonomy gate; classification review is separate from runtime acceptance.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {loadCatalog} from './site-test-harness.mjs';
export function checkTaxonomyReview(root,fixture=loadCatalog(root)){
 const {api}=fixture,ledger=JSON.parse(fs.readFileSync(path.join(root,'docs/qa/CATALOG-TAXONOMY.json')));
 assert.deepEqual(JSON.parse(JSON.stringify(api.TAXONOMY)),ledger.records,'Taxonomy documentation differs from shipped mapping');
 assert.deepEqual(JSON.parse(JSON.stringify(api.COMMAND_ALIASES)),ledger.commandAliases);
 const covered=new Set();
 for(const i of api.ITEMS){
  const key=i.type==='Quick Command'?'command:'+i.name:i.file,r=api.TAXONOMY[key];covered.add(key);
  assert(r,'Missing taxonomy: '+key);
  if(i.type==='Quick Command'){assert.equal(r.code,i.code,key);assert.equal(r.group,i.group,key);continue;}
  const sha=crypto.createHash('sha256').update(fs.readFileSync(path.join(root,i.publishedPath))).digest('hex');
  assert.equal(r.sha256,sha,'Taxonomy source review stale: '+key);
  assert(api.DOMAIN_SECTIONS.includes(r.primary),key);
  assert.equal(typeof r.report,'boolean');
  assert.equal(r.scope,i.operatorCard?.scope||'REFERENCE','Target scope review stale: '+key);
  assert.equal(new Set([r.primary,...r.secondary]).size,1+r.secondary.length,key);
  for(const d of r.secondary)assert(api.DOMAIN_SECTIONS.includes(d)&&d!=='Reports',key);
  if(r.report)assert(['single','multi','org','group','ip','local'].some(s=>api.matchesReportScope(i,s)),'Report has no target view: '+key);
 }
 for(const [alias,canonical]of Object.entries(api.COMMAND_ALIASES)){
  covered.add('command:'+alias);
  const a=api.TAXONOMY['command:'+alias],b=api.TAXONOMY['command:'+canonical];
  assert.equal(a.code.trim().replace(/\s+/g,' '),b.code.trim().replace(/\s+/g,' '),'Alias body differs: '+alias);
  assert(api.ITEMS.some(i=>i.name===canonical&&i.aliases?.includes(alias)),alias);
  assert(!api.ITEMS.some(i=>i.name===alias),alias);
 }
 assert.deepEqual([...covered].sort(),Object.keys(api.TAXONOMY).sort(),'Unaccounted taxonomy records');
 return {entries:api.ITEMS.length,aliases:Object.keys(api.COMMAND_ALIASES).length};
}
