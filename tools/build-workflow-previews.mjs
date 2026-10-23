// Authored samples stay source-bound. Never refresh hashes without reviewing examples.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
export function checkWorkflowPreviews(base=root,fixture=loadCatalog(base)){
 const specs=JSON.parse(fs.readFileSync(path.join(base,'workflow-preview-specs.json'),'utf8'));
 const scripts=fixture.api.ITEMS.filter(i=>i.operatorCard);
 assert.deepEqual(Object.keys(specs).sort(),Array.from(scripts,i=>i.file).sort(),'Every script needs one authored preview');
 assert.deepEqual(JSON.parse(JSON.stringify(fixture.window.FIELD_KIT_WORKFLOW_PREVIEWS)),specs,'Shipped previews differ from authored specs');
 for(const i of scripts){
  const r=specs[i.file],source=fs.readFileSync(path.join(base,i.publishedPath),'utf8');
  assert.equal(r.sourceSha256,crypto.createHash('sha256').update(source).digest('hex'),'Preview source review stale: '+i.file);
  assert(['illustrative-output','static-illustration'].includes(r.kind),i.file);
  assert(r.text.length>80&&r.text.length<6000&&r.text.split('\n').length>=6,i.file);
  if(r.kind!=='static-illustration')assert(r.sourceEvidence.length>0,i.file);
  for(const quote of r.sourceEvidence)assert(source.includes(quote),'Preview evidence missing: '+i.file+' / '+quote);
  assert(fixture.api.workflowPreview(i),i.file);
 }
 return {scripts:scripts.length,commands:0};
}
if(process.argv[1]===fileURLToPath(import.meta.url)){
 if(process.argv.includes('--check'))console.log(JSON.stringify(checkWorkflowPreviews(root)));
 else{
  const specs=JSON.parse(fs.readFileSync(path.join(root,'workflow-preview-specs.json'),'utf8'));
  fs.writeFileSync(path.join(root,'workflow-previews.js'),'// Illustrative examples, not live results or verbatim captured sessions. Bound to reviewed source bytes.\nwindow.FIELD_KIT_WORKFLOW_PREVIEWS = Object.freeze('+JSON.stringify(specs,null,2)+');\n');
  console.log(JSON.stringify(checkWorkflowPreviews(root)));
 }
}
