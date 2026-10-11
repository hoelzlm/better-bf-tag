// e2e/lib.mjs — shared helpers for the API and UI e2e suites.
// Configuration is read from environment variables only (no hardcoded paths):
//   E2E_BASE           base URL, e.g. https://localhost:28443 (default http://localhost:8080)
//   E2E_ADMIN_USER      admin username (default "admin")
//   E2E_ADMIN_PASS      admin password (default "admin12345")
//   E2E_ARTIFACT_DIR    where screenshots/logs go (default "<e2e-dir>/artifacts")
import WebSocket from 'ws';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import fs from 'node:fs';

const E2E_DIR = path.dirname(fileURLToPath(import.meta.url));

export const BASE = process.env.E2E_BASE ?? 'http://localhost:8080';
export const API = `${BASE}/api/v1`;
export const ADMIN_USER = process.env.E2E_ADMIN_USER ?? 'admin';
export const ADMIN_PASS = process.env.E2E_ADMIN_PASS ?? 'admin12345';
export const ARTIFACT_DIR = process.env.E2E_ARTIFACT_DIR
  ? path.resolve(process.env.E2E_ARTIFACT_DIR)
  : path.join(E2E_DIR, 'artifacts');

fs.mkdirSync(ARTIFACT_DIR, { recursive: true });

let pass = 0;
let fail = 0;
const failures = [];

export function ok(cond, name, extra) {
  if (cond) {
    pass++;
    console.log(`PASS ${name}`);
  } else {
    fail++;
    failures.push(name);
    console.log(`FAIL ${name}${extra !== undefined ? ' :: ' + JSON.stringify(extra).slice(0, 400) : ''}`);
  }
  return cond;
}

export async function call(method, path, { token, body, headers } = {}) {
  const h = { ...(headers ?? {}) };
  if (token) h.authorization = `Bearer ${token}`;
  if (body !== undefined) h['content-type'] = 'application/json';
  const r = await fetch(`${API}${path}`, {
    method,
    headers: h,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });
  const text = await r.text();
  let json;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = text;
  }
  return { status: r.status, json, headers: r.headers };
}

export async function must(method, path, opts, expect = [200, 201, 204]) {
  const r = await call(method, path, opts);
  const exp = Array.isArray(expect) ? expect : [expect];
  ok(exp.includes(r.status), `${method} ${path} -> ${exp.join('/')}`, { status: r.status, body: r.json });
  return r;
}

export async function expectErr(method, path, opts, status, code, label) {
  const r = await call(method, path, opts);
  ok(
    r.status === status && (!code || r.json?.error?.code === code),
    `${label}: ${method} ${path} -> ${status} ${code ?? ''}`,
    { status: r.status, body: r.json },
  );
  return r;
}

export class WsClient {
  constructor(name, token) {
    this.name = name;
    this.msgs = [];
    this.waiters = [];
    this.ws = new WebSocket(`${BASE.replace(/^http/, 'ws')}/ws?token=${encodeURIComponent(token)}`, {
      rejectUnauthorized: false,
    });
    this.ws.on('error', (e) => console.log(`WS ${name} error ${e.message}`));
    this.ws.on('message', (d) => {
      const m = JSON.parse(d.toString());
      this.msgs.push(m);
      this.waiters = this.waiters.filter((w) => !w(m));
    });
    this.closed = new Promise((res) => this.ws.on('close', (code) => res(code)));
  }
  waitFor(pred, ms = 5000) {
    const hit = this.msgs.find(pred);
    if (hit) return Promise.resolve(hit);
    return new Promise((res) => {
      const t = setTimeout(() => res(null), ms);
      this.waiters.push((m) => {
        if (pred(m)) {
          clearTimeout(t);
          res(m);
          return true;
        }
        return false;
      });
    });
  }
  close() {
    this.ws.close();
  }
}

export function summary(label) {
  console.log(`\n${label} RESULT: ${pass} passed, ${fail} failed`);
  if (fail) console.log('FAILED:\n- ' + failures.join('\n- '));
  return fail ? 1 : 0;
}
