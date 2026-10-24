// Release gate for source-matched card copy. Does not verify runtime behavior.
import assert from 'node:assert/strict';
const meaningful=value=>typeof value==='string' && value.trim().length>0;
const concreteInput=value=>meaningful(value)&&!/^(?:tenant|user|none|n\/a|no input|nothing)$/i.test(value.trim());
export function validateCardContract({api,window,document,hashes}){
  const counts={sources:0,scripts:0,commands:0,pending:0};
  const sourceRecords=window.FIELD_KIT_CARD_GUIDANCE;
  const commandRecords=window.FIELD_KIT_COMMAND_GUIDANCE;
  assert(sourceRecords && commandRecords,'Reviewed card guidance must load');
  assert(typeof window.FIELD_KIT_START?.launch==='function','Reviewed launch guidance must load');
  for(const item of api.ITEMS){
    const label=item.file||item.name;
    if(item.publishedPath){
      counts.sources++;
      const review=sourceRecords[item.file];
      assert(review,`Missing source-bound card review: ${label}`);
      assert.equal(review.sourceSha256,hashes[item.publishedPath],`Card review is stale: ${label}`);
      if(!item.publishedPath.endsWith('.ps1'))continue;
      counts.scripts++;
      const operator=window.FIELD_KIT_OPERATOR_CARDS?.[item.file];
      assert(operator && meaningful(operator.name) && meaningful(operator.scope) && meaningful(operator.input) && meaningful(operator.objective),`Missing approved operator card: ${label}`);
      assert.equal(operator.objective,review.objective,`Card/script purpose records differ: ${label}`);
      assert.equal(operator.sourceSha256,hashes[item.publishedPath],`Operator copy is stale: ${label}`);
      assert(Array.isArray(operator.details) && operator.details.length>0,`Operational details missing: ${label}`);
      assert.equal(api.relatedItems(item).length,3,`Three usable related items required: ${label}`);
      assert(Array.isArray(operator.related) && new Set(operator.related).size===3 && !operator.related.includes(item.file),`Three distinct reviewed relationships required: ${label}`);
      assert.deepEqual(Array.from(api.relatedItems(item),other=>other.type==='Quick Command'?'command:'+other.name:other.file),Array.from(operator.related),`Rendered relationships differ from review: ${label}`);
      for(const other of api.relatedItems(item))assert((other.publishedPath || other.code) && other.status!=='Source pending',`Related source unavailable: ${label}`);
      assert(Array.isArray(operator.preparation),`Reviewed operational preparation missing: ${label}`);
      api.openItem(item);
      const rendered=document.getElementById('drawerBody').innerHTML;
      const escape=text=>text.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#039;');
      const scope=/GROUP$/.test(operator.scope)?operator.scope==='SINGLE-GROUP'?'1 group':'1 or more groups':operator.scope;
      const input=operator.input.replace(/\s*\/\s*(?:CSV|TXT)/g,'');
      for(const text of [operator.objective,scope,input,...operator.preparation,...operator.details])assert(rendered.includes(escape(text)),`Reviewed operator information not displayed: ${label}`);
      const formats=['CSV','TXT'].filter(format=>operator.input.includes(format)).join(' or ');
      if(formats)assert(rendered.includes(formats),`Reviewed file formats not displayed: ${label}`);
      if(operator.notice){
        assert(rendered.includes(escape(operator.notice)),`Operational notice not displayed: ${label}`);
        assert(rendered.indexOf('operator-notice')<rendered.indexOf('guided-start'),`Operational notice must precede launch: ${label}`);
      }
      assert(meaningful(review.objective),`Card needs a purpose: ${label}`);
      assert(concreteInput(review.input) && concreteInput(api.inputInfo(item)),`Card needs explicit inputs or default context: ${label}`);
      assert(meaningful(review.requires),`Card needs reviewed requirements: ${label}`);
      assert(['right-click','terminal','terminal-admin','workflow'].includes(review.startMode),`Card needs a reviewed launch mode: ${label}`);
      assert.equal(review.startMode==='workflow',Boolean(item.workflow),`Workflow launch mode differs from card: ${label}`);
      assert(meaningful(api.startMarkup(item)),`Card needs launch directions: ${label}`);
      const completion=api.completionInfo(item);
      for(const field of ['result','next','blocked'])assert(meaningful(completion?.[field]),`Card needs completion ${field}: ${label}`);
      assert(meaningful(api.finishMarkup(item)),`Card needs rendered completion help: ${label}`);
    }else if(item.type==='Quick Command'){
      counts.commands++;
      const review=commandRecords[item.name];
      assert(review,`Missing quick-command review: ${label}`);
      assert.equal(review.code,item.code,`Quick-command review is stale: ${label}`);
      assert(meaningful(review.useFor),`Quick command needs a purpose: ${label}`);
      assert(concreteInput(review.input) && concreteInput(api.inputInfo(item)),`Quick command needs explicit inputs or default context: ${label}`);
      assert(meaningful(review.requires),`Quick command needs reviewed requirements: ${label}`);
      assert.equal(api.relatedItems(item).length,3,`Three reviewed related items required for quick command: ${label}`);
      assert(Array.isArray(review.related) && new Set(review.related).size===3,`Explicit quick-command relationships missing: ${label}`);
      assert(Array.isArray(review.connectFirst),`Quick command needs reviewed preparation, including an empty list for local commands: ${label}`);
    }else{
      counts.pending++;
      assert.equal(item.status,'Source pending',`Missing source presented as runnable: ${label}`);
    }
  }
  return counts;
}
