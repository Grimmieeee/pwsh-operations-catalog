// Replace legacy fixed colors with themeable fallbacks; dark values are retained.
import fs from 'node:fs';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
const file=path.join(root,'index.html');let html=fs.readFileSync(file,'utf8');
const current=html.match(/<style>([\s\S]*?)<\/style>/)[1];
const source=current.replace(/var\(--fk-[0-9a-f]+,(#[0-9a-f]+)\)/gi,'$1');
const colors=new Map();
for(const match of source.matchAll(/([\w-]+)\s*:\s*([^;{}]+)/g)){
 for(const hex of match[2].matchAll(/#[0-9a-f]{3,8}\b/gi)){
  const key=hex[0].toLowerCase();if(!colors.has(key))colors.set(key,new Set());colors.get(key).add(match[1]);
 }
}
const rgb=hex=>{let s=hex.slice(1);if(s.length===3)s=[...s].map(x=>x+x).join('');return [0,2,4].map(i=>parseInt(s.slice(i,i+2),16)/255);};
const hsl=hex=>{const [r,g,b]=rgb(hex),max=Math.max(r,g,b),min=Math.min(r,g,b),d=max-min,l=(max+min)/2;let h=0,s=0;if(d){s=d/(1-Math.abs(2*l-1));h=max===r?((g-b)/d)%6:max===g?(b-r)/d+2:(r-g)/d+4;h=((h*60)+360)%360;}return [h,s,l];};
const explicit={'#151b1e':'#f4f7f3','#101619':'#edf2ee','#ffffff':'#19332b','#fff':'#19332b','#e2f3ee':'#19332b','#33444b':'#c9d6ce','#27373d':'#d5dfd8','#00ffeb':'#006f61','#00f0b5':'#006f61','#ffff79':'#765d00','#ffa2ae':'#a93747'};
const light=(hex,props)=>{
 if(explicit[hex])return explicit[hex];
 const [h,s,l]=hsl(hex);let target;
 const foreground=[...props].some(p=>p==='color'||p.startsWith('--'));
 if(l<.27)target=.97-l*.25;
 else if(!foreground && [...props].some(p=>p.includes('border')))target=.70;
 else if(s>.45)target=.25;
 else target=.30;
 return `hsl(${Math.round(h)} ${Math.round(Math.min(s,.70)*100)}% ${Math.round(target*100)}%)`;
};
const css=source.replace(/#[0-9a-f]{3,8}\b/gi,hex=>`var(--fk-${hex.slice(1).toLowerCase()},${hex})`)
 .replaceAll('rgb(255 255 255 / .70)','rgb(var(--wordmark-rgb,255 255 255) / .70)')
 .replaceAll('rgb(255 255 255 / .85)','rgb(var(--wordmark-rgb,255 255 255) / .85)');
html=html.replace(current,css);fs.writeFileSync(file,html);
const palette=[...colors].sort(([a],[b])=>a.localeCompare(b)).map(([hex,props])=>`  --fk-${hex.slice(1)}:${light(hex,props)};`).join('\n');
const tail=`\n/* Color changes preserve the existing typography and geometry. */
:root{--flag-read:#afffdd;--flag-change:#ffe19b;--flag-danger:#ffaba3;--flag-verified:#bbffe6}
html{color-scheme:dark}
html[data-theme="light"]{color-scheme:light;--wordmark-rgb:25 51 43;--flag-read:#176b4d;--flag-change:#7a5700;--flag-danger:#aa3833;--flag-verified:#176b4d}
.result-verification{color:var(--flag-verified)}
.result-read,.result:hover .result-read,.access-tag.access-read,.about-key .access-read{color:var(--flag-read)}
.result-change,.result:hover .result-change,.access-tag.access-change,.about-key .access-change{color:var(--flag-change)}
.result-danger,.result:hover .result-danger,.access-tag.access-danger,.about-key .access-danger{color:var(--flag-danger)}
.result-verification .verification-seal{color:var(--flag-verified)}
.signature-note,.signature-mark,.signature-muted,.signature-established,.signature-established strong{color:var(--fk-d8f3eb,#d8f3eb)}
.signature-mark,.signature-mark .signature-slash{font-weight:400}
.result-name{font-size:18px}
.verification-check{display:inline-flex;align-items:center;justify-content:center;flex:none;width:16px;color:var(--flag-verified);font:400 15px/1 var(--ui);border:0;border-radius:0;background:transparent;letter-spacing:0}
.result-check{grid-column:3;justify-self:end}
.result-flags{max-width:none}
.verification-key{max-width:1040px;margin:10px auto 0;text-align:right}
.verification-key button{display:inline-flex;align-items:center;gap:4px;padding:4px 0;border:0;background:transparent;color:var(--muted);font:400 12px/1.4 var(--ui)}
.verification-key button:focus-visible,.verification-check:focus-visible{outline:2px solid var(--mint);outline-offset:3px}
.verification-key .verification-check{font-size:13px}
@media(min-width:761px){
  .shell{grid-template-columns:280px minmax(0,1fr)}
  .sidebar{background:var(--fk-0e1517,#0b1214)}
  .catalog{width:100%;max-width:1364px;margin-inline:0}
  .search-box{max-width:1306px;margin-left:14px;margin-right:0}
  .verification-key{max-width:1306px;margin-left:14px;margin-right:0}
  .result:hover,.result:focus-visible{background:linear-gradient(90deg,rgba(0,240,181,.10),rgba(0,240,181,.015));box-shadow:inset 3px 0 0 rgba(0,240,181,.5)}
  html[data-theme="light"] .result:hover,html[data-theme="light"] .result:focus-visible{background:linear-gradient(90deg,rgba(0,111,97,.09),rgba(0,111,97,.015));box-shadow:inset 3px 0 0 rgba(0,111,97,.5)}
}
@media(min-width:761px) and (max-width:1100px){
  .shell{grid-template-columns:250px minmax(0,1fr)}
  .result{grid-template-columns:minmax(0,1fr) auto 16px}
  .result-risk-flags{max-width:200px}
}
@media(max-width:760px){
  .result{grid-template-columns:minmax(0,1fr) 16px;grid-template-areas:"name name" "flags arrow";gap:7px 10px}
  .result-name{font-size:18px}
  .result-flags{justify-self:stretch;justify-content:flex-start;max-width:100%;min-width:0}
  .result-risk-flags{justify-content:flex-start;gap:6px 12px;max-width:100%}
  .result-tag{font-size:11px;line-height:1.4;white-space:normal}
  .result-check{grid-area:arrow;align-self:center}
  .theme-select{max-width:68px;padding:5px 2px}
  .masthead-note{gap:3px}
}
.theme-select{margin-left:auto;flex:none;max-width:84px;border:1px solid var(--line);border-radius:2px;background:transparent;color:var(--body);font:400 12px/1.4 var(--ui);padding:5px 7px;cursor:pointer}
.theme-select:focus-visible{outline:2px solid var(--mint);outline-offset:3px}
html[data-theme="light"] .overlay{background:rgba(20,40,30,.24)}
html[data-theme="light"] .drawer-overlay{background:rgba(20,40,30,.28)}
/* Compact desktop candidate; mobile retains its existing scale. */
@media(min-width:1101px){
  .shell{grid-template-columns:280px minmax(0,1fr)}
  .nav button,.area-button{font-size:16px}
  .topbar{height:58px;padding-inline:32px}
  .search-wrap{width:100%;max-width:1560px;margin-inline:auto;padding:20px 32px 18px}
  .search-box{min-height:64px;padding-inline:16px;gap:12px;max-width:none}
  .search-box input{font-size:20px}
  .search-box>span{font-size:24px}
  .catalog{padding:16px 32px 80px;max-width:1560px;margin-inline:auto}
  .verification-key{max-width:none;margin-top:10px}
  .group-title{padding-top:22px;padding-bottom:16px}
  .group-title::before{height:28px;width:4px}
  .group-title-accent,.group-title-muted{font-size:14px}
  .result{min-height:60px;grid-template-columns:minmax(0,1fr) auto 16px;padding:10px 12px;gap:12px}
  .result-name{font-size:20px}
  .result-tag{font-size:12px}
  .result-risk-flags{gap:16px}
  .result-check{font-size:15px;width:16px}
  html[data-theme="dark"] .workspace{background:linear-gradient(180deg,#172426,#111b1e)}
  html[data-theme="dark"] .sidebar{background:#0b1c1c}
  html[data-theme="dark"] .topbar,html[data-theme="dark"] .search-wrap{background:transparent}
  html[data-theme="dark"] .search-box{background:#16312e;border-color:#5b8e80}
  html[data-theme="dark"] .area-button.active{background:linear-gradient(90deg,#16473d,#102f2a)}
  html[data-theme="dark"] .result:hover,html[data-theme="dark"] .result:focus-visible{background:linear-gradient(90deg,#1b3b33,rgba(27,59,51,.12));box-shadow:inset 3px 0 0 #1ad8ae}
  html[data-theme="light"] .area-button.active{background:linear-gradient(90deg,rgba(0,111,97,.13),rgba(0,111,97,.04))}
}
`;
fs.writeFileSync(path.join(root,'site-theme.css'),'/* Light palette for legacy color fallbacks. Dark colors remain in index.html. */\nhtml[data-theme="light"]{\n'+palette+'\n}\n'+tail);
fs.appendFileSync(path.join(root,'site-theme.css'), '\n.brand-lockup{display:inline-grid;grid-template-columns:minmax(0,max-content);max-width:100%}\n.brand-tagline{width:0;min-width:100%;margin-top:10px;color:rgb(var(--wordmark-rgb,255 255 255) / .85);font:400 12px/1.5 var(--ui);letter-spacing:.29em;white-space:nowrap;text-align:justify;text-align-last:justify}\n.tagline-quickly{color:rgb(var(--wordmark-rgb,255 255 255) / .70)}\n.signature-mark,.signature-mark .signature-slash{color:rgb(var(--wordmark-rgb,255 255 255) / .85)}\n.signature-mark{letter-spacing:.65em}\n.signature-mark .signature-slash{letter-spacing:inherit;margin-left:0}\n@media(min-width:761px){.brand{height:112px;padding:27px 20px 0}.nav{padding-top:8px}.search-wrap{padding-top:62px}}\n@media(max-width:760px){.brand{padding-bottom:32px}}\n');
console.log(`Theme-enabled ${colors.size} legacy colors.`);
