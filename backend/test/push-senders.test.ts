import { createServer, type IncomingMessage, type Server, type ServerResponse } from 'node:http';
import { createServer as createHttp2Server, type Http2Server } from 'node:http2';
import { generateKeyPairSync } from 'node:crypto';
import { jwtVerify, importSPKI, decodeProtectedHeader } from 'jose';
import { describe, it, expect, beforeAll, beforeEach, afterEach } from 'vitest';

import { FcmPushSender } from '../src/push/fcm-sender.js';
import { ApnsPushSender } from '../src/push/apns-sender.js';
import { PlatformPushSender } from '../src/push/platform-sender.js';
import type { PushMessage, PushResult, PushSender } from '../src/push/push-sender.js';

function baseMessage(overrides: Partial<PushMessage> = {}): PushMessage {
  return {
    deviceId: 'device-1',
    platform: 'android',
    token: 'fcm-token-1',
    data: {
      type: 'alarm.triggered',
      incident_id: 'incident-1',
      alarm_id: 'alarm-1',
      keyword: 'B2 – Wohnungsbrand',
      address: 'Musterstraße 1',
    },
    ...overrides,
  };
}

async function readJsonBody(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  for await (const chunk of req) {
    chunks.push(chunk as Buffer);
  }
  const raw = Buffer.concat(chunks).toString('utf-8');
  return raw ? JSON.parse(raw) : undefined;
}

function listen(server: Server): Promise<number> {
  return new Promise(resolve => {
    server.listen(0, '127.0.0.1', () => {
      const address = server.address();
      resolve(typeof address === 'object' && address !== null ? address.port : 0);
    });
  });
}

describe('FcmPushSender', () => {
  let rsaKeyPair: { publicKey: string; privateKey: string };
  let server: Server;
  let port: number;
  let tokenRequests: Array<{ body: string; headers: IncomingMessage['headers'] }>;
  let fcmRequests: Array<{ body: unknown; headers: IncomingMessage['headers'] }>;
  let tokenResponse: { status: number; body: unknown };
  let fcmResponse: { status: number; body: unknown };

  beforeAll(() => {
    const pair = generateKeyPairSync('rsa', { modulusLength: 2048 });
    rsaKeyPair = {
      publicKey: pair.publicKey.export({ type: 'spki', format: 'pem' }) as string,
      privateKey: pair.privateKey.export({ type: 'pkcs8', format: 'pem' }) as string,
    };
  });

  beforeEach(async () => {
    tokenRequests = [];
    fcmRequests = [];
    tokenResponse = {
      status: 200,
      body: { access_token: 'access-token-1', expires_in: 3600, token_type: 'Bearer' },
    };
    fcmResponse = { status: 200, body: { name: 'projects/p/messages/1' } };

    server = createServer(async (req: IncomingMessage, res: ServerResponse) => {
      if (req.url === '/token') {
        const chunks: Buffer[] = [];
        for await (const chunk of req) chunks.push(chunk as Buffer);
        tokenRequests.push({
          body: Buffer.concat(chunks).toString('utf-8'),
          headers: req.headers,
        });
        res.writeHead(tokenResponse.status, { 'content-type': 'application/json' });
        res.end(JSON.stringify(tokenResponse.body));
        return;
      }
      if (req.url?.includes('/messages:send')) {
        const body = await readJsonBody(req);
        fcmRequests.push({ body, headers: req.headers });
        res.writeHead(fcmResponse.status, { 'content-type': 'application/json' });
        res.end(JSON.stringify(fcmResponse.body));
        return;
      }
      res.writeHead(404);
      res.end();
    });
    port = await listen(server);
  });

  afterEach(async () => {
    await new Promise<void>(resolve => server.close(() => resolve()));
  });

  function makeSender(now?: () => Date): FcmPushSender {
    return new FcmPushSender({
      serviceAccount: {
        project_id: 'test-project',
        client_email: 'svc@test-project.iam.gserviceaccount.com',
        private_key: rsaKeyPair.privateKey,
        token_uri: `http://127.0.0.1:${port}/token`,
      },
      endpoint: `http://127.0.0.1:${port}`,
      ...(now ? { now } : {}),
    });
  }

  it('fetches a token via the JWT-bearer grant', async () => {
    const sender = makeSender();
    await sender.send([baseMessage()]);

    expect(tokenRequests).toHaveLength(1);
    expect(tokenRequests[0]?.headers['content-type']).toBe('application/x-www-form-urlencoded');
    const params = new URLSearchParams(tokenRequests[0]?.body ?? '');
    expect(params.get('grant_type')).toBe('urn:ietf:params:oauth:grant-type:jwt-bearer');
    const assertion = params.get('assertion');
    expect(assertion).toBeTruthy();

    const publicKey = await importSPKI(rsaKeyPair.publicKey, 'RS256');
    const { payload } = await jwtVerify(assertion as string, publicKey);
    expect(payload['scope']).toBe('https://www.googleapis.com/auth/firebase.messaging');
    expect(payload['iss']).toBe('svc@test-project.iam.gserviceaccount.com');
    expect(payload['aud']).toBe(`http://127.0.0.1:${port}/token`);
  });

  it('reuses the cached access token across two send() calls', async () => {
    const sender = makeSender();
    await sender.send([baseMessage()]);
    await sender.send([baseMessage({ deviceId: 'device-2', token: 'fcm-token-2' })]);

    expect(tokenRequests).toHaveLength(1);
    expect(fcmRequests).toHaveLength(2);
  });

  it('sends exactly the Android payload from docs/05 with no extra fields', async () => {
    const sender = makeSender();
    await sender.send([baseMessage()]);

    expect(fcmRequests).toHaveLength(1);
    expect(fcmRequests[0]?.body).toEqual({
      message: {
        token: 'fcm-token-1',
        android: {
          priority: 'high',
          ttl: '300s',
          notification: {
            channel_id: 'alarm',
            sound: 'alarm',
            tag: 'incident-incident-1',
          },
        },
        notification: { title: 'B2 – Wohnungsbrand', body: 'Musterstraße 1' },
        data: { type: 'alarm.triggered', incident_id: 'incident-1', alarm_id: 'alarm-1' },
      },
    });
  });

  it('sends the Testalarm payload (ADR 0021): same channel/sound, tag test-alarm, no alarm_id', async () => {
    const sender = makeSender();
    await sender.send([baseMessage({ data: { type: 'test_alarm' } })]);

    expect(fcmRequests).toHaveLength(1);
    expect(fcmRequests[0]?.body).toEqual({
      message: {
        token: 'fcm-token-1',
        android: {
          priority: 'high',
          ttl: '300s',
          notification: {
            channel_id: 'alarm',
            sound: 'alarm',
            tag: 'test-alarm',
          },
        },
        notification: {
          title: 'Testalarm',
          body: 'Wenn du das hörst, funktioniert der Alarm.',
        },
        data: { type: 'test_alarm' },
      },
    });
  });

  it('maps 404 UNREGISTERED to invalid_token', async () => {
    fcmResponse = {
      status: 404,
      body: {
        error: {
          status: 'NOT_FOUND',
          details: [{ errorCode: 'UNREGISTERED' }],
        },
      },
    };
    const sender = makeSender();
    const [result] = await sender.send([baseMessage()]);
    expect(result).toEqual<PushResult>({ deviceId: 'device-1', outcome: 'invalid_token' });
  });

  it('maps 500 to rejected', async () => {
    fcmResponse = { status: 500, body: { error: { status: 'INTERNAL' } } };
    const sender = makeSender();
    const [result] = await sender.send([baseMessage()]);
    expect(result).toEqual<PushResult>({ deviceId: 'device-1', outcome: 'rejected' });
  });
});

describe('ApnsPushSender', () => {
  let ecKeyPair: { publicKey: string; privateKey: string };
  let server: Http2Server;
  let port: number;
  let requests: Array<{ headers: Record<string, string | string[] | undefined>; body: string }>;
  let responsePlan: { status: number; body?: unknown };

  beforeAll(() => {
    const pair = generateKeyPairSync('ec', { namedCurve: 'prime256v1' });
    ecKeyPair = {
      publicKey: pair.publicKey.export({ type: 'spki', format: 'pem' }) as string,
      privateKey: pair.privateKey.export({ type: 'pkcs8', format: 'pem' }) as string,
    };
  });

  beforeEach(async () => {
    requests = [];
    responsePlan = { status: 200 };

    server = createHttp2Server();
    server.on('stream', (stream, headers) => {
      const chunks: Buffer[] = [];
      stream.on('data', chunk => chunks.push(chunk as Buffer));
      stream.on('end', () => {
        requests.push({
          headers: headers as unknown as Record<string, string | string[] | undefined>,
          body: Buffer.concat(chunks).toString('utf-8'),
        });
        const plan = responsePlan;
        stream.respond({
          ':status': plan.status,
          'content-type': 'application/json',
        });
        stream.end(plan.body !== undefined ? JSON.stringify(plan.body) : '');
      });
    });
    await new Promise<void>(resolve => server.listen(0, '127.0.0.1', () => resolve()));
    const address = server.address();
    port = typeof address === 'object' && address !== null ? address.port : 0;
  });

  afterEach(async () => {
    await new Promise<void>(resolve => server.close(() => resolve()));
  });

  function makeSender(now?: () => Date): ApnsPushSender {
    return new ApnsPushSender({
      key: ecKeyPair.privateKey,
      keyId: 'KEY123',
      teamId: 'TEAM123',
      bundleId: 'de.bftag.app',
      production: false,
      origin: `http://127.0.0.1:${port}`,
      ...(now ? { now } : {}),
    });
  }

  it('sends the documented headers and payload, with a verifiable ES256 JWT', async () => {
    const fixedNow = new Date('2026-01-01T00:00:00.000Z');
    const sender = makeSender(() => fixedNow);
    await sender.send([baseMessage({ platform: 'ios', token: 'apns-token-1' })]);
    await sender.close();

    expect(requests).toHaveLength(1);
    const req = requests[0];
    expect(req).toBeDefined();
    expect(req?.headers[':path']).toBe('/3/device/apns-token-1');
    expect(req?.headers['apns-priority']).toBe('10');
    expect(req?.headers['apns-push-type']).toBe('alert');
    expect(req?.headers['apns-topic']).toBe('de.bftag.app');
    const expectedExpiration = Math.floor(fixedNow.getTime() / 1000) + 300;
    expect(Number(req?.headers['apns-expiration'])).toBeCloseTo(expectedExpiration, 0);

    const authHeader = String(req?.headers['authorization']);
    expect(authHeader.startsWith('bearer ')).toBe(true);
    const jwt = authHeader.slice('bearer '.length);
    const header = decodeProtectedHeader(jwt);
    expect(header.kid).toBe('KEY123');
    expect(header.alg).toBe('ES256');

    const publicKey = await importSPKI(ecKeyPair.publicKey, 'ES256');
    const { payload } = await jwtVerify(jwt, publicKey);
    expect(payload['iss']).toBe('TEAM123');
    expect(payload['iat']).toBeTypeOf('number');

    expect(JSON.parse(req?.body ?? '{}')).toEqual({
      aps: {
        alert: { title: 'B2 – Wohnungsbrand', body: 'Musterstraße 1' },
        sound: 'alarm.wav',
        'interruption-level': 'time-sensitive',
        'thread-id': 'incident-incident-1',
      },
      incident_id: 'incident-1',
      alarm_id: 'alarm-1',
    });
  });

  it('sends the Testalarm payload (ADR 0021): thread-id test-alarm, top-level type test_alarm', async () => {
    const sender = makeSender();
    await sender.send([
      baseMessage({ platform: 'ios', token: 'apns-token-1', data: { type: 'test_alarm' } }),
    ]);
    await sender.close();

    expect(requests).toHaveLength(1);
    expect(JSON.parse(requests[0]?.body ?? '{}')).toEqual({
      aps: {
        alert: { title: 'Testalarm', body: 'Wenn du das hörst, funktioniert der Alarm.' },
        sound: 'alarm.wav',
        'interruption-level': 'time-sensitive',
        'thread-id': 'test-alarm',
      },
      type: 'test_alarm',
    });
  });

  it('maps 410 to invalid_token', async () => {
    responsePlan = { status: 410, body: { reason: 'Unregistered' } };
    const sender = makeSender();
    const [result] = await sender.send([baseMessage({ platform: 'ios', token: 'apns-token-1' })]);
    await sender.close();
    expect(result).toEqual<PushResult>({ deviceId: 'device-1', outcome: 'invalid_token' });
  });

  it('maps 400 BadDeviceToken to invalid_token', async () => {
    responsePlan = { status: 400, body: { reason: 'BadDeviceToken' } };
    const sender = makeSender();
    const [result] = await sender.send([baseMessage({ platform: 'ios', token: 'apns-token-1' })]);
    await sender.close();
    expect(result).toEqual<PushResult>({ deviceId: 'device-1', outcome: 'invalid_token' });
  });

  it('maps other 400 reasons to rejected', async () => {
    responsePlan = { status: 400, body: { reason: 'BadTopic' } };
    const sender = makeSender();
    const [result] = await sender.send([baseMessage({ platform: 'ios', token: 'apns-token-1' })]);
    await sender.close();
    expect(result).toEqual<PushResult>({ deviceId: 'device-1', outcome: 'rejected' });
  });
});

describe('PlatformPushSender', () => {
  class StubSender implements PushSender {
    constructor(private outcome: PushResult['outcome']) {}
    received: PushMessage[] = [];
    async send(messages: PushMessage[]): Promise<PushResult[]> {
      this.received.push(...messages);
      return messages.map(m => ({ deviceId: m.deviceId, outcome: this.outcome }));
    }
  }

  it('routes android messages to the android sender and ios messages to the ios sender', async () => {
    const android = new StubSender('delivered');
    const ios = new StubSender('invalid_token');
    const sender = new PlatformPushSender({ android, ios });

    const results = await sender.send([
      baseMessage({ deviceId: 'a1', platform: 'android' }),
      baseMessage({ deviceId: 'i1', platform: 'ios' }),
    ]);

    expect(android.received.map(m => m.deviceId)).toEqual(['a1']);
    expect(ios.received.map(m => m.deviceId)).toEqual(['i1']);
    expect(results).toEqual(
      expect.arrayContaining([
        { deviceId: 'a1', outcome: 'delivered' },
        { deviceId: 'i1', outcome: 'invalid_token' },
      ])
    );
  });

  it('rejects messages for an unconfigured platform', async () => {
    const android = new StubSender('delivered');
    const sender = new PlatformPushSender({ android });

    const results = await sender.send([baseMessage({ deviceId: 'i1', platform: 'ios' })]);

    expect(results).toEqual([{ deviceId: 'i1', outcome: 'rejected' }]);
  });
});
