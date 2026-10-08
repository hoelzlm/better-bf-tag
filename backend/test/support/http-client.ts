export interface HttpResponse<T = unknown> {
  status: number;
  body: T | null;
  headers: Headers;
}

interface StoredCookie {
  value: string;
  expiresAt?: number;
}

/**
 * Minimal fetch-based HTTP client with a cookie jar, for black-box tests
 * against a startTestApp() instance. Stores Set-Cookie name=value pairs,
 * sends them back as a Cookie header, and respects Max-Age=0 / Expires in
 * the past by dropping the cookie.
 */
export class HttpClient {
  private readonly cookies = new Map<string, StoredCookie>();

  constructor(private readonly baseUrl: string) {}

  get(path: string, opts?: { token?: string }): Promise<HttpResponse> {
    return this.request('GET', path, undefined, opts);
  }

  post(path: string, body?: unknown, opts?: { token?: string }): Promise<HttpResponse> {
    return this.request('POST', path, body, opts);
  }

  put(path: string, body?: unknown, opts?: { token?: string }): Promise<HttpResponse> {
    return this.request('PUT', path, body, opts);
  }

  patch(path: string, body?: unknown, opts?: { token?: string }): Promise<HttpResponse> {
    return this.request('PATCH', path, body, opts);
  }

  delete(path: string, opts?: { token?: string }): Promise<HttpResponse> {
    return this.request('DELETE', path, undefined, opts);
  }

  private async request(
    method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE',
    path: string,
    body: unknown,
    opts?: { token?: string }
  ): Promise<HttpResponse> {
    const headers: Record<string, string> = {};
    const cookieHeader = this.buildCookieHeader();
    if (cookieHeader) headers['cookie'] = cookieHeader;
    if (opts?.token) headers['authorization'] = `Bearer ${opts.token}`;

    let payload: string | undefined;
    if (body !== undefined) {
      headers['content-type'] = 'application/json';
      payload = JSON.stringify(body);
    }

    const response = await fetch(`${this.baseUrl}${path}`, {
      method,
      headers,
      body: payload,
    });

    this.storeCookies(response.headers);

    const text = await response.text();
    let parsedBody: unknown = null;
    if (text) {
      try {
        parsedBody = JSON.parse(text);
      } catch {
        parsedBody = text;
      }
    }

    return { status: response.status, body: parsedBody, headers: response.headers };
  }

  /** Reads the currently stored raw cookie value (for black-box tests that need to inspect/replay it). */
  getCookie(name: string): string | undefined {
    return this.cookies.get(name)?.value;
  }

  /** Overrides the stored raw cookie value (for black-box tests replaying an old/stale token). */
  setCookie(name: string, value: string): void {
    this.cookies.set(name, { value });
  }

  private buildCookieHeader(): string | undefined {
    const now = Date.now();
    const pairs: string[] = [];
    for (const [name, cookie] of this.cookies) {
      if (cookie.expiresAt !== undefined && cookie.expiresAt <= now) continue;
      pairs.push(`${name}=${cookie.value}`);
    }
    return pairs.length > 0 ? pairs.join('; ') : undefined;
  }

  private storeCookies(headers: Headers): void {
    const setCookieHeaders = this.getSetCookieHeaders(headers);
    for (const raw of setCookieHeaders) {
      this.applySetCookie(raw);
    }
  }

  private getSetCookieHeaders(headers: Headers): string[] {
    const headersWithGetter = headers as Headers & { getSetCookie?: () => string[] };
    if (typeof headersWithGetter.getSetCookie === 'function') {
      return headersWithGetter.getSetCookie();
    }
    const single = headers.get('set-cookie');
    return single ? [single] : [];
  }

  private applySetCookie(raw: string): void {
    const segments = raw.split(';').map(segment => segment.trim());
    const [pairSegment, ...attributeSegments] = segments;
    if (!pairSegment) return;
    const eqIndex = pairSegment.indexOf('=');
    if (eqIndex === -1) return;
    const name = pairSegment.slice(0, eqIndex);
    const value = pairSegment.slice(eqIndex + 1);

    let maxAgeSeconds: number | undefined;
    let expiresDate: string | undefined;
    for (const attribute of attributeSegments) {
      const eq = attribute.indexOf('=');
      const key = (eq === -1 ? attribute : attribute.slice(0, eq)).toLowerCase();
      const attrValue = eq === -1 ? '' : attribute.slice(eq + 1);
      if (key === 'max-age') maxAgeSeconds = Number(attrValue);
      if (key === 'expires') expiresDate = attrValue;
    }

    if (maxAgeSeconds !== undefined && maxAgeSeconds <= 0) {
      this.cookies.delete(name);
      return;
    }

    let expiresAt: number | undefined;
    if (maxAgeSeconds !== undefined) {
      expiresAt = Date.now() + maxAgeSeconds * 1000;
    } else if (expiresDate) {
      const parsed = Date.parse(expiresDate);
      if (!Number.isNaN(parsed)) {
        if (parsed <= Date.now()) {
          this.cookies.delete(name);
          return;
        }
        expiresAt = parsed;
      }
    }

    this.cookies.set(name, { value, expiresAt });
  }
}
