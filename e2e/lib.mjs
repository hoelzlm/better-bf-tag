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
import { spawn } from 'node:child_process';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import net from 'node:net';

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

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// --- shared CDP / headless Chrome helpers -----------------------------
// Used by ui.mjs and screenshots.mjs so both drive Chrome the exact same
// way (spawn, connect, send/evalJs/nav/waitFor/enableSemantics).

export function freePort() {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.on('error', reject);
    srv.listen(0, '127.0.0.1', () => {
      const { port } = srv.address();
      srv.close(() => resolve(port));
    });
  });
}

/**
 * Creates a headless-Chrome + CDP session. Returns an object with the
 * same helpers ui.mjs used to keep as module-level state/functions, now
 * reusable from screenshots.mjs too. Call `start()` then `connect()`,
 * and `cleanup()` (also auto-registered on process exit) when done.
 */
export function createCdpSession({ chromeBin, windowSize = '1400,900' } = {}) {
  const CHROME_BIN = chromeBin ?? process.env.CHROME_BIN ?? 'google-chrome';
  const profileDir = mkdtempSync(path.join(tmpdir(), 'bftag-e2e-chrome-'));
  let chrome;
  let cdp;
  let msgId = 0;
  const pending = new Map();
  const consoleErrors = [];

  function cleanup() {
    if (chrome && chrome.exitCode === null && chrome.signalCode === null) {
      try {
        chrome.kill('SIGKILL');
      } catch {
        // already gone
      }
    }
    try {
      rmSync(profileDir, { recursive: true, force: true });
    } catch {
      // best effort
    }
  }
  process.on('exit', cleanup);

  async function start() {
    const port = await freePort();
    chrome = spawn(
      CHROME_BIN,
      [
        '--headless=new',
        '--no-sandbox',
        '--ignore-certificate-errors',
        `--window-size=${windowSize}`,
        '--autoplay-policy=no-user-gesture-required',
        `--user-data-dir=${profileDir}`,
        `--remote-debugging-port=${port}`,
        'about:blank',
      ],
      { stdio: 'ignore' },
    );
    chrome.on('error', (e) => console.log(`NOTE chrome spawn error: ${e.message}`));
    return port;
  }

  async function connect(port) {
    let tabs;
    for (let i = 0; i < 60; i++) {
      try {
        tabs = await (await fetch(`http://127.0.0.1:${port}/json`)).json();
        break;
      } catch {
        await sleep(250);
      }
    }
    if (!tabs) throw new Error('Chrome DevTools endpoint never came up');
    const page = tabs.find((t) => t.type === 'page');
    cdp = new WebSocket(page.webSocketDebuggerUrl);
    await new Promise((resolve, reject) => {
      cdp.on('open', resolve);
      cdp.on('error', reject);
    });
    cdp.on('message', (d) => {
      const m = JSON.parse(d.toString());
      if (m.id && pending.has(m.id)) {
        const { resolve } = pending.get(m.id);
        pending.delete(m.id);
        resolve(m.result ?? {});
      }
      if (m.method === 'Runtime.exceptionThrown') {
        consoleErrors.push(m.params.exceptionDetails?.exception?.description ?? m.params.exceptionDetails?.text ?? 'exception');
      }
      if (m.method === 'Runtime.consoleAPICalled' && m.params.type === 'error') {
        consoleErrors.push(m.params.args.map((a) => a.value ?? a.description).join(' '));
      }
    });
    await send('Page.enable');
    await send('Runtime.enable');
  }

  function send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = ++msgId;
      pending.set(id, { resolve, reject });
      cdp.send(JSON.stringify({ id, method, params }));
    });
  }

  async function evalJs(expression) {
    const r = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (r.exceptionDetails) {
      throw new Error(r.exceptionDetails.text ?? 'Runtime.evaluate exception');
    }
    return r.result?.value;
  }

  async function waitFor(predicate, timeoutMs = 8000, intervalMs = 150) {
    const start = Date.now();
    for (;;) {
      let value;
      try {
        value = await predicate();
      } catch {
        value = undefined;
      }
      if (value) return value;
      if (Date.now() - start > timeoutMs) return undefined;
      await sleep(intervalMs);
    }
  }

  async function nav(url) {
    await send('Page.navigate', { url });
    await waitFor(async () => (await evalJs('document.readyState')) === 'complete', 10000, 200);
  }

  const enableSemantics = () =>
    evalJs(
      `(() => { const p = document.querySelector('flt-semantics-placeholder'); if (p) { p.click(); return true; } return false; })()`,
    );

  return {
    start,
    connect,
    send,
    evalJs,
    waitFor,
    nav,
    enableSemantics,
    cleanup,
    get consoleErrors() {
      return consoleErrors;
    },
  };
}

export function summary(label) {
  console.log(`\n${label} RESULT: ${pass} passed, ${fail} failed`);
  if (fail) console.log('FAILED:\n- ' + failures.join('\n- '));
  return fail ? 1 : 0;
}
