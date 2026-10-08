import type { FastifyInstance, FastifyPluginAsync, FastifyRequest } from 'fastify';
import type { WebSocket } from 'ws';
import { and, eq, isNull } from 'drizzle-orm';
import { person, device } from '../db/schema.js';
import { verifyAccessToken } from '../access/tokens.js';
import type { Permission } from '../access/types.js';
import type { RealtimeEvent, RealtimeSubscriber } from './realtime.js';

/** Revokes matching live `/ws` connections (ADR 0010 `session.revoked`). */
export interface WsHub {
  revokeDevice(deviceId: string): void;
  revokePerson(personId: string): void;
}

declare module 'fastify' {
  interface FastifyInstance {
    wsHub: WsHub;
  }
}

interface ConnectionMeta {
  socket: WebSocket;
  personId: string;
  deviceId?: string;
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
 * `routes/persons.ts`) that also need to call `app.wsHub`.
 */
export function createWsPlugin(): { plugin: FastifyPluginAsync; hub: WsHub } {
  // Tracks every live connection so the `onClose` hook below can terminate
  // them immediately instead of relying on @fastify/websocket's default
  // `preClose` (which calls the graceful, handshake-based `socket.close()`
  // and could otherwise make `app.close()` linger in tests).
  const connections = new Set<WebSocket>();
  // Per-connection personId/deviceId, so session.revoked (ADR 0010) can
  // target exactly the connections of a revoked device or person.
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

  let permission: Permission;
  let personId: string;
  let deviceId: string | undefined;
  try {
    const claims = await verifyAccessToken({ config: app.config, clock: app.clock }, token);

    // ADR 0010 "Prüfung bei jeder Anfrage": the same person (and, for
    // device tokens, device) check requireAuth does on every HTTP request
    // applies at connection time for /ws too.
    const [found] = await app.db
      .select({ id: person.id, permission: person.permission, active: person.active })
      .from(person)
      .where(eq(person.id, claims.personId))
      .limit(1);
    if (!found || !found.active) {
      socket.close(4401, 'unauthorized');
      return;
    }

    if (claims.deviceId !== undefined) {
      const [deviceRow] = await app.db
        .select({ id: device.id })
        .from(device)
        .where(and(eq(device.id, claims.deviceId), isNull(device.revokedAt)))
        .limit(1);
      if (!deviceRow) {
        socket.close(4401, 'unauthorized');
        return;
      }
    }

    permission = found.permission;
    personId = found.id;
    deviceId = claims.deviceId;
  } catch {
    socket.close(4401, 'unauthorized');
    return;
  }

  connections.add(socket);
  meta.set(socket, { socket, personId, ...(deviceId !== undefined ? { deviceId } : {}) });

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
