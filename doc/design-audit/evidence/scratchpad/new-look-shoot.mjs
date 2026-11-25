// Screenshots the concept page with headless Chrome (CDP, port 9344).
// Usage: node new-look-shoot.mjs <dir with index.html>
import { spawn } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const DIR = process.argv[2];
const PORT = 9344;
const profile = mkdtempSync(join(tmpdir(), 'newlook-chrome-'));
const chrome = spawn('/usr/bin/google-chrome', ['--headless=new', `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`, '--hide-scrollbars', '--no-first-run', '--disable-gpu', 'about:blank'], { stdio: 'ignore' });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let ws, id = 0; const pending = new Map(); const waiters = [];
async function connect() {
  for (let i = 0; i < 50; i++) { try { const r = await fetch(`http://127.0.0.1:${PORT}/json/list`); const t = (await r.json()).find((x) => x.type === 'page'); if (t) return t.webSocketDebuggerUrl; } catch {} await sleep(200); }
  throw new Error('chrome did not start');
}
const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
const evaluate = async (expr) => (await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true })).result?.value;

async function shoot(name, w, theme, dsf = 1, clipSel = null) {
  await send('Emulation.setDeviceMetricsOverride', { width: w, height: 900, deviceScaleFactor: dsf, mobile: w < 500 && !clipSel });
  await send('Page.navigate', { url: `file://${DIR}/index.html?theme=${theme}` });
  await sleep(1500);
  await evaluate('document.fonts.ready.then(() => true)');
  const m = await send('Page.getLayoutMetrics');
  const { height } = m.cssContentSize;
  let clip = { x: 0, y: 0, width: w, height: Math.min(height, 16000), scale: 1 };
  if (clipSel) {
    const r = await evaluate(`(() => { const b = document.querySelector('${clipSel}').getBoundingClientRect(); return { x: b.x - 12, y: b.y + scrollY - 12, width: b.width + 24, height: b.height + 24 }; })()`);
    clip = { ...r, scale: 1 }; console.log(JSON.stringify(r));
  }
  await send('Emulation.setDeviceMetricsOverride', { width: w, height: Math.ceil(Math.min(height, 16000)), deviceScaleFactor: dsf, mobile: w < 500 && !clipSel });
  await sleep(400);
  const r = await send('Page.captureScreenshot', { format: 'png', clip, captureBeyondViewport: true });
  writeFileSync(join(DIR, `${name}.png`), Buffer.from(r.data, 'base64'));
  const overflow = await evaluate('document.documentElement.scrollWidth > window.innerWidth');
  const fonts = await evaluate('[...document.fonts].filter(f => f.status === "loaded").map(f => f.family + " " + f.weight).join(", ")');
  console.log(`${name}.png ${w}x${Math.round(clip.height)} ${overflow ? 'HORIZONTAL-OVERFLOW' : 'no-overflow'} fonts: ${fonts}`);
}

try {
  ws = new WebSocket(await connect());
  ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id).res(m.result || {}); pending.delete(m.id); } };
  await new Promise((r) => (ws.onopen = r));
  await send('Page.enable'); await send('Runtime.enable');
  const only = process.argv[3];
  const jobs = [
    ['shot-1440-light', 1440, 'light'], ['shot-1440-dark', 1440, 'dark'],
    ['shot-390-light', 390, 'light'], ['shot-390-dark', 390, 'dark'],
    ['frame-home-light', 1440, 'light', 2, '.screen:nth-child(1) .phone'], ['frame-workout-dark', 1440, 'dark', 2, '.screen:nth-child(2) .phone'],
    ['frame-exercise-light', 1440, 'light', 2, '.screen:nth-child(3) .phone'], ['frame-history-dark', 1440, 'dark', 2, '.screen:nth-child(4) .phone'],
    ['frame-picker-light', 1440, 'light', 2, '.screen:nth-child(5) .phone'], ['frame-picker-dark', 1440, 'dark', 2, '.screen:nth-child(5) .phone'],
    ['frame-home-dark', 1440, 'dark', 2, '.screen:nth-child(1) .phone'], ['frame-exercise-dark', 1440, 'dark', 2, '.screen:nth-child(3) .phone'],
    ['m390-ds-dark', 390, 'dark', 1, '.ds'], ['m390-head-light', 390, 'light', 2, '.page-head'], ['m390-home-light', 390, 'light', 1, '.screen:nth-child(1) .phone'],
    ['ds-light', 1440, 'light', 1, '.ds'], ['ds-dark', 1440, 'dark', 1, '.ds'],
  ];
  for (const j of jobs) if (!only || j[0].includes(only)) await shoot(...j);
} finally {
  try { ws?.close(); } catch {}
  chrome.kill('SIGKILL');
}
