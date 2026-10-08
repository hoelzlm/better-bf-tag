import type { FastifyInstance, FastifyPluginAsync, FastifyRequest } from 'fastify';
import type { WebSocket } from 'ws';
import { eq } from 'drizzle-orm';
import { person } from '../db/schema.js';
import { verifyAccessToken } from '../access/tokens.js';
import type { Permission } from '../access/types.js';
import type { RealtimeEvent, RealtimeSubscriber } from './realtime.js';

/**
 * WebSocket transport `/ws` (ADR 0009). Registered directly on the
 * top-level app, not under `/api/v1`, and hidden from the OpenAPI spec.
 */
export const wsRoutes: FastifyPluginAsync = async fastify => {
  // Tracks every live connection so the `onClose` hook below can terminate
  // them immediately instead of relying on @fastify/websocket's default
  // `preClose` (which calls the graceful, handshake-based `socket.close()`
  // and could otherwise make `app.close()` linger in tests).
  const connections = new Set<WebSocket>();

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
      void handleConnection(fastify, socket, request, connections);
    }
  );
};

async function handleConnection(
  app: FastifyInstance,
  socket: WebSocket,
  request: FastifyRequest,
  connections: Set<WebSocket>
): Promise<void> {
  const query = request.query as Record<string, unknown>;
  const token = typeof query['token'] === 'string' ? query['token'] : undefined;

  if (!token) {
    socket.close(4401, 'unauthorized');
    return;
  }

  let permission: Permission;
  try {
    const claims = await verifyAccessToken({ config: app.config, clock: app.clock }, token);

    // ADR 0010 "Prüfung bei jeder Anfrage": the same person check requireAuth
    // does on every HTTP request applies at connection time for /ws too.
    const [found] = await app.db
      .select({ id: person.id, permission: person.permission, active: person.active })
      .from(person)
      .where(eq(person.id, claims.personId))
      .limit(1);
    if (!found || !found.active) {
      socket.close(4401, 'unauthorized');
      return;
    }
    permission = found.permission;
  } catch {
    socket.close(4401, 'unauthorized');
    return;
  }

  connections.add(socket);

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
    app.realtime.detach(subscriber);
  };

  socket.on('close', cleanup);
  socket.on('error', cleanup);
}
