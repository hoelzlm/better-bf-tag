# ADR 0002 – Backend: Node.js/TypeScript vs. Python

- **Status:** Vorgeschlagen (Empfehlung: Node.js/TypeScript mit Fastify)
- **Datum:** 2026-10-07

## Kontext

Das Backend soll selbst gebaut und auf einem Hetzner-VPS betrieben werden. Es muss können:

1. REST-API mit sauberer **OpenAPI**-Spezifikation (daraus wird der Dart-Client generiert)
2. **WebSocket**-Broadcast an ca. 5–50 gleichzeitige Clients
3. **Zeitgesteuerte Jobs** (geplante Alarme), die einen Neustart überleben
4. **Push** über FCM HTTP v1 und APNs (HTTP/2, Token-Auth)
5. PostgreSQL mit Migrationen
6. Wenig Ressourcen und Betriebsaufwand (ein Container, kein Redis)

Zur Auswahl stehen Node.js und Python. Ein Dart-Backend (z. B. Serverpod) hätte den Vorteil
einer Sprache für alles, wurde aber auf Wunsch nicht weiter betrachtet.

## Kandidaten

### A) Node.js (24 LTS) + TypeScript

| Baustein | Bibliothek |
|----------|------------|
| HTTP-Framework | **Fastify** |
| Validierung + OpenAPI | `zod` + `fastify-type-provider-zod` + `@fastify/swagger` |
| WebSocket | `@fastify/websocket` (basiert auf `ws`) |
| DB / ORM / Migrationen | **Drizzle ORM** + `drizzle-kit` (alternativ Kysely) |
| Jobs | **pg-boss** (Job-Queue in PostgreSQL, unterstützt verzögerte Jobs und Singleton-Keys) |
| FCM | `firebase-admin` (`messaging().send`) |
| APNs | `@parse/node-apn` oder direkt `http2` + `jose` für den JWT |
| Passwörter | `argon2` |
| Tests | `vitest` |

### B) Python (3.13) + FastAPI

| Baustein | Bibliothek |
|----------|------------|
| HTTP-Framework | **FastAPI** + Uvicorn |
| Validierung + OpenAPI | Pydantic v2, OpenAPI ist eingebaut |
| WebSocket | FastAPI/Starlette WebSockets |
| DB / ORM / Migrationen | SQLAlchemy 2 (async) + **Alembic** |
| Jobs | **procrastinate** (Postgres-basiert) oder APScheduler mit SQLAlchemy-Jobstore |
| FCM | `firebase-admin` (Python-SDK, intern synchron, deshalb im Threadpool aufrufen) |
| APNs | `aioapns` |
| Passwörter | `argon2-cffi` |
| Tests | `pytest` + `httpx` |

## Bewertung

Skala: ++ sehr gut, + gut, o neutral, – schwächer

| Kriterium | Node/TS | Python | Anmerkung |
|-----------|:-------:|:------:|-----------|
| OpenAPI-Erzeugung | + | ++ | FastAPI bringt das von Haus aus mit; Fastify braucht Plugins, ist mit zod aber ebenfalls gut |
| WebSocket / Echtzeit | ++ | + | Node ist von Grund auf event-getrieben; in Python ist es möglich, aber man muss sync/async sauber trennen |
| Async-Ökosystem durchgängig | ++ | o | In Python sind manche Bibliotheken nur synchron (z. B. firebase-admin); in Node ist alles async |
| Geplante Jobs ohne Redis | ++ | + | pg-boss ist ausgereift und verbreitet; procrastinate ist gut, aber weniger verbreitet |
| Push (FCM/APNs) | + | + | beide mit offiziellem bzw. gepflegtem SDK |
| Datenbank / Migrationen | + | ++ | SQLAlchemy + Alembic ist sehr ausgereift; Drizzle ist jünger, aber typsicher und schlank |
| Typsicherheit | ++ | + | TS prüft zur Compile-Zeit; Python nur mit mypy/pyright und Disziplin |
| Ressourcenbedarf | + | + | beide ca. 60–150 MB RAM, für einen VPS irrelevant |
| Docker-Image | + | + | beide einfach |
| Lesbarkeit für Einsteiger | + | ++ | Python ist meist leichter zu lesen |
| Nähe zu Dart/Flutter | + | o | TS-Syntax und Typsystem liegen näher an Dart |

## Entscheidung (Vorschlag)

**Node.js/TypeScript mit Fastify, Drizzle und pg-boss.**

Begründung:
- Der Kern des Systems ist Echtzeit: Alarm auslösen, Push und WebSocket gleichzeitig verschicken,
  Status live verteilen. Dafür passt das durchgängig asynchrone Node-Ökosystem am besten.
- pg-boss deckt geplante Alarme mit Neustart-Sicherheit und Idempotenz (Singleton-Key) direkt ab,
  ohne Redis.
- Starke Typen von der Datenbank (Drizzle) über die API (zod) bis zur OpenAPI-Spezifikation
  verringern Fehler zwischen Backend und Dart-Client.

**Wichtigster Vorbehalt:** Die Unterschiede sind klein. Wenn du Python deutlich besser kennst als
TypeScript, nimm **FastAPI**. Gute Sprachkenntnis wiegt bei einem 2-Wochen-Plan mehr als die
genannten Vorteile. Architektur, API und Datenmodell in dieser Doku gelten für beide Varianten.

## Konsequenzen

- `backend/` wird ein Node-Projekt (pnpm, `tsconfig`, ESLint/Prettier).
- Das Backend-Image baut auf `node:24-alpine` bzw. `-slim` auf, multi-stage.
- `openapi.json` wird beim Build erzeugt und ins Repo committet. Ein Skript generiert daraus
  `packages/api_client`.
- Das Monorepo enthält zwei Toolchains (Dart und Node). Deshalb ein gemeinsames `Makefile` oder
  `justfile` im Root für übliche Befehle.
