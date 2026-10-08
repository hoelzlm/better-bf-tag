# ADR 0008 – Konventionen für das Grundgerüst (Backend, Tests, Web-Login, Codegen)

- **Status:** Angenommen
- **Datum:** 2026-10-08

## Kontext

Ticket 01 legt das Grundgerüst an. Einige Punkte lassen ADR 0002 und das Ticket offen, oder sie
passen nicht zur lokalen Umgebung (kein Java, kein pnpm installiert, Node 26 lokal). Alle
weiteren Tickets bauen auf diesen Konventionen auf.

## Entscheidung

### Backend-Projekt

- **npm** statt pnpm (kein Extra-Tool, `package-lock.json` wird committet). ESM (`"type": "module"`),
  TypeScript strict, `tsx` für `dev`, `tsc` für den Build nach `dist/`, `vitest` für Tests.
- Node-Version: `engines.node >= 24`; das Docker-Image nutzt `node:24-slim` (multi-stage).
- Datenbanktreiber `pg` (node-postgres) mit Drizzle. Migrationen erzeugt `drizzle-kit generate`
  als SQL nach `backend/drizzle/`; sie werden committet und beim Start mit dem Drizzle-Migrator
  ausgeführt.
- Konfiguration nur über Umgebungsvariablen, geprüft mit zod in `backend/src/config.ts`.
- Port 8080. Alle Routen unter `/api/v1`.
- Fehlerformat überall `{ "error": { "code", "message" } }`, auch für Validierung (400,
  `validation_error`), 401 `unauthorized`, 404 `not_found`, 429 `rate_limited`.

### Austauschpunkte (Dependency Injection)

- `buildApp(deps)` in `backend/src/app.ts` erzeugt die Fastify-Instanz, ohne zu lauschen.
  `deps = { config, db, clock, pushSender }`. `backend/src/server.ts` verdrahtet die echten
  Implementierungen, führt Migrationen und Bootstrap aus und lauscht.
- `Clock` (`now(): Date`) – einzige Zeitquelle. JWT-Prüfung und Ablaufzeiten verwenden sie
  (deshalb `jose` statt `@fastify/jwt`: `jwtVerify(..., { currentDate })`).
- `PushSender` – nur die Schnittstelle und ein Noop für den Betrieb; echte Anbieter in Ticket 09.

### Web-Sitzung

- Neue Tabelle `web_session` (id, person_id, refresh_token_hash, created_at, expires_at,
  revoked_at). Das Refresh-Token ist ein zufälliges opakes Token (32 Byte, base64url); gespeichert
  wird nur sein SHA-256-Hash. Jeder Refresh ersetzt den Hash in derselben Zeile (Rotation); ein
  altes Token passt danach auf keine Zeile und wird mit 401 abgelehnt. Logout setzt `revoked_at`.
- Refresh-Laufzeit Web: 14 Tage (konfigurierbar). Access-Token: JWT HS256, 15 min,
  Claims `sub` (Person-ID) und `permission`.
- Cookie `bftag_refresh`: HttpOnly, SameSite=Strict, Path=`/api/v1/auth`, `Secure` per
  Konfiguration (lokal aus). Das Access-Token steht nur im Speicher des Web-Clients.
- Lokal laufen Web-App und Backend auf verschiedenen Ports; CORS mit Credentials für die
  konfigurierten Origins (`CORS_ORIGINS`). In Produktion liefert Caddy beides unter einer Domain.
- Bootstrap: Fehlt eine eigene Feuerwehr, wird sie angelegt. Existiert keine Person mit
  Berechtigung Administrator, wird eine aus `BOOTSTRAP_ADMIN_USERNAME`/`BOOTSTRAP_ADMIN_PASSWORD`
  angelegt (Personentyp Betreuer).

### Tests

- Black-Box über HTTP: Die Tests starten das Backend im Testprozess mit `buildApp` und
  `listen({ port: 0 })` und sprechen es nur per `fetch` an. Eine PostgreSQL 17 läuft über
  Testcontainers (einmal pro Testlauf, vitest `globalSetup`), jede Testdatei bekommt eine eigene
  frische Datenbank.
- Einzige Ausnahme vom Black-Box-Prinzip: Datenbank-Constraints, die die API (noch) nicht
  erreichen kann, dürfen per SQL geprüft werden.
- Testhilfen liegen in `backend/test/support/`: `FakeClock`, `RecordingPushSender`, `startTestApp`.

### Codegen und Monorepo-Befehle

- `backend/openapi.json` wird per `npm run openapi` aus der App erzeugt und committet; CI prüft,
  dass sie aktuell ist.
- Der Dart-Client wird mit dem Docker-Image `openapitools/openapi-generator-cli` erzeugt
  (Generator `dart-dio`, kein lokales Java nötig) und danach mit `build_runner` vervollständigt.
  Paketname `bftag_api_client`. Generierter Code wird committet.
- Root-`justfile` mit `dev`, `test`, `gen-api` (und Hilfsrezepten).
- Lokale Entwicklung: `compose.yaml` im Repo-Root startet `db` (postgres:17) und `backend`.
  Die Compose-Datei für den VPS entsteht getrennt in `infra/` (Ticket 15).
- Dart-Paketnamen: `bftag_web` (apps/web), `bftag_core` (packages/core), `bftag_api_client`.

## Konsequenzen

- Abweichung von ADR 0002 (pnpm) ist bewusst; ein späterer Wechsel betrifft nur `backend/`.
- Web- und Geräte-Sitzungen liegen in getrennten Tabellen (`web_session` bzw. `device`,
  `monitor_display`). Das Sperren eines Geräts berührt keine Web-Sitzung.
- `gen-api` setzt einen laufenden Docker-Daemon voraus.
