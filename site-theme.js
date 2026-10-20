// Apply before paint; storage is optional and never blocks the catalog.
(() => {
  const key = 'field-kit-appearance';
  const valid = value => ['system','light','dark'].includes(value);
  let choice = 'system';
  try { const saved = window.localStorage.getItem(key); if (valid(saved)) choice = saved; } catch {}
  let media;
  try { media = window.matchMedia('(prefers-color-scheme: light)'); } catch {}
  const apply = () => {
    const theme = choice === 'system' ? (media?.matches ? 'light' : 'dark') : choice;
    document.documentElement.setAttribute('data-theme', theme);
    const color = document.querySelector('meta[name="theme-color"]');
    color?.setAttribute('content', theme === 'light' ? '#f4f7f3' : '#151b1e');
  };
  apply();
  const onSystemChange = () => { if (choice === 'system') apply(); };
  if (media?.addEventListener) media.addEventListener('change', onSystemChange);
  else if (media?.addListener) media.addListener(onSystemChange);
  const attach = () => {
    const control = document.getElementById('themeSelect');
    if (!control) return;
    control.value = choice;
    control.addEventListener('change', () => {
      choice = valid(control.value) ? control.value : 'system';
      try { window.localStorage.setItem(key, choice); } catch {}
      apply();
    });
    window.addEventListener('storage', event => {
      if (event.key !== key) return;
      choice = valid(event.newValue) ? event.newValue : 'system';
      control.value = choice;
      apply();
    });
  };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', attach, {once:true});
  else attach();
})();
