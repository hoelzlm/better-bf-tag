# Dokumentation

Fachbegriffe (Glossar): [CONTEXT.md](../CONTEXT.md)

| Dokument | Inhalt |
|----------|--------|
| [01 – Vision und Scope](01-vision-scope.md) | Ziel, Rahmenbedingungen, MVP-Umfang, Nicht-Ziele |
| [02 – Architektur](02-architektur.md) | Komponenten, Datenflüsse, Tech-Stack |
| [03 – Datenmodell](03-datenmodell.md) | Tabellen, Status, Beziehungen |
| [04 – API](04-api.md) | REST-Endpunkte, WebSocket-Events, Authentifizierung |
| [05 – Alarmierung und Push](05-alarmierung-push.md) | Alarmablauf, FCM/APNs, Alarmton, Plattform-Einschränkungen |
| [06 – Clients](06-clients.md) | Admin, Monitor, Mobile-App: Screens und Funktionen |
| [07 – Deployment](07-deployment.md) | Hetzner-VPS, Docker Compose, TLS, Backups, Härtung |
| [08 – Store-Veröffentlichung](08-store-release.md) | Google Play und Apple App Store / TestFlight |
| [09 – Datenschutz](09-datenschutz.md) | DSGVO, Minderjährige, Datensparsamkeit |
| [10 – Roadmap](10-roadmap.md) | 2-Wochen-Plan bis zur ersten nutzbaren Version |

## Architecture Decision Records (ADR)

| ADR | Entscheidung | Status |
|-----|--------------|--------|
| [0001](adr/0001-monorepo.md) | Monorepo mit Dart Pub Workspaces | Angenommen |
| [0002](adr/0002-backend-sprache.md) | Backend: Node.js/TypeScript vs. Python | Vorgeschlagen (Node.js) |
| [0003](adr/0003-push.md) | Push über FCM (Android) und APNs direkt (iOS) | Vorgeschlagen |
| [0004](adr/0004-flutter-web.md) | Admin und Monitor als eine Flutter-Web-App | Vorgeschlagen |
| [0005](adr/0005-authentifizierung.md) | Login per QR-Code-Kopplung statt E-Mail für Personen | Vorgeschlagen |
| [0006](adr/0006-quittierung-statt-rueckmeldung.md) | Quittierung statt „komme / komme nicht“ | Angenommen |
| [0007](adr/0007-personen-dauerhaft-anonymisierung.md) | Personen dauerhaft, Anonymisierung nach 8 Wochen | Angenommen |

Neue ADRs nach dem Muster `adr/NNNN-titel.md` anlegen (Kontext → Entscheidung → Konsequenzen).

## Rahmenbedingungen (Stand 2026-10-07)

- Nur für die **eigene Jugendfeuerwehr**, also kein Multi-Tenant-Betrieb.
- Apple Developer Account ist vorhanden.
- Android über den **Google Play Store**, idealerweise innerhalb von 2 Wochen.
- Hosting auf einem **Hetzner-VPS** (EU).
- **Eigenes Backend**, kein Supabase oder Firebase als Datenbank.
