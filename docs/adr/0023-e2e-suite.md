# ADR 0023 – E2E-Suite gegen den Produktions-Stack (`just e2e`)

- **Status:** Angenommen
- **Datum:** 2026-10-11

## Kontext

Ticket 18 verlangt einen reproduzierbaren End-to-End-Test gegen die echten Images aus `infra/`
(Caddy, HTTPS, WebSocket) – API und Web-UI. Vorlagen liegen als Wegwerf-Code in
`.scratch/mvp/e2e-seed/`. Offen waren Ort, Laufzeit, Abhängigkeiten, Zusammenspiel mit
`infra/smoke-test.sh` und die Einbindung in CI.

## Entscheidung

- **Ort:** eigenes Verzeichnis `e2e/` im Repo-Root mit eigenem `package.json`
  (`"type": "module"`, `"private": true`, `engines.node >= 24`, einzige Abhängigkeit `ws`,
  `package-lock.json` eingecheckt). Kein TypeScript, kein Test-Framework – schlichte
  `.mjs`-Skripte mit `PASS`/`FAIL`-Zeilen und Exit-Code ≠ 0 bei mindestens einem Fehlschlag.
- **Dateien:** `e2e/run.sh` (Orchestrierung), `e2e/lib.mjs` (gemeinsame Helfer: `ok()`,
  HTTP-Aufruf, Ergebniszählung), `e2e/api.mjs` (API-Szenario), `e2e/ui.mjs` (Web-UI über
  Chrome DevTools Protocol). Konfiguration nur über Umgebungsvariablen, keine absoluten Pfade.
- **Stack:** `e2e/run.sh` baut die Images wie `infra/smoke-test.sh` (Tag `e2e`,
  `SKIP_WEB_BUILD=1` überspringt den Flutter-Build), startet `infra/docker-compose.yml` unter dem
  Compose-Projekt `bftag-e2e` auf den Ports 28080/28443 (kollidiert nicht mit dem Smoke-Test
  auf 18080/18443) mit zufälligen Secrets in einer `mktemp`-`.env` und räumt per `trap … EXIT`
  **immer** mit `down -v --remove-orphans` ab.
- **Rate-Limit:** `infra/docker-compose.yml` reicht `AUTH_RATE_LIMIT_MAX`
  (Default 10, wie im Backend) an das Backend durch; `run.sh` setzt `AUTH_RATE_LIMIT_MAX=1000`.
- **UI-Test:** Chrome headless (`CHROME_BIN`, Default `google-chrome`) mit `--no-sandbox`,
  `--ignore-certificate-errors` und Wegwerf-Profil (`mktemp -d`), zufälliger freier
  Remote-Debugging-Port. Flutter-Semantics per Klick auf `flt-semantics-placeholder`;
  Buttons über `role=button`. Text-Vergleiche case-insensitiv und ß/SS-tolerant.
  Die Alarmierung während des UI-Laufs löst `ui.mjs` selbst per API aus (kein `alarm.sh`).
- **Artefakte:** Screenshots und Logs nach `E2E_ARTIFACT_DIR` (Default `e2e/artifacts/`,
  in `.gitignore`). Bei Fehlschlag zusätzlich `docker compose logs` dorthin.
- **Selbsttest:** `E2E_FORCE_FAIL=1` lässt `api.mjs` einen absichtlich falschen Check
  ausführen – damit ist prüfbar, dass ein roter Check `just e2e` scheitern lässt.
- **CI:** eigener Workflow `.github/workflows/e2e.yml`, nur `pull_request` nach `main` und
  `workflow_dispatch`, `timeout-minutes: 15`, Ziel-Laufzeit < ~6 min; `e2e/artifacts/` wird als
  Artifact hochgeladen. `just ci` enthält den E2E-Lauf **nicht** (braucht Docker und Chrome).
- **Nicht abgedeckt:** Mobile-App auf Gerät/Emulator und echte Push-Zustellung (FCM/APNs).

## Konsequenzen

- Ein grüner Lauf belegt das Zusammenspiel von Caddy, Backend, Datenbank und Web-Build.
- Der UI-Test hängt an Flutter-Semantics-Details; Änderungen an Beschriftungen können ihn brechen.
- `infra/smoke-test.sh` bleibt als schneller Infrastruktur-Check bestehen.
