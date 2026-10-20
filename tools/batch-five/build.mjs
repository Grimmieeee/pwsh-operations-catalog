import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
const root=path.resolve(import.meta.dirname,'../..');
const definitions=[
 ['Cert','tools/MANAGE-CERT-SIGNATURES.ps1',6,'Certificate subject normalization and selection with fixtures; no creation, trust-store or private-key operations.'],
 ['Sign','tools/SIGN-FOLDER-SCRIPTS.ps1',4,'Certificate selection and thumbprint normalization with fixtures; no signing or trust changes.'],
 ['GitRepo','tools/git-repo.ps1',6,'Changed-filename risk screening with synthetic Git status; no real Git commands, commit, push or pull.'],
 ['Handoff','tools/git-handoff.ps1',8,'Metadata redaction and object-ID validation only; no repository reads or handoff writes.'],
 ['Preflight','tools/GET-TERMINAL-READINESS-CHECK.ps1',3,'Relative-path presentation only; no installed-module, signature or certificate readiness claim.'],
 ['Join','published-source/endpoint/JOIN-COMPUTER-TO-DOMAIN.ps1',2,'Simulated approved join workflow success/failure and reboot-pending messaging; no actual join or reboot.'],
 ['Basic','toys/SET-THEME-BASIC.ps1',4,'Actual plain output helpers; no profile or host appearance changes.'],
 ['SeaGlass','toys/SET-THEME-SEAGLASS.ps1',3,'Generated profile block boundaries, syntax and highlighting only; no installer or profile writes.'],
 ['Silicon','toys/SET-THEME-SILICON-VALLEY.ps1',3,'Generated profile block boundaries, syntax and highlighting only; no installer or profile writes.'],
 ['Cobalt','toys/SET-THEME-COBALT.ps1',3,'ANSI palette assignments only; no execution-policy or host appearance changes.'],
 ['Rain','toys/rain.ps1',3,'Cursor, narrow-width centering and clock functions only; animation and live resize not tested.'],
 ['Static','toys/static.ps1',3,'Cursor bounds and floating-label positions only; animation and live resize not tested.'],
 ['Attractor','toys/attractor.ps1',3,'Cursor bounds, negative draw guard and color reset only; animation and live resize not tested.']
];
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[...definitions.map(x=>x[1]),'tests/batch-five.test.ps1'].map(relative=>{const bytes=fs.readFileSync(path.join(root,relative));return {path:relative,sha256:hash(bytes),source:bytes.toString('base64')};});
const payload=Buffer.from(JSON.stringify({schema:1,version:'0.1.0',cases:51,suites:definitions.map(([id,source,cases,scope])=>({id,source,cases,scope})),files}));
const template=fs.readFileSync(path.join(root,'tools/batch-four/runner.ps1.txt'),'utf8')
 .replaceAll('batch 4','batch 5').replaceAll('Batch 4','Batch 5').replaceAll('BATCH 4','BATCH 5')
 .replaceAll('batch-4','batch-5').replaceAll('B4-','B5-').replaceAll('batch=4','batch=5')
 .replaceAll('batch-four.test.ps1','batch-five.test.ps1').replaceAll('16','13').replaceAll('103','51')
 .replace('utility|endpoint)/|tools/|tests/','utility|endpoint)/|tools/|toys/|tests/');
const out=path.resolve(process.argv[2]||path.join(import.meta.dirname,'Invoke-FieldKitBatch5-v0.1.0.ps1'));
fs.writeFileSync(out,'\ufeff'+template.replace('__PAYLOAD__',zlib.gzipSync(payload).toString('base64')).replace('__HASH__',hash(payload)).replace('__SUITE_COUNT__',String(definitions.length)),'utf8');
console.log(JSON.stringify({file:out,tools:definitions.length,cases:51,bytes:fs.statSync(out).size}));
