// Publish recorded acceptance history without upgrading it to current-release testing.
import fs from 'node:fs';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
const rows=JSON.parse(fs.readFileSync('docs/qa/OPERATOR-SCRIPT-ALIGNMENT.json','utf8'));
const history={};
for(const row of rows){
 const prior=row.priorVerification;
 if(!prior?.operatorTested || prior.sha256!==row.oldSha256)continue;
 assert.match(prior.sha256,/^[a-f0-9]{64}$/);
 assert.equal(crypto.createHash('sha256').update(fs.readFileSync(row.path)).digest('hex'),row.newSha256,row.file);
 assert.ok(fs.existsSync(prior.evidence),row.file);
 history[row.file]={path:row.path,currentVersion:row.version,currentSha256:row.newSha256,accepted:prior};
}
const output='// Generated from recorded acceptance history; not current-release operator verification.\nwindow.FIELD_KIT_VERIFICATION_HISTORY = Object.freeze('+JSON.stringify(history,null,2)+');\n';
if(process.argv.includes('--check'))assert.equal(fs.readFileSync('verification-history.js','utf8'),output,'Verification history is stale');
else fs.writeFileSync('verification-history.js',output);
console.log(`${Object.keys(history).length} source-bound historical acceptance records`);
