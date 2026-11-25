// Assessment B: drives headless Chrome on 9342, keeps the viewport override alive while the
// impeccable detector scans each page over CDP, and measures targets/headings/labels/AX names.
import { spawn } from 'node:child_process';
import { mkdirSync, writeFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';

const BASE = 'http://127.0.0.1:3001';
const OUT = process.argv[2];
mkdirSync(join(OUT, 'det'), { recursive: true }); mkdirSync(join(OUT, 'meas'), { recursive: true }); mkdirSync(join(OUT, 'png'), { recursive: true });
const PORT = 9342;
const profile = mkdtempSync(join(OUT, 'chrome-profile-'));
const chrome = spawn('/usr/bin/google-chrome', ['--headless=new', `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, '--hide-scrollbars', '--no-first-run', '--disable-gpu', 'about:blank'], { stdio: 'ignore' });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const DET = '/home/pedro/.claude/skills/impeccable/scripts/impeccable';
const REPO = '/home/pedro/code/pqdesu/fitness_app/.claude/worktrees/opus-plan-session-e72fa6';

let ws, id = 0; const pending = new Map(); const waiters = [];
async function connect() {
  for (let i = 0; i < 50; i++) { try { const r = await fetch(`http://127.0.0.1:${PORT}/json/list`); const t = (await r.json()).find((x) => x.type === 'page'); if (t) return t.webSocketDebuggerUrl; } catch {} await sleep(200); }
  throw new Error('chrome did not start');
}
const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
const once = (method) => new Promise((res) => waiters.push({ method, res }));
const evaluate = async (expr) => (await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true })).result?.value;
async function go(path) { const loaded = once('Page.loadEventFired'); await send('Page.navigate', { url: BASE + path }); await Promise.race([loaded, sleep(8000)]); await sleep(1200); }
async function viewport(w, h, mobile) { await send('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: mobile ? 2 : 1, mobile }); await send('Emulation.setTouchEmulationEnabled', { enabled: mobile }); }
function detect(target) {
  return new Promise((res) => {
    const p = spawn(DET, ['detect', '--cdp', String(PORT), '--target', target, '--json'], { cwd: REPO });
    let out = '', err = ''; p.stdout.on('data', (d) => (out += d)); p.stderr.on('data', (d) => (err += d));
    const t = setTimeout(() => p.kill(), 180000);
    p.on('close', (code) => { clearTimeout(t); res({ code, out, err }); });
  });
}
const MEASURE = `(() => {
  const vis = (e) => { const r = e.getBoundingClientRect(); if (r.width === 0 || r.height === 0) return false; if (e.checkVisibility && !e.checkVisibility({ checkOpacity: true, checkVisibilityCSS: true })) return false; return true; };
  const desc = (e) => { const t = (e.getAttribute('aria-label') || e.innerText || e.value || e.title || '').trim().replace(/\\s+/g, ' ').slice(0, 40); return e.tagName.toLowerCase() + (e.type && e.tagName !== 'A' ? '[' + e.type + ']' : '') + (e.id ? '#' + e.id : '') + (e.className && typeof e.className === 'string' ? '.' + e.className.trim().split(/\\s+/).slice(0, 3).join('.') : '') + ' "' + t + '"'; };
  const sel = 'a[href], button, input:not([type=hidden]), select, textarea, summary, [role=button], [tabindex]:not([tabindex="-1"]), label.btn';
  const els = [...document.querySelectorAll(sel)].filter(vis);
  const items = els.map((e) => { const r = e.getBoundingClientRect(); return { e, r, d: desc(e), w: Math.round(r.width * 10) / 10, h: Math.round(r.height * 10) / 10, cx: r.left + r.width / 2, cy: r.top + r.height / 2 + scrollY, rect: { l: r.left, t: r.top + scrollY, r: r.right, b: r.bottom + scrollY } }; });
  const distToRect = (x, y, R) => { const dx = Math.max(R.l - x, 0, x - R.r); const dy = Math.max(R.t - y, 0, y - R.b); return Math.hypot(dx, dy); };
  const inline = (e) => { const p = e.parentElement; if (!p) return false; if (e.tagName !== 'A') return false; const cs = getComputedStyle(e); if (cs.display !== 'inline') return false; return (p.innerText || '').trim().length > (e.innerText || '').trim().length + 10; };
  const small = items.filter((i) => i.w < 44 || i.h < 44).map((i) => {
    const under24 = i.w < 24 || i.h < 24; let spacingOk = null;
    if (under24) { spacingOk = items.every((o) => o === i || (distToRect(i.cx, i.cy, o.rect) >= 12 && (!(o.w < 24 || o.h < 24) || Math.hypot(o.cx - i.cx, o.cy - i.cy) >= 24))); }
    return { d: i.d, w: i.w, h: i.h, under24, spacingOk, inline: inline(i.e), checkbox: i.e.type === 'checkbox' || i.e.type === 'radio' };
  });
  const headings = [...document.querySelectorAll('h1,h2,h3,h4,h5,h6,[role=heading]')].filter(vis).map((h) => h.tagName + ' ' + h.innerText.trim().replace(/\\s+/g, ' ').slice(0, 50) + ' (' + getComputedStyle(h).fontSize + ')');
  const landmarks = [...document.querySelectorAll('main,nav,header,footer,aside,[role=main],[role=navigation],[role=banner],[role=contentinfo],[role=region],section[aria-label],section[aria-labelledby]')].map((l) => l.tagName + (l.getAttribute('role') ? '[role=' + l.getAttribute('role') + ']' : '') + (l.getAttribute('aria-label') ? '[aria-label=' + l.getAttribute('aria-label') + ']' : '') + (vis(l) ? '' : ' (hidden)'));
  const inputs = [...document.querySelectorAll('input:not([type=hidden]), select, textarea')].map((e) => ({ d: desc(e), name: e.name, type: e.type, inputmode: e.getAttribute('inputmode'), autocomplete: e.getAttribute('autocomplete'), step: e.getAttribute('step'), min: e.getAttribute('min'), labels: e.labels ? e.labels.length : 0, labelText: e.labels && e.labels[0] ? e.labels[0].innerText.trim().slice(0, 30) : null, ariaLabel: e.getAttribute('aria-label'), placeholder: e.placeholder || null, visible: vis(e), fontSize: getComputedStyle(e).fontSize }));
  const fonts = [...document.fonts].filter((f) => f.status === 'loaded').map((f) => f.family + ' ' + f.weight + ' ' + f.style);
  const imgs = [...document.querySelectorAll('img, svg')].map((i) => i.tagName + ' alt=' + i.getAttribute('alt') + ' aria-hidden=' + i.getAttribute('aria-hidden') + ' ' + (i.getAttribute('src') || '').slice(0, 60));
  const overflow = document.documentElement.scrollWidth > innerWidth;
  const focusables = items.length;
  return { url: location.href, title: document.title, lang: document.documentElement.lang, total: focusables, small, headings, landmarks, inputs, fonts: [...new Set(fonts)], imgs, overflow, docHeight: document.documentElement.scrollHeight };
})()`;
async function axUnnamed() {
  const { nodes } = await send('Accessibility.getFullAXTree');
  const roles = new Set(['button', 'link', 'textbox', 'combobox', 'checkbox', 'spinbutton', 'menuitem', 'radio', 'searchbox', 'switch', 'tab', 'listbox']);
  return nodes.filter((n) => !n.ignored && roles.has(n.role?.value)).map((n) => ({ role: n.role.value, name: n.name?.value ?? '' }));
}


const [,, , PATH, W, JSFILE, SHOT] = process.argv;
import('node:fs').then(async (fs) => {
ws = new WebSocket(await connect());
ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { const p = pending.get(m.id); pending.delete(m.id); m.error ? p.rej(new Error(m.error.message)) : p.res(m.result); } else if (m.method) { for (let i = waiters.length - 1; i >= 0; i--) if (waiters[i].method === m.method) { waiters[i].res(m.params); waiters.splice(i, 1); } } };
await new Promise((r) => (ws.onopen = r));
await send('Page.enable'); await send('Runtime.enable');
try {
  const mobile = Number(W) < 800; await viewport(Number(W), mobile ? 844 : 800, mobile);
  if (!PATH.startsWith('!')) { await go('/users/sign_in');
  await evaluate(`(() => { document.querySelector('#user_email').value='admin@example.com'; document.querySelector('#user_password').value='auditpass123'; document.querySelector('form').requestSubmit(); })()`);
  await sleep(2500); }
  await go(PATH.replace(/^!/, ''));
  const rows = [];
  for (let k = 0; k < Number(JSFILE); k++) {
    await send('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9 });
    await send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Tab', code: 'Tab', windowsVirtualKeyCode: 9 });
    await sleep(60);
    rows.push(await evaluate(`(() => { const e = document.activeElement; if (!e || e === document.body) return 'body'; const c = getComputedStyle(e); const fv = e.matches(':focus-visible'); return (fv ? 'FV ' : 'nofv ') + e.tagName + '.' + [...e.classList].slice(0,3).join('.') + ' "' + (e.getAttribute('aria-label') || e.innerText || '').trim().replace(/\\s+/g,' ').slice(0,28) + '" outline=' + c.outlineStyle + ' ' + c.outlineWidth + ' ' + c.outlineColor + ' shadow=' + c.boxShadow.slice(0,70); })()`));
  }
  const v = rows.join('\n');
  console.log(typeof v === 'string' ? v : JSON.stringify(v, null, 1));
  if (SHOT) { const s = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(SHOT, Buffer.from(s.data, 'base64')); }
} catch (e) { console.error('ERR', e); } finally { ws.close(); chrome.kill('SIGKILL'); }
});
