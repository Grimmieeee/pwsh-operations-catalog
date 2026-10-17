// Reproducible presentation-only candidates. Service logic is checked separately.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {loadCatalog} from './site-test-harness.mjs';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const inspection=JSON.parse(fs.readFileSync(process.argv[2],'utf8').replace(/^\uFEFF/,''));
const baseline=path.resolve(process.argv[3]);
const {api}=loadCatalog(root);
const scalarArray=x=>x==null?[]:Array.isArray(x)?x:[x];
const ps=s=>"'"+s.replace(/[\u2018\u2019]/g,"'").replace(/[\u201c\u201d]/g,'"').replace(/[\u2013\u2014]/g,'-').replaceAll("'","''")+"'";
const report=[];
const custom=new Set(['tools/git-handoff.ps1','tools/git-repo.ps1','tools/git-security.ps1','tools/set-execution.ps1']);
const statusFunctions=new Map([['ok',['[OK]','Green']],['write-ok',['[OK]','Green']],['info',['[INFO]',null]],['write-info',['[INFO]',null]],['warn',['[WARN]','Yellow']],['write-warn',['[WARN]','Yellow']],['risk',['[RISK]','Red']],['fail',['[FAIL]','Red']],['write-fail',['[FAIL]','Red']]]);
const headings=new Set(['Section','Write-Section','Show-Section']);
const plainHeadings=new Map([['SUMMARY','TICKET SUMMARY'],['GROUP','TARGET'],['USER','TARGET'],['MAILBOX','TARGET'],['FOLLOW-UP','NEXT STEP'],['NEXT','NEXT STEP'],['STANDARD NOTE','STATUS']]);
const helpers=`
# Console presentation only. Does not request scopes, query services or write data.
$script:FKEndWritten = $false
$script:FKStatusWritten = $false
$script:FKHasIssue = $false
function Write-FKStatus {
    param([string]$Status)
    Write-Host ''
    if ($Status -eq 'REVIEW REQUIRED') { Write-Host ('STATUS: '+$Status) -ForegroundColor Yellow }
    else { Write-Host ('STATUS: '+$Status) }
    $script:FKStatusWritten = $true
}
function Write-FKStart {
    param([string]$Title,[string]$Objective,[string]$Mode)
    Write-Host $Title
    Write-Host $Objective
    if ($Mode) { Write-Host $Mode }
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    Write-Host ''
}
function Write-FKHeading {
    param([string]$Title)
    Write-Host ''
    switch ($Title.Trim().ToUpperInvariant()) {
        'SUMMARY' { Write-Host 'TICKET SUMMARY'; break }
        'FOLLOW-UP' { Write-Host 'NEXT STEP'; break }
        'NEXT' { Write-Host 'NEXT STEP'; break }
        default { Write-Host $Title }
    }
}
function Close-FKConsole {
    param([bool]$SkipPause = $false)
    if (-not $script:FKEndWritten) {
        Write-Host ''
        if (-not $script:FKStatusWritten) {
            Write-FKStatus $(if ($script:FKHasIssue) { 'REVIEW REQUIRED' } else { 'RUN FINISHED' })
        }
        Write-Host ("COMPLETED: {0}" -f (Get-Date).ToString('MM/dd/yyyy HH:mm'))
        $script:FKEndWritten = $true
    }
    if ($SkipPause) { return }
    Write-Host ''
    Write-Host 'Press ESC to close'
    if ($Host.Name -eq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and
        (Get-Command Read-Host).CommandType -ne 'Function') {
        try {
            while ($true) {
                $key=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                if ($key.VirtualKeyCode -eq 27 -or $key.VirtualKeyCode -eq 13) { return }
            }
        }
        catch { Write-Host 'Key input unavailable here.' }
    }
    while ($true) {
        $answer=Read-Host 'Type ESC then press ENTER to close'
        if ([string]::IsNullOrWhiteSpace($answer) -or $answer.Trim() -ieq 'ESC' -or $answer -eq [string][char]27) { return }
    }
}
`;
for(const item of inspection){
 const base=path.join(baseline,item.path);
 const original=fs.readFileSync(fs.existsSync(base)?base:path.join(root,item.path));
 fs.mkdirSync(path.dirname(base),{recursive:true});fs.writeFileSync(base,original);
 let reason=item.batch==='Completed IR release'?'Retain exact verified IR 1.0.0':item.path.startsWith('toys/')?'Preserve custom animation/theme contract':custom.has(item.path)?'Custom repository/security/setup interaction requires focused review':scalarArray(item.parseErrors).length?'Existing parse error; held for separate fix':null;
 const functions=scalarArray(item.functions),commands=scalarArray(item.commands);
 const pause=functions.find(f=>f.name==='Pause-End');
 const title=commands.find(c=>c.name==='Write-Host'&&!c.function&&c.value&&/^[A-Z][A-Z0-9 &:/()_-]{5,}$/.test(c.value)&&!c.value.startsWith('READ-ONLY'));
 if(!reason&&(!pause||!title))reason='Custom entry/closing layout requires focused review';
 if(reason){report.push({path:item.path,state:'Unchanged',reason});continue;}
 const text=original.toString('utf8').replace(/^\uFEFF/,'');
 if(text.includes('function Write-FKStart'))throw Error('Already aligned: '+item.path);
 const edits=[];const covered=[];
 for(const f of functions){
  const params=scalarArray(f.parameters);const status=statusFunctions.get(f.name.toLowerCase());
  if(status&&params.length===1){
   const name=params[0];const [prefix,color]=status;
   edits.push({start:f.start,end:f.end,value:`function ${f.name} {\n    param([string]$${name})\n${['[WARN]','[FAIL]','[RISK]'].includes(prefix)?'    $script:FKHasIssue = $true\n':''}    Write-Host ${ps(prefix+' ')}${color?' -ForegroundColor '+color:''} -NoNewline\n    Write-Host $${name}\n}`});covered.push(f);continue;
  }
  if(headings.has(f.name)&&params.length===1){
   edits.push({start:f.start,end:f.end,value:`function ${f.name} {\n    param([string]$${params[0]})\n    Write-FKHeading -Title $${params[0]}\n}`});covered.push(f);continue;
  }
  if(f.name==='Pause-End'){
   const hasNoPause=/\$NoPause\b/.test(item.params||'');
   edits.push({start:f.start,end:f.end,value:`function Pause-End {\n    Close-FKConsole${hasNoPause?' -SkipPause ([bool]$NoPause)':''}\n}`});covered.push(f);
  }
 }
 const meta=api.ITEMS.find(x=>x.publishedPath===item.path);
 const objective=(meta?.objective||meta?.notes||item.name).split(/(?<=[.!?])\s+/)[0];
 const mode=/destructive/i.test(item.access)?'MAKES CHANGES / DESTRUCTIVE':/change|mixed/i.test(item.access)?'MAKES CHANGES':'';
 edits.push({start:title.start,end:title.end,value:`Write-FKStart -Title ${ps(title.value)} -Objective ${ps(objective)} -Mode ${ps(mode)}`});
 for(const c of commands){
  if(c===title||covered.some(f=>c.start>=f.start&&c.end<=f.end))continue;
  if(c.name==='Write-Host'&&plainHeadings.has(c.value))edits.push({start:c.start,end:c.end,value:`Write-FKHeading -Title ${ps(plainHeadings.get(c.value))}`});
  if(c.name==='Write-Host'&&!c.function&&/^(READ-ONLY\. NO CHANGES MADE\.|Read-only|Change-making|CHANGE-MAKING|CHANGES MAY BE MADE\.)$/i.test(c.value||''))edits.push({start:c.start,end:c.end,value:"Write-Host ''"});
 }
 const inject=Math.min(...functions.map(f=>f.start));
 edits.push({start:inject,end:inject,value:helpers+'\n'});
 edits.sort((a,b)=>b.start-a.start||b.end-a.end);
 let result=text,previous=text.length+1;
 for(const e of edits){if(e.end>previous)throw Error('Overlapping presentation edits: '+item.path);result=result.slice(0,e.start)+e.value+result.slice(e.end);previous=e.start;}
 const h=crypto.createHash('sha256').update(item.path).digest('hex');
 const guid=`${h.slice(0,8)}-${h.slice(8,12)}-${h.slice(12,16)}-${h.slice(16,20)}-${h.slice(20,32)}`;
 result=`<#PSScriptInfo\n.VERSION 0.1.0\n.GUID ${guid}\n.AUTHOR FIELD // KIT\n.DESCRIPTION Console alignment candidate; operator validation pending.\n#>\n`+result;
 const encoded=(original[0]===0xef&&original[1]===0xbb&&original[2]===0xbf?'\uFEFF':'')+result;
 fs.writeFileSync(path.join(root,item.path),encoded,'utf8');
 report.push({path:item.path,state:'Formatting candidate',version:'0.1.0',baselineSha256:crypto.createHash('sha256').update(original).digest('hex'),sha256:crypto.createHash('sha256').update(encoded).digest('hex'),presentationFunctions:covered.map(f=>f.name),held:/GET-ACCOUNT-STATUS\.ps1|GET-GROUP-MEMBERS\.ps1/.test(item.path)});
}
fs.writeFileSync(path.join(root,'docs/qa/CONSOLE-ALIGNMENT-REPORT.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({candidates:report.filter(x=>x.state==='Formatting candidate').length,unchanged:report.filter(x=>x.state==='Unchanged').map(x=>({path:x.path,reason:x.reason}))},null,2));
