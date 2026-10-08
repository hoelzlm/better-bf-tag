import type { FastifyInstance, FastifyPluginAsync, FastifyRequest } from 'fastify';
import type { WebSocket } from 'ws';
import { verifyAccessToken } from '../access/tokens.js';
import { resolvePrincipal } from '../access/authenticate.js';
import type { Permission } from '../access/types.js';
import type { RealtimeEvent, RealtimeSubscriber } from './realtime.js';

/** Revokes matching live `/ws` connections (ADR 0010/0012 `session.revoked`). */
export interface WsHub {
  revokeDevice(deviceId: string): void;
  revokePerson(personId: string): void;
  revokeMonitor(monitorId: string): void;
}

declare module 'fastify' {
  interface FastifyInstance {
    wsHub: WsHub;
  }
}

interface ConnectionMeta {
  socket: WebSocket;
  personId?: string;
  deviceId?: string;
  monitorId?: string;
}

/**
 * Builds the `/ws` plugin together with its `WsHub`. The hub and the
 * connection-tracking maps live in this outer closure (not inside the
 * plugin function's own body) specifically so `buildApp` can
 * `app.decorate('wsHub', hub)` on the *top-level* app instance before
 * registering the plugin: Fastify's encapsulation means a decoration made
 * with `fastify.decorate(...)` from inside a registered plugin is only
 * visible to that plugin's own context and its children, never to sibling
 * route registrations (e.g. `routes/devices.ts`, `routes/auth.ts`,
 * `routes/persons.ts`, `routes/monitors.ts`) that also need to call
 * `app.wsHub`.
 */
export function createWsPlugin(): { plugin: FastifyPluginAsync; hub: WsHub } {
  // Tracks every live connection so the `onClose` hook below can terminate
  // them immediately instead of relying on @fastify/websocket's default
  // `preClose` (which calls the graceful, handshake-based `socket.close()`
  // and could otherwise make `app.close()` linger in tests).
  const connections = new Set<WebSocket>();
  // Per-connection personId/deviceId/monitorId, so session.revoked (ADR
  // 0010/0012) can target exactly the connections of a revoked device,
  // person, or monitor.
  const meta = new Map<WebSocket, ConnectionMeta>();

  function sendRevoked(socket: WebSocket): void {
    if (socket.readyState === socket.OPEN) {
      socket.send(JSON.stringify({ type: 'session.revoked' }));
    }
    socket.close(4403, 'revoked');
  }

  const hub: WsHub = {
    revokeDevice(deviceId: string): void {
      for (const m of meta.values()) {
        if (m.deviceId === deviceId) {
          sendRevoked(m.socket);
        }
      }
    },
    revokePerson(personId: string): void {
      for (const m of meta.values()) {
        if (m.personId === personId) {
          sendRevoked(m.socket);
        }
      }
    },
    revokeMonitor(monitorId: string): void {
      for (const m of meta.values()) {
        if (m.monitorId === monitorId) {
          sendRevoked(m.socket);
        }
      }
    },
  };

  /**
   * WebSocket transport `/ws` (ADR 0009). Registered directly on the
   * top-level app, not under `/api/v1`, and hidden from the OpenAPI spec.
   */
  const plugin: FastifyPluginAsync = async fastify => {
    fastify.addHook('onClose', (_instance, done) => {
      for (const socket of connections) {
        socket.terminate();
      }
      done();
    });

    fastify.get(
      '/ws',
      { websocket: true, schema: { hide: true } },
      (socket: WebSocket, request: FastifyRequest) => {
        void handleConnection(fastify, socket, request, connections, meta);
      }
    );
  };

  return { plugin, hub };
}

async function handleConnection(
  app: FastifyInstance,
  socket: WebSocket,
  request: FastifyRequest,
  connections: Set<WebSocket>,
  meta: Map<WebSocket, ConnectionMeta>
): Promise<void> {
  const query = request.query as Record<string, unknown>;
  const token = typeof query['token'] === 'string' ? query['token'] : undefined;

  if (!token) {
    socket.close(4401, 'unauthorized');
    return;
  }

  // `/ws` is an opt-in monitor route (ADR 0012): both Person and Monitor
  // tokens are accepted here, with the same DB re-check requireAuth does
  // on every HTTP request ("Prüfung bei jeder Anfrage").
  let permission: Permission;
  let personId: string | undefined;
  let deviceId: string | undefined;
  let monitorId: string | undefined;
  try {
    const claims = await verifyAccessToken({ config: app.config, clock: app.clock }, token);
    const principal = await resolvePrincipal({ db: app.db }, claims);

    if (principal.kind === 'monitor') {
      monitorId = principal.monitorId;
      // Monitors see what Mannschaft sees (ADR 0012); reusing the
      // permission-based audience filter below with 'crew' is exact as
      // long as no event restricts audience below crew.
      permission = 'crew';
    } else {
      personId = principal.personId;
      deviceId = principal.deviceId;
      permission = principal.permission;
    }
  } catch {
    socket.close(4401, 'unauthorized');
    return;
  }

  connections.add(socket);
  meta.set(socket, {
    socket,
    ...(personId !== undefined ? { personId } : {}),
    ...(deviceId !== undefined ? { deviceId } : {}),
    ...(monitorId !== undefined ? { monitorId } : {}),
  });

  // Delivers every event to this connection in `seq` order. Events whose
  // `audience` excludes this connection's permission become a `skip`
  // message instead, so `seq` stays gap-free without leaking the event's
  // data (ADR 0009). No route in this ticket sets `audience` — every event
  // goes to everyone — so the skip path has no HTTP-level test; it is only
  // exercised by code review here.
  const subscriber: RealtimeSubscriber = {
    send(event: RealtimeEvent) {
      if (socket.readyState !== socket.OPEN) return;
      if (event.audience && !event.audience(permission)) {
        socket.send(JSON.stringify({ seq: event.seq, type: 'skip' }));
        return;
      }
      socket.send(
        JSON.stringify({ seq: event.seq, type: event.type, at: event.at, data: event.data })
      );
    },
  };

  // Reads `seq` and registers the subscriber atomically under the Realtime
  // mutex (Realtime.attach), so no event emitted concurrently with the
  // attach can be missed or duplicated relative to this `hello`.
  const seq = await app.realtime.attach(subscriber);
  socket.send(JSON.stringify({ type: 'hello', seq }));

  let awaitingPong = false;
  const heartbeat = setInterval(() => {
    if (awaitingPong) {
      socket.terminate();
      return;
    }
    awaitingPong = true;
    socket.ping();
    void app.realtime.currentSeq().then(currentSeq => {
      if (socket.readyState === socket.OPEN) {
        socket.send(JSON.stringify({ type: 'heartbeat', seq: currentSeq }));
      }
    });
  }, app.config.WS_HEARTBEAT_MS);

  socket.on('pong', () => {
    awaitingPong = false;
  });

  const cleanup = (): void => {
    clearInterval(heartbeat);
    connections.delete(socket);
    meta.delete(socket);
    app.realtime.detach(subscriber);
  };

  socket.on('close', cleanup);
  socket.on('error', cleanup);
}
