import { loadConfig } from './config.js';
import { createDb, runMigrations, type Db } from './db/client.js';
import { buildApp, type AppDeps } from './app.js';
import { systemClock } from './clock.js';
import { noopPushSender } from './push/push-sender.js';

async function main(): Promise<void> {
  const config = loadConfig();

  const { db, pool } = createDb(config.DATABASE_URL);

  await runMigrations(db);

  const deps: AppDeps = {
    config,
    db: db as Db,
    pool,
    clock: systemClock,
    pushSender: noopPushSender,
  };

  const app = await buildApp(deps);

  const signals = ['SIGTERM', 'SIGINT'];
  for (const signal of signals) {
    process.on(signal, async () => {
      app.log.info({ signal }, 'Received shutdown signal');
      await app.close();
      await pool.end();
      process.exit(0);
    });
  }

  try {
    await app.listen({ port: config.PORT, host: config.HOST });
    app.log.info(`Server listening on ${config.HOST}:${config.PORT}`);
  } catch (err) {
    app.log.error(err, 'Failed to start server');
    await pool.end();
    process.exit(1);
  }
}

main();
