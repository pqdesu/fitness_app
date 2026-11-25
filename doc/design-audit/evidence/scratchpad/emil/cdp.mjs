// Minimal CDP driver for the audit server (port 3001), headless Chrome on port 9343.
import { spawn } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
export const BASE = 'http://127.0.0.1:3001';
const PORT = 9343;
export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let ws, id = 0; const pending = new Map(); const waiters = []; const CUR = {};
export let chrome;
export async function start() {
  const profile = mkdtempSync(join(tmpdir(), 'emil-chrome-'));
  chrome = spawn('/usr/bin/google-chrome', ['--headless=new', `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, '--hide-scrollbars', '--no-first-run', '--disable-gpu', 'about:blank'], { stdio: 'ignore' });
  let url;
  for (let i = 0; i < 50 && !url; i++) { try { const r = await fetch(`http://127.0.0.1:${PORT}/json/list`); const t = (await r.json()).find((x) => x.type === 'page'); if (t) url = t.webSocketDebuggerUrl; } catch {} await sleep(200); }
  ws = new WebSocket(url);
  ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { const p = pending.get(m.id); pending.delete(m.id); m.error ? p.rej(new Error(m.error.message)) : p.res(m.result); } else if (m.method) { for (let i = waiters.length - 1; i >= 0; i--) if (waiters[i].method === m.method) { waiters[i].res(m.params); waiters.splice(i, 1); } } };
  await new Promise((r) => (ws.onopen = r));
  await send('Page.enable'); await send('Network.enable'); await send('Runtime.enable');
}
export const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
const once = (method) => new Promise((res) => waiters.push({ method, res }));
export const evaluate = async (expr) => { const r = await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 500)); return r.result?.value; };
export async function go(path) { const loaded = once('Page.loadEventFired'); await send('Page.navigate', { url: BASE + path }); await Promise.race([loaded, sleep(8000)]); await sleep(900); }
export async function viewport(w, h, mobile) { Object.assign(CUR, { w, h, mobile, dsf: mobile ? 2 : 1 }); await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: CUR.dsf, mobile }); await send('Emulation.setTouchEmulationEnabled', { enabled: mobile }); }
export async function shot(out, name, full = true) {
  const m = await send('Page.getLayoutMetrics'); const { height } = m.cssContentSize || m.contentSize; const vp = m.cssLayoutViewport;
  const h = full ? Math.min(Math.max(height, vp.clientHeight), 7000) : vp.clientHeight;
  if (full) { await send('Emulation.setDeviceMetricsOverride', { width: vp.clientWidth, height: Math.round(h), deviceScaleFactor: CUR.dsf, mobile: CUR.mobile }); await sleep(400); }
  const r = await send('Page.captureScreenshot', { format: 'png', clip: { x: 0, y: 0, width: vp.clientWidth, height: h, scale: 1 } });
  if (full) await viewport(CUR.w, CUR.h, CUR.mobile);
  writeFileSync(join(out, `${name}.png`), Buffer.from(r.data, 'base64'));
  const overflow = await evaluate('document.documentElement.scrollWidth > window.innerWidth');
  console.log(`${name}.png ${vp.clientWidth}x${Math.round(h)}${overflow ? '  HORIZONTAL-OVERFLOW' : ''}`);
}
export async function login(email) {
  await send('Network.clearBrowserCookies'); await go('/users/sign_in');
  await evaluate(`(() => { document.querySelector('#user_email').value='${email}'; document.querySelector('#user_password').value='auditpass123'; document.querySelector('form').requestSubmit(); })()`);
  await sleep(2500);
}
// POST a form from inside the page (same origin, session cookie, CSRF token); returns the final URL and status.
export async function post(path, fields) {
  return evaluate(`(async () => { const fd = new FormData(); fd.append('authenticity_token', document.querySelector('meta[name=csrf-token]').content);
    for (const [k, v] of ${JSON.stringify(fields)}) fd.append(k, v);
    const r = await fetch('${path}', { method: 'POST', body: fd, credentials: 'same-origin' }); const t = await r.text();
    const flash = (t.match(/class="flash-text">([^<]*)/) || [])[1]; return { url: r.url, status: r.status, flash }; })()`);
}
export function stop() { try { ws.close(); } catch {} chrome.kill('SIGKILL'); }
