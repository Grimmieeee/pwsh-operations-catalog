import test from 'node:test';import assert from 'node:assert/strict';import fs from 'node:fs';import path from 'node:path';import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';import {loadCatalog} from '../tools/site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..'),review=JSON.parse(fs.readFileSync(path.join(root,'docs/qa/BEC-NAMING-REVIEW.json'),'utf8'));
const hash=value=>crypto.createHash('sha256').update(value).digest('hex');
test('all eleven response scripts use BEC filenames, labels and source-bound reviews',()=>{
 const {api}=loadCatalog(root);assert.equal(review.entries.length,11);
 assert.equal(api.ITEMS.length,326);assert.equal(api.ITEMS.filter(x=>x.publishedPath).length,94);
 assert.ok(api.ITEMS.every(x=>!/^IR-/i.test(x.file)));
 for(const r of review.entries){
  const item=api.ITEMS.find(x=>x.file===r.file);assert.ok(item,r.file);assert.match(item.displayName,/^BEC: /);
  assert.equal(item.operatorCard.sourceSha256,hash(fs.readFileSync(path.join(root,r.path))));
  assert.equal(item.version,r.version);assert.equal(api.isVerifiedRelease(item),false);
  assert.equal(fs.existsSync(path.join(root,r.oldPath)),false);
 }
});
test('inverse naming edits reconstruct exact prior source bytes for every renamed script',()=>{
 for(const r of review.entries){let text=fs.readFileSync(path.join(root,r.path),'utf8');assert.equal(hash(text),r.sourceSha256);
  for(const pair of [...r.replacements].reverse())text=text.replaceAll(pair.new,pair.old);
  assert.equal(hash(text),r.priorSourceSha256,r.file);
 }
});
test('IR, incident response, BEC and every legacy filename find the renamed tools',()=>{
 const {api}=loadCatalog(root);
 for(const query of ['IR','incident response','BEC']){
  api.state.area='Full Library';api.state.query=query;
  const matches=api.filteredItems();for(const r of review.entries)assert.ok(matches.some(x=>x.file===r.file),query+': '+r.file);
 }
 for(const r of review.entries){api.state.query=r.oldFile;assert.equal(api.filteredItems()[0]?.file,r.file,r.oldFile);}
});
test('Incident Response section retains BEC script and command labels',()=>{
 const {api,document}=loadCatalog(root);api.state.area='Incident Response';api.renderResults();
 assert.equal(document.getElementById('crumb').textContent,'INCIDENT RESPONSE');
 for(const r of review.entries)assert.ok(api.filteredItems().some(x=>x.file===r.file),'BEC navigation: '+r.file);
 assert.equal(api.ITEMS.find(x=>x.file==='BEC-GET-IP-TRACE.ps1').group,'Investigation');
 assert.equal(api.ITEMS.find(x=>x.file==='BEC-INVOKE-EMAIL-RECOVERY.ps1').group,'Response');
 assert.match(api.ITEMS.find(x=>x.name==='Revoke Active Sessions').displayName,/^BEC: /);
});
test('active companion paths resolve only to the renamed BEC trio',()=>{
 const trio=['BEC-RISK-ASSESSMENT.ps1','BEC-CONTAIN-ERADICATE.ps1','BEC-RECOVER-VALIDATE.ps1'];
 for(const file of trio){const text=fs.readFileSync(path.join(root,'published-source/incident-response',file),'utf8');
  assert.doesNotMatch(text,/ir-(?:risk-assessment|contain-eradicate|recover-validate)/i);
  for(const match of text.matchAll(/['"](BEC-(?:RISK-ASSESSMENT|CONTAIN-ERADICATE|RECOVER-VALIDATE))['"]/g))assert.ok(fs.existsSync(path.join(root,'published-source/incident-response',match[1]+'.ps1')));
 }
});

test('current entry points describe BEC while historical acceptance retains original filenames',()=>{
 const read=file=>fs.readFileSync(path.join(root,file),'utf8');
 const handoff=read('tools/PROJECT-HANDOFF.md').split('## IR 1.0.0, version-bound verification and catalog alignment')[1];
 assert.ok(handoff);assert.match(handoff,/ir-risk-assessment\.ps1/);assert.match(handoff,/ir-contain-eradicate\.ps1/);assert.match(handoff,/ir-recover-validate\.ps1/);
 assert.doesNotMatch(handoff,/BEC-(?:RISK-ASSESSMENT|CONTAIN-ERADICATE|RECOVER-VALIDATE)\.ps1/);
 const current=read('docs/PROJECT-STATUS.md').split('## Historical release checkpoints')[0];
 assert.match(current,/BEC-prefixed filenames/);assert.doesNotMatch(current,/broader investigation uses Incident Response:/);
 assert.match(read('README.md'),/naming release is 1\.0\.3/);
});
