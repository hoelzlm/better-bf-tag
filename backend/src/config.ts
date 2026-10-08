import { z } from 'zod';

/**
 * Strict string -> boolean parsing for env vars.
 *
 * z.coerce.boolean() is a trap here: it coerces via `Boolean(value)`, so
 * *any* non-empty string (including the string "false") becomes `true`.
 * We only want 'true' / '1' to mean true; everything else (including
 * unset) means false/the default.
 */
function strictBooleanEnv(defaultValue: boolean) {
  return z
    .string()
    .optional()
    .transform(value => {
      if (value === undefined) return defaultValue;
      return value === 'true' || value === '1';
    });
}

export const configSchema = z.object({
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().int().positive().default(8080),
  HOST: z.string().default('0.0.0.0'),
  JWT_SECRET: z.string().min(32),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(900),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(14),
  COOKIE_SECURE: strictBooleanEnv(false),
  TRUST_PROXY: strictBooleanEnv(false),
  CORS_ORIGINS: z
    .string()
    .default('')
    .transform(s => (s ? s.split(',').map(o => o.trim()) : [])),
  AUTH_RATE_LIMIT_MAX: z.coerce.number().int().positive().default(10),
  AUTH_RATE_LIMIT_WINDOW_MS: z.coerce.number().int().positive().default(60000),
  WS_HEARTBEAT_MS: z.coerce.number().int().positive().default(25000),
  PAIRING_CODE_TTL_HOURS: z.coerce.number().int().positive().default(24),
  BOOTSTRAP_ADMIN_USERNAME: z.string().optional(),
  BOOTSTRAP_ADMIN_PASSWORD: z.string().min(8).optional(),
  OWN_FIRE_DEPARTMENT_NAME: z.string().default('Eigene Feuerwehr'),
});

export type Config = z.infer<typeof configSchema>;

export function loadConfig(env: Record<string, string | undefined> = process.env): Config {
  return configSchema.parse(env);
}
