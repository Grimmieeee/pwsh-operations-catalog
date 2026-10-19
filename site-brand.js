// Approved footer proportions, adapted to the navigation width.
(() => {
  const root = document.querySelector('.signature');
  if (!root) return;
  const by = root.querySelector('.signature-note');
  const row = root.querySelector('.signature-row');
  const maker = root.querySelector('.signature-mark');
  const established = root.querySelector('.signature-established');
  const context = document.createElement('canvas').getContext('2d');
  if (!context) return;
  function alignSignature() {
    if (!row.clientWidth) return;
    const family = getComputedStyle(by).fontFamily;
    context.font = `400 10px ${family}`;
    const labelWidth = context.measureText('BY').width + 2.2;
    context.font = `600 100px ${family}`;
    const size = Math.min(17, 1.08 * 100 * labelWidth / context.measureText('B').width);
    root.style.setProperty('--signature-size', `${size}px`);
    root.style.setProperty('--signature-scale', '1');
    const desired = maker.getBoundingClientRect().width + established.getBoundingClientRect().width + 12;
    const scale = Math.min(1, row.clientWidth / desired);
    root.style.setProperty('--signature-scale', String(scale));
    // Match visible glyph edges rather than different-sized font boxes.
    context.font = `400 ${10 * scale}px ${family}`;
    const smallLeft = context.measureText('B').actualBoundingBoxLeft;
    context.font = `600 ${size * scale}px ${family}`;
    const largeLeft = context.measureText('B').actualBoundingBoxLeft;
    root.style.setProperty('--by-optical-offset', `${smallLeft - largeLeft}px`);
  }
  alignSignature();
  if (document.fonts) document.fonts.ready.then(alignSignature);
  window.addEventListener('resize', alignSignature, {passive:true});
  if (typeof ResizeObserver !== 'undefined') new ResizeObserver(alignSignature).observe(row);
})();
