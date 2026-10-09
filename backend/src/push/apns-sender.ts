import { connect, type ClientHttp2Session } from 'node:http2';
import { SignJWT, importPKCS8 } from 'jose';
import type { PushMessage, PushResult, PushSender } from './push-sender.js';

export interface ApnsPushSenderOptions {
  /** p8 PEM private key. */
  key: string;
  keyId: string;
  teamId: string;
  bundleId: string;
  production: boolean;
  /** Default https://api.push.apple.com (production) / https://api.sandbox.push.apple.com (sandbox). */
  origin?: string;
  now?: () => Date;
}

const FIFTY_MINUTES_MS = 50 * 60 * 1000;
const EXPIRATION_WINDOW_SECONDS = 300;

interface CachedToken {
  jwt: string;
  createdAt: number;
}

/** APNs HTTP/2 token-auth sender (ADR 0018): one reused h2 session, cached provider JWT. */
export class ApnsPushSender implements PushSender {
  private readonly key: string;
  private readonly keyId: string;
  private readonly teamId: string;
  private readonly bundleId: string;
  private readonly origin: string;
  private readonly now: () => Date;
  private cachedToken: CachedToken | undefined;
  private session: ClientHttp2Session | undefined;

  constructor(opts: ApnsPushSenderOptions) {
    this.key = opts.key;
    this.keyId = opts.keyId;
    this.teamId = opts.teamId;
    this.bundleId = opts.bundleId;
    this.origin =
      opts.origin ??
      (opts.production ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com');
    this.now = opts.now ?? (() => new Date());
  }

  async send(messages: PushMessage[]): Promise<PushResult[]> {
    const jwt = await this.getToken();
    return Promise.all(messages.map(message => this.sendOne(message, jwt)));
  }

  private async sendOne(message: PushMessage, jwt: string): Promise<PushResult> {
    const body = JSON.stringify({
      aps: {
        alert: {
          title: message.data.keyword,
          body: message.data.address,
        },
        sound: 'alarm.wav',
        'interruption-level': 'time-sensitive',
        'thread-id': `incident-${message.data.incident_id}`,
      },
      incident_id: message.data.incident_id,
      alarm_id: message.data.alarm_id,
    });

    try {
      const { status, body: responseBody } = await this.request(message.token, jwt, body);

      if (status === 200) {
        return { deviceId: message.deviceId, outcome: 'delivered' };
      }
      if (status === 410) {
        return { deviceId: message.deviceId, outcome: 'invalid_token' };
      }
      if (status === 400) {
        let parsed: { reason?: string } | undefined;
        try {
          parsed = responseBody ? (JSON.parse(responseBody) as { reason?: string }) : undefined;
        } catch {
          parsed = undefined;
        }
        if (parsed?.reason === 'BadDeviceToken') {
          return { deviceId: message.deviceId, outcome: 'invalid_token' };
        }
      }
      return { deviceId: message.deviceId, outcome: 'rejected' };
    } catch {
      return { deviceId: message.deviceId, outcome: 'rejected' };
    }
  }

  private request(
    token: string,
    jwt: string,
    body: string
  ): Promise<{ status: number; body: string }> {
    return new Promise((resolve, reject) => {
      const session = this.getSession();

      const req = session.request({
        ':method': 'POST',
        ':path': `/3/device/${token}`,
        authorization: `bearer ${jwt}`,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        'apns-expiration': String(
          Math.floor(this.now().getTime() / 1000) + EXPIRATION_WINDOW_SECONDS
        ),
        'apns-topic': this.bundleId,
        'content-type': 'application/json',
      });

      let status = 0;
      const chunks: Buffer[] = [];

      req.on('response', headers => {
        status = Number(headers[':status'] ?? 0);
      });
      req.on('data', chunk => {
        chunks.push(chunk as Buffer);
      });
      req.on('end', () => {
        resolve({ status, body: Buffer.concat(chunks).toString('utf-8') });
      });
      req.on('error', err => {
        reject(err);
      });

      req.end(body);
    });
  }

  private getSession(): ClientHttp2Session {
    if (!this.session || this.session.closed || this.session.destroyed) {
      const session = connect(this.origin);
      session.on('error', () => {
        // Swallow: the next request() call reconnects via getSession().
      });
      this.session = session;
    }
    return this.session;
  }

  private async getToken(): Promise<string> {
    const nowMs = this.now().getTime();
    if (this.cachedToken && nowMs - this.cachedToken.createdAt < FIFTY_MINUTES_MS) {
      return this.cachedToken.jwt;
    }

    const key = await importPKCS8(this.key, 'ES256');
    const nowSeconds = Math.floor(nowMs / 1000);
    const jwt = await new SignJWT({})
      .setProtectedHeader({ alg: 'ES256', kid: this.keyId })
      .setIssuer(this.teamId)
      .setIssuedAt(nowSeconds)
      .sign(key);

    this.cachedToken = { jwt, createdAt: nowMs };
    return jwt;
  }

  async close(): Promise<void> {
    if (this.session && !this.session.closed && !this.session.destroyed) {
      await new Promise<void>(resolve => {
        this.session?.close(() => resolve());
      });
    }
  }
}
