(async () => {
  document.querySelector('[data-bs-toggle="modal"]').click(); await new Promise((r) => setTimeout(r, 800));
  const m = document.querySelector('.modal.show'); if (!m) return 'no modal';
  const els = [...m.querySelectorAll('a[href], button, input:not([type=hidden]), select, textarea, label')].filter((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0; });
  const small = els.map((e) => { const r = e.getBoundingClientRect(); return [e.tagName + '.' + [...e.classList].slice(0, 3).join('.') + ' "' + (e.getAttribute('aria-label') || e.innerText || e.value || '').trim().replace(/\s+/g, ' ').slice(0, 30) + '"', Math.round(r.width), Math.round(r.height)]; }).filter(([, w, h]) => w < 44 || h < 44);
  const counts = {}; small.forEach(([d, w, h]) => { const k = d.replace(/"[^"]*"/, '"…"') + ' ' + w + 'x' + h; counts[k] = (counts[k] || 0) + 1; });
  return 'modal targets ' + els.length + '\n' + Object.entries(counts).map(([k, v]) => v + 'x ' + k).join('\n') + '\nfirst labels: ' + els.filter((e) => e.tagName === 'LABEL').slice(0, 3).map((e) => e.getBoundingClientRect().height).join(',') + '\ntitle: ' + (m.querySelector('.modal-title')?.innerText) + ' aria-labelledby=' + m.getAttribute('aria-labelledby') + ' role=' + m.getAttribute('role') + ' aria-modal=' + m.getAttribute('aria-modal');
})()
