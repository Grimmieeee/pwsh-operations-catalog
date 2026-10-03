const RAW_DATA = window.CATALOG_DATA;
const DATA = Array.isArray(RAW_DATA)
  ? RAW_DATA
      .filter(x => x && typeof x === 'object' && typeof x.name === 'string')
      .map((x, i) => ({ ...x, _catalogIndex: i }))
  : [];

const VISIBLE_STEP = 18;
let visibleCount = VISIBLE_STEP;
let selectedArea = '';
let selectedSubarea = '';
let selectedStatus = '';

const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({
  '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;'
}[c]));

const norm = s => String(s ?? '')
  .toLowerCase()
  .replace(/can't/g, 'cannot')
  .replace(/won't/g, 'will not')
  .replace(/isn't/g, 'is not')
  .replace(/doesn't/g, 'does not')
  .replace(/don't/g, 'do not')
  .normalize('NFKD')
  .replace(/[^\w\s@.+/-]/g, ' ')
  .replace(/\s+/g, ' ')
  .trim();

function safeUrl(raw) {
  const value = String(raw || '').trim();
  if (!value || value === '#' || value === '/') return '';

  try {
    const url = new URL(value, window.location.href);

    if (url.origin === window.location.origin) {
      const current = new URL(window.location.href);
      const samePage =
        url.pathname === current.pathname &&
        !url.search &&
        !url.hash;

      return samePage ? '' : url.href;
    }

    if (url.protocol === 'https:') return url.href;
    return '';
  } catch {
    return '';
  }
}

function uniq(key) {
  return [...new Set(DATA.map(x => x[key]).filter(Boolean))].sort();
}

function addOptions(id, values) {
  const el = document.getElementById(id);
  values.forEach(value => {
    const option = document.createElement('option');
    option.value = value;
    option.textContent = value;
    el.appendChild(option);
  });
}

addOptions('typeFilter', uniq('type'));
addOptions('platformFilter', uniq('platform'));
addOptions('accessFilter', uniq('access'));

function safety(x) {
  if (x.access === 'Read-only') return ['Safe check', 'safe-pill'];
  if (x.access === 'Change') return ['Makes changes', 'change-pill'];
  if (x.access === 'Destructive') return ['Destructive', 'bad-pill'];
  if (x.type === 'Workflow' || x.type === 'Runbook') return ['Workflow', 'workflow-pill'];
  if (x.type === 'Automation') return ['Automation', 'auto-pill'];
  return [x.type || 'Info', 'tool-pill'];
}

function iconFor(x) {
  const n = norm(`${x.name} ${x.area} ${x.subarea}`);
  if (n.includes('password')) return '⌕';
  if (n.includes('mfa') || n.includes('auth')) return '◇';
  if (n.includes('mail') || n.includes('inbox') || n.includes('forward')) return '✉';
  if (n.includes('dns') || n.includes('network')) return '◎';
  if (n.includes('group')) return '◉';
  if (n.includes('printer') || n.includes('endpoint') || n.includes('computer')) return '▣';
  if (n.includes('security') || n.includes('risk') || n.includes('compromise')) return '◇';
  return '>_';
}

function inputFor(x) {
  if (x.input) return x.input;
  const c = x.code || '';
  if (/user@domain\.com/i.test(c)) return 'User UPN';
  if (/"username"/i.test(c)) return 'Username';
  if (/group@domain\.com|GROUP-OBJECT-ID|Group Name/i.test(c)) return 'Group name or ID';
  if (/server01/i.test(c)) return 'Hostname';
  if (/example\.com/i.test(c)) return 'Hostname or domain';
  if (/THUMBPRINT/i.test(c)) return 'Certificate thumbprint';
  if (/Rule Name/i.test(c)) return 'Rule name';
  if (/SEARCH-NAME/i.test(c)) return 'Search name';
  if (/1\.2\.3\.4|8\.8\.8\.8/i.test(c)) return 'IP address';
  return '';
}

function cleanNeeds(s) {
  return String(s || '')
    .replace(/^Requires:\s*/i, '')
    .replace(/\s*\|\s*Connect:.*/i, '')
    .trim();
}

function connectionFor(x) {
  const req = String(x.requires || '').trim();
  const platform = String(x.platform || '');

  const explicit = req.match(/Connect:\s*(.+?)(?=\s*\|\s*Requires:|$)/i);
  if (explicit) return explicit[1].trim();

  const importModule = req.match(/Import-Module\s+[A-Za-z0-9_.-]+/i);
  if (importModule) return importModule[0];

  if (/Connect-IPPSSession/i.test(req)) return 'Connect-IPPSSession';
  if (/Connect-ExchangeOnline/i.test(req)) return 'Connect-ExchangeOnline';
  if (/Connect-MgGraph/i.test(req)) return 'Connect-MgGraph';

  if (/Exchange Online/i.test(platform)) return 'Connect-ExchangeOnline';
  if (/Microsoft Graph|\bGraph\b/i.test(platform)) return 'Connect-MgGraph';
  if (/Active Directory/i.test(platform)) return 'Import-Module ActiveDirectory';

  return '';
}

function subareaLabel(raw) {
  return String(raw || '')
    .replace(/^Active Directory - /i, 'AD · ')
    .replace(/^Exchange Online - /i, 'EXO · ')
    .replace(/^Local Windows - /i, 'Windows · ')
    .replace(/^Graph - /i, 'Graph · ')
    .replace(/^RMM /i, 'RMM · ');
}

function searchBlob(x) {
  return norm([
    x.name, x.type, x.area, x.subarea, x.platform, x.access, x.status,
    x.file, x.notes, x.keywords, x.source, (x.related || []).join(' '), x.code
  ].join(' '));
}

function searchScore(x, q) {
  if (!q) return 0;
  const nq = norm(q);
  const tokens = nq.split(' ').filter(Boolean);
  const name = norm(x.name);
  const keys = norm(x.keywords);
  const area = norm(`${x.area} ${x.subarea}`);
  const file = norm(x.file);
  const blob = searchBlob(x);

  let score = 0;
  if (name === nq) score += 180;
  if (name.startsWith(nq)) score += 120;
  if (name.includes(nq)) score += 90;
  if (keys.includes(nq)) score += 70;
  if (area.includes(nq)) score += 45;
  if (file.includes(nq)) score += 35;

  for (const token of tokens) {
    if (name.includes(token)) score += 30;
    else if (keys.includes(token)) score += 22;
    else if (area.includes(token)) score += 14;
    else if (file.includes(token)) score += 10;
    else if (blob.includes(token)) score += 5;
  }

  if (x.status === 'Ready') score += 4;
  if (x.type === 'Quick Command') score += 2;
  return score;
}

function searchTokens(q) {
  const stop = new Set(['a','an','and','are','for','i','in','is','it','me','my','of','on','the','to','with']);
  return norm(q).split(' ').filter(token => token && !stop.has(token));
}

function searchableWords(x) {
  return norm([
    x.name, x.type, x.area, x.subarea, x.platform, x.access, x.status,
    x.file, x.notes, x.keywords, x.source, (x.related || []).join(' ')
  ].join(' ')).split(' ').filter(Boolean);
}

function searchMatches(x, q) {
  const tokens = searchTokens(q);
  if (!tokens.length) return true;

  const words = searchableWords(x);
  const matched = tokens.filter(token =>
    words.some(word => word === token || word.startsWith(token))
  ).length;

  const minimum = tokens.length <= 2 ? 1 : Math.ceil(tokens.length * 0.6);
  return matched >= minimum;
}

function displayTitle(x) {
  const exact = {
    'Get User': 'User Details',
    'Get User By Upn': 'User Details by UPN',
    'Reset Password': 'Reset User Password',
    'Delete User': 'Delete User Account',
    'Disable User': 'Disable User Account',
    'Enable User': 'Enable User Account',
    'Unlock User': 'Unlock User Account',
    'Show Password Expiry': 'Password Expiry',
    'Show All Authentication Methods For One User': 'User Authentication Methods',
    'Show Registration Status For One User': 'User MFA Registration',
    'Recipient': 'Trace Mail to Recipient',
    'Sender': 'Trace Mail from Sender'
  };
  return exact[x.name] || x.name;
}

function row(label, value) {
  return value
    ? `<div class="detail-row"><div class="detail-label">${esc(label)}</div><div class="detail-value">${esc(value)}</div></div>`
    : '';
}

function resultHTML(x) {
  const [label, pill] = safety(x);
  return `
    <article class="result-row">
      <button class="result-open" type="button" data-open-index="${x._catalogIndex}">
        <div class="fix-cell">
          <div class="result-icon">${esc(iconFor(x))}</div>
          <div class="fix-copy">
            <h2>${esc(displayTitle(x))}</h2>
            <div class="fix-sub">${esc(subareaLabel(x.subarea || x.area))}</div>
          </div>
        </div>
        <div class="result-col environment-col">${esc(x.platform || 'PowerShell')}</div>
        <div class="result-col type-col">${esc(x.type || '')}</div>
        <div class="result-col safety-col"><span class="statuspill ${pill}">${esc(label)}</span></div>
        <div class="result-arrow" aria-hidden="true">›</div>
      </button>
    </article>`;
}

function getRows() {
  const q = document.getElementById('search').value.trim();
  const type = document.getElementById('typeFilter').value;
  const platform = document.getElementById('platformFilter').value;
  const access = document.getElementById('accessFilter').value;

  let rows = DATA.filter(x => {
    if (selectedArea && x.area !== selectedArea) return false;
    if (selectedSubarea && x.subarea !== selectedSubarea) return false;
    if (selectedStatus && x.status !== selectedStatus) return false;
    if (type && x.type !== type) return false;
    if (platform && x.platform !== platform) return false;
    if (access && x.access !== access) return false;
    return searchMatches(x, q);
  });

  const sort = document.getElementById('sort').value;
  if (sort === 'relevance' && q) {
    rows.sort((a, b) => searchScore(b, q) - searchScore(a, q) || a._order - b._order);
  } else if (sort === 'name') {
    rows.sort((a, b) => a.name.localeCompare(b.name));
  } else if (sort === 'type') {
    rows.sort((a, b) => a.type.localeCompare(b.type) || a.name.localeCompare(b.name));
  } else if (sort === 'area') {
    rows.sort((a, b) => a.area.localeCompare(b.area) || a.name.localeCompare(b.name));
  } else {
    rows.sort((a, b) => a._order - b._order);
  }

  return rows;
}

function contextText() {
  if (selectedStatus === 'Candidate') return 'Ideas to Add';
  if (selectedSubarea) return subareaLabel(selectedSubarea);
  if (selectedArea) return selectedArea;
  return 'Everything';
}

function renderCounts() {
  document.getElementById('catalogCount').textContent = `${DATA.length} entries`;
  document.querySelectorAll('[data-count-area]').forEach(el => {
    const area = el.dataset.countArea || '';
    el.textContent = area ? DATA.filter(x => x.area === area).length : DATA.length;
  });
  document.querySelectorAll('[data-count-status]').forEach(el => {
    el.textContent = DATA.filter(x => x.status === el.dataset.countStatus).length;
  });
}

function renderSubareas() {
  const section = document.getElementById('subareaSection');
  const nav = document.getElementById('subareaNav');

  if (!selectedArea || selectedStatus) {
    section.classList.add('hidden');
    nav.innerHTML = '';
    return;
  }

  const counts = new Map();
  DATA.filter(x => x.area === selectedArea && x.subarea).forEach(x => {
    counts.set(x.subarea, (counts.get(x.subarea) || 0) + 1);
  });

  const items = [...counts.entries()].sort((a, b) =>
    b[1] - a[1] || subareaLabel(a[0]).localeCompare(subareaLabel(b[0]))
  );

  nav.innerHTML = [
    `<button class="subnavbtn ${selectedSubarea ? '' : 'active'}" data-subarea=""><span>All ${esc(selectedArea)}</span><span>${DATA.filter(x => x.area === selectedArea).length}</span></button>`,
    ...items.map(([raw, count]) =>
      `<button class="subnavbtn ${selectedSubarea === raw ? 'active' : ''}" data-subarea="${esc(raw)}"><span>${esc(subareaLabel(raw))}</span><span>${count}</span></button>`
    )
  ].join('');

  nav.querySelectorAll('[data-subarea]').forEach(btn => {
    btn.onclick = () => {
      selectedSubarea = btn.dataset.subarea || '';
      visibleCount = VISIBLE_STEP;
      renderSubareas();
      render();
    };
  });

  section.classList.remove('hidden');
}

function render() {
  const rows = getRows();
  const shown = rows.slice(0, visibleCount);
  const list = document.getElementById('resultsList');
  const context = contextText();

  list.innerHTML = shown.map(resultHTML).join('');
  document.getElementById('contextLine').textContent = context;
  document.getElementById('currentAreaLabel').textContent = context.toUpperCase();
  document.getElementById('resultsLine').textContent =
    rows.length ? `Showing ${shown.length} of ${rows.length} results` : '0 results';

  document.getElementById('empty').classList.toggle('hidden', rows.length > 0);
  document.getElementById('loadMore').classList.toggle('hidden', shown.length >= rows.length);
  document.getElementById('clearSearch').classList.toggle(
    'hidden',
    !document.getElementById('search').value
  );

  list.querySelectorAll('[data-open-index]').forEach(btn => {
    btn.onclick = () => openDrawer(Number(btn.dataset.openIndex));
  });
}

function resetResults() {
  visibleCount = VISIBLE_STEP;
  render();
}

function copyText(text, button) {
  navigator.clipboard.writeText(text).then(() => {
    const old = button.textContent;
    button.textContent = 'Copied';
    setTimeout(() => { button.textContent = old; }, 900);
  });
}

function openDrawer(index) {
  const x = DATA[index];
  if (!x) return;

  const [label, pill] = safety(x);
  const safeRef = safeUrl(x.url);
  const related = (x.related || []).length ? row('Related', x.related.join(' · ')) : '';
  const code = x.code
    ? `<div class="drawer-section">
         <div class="drawer-section-label">POWERSHELL</div>
         <pre class="drawer-code">${esc(x.code)}</pre>
         <button class="drawer-action copy-code" type="button">Copy command</button>
       </div>`
    : '';

  document.getElementById('drawerContent').innerHTML = `
    <div class="drawer-heading">
      <div class="drawer-icon">${esc(iconFor(x))}</div>
      <div>
        <span class="statuspill ${pill}">${esc(label)}</span>
        <h2>${esc(displayTitle(x))}</h2>
        <div class="drawer-meta">${esc(x.type)} · ${esc(x.area)}${x.subarea ? ` · ${esc(subareaLabel(x.subarea))}` : ''}</div>
      </div>
    </div>

    ${x.notes ? `<p class="drawer-summary">${esc(x.notes)}</p>` : ''}

    <div class="drawer-details">
      ${row('Works with', x.platform)}
      ${row('Connect', connectionFor(x))}
      ${row('You provide', inputFor(x))}
      ${row('You get', x.output)}
      ${x.file ? row('File', x.file) : ''}
      ${related}
    </div>

    ${code}

    ${(x.file || safeRef) ? `
      <div class="drawer-actions">
        ${x.file ? '<button class="drawer-action copy-file" type="button">Copy file name</button>' : ''}
        ${safeRef ? `<a class="drawer-action" href="${esc(safeRef)}" target="_blank" rel="noopener noreferrer">Open reference ↗</a>` : ''}
      </div>` : ''}
  `;

  const drawerContent = document.getElementById('drawerContent');
  const copyCode = drawerContent.querySelector('.copy-code');
  const copyFile = drawerContent.querySelector('.copy-file');
  if (copyCode) copyCode.onclick = () => copyText(x.code, copyCode);
  if (copyFile) copyFile.onclick = () => copyText(x.file, copyFile);

  document.body.classList.add('drawer-open');
  document.getElementById('detailDrawer').setAttribute('aria-hidden', 'false');
}

function closeDrawer() {
  document.body.classList.remove('drawer-open');
  document.getElementById('detailDrawer').setAttribute('aria-hidden', 'true');
}

function setActiveNav(target) {
  document.querySelectorAll('.navbtn').forEach(btn => btn.classList.remove('active'));
  if (target) target.classList.add('active');
}

function selectArea(area, sourceButton = null) {
  selectedArea = area || '';
  selectedSubarea = '';
  selectedStatus = '';
  const target = sourceButton || [...document.querySelectorAll('.navbtn[data-area]')]
    .find(btn => (btn.dataset.area || '') === selectedArea);
  setActiveNav(target);
  setMobileNav(selectedArea);
  renderSubareas();
  closeMobileMenu();
  resetResults();
}

function clearAll() {
  selectedArea = '';
  selectedSubarea = '';
  selectedStatus = '';
  document.getElementById('search').value = '';
  document.getElementById('typeFilter').value = '';
  document.getElementById('platformFilter').value = '';
  document.getElementById('accessFilter').value = '';
  document.getElementById('sort').value = 'relevance';
  setActiveNav(document.querySelector('.navbtn[data-area=""]'));
  setMobileNav('');
  renderSubareas();
  resetResults();
}

function setMobileNav(area) {
  document.querySelectorAll('.mobile-navbtn[data-mobile-area]').forEach(btn => {
    btn.classList.toggle('active', (btn.dataset.mobileArea || '') === area);
  });
}

function closeMobileMenu() {
  document.body.classList.remove('menu-open');
}

document.getElementById('search').addEventListener('input', resetResults);
document.getElementById('clearSearch').onclick = () => {
  document.getElementById('search').value = '';
  document.getElementById('search').focus();
  resetResults();
};

['typeFilter', 'platformFilter', 'accessFilter', 'sort'].forEach(id => {
  document.getElementById(id).onchange = resetResults;
});

document.getElementById('resetFilters').onclick = clearAll;

document.querySelectorAll('.navbtn[data-area]').forEach(btn => {
  btn.onclick = () => selectArea(btn.dataset.area || '', btn);
});

document.querySelectorAll('.navbtn[data-status]').forEach(btn => {
  btn.onclick = () => {
    selectedArea = '';
    selectedSubarea = '';
    selectedStatus = btn.dataset.status || '';
    setActiveNav(btn);
    setMobileNav('');
    renderSubareas();
    closeMobileMenu();
    resetResults();
  };
});

document.querySelectorAll('.chip').forEach(btn => {
  btn.onclick = () => {
    document.getElementById('search').value = btn.dataset.q || '';
    selectedArea = '';
    selectedSubarea = '';
    selectedStatus = '';
    setActiveNav(document.querySelector('.navbtn[data-area=""]'));
    setMobileNav('');
    renderSubareas();
    resetResults();
  };
});

document.getElementById('loadMore').onclick = () => {
  visibleCount += VISIBLE_STEP;
  render();
};

document.getElementById('closeDrawer').onclick = closeDrawer;
document.getElementById('drawerOverlay').onclick = closeDrawer;

document.getElementById('mobileMenuBtn').onclick = () => {
  document.body.classList.toggle('menu-open');
};
document.getElementById('mobileMoreBtn').onclick = () => {
  document.body.classList.add('menu-open');
};
document.getElementById('mobileOverlay').onclick = closeMobileMenu;

document.getElementById('mobileFilterToggle').onclick = () => {
  document.querySelector('.search-zone').classList.toggle('filters-open');
  document.getElementById('mobileFilterState').textContent =
    document.querySelector('.search-zone').classList.contains('filters-open') ? 'Hide' : 'Show';
};

document.querySelectorAll('.mobile-navbtn[data-mobile-area]').forEach(btn => {
  btn.onclick = () => {
    selectArea(btn.dataset.mobileArea || '');
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };
});

document.addEventListener('keydown', event => {
  if (event.key === 'Escape') {
    closeDrawer();
    closeMobileMenu();
  }
});

renderCounts();
renderSubareas();
render();
