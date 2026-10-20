// Generate a source-grounded queue; this does not certify script behavior.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const {api}=loadCatalog(root);
const entries=api.ITEMS.map(item=>{
 const source=item.publishedPath?fs.readFileSync(path.join(root,item.publishedPath)):null;
 const script=!!source&&/\.ps1$/i.test(item.file);
 const sourceKind=source?'Published source':item.status==='Source pending'?'Source pending':item.code?'Inline command':'Reference / planned entry';
 const batch=!source?(sourceKind==='Inline command'?'Quick commands':sourceKind==='Source pending'?'Source-pending triage':'Reference / planned triage'):!script?'Documentation / reference':api.isVerifiedRelease(item)?'Completed verified release':/Toys|Tools/.test(item.logicalArea)?'Local tools and toys':/destructive|change|mixed/i.test(item.access)?'Change and destructive workflows':/^Tenant/.test(item.group)?'Tenant-wide read-only audits':'Identity, mailbox and IR read-only tools';
 return {file:item.file,name:item.name,type:item.type,sourceKind,area:item.logicalArea,group:item.group,access:item.access,catalogStatus:item.status,publishedPath:item.publishedPath||null,version:item.version||null,sha256:source?crypto.createHash('sha256').update(source).digest('hex'):null,batch,reviewState:api.isVerifiedRelease(item)?'Verified exact release':'Review required',operatorTested:api.isVerifiedRelease(item)};
}).sort((a,b)=>a.batch.localeCompare(b.batch)||a.file.localeCompare(b.file));
const counts={catalogEntries:entries.length,publishedSources:entries.filter(x=>x.publishedPath).length,publishedPowerShell:entries.filter(x=>x.publishedPath&&/\.ps1$/i.test(x.file)).length,verifiedReleases:entries.filter(x=>x.operatorTested).length,batches:{}};
for(const e of entries)counts.batches[e.batch]=(counts.batches[e.batch]||0)+1;
fs.writeFileSync(path.join(root,'docs/qa/CATALOG-REVIEW-INVENTORY.json'),JSON.stringify({note:'Repository inventory only. Unbadged does not mean untested; reconcile owner evidence before scheduling. Batch 1 is closed; see docs/PROJECT-STATUS.md. Update after source/catalog changes.',counts,entries},null,2)+'\n');
console.log(JSON.stringify(counts,null,2));
