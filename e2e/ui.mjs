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

// Pins the layout viewport via CDP, independent of the native browser
// window (ADR 0012's requestFullscreen(), triggered by the monitor's
// "Zum Aktivieren tippen" gesture, resizes the native headless-Chrome
// window to the (tiny, display-less) default screen resolution in CI --
// --window-size alone does not survive that. screenshots.mjs already
// relies on this same override for its monitor shots; do the same here
// instead of trying to scroll elements into view (futile: CanvasKit
// paints to a single fixed-size canvas, so scrolling a flt-semantics
// overlay node desyncs its reported rect from the actually-painted
// pixels instead of truly bringing the button on-screen).
async function pinViewport(width, height) {
  await send('Emulation.setDeviceMetricsOverride', {
    width,
    height,
    deviceScaleFactor: 1,
    mobile: false,
  });
}

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
    const matches = els.filter(x => re.test((x.getAttribute('aria-label') || '') + ' ' + (x.innerText || '')));
    // Several screens have more than one element matching the same text
    // (e.g. incidents_screen.dart's app-bar "Einsatz anlegen" action vs.
    // its empty-state CTA) -- prefer one that isn't disabled.
    const e = matches.find(x => x.getAttribute('aria-disabled') !== 'true') ?? matches[0];
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
  // Polls like clickByText (the dialog this targets often hasn't finished
  // its open animation/render yet when the preceding click returns).
  const expr = `(() => {
    const e = [...document.querySelectorAll('input, textarea, flt-semantics[role=textbox], [role=textbox]')][${index}];
    if (!e) return null;
    const r = e.getBoundingClientRect();
    if (r.width === 0 && r.height === 0) return null;
    return { x: r.x + r.width / 2, y: r.y + r.height / 2 };
  })()`;
  const box = await waitFor(async () => (await evalJs(expr)) ?? undefined, 5000, 150);
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

// Always creates a fresh vehicle with a distinctive, regex-safe short_name
// so the UI critical-path step (below) can click its checkbox by text.
async function ensureNamedVehicle(token, shortName) {
  const created = await call('POST', '/vehicles', {
    token,
    body: { call_sign: `${shortName} Einsatzfahrzeug`, short_name: shortName, type: 'HLF' },
  });
  await check(created.status === 201 && !!created.json?.id, `crit-path: created vehicle ${shortName}`, created);
  return created.json;
}

// Ends any currently running BF-Tag and starts a fresh one so the UI
// critical-path step has an active, non-ended day to create an Einsatz in.
async function ensureRunningBfDay(token, namePrefix) {
  const iso = (offsetMin) => new Date(Date.now() + offsetMin * 60000).toISOString();
  const days = await call('GET', '/bf-days', { token });
  const dayList = Array.isArray(days.json) ? days.json : (days.json?.bf_days ?? days.json?.items ?? []);
  for (const d of dayList) {
    if (d.state === 'running') await call('POST', `/bf-days/${d.id}/end`, { token });
  }
  const dayRes = await call('POST', '/bf-days', {
    token,
    body: { name: `${namePrefix} ${Date.now()}`, starts_at: iso(-60), ends_at: iso(600) },
  });
  await check(dayRes.status === 201 && !!dayRes.json?.id, `crit-path: created BF-Tag (${namePrefix})`, dayRes);
  const day = dayRes.json;
  const startRes = await call('POST', `/bf-days/${day.id}/start`, { token });
  await check(startRes.status === 200, `crit-path: started BF-Tag (${namePrefix})`, startRes);
  return day;
}

const UI_CRIT_KEYWORD = `Kritischer Pfad E2E ${Date.now()}`;

// Einsätze kritischer Pfad (concept docs/design/screens/web-einsaetze.md
// §3.4, AC15-19): Einsatz anlegen (Topbar) -> Speichern -> the filter auto-
// switches to "Entwurf" and keyboard focus lands on the new card's
// Alarmieren button -> Enter opens the AlarmDialog (focus already on the
// first vehicle checkbox) -> pick a vehicle -> "Jetzt alarmieren" -> the
// alarmed incident is visible again under filter "laufend" (no manual
// filter click needed -- that is the point of the auto-switch).
// [vehicle] is created well before this runs (see main()) so its realtime
// snapshot has had the rest of the UI suite's wall-clock time to propagate
// -- opening the AlarmDialog should never race the websocket reconnect.
async function uiCriticalPathAlarm(token, vehicle) {
  await ensureRunningBfDay(token, 'UI Kritischer Pfad');

  await nav(`${BASE}/admin/einsaetze`);
  await waitForSemantics();
  // The AppBar's "Einsatz anlegen" button renders (disabled) before the
  // days list finishes loading (incidents_screen.dart's _loadDays, a REST
  // call fired from initState) -- waitForSemantics() alone is satisfied by
  // that early render. Wait for the state-dependent filter row (only shown
  // once `days` has loaded) so the click below lands once the button is
  // actually enabled, instead of racing the load on a slower CI runner.
  await waitFor(async () => {
    await enableSemantics();
    const t = await bodyText();
    return /entwurf/i.test(t) ? t : undefined;
  }, 8000, 200);
  await stepShot('crit-path-before-create');

  await check(await clickByText('^\\s*einsatz anlegen\\s*$'), 'crit-path: clicked Einsatz anlegen');
  await waitForSemantics();
  await check(await typeInto(0, UI_CRIT_KEYWORD), 'crit-path: typed Stichwort');
  await check(await typeInto(1, 'Teststr. 42'), 'crit-path: typed Adresse');
  await stepShot('crit-path-form-filled');

  await check(await clickByText('^\\s*speichern\\s*$'), 'crit-path: clicked Speichern');

  const createdText = await waitFor(async () => {
    await enableSemantics();
    const t = await bodyText();
    return t.includes(UI_CRIT_KEYWORD) ? t : undefined;
  }, 8000, 200);
  await stepShot('crit-path-after-create');
  await check(
    !!createdText,
    'crit-path: new card visible after create (filter auto-switched to Entwurf, AC15)',
    createdText?.slice(0, 300),
  );

  // AC16/AC17/AC18: keyboard focus landed on the new card's Alarmieren
  // button -- Enter opens the AlarmDialog without any click.
  await pressEnter();
  const dialogText = await waitFor(async () => {
    await enableSemantics();
    const t = await bodyText();
    return /alarmieren/i.test(t) ? t : undefined;
  }, 5000, 200);
  await stepShot('crit-path-alarm-dialog');
  await check(
    !!dialogText,
    'crit-path: AlarmDialog opened via Enter on the focused Alarmieren button (AC16/AC17/AC18)',
    dialogText?.slice(0, 300),
  );

  // The vehicle created just above arrives via the realtime snapshot, not
  // instantly -- poll for its checkbox instead of clicking immediately.
  const vehicleVisible = await waitFor(async () => {
    await enableSemantics();
    const t = await bodyText();
    return t.includes(vehicle.short_name) ? t : undefined;
  }, 15000, 200);
  await check(!!vehicleVisible, 'crit-path: vehicle checkbox appeared in the AlarmDialog', vehicleVisible?.slice(0, 300));
  await check(await clickByText(vehicle.short_name), 'crit-path: selected a vehicle checkbox');
  // Selecting a vehicle can trigger an async rebuild (double-crewed check
  // against shiftsProvider) that reflows the dialog's action row a moment
  // later -- give it time to settle before clicking the submit button so
  // the click doesn't land on a position that has since shifted.
  await sleep(300);
  await check(await clickByText('^\\s*jetzt alarmieren\\s*$'), 'crit-path: clicked Jetzt alarmieren');

  // Wait for the AlarmDialog to actually close before reading the list
  // behind it -- otherwise the dialog's own "... alarmieren" title text
  // satisfies the UI_CRIT_KEYWORD check below without the trigger having
  // taken effect yet. Retry the click once in case it missed the button.
  let dialogClosed = await waitFor(async () => {
    await enableSemantics();
    const t = await bodyText();
    return /jetzt alarmieren/i.test(t) ? undefined : true;
  }, 4000, 200);
  if (!dialogClosed) {
    await clickByText('^\\s*jetzt alarmieren\\s*$');
    dialogClosed = await waitFor(async () => {
      await enableSemantics();
      const t = await bodyText();
      return /jetzt alarmieren/i.test(t) ? undefined : true;
    }, 8000, 200);
  }
  await check(!!dialogClosed, 'crit-path: AlarmDialog closed after Jetzt alarmieren');

  const runningText = await waitFor(async () => {
    await enableSemantics();
    const t = await bodyText();
    return t.includes(UI_CRIT_KEYWORD) ? t : undefined;
  }, 8000, 200);
  await stepShot('crit-path-running');
  await check(
    !!runningText,
    'crit-path: alarmed incident still visible right after trigger, filter auto-switched (AC19)',
    runningText?.slice(0, 300),
  );

  // Strengthen the AC19 check: confirm the incident actually left the
  // Entwurf filter (not just still showing there because the dialog
  // silently failed) -- then restore the laufend tab for a clean state.
  await check(await clickByText('^\\s*entwurf\\s*$'), 'crit-path: clicked Entwurf tab to verify the incident left it');
  await sleep(500);
  const entwurfText = norm(await bodyText());
  await stepShot('crit-path-entwurf-after-trigger');
  await check(
    !entwurfText.includes(norm(UI_CRIT_KEYWORD)),
    'crit-path: alarmed incident no longer listed under Entwurf (AC19)',
    entwurfText.slice(0, 300),
  );
  await check(await clickByText('^\\s*laufend\\s*$'), 'crit-path: switched back to laufend');
  await sleep(500);
  const laufendText = await bodyText();
  await stepShot('crit-path-laufend-confirmed');
  await check(
    laufendText.includes(UI_CRIT_KEYWORD),
    'crit-path: alarmed incident visible under filter laufend (AC19)',
    laufendText.slice(0, 300),
  );
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
  // Pin the layout viewport for the whole run (see pinViewport's comment):
  // without this, the monitor's requestFullscreen() call shrinks the
  // native headless-Chrome window later in the run, well after
  // --window-size has already been applied.
  await pinViewport(1400, 900);

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

  // Create the critical-path vehicle as early as possible so its realtime
  // snapshot has the whole admin-pages loop below (several seconds of real
  // wall time) to propagate before the AlarmDialog needs it.
  const earlyToken = await apiLogin();
  await check(!!earlyToken, 'crit-path: admin API login works');
  const critPathVehicle = await ensureNamedVehicle(earlyToken, `UIKP${Date.now() % 100000}`);

  // --- the 8 admin pages ----------------------------------------------
  for (const [p, name] of ADMIN_PAGES) {
    await nav(`${BASE}${p}`);
    await waitForSemantics();
    const pathname = await evalJs('location.pathname');
    const text = await bodyText();
    await stepShot(name);
    await check(pathname === p && text.length > 0, `page ${p} renders`, { pathname, text: text.slice(0, 200) });
  }

  // --- Einsätze kritischer Pfad (concept §3.4, AC15-19) -----------------
  await uiCriticalPathAlarm(earlyToken, critPathVehicle);

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
