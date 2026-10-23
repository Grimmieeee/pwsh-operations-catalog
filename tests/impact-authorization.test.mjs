import test from 'node:test';
import assert from 'node:assert/strict';
import {loadCatalog} from '../tools/site-test-harness.mjs';
import {checkImpactReview,root} from '../tools/impact-review.mjs';
const {api}=loadCatalog(root);
const named=name=>{const i=api.ITEMS.find(x=>x.name===name || x.aliases?.includes(name));assert.ok(i,name);return i;};
test('all active catalog entries have a current source-bound impact review',()=>assert.equal(checkImpactReview().entries,api.ITEMS.length));
test('equivalent all-inbox-rule deletions have identical impact and executable safeguards',()=>{
 const a=named('Remove All Inbox Rules'),b=named('Delete All Inbox Rules');
 assert.equal(a.access,'Destructive');assert.equal(a.access,b.access);assert.equal(a.code,b.code);
 assert.match(a.code,/Type DELETE \$Mailbox/);assert.match(a.code,/-IncludeHidden/);
 assert.ok(a.code.indexOf('Format-Table')<a.code.indexOf('Type DELETE'));
 assert.ok(a.code.indexOf('Type DELETE')<a.code.indexOf('Remove-InboxRule'));
 assert.match(a.code,/\$Remaining = @\(Get-InboxRule/);
 assert.match(a.code,/rules remain; review partial results/);
});
test('cloud and local user deletion resolve targets before target-bound approval',()=>{
 for(const name of ['Delete Cloud User','Delete Local User']){
  const i=named(name);assert.equal(i.access,'Destructive');
  assert.match(i.code,/Get-(?:MgUser|LocalUser)/);assert.match(i.code,/Type DELETE \$\(\$User\./);
  assert.match(i.code,/-cne "DELETE/);assert.match(i.code,/Cancelled; no changes/);
  assert.ok(i.code.indexOf('Type DELETE')<i.code.indexOf('Remove-'));
  assert.match(i.code,/independently verify/);
 }
});
test('hard purge requires a completed search, visible scope and search-bound approval',()=>{
 const i=named('Hard-Delete Search Results');assert.equal(i.access,'Destructive');
 assert.match(i.code,/Get-ComplianceSearch/);assert.match(i.code,/ExchangeLocation,ContentMatchQuery/);
 assert.match(i.code,/Status -ne 'Completed'/);assert.match(i.code,/-cne "PURGE \$SearchName"/);
 assert.ok(i.code.indexOf('Type PURGE')<i.code.indexOf('New-ComplianceSearchAction'));
 assert.match(i.code,/Purge submitted/);
});
test('bounded removals request native confirmation instead of suppressing it',()=>{
 for(const name of ['Remove Distribution Group Member','Remove User from AD Group','Remove Mailbox Full Access Delegate','Remove Mailbox Send As Delegate','Remove Specific Inbox Rule','Remove Calendar Permission']){
  assert.match(named(name).code,/-Confirm:\$true/,name);
  assert.doesNotMatch(named(name).code,/-Confirm:\$false/,name);
 }
});
test('disruptive quick commands require explicit opt-in and cancel within a child scope',()=>{
 for(const name of ['Reboot Computer','Stop Process By Name','Release And Renew Dhcp','Reset Tcp/Ip Stack','Reset Winsock','Restart Adapter','Restart Service','Suspend For One Reboot','Update All Eligible WinGet Packages','Disable Network Adapter','Restart Network Adapter','Isolate Device - Disable Enabled Adapters']){
  const {code}=named(name);assert.match(code,/^& \{/);assert.match(code,/Type APPLY to approve/);
  assert.match(code,/-cne 'APPLY'/);assert.match(code,/Cancelled; no changes\.'; return/);
 }
});

test('Script Setup gate is the only operational source change and precedes mutations',async()=>{
 const fs=await import('node:fs');const crypto=await import('node:crypto');
 const source=fs.readFileSync(root+'/tools/set-execution.ps1','utf8');
 const review=JSON.parse(fs.readFileSync(root+'/docs/qa/OPERATOR-SCRIPT-ALIGNMENT.json','utf8')).find(x=>x.file==='set-execution.ps1');
 const gate=source.match(/^    # BEGIN IMPACT APPROVAL\n[\s\S]*?^    # END IMPACT APPROVAL\n/m)?.[0];assert.ok(gate);
 const before=source.replace(gate,'').replace('.VERSION 1.0.3','.VERSION 1.0.2');
 assert.equal(crypto.createHash('sha256').update(before).digest('hex'),review.operationalChange.priorSourceSha256);
 assert.match(gate,/-cne 'SETUP'/);assert.match(gate,/return/);
 assert.ok(source.indexOf('Type SETUP')<source.indexOf('Set-ExecutionPolicy'));
 assert.ok(source.indexOf('Type SETUP')<source.indexOf('Unblock-File'));
});
