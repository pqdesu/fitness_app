import { start, stop, go, login, viewport, evaluate, sleep, send } from './cdp.mjs';
await start();
try {
  await viewport(390, 844, true); await login('admin@example.com'); await go('/workout_days/14');
  console.log(JSON.stringify(await evaluate(`(() => { const c = document.querySelector('.timer-clock'); const w = (t) => { c.textContent = t; return c.getBoundingClientRect().width; };
    const r = { clock: [w('1:11:11'), w('0:00:00'), w('8:48:58')] }; const n = document.querySelector('.week-summary dd, .row-title'); 
    const s = document.createElement('span'); s.style.fontFamily = 'Inter'; s.style.fontVariantNumeric='tabular-nums'; document.body.append(s); const w2 = (t) => { s.textContent = t; return s.getBoundingClientRect().width; }; r.inter = [w2('111.1'), w2('888.8')];
    r.btnActive = getComputedStyle(document.querySelector('.btn-primary')).transform; r.fonts = [...document.fonts].filter(f => f.status==='loaded').map(f => f.family + f.weight).join(',');
    r.progressBar = (() => { const d = document.createElement('div'); d.className='turbo-progress-bar'; document.body.append(d); return getComputedStyle(d).backgroundColor; })();
    return r; })()`)));
  // reduced motion probe: does collapse transition go to none?
  await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] }); await go('/');
  console.log(JSON.stringify(await evaluate(`(() => { const d = document.createElement('div'); d.className = 'collapsing'; document.body.append(d); const m = document.createElement('div'); m.className='modal fade'; m.innerHTML='<div class=modal-dialog></div>'; document.body.append(m);
    return { collapsing: getComputedStyle(d).transition, modal: getComputedStyle(m.firstChild).transition, card: getComputedStyle(document.querySelector('.card')).transition }; })()`)));
} finally { stop(); }
