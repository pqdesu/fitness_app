(() => {
  const out = {};
  const pick = (label, sel, pseudo) => { const e = document.querySelector(sel); if (!e) { out[label] = 'n/a'; return; } const c = getComputedStyle(e, pseudo); let bgEl = e, bg = 'rgba(0, 0, 0, 0)'; while (bgEl && (bg = getComputedStyle(bgEl).backgroundColor) === 'rgba(0, 0, 0, 0)') bgEl = bgEl.parentElement; out[label] = { color: c.color, bg, fs: c.fontSize, fw: c.fontWeight, border: c.borderTopColor + ' ' + c.borderTopWidth, opacity: c.opacity }; };
  pick('text-muted', '.text-muted'); pick('placeholder', 'input.form-control', '::placeholder'); pick('form-control', 'input.form-control');
  pick('btn-primary', '.btn-primary'); pick('btn-light', '.btn-light'); pick('btn-outline-secondary', '.btn-outline-secondary'); pick('btn-outline-danger', '.btn-outline-danger');
  pick('bottom-nav-item', '.bottom-nav-item:not(.active)'); pick('bottom-nav-active', '.bottom-nav-item.active'); pick('chip', '.chip'); pick('timer-status', '.timer-status'); pick('timer-meta', '.timer-meta');
  pick('form-check-input', '.form-check-input'); pick('app-table th', '.app-table th'); pick('badge', '.badge'); pick('eyebrow', '.eyebrow'); pick('row-link-sub', '.row-link .text-muted'); pick('link', 'main a:not(.btn)');
  pick('focus-btn-shadow', '.btn-primary', ':focus-visible');
  out.rootVars = ['--bs-secondary-color', '--bs-body-color', '--bs-tertiary-color', '--bs-link-color', '--bs-focus-ring-color', '--bs-primary'].map((v) => v + '=' + getComputedStyle(document.documentElement).getPropertyValue(v)).join(' ; ');
  out.disabledBtn = [...document.querySelectorAll('.btn:disabled, .btn.disabled')].length;
  return out;
})()
