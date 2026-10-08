/**
 * Minimal WebSocket test client using Node's global `WebSocket` (Node >= 22,
 * no extra dependency). Black-box: talks to `/ws` the same way a real
 * client would.
 */
export interface WsMessage {
  seq?: number;
  type: string;
  at?: string;
  data?: unknown;
  [key: string]: unknown;
}

export interface WsTestClient {
  /** Resolves with the next message, optionally filtered by `predicate`. */
  next(predicate?: (msg: WsMessage) => boolean, timeoutMs?: number): Promise<WsMessage>;
  /** Resolves with the close code once the connection closes. */
  closeCode: Promise<number>;
  /** All messages received so far, in arrival order. */
  readonly messages: WsMessage[];
  close(): void;
}

function wsUrl(baseUrl: string, token: string | undefined): string {
  const url = new URL(baseUrl);
  url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:';
  url.pathname = '/ws';
  if (token !== undefined) {
    url.searchParams.set('token', token);
  }
  return url.toString();
}

/**
 * Opens a `/ws` connection and resolves once the socket is open (or
 * immediately closed — callers must check `closeCode` for auth failures,
 * since the WebSocket `open` event may never fire before a close with a
 * non-1000 code on some runtimes).
 */
export function connectWs(baseUrl: string, token?: string): Promise<WsTestClient> {
  return new Promise((resolve, reject) => {
    const socket = new WebSocket(wsUrl(baseUrl, token));
    const messages: WsMessage[] = [];
    const waiters: Array<{
      predicate?: (msg: WsMessage) => boolean;
      resolve: (msg: WsMessage) => void;
      reject: (err: Error) => void;
      timeout: ReturnType<typeof setTimeout>;
    }> = [];

    let settledOpen = false;
    let closeCodeResolve: (code: number) => void;
    const closeCode = new Promise<number>(res => {
      closeCodeResolve = res;
    });

    function deliver(msg: WsMessage): void {
      // Deliver to the oldest matching waiter directly instead of buffering
      // it in `messages` too, so a message is never observed twice (once
      // via a waiter, once again via a later `next()`'s buffer scan).
      const index = waiters.findIndex(w => !w.predicate || w.predicate(msg));
      if (index !== -1) {
        const waiter = waiters[index];
        if (!waiter) return;
        waiters.splice(index, 1);
        clearTimeout(waiter.timeout);
        waiter.resolve(msg);
        return;
      }
      messages.push(msg);
    }

    socket.addEventListener('message', event => {
      const data = typeof event.data === 'string' ? event.data : String(event.data);
      let parsed: WsMessage;
      try {
        parsed = JSON.parse(data) as WsMessage;
      } catch {
        return;
      }
      deliver(parsed);
    });

    socket.addEventListener('open', () => {
      if (settledOpen) return;
      settledOpen = true;
      resolve(client);
    });

    socket.addEventListener('close', event => {
      closeCodeResolve(event.code);
      if (!settledOpen) {
        settledOpen = true;
        resolve(client);
      }
      for (const waiter of waiters.splice(0)) {
        clearTimeout(waiter.timeout);
        waiter.reject(
          new Error(`WebSocket closed (code ${event.code}) before a matching message arrived`)
        );
      }
    });

    socket.addEventListener('error', () => {
      if (!settledOpen) {
        settledOpen = true;
        reject(new Error('WebSocket connection error'));
      }
    });

    const client: WsTestClient = {
      messages,
      closeCode,
      next(predicate, timeoutMs = 2000) {
        const already = messages.find(m => !predicate || predicate(m));
        if (already) {
          // Only consume already-buffered messages once per call: remove it
          // so a second `next()` doesn't see the same message again.
          messages.splice(messages.indexOf(already), 1);
          return Promise.resolve(already);
        }
        return new Promise<WsMessage>((res, rej) => {
          const timeout = setTimeout(() => {
            const idx = waiters.findIndex(w => w.resolve === res);
            if (idx !== -1) waiters.splice(idx, 1);
            rej(new Error('Timed out waiting for WebSocket message'));
          }, timeoutMs);
          waiters.push({ predicate, resolve: res, reject: rej, timeout });
        });
      },
      close() {
        socket.close();
      },
    };
  });
}
