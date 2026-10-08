# 01 — Grundgerüst: Administrator meldet sich im Web an

**What to build:** Ein Administrator öffnet die Web-App im Browser, meldet sich mit dem Bootstrap-Zugang aus der Server-Konfiguration an und sieht eine (noch leere) Lage. Darunter steht das komplette Grundgerüst: Backend mit PostgreSQL und Migrationen, Flutter-Monorepo (Pub Workspace) mit Web-App, gemeinsamem Paket und generiertem API-Client sowie die Test-Infrastruktur, auf der alle weiteren Tickets aufbauen.

**Blocked by:** None, aber die Backend-Sprache (ADR 0002) muss vorher entschieden werden.

**Status:** needs-info

> **needs-info:** Wartet auf die Entscheidung Node.js/TypeScript vs. Python (ADR 0002). Danach `Status: ready-for-agent` setzen.

- [ ] ADR 0002 ist entschieden und auf „Angenommen“ gesetzt
- [ ] Backend startet mit PostgreSQL per Docker Compose lokal; Migrationen laufen beim Start
- [ ] Health-Endpunkt antwortet, auch mit Prüfung der Datenbank
- [ ] Der erste Administrator wird aus der Server-Konfiguration angelegt, falls noch keiner existiert
- [ ] Web-Login mit Benutzername und Passwort (Argon2id): Access-Token 15 min, Refresh-Token als HttpOnly-Cookie, Refresh und Logout funktionieren; Rate-Limiting auf den Auth-Endpunkten
- [ ] Die OpenAPI-Spezifikation wird aus dem Backend erzeugt, der Dart-API-Client daraus generiert
- [ ] Flutter-Web-App mit Routen für Admin und Monitor (go_router); Login-Screen und leere Lage
- [ ] Test-Infrastruktur: Black-Box-Tests gegen das gestartete Backend mit echter PostgreSQL (Testcontainer); Push-Fake und steuerbare Uhr lassen sich beim Start einschleusen
- [ ] Tests: Login erfolgreich/fehlgeschlagen, Refresh, Logout, abgelaufenes Access-Token (über die steuerbare Uhr)
- [ ] CI führt Backend-Tests und Flutter-Analyse/Build aus (pfadbasiert gefiltert)
- [ ] Root-Befehle (just/make) für dev, test, gen-api

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
