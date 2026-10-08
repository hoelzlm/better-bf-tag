import { PostgreSqlContainer, type StartedPostgreSqlContainer } from '@testcontainers/postgresql';
import type { GlobalSetupContext } from 'vitest/node';

declare module 'vitest' {
  export interface ProvidedContext {
    pgAdminUrl: string;
  }
}

export default async function setup(project: GlobalSetupContext): Promise<() => Promise<void>> {
  const container: StartedPostgreSqlContainer = await new PostgreSqlContainer(
    'postgres:17'
  ).start();

  project.provide('pgAdminUrl', container.getConnectionUri());

  return async () => {
    await container.stop();
  };
}
