// e2e/screenshots.mjs — Web + Monitor screenshots for the design-review
// harness (`just screenshots dir=...`, see justfile and docs/testing/README.md).
//
// Reuses the e2e stack (ADR 0023): run against the same compose stack as
// api.mjs/ui.mjs via e2e/run.sh with E2E_MODE=screenshots. Seeds its own
// deterministic example data via the API (lib.mjs's call()/must()), then
// drives headless Chrome over CDP (lib.mjs's createCdpSession) to capture
// PNGs into SCREENSHOT_DIR/{web,monitor}/<screen>[-<state>]-<W>x<H>.png.
//
// The mobile (app/) screenshots are NOT produced here — see
// apps/mobile/screenshot_test/ and the justfile `screenshots` recipe.
import { writeFileSync } from 'node:fs';
import path from 'node:path';
import { call, must, ok, summary, BASE, ADMIN_USER, ADMIN_PASS, createCdpSession } from './lib.mjs';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const SCREENSHOT_DIR = process.env.SCREENSHOT_DIR
  ? path.resolve(process.env.SCREENSHOT_DIR)
  : path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'docs', 'design', 'screenshots', 'before');
const WEB_DIR = path.join(SCREENSHOT_DIR, 'web');
const MONITOR_DIR = path.join(SCREENSHOT_DIR, 'monitor');

const cdpSession = createCdpSession({ windowSize: '1440,900' });
const { send, evalJs, waitFor, nav, enableSemantics } = cdpSession;

process.on('SIGINT', () => process.exit(130));
process.on('SIGTERM', () => process.exit(143));

async function setViewport(width, height) {
  await send('Emulation.setDeviceMetricsOverride', {
    width,
    height,
    deviceScaleFactor: 1,
    mobile: false,
  });
}

async function shot(dir, name, width, height) {
  const r = await send('Page.captureScreenshot', { format: 'png' });
  const file = path.join(dir, `${name}-${width}x${height}.png`);
  writeFileSync(file, Buffer.from(r.data, 'base64'));
  console.log(`SHOT ${file}`);
  return file;
}

const labels = () =>
  evalJs(
    `[...document.querySelectorAll('flt-semantics [aria-label], flt-semantics, input, textarea')]
      .map(e => (e.getAttribute('aria-label') || e.innerText || e.placeholder || '').trim())
      .filter(Boolean).slice(0, 300)`,
  );
const bodyText = async () => (await labels()).join(' | ');

async function waitForSemantics(timeoutMs = 8000) {
  return waitFor(async () => {
    await enableSemantics();
    const t = await bodyText();
    return t.length > 0 ? t : undefined;
  }, timeoutMs, 200);
}

// Let a freshly rendered/navigated page settle (Flutter layout, fonts,
// map tiles if online) before capturing. A short fixed delay, per ADR
// 0023/this harness's spec: polling isn't reliable across every screen
// (clock text always changes), a fixed delay is acceptable here.
async function settle(ms = 900) {
  await sleep(ms);
}

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

// --- 1. seed deterministic example data via the API ----------------------

const tag = 'screenshots';
const iso = (offsetMin) => new Date(Date.now() + offsetMin * 60000).toISOString();

async function seed() {
  const login = await must('POST', '/auth/login', { body: { username: ADMIN_USER, password: ADMIN_PASS } });
  const admin = login.json.access_token;
  ok(!!admin, 'screenshots: admin login works');

  // Personen mit mehreren Personentypen.
  const mk = async (display_name, permission, person_type) =>
    (await must('POST', '/persons', { token: admin, body: { display_name, person_type, permission } }, 201)).json;
  const disp = await mk(`Leitstelle ${tag}`, 'dispatch', 'supervisor');
  const prep = await mk(`Vorbereitung ${tag}`, 'preparation', 'supervisor');
  const crewA = await mk(`Anna Jugend ${tag}`, 'crew', 'youth');
  const crewB = await mk(`Ben Jugend ${tag}`, 'crew', 'youth');
  const crewC = await mk(`Clara Betreuer ${tag}`, 'crew', 'supervisor');
  const pw = `pw-${tag}-0123456789`;
  await must('PUT', `/persons/${disp.id}/web-access`, { token: admin, body: { username: `disp-${tag}`, password: pw } });
  await must('PUT', `/persons/${prep.id}/web-access`, { token: admin, body: { username: `prep-${tag}`, password: pw } });
  const dispTok = (await must('POST', '/auth/login', { body: { username: `disp-${tag}`, password: pw } }, 200)).json.access_token;
  const prepTok = (await must('POST', '/auth/login', { body: { username: `prep-${tag}`, password: pw } }, 200)).json.access_token;

  // 3+ Fahrzeuge mit unterschiedlichem FMS-Status.
  const hlf = (await must('POST', '/vehicles', { token: admin, body: { call_sign: `Florian ${tag} 46/1`, short_name: 'HLF-1', type: 'HLF' } }, 201)).json;
  const rtw = (await must('POST', '/vehicles', { token: admin, body: { call_sign: `Florian ${tag} 83/1`, short_name: 'RTW-1', type: 'RTW' } }, 201)).json;
  const dlk = (await must('POST', '/vehicles', { token: admin, body: { call_sign: `Florian ${tag} 33/1`, short_name: 'DLK-1', type: 'DLK' } }, 201)).json;

  // Folien.
  await must('POST', '/slides', { token: admin, body: { title: 'Willkommen zum BF-Tag', body: '## Heute\n\nViel Spaß!', duration_seconds: 10, active: true } }, 201);
  await must('POST', '/slides', { token: admin, body: { title: 'Sicherheitshinweise', body: 'Bitte Helme tragen.', duration_seconds: 8, active: true } }, 201);

  // Nur ein BF-Tag darf laufen.
  const days = (await must('GET', '/bf-days', { token: admin })).json;
  for (const d of Array.isArray(days) ? days : (days?.bf_days ?? days?.items ?? [])) {
    if (d.state === 'running') await call('POST', `/bf-days/${d.id}/end`, { token: admin });
  }
  const day = (await must('POST', '/bf-days', { token: admin, body: { name: `Screenshots ${tag}`, starts_at: iso(-60), ends_at: iso(600) } }, 201)).json;
  await must('PUT', `/bf-days/${day.id}/participants`, { token: admin, body: { person_ids: [disp.id, prep.id, crewA.id, crewB.id, crewC.id] } });
  await must('POST', `/bf-days/${day.id}/start`, { token: admin }, 200);

  // Schichten.
  const shift = (await must('POST', `/bf-days/${day.id}/shifts`, { token: dispTok, body: { name: 'Schicht 1', starts_at: iso(-30), ends_at: iso(300) } }, 201)).json;
  await must('PUT', `/shifts/${shift.id}/crew`, {
    token: dispTok,
    body: {
      assignments: [
        { vehicle_id: hlf.id, person_id: crewA.id, function: 'GF' },
        { vehicle_id: hlf.id, person_id: crewB.id, function: 'MA' },
        { vehicle_id: rtw.id, person_id: crewC.id, function: 'MA' },
      ],
    },
  });

  // Unterschiedliche FMS-Status.
  const pairA = (await must('POST', `/persons/${crewA.id}/pairing-code`, { token: admin }, [200, 201])).json;
  const devA = (await must('POST', '/auth/pair', { body: { code: pairA.code, platform: 'android', app_version: '1.0.0-screenshots', device_name: 'Screenshot-Device' } }, [200, 201])).json;
  await must('PUT', `/vehicles/${hlf.id}/status`, { token: devA.access_token, body: { status: 3 } }, [200, 204]);
  await must('PUT', `/vehicles/${rtw.id}/status`, { token: dispTok, body: { status: 2 } }, [200, 204]);
  // dlk bleibt auf Status 1 (default).

  // Tagesablauf.
  await must('POST', `/bf-days/${day.id}/program-items`, { token: dispTok, body: { title: 'Mittagessen', type: 'meal', starts_at: iso(30), ends_at: iso(60) } }, 201);
  await must('POST', `/bf-days/${day.id}/program-items`, { token: dispTok, body: { title: 'Ausbildung Löschtechnik', type: 'training', starts_at: iso(70), ends_at: iso(130) } }, 201);

  // Einsatz: einer läuft aktuell und hat eine Position (für die Karte).
  const runningIncident = (await must('POST', `/bf-days/${day.id}/incidents`, {
    token: prepTok,
    body: { keyword: 'B3 Großbrand Lagerhalle', address: 'Industriestraße 7', report: 'Starke Rauchentwicklung aus dem Dach.', script: 'GEHEIM: Nebelmaschine im Innenhof.', latitude: 48.137, longitude: 11.575 },
  }, 201)).json;
  const alarmRes = await must('POST', `/incidents/${runningIncident.id}/alarms`, { token: dispTok, body: { vehicle_ids: [hlf.id, rtw.id] } }, 201);
  ok(alarmRes.json?.alarm?.state === 'triggered', 'screenshots: seeded alarm triggered');

  // Zweiter, geschlossener Einsatz (für die Liste).
  const closedIncident = (await must('POST', `/bf-days/${day.id}/incidents`, { token: prepTok, body: { keyword: 'B1 Kleinbrand', address: 'Nebenstraße 2', report: 'Mülltonnenbrand.' } }, 201)).json;
  await must('POST', `/incidents/${closedIncident.id}/alarms`, { token: dispTok, body: { vehicle_ids: [dlk.id] } }, 201);
  await must('POST', `/incidents/${closedIncident.id}/close`, { token: dispTok }, 200);

  // Durchsage.
  const announcement = (await must('POST', `/bf-days/${day.id}/announcements`, { token: dispTok, body: { text: 'Abendessen ist in 10 Minuten fertig.' } }, 201)).json;

  // Monitor fürs Kopplungsscreenshot.
  const mon = (await must('POST', '/monitors', { token: admin, body: { name: `Monitor ${tag}` } }, 201)).json;
  const monCode = (await must('POST', `/monitors/${mon.id}/pairing-code`, { token: admin }, [200, 201])).json;

  return { admin, dispTok, prepTok, day, runningIncident, announcement, monCode, hlf, rtw, dlk };
}

// --- 2. Web screenshots (1440x900) ----------------------------------------

const ADMIN_PAGES = [
  ['/admin', 'lage'],
  ['/admin/bf-tage', 'bf-tage'],
  ['/admin/schichten', 'schichten'],
  ['/admin/persons', 'personen'],
  ['/admin/fahrzeuge', 'fahrzeuge'],
  ['/admin/einsaetze', 'einsaetze'],
  ['/admin/durchsagen', 'durchsagen'],
  ['/admin/tagesablauf', 'tagesablauf'],
  ['/admin/slides', 'folien'],
  ['/admin/monitors', 'monitore'],
];

async function webShots() {
  await setViewport(1440, 900);

  await nav(`${BASE}/admin/login`);
  await waitForSemantics();
  await settle();
  await shot(WEB_DIR, 'login', 1440, 900);

  await typeInto(0, ADMIN_USER);
  await typeInto(1, ADMIN_PASS);
  await clickByText('^\\s*(anmelden|login|einloggen)\\s*$');
  await waitFor(async () => !/login/.test(await evalJs('location.pathname')), 6000, 200);
  await waitForSemantics();
  await settle();

  for (const [p, name] of ADMIN_PAGES) {
    await nav(`${BASE}${p}`);
    await waitForSemantics();
    await settle();
    if (name === 'einsaetze') {
      // Default Filter ist "Entwurf"; die Seed-Daten enthalten keinen
      // Einsatz im Entwurf (nur laufend/abgeschlossen) -- für den
      // regulären Übersichts-Screenshot auf "laufend" wechseln, damit
      // tatsächlich Daten sichtbar sind (sonst identisch zum Leerzustand).
      await clickByText('^\\s*laufend\\s*$');
      await waitForSemantics();
      await settle();
    }
    await shot(WEB_DIR, name, 1440, 900);
  }

  // Dialog: "Person anlegen" offen.
  await nav(`${BASE}/admin/persons`);
  await waitForSemantics();
  await settle();
  await clickByText('person anlegen|hinzufügen|neue person');
  await waitForSemantics();
  await settle();
  await shot(WEB_DIR, 'personen-dialog', 1440, 900);

  // Leerzustand: der Einsätze-Filter "Entwurf" ist voreingestellt, und die
  // Seed-Daten legen keinen Einsatz im Entwurfsstatus an (nur
  // laufend/abgeschlossen) -- das ist der zuverlässige, deterministische
  // Leerzustand. (Hinweis: ein Filter "Verworfen" existiert im UI nicht --
  // verworfene Einsätze werden laut Code-Kommentar in incidents_screen.dart
  // komplett ausgeblendet, nicht separat gefiltert.)
  await nav(`${BASE}/admin/einsaetze`);
  await waitForSemantics();
  await settle();
  await clickByText('^\\s*entwurf\\s*$');
  await waitForSemantics();
  await settle();
  await shot(WEB_DIR, 'einsaetze-empty', 1440, 900);
}

// --- 3. Monitor screenshots (1920x1080) ------------------------------------

// Fails loudly if the page currently shown is the Einsatzansicht instead of
// Standby -- guards against the screenshots.mjs ordering bug where a monitor
// pairs while an alarmed incident from seed() is already open and correctly
// (per docs/design/screens/monitor-alarm.md §4) jumps straight to
// MonitorIncidentScreen, silently producing a wrong "standby" screenshot.
async function assertStandbyScreen(name) {
  await enableSemantics();
  const t = await bodyText();
  if (/EINSATZ\s*\d/.test(t)) {
    throw new Error(
      `screenshots: expected Standby screen for "${name}" shot but found Einsatzansicht markup ` +
        `("EINSATZ <n>") in body text -- an alarmed incident is open when the monitor paired. ` +
        `Body text: ${t.slice(0, 300)}`,
    );
  }
  if (!t.includes('Fahrzeugstatus & Besatzung')) {
    throw new Error(
      `screenshots: expected Standby screen for "${name}" shot but "Fahrzeugstatus & Besatzung" ` +
        `(MonitorVehiclePanel heading) is missing from body text. Body text: ${t.slice(0, 300)}`,
    );
  }
}

async function monitorShots(seeded) {
  await setViewport(1920, 1080);

  // Vor dem Pairing: den bereits in seed() alarmierten Einsatz schließen.
  // Er wird für die webShots()-Einsätze-Übersicht (Filter "laufend") als
  // laufender Einsatz benötigt, muss aber geschlossen sein, bevor der
  // Monitor hier koppelt -- sonst liegt er bereits im initialen Snapshot
  // und der Monitor springt (korrekt, siehe
  // docs/design/screens/monitor-alarm.md §4) sofort in die Einsatzansicht
  // statt Standby zu zeigen.
  await must('POST', `/incidents/${seeded.runningIncident.id}/close`, { token: seeded.dispTok }, 200);

  // Aktivierung: frischer Browser-Kontext (kein localStorage), vor dem
  // Tap auf "aktivieren".
  await evalJs('localStorage.clear()');
  await nav(`${BASE}/monitor`);
  await waitForSemantics();
  await settle();
  await shot(MONITOR_DIR, 'aktivierung', 1920, 1080);

  // Kopplung.
  await clickByText('aktivieren');
  await waitForSemantics();
  await settle();
  await shot(MONITOR_DIR, 'kopplung', 1920, 1080);

  await typeInto(0, seeded.monCode.code);
  await clickByText('koppeln');
  await waitFor(async () => {
    await enableSemantics();
    const t = (await bodyText()).toLowerCase();
    return !t.includes('koppeln') ? t : undefined;
  }, 10000, 300);
  await settle(1500);

  // Standby: Fahrzeugstatus/Besatzung/Tagesablauf/Folie sind bereits
  // sichtbar. Der in seed() alarmierte Einsatz wurde oben vor dem Pairing
  // geschlossen, daher zeigt der initiale Snapshot keinen offenen Alarm und
  // der Monitor bleibt im Standby (statt sofort in die Einsatzansicht zu
  // springen).
  await assertStandbyScreen('standby');
  await shot(MONITOR_DIR, 'standby', 1920, 1080);

  // Standby mit Durchsage-Banner: erneute Durchsage frisch auslösen,
  // damit das Banner sichtbar ist (bestehende sind ggf. schon abgelaufen).
  await must('POST', `/bf-days/${seeded.day.id}/announcements`, { token: seeded.dispTok, body: { text: 'Testdurchsage für den Screenshot.' } }, 201);
  await settle(1200);
  await assertStandbyScreen('standby-durchsage');
  await shot(MONITOR_DIR, 'standby-durchsage', 1920, 1080);

  // Alarmzustand + Einsatzansicht mit Karte: ein frischer Live-Alarm nach
  // dem Pairing (per API), damit der Monitor den Übergang Standby ->
  // Alarmzustand (20 s) -> Einsatzansicht tatsächlich live durchläuft (ein
  // nur per Snapshot bereits laufender Einsatz löst laut Produktionslogik
  // keinen Alarm-Übergang aus -- nur ein live `alarm.triggered`-Event tut
  // das).
  const liveIncident = (await must('POST', `/bf-days/${seeded.day.id}/incidents`, {
    token: seeded.prepTok,
    body: { keyword: 'B2 Kellerbrand', address: 'Hauptstraße 1', report: 'Rauch aus dem Keller.', latitude: 48.138, longitude: 11.576 },
  }, 201)).json;
  await must('POST', `/incidents/${liveIncident.id}/alarms`, { token: seeded.dispTok, body: { vehicle_ids: [seeded.dlk.id] } }, 201);
  await settle(1500);
  await shot(MONITOR_DIR, 'alarm', 1920, 1080);
  // Den Rest der 20-s-Alarmzustand-Phase abwarten (insgesamt >= 21 s seit
  // Alarmauslösung), bevor die Einsatzansicht aufgenommen wird.
  await settle(20000);
  await shot(MONITOR_DIR, 'einsatzansicht', 1920, 1080);

  // Einsatz-Fallback: ein alarmierter Einsatz ohne Standort (kein
  // latitude/longitude) -- den vorherigen Einsatz vorher schließen, damit
  // die Rotation nicht dazwischenfunkt.
  await must('POST', `/incidents/${liveIncident.id}/close`, { token: seeded.dispTok }, 200);
  const fallbackIncident = (await must('POST', `/bf-days/${seeded.day.id}/incidents`, {
    token: seeded.prepTok,
    body: { keyword: 'B1 Kleinbrand ohne Standort', address: 'Seitenweg 3', report: 'Kein GPS verfügbar.' },
  }, 201)).json;
  await must('POST', `/incidents/${fallbackIncident.id}/alarms`, { token: seeded.dispTok, body: { vehicle_ids: [seeded.hlf.id] } }, 201);
  await settle(1500);
  // Auch hier die Alarmzustand-Phase abwarten, bevor die
  // Einsatzansicht (Fallback ohne Karte) aufgenommen wird.
  await settle(20000);
  await shot(MONITOR_DIR, 'einsatz-fallback', 1920, 1080);
}

async function main() {
  const port = await cdpSession.start();
  await cdpSession.connect(port);

  const seeded = await seed();
  await webShots();
  await monitorShots(seeded);

  const exitCode = summary('SCREENSHOTS');
  process.exit(exitCode);
}

main().catch((e) => {
  console.error('CRASH', e);
  process.exit(2);
});
