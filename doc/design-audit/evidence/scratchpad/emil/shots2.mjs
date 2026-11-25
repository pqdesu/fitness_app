import { start, stop, go, login, viewport, shot, evaluate, sleep } from './cdp.mjs';
const OUT = process.argv[2];
const at = (sel, idx = 0) => evaluate(`(() => { const e = document.querySelectorAll(${JSON.stringify(sel)})[${idx}]; if (!e) return false; e.scrollIntoView({block: 'start'}); window.scrollBy(0, -70); return true; })()`);
await start();
try {
  await viewport(390, 844, true);
  await login('admin@example.com');
  await go('/workout_days/14'); await at('.day-in-workout li'); await sleep(300); await shot(OUT, 'vp-workout-day-longname', false);
  await at('.day-in-workout li', 13); await sleep(300); await shot(OUT, 'vp-workout-day-bike', false);
  await go('/workout_exercises/26'); await sleep(300); await shot(OUT, 'vp-exercise-top', false);
  await at('.set-table tbody', 2); await sleep(300); await shot(OUT, 'vp-exercise-sets', false);
  await at('.set-form'); await sleep(300); await shot(OUT, 'vp-exercise-addset', false);
  await go('/workout_logs/8'); await sleep(300); await shot(OUT, 'vp-log-top', false);
  await go('/workout_logs'); await sleep(300); await shot(OUT, 'vp-history-top', false);
  await go('/'); await at('.recent-list'); await sleep(300); await shot(OUT, 'vp-home-recent', false);
  await go('/'); await at('.week-summary'); await sleep(300); await shot(OUT, 'vp-home-week', false);
  await go('/dashboard/month'); await sleep(300); await shot(OUT, 'vp-month-top', false);
  await at('.month-list', 1); await sleep(300); await shot(OUT, 'vp-month-exercises', false);
  await viewport(320, 700, true);
  await go('/workout_exercises/26'); await at('.set-table tbody', 0); await sleep(300); await shot(OUT, 'vp320-exercise-sets', false);
  await evaluate(`document.querySelector('.set-table [data-action="row-edit#edit"]').click()`); await sleep(400); await shot(OUT, 'vp320-exercise-editing', false);
  await viewport(390, 844, true);
  await go('/workout_exercises/26');
  console.log(JSON.stringify(await evaluate(`(() => { const g = (e, p) => e ? getComputedStyle(e)[p] : 'n/a'; const q = (s) => document.querySelector(s);
    const fields = [...document.querySelectorAll('input.form-control, select.form-select, textarea')].map(e => e.id + ':' + getComputedStyle(e).fontSize);
    return { fields: fields.slice(0, 12), tdAlign: g(q('.set-table tbody tr:not(.set-rest-row) td:nth-child(2)'), 'textAlign'), btnTransform: g(q('.btn-primary'), 'transition'),
      metaViewport: q('meta[name=viewport]').content, themeColor: !!q('meta[name=theme-color]'), manifest: !!q('link[rel=manifest]'), appleIcon: !!q('link[rel~=apple-touch-icon]'),
      bottomNavBg: g(q('.bottom-nav'), 'backgroundColor'), navbarPos: g(q('.app-navbar'), 'position'), h1wrap: g(q('h1'), 'textWrap'), cardRadius: g(q('.card'), 'borderRadius'), btnRadius: g(q('.btn'), 'borderRadius'), inputRadius: g(q('.form-control'), 'borderRadius'), cardShadow: g(q('.card'), 'boxShadow') }; })()`)));
} finally { stop(); }
