// Screenshots every page of the audit server (port 3001) at phone and desktop width, through headless Chrome's CDP.
// Usage: node shoot.mjs <outdir>
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const BASE = 'http://127.0.0.1:3001';
const OUT = process.argv[2];
mkdirSync(OUT, { recursive: true });
const PORT = 9333;
const profile = mkdtempSync(join(tmpdir(), 'audit-chrome-'));
const chrome = spawn('/usr/bin/google-chrome', ['--headless=new', `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, '--hide-scrollbars', '--no-first-run', '--disable-gpu', 'about:blank'], { stdio: 'ignore' });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let ws, id = 0; const pending = new Map(); const waiters = [];
async function connect() {
  for (let i = 0; i < 50; i++) { try { const r = await fetch(`http://127.0.0.1:${PORT}/json/list`); const t = (await r.json()).find((x) => x.type === 'page'); if (t) return t.webSocketDebuggerUrl; } catch {} await sleep(200); }
  throw new Error('chrome did not start');
}
const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
const once = (method) => new Promise((res) => waiters.push({ method, res }));
const evaluate = async (expr) => (await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true })).result?.value;

async function go(path) {
  const loaded = once('Page.loadEventFired');
  await send('Page.navigate', { url: BASE + path });
  await Promise.race([loaded, sleep(8000)]);
  await sleep(900);
}
const CUR = {};
async function viewport(w, h, mobile) {
  Object.assign(CUR, { w, h, mobile, dsf: mobile ? 2 : 1 });
  await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: mobile ? 2 : 1, mobile });
  await send('Emulation.setTouchEmulationEnabled', { enabled: mobile });
}
async function shot(name, full = true) {
  const m = await send('Page.getLayoutMetrics');
  const { width, height } = m.cssContentSize || m.contentSize;
  const vp = m.cssLayoutViewport;
  const h = full ? Math.min(Math.max(height, vp.clientHeight), 6000) : vp.clientHeight;
  // a tall viewport keeps position:fixed bars (bottom nav) at the real bottom of a full-page shot
  if (full) { await send('Emulation.setDeviceMetricsOverride', { width: vp.clientWidth, height: Math.round(h), deviceScaleFactor: CUR.dsf, mobile: CUR.mobile }); await sleep(400); }
  const r = await send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: vp.clientWidth, height: h, scale: 1 } });
  if (full) await viewport(CUR.w, CUR.h, CUR.mobile);
  writeFileSync(join(OUT, `${name}.png`), Buffer.from(r.data, 'base64'));
  const overflow = await evaluate('document.documentElement.scrollWidth > window.innerWidth');
  console.log(`${name}.png ${vp.clientWidth}x${Math.round(h)}${overflow ? '  HORIZONTAL-OVERFLOW' : ''}`);
}
async function login(email) {
  await go('/users/sign_out'); // harmless GET if not routed; cookies are cleared below anyway
  await send('Network.clearBrowserCookies');
  await go('/users/sign_in');
  await evaluate(`(() => { document.querySelector('#user_email').value='${email}'; document.querySelector('#user_password').value='auditpass123'; document.querySelector('form').requestSubmit(); })()`);
  await sleep(2500);
}
const OPEN_COLLAPSES = `document.querySelectorAll('[data-bs-toggle="collapse"].collapsed, [data-bs-toggle="collapse"][aria-expanded="false"]').forEach((b) => b.click()); new Promise((r) => setTimeout(r, 700))`;
const CLICK = (sel) => `(() => { const e = document.querySelector('${sel}'); if (e) e.click(); return !!e; })() && new Promise((r) => setTimeout(r, 700))`;

const ADMIN_PAGES = [
  ['home', '/'], ['today-workout-lower', '/workout_days/11'], ['today-exercise-hip-thrust', '/workout_exercises/17'], ['today-exercise-todo-rdl', '/workout_exercises/19'],
  ['today-log', '/workout_logs/7'], ['past-workout-upper-mon', '/workout_days/10'], ['month', '/dashboard/month'], ['splits', '/splits'], ['split-show', '/splits/1'], ['split-new', '/splits/new'],
  ['split-edit', '/splits/1/edit'], ['workout-day-new', '/splits/1/workout_days/new'], ['workout-day-today-legs', '/workout_days/3'],
  ['workout-day-past-push', '/workout_days/1'], ['workout-day-future-upper', '/workout_days/4'], ['workout-day-edit', '/workout_days/1/edit'],
  ['exercise-page', '/workout_exercises/1'], ['history', '/workout_logs'], ['log-show-upper', '/workout_logs/1'], ['log-show-lower', '/workout_logs/2'],
  ['log-show-restday', '/workout_logs/5'], ['log-show-cardio', '/workout_logs/6'], ['log-new', '/workout_logs/new'], ['log-new-cardio', '/workout_logs/new?workout=Cardio'],
  ['timer-edit', '/workout_logs/1/timer/edit'], ['log-exercise-edit', '/workout_log_exercises/1/edit'], ['exercises', '/exercises'], ['exercise-new', '/exercises/new'],
  ['exercise-edit', '/exercises/1/edit'], ['admin-users', '/admin/users'], ['admin-equipment', '/admin/equipment'], ['admin-tags', '/admin/tags'], ['account', '/users/edit'],
];
const DESKTOP = ['home', 'today-workout-lower', 'today-exercise-hip-thrust', 'month', 'split-show', 'workout-day-today-legs', 'exercise-page', 'history', 'log-show-upper', 'exercises'];
const STATES = [ // [name, path, js]
  ['home--expanded', '/', OPEN_COLLAPSES],
  ['home--move-modal', '/', CLICK('[data-bs-target="#move-workout"]')],
  ['home--user-menu', '/', CLICK('[data-bs-toggle="dropdown"]')],
  ['workout-day-today-legs--picker', '/workout_days/3', CLICK('[data-bs-toggle="modal"]')],
  ['today-workout-lower--picker', '/workout_days/11', CLICK('[data-bs-toggle="modal"]')],
  ['today-exercise-hip-thrust--expanded', '/workout_exercises/17', OPEN_COLLAPSES],
  ['today-exercise-hip-thrust--actions-menu', '/workout_exercises/17', CLICK('.dropdown [data-bs-toggle="dropdown"]:not(.navbar *)')],
  ['split-show--picker', '/splits/1', CLICK('[data-bs-toggle="modal"]')],
  ['log-show-upper--expanded', '/workout_logs/1', OPEN_COLLAPSES],
  ['exercise-page--expanded', '/workout_exercises/1', OPEN_COLLAPSES],
  ['history--confirm', '/workout_logs', CLICK('[data-turbo-confirm]')],
];

ws = new WebSocket(await connect());
ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { const p = pending.get(m.id); pending.delete(m.id); m.error ? p.rej(new Error(m.error.message)) : p.res(m.result); } else if (m.method) { for (let i = waiters.length - 1; i >= 0; i--) if (waiters[i].method === m.method) { waiters[i].res(m.params); waiters.splice(i, 1); } } };
await new Promise((r) => (ws.onopen = r));
await send('Page.enable'); await send('Network.enable'); await send('Runtime.enable');
try {
  await viewport(390, 844, true);
  for (const [n, p] of [['signin', '/users/sign_in'], ['signup', '/users/sign_up'], ['password-new', '/users/password/new']]) { await go(p); await shot(`phone--loggedout--${n}`); }
  await login('admin@example.com');
  for (const [n, p] of ADMIN_PAGES) { await go(p); await shot(`phone--${n}`); }
  for (const [n, p, js] of STATES) { await go(p); await evaluate(js); await shot(`phone--${n}`, false); }
  await login('notadmin@example.com');
  for (const [n, p] of [['home', '/'], ['splits', '/splits'], ['history', '/workout_logs'], ['exercises', '/exercises'], ['month', '/dashboard/month'], ['account', '/users/edit']]) { await go(p); await shot(`phone--empty--${n}`); }
  await login('admin@example.com');
  await viewport(1280, 800, false);
  for (const [n, p] of ADMIN_PAGES.filter(([n]) => DESKTOP.includes(n))) { await go(p); await shot(`desktop--${n}`); }
} finally { ws.close(); chrome.kill(); }
