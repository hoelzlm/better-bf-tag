# ADR 0001 – Monorepo mit Dart Pub Workspaces

- **Status:** Angenommen
- **Datum:** 2026-10-07

## Kontext

Drei Flutter-Oberflächen (Admin, Monitor, Mobile), gemeinsamer Dart-Code, ein Backend und
Infrastruktur sollen zusammen versioniert werden. Eine Person entwickelt; API-Änderungen betreffen
meist Backend und Clients gleichzeitig.

## Entscheidung

- **Ein Git-Repository** für alles.
- Dart-Pakete werden über **Pub Workspaces** verbunden (Dart ≥ 3.6, `workspace:` im Root-`pubspec.yaml`).
  So gibt es ein gemeinsames Lockfile und eine Abhängigkeitsauflösung für alle Flutter-Projekte.
  **melos** kommt nur dazu, wenn Skripte über mehrere Pakete hinweg nötig werden.
- Admin und Monitor teilen sich **eine** Flutter-Web-App (`apps/web`), siehe ADR 0004.
- Das Backend liegt in `backend/` mit eigener Toolchain und ist nicht Teil des Pub Workspace.
- Ein Root-`justfile` oder `Makefile` bündelt die üblichen Befehle (`dev`, `test`, `gen-api`, `deploy`).

## Struktur

```
apps/mobile          Flutter iOS/Android
apps/web             Flutter Web (/admin, /monitor)
packages/core        Dart: Domain, Repositories, Realtime, Riverpod-Provider
packages/api_client  Dart: aus OpenAPI generiert (nicht von Hand ändern)
backend              API-Server
infra                Docker Compose, Caddy, Skripte
docs                 Dokumentation, ADRs
```

## Konsequenzen

- Eine API-Änderung samt Client-Anpassung geht in einem Commit.
- CI muss pfadbasiert filtern (Backend-Jobs nur bei Änderungen in `backend/**` usw.).
