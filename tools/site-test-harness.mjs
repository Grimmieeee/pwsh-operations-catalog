// Dependency-free DOM fixture for catalog checks; not shipped as a browser dependency.
import vm from 'node:vm';
import fs from 'node:fs';
import path from 'node:path';
import { webcrypto } from 'node:crypto';

export class FixtureElement {
  constructor(document){
    this.document=document; this.attributes={}; this.dataset={}; this.style={}; this.listeners={};
    this.children=[]; this.isConnected=true; this.textContent=''; this.innerHTML=''; this.value=''; this.inert=false;
    const values=new Set();
    this.classList={add:(...names)=>names.forEach(n=>values.add(n)),remove:(...names)=>names.forEach(n=>values.delete(n)),
      contains:name=>values.has(name),toggle:(name,force)=>{const enabled=force??!values.has(name);enabled?values.add(name):values.delete(name);return enabled;}};
  }
  querySelectorAll(){return [];}
  querySelector(){return null;}
  setAttribute(name,value){this.attributes[name]=String(value);}
  getAttribute(name){return this.attributes[name]??null;}
  addEventListener(name,callback){this.listeners[name]=callback;}
  appendChild(element){element.parentElement=this;this.children.push(element);return element;}
  select(){this.document.activeElement=this;}
  focus(){this.document.activeElement=this;}
  remove(){this.isConnected=false;}
  contains(element){return this===element||this.children.includes(element);}
  getClientRects(){return [{}];}
}

export function loadCatalog(root,{integrity,fetchImpl}={}){
  const elements=new Map();
  const document={activeElement:null,listeners:{},execCommand:()=>true,
    addEventListener(name,fn){this.listeners[name]=fn;},
    getElementById(id){if(!elements.has(id))elements.set(id,new FixtureElement(document));return elements.get(id);},
    querySelector(selector){return this.getElementById(selector);},
    createElement(){return new FixtureElement(document);}};
  document.body=new FixtureElement(document);
  document.activeElement=document.getElementById('search');
  const location=new URL('https://example.invalid/pwsh-operations-catalog/');
  const window={location,innerWidth:1200,crypto:webcrypto,addEventListener(){},
    requestAnimationFrame:fn=>fn(),setTimeout,clearTimeout};
  const logs=[];
  const context=vm.createContext({window,document,navigator:{clipboard:{writeText:async()=>{}}},
    HTMLElement:FixtureElement,URL,TextDecoder,TextEncoder,AbortController,Uint8Array,Blob,Response,
    fetch:fetchImpl??(async()=>{throw new Error('Unexpected network request in fixture');}),
    console:{info:(...args)=>logs.push(args),error:(...args)=>logs.push(args)}});
  vm.runInContext(fs.readFileSync(path.join(root,'catalog-data.js'),'utf8'),context);
  const manifestPath=path.join(root,'source-integrity.js');
  if(integrity)window.FIELD_KIT_SOURCE_INTEGRITY=integrity;
  else if(fs.existsSync(manifestPath))vm.runInContext(fs.readFileSync(manifestPath,'utf8'),context);
  const guidancePath=path.join(root,'connection-guidance.js');
  if(fs.existsSync(guidancePath))vm.runInContext(fs.readFileSync(guidancePath,'utf8'),context);
  const cardPath=path.join(root,'card-guidance.js');
  if(fs.existsSync(cardPath))vm.runInContext(fs.readFileSync(cardPath,'utf8'),context);
  const startPath=path.join(root,'workflow-start.js');
  if(fs.existsSync(startPath))vm.runInContext(fs.readFileSync(startPath,'utf8'),context);
  const historyPath=path.join(root,'verification-history.js');
  if(fs.existsSync(historyPath))vm.runInContext(fs.readFileSync(historyPath,'utf8'),context);
  const source=fs.readFileSync(path.join(root,'field-kit-app.js'),'utf8');
  const marker='  runFrameworkAudit();';
  if(!source.includes(marker))throw new Error('Catalog startup changed; update the checker');
  const instrumented=source.replace(marker,`  window.__TEST = { ITEMS,PLANNED_ITEMS,state,filteredItems,renderResults,catalogIconType,catalogIconMarkup,catalogCompare,setCatalogSort,openItem,closeItem,approvedSourceUrl,resolveSource,safeReferenceUrl,copyText,copyWithFeedback,toggleSource,sourceCache,runFrameworkAudit,isVerifiedRelease,verificationHistory,verificationRank,releaseTag,rowTags,buildIRBundle,buildSetupBundle,connectionInfo,inputInfo,startMarkup,completionInfo,finishMarkup,relatedItems };\n${marker}`);
  vm.runInContext(instrumented,context);
  return {api:window.__TEST,window,document,elements,context,logs};
}
