// All-entry screening. Pattern matches are review leads, not runtime evidence.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const {api}=loadCatalog(root);
const hash=bytes=>crypto.createHash('sha256').update(bytes).digest('hex');
const ledgerFile=path.join(root,'docs/qa/SOURCE-REVIEW-LEDGER.json');
const ledger=fs.existsSync(ledgerFile)?JSON.parse(fs.readFileSync(ledgerFile,'utf8')):{};
const rules=[
 ['URI_VARIABLE_QUESTION',/\$[a-zA-Z_]\w*\?`?\$/,'Check URI variable boundaries.'],
 ['SWALLOWED_ERROR',/catch\s*\{\s*return\s+\$(?:null|false)\s*\}/i,'Trace callers: a swallowed error can become missing/clean data.'],
 ['FIRST_MATCH',/return\s+@\(\$(?:fallback|result)\.value\)\[0\]/i,'Review identity ambiguity and actual call sites.'],
 ['COMPLETION_MESSAGE',/\b(?:OK|Write-OK)\s+["']Complete(?:[.!"'])/i,'Review whether failure and unavailable states remain visible.'],
 ['HOST_EXIT',/^\s*exit(?:\s+\d+)?\s*$/i,'Review interactive host lifetime.'],
 ['QUIET_ERROR',/-(?:ErrorAction|EA)\s+SilentlyContinue\b/i,'Distinguish optional probes from hidden failures.'],
 ['POLICY_CHANGE',/\bSet-ExecutionPolicy\b/i,'Check explicit setup/theme purpose and disclosure.'],
 ['LOCAL_INSTALL',/\b(?:Install-Module|Install-WindowsFeature|Add-WindowsCapability)\b/i,'Distinguish printed directions from executable installs.'],
 ['PROCESS_START',/\b(?:Start-Process|Invoke-Expression)\b/i,'Review external input and invocation arguments.']
];
const entries=api.ITEMS.map(item=>{
 const bytes=item.publishedPath?fs.readFileSync(path.join(root,item.publishedPath)):null;
 const text=bytes?bytes.toString('utf8'):item.code||'';
 const sha256=bytes?hash(bytes):text?hash(text):null;
 const kind=bytes?(/\.ps1$/i.test(item.file)?'PowerShell':'Reference'):item.code?'Quick command':'Source pending';
 const signals=[];
 for(const [id,re,note] of rules)for(const match of text.matchAll(new RegExp(re.source,[...new Set(re.flags+'gm')].join(''))))signals.push({id,line:text.slice(0,match.index).split('\n').length,note});
 const record=ledger[item.file]?.sha256===sha256?ledger[item.file]:null;
 const operator=api.isVerifiedRelease(item);
 return {name:item.displayName,file:item.file,path:item.publishedPath||null,kind,access:item.access,sha256,
  family:operator?'Verified IR':kind==='PowerShell'?(/Toys|Tools/.test(item.logicalArea)?'Local tools / toys':/change|destructive|mixed/i.test(item.access)?'Change workflows':'Read-only workflows'):kind,
  state:operator?'Operator verified — exact version':record?.state||'Needs review',review:record,signals,
  authentication:{graph:/\b(?:Connect-MgGraph|Invoke-MgGraphRequest)\b/i.test(text),exchange:/\bConnect-ExchangeOnline\b/i.test(text),ad:/\b(?:Get|Set|Remove|Disable|Enable|New|Add)-AD\w+/i.test(text)},
  resultStates:[...new Set([...text.matchAll(/(?:Result|Status)\s*=\s*["']([a-zA-Z][a-zA-Z -]{1,30})["']/g)].map(x=>x[1]))]};
});
const report={note:'Every catalog entry screened. Pattern signals require source review. Scoped review and automated tests do not confer operator verification.',counts:{entries:entries.length,scripts:entries.filter(x=>x.kind==='PowerShell').length,commands:entries.filter(x=>x.kind==='Quick command').length,references:entries.filter(x=>x.kind==='Reference').length,pending:entries.filter(x=>x.kind==='Source pending').length,operatorVerified:entries.filter(x=>x.state.startsWith('Operator verified')).length,scopedReviews:entries.filter(x=>x.review).length},entries};
const output=JSON.stringify(report,null,2)+'\n',target=path.join(root,'docs/qa/CATALOG-SAFETY-AUDIT.json');
if(process.argv.includes('--write')){
 fs.writeFileSync(target,output);
 const cells=value=>String(value).replaceAll('|','/').replaceAll('\n',' ');
 const rows=entries.filter(x=>x.kind==='PowerShell').map(x=>`| ${cells(x.file)} | ${cells(x.family)} | ${cells(x.state)} | ${cells(x.review?.scope.join('; ')||'Parser/integrity screening; detailed source review remains')} |`).join('\n');
 fs.writeFileSync(path.join(root,'docs/qa/CATALOG-SAFETY-MATRIX.md'),'# Catalog safety review matrix\n\nGenerated from current source hashes. Automated-test states describe the listed scope only; native operator verification is a separate gate. Pattern matches in the JSON are review leads.\n\n'+JSON.stringify(report.counts)+'\n\n| Script | Family | Review state | Scope / remaining review |\n|---|---|---|---|\n'+rows+'\n');
}
else if(process.argv.includes('--check')){if(fs.readFileSync(target,'utf8')!==output)throw new Error('Safety inventory is stale. Review source changes and regenerate with --write.');}
else process.stdout.write(output);
if(process.argv.includes('--write')||process.argv.includes('--check'))console.log(JSON.stringify(report.counts));
