// Release gate for source-matched card copy. Does not verify runtime behavior.
import assert from 'node:assert/strict';
const meaningful=value=>typeof value==='string' && value.trim().length>0;
const concreteInput=value=>meaningful(value)&&!/^(?:tenant|user|none|n\/a|no input|nothing)$/i.test(value.trim());
export function validateCardContract({api,window,hashes}){
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
      assert(operator && meaningful(operator.name) && meaningful(operator.scope) && meaningful(operator.input),`Missing approved operator card: ${label}`);
      assert.equal(operator.sourceSha256,hashes[item.publishedPath],`Operator copy is stale: ${label}`);
      assert(Array.isArray(operator.details) && operator.details.length>0,`Operational details missing: ${label}`);
      assert.equal(api.relatedItems(item).length,3,`Three usable related items required: ${label}`);
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
      assert(Array.isArray(review.connectFirst),`Quick command needs reviewed preparation, including an empty list for local commands: ${label}`);
    }else{
      counts.pending++;
      assert.equal(item.status,'Source pending',`Missing source presented as runnable: ${label}`);
    }
  }
  return counts;
}
