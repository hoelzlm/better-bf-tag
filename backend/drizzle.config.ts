import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema.ts',
  out: './drizzle',
  migrations: {
    table: 'drizzle_migrations',
    schema: 'public',
  },
  dbCredentials: {
    url: 'postgres://bftag:bftag@localhost:5432/bftag',
  },
});
