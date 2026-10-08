# ADR 0010 – Personenverwaltung, Kopplungscodes, Geräte-Sitzungen, Sperre

- **Status:** Angenommen
- **Datum:** 2026-10-08

## Kontext

Ticket 04 setzt ADR 0005 für Personen um (Ticket 03 danach für Monitore). Offen waren: Format und
Lebenszyklus der Kopplungscodes, die Endpunkte für gekoppelte Geräte, wie eine Sperre „sofort“
wirkt, wer einen Web-Zugang haben darf, und wie die App gebaut wird.

## Entscheidung

### Personen

- `POST /persons`, `GET /persons`, `GET /persons/{id}`, `PATCH /persons/{id}` – nur Administrator.
  **Kein DELETE** (ADR 0007): `active=false` deaktiviert. Neue Personen gehören zur eigenen
  Feuerwehr; andere Feuerwehren kommen später.
- Administrator nur bei Personentyp Betreuer: DB-Check (besteht) **und** API-Prüfung mit 400
  `admin_requires_supervisor`.
- Die letzte aktive Person mit Berechtigung Administrator kann weder deaktiviert noch herabgestuft
  werden: 409 `last_admin`.
- **Web-Zugang** (`username` + Passwort, Argon2id, Passwort ≥ 8 Zeichen) nur für Einsatzvorbereitung,
  Leitstelle, Administrator. Gesetzt per `PUT /persons/{id}/web-access { username, password }`,
  entfernt per `DELETE /persons/{id}/web-access` (widerruft alle Web-Sitzungen). Für Mannschaft:
  400 `web_access_not_allowed`. Benutzername schon vergeben: 409 `username_taken`. Wird eine
  Person auf Mannschaft herabgestuft, wird ihr Web-Zugang entfernt.
- `POST /auth/login` und `/auth/refresh` lehnen Personen mit Berechtigung Mannschaft ab
  (wie falsche Zugangsdaten).
- Deaktivieren widerruft alle Web-Sitzungen und sperrt alle Geräte der Person (mit `session.revoked`).
- Antworten nennen nie das Passwort, nur `has_web_access` und `username`.

### Prüfung bei jeder Anfrage

`requireAuth` prüft nach der JWT-Signatur zusätzlich in der Datenbank: Person aktiv, und – falls
das Token eine `device_id` trägt – Gerät nicht gesperrt. Die **Berechtigung kommt aus der
Datenbank**, nicht aus dem Token. Änderungen an Berechtigung, Deaktivierung und Sperre wirken damit
sofort und nicht erst nach Ablauf des Access-Tokens (15 min). Bei ~50 Personen ist die eine
zusätzliche Abfrage pro Anfrage unkritisch. Gleiches gilt für den Verbindungsaufbau von `/ws`.

### Kopplungscode

- Tabelle `pairing_code` wie in docs/03-datenmodell.md (`code_hash` PK = SHA-256 des
  normalisierten Codes, `target_type` `person`|`monitor`, `target_id`, `created_at`, `expires_at`,
  `used_at`). Ticket 03 nutzt dieselbe Tabelle für Monitore.
- Code: 8 Zeichen aus `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (ohne 0/O/1/I, 40 Bit), kryptographisch
  zufällig. Angezeigt als `ABCD-EFGH`; beim Einlösen werden Groß-/Kleinschreibung, Leerzeichen und
  Bindestriche ignoriert. Der **QR-Code enthält nur die 8 Zeichen** (die App kennt ihre API-URL
  aus dem Build, `API_BASE_URL`).
- Gültig 24 h ab Erzeugung (`PAIRING_CODE_TTL_HOURS`, Standard 24, Zeit aus `Clock`), einmal
  einlösbar. Ein neuer Code für dieselbe Person macht ihre älteren, unbenutzten Codes ungültig
  (gelöscht). Der Klartext wird nur in der Antwort auf das Erzeugen geliefert.
- `POST /persons/{id}/pairing-code` → `{ person_id, display_name, code, expires_at }`;
  `POST /persons/pairing-codes { person_ids? }` → Liste derselben Objekte für die angegebenen bzw.
  alle aktiven Personen (Grundlage der druckbaren Liste; „alle Teilnehmer“ folgt mit der Teilnahme
  in Ticket 05). Für inaktive Personen kein Code (409 `person_inactive`).
- Die druckbare Liste erzeugt die Web-App als PDF (`pdf` + `printing`, Druckdialog des Browsers):
  pro Person Anzeigename, QR-Code, Code, „gültig bis“.

### Geräte-Sitzung (Mobile-App)

- `POST /auth/pair { code, platform: android|ios, app_version, device_name? }` (öffentlich,
  Rate-Limit wie Login). Ungültig, abgelaufen oder benutzt: 401 `invalid_pairing_code`. Erfolg:
  Code `used_at` setzen, Zeile in `device` anlegen (Spalten laut Datenmodell plus
  `device_name text null`, `created_at`), Antwort
  `{ access_token, refresh_token, expires_in, device_id, person }` (Status 200).
- Access-Token wie Web (JWT HS256, 15 min) plus Claim `device_id`.
- `POST /auth/device/refresh { refresh_token }` → gleiche Antwortform, Refresh-Token rotiert
  (Hash in derselben `device`-Zeile ersetzen, `last_seen_at` setzen). Gerät gesperrt, Person
  inaktiv oder Token unbekannt: 401 `invalid_refresh_token`. Kein Ablaufdatum für Geräte-Tokens
  (nur Sperre). Ticket 03 erweitert `pair`/`device/refresh` für Monitore.
- `POST /auth/device/logout` (Bearer-Token mit `device_id`) – „Gerät abmelden“: setzt
  `revoked_at` des eigenen Geräts, 204.
- `GET /persons/{id}/devices` (Admin) → `{ id, platform, device_name, app_version, created_at,
  last_seen_at, revoked_at }`, neueste zuerst, gesperrte eingeschlossen.
  `DELETE /devices/{id}` (Admin) sperrt (`revoked_at` setzen, Zeile bleibt), 204; schon gesperrt: 204.

### `session.revoked`

- Steuer-Nachricht **ohne `seq`**, nur an die Verbindungen des betroffenen Geräts:
  `{ "type": "session.revoked" }`, danach schließt der Server die Verbindung mit Close-Code
  **4403**. Sie ist kein Datenzustand und verbraucht deshalb keine `seq` (ADR 0009 bleibt
  unberührt; andere Clients bekommen auch kein `skip`).
- Auslöser: `DELETE /devices/{id}`, `POST /auth/device/logout`, Deaktivieren der Person.
- Der Verbindungs-Hub in `backend/src/realtime/ws.ts` kennt pro Verbindung `personId` und
  `deviceId` und bietet `revokeDevice(deviceId)` bzw. `revokePerson(personId)`.
- Client (`RealtimeClient`): `session.revoked` oder Close-Code 4403 ⇒ kein Reconnect, Zustand
  „widerrufen“; die App löscht ihre Tokens und zeigt wieder die Kopplung. Ebenso, wenn
  `/auth/device/refresh` mit 401 antwortet.

### Mobile-App

- `apps/mobile`, Paket `bftag_mobile`, `flutter create --org de.bftag --platforms ios,android`
  (vorläufige App-ID `de.bftag.bftag_mobile`; die endgültige ID legt Ticket 16 fest). Mitglied im
  Pub-Workspace, Android minSdk 26, iOS 16.
- `mobile_scanner` (QR), `flutter_secure_storage` (Refresh-Token, Geräte-ID), `go_router`, Riverpod.
- Geräte-Sitzung als `PairedSessionController` in `packages/core` mit austauschbarem
  `TokenStore` (Mobile: Secure Storage; Ticket 03: Browser-Speicher für den Monitor).
- Screens dieses Tickets: Kopplung (Scan oder Code abtippen), Start („Hallo <Anzeigename>“),
  Einstellungen („Gerät abmelden“). Push, Alarm und weitere Screens folgen mit ihren Tickets.

## Konsequenzen

- Eine DB-Abfrage mehr pro Anfrage; dafür wirken Sperre und Rechteänderung sofort.
- Wer den Kopplungscode fotografiert, kann das Gerät innerhalb von 24 h koppeln; das ist mit der
  Sperre im Admin abgedeckt (ADR 0005).
- Die App ist an eine Server-URL gebunden (Build-Parameter). Mehrere Feuerwehren mit eigenen
  Servern bräuchten später die URL im QR-Code.
