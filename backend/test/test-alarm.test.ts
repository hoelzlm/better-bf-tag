import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Pool } from 'pg';
import { startTestApp, type TestApp } from './support/test-app.js';
import { createPerson, loginAs } from './support/create-person.js';
import { connectWs } from './support/ws-client.js';

interface PairingCodeResponse {
  code: string;
}

async function waitUntil(predicate: () => boolean, timeoutMs = 2000): Promise<void> {
  const start = Date.now();
  while (!predicate()) {
    if (Date.now() - start > timeoutMs) {
      throw new Error('Timed out waiting for condition');
    }
    await new Promise(resolve => setTimeout(resolve, 10));
  }
}

describe('test-alarm', () => {
  let app: TestApp;
  let pool: Pool;
  let adminToken: string;

  beforeAll(async () => {
    app = await startTestApp();
    pool = new Pool({ connectionString: app.databaseUrl });
    adminToken = await loginAs(app, 'admin', 'admin-password');
  });

  afterAll(async () => {
    await pool.end();
    await app.close();
  });

  let counter = 0;
  function uniqueToken(label: string): string {
    counter += 1;
    return `test-alarm-token-${label}-${counter}`;
  }

  async function createParticipant(username: string): Promise<string> {
    const person = await createPerson(app, {
      displayName: username,
      personType: 'youth',
      permission: 'crew',
      username,
      password: 'participant-password',
    });
    return person.id;
  }

  /** Pairs a brand-new Device for the given Person via the real /auth/pair flow. */
  async function pairDevice(personId: string): Promise<{ deviceId: string; token: string }> {
    const codeRes = await app
      .client()
      .post(`/api/v1/persons/${personId}/pairing-code`, {}, { token: adminToken });
    const code = (codeRes.body as PairingCodeResponse).code;
    const pairRes = await app
      .client()
      .post('/api/v1/auth/pair', { code, platform: 'android', app_version: '1.0.0' });
    expect(pairRes.status).toBe(200);
    return {
      deviceId: (pairRes.body as { device_id: string }).device_id,
      token: (pairRes.body as { access_token: string }).access_token,
    };
  }

  async function setPushToken(deviceAccessToken: string, token: string): Promise<void> {
    const res = await app
      .client()
      .put('/api/v1/me/device/push-token', { token }, { token: deviceAccessToken });
    expect(res.status).toBe(204);
  }

  async function revokeDevice(deviceId: string): Promise<void> {
    const res = await app.client().delete(`/api/v1/devices/${deviceId}`, { token: adminToken });
    expect(res.status).toBe(204);
  }

  async function triggerTestAlarm(
    deviceAccessToken: string,
    body: Record<string, unknown> = {}
  ): Promise<{ status: number; body: unknown }> {
    const res = await app
      .client()
      .post('/api/v1/me/device/test-alarm', body, { token: deviceAccessToken });
    return { status: res.status, body: res.body };
  }

  async function tableCounts(): Promise<{ incidents: number; alarms: number; recipients: number }> {
    const [incidents, alarms, recipients] = await Promise.all([
      pool.query('select count(*)::int as c from incident'),
      pool.query('select count(*)::int as c from alarm'),
      pool.query('select count(*)::int as c from alarm_recipient'),
    ]);
    return {
      incidents: incidents.rows[0].c,
      alarms: alarms.rows[0].c,
      recipients: recipients.rows[0].c,
    };
  }

  it('web session -> 403 forbidden', async () => {
    const res = await triggerTestAlarm(adminToken);
    expect(res.status).toBe(403);
    expect((res.body as { error: { code: string } }).error.code).toBe('forbidden');
  });

  it('device without a push token -> 409 no_push_token', async () => {
    const personId = await createParticipant('test-alarm-no-token');
    const { token: deviceToken } = await pairDevice(personId);

    const res = await triggerTestAlarm(deviceToken);
    expect(res.status).toBe(409);
    expect((res.body as { error: { code: string } }).error.code).toBe('no_push_token');
  });

  it('immediate: only the caller device gets a message; no incident/alarm rows; no WS event; seq unchanged', async () => {
    const personId = await createParticipant('test-alarm-p1');
    const otherPersonId = await createParticipant('test-alarm-p2');

    const { deviceId: callerDeviceId, token: callerToken } = await pairDevice(personId);
    const { deviceId: sameSiblingDeviceId, token: sameSiblingToken } = await pairDevice(personId);
    const { deviceId: otherDeviceId, token: otherToken } = await pairDevice(otherPersonId);

    await setPushToken(callerToken, uniqueToken('caller'));
    await setPushToken(sameSiblingToken, uniqueToken('sibling'));
    await setPushToken(otherToken, uniqueToken('other'));

    app.push.clear();
    const before = await tableCounts();

    const dispatchToken = adminToken;
    const ws = await connectWs(app.baseUrl, dispatchToken);
    const hello = await ws.next(m => m.type === 'hello');
    const seqBefore = hello.seq as number;

    try {
      const res = await triggerTestAlarm(callerToken, { delay_seconds: 0 });
      expect(res.status).toBe(200);
      expect((res.body as { outcome: string }).outcome).toBe('delivered');

      expect(app.push.sent).toHaveLength(1);
      expect(app.push.sent[0]?.deviceId).toBe(callerDeviceId);
      expect(app.push.sent[0]?.data).toEqual({ type: 'test_alarm' });
      expect(app.push.sentTo(sameSiblingDeviceId)).toHaveLength(0);
      expect(app.push.sentTo(otherDeviceId)).toHaveLength(0);

      const after = await tableCounts();
      expect(after).toEqual(before);

      // No WS event: a short heartbeat/no-op window — assert nothing else
      // arrived and the snapshot seq is unchanged.
      await expect(ws.next(undefined, 200)).rejects.toThrow();

      const snapshot = await app.client().get('/api/v1/snapshot', { token: dispatchToken });
      expect((snapshot.body as { seq: number }).seq).toBe(seqBefore);
    } finally {
      ws.close();
    }
  });

  it('invalid_token clears the token on the device', async () => {
    const personId = await createParticipant('test-alarm-invalid');
    const { deviceId, token: deviceToken } = await pairDevice(personId);
    const pushToken = uniqueToken('invalid');
    await setPushToken(deviceToken, pushToken);
    app.push.markInvalid(pushToken);

    const res = await triggerTestAlarm(deviceToken, { delay_seconds: 0 });
    expect(res.status).toBe(200);
    expect((res.body as { outcome: string }).outcome).toBe('invalid_token');

    const row = (await pool.query('select push_token from device where id = $1', [deviceId]))
      .rows[0];
    expect(row?.push_token).toBeNull();
  });

  it('second call within 10s -> 429 test_alarm_cooldown', async () => {
    const personId = await createParticipant('test-alarm-cooldown');
    const { token: deviceToken } = await pairDevice(personId);
    await setPushToken(deviceToken, uniqueToken('cooldown'));

    const first = await triggerTestAlarm(deviceToken, { delay_seconds: 0 });
    expect(first.status).toBe(200);

    const second = await triggerTestAlarm(deviceToken, { delay_seconds: 0 });
    expect(second.status).toBe(429);
    expect((second.body as { error: { code: string } }).error.code).toBe('test_alarm_cooldown');
  });

  it('delay_seconds=5 -> 202 scheduled; nothing sent until the timer fires, then exactly one message', async () => {
    const personId = await createParticipant('test-alarm-delayed');
    const { deviceId, token: deviceToken } = await pairDevice(personId);
    await setPushToken(deviceToken, uniqueToken('delayed'));

    app.push.clear();
    const res = await triggerTestAlarm(deviceToken, { delay_seconds: 5 });
    expect(res.status).toBe(202);
    expect(res.body).toEqual({ scheduled: true });
    expect(app.push.sent).toHaveLength(0);

    app.testAlarmTimer.fireAll();
    await waitUntil(() => app.push.sent.length > 0);

    expect(app.push.sent).toHaveLength(1);
    expect(app.push.sent[0]?.deviceId).toBe(deviceId);
    expect(app.push.sent[0]?.data).toEqual({ type: 'test_alarm' });
  });

  it('revoked before the timer fires -> nothing sent', async () => {
    const personId = await createParticipant('test-alarm-revoked');
    const { deviceId, token: deviceToken } = await pairDevice(personId);
    await setPushToken(deviceToken, uniqueToken('revoked'));

    app.push.clear();
    const res = await triggerTestAlarm(deviceToken, { delay_seconds: 5 });
    expect(res.status).toBe(202);

    await revokeDevice(deviceId);

    app.testAlarmTimer.fireAll();
    // Give the async delivery a chance to run and confirm it stays empty.
    await new Promise(resolve => setTimeout(resolve, 100));
    expect(app.push.sent).toHaveLength(0);
  });

  it('delay_seconds 31 -> 400 validation_error', async () => {
    const personId = await createParticipant('test-alarm-too-long');
    const { token: deviceToken } = await pairDevice(personId);
    await setPushToken(deviceToken, uniqueToken('too-long'));

    const res = await triggerTestAlarm(deviceToken, { delay_seconds: 31 });
    expect(res.status).toBe(400);
  });
});
