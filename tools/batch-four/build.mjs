import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
const root=path.resolve(import.meta.dirname,'../..');
const definitions=[
 ['Disable','published-source/identity/INVOKE-DISABLE-ACCOUNTS.ps1',8,'Simulated cloud disable workflow: preview, approval, mutation and readback; auth and AD are fixtures.'],
 ['MFA','published-source/identity/INVOKE-ENFORCE-PER-USER-MFA.ps1',7,'Simulated per-user MFA workflow: approval, mutation and readback; auth is a fixture.'],
 ['Hold','published-source/mailbox/INVOKE-LITIGATION-HOLD.ps1',8,'Simulated hold enforcement workflow: approval, mutation and readback; Exchange/auth are fixtures.'],
 ['Delete','published-source/identity/INVOKE-DELETE-ACCOUNTS.ps1',7,'Exact Graph lookup and post-delete absence verification functions only; no account deletion.'],
 ['Groups','published-source/identity/INVOKE-REMOVE-USER-GROUPS.ps1',6,'Membership DELETE route and eventual removal readback functions only; no actual group changes.'],
 ['Cleanup','published-source/mailbox/CLEANUP-DISABLED-USER-MAILBOX-ACCESS.ps1',8,'Principal matching and SendOnBehalf target isolation only; disabled-state/auth and removal are not exercised.'],
 ['Recovery','published-source/incident-response/BEC-INVOKE-EMAIL-RECOVERY.ps1',5,'Encoded message-move request and root-folder creation functions only; no mailbox access or message changes.'],
 ['Drift','published-source/tenant/GET-TENANT-DRIFT-REVIEW.ps1',6,'Synthetic added/removed/changed comparisons and real temporary JSON write/read; no tenant queries.'],
 ['Modules','published-source/utility/INSTALL-M365-MODULES.ps1',4,'Simulated module installation workflow with cancellation, scope and failure checks; nothing is installed.'],
 ['Session','published-source/utility/RESET-M365-SESSION.ps1',3,'Simulated reset workflow; checks unrelated sessions are preserved; no real disconnections.'],
 ['JumpboxSession','tools/INVOKE-SESSION-RESET.ps1',3,'Simulated jumpbox reset workflow; no password variable removal, disconnections or new windows.'],
 ['Execution','tools/set-execution.ps1',6,'Simulated execution-policy/unblock workflow; managed policy preserved; no real policy/unblock changes.'],
 ['ThreatIntel','published-source/incident-response/BEC-GET-THREAT-INTEL-ACTIVITY.ps1',14,'IP input guards only; provider API calls, credentials and reputation findings are not tested.'],
 ['GitSecurity','tools/git-security.ps1',13,'Event triage and real temporary JSON/JSON-lines parsing; no GitHub requests or real security logs.'],
 ['MapKit','tools/INVOKE-MAP-KIT.ps1',3,'Actual map workflow against a tiny disposable folder, including missing path; signatures skipped.'],
 ['Storage','published-source/endpoint/GET-WINDOWS-STORAGE-CLEANUP-REVIEW.ps1',3,'Storage collector with synthetic CIM/file records; top-file ranking and skip option; no real drive walk.']
];
const hash=b=>crypto.createHash('sha256').update(b).digest('hex');
const files=[...definitions.map(x=>x[1]),'tests/batch-four.test.ps1'].map(relative=>{const bytes=fs.readFileSync(path.join(root,relative));return {path:relative,sha256:hash(bytes),source:bytes.toString('base64')};});
const payload=Buffer.from(JSON.stringify({schema:1,version:'0.1.0',cases:definitions.reduce((sum,row)=>sum+row[2],0),suites:definitions.map(([id,source,cases,scope])=>({id,source,cases,scope})),files}));
const template=fs.readFileSync(path.join(import.meta.dirname,'runner.ps1.txt'),'utf8');
const out=path.resolve(process.argv[2]||path.join(import.meta.dirname,'Invoke-FieldKitBatch4-v0.1.0.ps1'));
fs.writeFileSync(out,'\ufeff'+template.replace('__PAYLOAD__',zlib.gzipSync(payload).toString('base64')).replace('__HASH__',hash(payload)).replace('__SUITE_COUNT__',String(definitions.length)),'utf8');
console.log(JSON.stringify({file:out,tools:definitions.length,cases:definitions.reduce((sum,row)=>sum+row[2],0),bytes:fs.statSync(out).size}));
