# better-bf-tag

Eigene Alarm- und Planungssoftware für den **Berufsfeuerwehrtag (BF-Tag)** unserer Jugendfeuerwehr.
Inspiriert von [bf-tag.de](https://bf-tag.de), aber mit kleinerem Funktionsumfang, eigenem Backend
und einer Android-App im Play Store.

> **Status:** Konzeptphase – es gibt noch keinen Code, nur Dokumentation und die Monorepo-Struktur.

## Bestandteile

| Teil | Technik | Zweck |
|------|---------|-------|
| `apps/web` | Flutter Web | Admin-Oberfläche (`/admin`) und Alarmmonitor (`/monitor`) |
| `apps/mobile` | Flutter (iOS + Android) | Push-Alarm, Rückmeldung, Fahrzeugstatus |
| `backend` | Node.js/TypeScript **oder** Python (siehe [ADR 0002](docs/adr/0002-backend-sprache.md)) | REST-API, WebSocket, Push, geplante Alarme |
| `packages/core` | Dart | Gemeinsame Logik für alle Flutter-Apps (State, Repositories, Realtime) |
| `packages/api_client` | Dart (generiert) | Aus der OpenAPI-Spezifikation generierter API-Client |
| `infra` | Docker Compose, Caddy | Deployment auf einem Hetzner-VPS |

## Repository-Struktur

```
better-bf-tag/
├── apps/
│   ├── mobile/          # Flutter-App für iOS und Android
│   └── web/             # Flutter Web: Admin und Monitor
├── backend/             # API-Server
├── packages/
│   ├── api_client/      # generierter Dart-Client (OpenAPI)
│   └── core/            # gemeinsame Dart-Logik
├── infra/               # Docker Compose, Caddy, Backup-Skripte
└── docs/                # Konzept, Architektur, ADRs
```

## Dokumentation

Einstieg: [docs/README.md](docs/README.md)

## Wichtiger Hinweis

Die Software dient **ausschließlich der Übung bzw. Simulation** im Rahmen der Jugendfeuerwehr.
Sie ist **nicht** für echte Einsätze oder den Echtbetrieb einer Feuerwehr gedacht.
