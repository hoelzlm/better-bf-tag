import type { FastifyInstance } from 'fastify';
import type { Pool } from 'pg';
import Fastify from 'fastify';
import {
  serializerCompiler,
  validatorCompiler,
  jsonSchemaTransform,
} from 'fastify-type-provider-zod';
import { fastifySwagger } from '@fastify/swagger';
import { fastifySwaggerUi } from '@fastify/swagger-ui';
import { fastifyCors } from '@fastify/cors';
import { fastifyCookie } from '@fastify/cookie';
import { fastifyRateLimit } from '@fastify/rate-limit';
import fastifyWebsocket from '@fastify/websocket';

import type { Config } from './config.js';
import type { Db } from './db/client.js';
import type { Clock } from './clock.js';
import type { PushSender } from './push/push-sender.js';
import { createErrorHandler, createNotFoundHandler, ApiError } from './errors.js';
import { healthRoutes } from './routes/health.js';
import { authRoutes } from './routes/auth.js';
import { meRoutes } from './routes/me.js';
import { vehicleRoutes } from './routes/vehicles.js';
import { personRoutes } from './routes/persons.js';
import { snapshotRoutes } from './routes/snapshot.js';
import { Realtime } from './realtime/realtime.js';
import { wsRoutes } from './realtime/ws.js';
import './access/authenticate.js';

export interface AppDeps {
  config: Config;
  db: Db;
  pool: Pool;
  clock: Clock;
  pushSender: PushSender;
}

declare module 'fastify' {
  interface FastifyInstance {
    config: Config;
    db: Db;
    pool: Pool;
    clock: Clock;
    pushSender: PushSender;
    realtime: Realtime;
  }
}

export async function buildApp(deps: AppDeps): Promise<FastifyInstance> {
  const { config, db, pool, clock, pushSender } = deps;

  const app = Fastify({
    logger: {
      level: 'info',
    },
    trustProxy: config.TRUST_PROXY,
  });

  app.decorate('config', config);
  app.decorate('db', db);
  app.decorate('pool', pool);
  app.decorate('clock', clock);
  app.decorate('pushSender', pushSender);
  app.decorate('realtime', new Realtime(db, clock));

  // Zod type provider
  app.setValidatorCompiler(validatorCompiler);
  app.setSerializerCompiler(serializerCompiler);

  // Error handler
  createErrorHandler(app);
  createNotFoundHandler(app);

  // CORS
  await app.register(fastifyCors, {
    origin: config.CORS_ORIGINS,
    credentials: true,
  });

  // Cookie
  await app.register(fastifyCookie, {
    secret: config.JWT_SECRET,
    hook: 'onRequest',
  });

  // Rate limiting: not applied globally; individual routes (auth) opt in via
  // their route `config.rateLimit`, keyed by IP.
  await app.register(fastifyRateLimit, {
    global: false,
    errorResponseBuilder: () =>
      new ApiError(429, 'rate_limited', 'Zu viele Versuche. Bitte später erneut versuchen.'),
  });

  // Swagger/OpenAPI
  await app.register(fastifySwagger, {
    openapi: {
      openapi: '3.0.3',
      info: {
        title: 'better-bf-tag API',
        version: '0.1.0',
      },
    },
    transform: jsonSchemaTransform,
  });

  await app.register(fastifySwaggerUi, {
    routePrefix: '/docs',
    uiConfig: {
      docExpansion: 'list',
      deepLinking: false,
    },
  });

  // WebSocket transport (ADR 0009): `/ws`, not under `/api/v1`, hidden from
  // the OpenAPI spec (see wsRoutes).
  await app.register(fastifyWebsocket);
  await app.register(wsRoutes);

  // Register routes under /api/v1
  await app.register(async function routes(fastify) {
    await fastify.register(healthRoutes, { prefix: '/api/v1' });
    await fastify.register(authRoutes, { prefix: '/api/v1' });
    await fastify.register(meRoutes, { prefix: '/api/v1' });
    await fastify.register(vehicleRoutes, { prefix: '/api/v1' });
    await fastify.register(personRoutes, { prefix: '/api/v1' });
    await fastify.register(snapshotRoutes, { prefix: '/api/v1' });

    // The generated spec is served for the Dart client codegen; hidden from
    // the spec itself to avoid a self-referential entry.
    fastify.get('/api/v1/openapi.json', { schema: { hide: true } }, async () => app.swagger());
  });

  return app;
}
