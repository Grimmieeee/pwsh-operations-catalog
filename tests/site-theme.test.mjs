import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const source=fs.readFileSync(path.join(root,'site-theme.js'),'utf8');
function fixture({saved=null,light=false,blocked=false,mediaUnavailable=false}={}){
 const attributes={},events={},systemEvents={},control={value:'',listeners:{},addEventListener(k,v){this.listeners[k]=v;}},meta={setAttribute(k,v){this[k]=v;}};
 const media={matches:light,addEventListener(k,v){systemEvents[k]=v;}};
 const storage=new Map(saved?[['field-kit-appearance',saved]]:[]);
 const window={localStorage:{getItem(k){if(blocked)throw Error('blocked');return storage.get(k)||null;},setItem(k,v){if(blocked)throw Error('blocked');storage.set(k,v);}},matchMedia(){if(mediaUnavailable)throw Error('unavailable');return media;},addEventListener(k,v){events[k]=v;}};
 const document={readyState:'complete',documentElement:{setAttribute(k,v){attributes[k]=v;}},querySelector(){return meta;},getElementById(){return control;}};
 vm.runInNewContext(source,{window,document});
 return {attributes,control,meta,storage,media,systemEvents,events};
}
test('system preference is applied immediately and follows later changes',()=>{
 const f=fixture({saved:'system',light:true});assert.equal(f.attributes['data-theme'],'light');assert.equal(f.control.value,'system');
 f.media.matches=false;f.systemEvents.change();assert.equal(f.attributes['data-theme'],'dark');
});
test('explicit choice survives system changes and is persisted',()=>{
 const f=fixture({saved:'dark',light:true});assert.equal(f.attributes['data-theme'],'dark');
 f.control.value='light';f.control.listeners.change();assert.equal(f.storage.get('field-kit-appearance'),'light');
 f.media.matches=false;f.systemEvents.change();assert.equal(f.attributes['data-theme'],'light');
 f.control.value='system';f.control.listeners.change();assert.equal(f.attributes['data-theme'],'dark');
});
test('blocked storage and missing media APIs leave the control functional',()=>{
 const f=fixture({blocked:true,mediaUnavailable:true});assert.equal(f.attributes['data-theme'],'dark');
 f.control.value='light';f.control.listeners.change();assert.equal(f.attributes['data-theme'],'light');assert.equal(f.meta.content,'#f4f7f3');
});
test('invalid saved values are rejected and other tabs synchronize valid choices',()=>{
 const f=fixture({saved:'untrusted-value'});assert.equal(f.control.value,'dark');
 f.events.storage({key:'field-kit-appearance',newValue:'light'});assert.equal(f.attributes['data-theme'],'light');
 f.events.storage({key:'field-kit-appearance',newValue:null});assert.equal(f.control.value,'dark');
});
test('appearance control remains labeled and bootstrap stays within self-only script policy',()=>{
 const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
 assert.ok(html.includes('aria-label="Color theme"'));assert.ok(html.indexOf('site-theme.js')<html.indexOf('<style>'));
 assert.ok(html.includes("script-src 'self'"));assert.ok(!html.includes("script-src 'self' 'unsafe-inline'"));
});
test('brighter status colors remain readable with existing typography',()=>{
 const css=fs.readFileSync(path.join(root,'site-theme.css'),'utf8');
 const luminance=hex=>{const values=hex.match(/[a-f0-9]{2}/gi).map(v=>parseInt(v,16)/255).map(v=>v<=.04045?v/12.92:((v+.055)/1.055)**2.4);return values[0]*.2126+values[1]*.7152+values[2]*.0722;};
 const contrast=(a,b)=>{const x=luminance(a),y=luminance(b);return (Math.max(x,y)+.05)/(Math.min(x,y)+.05);};
 for(const [palette,bg] of [['#afffdd #ffe19b #ffaba3 #bbffe6','#151b1e'],['#176b4d #7a5700 #aa3833 #176b4d','#f4f7f3']])for(const color of palette.split(' '))assert.ok(contrast(color,bg)>=4.5,color);
 assert.ok(!css.includes('font:400 13px/1.5 var(--ui)'));
 assert.ok(!css.includes('border-width:1px'));
});

test('first visit defaults to Dark even on a light system',()=>{const f=fixture({light:true});assert.equal(f.control.value,'dark');assert.equal(f.attributes['data-theme'],'dark');});
