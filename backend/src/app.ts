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

import type { Config } from './config.js';
import type { Db } from './db/client.js';
import type { Clock } from './clock.js';
import type { PushSender } from './push/push-sender.js';
import { createErrorHandler, createNotFoundHandler } from './errors.js';
import { healthRoutes } from './routes/health.js';

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
  }
}

export async function buildApp(deps: AppDeps): Promise<FastifyInstance> {
  const { config, db, pool, clock, pushSender } = deps;

  const app = Fastify({
    logger: {
      level: 'info',
    },
  });

  app.decorate('config', config);
  app.decorate('db', db);
  app.decorate('pool', pool);
  app.decorate('clock', clock);
  app.decorate('pushSender', pushSender);

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

  // Rate limiting (global)
  await app.register(fastifyRateLimit, {
    max: 100,
    timeWindow: '1 minute',
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

  // Register routes under /api/v1
  await app.register(async function routes(fastify) {
    await fastify.register(healthRoutes, { prefix: '/api/v1' });
  });

  return app;
}
