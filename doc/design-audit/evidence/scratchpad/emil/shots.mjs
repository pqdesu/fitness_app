import { start, stop, go, login, viewport, shot, evaluate, sleep } from './cdp.mjs';
const OUT = process.argv[2];
await start();
try {
  await viewport(390, 844, true);
  await login('admin@example.com');
  await go('/splits/4');
  const weLink = '/workout_exercises/26';
  console.log('we', weLink);
  const pages = [['wc-workout-day', '/workout_days/14'], ['wc-log-show', '/workout_logs/8'], ['wc-exercise-page', weLink], ['wc-split-show', '/splits/4'], ['wc-splits', '/splits'],
    ['wc-history', '/workout_logs'], ['wc-home', '/'], ['wc-month', '/dashboard/month'], ['wc-log-exercise-edit', '/workout_log_exercises/21/edit'], ['wc-exercises', '/exercises']];
  for (const [n, p] of pages) { await go(p); await shot(OUT, n); }
  // states
  await go('/workout_logs/8'); await evaluate(`document.querySelectorAll('[data-bs-toggle="collapse"][aria-expanded="false"]').forEach(b => b.click())`); await sleep(700); await shot(OUT, 'wc-log-show--expanded');
  await go(weLink); await evaluate(`document.querySelector('.set-table [data-action="row-edit#edit"]').click()`); await sleep(400); await shot(OUT, 'wc-exercise-page--editing-set1', false);
  await go(weLink); await evaluate(`document.querySelector('.set-table .actions-toggle').click()`); await sleep(500); await shot(OUT, 'wc-exercise-page--actions', false);
  await go('/workout_days/14'); await evaluate(`(() => { const b = document.querySelector('.day-in-workout [data-turbo-confirm], [data-turbo-confirm]'); console.log(b); document.querySelector('form[data-turbo-confirm]')?.requestSubmit(); })()`); await sleep(700); await shot(OUT, 'wc-workout-day--confirm', false);
  // flash with a long message: submit add-set through Turbo
  await go(weLink); await evaluate(`document.querySelector('.set-form button[type=submit], .set-form button').click()`); await sleep(1800); await shot(OUT, 'wc-exercise-page--flash', false);
  // 320 px
  await viewport(320, 700, true);
  for (const [n, p] of [['wc320-workout-day', '/workout_days/14'], ['wc320-exercise-page', weLink], ['wc320-log-show', '/workout_logs/8'], ['wc320-history', '/workout_logs']]) { await go(p); await shot(OUT, n); }
  await viewport(1280, 800, false);
  for (const [n, p] of [['wcdesk-log-show', '/workout_logs/8'], ['wcdesk-exercise-page', weLink]]) { await go(p); await shot(OUT, n); }
  // probe computed styles
  await viewport(390, 844, true); await go(weLink);
  console.log(JSON.stringify(await evaluate(`(() => { const g = (s, p) => { const e = document.querySelector(s); return e ? getComputedStyle(e)[p] : 'n/a'; };
    return { tap: g('html', 'webkitTapHighlightColor'), btnTouch: g('.btn', 'touchAction'), btnSelect: g('.btn', 'userSelect'), btnTransition: g('.btn-primary', 'transition'), overscroll: g('html', 'overscrollBehaviorY'), inputFs: g('.set-form input', 'fontSize'), noteFs: g('.set-note input', 'fontSize'), bodyFs: g('body', 'fontSize'), tableNum: g('.set-table', 'fontVariantNumeric'), tdAlign: g('.set-table td:nth-child(2)', 'textAlign'), h1: g('h1', 'letterSpacing') + ' ' + g('h1','fontSize') + ' ' + g('h1','textWrap'), dropdownTransition: g('.dropdown-menu', 'transition'), modalTransition: g('.modal-dialog', 'transition') }; })()`)));
} finally { stop(); }
