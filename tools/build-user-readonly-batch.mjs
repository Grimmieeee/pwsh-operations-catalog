// Package exact candidates with the reviewed runner; no source rewriting.
// Run: node tools/build-user-readonly-batch.mjs /absolute/output/directory
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const sources=[
 ['Forwarding','published-source/mailbox/GET-MAILBOX-FORWARDING.ps1'],
 ['Permissions','published-source/mailbox/GET-MAILBOX-PERMISSIONS.ps1'],
 ['Groups','published-source/identity/GET-USER-GROUPS.ps1']
];
const manifest={schemaVersion:1,batchVersion:'0.1.0',scripts:sources.map(([key,p])=>({key,path:p,version:'0.1.0',sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex')}))};
fs.writeFileSync(path.join(root,'docs/qa/user-readonly-manifest.json'),JSON.stringify(manifest,null,2)+'\n');
if(!process.argv[2]){console.log('Manifest refreshed; supply an output directory to build a ZIP.');process.exit(0);}
const output=path.resolve(process.argv[2]);
const folder=path.join(output,'FIELD-KIT-User-ReadOnly-Batch-0.1.0');
fs.mkdirSync(folder,{recursive:true});
const copy=(from,to)=>{const destination=path.join(folder,to);fs.mkdirSync(path.dirname(destination),{recursive:true});fs.copyFileSync(path.join(root,from),destination);};
for(const [,p]of sources)copy(p,p);
copy('docs/qa/Invoke-UserReadOnlyBatch.ps1','Invoke-UserReadOnlyBatch.ps1');
copy('docs/qa/user-readonly-manifest.json','user-readonly-manifest.json');
copy('docs/qa/USER-READONLY-BATCH.md','READ-ME.md');
const zip=folder+'.zip';
execFileSync('python3',['-c','import zipfile,pathlib,sys;root=pathlib.Path(sys.argv[1]);z=zipfile.ZipFile(sys.argv[2],"w",zipfile.ZIP_DEFLATED);[(z.write(p,p.relative_to(root))) for p in sorted(root.rglob("*")) if p.is_file()];z.close()',folder,zip]);
console.log(zip);
