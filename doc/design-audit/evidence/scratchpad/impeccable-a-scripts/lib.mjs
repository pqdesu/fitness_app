import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
export const BASE = 'http://127.0.0.1:3001';
export const OUT = '/tmp/claude-1000/-home-pedro-code-pqdesu-fitness-app--claude-worktrees-opus-plan-session-e72fa6/d91907ca-cfc9-418e-acc7-1a8504a66bda/scratchpad/shots/impeccable-a';
mkdirSync(OUT, { recursive: true });
const PORT = 9341;
export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let ws, id = 0, chrome; const pending = new Map(); const waiters = [];
const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
export { send };
const once = (method) => new Promise((res) => waiters.push({ method, res }));
export const ev = async (expr) => { const r = await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true }); if (r.exceptionDetails) return 'ERR ' + JSON.stringify(r.exceptionDetails.exception?.description || r.exceptionDetails.text); return r.result?.value; };
export async function go(path) { const loaded = once('Page.loadEventFired'); await send('Page.navigate', { url: BASE + path }); await Promise.race([loaded, sleep(8000)]); await sleep(900); }
export async function viewport(w, h, mobile) { await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: mobile ? 2 : 1, mobile }); await send('Emulation.setTouchEmulationEnabled', { enabled: mobile }); }
export async function shot(name) { const r = await send('Page.captureScreenshot', { format: 'png' }); writeFileSync(join(OUT, `${name}.png`), Buffer.from(r.data, 'base64')); console.log('shot', name); }
export async function key(k, code, keyCode, shift=false) { const mod = shift ? 8 : 0; await send('Input.dispatchKeyEvent', { type: 'keyDown', key: k, code, windowsVirtualKeyCode: keyCode, modifiers: mod }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code, windowsVirtualKeyCode: keyCode, modifiers: mod }); await sleep(150); }
export const tab = (shift=false) => key('Tab', 'Tab', 9, shift);
export async function mouse(x, y) { await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await sleep(400); }
export async function start() {
  const profile = mkdtempSync(join(tmpdir(), 'impa-chrome-'));
  chrome = spawn('/usr/bin/google-chrome', ['--headless=new', `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, '--hide-scrollbars', '--no-first-run', '--disable-gpu', 'about:blank'], { stdio: 'ignore' });
  let url; for (let i = 0; i < 50; i++) { try { const r = await fetch(`http://127.0.0.1:${PORT}/json/list`); const t = (await r.json()).find((x) => x.type === 'page'); if (t) { url = t.webSocketDebuggerUrl; break; } } catch {} await sleep(200); }
  ws = new WebSocket(url);
  ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { const p = pending.get(m.id); pending.delete(m.id); m.error ? p.rej(new Error(m.error.message)) : p.res(m.result); } else if (m.method) { for (let i = waiters.length - 1; i >= 0; i--) if (waiters[i].method === m.method) { waiters[i].res(m.params); waiters.splice(i, 1); } } };
  await new Promise((r) => (ws.onopen = r));
  await send('Page.enable'); await send('Network.enable'); await send('Runtime.enable');
}
export async function login(email) { await send('Network.clearBrowserCookies'); await go('/users/sign_in'); await ev(`(() => { document.querySelector('#user_email').value='${email}'; document.querySelector('#user_password').value='auditpass123'; document.querySelector('form').requestSubmit(); })()`); await sleep(2500); }
export function stop() { ws.close(); chrome.kill(); }
