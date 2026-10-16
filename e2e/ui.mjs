// e2e/ui.mjs — headless Chrome (CDP) pass over the Flutter web app.
// Usage: E2E_BASE=https://localhost:28443 E2E_ADMIN_USER=.. E2E_ADMIN_PASS=.. node ui.mjs
//
// Env (also see lib.mjs):
//   CHROME_BIN   path to a Chrome/Chromium binary (default "google-chrome")
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { ok, call, summary, ARTIFACT_DIR, BASE, ADMIN_USER, ADMIN_PASS, createCdpSession } from './lib.mjs';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Lowercase + ß->ss normalization so "GROSSBRAND" (monitor, uppercase) and
// "Großbrand" (API input) compare equal regardless of case/eszett.
const norm = (s) => (s ?? '').toLowerCase().replace(/ß/g, 'ss');

process.on('SIGINT', () => process.exit(130));
process.on('SIGTERM', () => process.exit(143));

const cdpSession = createCdpSession({ windowSize: '1400,900' });
const { send, evalJs, waitFor, nav, enableSemantics } = cdpSession;
const consoleErrors = cdpSession.consoleErrors;
let failCount = 0;
let stepCount = 0;

async function shot(name) {
  const r = await send('Page.captureScreenshot', { format: 'png' });
  const file = path.join(ARTIFACT_DIR, `${name}.png`);
  writeFileSync(file, Buffer.from(r.data, 'base64'));
  console.log(`SHOT ${file}`);
  return file;
}

async function stepShot(label) {
  stepCount++;
  try {
    await shot(`ui-${String(stepCount).padStart(2, '0')}-${label}`);
  } catch (e) {
    console.log(`NOTE step screenshot failed: ${e.message}`);
  }
}

function slugify(s) {
  return s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
}

async function failShot(label) {
  failCount++;
  try {
    await shot(`ui-fail-${failCount}-${slugify(label)}`);
  } catch (e) {
    console.log(`NOTE failure screenshot failed: ${e.message}`);
  }
}

// Wraps lib.mjs's ok() with an automatic failure screenshot.
async function check(cond, name, extra) {
  const result = ok(cond, name, extra);
  if (!result) await failShot(name);
  return result;
}

const labels = () =>
  evalJs(
    `[...document.querySelectorAll('flt-semantics [aria-label], flt-semantics, input, textarea')]
      .map(e => (e.getAttribute('aria-label') || e.innerText || e.placeholder || '').trim())
      .filter(Boolean).slice(0, 300)`,
  );

const bodyText = async () => (await labels()).join(' | ');

// Flutter semantics (and the underlying DOM) build up asynchronously after
// a click/navigation; poll instead of a fixed sleep.
async function waitForSemantics(timeoutMs = 8000) {
  return waitFor(async () => {
    await enableSemantics();
    const t = await bodyText();
    return t.length > 0 ? t : undefined;
  }, timeoutMs, 200);
}

// Searches [role=button] first (per ADR 0023: the "Anmelden" heading has
// the same label as the login button), falling back to any semantics node.
async function clickByText(re) {
  const exprFor = (selector) => `(() => {
    const re = new RegExp(${JSON.stringify(re)}, 'i');
    const els = [...document.querySelectorAll(${JSON.stringify(selector)})];
    const e = els.find(x => re.test((x.getAttribute('aria-label') || '') + ' ' + (x.innerText || '')));
    if (!e) return null;
    const r = e.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) return null;
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  })()`;
  const box = await waitFor(
    async () => (await evalJs(exprFor('[role=button]'))) ?? (await evalJs(exprFor('flt-semantics, [aria-label]'))),
    5000,
    150,
  );
  if (!box) return false;
  for (const type of ['mousePressed', 'mouseReleased']) {
    await send('Input.dispatchMouseEvent', { type, x: box.x, y: box.y, button: 'left', clickCount: 1 });
  }
  return true;
}

async function typeInto(index, text) {
  const box = await evalJs(`(() => {
    const e = [...document.querySelectorAll('input, textarea, flt-semantics[role=textbox], [role=textbox]')][${index}];
    if (!e) return null;
    const r = e.getBoundingClientRect();
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  })()`);
  if (!box) return false;
  for (const type of ['mousePressed', 'mouseReleased']) {
    await send('Input.dispatchMouseEvent', { type, x: box.x, y: box.y, button: 'left', clickCount: 1 });
  }
  await sleep(200);
  await send('Input.insertText', { text });
  return true;
}

async function pressEnter() {
  for (const type of ['keyDown', 'keyUp']) {
    await send('Input.dispatchKeyEvent', { type, key: 'Enter', code: 'Enter', windowsVirtualKeyCode: 13 });
  }
}

const ADMIN_PAGES = [
  ['/admin/persons', 'persons'],
  ['/admin/fahrzeuge', 'vehicles'],
  ['/admin/bf-tage', 'bfdays'],
  ['/admin/einsaetze', 'incidents'],
  ['/admin/schichten', 'shifts'],
  ['/admin/monitors', 'monitors'],
  ['/admin/slides', 'slides'],
  ['/admin', 'lage'],
];

const KEYWORD = 'B3 Großbrand Lagerhalle';
const SCRIPT = 'GEHEIM-DREHBUCH';

async function apiLogin() {
  const r = await call('POST', '/auth/login', { body: { username: ADMIN_USER, password: ADMIN_PASS } });
  return r.json?.access_token;
}

async function ensureVehicle(token) {
  const list = await call('GET', '/vehicles', { token });
  const vehicles = Array.isArray(list.json) ? list.json : (list.json?.vehicles ?? list.json?.items ?? []);
  if (vehicles.length > 0) return vehicles[0].id;
  const created = await call('POST', '/vehicles', {
    token,
    body: { call_sign: `UI E2E ${Date.now()}`, short_name: 'UI-E2E', type: 'HLF' },
  });
  return created.json?.id;
}

async function triggerUiAlarm(token) {
  const iso = (offsetMin) => new Date(Date.now() + offsetMin * 60000).toISOString();

  const vehicleId = await ensureVehicle(token);
  await check(!!vehicleId, 'have a vehicle for the UI alarm');

  const days = await call('GET', '/bf-days', { token });
  const dayList = Array.isArray(days.json) ? days.json : (days.json?.bf_days ?? days.json?.items ?? []);
  for (const d of dayList) {
    if (d.state === 'running') await call('POST', `/bf-days/${d.id}/end`, { token });
  }

  const dayRes = await call('POST', '/bf-days', {
    token,
    body: { name: `UI E2E ${Date.now()}`, starts_at: iso(-60), ends_at: iso(600) },
  });
  await check(dayRes.status === 201 && !!dayRes.json?.id, 'created BF-Tag for the UI alarm', dayRes);
  const day = dayRes.json;

  const startRes = await call('POST', `/bf-days/${day.id}/start`, { token });
  await check(startRes.status === 200, 'started BF-Tag', startRes);

  const incRes = await call('POST', `/bf-days/${day.id}/incidents`, {
    token,
    body: { keyword: KEYWORD, address: 'Industriestr. 7', report: 'Starke Rauchentwicklung', script: SCRIPT },
  });
  await check(incRes.status === 201 && !!incRes.json?.id, 'created incident with keyword', incRes);

  const alarmRes = await call('POST', `/incidents/${incRes.json.id}/alarms`, {
    token,
    body: { vehicle_ids: [vehicleId] },
  });
  await check([200, 201].includes(alarmRes.status), 'triggered alarm for vehicle', alarmRes);
}

async function main() {
  const port = await cdpSession.start();
  await cdpSession.connect(port);

  // --- login ---------------------------------------------------------
  await nav(`${BASE}/admin/login`);
  await waitForSemantics();
  await stepShot('login');
  await check((await evalJs('location.pathname')) === '/admin/login', 'nav to /admin/login shows login page', await evalJs('location.href'));

  await check(await typeInto(0, ADMIN_USER), 'typed admin username');
  await check(await typeInto(1, ADMIN_PASS), 'typed admin password');
  await check(await clickByText('^\\s*(anmelden|login|einloggen)\\s*$'), 'clicked login button');

  let loggedInPath = await waitFor(async () => {
    const p = await evalJs('location.pathname');
    return !/login/.test(p) ? p : undefined;
  }, 5000, 200);
  if (!loggedInPath) {
    console.log('NOTE login click did not navigate yet, retrying with Enter');
    await pressEnter();
    loggedInPath = await waitFor(async () => {
      const p = await evalJs('location.pathname');
      return !/login/.test(p) ? p : undefined;
    }, 6000, 200);
  }
  await waitForSemantics();
  await stepShot('after-login');
  await check(!!loggedInPath && !/login/.test(loggedInPath), 'logged in, left login page', loggedInPath);

  // --- the 8 admin pages ----------------------------------------------
  for (const [p, name] of ADMIN_PAGES) {
    await nav(`${BASE}${p}`);
    await waitForSemantics();
    const pathname = await evalJs('location.pathname');
    const text = await bodyText();
    await stepShot(name);
    await check(pathname === p && text.length > 0, `page ${p} renders`, { pathname, text: text.slice(0, 200) });
  }

  // --- monitor pairing (fresh browser context) -------------------------
  await evalJs('localStorage.clear()');
  await nav(`${BASE}/monitor`);
  await waitForSemantics();
  await check(await clickByText('aktivieren'), 'clicked monitor activation overlay');
  await waitForSemantics();
  await stepShot('monitor-pairing-screen');
  const pairingText = await bodyText();
  await check(/koppeln/i.test(pairingText), 'monitor shows pairing screen', pairingText.slice(0, 300));

  const adminToken = await apiLogin();
  await check(!!adminToken, 'admin API login works');

  const monRes = await call('POST', '/monitors', { token: adminToken, body: { name: `UI E2E Monitor ${Date.now()}` } });
  await check(monRes.status === 201 && !!monRes.json?.id, 'created monitor via admin API', monRes);
  const codeRes = await call('POST', `/monitors/${monRes.json.id}/pairing-code`, { token: adminToken });
  await check([200, 201].includes(codeRes.status) && !!codeRes.json?.code, 'generated pairing code via admin API', codeRes);

  await check(await typeInto(0, codeRes.json.code), 'typed pairing code on monitor screen');
  await check(await clickByText('koppeln'), 'clicked Koppeln button');

  const pairedText = await waitFor(async () => {
    await enableSemantics();
    const t = norm(await bodyText());
    return !t.includes('koppeln') ? t : undefined;
  }, 10000, 300);
  await stepShot('monitor-paired');
  await check(!!pairedText && !pairedText.includes('koppeln'), 'monitor left pairing screen', pairedText?.slice(0, 300));

  // --- live alarm on the monitor, triggered via the API -----------------
  await triggerUiAlarm(adminToken);

  const alarmText = await waitFor(async () => {
    await enableSemantics();
    const t = norm(await bodyText());
    return t.includes('grossbrand') ? t : undefined;
  }, 15000, 300);
  await stepShot('monitor-alarm');
  const finalText = norm(alarmText ?? (await bodyText()));
  await check(finalText.includes('grossbrand'), 'monitor shows live alarm keyword (normalized)', finalText.slice(0, 400));
  await check(!finalText.includes(norm(SCRIPT)), 'monitor does not show the script', finalText.slice(0, 400));

  await check(consoleErrors.length === 0, 'no uncaught JS exceptions', consoleErrors.join(' || '));

  const exitCode = summary('UI');
  process.exit(exitCode);
}

main().catch(async (e) => {
  console.error('CRASH', e);
  try {
    await failShot('crash');
  } catch {
    // best effort
  }
  process.exit(2);
});
