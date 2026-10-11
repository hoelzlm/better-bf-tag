// Headless Chrome UI pass over the Flutter web app via CDP + Flutter semantics.
// Usage: BASE=https://localhost:18443 ADMIN_USER=.. ADMIN_PASS=.. node ui.mjs
import { createRequire } from 'node:module';
import { spawn } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
const require = createRequire('/home/markus/Developer/better-bf-tag/backend/package.json');
const WebSocket = require('ws');

const BASE = process.env.BASE;
const OUT = '/home/markus/.hermes/cache/scratch/e2e';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let pass = 0, fail = 0;
const ok = (c, n, x) => { if (c) { pass++; console.log('PASS ' + n); } else { fail++; console.log('FAIL ' + n + (x ? ' :: ' + String(x).slice(0, 300) : '')); } };

const prof = mkdtempSync(`${OUT}/chrome-`);
const chrome = spawn('google-chrome', ['--headless=new', '--no-sandbox', '--ignore-certificate-errors', '--remote-debugging-port=9333',
  `--user-data-dir=${prof}`, '--window-size=1400,900', '--autoplay-policy=no-user-gesture-required', 'about:blank'], { stdio: 'ignore' });
process.on('exit', () => chrome.kill('SIGKILL'));

let ws, id = 0; const pending = new Map();
const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending.set(i, { res, rej }); ws.send(JSON.stringify({ id: i, method, params })); });
const evalJs = async (expr) => (await send('Runtime.evaluate', { expression: expr, awaitPromise: true, returnByValue: true })).result?.value;
const shot = async (name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); writeFileSync(`${OUT}/${name}.png`, Buffer.from(r.data, 'base64')); console.log(`SHOT ${OUT}/${name}.png`); };
const nav = async (url) => { await send('Page.navigate', { url }); await sleep(4000); };
const enableSemantics = () => evalJs(`(() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) { p.click(); return true; } return false; })()`);
const labels = () => evalJs(`[...document.querySelectorAll('flt-semantics [aria-label], flt-semantics, input, textarea')].map(e => (e.getAttribute('aria-label')||e.innerText||e.placeholder||'').trim()).filter(Boolean).slice(0,200)`);
const bodyText = async () => (await labels()).join(' | ');
async function clickByLabel(re) {
  const box = await evalJs(`(() => { const re = new RegExp(${JSON.stringify(re)}, 'i'); const els = [...document.querySelectorAll('[role=button], flt-semantics[flt-tappable], button'), ...document.querySelectorAll('flt-semantics, [aria-label]')];
    const e = els.find(x => re.test((x.getAttribute('aria-label')||'') + ' ' + (x.innerText||''))); if (!e) return null; const r = e.getBoundingClientRect(); return {x: r.x + r.width/2, y: r.y + r.height/2}; })()`);
  if (!box) return false;
  for (const type of ['mousePressed', 'mouseReleased']) await send('Input.dispatchMouseEvent', { type, x: box.x, y: box.y, button: 'left', clickCount: 1 });
  await sleep(1500); return true;
}
async function typeInto(index, text) {
  const box = await evalJs(`(() => { const e = [...document.querySelectorAll('input, textarea, flt-semantics[role=textbox], [role=textbox]')][${index}]; if (!e) return null; const r = e.getBoundingClientRect(); return {x: r.x + r.width/2, y: r.y + r.height/2}; })()`);
  if (!box) return false;
  for (const type of ['mousePressed', 'mouseReleased']) await send('Input.dispatchMouseEvent', { type, x: box.x, y: box.y, button: 'left', clickCount: 1 });
  await sleep(400); await send('Input.insertText', { text }); await sleep(300); return true;
}

async function main() {
  let tabs;
  for (let i = 0; i < 30; i++) { try { tabs = await (await fetch('http://127.0.0.1:9333/json')).json(); break; } catch { await sleep(300); } }
  const page = tabs.find((t) => t.type === 'page');
  ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => ws.on('open', r));
  const consoleErrors = [];
  ws.on('message', (d) => { const m = JSON.parse(d); if (m.id && pending.has(m.id)) { pending.get(m.id).res(m.result ?? {}); pending.delete(m.id); }
    if (m.method === 'Runtime.exceptionThrown') consoleErrors.push(m.params.exceptionDetails?.exception?.description ?? m.params.exceptionDetails?.text);
    if (m.method === 'Runtime.consoleAPICalled' && m.params.type === 'error') consoleErrors.push(m.params.args.map((a) => a.value ?? a.description).join(' ')); });
  await send('Page.enable'); await send('Runtime.enable');

  // login page
  await nav(`${BASE}/admin`);
  await sleep(3000);
  ok(/\/admin\/login/.test(await evalJs('location.pathname')), 'unauthenticated /admin redirects to /admin/login', await evalJs('location.href'));
  await enableSemantics(); await sleep(1500);
  await shot('ui-01-login');
  console.log('LABELS', JSON.stringify(await labels()));
  ok(await typeInto(0, process.env.ADMIN_USER), 'typed username');
  ok(await typeInto(1, process.env.ADMIN_PASS), 'typed password');
  ok(await clickByLabel('^\\s*(anmelden|login|einloggen)'), 'clicked login button');
  await sleep(2500);
  if (/login/.test(await evalJs('location.pathname'))) { console.log('NOTE button click did not navigate, pressing Enter');
    for (const type of ['keyDown', 'keyUp']) await send('Input.dispatchKeyEvent', { type, key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 }); }
  await sleep(4000);
  await shot('ui-02-after-login');
  const path = await evalJs('location.pathname');
  ok(!/login/.test(path), 'logged in, left login page', path);
  console.log('LABELS', JSON.stringify(await labels()));

  for (const [p, name] of [['/admin/persons', 'persons'], ['/admin/fahrzeuge', 'vehicles'], ['/admin/bf-tage', 'bfdays'], ['/admin/einsaetze', 'incidents'], ['/admin/schichten', 'shifts'], ['/admin/monitors', 'monitors'], ['/admin/slides', 'slides'], ['/admin', 'lage']]) {
    await nav(`${BASE}${p}`); await enableSemantics(); await sleep(1500);
    const t = await bodyText();
    ok(await evalJs('location.pathname') === p && t.length > 0, `page ${p} renders`, t);
    console.log(`TEXT ${p}: ${t.slice(0, 400)}`);
    await shot(`ui-${name}`);
  }

  // monitor pairing page (fresh context)
  await evalJs('localStorage.clear()');
  await nav(`${BASE}/monitor`); await enableSemantics(); await sleep(1500);
  await shot('ui-monitor-activate');
  await clickByLabel('aktivieren'); await sleep(2000); await enableSemantics(); await sleep(1000);
  await shot('ui-monitor-pairing');
  console.log('TEXT /monitor: ' + (await bodyText()).slice(0, 300));
  if (process.env.MONITOR_CODE) {
    ok(await typeInto(0, process.env.MONITOR_CODE), 'typed monitor code');
    await clickByLabel('koppeln|verbinden|pair|weiter');
    await sleep(5000); await enableSemantics(); await sleep(1000);
    await shot('ui-monitor-paired');
    const t = await bodyText();
    console.log('TEXT monitor after pairing: ' + t.slice(0, 400));
    ok(!/kopplungscode/i.test(t) || /E2E/i.test(t), 'monitor left pairing screen', t);
  }
  if (process.env.ALARM_CMD) {
    const { execSync } = await import('node:child_process');
    console.log(execSync(process.env.ALARM_CMD).toString());
    await sleep(5000); await enableSemantics(); await sleep(1000);
    await shot('ui-monitor-alarm');
    const t = await bodyText();
    console.log('TEXT monitor alarm: ' + t.slice(0, 400));
    ok(/Großbrand/.test(t), 'monitor shows live alarm via websocket', t);
    ok(!/GEHEIM-DREHBUCH/.test(t), 'monitor does not show script', t);
  }
  ok(consoleErrors.length === 0, 'no JS console errors/exceptions', consoleErrors.join(' || '));
  console.log(`\nUI RESULT: ${pass} passed, ${fail} failed`);
  process.exit(fail ? 1 : 0);
}
main().catch((e) => { console.error('CRASH', e); process.exit(2); });
