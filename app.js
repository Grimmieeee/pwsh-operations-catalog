const DATA = window.CATALOG_DATA || [];
const PAGE_SIZE = 3;
let page=1,view='grid',selectedArea='',selectedType='',selectedStatus='';
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[c]));
const norm=s=>String(s??'').toLowerCase()
  .replace(/can't/g,'cannot').replace(/won't/g,'will not').replace(/isn't/g,'is not')
  .replace(/doesn't/g,'does not').replace(/don't/g,'do not')
  .normalize('NFKD').replace(/[^\w\s@.+/-]/g,' ').replace(/\s+/g,' ').trim();

function skillFor(x){
  if(x.type==='Quick Command'||x.type==='Runbook'||x.type==='Reference') return 'Beginner';
  if(x.type==='Workflow'||x.type==='Automation'||x.access==='Destructive') return 'Advanced';
  return 'Intermediate';
}
function uniq(key){return [...new Set(DATA.map(x=>x[key]).filter(Boolean))].sort()}
function addOptions(id,vals){const el=document.getElementById(id);vals.forEach(v=>{const o=document.createElement('option');o.value=v;o.textContent=v;el.appendChild(o)})}
addOptions('categoryFilter',uniq('area'));addOptions('platformFilter',uniq('platform'));addOptions('skillFilter',['Beginner','Intermediate','Advanced']);

function safety(x){
  if(x.access==='Read-only')return['Safe check','safe-pill','safe-card'];
  if(x.access==='Change')return['Makes changes','change-pill','change-card'];
  if(x.access==='Destructive')return['Destructive','bad-pill','change-card'];
  if(x.type==='Workflow'||x.type==='Runbook')return['Workflow','workflow-pill','workflow-card'];
  if(x.type==='Automation')return['Automation','auto-pill','automation-card'];
  return[x.type||'Info','tool-pill','tool-card'];
}
function iconFor(x){
  const n=norm(x.name+' '+x.area+' '+x.subarea);
  if(n.includes('password'))return'⌕'; if(n.includes('mfa')||n.includes('auth'))return'◇';
  if(n.includes('mail')||n.includes('inbox')||n.includes('forward'))return'✉';
  if(n.includes('dns')||n.includes('network'))return'◎'; if(n.includes('group'))return'◉';
  if(n.includes('printer'))return'▣'; if(n.includes('endpoint')||n.includes('computer'))return'▣';
  if(n.includes('security')||n.includes('risk')||n.includes('compromise'))return'◇'; return'&gt;_';
}
function inputFor(x){
  if(x.input)return x.input; const c=x.code||'';
  if(/user@domain\.com/i.test(c))return'User UPN';if(/"username"/i.test(c))return'Username';
  if(/group@domain\.com|GROUP-OBJECT-ID|Group Name/i.test(c))return'Group name or ID';
  if(/server01/i.test(c))return'Hostname';if(/example\.com/i.test(c))return'Hostname or domain';
  if(/THUMBPRINT/i.test(c))return'Certificate thumbprint';if(/Rule Name/i.test(c))return'Rule name';
  if(/SEARCH-NAME/i.test(c))return'Search name';if(/1\.2\.3\.4|8\.8\.8\.8/i.test(c))return'IP address';
  return'';
}
function cleanNeeds(s){return String(s||'').replace(/^Requires:\s*/i,'').replace(/\s*\|\s*Connect:.*/i,'').trim()}
function searchBlob(x){return norm([x.name,x.type,x.area,x.subarea,x.platform,x.access,x.status,x.file,x.notes,x.keywords,x.source,(x.related||[]).join(' '),x.code].join(' '))}
function searchScore(x,q){
  if(!q)return 0; const nq=norm(q),tokens=nq.split(' ').filter(Boolean),name=norm(x.name),keys=norm(x.keywords),area=norm(x.area+' '+x.subarea),file=norm(x.file),blob=searchBlob(x);
  let s=0;
  if(name===nq)s+=180;if(name.startsWith(nq))s+=120;if(name.includes(nq))s+=90;
  if(keys.includes(nq))s+=70;if(area.includes(nq))s+=45;if(file.includes(nq))s+=35;
  for(const t of tokens){if(name.includes(t))s+=30;else if(keys.includes(t))s+=22;else if(area.includes(t))s+=14;else if(file.includes(t))s+=10;else if(blob.includes(t))s+=5}
  if(x.status==='Ready')s+=4; if(x.type==='Quick Command')s+=2;
  return s;
}
function copyText(t,b){navigator.clipboard.writeText(t).then(()=>{const old=b.textContent;b.textContent='Copied';setTimeout(()=>b.textContent=old,800)})}
function row(l,v){return v?`<div class="drow"><div class="dlab">${esc(l)}:</div><div class="dval">${esc(v)}</div></div>`:''}

function displayTitle(x){
  const exact={
    'Get User':'User Details','Get User By Upn':'User Details by UPN','Reset Password':'Reset User Password',
    'Delete User':'Delete User Account','Disable User':'Disable User Account','Enable User':'Enable User Account',
    'Unlock User':'Unlock User Account','Show Password Expiry':'Password Expiry',
    'Show All Authentication Methods For One User':'User Authentication Methods',
    'Show Registration Status For One User':'User MFA Registration','Recipient':'Trace Mail to Recipient','Sender':'Trace Mail from Sender'
  };
  return exact[x.name]||x.name;
}
function cardHTML(x,index){
  const [label,pill,cardclass]=safety(x);
  const related=(x.related||[]).length?row('Related',x.related.join(' · ')):'';
  const code=x.code?`<details class="showps"><summary>&gt;_ &nbsp; Show PowerShell</summary><pre>${esc(x.code)}</pre><div class="actions"><button class="btn copy-code">Copy command</button></div></details>`:'';
  const acts=(x.file||x.url)?`<div class="actions">${x.file?'<button class="btn copy-file">Copy file name</button>':''}${x.url?`<a class="btn" href="${esc(x.url)}" target="_blank" rel="noreferrer">Open reference</a>`:''}</div>`:'';
  return `<article class="card ${cardclass}"><div class="cardtop"><span class="number">${String(index+1).padStart(2,'0')}</span><span class="statuspill ${pill}">${esc(label)}</span></div><div class="cardbody"><div class="cardicon">${iconFor(x)}</div><div><h3>${esc(displayTitle(x))}</h3></div></div><div class="details">${row('Works with',x.platform)}${row('Needs',cleanNeeds(x.requires))}${row('You provide',inputFor(x))}${row('You get',x.output)}${x.file?row('File',x.file):''}${related}<div class="meta">${esc(x.type)} · ${esc(x.area)}${x.subarea?' · '+esc(x.subarea):''}${x.status!=='Ready'?' · '+esc(x.status):''}</div></div>${code}${acts}</article>`;
}
function getRows(){
  const q=document.getElementById('search').value.trim(),cat=document.getElementById('categoryFilter').value||selectedArea,platform=document.getElementById('platformFilter').value,skill=document.getElementById('skillFilter').value;
  let rows=DATA.filter(x=>{
    if(cat&&x.area!==cat)return false;if(selectedType&&x.type!==selectedType)return false;if(selectedStatus&&x.status!==selectedStatus)return false;if(platform&&x.platform!==platform)return false;if(skill&&skillFor(x)!==skill)return false;
    if(q){const tokens=norm(q).split(' ').filter(Boolean),blob=searchBlob(x);if(!tokens.every(t=>blob.includes(t)))return false}
    return true;
  });
  const sort=document.getElementById('sort').value;
  if(sort==='relevance'&&q)rows.sort((a,b)=>searchScore(b,q)-searchScore(a,q)||a._order-b._order);
  else if(sort==='name')rows.sort((a,b)=>a.name.localeCompare(b.name));
  else if(sort==='type')rows.sort((a,b)=>a.type.localeCompare(b.type)||a.name.localeCompare(b.name));
  else if(sort==='area')rows.sort((a,b)=>a.area.localeCompare(b.area)||a.name.localeCompare(b.name));
  else rows.sort((a,b)=>a._order-b._order);
  return rows;
}
function render(){
  const rows=getRows(),pages=Math.max(1,Math.ceil(rows.length/PAGE_SIZE));if(page>pages)page=pages;
  const start=(page-1)*PAGE_SIZE,shown=rows.slice(start,start+PAGE_SIZE),grid=document.getElementById('grid');
  grid.className='grid'+(view==='list'?' list':'');grid.innerHTML=shown.map((x,i)=>cardHTML(x,start+i)).join('');
  document.getElementById('resultsLine').textContent=`Showing ${rows.length?start+1:0}-${Math.min(start+PAGE_SIZE,rows.length)} of ${rows.length} results`;
  document.getElementById('empty').style.display=rows.length?'none':'block';
  grid.querySelectorAll('.card').forEach((c,i)=>{const x=shown[i],cb=c.querySelector('.copy-code'),fb=c.querySelector('.copy-file');if(cb)cb.onclick=()=>copyText(x.code,cb);if(fb)fb.onclick=()=>copyText(x.file,fb)});
  const pg=document.getElementById('pager');pg.innerHTML='';
  if(pages>1){
    const mk=(txt,disabled,fn,active=false)=>{const b=document.createElement('button');b.className='pagebtn'+(active?' active':'');b.textContent=txt;b.disabled=disabled;b.onclick=fn;pg.appendChild(b)};
    mk('‹',page===1,()=>{page--;render()});let nums=[];for(let n=1;n<=pages;n++){if(n===1||n===pages||Math.abs(n-page)<=2)nums.push(n)}
    let prev=0;nums.forEach(n=>{if(prev&&n-prev>1){const s=document.createElement('span');s.textContent='…';s.style.color='#6ea5b5';s.style.padding='5px 2px';pg.appendChild(s)}mk(n,false,()=>{page=n;render()},n===page);prev=n});mk('›',page===pages,()=>{page++;render()});
  }
}
function reset(){page=1;render()}
document.getElementById('search').addEventListener('input',reset);document.getElementById('searchBtn').onclick=reset;
document.getElementById('categoryFilter').onchange=()=>{selectedArea='';reset()};document.getElementById('platformFilter').onchange=reset;document.getElementById('skillFilter').onchange=reset;document.getElementById('sort').onchange=reset;
document.getElementById('gridView').onclick=()=>{view='grid';document.getElementById('gridView').classList.add('active');document.getElementById('listView').classList.remove('active');render()};
document.getElementById('listView').onclick=()=>{view='list';document.getElementById('listView').classList.add('active');document.getElementById('gridView').classList.remove('active');render()};
document.querySelectorAll('.navbtn').forEach(btn=>btn.onclick=()=>{document.querySelectorAll('.navbtn').forEach(b=>b.classList.remove('active'));btn.classList.add('active');selectedArea=btn.dataset.area||'';selectedType=btn.dataset.type||'';selectedStatus=btn.dataset.status||'';document.getElementById('categoryFilter').value='';reset()});
document.querySelectorAll('.chip').forEach(btn=>btn.onclick=()=>{document.getElementById('search').value=btn.dataset.q||'';selectedArea='';selectedType='';selectedStatus='';document.getElementById('categoryFilter').value='';document.querySelectorAll('.navbtn').forEach(b=>b.classList.remove('active'));document.querySelector('.navbtn[data-area=""]').classList.add('active');reset()});

function setMobileNav(area){document.querySelectorAll('.mobile-navbtn[data-mobile-area]').forEach(b=>b.classList.toggle('active',(b.dataset.mobileArea||'')===area))}
function closeMobileMenu(){document.body.classList.remove('menu-open')}
document.getElementById('mobileMenuBtn').onclick=()=>document.body.classList.toggle('menu-open');document.getElementById('mobileMoreBtn').onclick=()=>document.body.classList.add('menu-open');document.getElementById('mobileOverlay').onclick=closeMobileMenu;
document.getElementById('mobileSearchFocus').onclick=()=>{const s=document.getElementById('search');s.scrollIntoView({behavior:'smooth',block:'center'});setTimeout(()=>s.focus(),250)};
document.getElementById('mobileFilterToggle').onclick=()=>{document.querySelector('.searchband').classList.toggle('filters-open');document.getElementById('mobileFilterState').textContent=document.querySelector('.searchband').classList.contains('filters-open')?'Hide':'Show'};
document.querySelectorAll('.mobile-navbtn[data-mobile-area]').forEach(b=>b.onclick=()=>{selectedArea=b.dataset.mobileArea||'';selectedType='';selectedStatus='';document.getElementById('categoryFilter').value='';setMobileNav(selectedArea);closeMobileMenu();reset();window.scrollTo({top:0,behavior:'smooth'})});
render();
