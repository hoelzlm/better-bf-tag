# ADR 0012 – Monitor: Kopplung, Sitzung, nur lesen, Standby

- **Status:** Angenommen
- **Datum:** 2026-10-08

## Kontext

Ticket 03 setzt ADR 0005 für Monitore um und baut auf ADR 0010 (Kopplungscode, Geräte-Sitzung,
`session.revoked`) auf. Offen waren: Tabelle und Lebenszyklus eines Monitors, ob Monitore denselben
Endpunkt wie die Mobile-App nutzen, wie ein Monitor-Token aussieht, wie „nur lesen“ erzwungen wird,
wo der Monitor seine Tokens speichert, und Details des Standby-Screens.

## Entscheidung

### Monitor (Stammdaten)

- Tabelle `monitor_display`: `id` uuid PK, `name` text not null, `refresh_token_hash` text null
  unique (null = nie gekoppelt), `paired_at` timestamptz null, `last_seen_at` timestamptz null,
  `created_at`, `revoked_at` timestamptz null. **Ein Monitor = eine Sitzung**: Eine neue Kopplung
  ersetzt den Hash (das alte Token ist danach ungültig).
- Admin-Endpunkte (nur Administrator): `GET /monitors`, `POST /monitors { name }` (201),
  `PATCH /monitors/{id} { name }`, `DELETE /monitors/{id}` = **sperren** (`revoked_at` setzen,
  Hash löschen, Zeile bleibt; idempotent 204; löst `session.revoked` aus),
  `POST /monitors/{id}/pairing-code` → 201 `{ monitor_id, name, code, expires_at }`.
  Antwortobjekt Monitor: `{ id, name, paired, paired_at, last_seen_at, revoked_at, created_at }`
  (`paired` = Hash vorhanden), sortiert nach Name.
- Kopplungscodes nutzen die Tabelle `pairing_code` aus ADR 0010 (`target_type = monitor`),
  gleiche Code-Regeln (8 Zeichen, 24 h, einmalig, neuer Code löscht ältere unbenutzte).
  Ein Kopplungscode darf auch für einen gesperrten Monitor erzeugt werden; das Einlösen hebt die
  Sperre auf (Wiederverwendung des Bildschirms ohne neuen Datensatz).

### Eigene Endpunkte für Monitore

Die Antwortform unterscheidet sich von der Mobile-App (kein `person`, keine `device_id`); ein
`oneOf` würde den generierten Dart-Client verschlechtern. Deshalb:

- `POST /auth/monitor/pair { code }` → 200 `{ access_token, refresh_token, expires_in, monitor: { id, name } }`.
  Code ungültig/abgelaufen/benutzt **oder** gehört zu einer Person: 401 `invalid_pairing_code`.
  Umgekehrt lehnt `POST /auth/pair` Monitor-Codes mit 401 ab. Einlösen wie ADR 0010 in einer
  Transaktion mit bedingtem Update (`used_at IS NULL`).
- `POST /auth/monitor/refresh { refresh_token }` → gleiche Antwortform, Rotation im selben
  Datensatz, `last_seen_at` setzen. Unbekannt oder gesperrt: 401 `invalid_refresh_token`.
  Kein Ablaufdatum (nur Sperre). Rate-Limit wie Login für beide.
- `GET /monitor/me` (nur Monitor-Token) → `{ id, name }`.

### Monitor-Token und „nur lesen“

- Access-Token: JWT HS256, 15 min, `sub` = Monitor-ID, Claim `kind: "monitor"`, keine
  `permission`. Personen-Tokens bekommen keinen `kind`-Claim (bzw. `kind: "person"`).
- `requireAuth` erzeugt einen **Principal**: Person (wie bisher) oder Monitor. Für Monitore prüft
  es in der Datenbank, dass der Monitor existiert, nicht gesperrt ist und gekoppelt ist; sonst 401.
- **Sicher per Voreinstellung:** Ein Monitor-Principal wird von jeder Route mit 403 `forbidden`
  abgewiesen, außer die Route erlaubt Monitore ausdrücklich. Erlaubt sind nur
  `GET /snapshot`, `GET /monitor/me` und `/ws`. Neue Routen sind damit für Monitore automatisch
  gesperrt; spätere Tickets (Einsatz, Folien) schalten Lese-Routen gezielt frei.
- Sichtbarkeit von Daten und Events: wie Berechtigung Mannschaft (Drehbuch wird entfernt, sobald
  es existiert; ADR 0009 `skip`-Mechanik gilt).
- Verbindungs-Hub (`ws.ts`): jede Verbindung kennt `monitorId` (oder `personId`/`deviceId`);
  `revokeMonitor(monitorId)` sendet `{"type":"session.revoked"}` (ohne `seq`) und schließt mit 4403.
  Auslöser: `DELETE /monitors/{id}` und eine neue Kopplung desselben Monitors (die alte Sitzung
  endet).

### Monitor im Browser (`apps/web`, Route `/monitor`)

- Eigene Sitzung, unabhängig von der Web-Sitzung des Administrators: `MonitorSessionController`
  (apps/web) auf Basis von `TokenStore` aus `packages/core` (ADR 0010) mit einer
  Browser-Implementierung über `localStorage` (Schlüssel `bftag.monitor.session`). Das
  Refresh-Token im `localStorage` ist bewusst akzeptiert: Der Monitor darf nur lesen, und ein
  abhandengekommener Bildschirm wird gesperrt (ADR 0005).
- Ablauf: Start → „Zum Aktivieren tippen“ (Vollbild-Overlay; der Tipp ist die Nutzergeste für
  Wake Lock, Vollbild und später den Alarmton aus Ticket 08) → ohne Sitzung Kopplungs-Screen
  (Code eingeben `ABCD-EFGH`, große Schrift) → Standby.
- Standby: dunkles, kontrastreiches Theme; große Uhr `HH:mm` mit Sekunden und Datum
  (de_DE, z. B. „Donnerstag, 8. Oktober 2026“), darunter die Fahrzeugstatus-Leiste aus Ticket 02
  (live über `RealtimeClient`). Zeitquelle injizierbar (Tests).
- Verbindung: Solange der `RealtimeClient` nicht verbunden ist, zeigt der Monitor oben ein rotes
  Banner „Keine Verbindung – verbinde neu …“; der Reconnect selbst ist der aus ADR 0009.
  `session.revoked`/4403 oder 401 beim Refresh ⇒ Tokens löschen, Kopplungs-Screen.
- Wake Lock: Paket `wakelock_plus` (Screen Wake Lock API im Browser), aktiviert beim Tipp und
  erneut, wenn die Seite wieder sichtbar wird.

## Konsequenzen

- Zwei kleine zusätzliche Auth-Endpunkte statt einer Union-Antwort.
- Ein Monitor-Token kann ohne ausdrückliche Freigabe keine Route nutzen; das muss jedes spätere
  Ticket für seine Lese-Routen beachten.
- Ein Monitor hat genau eine aktive Sitzung; zwei Fernseher brauchen zwei Monitore.
