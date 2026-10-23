import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { loadCatalog,FixtureElement } from '../tools/site-test-harness.mjs';
import { validateCardContract } from '../tools/card-contract.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const digest=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const fixturePath='published-source/fixture.ps1';

test('catalog markers distinguish reports, account actions and non-account tools',()=>{
 const f=loadCatalog(root),find=file=>f.api.ITEMS.find(x=>x.file===file);
 for(const [file,type] of [
  ['GET-USER-GROUPS.ps1','multi'],['INVOKE-ASSIGN-LICENSES.ps1','multi'],
  ['BEC-CONTAIN-ERADICATE.ps1','single'],['BEC-RISK-ASSESSMENT.ps1','single'],
  ['GET-TENANT-DRIFT-REVIEW.ps1','organization'],['PREPARE-FIELD-KIT.ps1','local']
 ])assert.equal(f.api.catalogIconType(find(file)),type,file);
 assert.equal(f.api.catalogIconType(f.api.ITEMS.find(x=>x.type==='Quick Command')),'command');
 const mailbox=find('GET-MAILBOX-FORWARDING.ps1');
 assert.match(f.api.catalogIconMarkup(mailbox),/One or multiple targets · SINGLE or MULTI-MAILBOX/);
 const kinds=new Set(['single','multi','report','organization','local','command','reference']);
 for(const item of f.api.ITEMS)assert.ok(kinds.has(f.api.catalogIconType(item)),item.displayName);
});

test('name and icon header sorting toggles direction across all visible results',()=>{
 const f=loadCatalog(root);
 let items=Array.from(f.api.filteredItems());
 assert.equal(items.length,329);
 assert.deepEqual(items.map(x=>x.displayName),items.map(x=>x.displayName).sort((a,b)=>a.localeCompare(b)));
 f.api.setCatalogSort('name');
 items=Array.from(f.api.filteredItems());
 assert.deepEqual(items.map(x=>x.displayName),items.map(x=>x.displayName).sort((a,b)=>b.localeCompare(a)));
 f.api.setCatalogSort('icon');
 const order=['single','multi','report','organization','local','command','reference'];
 const rank=()=>Array.from(f.api.filteredItems(),x=>order.indexOf(f.api.catalogIconType(x)));
 assert.deepEqual(rank(),rank().sort((a,b)=>a-b));
 f.api.setCatalogSort('icon');assert.deepEqual(rank(),rank().sort((a,b)=>b-a));
 const before=f.api.state.sortKey;f.api.setCatalogSort('unknown');assert.equal(f.api.state.sortKey,before);
});

test('flag sorting preserves destructive warnings and search membership',()=>{
 const f=loadCatalog(root);f.api.state.query='mailbox';
 const before=Array.from(f.api.filteredItems(),x=>x.displayName).sort();
 f.api.setCatalogSort('flag');
 assert.deepEqual(Array.from(f.api.filteredItems(),x=>x.displayName).sort(),before);
 f.api.state.query='';f.api.setCatalogSort('flag');
 const list=Array.from(f.api.filteredItems());
 assert.ok(/destructive/i.test(list[0].access));
 assert.match(f.elements.get('results').innerHTML,/result-danger/);
 assert.match(f.elements.get('catalogSortStatus').textContent,/impact, descending/);
});

test('sorted row click opens the matching source and hides sort controls on guides',()=>{
 const f=loadCatalog(root);
 const buttons=[];const rows=f.elements.get('results');
 rows.querySelectorAll=selector=>selector==='[data-open-index]'?buttons:[];
 const row=new FixtureElement(f.document);row.setAttribute('data-open-index','3');buttons.push(row);
 f.api.setCatalogSort('name');
 const selected=f.api.filteredItems()[3];row.listeners.click();
 assert.equal(f.api.state.selected,selected);
 for(const area of ['Start Here','About']){f.api.state.area=area;f.api.renderResults();assert.equal(f.elements.get('catalogHead').classList.contains('hidden'),true);}
});

test('Start Here makes preparation, one-job scope and completion visible',()=>{
 const f=loadCatalog(root);f.api.state.area='Start Here';f.api.renderResults();
 const html=f.elements.get('results').innerHTML;
 for(const text of ['1. Confirm the customer and computer','2. Prepare PowerShell','3. Choose and run one job','4. Review, finish and close','Download Setup Package','RESULT: READY','same Windows account and PowerShell edition','same window','does not guarantee another password or MFA prompt'])assert.ok(html.includes(text),text);
 assert.doesNotMatch(html,/RMM/i);
 for(const file of ['published-source/utility/START-HERE.md','published-source/utility/PREPARE-FIELD-KIT.ps1'])assert.doesNotMatch(fs.readFileSync(path.join(root,file),'utf8'),/RMM/i);
 assert.equal(f.elements.get('.search-wrap').classList.contains('hidden'),true);
 assert.equal(f.elements.get('empty').classList.contains('hidden'),true);
});

test('first-run ZIP contains the exact reviewed setup, guide and checksum list',async()=>{
 const f=loadCatalog(root,{fetchImpl:async url=>new Response(fs.readFileSync(path.join(root,new URL(url).pathname.replace('/pwsh-operations-catalog/',''))),{headers:{'content-type':'text/plain'}})});
 const archive=Buffer.from(await (await f.api.buildSetupBundle()).arrayBuffer());
 const report=JSON.parse(execFileSync('python3',['-c','import io,sys,zipfile,hashlib,json; z=zipfile.ZipFile(io.BytesIO(sys.stdin.buffer.read())); assert z.testzip() is None; print(json.dumps({"hashes":{n:hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist()},"checksums":z.read("SHA256SUMS.txt").decode()}))'],{input:archive,encoding:'utf8'}));
 assert.equal(Object.keys(report.hashes).length,3);
 for(const name of ['PREPARE-FIELD-KIT.ps1','START-HERE.md']){
  const item=f.api.ITEMS.find(x=>x.file===name),hash=digest(fs.readFileSync(path.join(root,item.publishedPath)));
  assert.equal(report.hashes[name],hash);assert.ok(report.checksums.includes(hash+'  '+name));
 }
});

test('first-run packaging refuses changed bytes and a missing source review',async()=>{
 const altered=loadCatalog(root,{fetchImpl:async()=>new Response('altered source',{headers:{'content-type':'text/plain'}})});
 await assert.rejects(altered.api.buildSetupBundle(),/checksum|integrity|match/i);
 const f=loadCatalog(root);f.window.FIELD_KIT_CARD_GUIDANCE={...f.window.FIELD_KIT_CARD_GUIDANCE,'PREPARE-FIELD-KIT.ps1':{sourceSha256:'stale'}};
 await assert.rejects(f.api.buildSetupBundle(),/source review/);
});

test('connection details distinguish customer sign-in, local setup and same-window cleanup',()=>{
 const f=loadCatalog(root);
 const text=file=>Array.from(f.api.connectionInfo(f.api.ITEMS.find(x=>x.file===file))).join(' ');
 assert.match(text('PREPARE-FIELD-KIT.ps1'),/official PowerShell Gallery.*no customer tenant sign-in/);
 assert.match(text('RESET-M365-SESSION.ps1'),/existing sessions in this PowerShell window/);
 const cloud=f.api.ITEMS.find(x=>f.window.FIELD_KIT_CONNECTION_GUIDANCE?.[x.publishedPath]?.services?.includes('GRAPH'));
 assert.match(Array.from(f.api.connectionInfo(cloud)).join(' '),/Microsoft Graph.*approved customer account/);
 const item=f.api.ITEMS.find(x=>x.file==='PREPARE-FIELD-KIT.ps1');
 f.window.FIELD_KIT_CONNECTION_GUIDANCE={...f.window.FIELD_KIT_CONNECTION_GUIDANCE,[item.publishedPath]:{sha256:'stale',services:['GRAPH']}};
 assert.equal(f.api.connectionInfo(item).length,0);
});

test('reviewed tenant audits disclose the required tenant ID before launch',()=>{
 const f=loadCatalog(root);
 const items=f.api.ITEMS.filter(x=>x.publishedPath?.startsWith('published-source/tenant/')&&fs.readFileSync(path.join(root,x.publishedPath),'utf8').includes('Graph read failed; review incomplete.'));
 assert.equal(items.length,13);
 for(const item of items){f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
  assert.ok(html.includes('Tenant ID'),item.file);assert.ok(html.indexOf('Tenant ID')<html.indexOf('guided-start'),item.file);
  assert.equal(Boolean(item.operatorCard.presentationRevision||item.operatorCard.operationalRevision),true);assert.equal(f.api.isVerifiedRelease(item),false);
 }
});

test('BEC lookup fix has source-bound review without claiming operator verification',()=>{
  const f=loadCatalog(root),risk=f.api.ITEMS.find(x=>x.file==='BEC-RISK-ASSESSMENT.ps1');
  f.api.openItem(risk);
  assert.ok(!f.elements.get('drawerBody').innerHTML.includes('Known limitation: app display names may be unresolved'));
  assert.equal(risk.operatorCard.workflowReview.kind,'bec-naming');
  assert.equal(risk.operatorCard.workflowReview.priorReview.kind,'uri-boundary-fix');
  assert.equal(digest(fs.readFileSync(path.join(root,risk.publishedPath))),risk.operatorCard.workflowReview.sourceSha256);
  assert.equal(f.api.isVerifiedRelease(risk),false);
});

test('offboarding language leads to read-only preparation without enabling missing sources',()=>{
  const f=loadCatalog(root);
  for(const query of ['employee left','departing employee','user leaving','offboarding','leaver']){
    f.api.state.query=query;
    const list=f.api.filteredItems();
    assert.equal(list[0].displayName,'Check User Before Deletion',query);
    assert.equal(list[0].access,'Read-only');
    assert.ok(list.some(x=>x.file==='INVOKE-REMOVE-LICENSES.ps1'));
    assert.ok(!list.some(x=>x.displayName==='User Offboarding'));
    assert.ok(f.api.PLANNED_ITEMS.some(x=>x.displayName==='User Offboarding'));
  }
  for(const query of ['remove license','Disable Sign-In']){
    f.api.state.query=query;
    assert.match(f.api.filteredItems()[0].displayName,query==='remove license'?/Remove User Licenses/:/Disable Sign-In/);
  }
  f.api.state.query='unmatchableexample123';f.api.renderResults();
  assert.equal(f.elements.get('empty').classList.contains('hidden'),false);
  assert.match(fs.readFileSync(path.join(root,'index.html'),'utf8'),/No matches\. Try a task name[\s\S]*browse a section/);
});

test('license removal keeps visible impact and the source retains exact target approval',()=>{
 const f=loadCatalog(root),item=f.api.ITEMS.find(x=>x.file==='INVOKE-REMOVE-LICENSES.ps1');f.api.openItem(item);
 const html=f.elements.get('drawerBody').innerHTML,source=fs.readFileSync(path.join(root,item.publishedPath),'utf8');
 for(const text of ['MAKES CHANGES','SINGLE or MULTI-USER','UPN / CSV / TXT','License removal can affect services'])assert.ok(html.includes(text),text);
 assert.match(source,/ExpectedTenantId/);assert.match(source,/REMOVE/);assert.equal(f.api.isVerifiedRelease(item),false);
});

test('investigation searches lead to assessment without hijacking explicit actions',()=>{
  const f=loadCatalog(root);
  for(const query of ['suspicious login','unexpected MFA prompts','compromised account','account hacked','suspicious sign-in']){
    f.api.state.query=query;
    assert.equal(f.api.filteredItems()[0].file,'BEC-RISK-ASSESSMENT.ps1',query);
  }
  f.api.state.query='Disable Sign-In';
  assert.equal(f.api.filteredItems()[0].name,'Disable Sign-In');
});

test('IR cards retain the exact launch, preparation and incident handoff',()=>{
 const f=loadCatalog(root);
 for(const item of f.api.ITEMS.filter(x=>x.workflow)){
  f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
  for(const text of ['DOWNLOAD BEC WORKFLOW','Workflow preparation','DETAILS','Paste the full path to '+item.file,'same PowerShell window'])assert.ok(html.includes(text),item.file+': '+text);
  const completion=f.api.completionInfo(item);for(const key of ['result','next','blocked'])assert.ok(html.includes(completion[key].replaceAll('&','&amp;')),item.file+': '+key);
  assert.equal(f.api.isVerifiedRelease(item),false);
 }
 for(const item of f.api.ITEMS.filter(x=>x.status==='Source pending')){f.api.openItem(item);assert.ok(!f.elements.get('drawerBody').innerHTML.includes('guided-start'));}
});

test('IR package is a readable ZIP with exact reviewed script bytes and a guide',async()=>{
  const f=loadCatalog(root,{fetchImpl:async url=>new Response(fs.readFileSync(path.join(root,new URL(url).pathname.replace('/pwsh-operations-catalog/',''))),{headers:{'content-type':'text/plain'}})});
  const archive=Buffer.from(await (await f.api.buildIRBundle()).arrayBuffer());
  const report=JSON.parse(execFileSync('python3',['-c','import io,sys,zipfile,hashlib,json; z=zipfile.ZipFile(io.BytesIO(sys.stdin.buffer.read())); assert z.testzip() is None; print(json.dumps({n:hashlib.sha256(z.read(n)).hexdigest() for n in z.namelist()}))'],{input:archive,encoding:'utf8'}));
  assert.equal(Object.keys(report).length,5);
  for(const item of f.api.ITEMS.filter(x=>x.workflow))assert.equal(report[item.file],item.operatorCard.workflowReview.sourceSha256);
  assert.ok(report['BEC-WORKFLOW-GUIDE.md']);assert.ok(report['SHA256SUMS.txt']);
  const guide=f.window.FIELD_KIT_START.guide();
  for(const text of ['BEC-RISK-ASSESSMENT','BEC-CONTAIN-ERADICATE','BEC-RECOVER-VALIDATE','48 hours','blocked or cancelled'])assert.ok(guide.includes(text));
});

test('IR package fails closed if any source bytes or release evidence differ',async()=>{
  const f=loadCatalog(root,{fetchImpl:async()=>new Response('changed script',{headers:{'content-type':'text/plain'}})});
  await assert.rejects(()=>f.api.buildIRBundle(),/checksum mismatch/);
  const risk=f.api.ITEMS.find(x=>x.file==='BEC-RISK-ASSESSMENT.ps1');risk.operatorCard.workflowReview.baselineVerification.operatorTested=false;
  await assert.rejects(()=>f.api.buildIRBundle(),/release review/);
});

test('missing start guidance leaves source controls available with a clear blocked state',()=>{
  const f=loadCatalog(root);f.window.FIELD_KIT_START=undefined;
  f.api.openItem(f.api.ITEMS.find(item=>item.file==='BEC-RISK-ASSESSMENT.ps1'));
  const html=f.elements.get('drawerBody').innerHTML;
  assert.ok(html.includes('Start guidance could not load'));
  assert.ok(html.includes('id="downloadSource"'));
  assert.ok(!html.includes('id="downloadIRWorkflow"'));
});

test('quick command risk, scoped preparation and missing-source readiness stay aligned',()=>{
  const f=loadCatalog(root);
  for(const item of f.api.ITEMS){
    if(!item.publishedPath&&!item.code){
      assert.equal(item.status,'Source pending',item.name);
      assert.ok(f.api.rowTags(item).includes('SOURCE PENDING'));
      f.api.openItem(item);
      const html=f.elements.get('drawerBody').innerHTML;
      assert.ok(html.includes('Source pending. Download not available yet.'));
      assert.ok(!html.includes('CONNECT FIRST'));
      assert.ok(!html.includes('id="downloadSource"'));
    }
    if(item.type==='Quick Command'){
      assert.ok(!/^\s*={8,}\s*$/m.test(item.code),item.name);
      assert.ok(!item.code.includes('<Package.Id>'),item.name);
      assert.ok(!item.connect.includes('Connect-MgGraph'),item.name);
    }
  }
  for(const name of ['Delete User','Delete Cloud User','Hard-Delete Search Results']){
    const item=f.api.ITEMS.find(x=>x.name===name);
    assert.equal(item.access,'Destructive');
    assert.ok(f.api.rowTags(item).includes('Destructive'));
  }
  for(const name of ['Show Graph Context','Disconnect Microsoft Graph']){
    const item=f.api.ITEMS.find(x=>x.name===name);
    assert.equal(item.connect.length,0);
    f.api.openItem(item);
    assert.ok(!f.elements.get('drawerBody').innerHTML.includes('CONNECT FIRST'));
  }
  for(const name of ['Show WinGet Package Information','Update Specific WinGet Package']){
    const item=f.api.ITEMS.find(x=>x.name===name);
    assert.ok(item.input.includes('winget search'));
    assert.ok(item.code.includes('--exact'));
  }
});

test('every script has compact operational details and source-reviewed prerequisites',()=>{
 const f=loadCatalog(root);
 for(const item of f.api.ITEMS.filter(x=>x.publishedPath?.endsWith('.ps1'))){
  f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
  assert.ok(html.includes('<summary>DETAILS</summary>'),item.file);
  assert.ok(!html.includes('<summary>CHECKS</summary>'),item.file);
  assert.ok(!html.split('<summary>DETAILS</summary>')[0].includes('Technical requirements:'),item.file);
  assert.ok(item.requires,item.file);
 }
 const removal=f.api.ITEMS.find(x=>x.file==='INVOKE-REMOVE-USER-GROUPS.ps1');f.api.openItem(removal);
 const html=f.elements.get('drawerBody').innerHTML;assert.ok(html.includes('Removes memberships, not the groups themselves.'));assert.ok(html.includes('managed or protected'));
 for(const [file,review] of Object.entries(f.window.FIELD_KIT_CARD_GUIDANCE)){
  const item=f.api.ITEMS.find(x=>x.file===file);assert.ok(item,file);assert.equal(review.sourceSha256,digest(fs.readFileSync(path.join(root,item.publishedPath))),file);
 }
});

test('quick command examples disclose replacement inputs before preparation or command',()=>{
  const f=loadCatalog(root);
  const examples=f.api.ITEMS.filter(x=>x.type==='Quick Command'&&/username|user@domain\.com|GROUP-OBJECT-ID|APP-ID/.test(x.code));
  assert.ok(examples.length>50);
  for(const item of examples){
    f.api.openItem(item);
    const html=f.elements.get('drawerBody').innerHTML;
    assert.ok(html.includes('Replace command examples'),item.name);
    assert.ok(html.indexOf('>INPUT</div>')<html.indexOf('>COMMAND</div>'),item.name);
  }
});

test('library total lives in About while result counts appear only for search or filters',()=>{
  const f=loadCatalog(root);
  const counter=f.elements.get('entryCount');
  const search=f.elements.get('search');
  assert.equal(counter.textContent,'');
  assert.ok(counter.classList.contains('hidden'));
  f.api.state.area='Incident Response';
  search.value='';search.listeners.input();
  assert.equal(counter.textContent,`(${f.api.filteredItems().length})`);
  assert.ok(!counter.classList.contains('hidden'));
  f.api.state.area='Full Library';
  search.value='mailbox';search.listeners.input();
  assert.equal(counter.textContent,`(${f.api.filteredItems().length})`);
  search.value='';search.listeners.input();
  assert.ok(counter.classList.contains('hidden'));
  f.api.state.area='About';search.listeners.input();
  assert.ok(counter.classList.contains('hidden'));
  assert.ok(f.elements.get('results').innerHTML.includes(`${f.api.ITEMS.length} catalog entries`));
});

test('compact cards retain change impact, operational warnings and exact source controls',()=>{
 const f=loadCatalog(root);
 for(const file of ['INVOKE-ASSIGN-LICENSES.ps1','INVOKE-REMOVE-LICENSES.ps1']){
  const item=f.api.ITEMS.find(x=>x.file===file);f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
  for(const text of ['MAKES CHANGES','Run with PowerShell','id="downloadSource"','id="showSource"','DETAILS'])assert.ok(html.includes(text),file+': '+text);
  assert.ok(!html.includes('AUTO-CONNECT'));assert.ok(!html.includes('data-copy="Connect-MgGraph'));assert.ok(!html.split('<summary>DETAILS</summary>')[0].includes('User.ReadWrite.All'));
  assert.ok(html.split('<summary>DETAILS</summary>')[1].includes('User.ReadWrite.All'));
 }
 const ir=f.api.ITEMS.find(x=>x.file==='BEC-CONTAIN-ERADICATE.ps1');f.api.openItem(ir);
 assert.ok(f.elements.get('drawerBody').innerHTML.includes('terminal capture/transcripts'));
 const theme=f.api.ITEMS.find(x=>x.file==='SET-THEME-COBALT.ps1');f.api.openItem(theme);
 assert.ok(f.elements.get('drawerBody').innerHTML.includes('sets Process execution policy to Bypass'));
});

test('all script cards lead with scope, then steps, actions, details and related items',()=>{
 const f=loadCatalog(root);
 for(const item of f.api.ITEMS.filter(x=>x.operatorCard)){
  f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
  const scope=html.indexOf('class="operator-scope"'),steps=html.indexOf('guided-start'),actions=html.indexOf('operator-actions'),details=html.indexOf('class="operator-details"'),related=html.indexOf('class="related-block"');
  assert.ok(scope>=0&&scope<steps&&steps<actions&&actions<details&&details<related,item.file);
  assert.equal(f.api.relatedItems(item).length,3,item.file);
  assert.ok(!/More (?:checks|guards)|>GUARDS<|>REQUIRES</.test(html),item.file);
 }
 const groups=f.api.ITEMS.find(x=>x.file==='GET-USER-GROUPS.ps1');
 assert.deepEqual([...f.api.relatedItems(groups)].map(x=>x.displayName),['Get Group Members','Remove User Groups','Get Group Owners']);
});

test('three BEC workflow display revisions expose checksum-verified canonical source',async()=>{
  const f=loadCatalog(root,{fetchImpl:async url=>{
    const relative=new URL(url,'https://catalog.invalid/').pathname.replace(/^\/pwsh-operations-catalog\//,'').replace(/^\//,'');
    return new Response(fs.readFileSync(path.join(root,relative)),{headers:{'content-type':'text/plain'}});
  }});
  for(const file of ['BEC-RISK-ASSESSMENT.ps1','BEC-CONTAIN-ERADICATE.ps1','BEC-RECOVER-VALIDATE.ps1']){
    const matches=f.api.ITEMS.filter(item=>item.file===file);
    assert.equal(matches.length,1);
    const item=matches[0];
    assert.notEqual(item.status,'Source pending');
    assert.equal(item.publishedPath,'published-source/incident-response/'+file);
    const bytes=fs.readFileSync(path.join(root,item.publishedPath));
    assert.deepEqual(Buffer.from(await f.api.resolveSource(item),'utf8'),bytes);
    assert.ok(bytes.toString('utf8').includes('.VERSION '+item.version));
    assert.equal(f.api.isVerifiedRelease(item),false);
    assert(item.workflow);
  }
});
test('VERIFIED is bound to operator evidence, exact version and source manifest hash',()=>{
  const f=loadCatalog(root);
  const item=f.api.ITEMS.find(item=>item.file==='BEC-RISK-ASSESSMENT.ps1');
  assert.equal(f.api.releaseTag(item),'');
  item.verification={version:item.version,sha256:digest(fs.readFileSync(path.join(root,item.publishedPath))),operatorTested:true};
  assert.match(f.api.releaseTag(item),/data-verification-about/);
  assert.ok(!f.api.releaseTag(item).includes('v1.0.0'));
  for(const altered of [
    {...item,version:'99.0.0'},
    {...item,verification:{...item.verification,sha256:'0'.repeat(64)}},
    {...item,verification:{...item.verification,operatorTested:false}},
    {...item,verification:null}
  ])assert.equal(f.api.releaseTag(altered),'');
  f.window.FIELD_KIT_SOURCE_INTEGRITY={...f.window.FIELD_KIT_SOURCE_INTEGRITY,[item.publishedPath]:'1'.repeat(64)};
  assert.equal(f.api.releaseTag(item),'');
  delete item.verification;
  const ledger=JSON.parse(fs.readFileSync(path.join(root,'docs/qa/OPERATOR-SCRIPT-ALIGNMENT.json'),'utf8'));
  for(const row of ledger.filter(x=>x.changed))assert.equal(f.api.isVerifiedRelease(f.api.ITEMS.find(x=>x.file===row.file)),false,row.file);
  assert(f.api.ITEMS.filter(item=>item.verification).length===0);
  const pilot=f.api.ITEMS.find(item=>item.file==='GET-USER-GROUPS.ps1');
  assert.equal(pilot.version,'1.0.2');
  assert.equal(f.api.releaseTag(pilot),'');
});
function sourceFixture(bytes,fetchImpl){return loadCatalog(root,{integrity:{[fixturePath]:digest(bytes)},fetchImpl:fetchImpl??(async()=>new Response(bytes,{headers:{'content-type':'text/plain'}}))});}

test('connection guidance is bound to every published script and suppresses redundant sign-in commands',()=>{
  const f=loadCatalog(root);
  for(const item of f.api.ITEMS.filter(item=>item.publishedPath?.endsWith('.ps1'))){
    const profile=f.window.FIELD_KIT_CONNECTION_GUIDANCE[item.publishedPath];
    assert.ok(profile,item.publishedPath);
    assert.equal(profile.sha256,digest(fs.readFileSync(path.join(root,item.publishedPath))),item.publishedPath);
    assert.ok(['auto','local','review'].includes(profile.mode));
    f.api.openItem(item);
    const html=f.elements.get('drawerBody').innerHTML;
    assert.ok(!html.includes('id="copyDownload"'),item.file);
    assert.ok(!html.includes('release-version'),item.file);
    if(profile.mode==='auto'){
      assert.ok(!html.includes('AUTO-CONNECT'),item.file);
      assert.ok(!html.includes('Sign in when the script asks.'),item.file);
      assert.ok(!html.includes('data-copy="Connect-'),item.file);
    } else assert.ok(!html.includes('AUTO-CONNECT'),item.file);
  }
  const risk=f.api.ITEMS.find(item=>item.file==='BEC-RISK-ASSESSMENT.ps1');
  f.window.FIELD_KIT_SOURCE_INTEGRITY={...f.window.FIELD_KIT_SOURCE_INTEGRITY,[risk.publishedPath]:'0'.repeat(64)};
  f.api.openItem(risk);
  assert.ok(!f.elements.get('drawerBody').innerHTML.includes('AUTO-CONNECT'));
  assert.ok(!f.elements.get('drawerBody').innerHTML.includes('data-verification-about'));
});

test('script copy is exposed inside the verified source box and removed when code is hidden',async()=>{
  const bytes=Buffer.from('<#\n.VERSION 1.0.0\n#>\nWrite-Output "fixture"\n');
  const f=sourceFixture(bytes);
  const base=f.api.ITEMS.find(item=>item.publishedPath);
  const item={...base,file:'fixture.ps1',publishedPath:fixturePath};
  f.api.openItem(item);
  assert.ok(!f.elements.get('drawerBody').innerHTML.includes('id="copyDownload"'));
  const button=f.document.getElementById('showSource');
  await f.api.toggleSource(item,button);
  const mount=f.document.getElementById('sourceMount');
  assert.match(mount.innerHTML,/<div class="source-heading">[\s\S]*id="copyScript"/);
  let copied='';f.context.navigator.clipboard.writeText=async text=>{copied=text;};
  const copy=f.document.getElementById('copyScript');
  await copy.listeners.click({currentTarget:copy});
  assert.equal(copied,bytes.toString('utf8'));
  await f.api.toggleSource(item,button);
  assert.equal(mount.innerHTML,'');
});

test('quick command preparation is inside DETAILS with its own copy control',()=>{
  const f=loadCatalog(root);
  const item=f.api.ITEMS.find(item=>item.type==='Quick Command'&&item.connect.length&&!/^\s*(Connect-|Import-Module)/i.test(item.code));
  f.api.openItem(item);
  const html=f.elements.get('drawerBody').innerHTML;
  assert.ok(html.includes('CONNECT FIRST'));
  assert.ok(html.indexOf('CONNECT FIRST')>html.indexOf('<summary>DETAILS</summary>'));
  assert.ok(html.indexOf('<summary>DETAILS</summary>')>html.indexOf('class="command-block"'));
  assert.ok(html.includes('class="copy-mini" type="button" data-copy-source'));
});

test('source paths and reference links reject executable, external, encoded and traversal targets',()=>{
  const f=loadCatalog(root);
  for(const value of ['javascript:alert(1)','https://evil.invalid/a.ps1','//evil.invalid/a.ps1','/tools/git-repo.ps1','tools/../index.ps1','tools/%2e%2e/a.ps1','tools/a.ps1?x=1','tools/a.ps1#x','tools\\a.ps1','tools/missing.ps1']){
    assert.throws(()=>f.api.approvedSourceUrl(value));
  }
  for(const value of ['javascript:alert(1)','data:text/html,test','https://user:pass@example.invalid/','file:///tmp/source'])assert.equal(f.api.safeReferenceUrl(value),'');
  assert.equal(f.api.safeReferenceUrl('https://learn.microsoft.com/'),'https://learn.microsoft.com/');
});

test('verified source preserves BOM, Unicode and CRLF exactly; successful reads are cached',async()=>{
  const bytes=Buffer.from('\uFEFF# Windows PowerShell\r\nWrite-Host "caf\u00e9"\r\n','utf8');let requests=0;
  const f=sourceFixture(bytes,async(url,options)=>{requests++;assert.equal(options.redirect,'error');assert.equal(options.credentials,'omit');return new Response(bytes,{headers:{'content-type':'text/plain'}});});
  const source=await f.api.resolveSource({publishedPath:fixturePath});
  assert.deepEqual(Buffer.from(source,'utf8'),bytes);
  assert.equal(await f.api.resolveSource({publishedPath:fixturePath}),source);assert.equal(requests,1);
});

test('changed bytes, HTML error pages, redirects, empty and oversized source fail closed',async()=>{
  for(const response of [
    ()=>new Response('wrong content'),
    ()=>new Response('<html>Error</html>',{headers:{'content-type':'text/html'}}),
    ()=>new Response('',{status:404}),
    ()=>new Response('',{headers:{'content-length':String(3*1024*1024)}}),
    ()=>new Response(Buffer.alloc(2*1024*1024+1,65)),
    ()=>({ok:true,redirected:true}),
    ()=>new Response('')
  ]){
    const f=sourceFixture(Buffer.from('# reviewed script'),async()=>response());
    await assert.rejects(f.api.resolveSource({publishedPath:fixturePath}));assert.equal(f.api.sourceCache.size,0);
  }
});

test('timeout is actionable and failed loads can be retried',async()=>{
  let first=true;const bytes=Buffer.from('# reviewed script');
  const f=sourceFixture(bytes,async()=>{if(first){first=false;const e=new Error('abort');e.name='AbortError';throw e;}return new Response(bytes);});
  await assert.rejects(f.api.resolveSource({publishedPath:fixturePath}),/timed out/);
  assert.equal(await f.api.resolveSource({publishedPath:fixturePath}),'# reviewed script');
});

test('late source response cannot wire another card to the previous script',async()=>{
  const bytes=Buffer.from('# card A');let release;
  const f=sourceFixture(bytes,()=>new Promise(resolve=>{release=()=>resolve(new Response(bytes));}));
  const item={publishedPath:fixturePath,file:'fixture.ps1'};f.api.state.selected=item;
  const mount=f.document.getElementById('sourceMount');const button=f.document.getElementById('showSource');
  const pending=f.api.toggleSource(item,button);
  f.api.state.selected={file:'other.ps1'};mount.isConnected=false;release();await pending;
  assert.equal(mount.innerHTML,'');assert.equal(f.document.getElementById('copyScript').listeners.click,undefined);
});

test('clipboard denial falls back inside the dialog; false copy never reports COPIED',async()=>{
  const f=loadCatalog(root);f.document.body.classList.add('drawer-open');
  f.context.navigator.clipboard.writeText=async()=>{throw new Error('Permission denied');};
  f.document.execCommand=()=>false;
  const button=new FixtureElement(f.document);button.textContent='COPY';
  await f.api.copyWithFeedback(button,'test');
  assert.equal(button.textContent,'COPY');assert.match(f.document.getElementById('copyStatus').textContent,/Copy failed/);
  assert.equal(f.document.getElementById('drawerBody').children.length,1);
  f.document.execCommand=()=>true;
  await f.api.copyWithFeedback(button,'test');assert.equal(button.textContent,'COPIED');
});

test('drawer isolates background, traps keyboard focus, and restores it on close',()=>{
  const f=loadCatalog(root);const previous=f.document.activeElement;
  const item=f.api.ITEMS.find(item=>item.type==='Quick Command');f.api.openItem(item);
  f.api.openItem(f.api.ITEMS.find(other=>other!==item&&other.type==='Quick Command')); // Related-card navigation keeps the original opener.
  const shell=f.document.querySelector('.shell');const drawer=f.document.getElementById('drawer');
  assert.equal(shell.inert,true);assert.equal(drawer.inert,false);
  const first=f.document.getElementById('closeDrawer');const last=new FixtureElement(f.document);
  drawer.querySelectorAll=()=>[first,last];let prevented=false;
  f.document.activeElement=last;f.document.listeners.keydown({key:'Tab',shiftKey:false,preventDefault:()=>{prevented=true;}});
  assert(prevented);assert.equal(f.document.activeElement,first);
  prevented=false;f.document.listeners.keydown({key:'Tab',shiftKey:true,preventDefault:()=>{prevented=true;}});
  assert(prevented);assert.equal(f.document.activeElement,last);
  f.api.closeItem();assert.equal(shell.inert,false);assert.equal(drawer.inert,true);assert.equal(f.document.activeElement,previous);
});

test('global search includes every scope regardless of navigation selection',()=>{
  const f=loadCatalog(root);f.api.state.query='mailbox';f.api.state.area='Toys';
  const toysResults=f.api.filteredItems().map(x=>x.file||x.name);
  f.api.state.area='Single User';assert.deepEqual(f.api.filteredItems().map(x=>x.file||x.name),toysResults);assert(toysResults.length>0);
});

 test('script cards preserve launch exceptions and use the agreed Enter wording',()=>{
 const f=loadCatalog(root);
 for(const item of f.api.ITEMS.filter(x=>x.operatorCard)){
  f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
  if(item.workflow){assert.ok(html.includes('same PowerShell window'),item.file);assert.ok(!html.includes('Run with PowerShell'),item.file);}
  else if(/^terminal/.test(item.startMode||'')){assert.ok(html.includes('PowerShell window')||html.includes('PowerShell as administrator'),item.file);assert.ok(!html.includes('Run with PowerShell'),item.file);}
  else{assert.ok(html.includes('Select <strong>Run with PowerShell.</strong>'),item.file);assert.ok(html.includes('Press Enter to close session when complete.'),item.file);}
 }
});

test('verified rows place evidence checks in the verification column; footer retains its typography',()=>{
  const f=loadCatalog(root);
  const sample=f.api.ITEMS.find(item=>item.file==='BEC-RISK-ASSESSMENT.ps1');
  sample.verification={version:sample.version,sha256:digest(fs.readFileSync(path.join(root,sample.publishedPath))),operatorTested:true};
  f.api.state.query='ir';f.api.renderResults();
  const html=f.elements.get('results').innerHTML;
  assert.ok(html.includes('class="verification-check" aria-hidden="true">✓</span>'));
  assert.ok(html.indexOf('class="result-risk-flags"')<html.indexOf('class="result-verification"'));
  assert.ok(!html.includes('> VERIFIED</span>'));
  const css=fs.readFileSync(path.join(root,'index.html'),'utf8');
  assert.ok(css.includes('.signature-mark{font-weight:600}'));
  assert.ok(css.includes('.brand-slash{margin:0 .65em 0 .30em;font-weight:200;letter-spacing:.08em;color:var(--fk-ffffff,#ffffff)}'));
  assert.ok(css.includes('.signature-muted{color:var(--fk-ffffff,#ffffff);font-weight:200}'));
  assert.ok(css.includes('.signature-slash{margin-left:.08em;letter-spacing:.08em;color:inherit;font-weight:200}'));
});

test('quick-command copy matches its exact example and local commands have no cloud preparation',()=>{
  const f=loadCatalog(root);
  const commands=f.api.ITEMS.filter(x=>x.type==='Quick Command');
  assert.equal(commands.length,235);
  for(const item of commands){
    const review=f.window.FIELD_KIT_COMMAND_GUIDANCE[item.name];
    assert.ok(review,item.name);assert.equal(review.code,item.code,item.name);
    assert.ok(item.useFor?.length>10,item.name);
    f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
    assert.ok(html.indexOf('USE FOR')<html.indexOf('>INPUT</div>'),item.name);
    assert.ok(html.includes('START') || html.includes('CONNECT FIRST'),item.name);
    if(item.platform==='Local Windows'){
      assert.deepEqual([...item.connect],[],item.name);
      assert.ok(!/Connect-MgGraph|Connect-ExchangeOnline/.test(item.requires),item.name);
    }
  }
});

test('terminal tools preserve session context and prompt for required launch parameters',()=>{
  const f=loadCatalog(root);
  for(const file of ['git-repo.ps1','git-handoff.ps1','git-security.ps1','RESET-M365-SESSION.ps1','INVOKE-SESSION-RESET.ps1']){
    const item=f.api.ITEMS.find(x=>x.file===file);f.api.openItem(item);
    const html=f.elements.get('drawerBody').innerHTML;
    assert.ok(html.includes('existing PowerShell window'),file);
    assert.ok(!html.includes('Run with PowerShell'),file);
    if(file==='git-security.ps1')assert.ok(html.includes('-Account (Read-Host'),file);
    if(['git-repo.ps1','git-handoff.ps1'].includes(file))assert.ok(html.includes('-Path (Read-Host'),file);
  }
  const join=f.api.ITEMS.find(x=>x.file==='JOIN-COMPUTER-TO-DOMAIN.ps1');f.api.openItem(join);
  assert.ok(f.elements.get('drawerBody').innerHTML.includes('Open PowerShell as administrator'));
});

test('cards preserve investigative limits and do not promise unavailable searches or tools',()=>{
  const f=loadCatalog(root);
  const intel=f.api.ITEMS.find(x=>x.file==='BEC-GET-THREAT-INTEL-ACTIVITY.ps1');
  assert.ok(!intel.objective.includes('tenant activity'));
  const mail=f.api.ITEMS.find(x=>x.file==='BEC-GET-TENANT-EMAIL-SEARCH.ps1');
  assert.ok(!mail.objective.includes('subject'));
  for(const item of f.api.ITEMS.filter(x=>x.status==='Source pending')){
    f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
    assert.ok(html.includes('Planned tool:'),item.file);
    assert.ok(!html.includes('class="guided-start"'),item.file);
    assert.ok(!html.includes('id="downloadSource"'),item.file);
  }
  for(const name of ['Isolate Device - Disable Enabled Adapters','Restart Adapter','Release And Renew Dhcp']){
    f.api.openItem(f.api.ITEMS.find(x=>x.name===name));
    assert.ok(f.elements.get('drawerBody').innerHTML.includes('Can disconnect your remote session'),name);
  }
  f.api.openItem(f.api.ITEMS.find(x=>x.name==='Set Local User Password'));
  assert.ok(f.elements.get('drawerBody').innerHTML.includes('command history or recordings'));
});


test('release card contract covers every source, command, default and completion path',()=>{
  const f=loadCatalog(root);
  const hashes=Object.fromEntries(f.api.ITEMS.filter(x=>x.publishedPath).map(x=>[x.publishedPath,digest(fs.readFileSync(path.join(root,x.publishedPath)))]));
  assert.deepEqual(validateCardContract({...f,hashes}),{sources:94,scripts:81,commands:235,pending:0});
  for(const item of f.api.ITEMS.filter(x=>x.publishedPath?.endsWith('.ps1'))){
    f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
    assert.ok(html.includes('<summary>DETAILS</summary>'),item.file);
  }
});

test('release card contract rejects missing inputs, requirements, launch and completion guidance',()=>{
  for(const field of ['input','requires','startMode','completion']){
    const f=loadCatalog(root),review=f.window.FIELD_KIT_CARD_GUIDANCE['GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1'];
    delete review[field];
    if(field==='completion')delete f.api.ITEMS.find(x=>x.file==='GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1').completion;
    const hashes=Object.fromEntries(f.api.ITEMS.filter(x=>x.publishedPath).map(x=>[x.publishedPath,digest(fs.readFileSync(path.join(root,x.publishedPath)))]));
    assert.throws(()=>validateCardContract({...f,hashes}),/Card needs/,field);
  }
});

test('release card contract rejects stale source and command guidance and missing reviews',()=>{
  for(const kind of ['source','command','missing','launch']){
    const f=loadCatalog(root);
    const hashes=Object.fromEntries(f.api.ITEMS.filter(x=>x.publishedPath).map(x=>[x.publishedPath,digest(fs.readFileSync(path.join(root,x.publishedPath)))]));
    if(kind==='source')hashes['published-source/endpoint/GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1']='0'.repeat(64);
    if(kind==='command')f.window.FIELD_KIT_COMMAND_GUIDANCE['Get User'].code+='; Get-Date';
    if(kind==='missing')f.window.FIELD_KIT_COMMAND_GUIDANCE={};
    if(kind==='launch')f.window.FIELD_KIT_START=undefined;
    assert.throws(()=>validateCardContract({...f,hashes}),/stale|Missing|launch guidance/,kind);
  }
});


test('the eight accepted report releases retain historical acceptance without inheriting it for changed bytes',()=>{
 const f=loadCatalog(root),ledger=JSON.parse(fs.readFileSync(path.join(root,'docs/qa/OPERATOR-SCRIPT-ALIGNMENT.json'),'utf8'));
 const names=['GET-QUARTERLY-CLEANUP-REVIEW.ps1','GET-TENANT-GROUP-OWNERS.ps1','GET-MAILBOX-PERMISSIONS.ps1','GET-MAILBOX-SECURITY-SNAPSHOT.ps1','BEC-GET-TOKEN-REPLAY-CHECK.ps1','GET-USER-PREDELETE-CHECK.ps1','GET-USER-SECURITY-SNAPSHOT.ps1','GET-TENANT-SECURITY-SNAPSHOT.ps1'];
 for(const file of names){const item=f.api.ITEMS.find(x=>x.file===file),row=ledger.find(x=>x.file===file);
  assert.equal(row.priorVerification.ownerAccepted,true,file);assert.equal(row.priorVerification.testMode,'Sampled read-only batch and HTML export',file);
  assert.equal(row.priorVerification.sha256,row.oldSha256,file);assert.equal(f.api.isVerifiedRelease(item),false,file);
  assert.equal(row.newSha256,digest(fs.readFileSync(path.join(root,item.publishedPath))),file);
  assert.ok(fs.readFileSync(path.join(root,item.publishedPath),'utf8').includes('function Offer-FKDesktopReport'));
 }
});

test('batch two acceptance remains tied to original bytes and resource acceptance is not invented',()=>{
 const f=loadCatalog(root),ledger=JSON.parse(fs.readFileSync(path.join(root,'docs/qa/OPERATOR-SCRIPT-ALIGNMENT.json'),'utf8'));
 const evidence=JSON.parse(fs.readFileSync(path.join(root,'docs/qa/BATCH-2-1.0.0-VERIFICATION.json'),'utf8'));
 assert.equal(evidence.records.length,11);
 for(const record of evidence.records){const item=f.api.ITEMS.find(x=>x.file===record.file || x.operatorCard?.legacyFiles?.includes(record.file)),row=ledger.find(x=>x.file===item?.file);
  assert.equal(row.oldSha256,record.releaseSha256,record.file);assert.equal(row.priorVerification.sha256,record.releaseSha256,record.file);
  assert.equal(record.readFailures,0);assert.equal(f.api.isVerifiedRelease(item),false,record.file);
 }
 assert.equal(f.api.isVerifiedRelease(f.api.ITEMS.find(x=>x.file==='GET-ROOM-RESOURCE-ACCESS.ps1')),false);
});


test('all 81 purpose sentences match reviewed source objectives and stay visible before scope',()=>{
 const f=loadCatalog(root),records=JSON.parse(fs.readFileSync(path.join(root,'docs/qa/CARD-OBJECTIVES-REVIEW.json'),'utf8'));
 assert.equal(records.length,81);
 for(const r of records){const item=f.api.ITEMS.find(x=>x.file===r.file);f.api.openItem(item);
  const html=f.elements.get('drawerBody').innerHTML,esc=s=>s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#039;');
  assert.equal(item.operatorCard.objective,r.objective,r.file);
  assert.equal(item.objective,r.objective,r.file);
  assert.ok(html.includes(`<p class="operator-purpose">${esc(r.objective)}</p>`),r.file);
  assert.ok(html.indexOf('operator-purpose')<html.indexOf('operator-scope'),r.file);
  assert.ok(html.indexOf('operator-purpose')<html.indexOf('guided-start'),r.file);
 }
});

test('all 81 scripts use reviewed relationships and every runnable relationship resolves',()=>{
 const f=loadCatalog(root);
 for(const item of f.api.ITEMS.filter(x=>x.operatorCard || x.type==='Quick Command')){
  const related=f.api.relatedItems(item);
  assert.equal(related.length,3,item.file||item.name);
  assert.equal(new Set(related).size,3,item.file||item.name);
  assert.ok(related.every(other=>other!==item && other.status!=='Source pending' && (other.publishedPath || other.code)));
  if(item.operatorCard)assert.deepEqual(Array.from(related,x=>x.type==='Quick Command'?'command:'+x.name:x.file),Array.from(item.operatorCard.related));
 }
 for(const item of f.api.ITEMS)assert.ok(!/^IR:/.test(item.displayName),item.displayName);
 const byFile=file=>f.api.ITEMS.find(x=>x.file===file);
 for(const file of ['BEC-INVOKE-EMAIL-RECOVERY.ps1','BEC-GET-TENANT-EMAIL-SEARCH.ps1']){
  const other=file==='BEC-INVOKE-EMAIL-RECOVERY.ps1'?'BEC-GET-TENANT-EMAIL-SEARCH.ps1':'BEC-INVOKE-EMAIL-RECOVERY.ps1';
  assert.ok(!f.api.relatedItems(byFile(file)).some(x=>x.file===other),'Do not imply an unsupported trace-to-recovery handoff');
 }
 assert.ok(!f.api.relatedItems(byFile('INVOKE-RESET-CLOUD-USER-PASSWORD.ps1')).some(x=>x.file==='INVOKE-DELETE-ACCOUNTS.ps1'));
 assert.ok(!f.api.relatedItems(byFile('GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1')).some(x=>x.file==='DEPLOY-TCPIP-PRINTER.ps1'));
});

test('rendered cards retain source-supported target scope and required preparation',()=>{
 const f=loadCatalog(root),open=file=>{const item=f.api.ITEMS.find(x=>x.file===file);f.api.openItem(item);return f.elements.get('drawerBody').innerHTML;};
 const cleanup=open('CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1');
 assert.ok(cleanup.includes('SINGLE-USER') && cleanup.includes('Disabled user UPN'));
 const cleanupSource=fs.readFileSync(path.join(root,'published-source/mailbox/CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1'),'utf8');
 assert.match(cleanupSource,/param\(\[string\]\$UPN\)/);
 const reputation=open('BEC-GET-THREAT-INTEL-ACTIVITY.ps1');
 assert.ok(reputation.includes('SINGLE or MULTI-IP') && reputation.includes('TXT') && reputation.includes('API key'));
 assert.ok(open('BEC-INVOKE-EMAIL-RECOVERY.ps1').includes('an admin role alone is not enough'));
 assert.ok(open('BEC-GET-TENANT-EMAIL-SEARCH.ps1').includes('not message bodies or attachments'));
 assert.ok(open('GET-TENANT-INBOX-RULES-AUDIT.ps1').includes('-IncludeShared'));
 assert.ok(open('GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1').includes('ten largest files'));
 assert.ok(open('git-repo.ps1').includes('-Action (Read-Host'));
 for(const file of ['SET-THEME-SEAGLASS.ps1','SET-THEME-SILICON-VALLEY.ps1','set-execution.ps1']){
  const html=open(file);assert.ok(html.indexOf('operator-notice')<html.indexOf('guided-start'));
 }
 assert.ok(open('set-execution.ps1').includes('every .ps1 file beside this file'));
});

test('presentation package approval cannot become operator verification or accept unbound evidence',async()=>{
 for(const mutation of ['hash','version','baseline','fingerprint','kind','evidence']){
  const f=loadCatalog(root,{fetchImpl:async()=>{throw Error('Unapproved package must not fetch source');}});
  const item=f.api.ITEMS.find(x=>x.file==='BEC-RISK-ASSESSMENT.ps1'),review=item.operatorCard.workflowReview;
  assert.equal(f.api.isVerifiedRelease(item),false);
  if(mutation==='hash')review.sourceSha256='0'.repeat(64);
  if(mutation==='version')review.version='99.0.0';
  if(mutation==='baseline')review.baselineVerification.sha256='0'.repeat(64);
  if(mutation==='fingerprint')review.nonPresentationSha256='0'.repeat(64);
  if(mutation==='kind')review.kind='presentation-only';
  if(mutation==='evidence')review.evidence='other-review.md';
  await assert.rejects(()=>f.api.buildIRBundle(),/release review/);
 }
});

test('novice searches prioritize matching complete tools and preserve exact command choices',()=>{
  const f=loadCatalog(root);
  for(const [query,name] of [['groups','Get User Groups'],['forwarding','Get Mailbox Forwarding'],['readiness','Check M365 PowerShell Readiness'],['Show Mailbox Forwarding','Show Mailbox Forwarding']]){
    f.api.state.query=query;
    assert.equal(f.api.filteredItems()[0].displayName,name,query);
  }
});

test('search rows show purposes and the same entity scope as opened cards',()=>{
  const f=loadCatalog(root);f.api.state.query='forwarding';f.api.renderResults();
  const item=f.api.ITEMS.find(x=>x.file==='GET-MAILBOX-FORWARDING.ps1');
  assert.ok(f.elements.get('results').innerHTML.includes(item.operatorCard.objective));
  assert.ok(f.api.rowTags(item).includes('SINGLE or MULTI-MAILBOX'));
  assert.ok(!f.api.rowTags(item).includes('MULTI USER'));
  assert.ok(f.api.startMarkup(item).includes('Right-click the downloaded file.'));
});

test('unpublished plans stay out of working searches, counts and cards',()=>{
  const f=loadCatalog(root);
  assert.equal(f.api.PLANNED_ITEMS.length,11);
  assert.equal(f.api.ITEMS.length,329);
  assert.ok(f.api.ITEMS.every(x=>x.publishedPath || x.code));
  for(const item of f.api.PLANNED_ITEMS){
    f.api.state.query=item.displayName;
    assert.ok(!f.api.filteredItems().some(x=>x.file===item.file));
  }
  f.api.state.area='About';f.api.renderResults();
  const html=f.elements.get('results').innerHTML;
  assert.ok(html.includes('PLANNED TOOLS (11)'));
  for(const item of f.api.PLANNED_ITEMS)assert.ok(html.includes(item.displayName));
});

test('every quick command has three source-bound reviewed relationships',()=>{
  const f=loadCatalog(root);
  const records=JSON.parse(fs.readFileSync(path.join(root,'command-relationship-specs.json'),'utf8'));
  const commands=f.api.ITEMS.filter(x=>x.type==='Quick Command');assert.equal(commands.length,235);
  for(const item of commands){
    const record=records[item.name];assert.equal(record.code,item.code,item.name);
    const links=Array.from(f.api.relatedItems(item));
    assert.equal(links.length,3,item.name);assert.equal(new Set(links).size,3,item.name);
    assert.ok(links.every(x=>x!==item && (x.publishedPath || x.code)),item.name);
    assert.deepEqual(links.map(x=>x.type==='Quick Command'?'command:'+x.name:x.file),record.related,item.name);
    item.code+='\n# Changed source';assert.equal(f.api.relatedItems(item).length,0,'Stale relationship review must not bind');
  }
});

test('task searches exclude incidental mentions in code, setup and broad subareas',()=>{
  const f=loadCatalog(root);
  for(const [query,excluded] of [['groups','Compare Script Files'],['printer','Restart Service'],['forwarding','Remove Mailbox Full Access Delegate']]){
    f.api.state.query=query;assert.ok(!f.api.filteredItems().some(x=>x.displayName===excluded),query);
  }
});

test('file input examples use supported columns and resource mailboxes do not advertise file input',()=>{
  const f=loadCatalog(root);
  const bulk=f.api.ITEMS.filter(x=>x.operatorCard?.input.includes('CSV'));
  assert.equal(bulk.length,15);
  for(const item of bulk){
    const sample=item.operatorCard.inputExample;
    assert.ok(sample && ['UPN','Group'].includes(sample.header),item.file);
    const source=fs.readFileSync(path.join(root,item.publishedPath),'utf8');
    assert.ok(source.includes('Import-Csv'),item.file);
    assert.ok(source.includes("'"+sample.header+"'") || source.includes('"'+sample.header+'"'),item.file);
    f.api.openItem(item);const html=f.elements.get('drawerBody').innerHTML;
    assert.ok(!html.includes('TXT: one entry per line.'));
    assert.ok(html.includes('Multiple entries: separate with commas when typing into the script.'));
    assert.ok(html.includes(sample.values.join(',')));
  }
  const resource=f.api.ITEMS.find(x=>x.file==='GET-ROOM-RESOURCE-ACCESS.ps1');
  assert.ok(!/CSV|TXT/.test(resource.operatorCard.input));
  f.api.openItem(resource);assert.ok(f.elements.get('drawerBody').innerHTML.includes('File input is not supported.'));
});

test('browsing defaults to alphabetical with an expandable type key',()=>{const f=loadCatalog(root);const names=Array.from(f.api.filteredItems(),x=>x.displayName);assert.deepEqual(names,[...names].sort((a,b)=>a.localeCompare(b)));f.api.renderResults();assert.match(f.elements.get('typeKeyItems').innerHTML,/One target/);assert.match(f.elements.get('typeKeyItems').innerHTML,/Organization-wide/);});

test('verified sorting remains evidence-bound and row columns are explicit',()=>{
 const f=loadCatalog(root);f.api.setCatalogSort('verified');
 const names=Array.from(f.api.filteredItems(),x=>x.displayName);
 assert.equal(names.length,329);
 assert.match(f.elements.get('results').innerHTML,/result-verification/);
 assert.match(f.elements.get('results').innerHTML,/No recorded operator acceptance/);
 assert.doesNotMatch(f.elements.get('results').innerHTML,/result-check verification-check/);
 f.api.setCatalogSort('verified');assert.equal(f.api.state.sortDirection,-1);
 const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
 assert.match(html,/data-sort="verified"/);assert.match(html,/>Script name /);
 assert.doesNotMatch(html,/id="showVerificationAbout"/);
});

test('VERIFIED header click sorts evidence matches both ways and explains empty status',()=>{
 const f=loadCatalog(root);const header=f.elements.get('catalogHead');
 const click=()=>header.listeners.click({target:{closest:()=>({getAttribute:()=> 'verified'})}});
 click();assert.equal(f.api.state.sortKey,'verified');
 assert.match(f.elements.get('verificationSortNote').textContent,/77 earlier-version accepted/);
 assert.equal(f.elements.get('verificationSortNote').classList.contains('hidden'),false);
 const item=f.api.ITEMS.find(x=>x.file==='BEC-RISK-ASSESSMENT.ps1');
 item.verification={version:item.version,sha256:digest(fs.readFileSync(path.join(root,item.publishedPath))),operatorTested:true};
 click();assert.equal(f.api.filteredItems().at(-1),item);
 click();assert.equal(f.api.filteredItems()[0],item);
 assert.match(f.elements.get('verificationSortNote').textContent,/1 current-release accepted/);
 f.api.state.area='About';f.api.renderResults();assert.equal(f.elements.get('verificationSortNote').classList.contains('hidden'),true);
});

test('historical checkmarks remain distinct from exact-release verification and expire on changes',()=>{
 const f=loadCatalog(root),items=f.api.ITEMS.filter(x=>f.api.verificationHistory(x));
 assert.equal(items.length,77);
 for(const item of items)assert.equal(f.api.isVerifiedRelease(item),false,item.file);
 f.api.setCatalogSort('verified');assert.equal(f.api.verificationRank(f.api.filteredItems()[0]),1);
 assert.equal(f.api.verificationRank(f.api.filteredItems().at(-1)),0);
 assert.match(f.elements.get('results').innerHTML,/verification-historical/);
 assert.doesNotMatch(f.elements.get('results').innerHTML,/✓\*/);
 assert.match(f.elements.get('results').innerHTML,/Earlier version accepted; current revision not retested/);
 const item=items[0];f.api.openItem(item);assert.match(f.elements.get('drawerBody').innerHTML,/Current revision not retested/);
 item.version='changed';assert.equal(f.api.verificationHistory(item),null);
 const next=items[1];f.window.FIELD_KIT_SOURCE_INTEGRITY={...f.window.FIELD_KIT_SOURCE_INTEGRITY,[next.publishedPath]:'0'.repeat(64)};
 assert.equal(f.api.verificationHistory(next),null);
 execFileSync(process.execPath,['tools/build-verification-history.mjs','--check'],{cwd:root});
});

test('workflow domains cover every entry while Reports is a cross-domain view',()=>{
 const f=loadCatalog(root),domains=Array.from(f.api.DOMAIN_SECTIONS);
 assert.deepEqual(domains,[...domains].sort((a,b)=>a.localeCompare(b)));
 for(const item of f.api.ITEMS)assert.ok(domains.includes(f.api.catalogDomain(item)),item.file);
 const cases={'GET-USER-GROUPS.ps1':'Identity','INVOKE-ASSIGN-LICENSES.ps1':'Licensing','GET-MAILBOX-FORWARDING.ps1':'Mailbox','BEC-RISK-ASSESSMENT.ps1':'Incident Response','GET-MFA-SECURITY-AUDIT.ps1':'Security','BACKUP-USER-PROFILE.ps1':'Endpoint','INSTALL-M365-MODULES.ps1':'Tools','attractor.ps1':'Extras'};
 for(const [file,domain] of Object.entries(cases))assert.equal(f.api.catalogDomain(f.api.ITEMS.find(x=>x.file===file)),domain);
 f.api.state.area='Reports';const reports=f.api.filteredItems();assert.ok(reports.length>10);
 assert.ok(reports.every(x=>f.api.isReportView(x)));
 for(const file of ['INVOKE-FILE-INVENTORY.ps1','INVOKE-MAP-KIT.ps1'])assert.ok(reports.some(x=>x.file===file),file);
 assert.ok(!reports.some(x=>x.operatorCard.family==='terminal'));
 for(const item of f.api.ITEMS.filter(x=>x.operatorCard && /read.only/i.test(x.access) && x.operatorCard.family!=='terminal'))assert.ok(reports.includes(item),item.file);
 assert.ok(new Set(reports.map(x=>f.api.catalogDomain(x))).size>3);
 const nav=f.elements.get('areaNav').innerHTML;assert.doesNotMatch(nav,/Request \/ Submit/);
 for(const label of ['Manage','Protect &amp; Respond','Resources'])assert.ok(nav.includes(label));
 const page=fs.readFileSync(path.join(root,'index.html'),'utf8');assert.match(page,/class="request-link"/);assert.match(page,/>Submit a Request /);assert.match(page,/>Icon Guide</);
 f.api.state.query='mailbox';const button={getAttribute:()=> 'Identity'};
 f.elements.get('areaNav').listeners.click({target:{closest:selector=>selector==='[data-area]'?button:null}});
 assert.equal(f.api.state.query,'');assert.equal(f.api.state.area,'Identity');
 assert.ok(f.api.filteredItems().every(x=>f.api.catalogDomain(x)==='Identity'));
});
