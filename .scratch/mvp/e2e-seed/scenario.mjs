// End-to-end user-flow scenario against a running better-bf-tag backend.
// Usage: BASE=http://localhost:8080 node scenario.mjs
import { createRequire } from 'node:module';
import { randomUUID } from 'node:crypto';
const require = createRequire('/home/markus/Developer/better-bf-tag/backend/package.json');
const WebSocket = require('ws');

const BASE = process.env.BASE ?? 'http://localhost:8080';
const API = `${BASE}/api/v1`;
const ADMIN_USER = process.env.ADMIN_USER ?? 'admin';
const ADMIN_PASS = process.env.ADMIN_PASS ?? 'admin12345';
const tag = Date.now().toString(36);
let pass = 0, fail = 0;
const failures = [];

function ok(cond, name, extra) {
  if (cond) { pass++; console.log(`PASS ${name}`); }
  else { fail++; failures.push(name); console.log(`FAIL ${name}${extra !== undefined ? ' :: ' + JSON.stringify(extra).slice(0, 400) : ''}`); }
}

async function call(method, path, { token, body, headers } = {}) {
  const h = { ...(headers ?? {}) };
  if (token) h.authorization = `Bearer ${token}`;
  if (body !== undefined) h['content-type'] = 'application/json';
  const r = await fetch(`${API}${path}`, { method, headers: h, body: body !== undefined ? JSON.stringify(body) : undefined });
  const text = await r.text();
  let json; try { json = text ? JSON.parse(text) : null; } catch { json = text; }
  return { status: r.status, json, headers: r.headers };
}
async function must(method, path, opts, expect = [200, 201, 204]) {
  const r = await call(method, path, opts);
  const exp = Array.isArray(expect) ? expect : [expect];
  ok(exp.includes(r.status), `${method} ${path} -> ${exp.join('/')}`, { status: r.status, body: r.json });
  return r;
}
async function expectErr(method, path, opts, status, code, label) {
  const r = await call(method, path, opts);
  ok(r.status === status && (!code || r.json?.error?.code === code), `${label}: ${method} ${path} -> ${status} ${code ?? ''}`, { status: r.status, body: r.json });
  return r;
}

class WsClient {
  constructor(name, token) {
    this.name = name; this.msgs = []; this.waiters = [];
    this.ws = new WebSocket(`${BASE.replace(/^http/, 'ws')}/ws?token=${encodeURIComponent(token)}`);
    this.ws.on('error', (e) => console.log(`WS ${name} error ${e.message}`));
    this.ws.on('message', (d) => { const m = JSON.parse(d.toString()); this.msgs.push(m); this.waiters = this.waiters.filter((w) => !w(m)); });
    this.closed = new Promise((res) => this.ws.on('close', (code) => res(code)));
  }
  waitFor(pred, ms = 5000) {
    const hit = this.msgs.find(pred); if (hit) return Promise.resolve(hit);
    return new Promise((res) => {
      const t = setTimeout(() => res(null), ms);
      this.waiters.push((m) => { if (pred(m)) { clearTimeout(t); res(m); return true; } return false; });
    });
  }
  close() { this.ws.close(); }
}

const iso = (offsetMin) => new Date(Date.now() + offsetMin * 60000).toISOString();

async function main() {
  // --- health + docs
  await must('GET', '/health');
  const oa = await must('GET', '/openapi.json');
  ok(Object.keys(oa.json?.paths ?? {}).length > 30, 'openapi.json served with paths');

  // --- auth
  await expectErr('POST', '/auth/login', { body: { username: ADMIN_USER, password: 'wrong-password' } }, 401, null, 'wrong admin password rejected');
  const login = await must('POST', '/auth/login', { body: { username: ADMIN_USER, password: ADMIN_PASS } }, 200);
  const admin = login.json.access_token;
  ok(!!admin, 'admin got access token');
  const setCookie = login.headers.get('set-cookie') ?? '';
  ok(/httponly/i.test(setCookie), 'refresh cookie is HttpOnly', setCookie);
  const refreshed = await call('POST', '/auth/refresh', { headers: { cookie: setCookie.split(';')[0] } });
  ok(refreshed.status === 200 && refreshed.json?.access_token, 'web refresh via cookie works', refreshed);
  await expectErr('GET', '/persons', {}, 401, null, 'unauthenticated blocked');

  // --- master data
  const fdr = await call('GET', '/fire-departments', { token: admin });
  console.log(`NOTE /fire-departments (documented in 04-api) -> ${fdr.status}`);
  const mk = async (display_name, permission, person_type = 'youth') =>
    (await must('POST', '/persons', { token: admin, body: { display_name, person_type, permission } }, 201)).json;
  const disp = await mk(`Leitstelle ${tag}`, 'dispatch', 'supervisor');
  const prep = await mk(`Vorbereitung ${tag}`, 'preparation', 'supervisor');
  const crewA = await mk(`Anna ${tag}`, 'crew');
  const crewB = await mk(`Ben ${tag}`, 'crew');
  const crewC = await mk(`Clara ${tag}`, 'crew');
  const pw = `pw-${tag}-0123456789`;
  await must('PUT', `/persons/${disp.id}/web-access`, { token: admin, body: { username: `disp-${tag}`, password: pw } });
  await must('PUT', `/persons/${prep.id}/web-access`, { token: admin, body: { username: `prep-${tag}`, password: pw } });
  const dispTok = (await must('POST', '/auth/login', { body: { username: `disp-${tag}`, password: pw } }, 200)).json.access_token;
  const prepTok = (await must('POST', '/auth/login', { body: { username: `prep-${tag}`, password: pw } }, 200)).json.access_token;
  await expectErr('POST', '/persons', { token: dispTok, body: { display_name: 'x', person_type: 'youth', permission: 'crew' } }, 403, 'forbidden', 'dispatch cannot manage persons');

  const hlf = (await must('POST', '/vehicles', { token: admin, body: { call_sign: `Florian ${tag} 46/1`, short_name: `HLF-${tag}`, type: 'HLF' } }, 201)).json;
  const rtw = (await must('POST', '/vehicles', { token: admin, body: { call_sign: `Florian ${tag} 83/1`, short_name: `RTW-${tag}`, type: 'RTW' } }, 201)).json;
  await must('POST', '/slides', { token: admin, body: { title: `Willkommen ${tag}`, body: 'E2E', duration_seconds: 10, active: true } }, 201);

  // --- BF day: end any running one first (only one may run)
  const days = (await must('GET', '/bf-days', { token: admin })).json;
  for (const d of (Array.isArray(days) ? days : days?.bf_days ?? days?.items ?? [])) {
    if (d.state === 'running') { console.log(`NOTE ending previously running day ${d.id}`); await call('POST', `/bf-days/${d.id}/end`, { token: admin }); }
  }
  const day = (await must('POST', '/bf-days', { token: admin, body: { name: `E2E ${tag}`, starts_at: iso(-60), ends_at: iso(600) } }, 201)).json;
  await must('PUT', `/bf-days/${day.id}/participants`, { token: admin, body: { person_ids: [disp.id, prep.id, crewA.id, crewB.id, crewC.id] } });
  await must('POST', `/bf-days/${day.id}/start`, { token: admin }, 200);
  const shift = (await must('POST', `/bf-days/${day.id}/shifts`, { token: dispTok, body: { name: 'Schicht 1', starts_at: iso(-30), ends_at: iso(300) } }, 201)).json;
  await must('PUT', `/shifts/${shift.id}/crew`, { token: dispTok, body: { assignments: [
    { vehicle_id: hlf.id, person_id: crewA.id, function: 'GF' },
    { vehicle_id: hlf.id, person_id: crewB.id, function: 'MA' },
    { vehicle_id: rtw.id, person_id: crewC.id, function: 'MA' },
  ] } });

  // --- device + monitor pairing
  const pairA = (await must('POST', `/persons/${crewA.id}/pairing-code`, { token: admin }, [200, 201])).json;
  const devA = (await must('POST', '/auth/pair', { body: { code: pairA.code, platform: 'android', app_version: '1.0.0-e2e', device_name: 'Pixel E2E' } }, [200, 201])).json;
  await expectErr('POST', '/auth/pair', { body: { code: pairA.code, platform: 'android', app_version: '1.0.0' } }, 401, null, 'pairing code is single-use').catch(() => {});
  const pairC = (await must('POST', `/persons/${crewC.id}/pairing-code`, { token: admin }, [200, 201])).json;
  const devC = (await must('POST', '/auth/pair', { body: { code: pairC.code, platform: 'ios', app_version: '1.0.0-e2e' } }, [200, 201])).json;
  const aTok = devA.access_token, cTok = devC.access_token;
  const me = (await must('GET', '/me', { token: aTok })).json;
  ok(me?.crew_assignments?.some((c) => c.vehicle_id === hlf.id && c.function === 'GF'), '/me shows crew assignment GF on HLF', me);
  const devRefresh = await call('POST', '/auth/device/refresh', { body: { refresh_token: devA.refresh_token } });
  ok(devRefresh.status === 200 && devRefresh.json.refresh_token !== devA.refresh_token, 'device refresh rotates token', devRefresh);
  const oldReuse = await call('POST', '/auth/device/refresh', { body: { refresh_token: devA.refresh_token } });
  ok(oldReuse.status === 401, 'old device refresh token rejected after rotation', oldReuse);
  const aTok2 = devRefresh.json?.access_token ?? aTok;

  const mon = (await must('POST', '/monitors', { token: admin, body: { name: `Monitor ${tag}` } }, 201)).json;
  const monCode = (await must('POST', `/monitors/${mon.id}/pairing-code`, { token: admin }, [200, 201])).json;
  const monTok = (await must('POST', '/auth/monitor/pair', { body: { code: monCode.code } }, [200, 201])).json.access_token;
  await must('GET', '/monitor/me', { token: monTok });
  await expectErr('GET', '/persons', { token: monTok }, 403, 'forbidden', 'monitor blocked from admin routes');
  await expectErr('POST', '/alarms/00000000-0000-4000-8000-000000000000/acknowledge', { token: monTok }, 403, 'forbidden', 'monitor cannot acknowledge');

  // --- realtime
  const wsBad = new WsClient('bad', 'garbage');
  ok((await Promise.race([wsBad.closed, new Promise((r) => setTimeout(() => r('timeout'), 5000))])) === 4401, 'ws with invalid token closed 4401');
  const wsA = new WsClient('crewA', aTok2), wsMon = new WsClient('monitor', monTok), wsDisp = new WsClient('disp', dispTok);
  for (const w of [wsA, wsMon, wsDisp]) ok(!!(await w.waitFor((m) => m.type === 'hello')), `ws hello for ${w.name}`);

  // --- incident lifecycle
  const SECRET = `Drehbuch-geheim-${tag}`;
  const inc = (await must('POST', `/bf-days/${day.id}/incidents`, { token: prepTok, body: { keyword: 'B2 Kellerbrand', address: 'Hauptstr. 1', report: 'Rauch aus Keller', script: SECRET } }, 201)).json;
  ok(inc.state === 'draft' && inc.number >= 1, 'incident created as draft with number', inc);
  await expectErr('GET', `/incidents/${inc.id}`, { token: aTok2 }, 404, 'not_found', 'crew cannot see draft');
  await expectErr('POST', `/incidents/${inc.id}/alarms`, { token: prepTok, body: { vehicle_ids: [hlf.id] } }, 403, 'forbidden', 'preparation cannot alarm');

  const alarmKey = randomUUID();
  const al = await must('POST', `/incidents/${inc.id}/alarms`, { token: dispTok, body: { id: alarmKey, vehicle_ids: [hlf.id] } }, 201);
  const alarm = al.json.alarm;
  ok(alarm?.state === 'triggered', 'first alarm triggered', al.json);
  ok(alarm?.recipients?.length === 2 && alarm.recipients.some((r) => r.person_id === crewA.id && r.has_device), 'recipients frozen from shift (A with device, B)', alarm?.recipients);
  const again = await call('POST', `/incidents/${inc.id}/alarms`, { token: dispTok, body: { id: alarmKey, vehicle_ids: [hlf.id] } });
  ok(again.status === 200 && again.json.alarm.id === alarm.id, 'idempotent alarm retry -> 200 same alarm', again);
  await expectErr('POST', `/incidents/${inc.id}/alarms`, { token: dispTok, body: { vehicle_ids: [hlf.id] } }, 409, 'vehicle_already_alarmed', 'double alarm blocked');

  const evA = await wsA.waitFor((m) => m.type === 'alarm.triggered' && m.data?.alarm?.id === alarm.id);
  ok(!!evA, 'crew ws got alarm.triggered');
  ok(evA && !JSON.stringify(evA).includes(SECRET), 'crew alarm event has no script');
  const evMon = await wsMon.waitFor((m) => m.type === 'alarm.triggered');
  ok(!!evMon && !JSON.stringify(evMon).includes(SECRET), 'monitor got alarm.triggered without script');
  const evDisp = await wsDisp.waitFor((m) => m.type === 'alarm.triggered');
  ok(!!evDisp && JSON.stringify(evDisp).includes(SECRET), 'dispatcher alarm event includes script');

  const crewInc = (await must('GET', `/incidents/${inc.id}`, { token: aTok2 })).json;
  ok(crewInc && !('script' in crewInc), 'crew GET incident has no script key', crewInc);
  const snapMon = (await must('GET', '/snapshot', { token: monTok })).json;
  ok(snapMon.incidents?.some((i) => i.id === inc.id) && !JSON.stringify(snapMon).includes(SECRET), 'monitor snapshot shows running incident w/o script');
  ok(Array.isArray(snapMon.slides) && snapMon.slides.length >= 1, 'snapshot contains slides');

  // ack
  await expectErr('POST', `/alarms/${alarm.id}/acknowledge`, { token: cTok }, 403, 'not_recipient', 'non-recipient cannot ack');
  const ack = await must('POST', `/alarms/${alarm.id}/acknowledge`, { token: aTok2 }, 200);
  ok(!!ack.json?.recipient?.acknowledged_at, 'ack has timestamp', ack.json);
  ok(!!(await wsDisp.waitFor((m) => m.type === 'alarm.acknowledged' && m.data?.person_id === crewA.id)), 'dispatcher ws got alarm.acknowledged');
  const ack2 = await call('POST', `/alarms/${alarm.id}/acknowledge`, { token: aTok2 });
  ok(ack2.status === 200, 'ack is idempotent', ack2);

  // vehicle status
  await must('PUT', `/vehicles/${hlf.id}/status`, { token: aTok2, body: { status: 3 } }, [200, 204]);
  ok(!!(await wsMon.waitFor((m) => m.type === 'vehicle.status_changed' && m.data?.vehicle_id === hlf.id && m.data?.status === 3 && m.data?.source === 'app')), 'monitor got status 3 from app');
  await expectErr('PUT', `/vehicles/${hlf.id}/status`, { token: aTok2, body: { status: 7 } }, 409, 'status_not_allowed', 'status 7 not allowed on HLF');
  await expectErr('PUT', `/vehicles/${rtw.id}/status`, { token: aTok2, body: { status: 3 } }, 403, 'forbidden', 'crew cannot set other vehicle status');
  await must('PUT', `/vehicles/${rtw.id}/status`, { token: cTok, body: { status: 7 } }, [200, 204]);
  await must('PUT', `/vehicles/${hlf.id}/status`, { token: dispTok, body: { status: 4 } }, [200, 204]);

  // scheduled follow-up alarm, then discard
  const planned = await must('POST', `/incidents/${inc.id}/alarms`, { token: dispTok, body: { vehicle_ids: [rtw.id], offset_minutes: 30 } }, 201);
  ok(planned.json?.alarm?.state === 'planned', 'relative alarm planned', planned.json);
  const crewView = (await must('GET', `/incidents/${inc.id}`, { token: aTok2 })).json;
  ok(!(crewView.alarms ?? []).some((a) => a.state === 'planned'), 'crew does not see planned alarms');
  const disc = await must('POST', `/alarms/${planned.json.alarm.id}/discard`, { token: dispTok }, 200);
  ok(disc.json?.alarm?.state === 'discarded', 'planned alarm discarded', disc.json);

  // short absolute schedule -> scheduler fires it
  const sched = await must('POST', `/incidents/${inc.id}/alarms`, { token: dispTok, body: { vehicle_ids: [rtw.id], scheduled_at: new Date(Date.now() + 4000).toISOString() } }, 201);
  const fired = await wsDisp.waitFor((m) => m.type === 'alarm.triggered' && m.data?.alarm?.id === sched.json?.alarm?.id, 20000);
  ok(!!fired, 'scheduler fired the timed alarm (~4s)');
  ok(fired?.data?.alarm?.recipients?.some((r) => r.person_id === crewC.id), 'timed alarm recipients = RTW crew');

  // close
  await expectErr('POST', `/incidents/${inc.id}/close`, { token: prepTok }, 403, 'forbidden', 'preparation cannot close');
  const closed = await must('POST', `/incidents/${inc.id}/close`, { token: dispTok }, 200);
  ok(closed.json?.incident?.state === 'closed', 'incident closed', closed.json);
  ok(!!(await wsA.waitFor((m) => m.type === 'incident.closed' && m.data?.id === inc.id)), 'crew ws got incident.closed');
  await expectErr('POST', `/alarms/${alarm.id}/acknowledge`, { token: aTok2 }, 409, 'alarm_not_active', 'ack after close rejected');
  await expectErr('POST', `/incidents/${inc.id}/close`, { token: dispTok }, 409, 'invalid_state_transition', 'double close rejected');

  // draft discard path
  const inc2 = (await must('POST', `/bf-days/${day.id}/incidents`, { token: prepTok, body: { keyword: 'TH1', address: 'Weg 2' } }, 201)).json;
  ok(inc2.number === inc.number + 1, 'incident numbers sequential');
  await must('POST', `/incidents/${inc2.id}/discard`, { token: prepTok }, 200);

  // seq gap-free per connection
  const seqs = wsA.msgs.filter((m) => typeof m.seq === 'number' && m.type !== 'hello' && m.type !== 'heartbeat').map((m) => m.seq);
  ok(seqs.every((s, i) => i === 0 || s === seqs[i - 1] + 1), 'crew ws seq is gap-free (skips fill gaps)', seqs);

  // device logout -> session revoked
  const wsC = new WsClient('crewC', cTok); await wsC.waitFor((m) => m.type === 'hello');
  await must('POST', '/auth/device/logout', { token: cTok, body: { refresh_token: devC.refresh_token } }, [200, 204]);
  const cClose = await Promise.race([wsC.closed, new Promise((r) => setTimeout(() => r('timeout'), 5000))]);
  ok(cClose === 4403, 'logged-out device ws closed with 4403', cClose);

  // end + anonymize
  await must('POST', `/bf-days/${day.id}/end`, { token: admin }, 200);
  await expectErr('POST', `/bf-days/${day.id}/incidents`, { token: prepTok, body: { keyword: 'x', address: 'y' } }, 409, 'bf_day_ended', 'no incidents after day ended');
  const prev = await must('GET', `/bf-days/${day.id}/anonymization-preview`, { token: dispTok }, 200);
  const anon = await must('POST', `/bf-days/${day.id}/anonymize`, { token: dispTok }, 200);
  ok(JSON.stringify(prev.json) === JSON.stringify(anon.json?.summary) && anon.json?.bf_day?.anonymized_at, 'anonymize summary matches preview', { prev: prev.json, anon: anon.json });

  for (const w of [wsA, wsMon, wsDisp]) w.close();
  console.log(`\nRESULT: ${pass} passed, ${fail} failed`);
  if (fail) console.log('FAILED:\n- ' + failures.join('\n- '));
  process.exit(fail ? 1 : 0);
}
main().catch((e) => { console.error('CRASH', e); process.exit(2); });
