# 18 — E2E-Suite (`just e2e`) und Doku-Abgleich

**What to build:** Ein reproduzierbarer End-to-End-Test, der den echten Ablauf eines BF-Tags gegen den laufenden Produktions-Stack (Images aus `infra/`, Caddy, HTTPS, WebSocket) prüft — API und Web-UI. Dazu zwei Doku-Abweichungen beheben, die beim manuellen E2E-Lauf am 2026-10-10 aufgefallen sind.

**Blocked by:** –

**Status:** ready-for-agent

## Ausgangslage

Manueller E2E-Lauf auf `main` (`aaf46e7`) war grün: API-Szenario 102/102 (Dev- und Prod-Stack), Web-UI 17/18 (der eine Fehler war ein Regex im Test, s. u.). Die Skripte dieses Laufs liegen als Vorlage in `.scratch/mvp/e2e-seed/`:

- `scenario.mjs` — API-Szenario: Stammdaten, Rechte je Berechtigung, BF-Tag, Schicht/Besatzung, Geräte- und Monitor-Kopplung, Token-Rotation, Erstalarm (Idempotenz, Doppelalarm-Schutz), Quittierung, Fahrzeugstatus (inkl. 7/8 nur RTW/KTW), geplante + zeitgesteuerte Alarmierung (Scheduler), Abschluss, Verwerfen, WebSocket (`hello`, Events, Drehbuch-Filter, lückenlose `seq`, 4401/4403), BF-Tag beenden + Anonymisieren.
- `ui.mjs` — Headless Chrome über CDP + Flutter-Semantics: Login, alle 8 Admin-Seiten, Monitor koppeln, Live-Alarm auf dem Monitor.
- `alarm.sh` — löst während des UI-Laufs einen Alarm per API aus.

Die Vorlagen haben hart kodierte Pfade (`/home/markus/...`) und sind Wegwerf-Code — übernehmen, aufräumen, nicht 1:1 einchecken.

## Aufgaben

- [ ] `e2e/` (oder `infra/e2e/`) mit API-Szenario und UI-Test, Node ≥ 24, `ws` als Abhängigkeit; keine absoluten Pfade
- [ ] `just e2e`: baut die Images (wie `infra/smoke-test.sh`, `SKIP_WEB_BUILD` respektieren), startet den Stack unter eigenem Compose-Projekt mit zufälligen Secrets, führt API- und UI-Test aus, räumt **immer** ab (`trap`)
- [ ] Login-Rate-Limit für den Testlauf hochsetzen (`AUTH_RATE_LIMIT_MAX` per `.env`), sonst laufen wiederholte Läufe in 429
- [ ] UI-Test: Flutter-Semantics per Klick auf `flt-semantics-placeholder` aktivieren; Buttons über `role=button` suchen (die Überschrift „Anmelden“ hat dasselbe Label wie der Button); Monitor zeigt das Stichwort in Großbuchstaben („GROSSBRAND“) — case-insensitiv und ß/SS-tolerant vergleichen
- [ ] Chrome headless mit `--no-sandbox` und Wegwerf-Profil (`--user-data-dir` in `mktemp -d`); lokal fehlt der Chrome-Sandbox wegen AppArmor die Berechtigung
- [ ] Screenshots bei Fehlschlag in ein Artefakt-Verzeichnis
- [ ] CI: eigener Job (z. B. in `backend.yml` oder neues `e2e.yml`) nur für PRs nach `main` und `workflow_dispatch`, Laufzeit < ~6 min; Screenshots als Artifact hochladen
- [ ] Doku: `docs/04-api.md` listet `GET/POST/PATCH/DELETE /fire-departments[/{id}]`, die Route gibt es nicht (404). Laut Spec („Weitere Feuerwehren im UI“ = später) ist das gewollt → Zeile in den Abschnitt „Später“ verschieben bzw. als „später“ markieren
- [ ] Doku: `README.md` sagt noch „Konzeptphase – es gibt noch keinen Code“ → Status aktualisieren, `just e2e`, `just infra-smoke`, `just infra-backup-test` in die Befehlstabelle
- [ ] Nicht abgedeckt und so in `docs/` vermerken: Mobile-App auf Gerät/Emulator und echte Push-Zustellung (braucht FCM/APNs, siehe GitHub #21/#22/#26)

## Akzeptanzkriterien

- `just e2e` läuft lokal zweimal hintereinander grün, ohne zurückbleibende Container/Volumes (`docker ps -a`, `docker volume ls` prüfen)
- Ein absichtlich kaputter Check (z. B. erwarteter Status geändert) lässt `just e2e` mit Exit ≠ 0 scheitern
- `just ci` bleibt grün; der neue CI-Job ist grün
