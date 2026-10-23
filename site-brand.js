// Fit the live wordmark to the workspace, including after webfonts load.
(() => {
  const heading = document.querySelector('.site-heading');
  const line = document.querySelector('.title-long');
  if (!heading || !line) return;
  function fitWordmark() {
    const available = heading.clientWidth;
    if (!available) return;
    heading.style.setProperty('--hero-size', '144px');
    const width = line.getBoundingClientRect().width;
    if (width > available) {
      heading.style.setProperty('--hero-size', `${144 * available / width}px`);
    }
  }
  fitWordmark();
  if (document.fonts) document.fonts.ready.then(fitWordmark);
  window.addEventListener('resize', fitWordmark, {passive:true});
  if (typeof ResizeObserver !== 'undefined') {
    let previousWidth = heading.clientWidth;
    new ResizeObserver(() => {
      if (heading.clientWidth === previousWidth) return;
      previousWidth = heading.clientWidth;
      fitWordmark();
    }).observe(heading);
  }
})();
