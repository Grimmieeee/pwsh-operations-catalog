import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { loadCatalog,FixtureElement } from '../tools/site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const digest=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const fixturePath='published-source/fixture.ps1';

test('minimal cards keep full copy commands and explicit safety caveats',()=>{
  const f=loadCatalog(root);
  const license=f.api.ITEMS.find(item=>item.file==='INVOKE-ASSIGN-LICENSES.ps1');
  f.api.openItem(license);
  let html=f.elements.get('drawerBody').innerHTML;
  assert.ok(html.includes('class="connect-command"'));
  assert.ok(html.includes('Show command'));
  assert.ok(html.includes('User.ReadWrite.All'));
  assert.ok(!html.includes('<summary>Details</summary>'));
  assert.ok(html.includes('Typed ASSIGN confirmation'));
  assert.ok(html.includes('<details class="requirements"><summary title='));
  assert.ok(!html.includes('run-info-label">REQUIRES'));
  assert.ok(html.includes('script’s numbered list'));
  const removal=f.api.ITEMS.find(item=>item.file==='INVOKE-REMOVE-LICENSES.ps1');
  f.api.openItem(removal);
  html=f.elements.get('drawerBody').innerHTML;
  assert.ok(html.includes('Numbered license selection or ALL'));
  assert.ok(!html.includes('selected SKU or ALL'));
  const ir=f.api.ITEMS.find(item=>item.file==='ir-contain-eradicate.ps1');
  f.api.openItem(ir);
  html=f.elements.get('drawerBody').innerHTML;
  assert.ok(html.includes('terminal capture/transcripts'));
  const theme=f.api.ITEMS.find(item=>item.file==='SET-THEME-COBALT.ps1');
  f.api.openItem(theme);
  assert.ok(f.elements.get('drawerBody').innerHTML.includes('sets Process execution policy to Bypass'));
});

test('cards separate operational checks from inputs and safety guards without overflow groups',()=>{
  const f=loadCatalog(root);
  for(const item of f.api.ITEMS){
    f.api.openItem(item);
    const html=f.elements.get('drawerBody').innerHTML;
    assert.ok(!/More (?:checks|guards)/.test(html),item.displayName);
    for(const label of ['INPUT','CHECKS','GUARDS']){
      assert.ok(html.split(`<div class="section-label">${label}</div>`).length<=2,item.displayName);
    }
  }
  const hold=f.api.ITEMS.find(item=>/Enforce Litigation Hold/.test(item.displayName));
  assert.ok(hold);
  f.api.openItem(hold);
  const html=f.elements.get('drawerBody').innerHTML;
  const checks=html.slice(html.indexOf('>CHECKS</div>'),html.indexOf('>GUARDS</div>'));
  const guards=html.slice(html.indexOf('>GUARDS</div>'),html.indexOf('<section class="run-info-block">'));
  for(const text of ['Pre-change hold-state review','Unlimited duration target','Post-change mailbox re-read','Optional CSV evidence']) assert.ok(checks.includes(text),text);
  for(const text of ['Typed HOLD confirmation','Changes only noncompliant mailboxes','REQUIRES']) assert.ok(guards.includes(text),text);
  const inputStart=html.indexOf('>INPUT</div>');
  assert.ok(inputStart>=0 && inputStart<html.indexOf('>CHECKS</div>'));
  assert.ok(html.slice(inputStart,html.indexOf('>CHECKS</div>')).includes('TXT/CSV mailbox list'));
  assert.ok(!guards.includes('>INPUT</div>'));
  assert.ok(!checks.includes('Typed HOLD confirmation'));
  assert.ok(!html.includes('More guards'));
});

test('three tested IR workflow steps expose checksum-verified canonical source',async()=>{
  const f=loadCatalog(root,{fetchImpl:async url=>{
    const relative=new URL(url,'https://catalog.invalid/').pathname.replace(/^\/pwsh-operations-catalog\//,'').replace(/^\//,'');
    return new Response(fs.readFileSync(path.join(root,relative)),{headers:{'content-type':'text/plain'}});
  }});
  for(const file of ['ir-risk-assessment.ps1','ir-contain-eradicate.ps1','ir-recover-validate.ps1']){
    const matches=f.api.ITEMS.filter(item=>item.file===file);
    assert.equal(matches.length,1);
    const item=matches[0];
    assert.notEqual(item.status,'Source pending');
    assert.equal(item.publishedPath,'published-source/incident-response/'+file);
    const bytes=fs.readFileSync(path.join(root,item.publishedPath));
    assert.deepEqual(Buffer.from(await f.api.resolveSource(item),'utf8'),bytes);
    assert.match(bytes.toString('utf8'),/\.VERSION 1\.0\.0/);
    assert.equal(f.api.isVerifiedRelease(item),true);
    assert(item.workflow);
  }
});
test('VERIFIED is bound to operator evidence, exact version and source manifest hash',()=>{
  const f=loadCatalog(root);
  const item=f.api.ITEMS.find(item=>item.file==='ir-risk-assessment.ps1');
  assert.match(f.api.releaseTag(item),/VERIFIED · <span class="release-version">v1\.0\.0<\/span>/);
  for(const altered of [
    {...item,version:'1.0.1'},
    {...item,verification:{...item.verification,sha256:'0'.repeat(64)}},
    {...item,verification:{...item.verification,operatorTested:false}},
    {...item,verification:null}
  ])assert(!f.api.releaseTag(altered).includes('VERIFIED'));
  f.window.FIELD_KIT_SOURCE_INTEGRITY={...f.window.FIELD_KIT_SOURCE_INTEGRITY,[item.publishedPath]:'1'.repeat(64)};
  assert(!f.api.releaseTag(item).includes('VERIFIED'));
  assert(f.api.ITEMS.filter(item=>item.verification).length===3);
});
function sourceFixture(bytes,fetchImpl){return loadCatalog(root,{integrity:{[fixturePath]:digest(bytes)},fetchImpl:fetchImpl??(async()=>new Response(bytes,{headers:{'content-type':'text/plain'}}))});}

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
