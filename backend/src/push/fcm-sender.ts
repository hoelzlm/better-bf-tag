import { SignJWT, importPKCS8 } from 'jose';
import type { PushMessage, PushResult, PushSender } from './push-sender.js';

export interface FcmServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

export interface FcmPushSenderOptions {
  serviceAccount: FcmServiceAccount;
  /** Default https://fcm.googleapis.com */
  endpoint?: string;
  tokenUri?: string;
  fetchImpl?: typeof fetch;
  now?: () => Date;
}

const DEFAULT_ENDPOINT = 'https://fcm.googleapis.com';
const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';
const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const FIVE_MINUTES_MS = 5 * 60 * 1000;

interface CachedToken {
  accessToken: string;
  /** ms epoch (deps.now()) at which the token should be considered expired. */
  expiresAt: number;
}

interface FcmErrorBody {
  error?: {
    status?: string;
    details?: Array<{ errorCode?: string }>;
  };
}

/** FCM HTTP v1 sender (ADR 0018): OAuth2 via service-account JWT-bearer grant, then messages:send. */
export class FcmPushSender implements PushSender {
  private readonly serviceAccount: FcmServiceAccount;
  private readonly endpoint: string;
  private readonly tokenUri: string;
  private readonly fetchImpl: typeof fetch;
  private readonly now: () => Date;
  private cachedToken: CachedToken | undefined;

  constructor(opts: FcmPushSenderOptions) {
    this.serviceAccount = opts.serviceAccount;
    this.endpoint = opts.endpoint ?? DEFAULT_ENDPOINT;
    this.tokenUri = opts.tokenUri ?? opts.serviceAccount.token_uri ?? DEFAULT_TOKEN_URI;
    this.fetchImpl = opts.fetchImpl ?? fetch;
    this.now = opts.now ?? (() => new Date());
  }

  async send(messages: PushMessage[]): Promise<PushResult[]> {
    const accessToken = await this.getAccessToken();
    return Promise.all(messages.map(message => this.sendOne(message, accessToken)));
  }

  private async sendOne(message: PushMessage, accessToken: string): Promise<PushResult> {
    const body = {
      message: {
        token: message.token,
        android: {
          priority: 'high',
          ttl: '300s',
          notification: {
            channel_id: 'alarm',
            sound: 'alarm',
            tag: `incident-${message.data.incident_id}`,
          },
        },
        notification: {
          title: message.data.keyword,
          body: message.data.address,
        },
        data: {
          type: 'alarm.triggered',
          incident_id: message.data.incident_id,
          alarm_id: message.data.alarm_id,
        },
      },
    };

    const url = `${this.endpoint}/v1/projects/${this.serviceAccount.project_id}/messages:send`;

    try {
      const res = await this.fetchImpl(url, {
        method: 'POST',
        headers: {
          authorization: `Bearer ${accessToken}`,
          'content-type': 'application/json',
        },
        body: JSON.stringify(body),
      });

      if (res.status === 200) {
        return { deviceId: message.deviceId, outcome: 'delivered' };
      }

      let parsed: FcmErrorBody | undefined;
      try {
        parsed = (await res.json()) as FcmErrorBody;
      } catch {
        parsed = undefined;
      }

      if (res.status === 404) {
        return { deviceId: message.deviceId, outcome: 'invalid_token' };
      }

      const errorCode = parsed?.error?.details?.find(d => d.errorCode)?.errorCode;
      if (errorCode === 'UNREGISTERED') {
        return { deviceId: message.deviceId, outcome: 'invalid_token' };
      }
      if (res.status === 400 && parsed?.error?.status === 'INVALID_ARGUMENT') {
        return { deviceId: message.deviceId, outcome: 'invalid_token' };
      }

      return { deviceId: message.deviceId, outcome: 'rejected' };
    } catch {
      return { deviceId: message.deviceId, outcome: 'rejected' };
    }
  }

  private async getAccessToken(): Promise<string> {
    const nowMs = this.now().getTime();
    if (this.cachedToken && nowMs < this.cachedToken.expiresAt) {
      return this.cachedToken.accessToken;
    }

    const nowSeconds = Math.floor(nowMs / 1000);
    const key = await importPKCS8(this.serviceAccount.private_key, 'RS256');
    const assertion = await new SignJWT({ scope: SCOPE })
      .setProtectedHeader({ alg: 'RS256' })
      .setIssuer(this.serviceAccount.client_email)
      .setSubject(this.serviceAccount.client_email)
      .setAudience(this.tokenUri)
      .setIssuedAt(nowSeconds)
      .setExpirationTime(nowSeconds + 3600)
      .sign(key);

    const res = await this.fetchImpl(this.tokenUri, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion,
      }).toString(),
    });

    if (!res.ok) {
      throw new Error(`FCM token request failed with status ${res.status}`);
    }

    const json = (await res.json()) as { access_token: string; expires_in: number };
    this.cachedToken = {
      accessToken: json.access_token,
      expiresAt: nowMs + json.expires_in * 1000 - FIVE_MINUTES_MS,
    };
    return json.access_token;
  }
}
