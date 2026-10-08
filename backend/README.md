# better-bf-tag Backend

Fastify + TypeScript + Drizzle ORM + PostgreSQL backend for the BF-Tag application.

## Quick Start (Docker Compose)

```bash
# From repo root
docker compose up -d --build

# Health check
curl http://localhost:8080/api/v1/health
```

The backend will be available at `http://localhost:8080/api/v1` with Swagger UI at `http://localhost:8080/docs`.

## Local Development (without Docker)

### Prerequisites

- Node.js 24+
- PostgreSQL 17

### Setup

```bash
cd backend
npm ci
```

Create a `.env` file in `backend/` with:

```env
DATABASE_URL=postgres://user:password@localhost:5432/dbname
JWT_SECRET=your-secret-at-least-32-characters-long
# Optional overrides
PORT=8080
HOST=0.0.0.0
COOKIE_SECURE=false
CORS_ORIGINS=http://localhost:8081
```

### Run

```bash
# Development with hot reload
npm run dev

# Production build
npm run build
npm start
```

## Commands

| Command               | Description                                  |
| --------------------- | -------------------------------------------- |
| `npm run dev`         | Start dev server with hot reload (tsx watch) |
| `npm run build`       | Compile TypeScript to `dist/`                |
| `npm start`           | Run compiled production server               |
| `npm run typecheck`   | Type-check without emitting                  |
| `npm run lint`        | Run ESLint + Prettier check                  |
| `npm run test`        | Run tests (vitest)                           |
| `npm run db:generate` | Generate Drizzle migrations to `drizzle/`    |

## Project Structure

```
backend/
├── src/
│   ├── config.ts          # Environment config (zod)
│   ├── clock.ts           # Clock interface (DI)
│   ├── push/push-sender.ts # Push notifications (DI)
│   ├── db/
│   │   ├── schema.ts      # Drizzle schema
│   │   └── client.ts      # DB pool + migrations
│   ├── errors.ts          # ApiError + Fastify error handler
│   ├── app.ts             # Fastify app factory (buildApp)
│   ├── routes/
│   │   └── health.ts      # GET /api/v1/health
│   └── server.ts          # Entry point
├── drizzle/               # Generated SQL migrations (committed)
├── dist/                  # Compiled output (gitignored)
├── package.json
├── tsconfig.json
├── Dockerfile
└── .dockerignore
```

## Database Migrations

Migrations are generated with `drizzle-kit generate` and committed to `backend/drizzle/`. They run automatically on server startup via `runMigrations()`.

To generate new migrations after schema changes:

```bash
cd backend
npm run db:generate
git add drizzle/
```

## Configuration

All config via environment variables (validated by zod in `src/config.ts`):

| Variable                    | Required | Default          | Description                      |
| --------------------------- | -------- | ---------------- | -------------------------------- |
| `DATABASE_URL`              | yes      | -                | PostgreSQL connection string     |
| `PORT`                      | no       | 8080             | HTTP port                        |
| `HOST`                      | no       | 0.0.0.0          | Bind address                     |
| `JWT_SECRET`                | yes      | -                | HS256 signing key (min 32 chars) |
| `ACCESS_TOKEN_TTL_SECONDS`  | no       | 900              | Access token lifetime            |
| `REFRESH_TOKEN_TTL_DAYS`    | no       | 14               | Refresh token lifetime           |
| `COOKIE_SECURE`             | no       | false            | Secure flag on refresh cookie    |
| `CORS_ORIGINS`              | no       | []               | Comma-separated allowed origins  |
| `AUTH_RATE_LIMIT_MAX`       | no       | 10               | Auth endpoint rate limit         |
| `AUTH_RATE_LIMIT_WINDOW_MS` | no       | 60000            | Auth rate limit window           |
| `BOOTSTRAP_ADMIN_USERNAME`  | no       | -                | Initial admin username           |
| `BOOTSTRAP_ADMIN_PASSWORD`  | no       | -                | Initial admin password (min 8)   |
| `OWN_FIRE_DEPARTMENT_NAME`  | no       | Eigene Feuerwehr | Name of own fire department      |
