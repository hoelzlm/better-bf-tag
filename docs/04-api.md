# 04 – API

Basis-URL: `https://<domain>/api/v1`. Format: JSON. Maßgeblich ist später die aus dem Backend
generierte OpenAPI-Datei (`/api/v1/openapi.json`). Dieses Dokument ist der Entwurf.
Fachbegriffe: [CONTEXT.md](../CONTEXT.md).

## Authentifizierung

Entscheidung: [ADR 0005](adr/0005-authentifizierung.md)

| Client | Login | Token |
|--------|-------|-------|
| Web (Admin/Leitstelle/Einsatzvorbereitung) | `POST /auth/login` mit Benutzername + Passwort | Access-Token (15 min) + Refresh-Token als HttpOnly-Cookie |
| Mobile-App | `POST /auth/pair` mit Kopplungscode | Access-Token + langlebiges Refresh-Token (Secure Storage) |
| Monitor | `POST /auth/monitor/pair` mit Kopplungscode | Access-Token + langlebiges Refresh-Token (eigene, von Person/Gerät getrennte Session), nur lesend |

Das JWT enthält `sub` (Person- oder Monitor-ID); bei Personen zusätzlich `permission` und ggf.
`device_id`, bei Monitoren stattdessen `kind: "monitor"` und kein `permission`.
**Monitor-Tokens dürfen nur die dafür freigegebenen Lese-Routen aufrufen** (`GET /snapshot`,
`GET /monitor/me`, `/ws`); jede andere Route antwortet einem Monitor-Token mit 403 `forbidden`.

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| POST | `/auth/login` | Web-Login |
| POST | `/auth/pair` | Code einlösen → Tokens (Gerät) |
| POST | `/auth/refresh` | Web-Token erneuern (Cookie) |
| POST | `/auth/logout` | Web-Refresh-Token widerrufen |
| POST | `/auth/device/refresh` | Geräte-Refresh-Token erneuern (rotierend) |
| POST | `/auth/device/logout` | eigenes Gerät abmelden/widerrufen |
| POST | `/auth/monitor/pair` | Monitor-Kopplungscode einlösen → Tokens (Monitor); löst eine vorherige Monitor-Session ab |
| POST | `/auth/monitor/refresh` | Monitor-Refresh-Token erneuern (rotierend) |
| GET | `/monitor/me` | eigener Monitor (`{ id, name }`), nur mit Monitor-Token |

## Berechtigungen

| Aktion | Mannschaft | Einsatzvorbereitung | Leitstelle | Administrator |
|---|:-:|:-:|:-:|:-:|
| Meldebild sehen, quittieren, Status eigenes Fahrzeug | ✓ | ✓ | ✓ | ✓ |
| Drehbuch sehen | | ✓ | ✓ | ✓ |
| Einsätze anlegen/bearbeiten | | ✓ | ✓ | ✓ |
| Alarmieren, Einsatz schließen, Status überschreiben | | | ✓ | ✓ |
| Schichten/Besatzungen pflegen | | | ✓ | ✓ |
| Einsatzbericht prüfen (später) | | | ✓ | ✓ |
| Anonymisierung auslösen | | | ✓ | ✓ |
| Personen, Fahrzeuge, Feuerwehren, Monitore, BF-Tage, Folien verwalten | | | | ✓ |

Die Spalten sind getrennte Rechte und keine Hierarchie, nur der Administrator darf alles.
**Das Drehbuch (`script`) wird für die Berechtigung Mannschaft und für Monitore serverseitig
aus jeder Antwort und jedem Event entfernt.**

## Ressourcen

Pfade unter einem BF-Tag nutzen `{day}` = BF-Tag-ID oder `current` für den laufenden.

### Stammdaten (Administrator)

| Methode | Pfad |
|---------|------|
| GET/POST/PATCH/DELETE | `/fire-departments[/{id}]` |
| GET/POST/PATCH | `/persons[/{id}]` |
| PUT/DELETE | `/persons/{id}/web-access` |
| POST | `/persons/{id}/pairing-code` |
| POST | `/persons/pairing-codes` (Body `{ person_ids? }`, ohne Angabe: alle aktiven Personen) |
| GET | `/persons/{id}/devices` |
| DELETE | `/devices/{id}` |
| GET/POST/PATCH/DELETE | `/vehicles[/{id}]` |
| GET/POST/PATCH/DELETE | `/monitors[/{id}]`, `POST /monitors/{id}/pairing-code` |
| GET/POST/PATCH/DELETE | `/slides[/{id}]`, `PUT /slides/order`, `POST/DELETE /slides/{id}/image` (ADR 0014); `GET /slides/{id}/image` auch Monitor |
| GET/POST/PATCH | `/bf-days[/{id}]` (GET: alle Personen) |
| POST | `/bf-days/{id}/start`, `/bf-days/{id}/end` (ADR 0013) |
| POST | `/bf-days/{id}/anonymize` (auch Leitstelle) |

### Pro BF-Tag

| Methode | Pfad | Berechtigung |
|---------|------|--------------|
| GET/PUT | `/bf-days/{day}/participants` | GET: Admin, Leitstelle; PUT: Admin |
| GET | `/bf-days/{day}/shifts` | alle |
| POST/PATCH/DELETE | `/bf-days/{day}/shifts[/{id}]` | Leitstelle |
| PUT | `/shifts/{id}/crew` | Leitstelle; Body: Liste aus `{vehicle_id, person_id, function}` |

### Fahrzeugstatus

| Methode | Pfad | Berechtigung |
|---------|------|--------------|
| PUT | `/vehicles/{id}/status` | Besatzung der aktuellen Schicht (`source: 'app'`) oder Leitstelle/Admin (`source: 'dispatch'`); sonst 403 `forbidden`. Status 7/8 nur für RTW/KTW, sonst 409 `status_not_allowed` (gilt für alle, auch Leitstelle) |

### Einsätze und Alarmierungen

Einsatzzustände: `draft` → `running` (Erstalarm, Ticket 08) → `closed` (Leitstelle); ein Entwurf
kann stattdessen nach `discarded` verworfen werden. Nummer pro BF-Tag (`number`), fortlaufend ab
1, verworfene Nummern werden nicht wiederverwendet. Drehbuch (`script`) nur für Einsatzvorbereitung,
Leitstelle, Admin — für Mannschaft/Monitor fehlt der Schlüssel `script` in der Antwort ganz (ADR
0016). Mannschaft/Monitor sehen in Liste und Einzelabruf nur `running`/`closed` (Entwürfe und
Verworfene filtert die Liste, der Einzelabruf antwortet 404 `not_found`).

| Methode | Pfad | Berechtigung | Beschreibung |
|---------|------|--------------|--------------|
| GET | `/bf-days/{day}/incidents?state=draft\|running\|closed\|discarded` | alle | Liste, sortiert nach `number` (Drehbuch je nach Berechtigung, Zustandsfilter nach Sichtbarkeit); ohne `alarms` |
| GET | `/incidents/{id}` | alle | Einzelabruf, inkl. `alarms: Alarm[]` (nach `triggered_at`, dann `created_at`); Mannschaft/Monitor 404 für `draft`/`discarded` |
| POST | `/bf-days/{day}/incidents` | Einsatzvorbereitung, Leitstelle, Admin | `{ keyword, address, report?, script? }` → 201 `draft`; 409 `bf_day_ended` |
| PATCH | `/incidents/{id}` | Einsatzvorbereitung, Leitstelle, Admin | Meldebild/Drehbuch bearbeiten, nur `draft`/`running`; sonst 409 `incident_not_editable` |
| POST | `/incidents/{id}/discard` | Einsatzvorbereitung, Leitstelle, Admin | nur `draft`, sonst 409 `invalid_state_transition` |
| POST | `/incidents/{id}/close` | Leitstelle | verwirft geplante Alarmierungen (später) |
| POST | `/incidents/{id}/alarms` | Leitstelle, Admin | Erstalarm (ADR 0017), siehe unten |
| POST | `/alarms/{id}/acknowledge` | Empfänger | Quittierung (ADR 0017), siehe unten |
| POST | `/incidents/{id}/copy` | Einsatzvorbereitung | in einen anderen BF-Tag kopieren (später) |
| POST | `/incidents/{id}/ready` | Einsatzvorbereitung | Bereitmeldung (später) |

#### Erstalarm: `POST /incidents/{id}/alarms` (ADR 0017)

Body `{ id?: uuid, vehicle_ids: uuid[] }`. `scheduled_at` ist in diesem Ticket **nicht** erlaubt
(400 `validation_error`; Planung kommt mit Ticket 11). `id` ist ein vom Client erzeugter
Idempotenz-Schlüssel: existiert bereits eine Alarmierung mit dieser `id` für denselben Einsatz,
antwortet der Server 200 mit genau dieser Alarmierung, ohne Event; für einen anderen Einsatz 409
`conflict`.

Zustandsprüfungen (in dieser Reihenfolge, alles in einer Transaktion):

1. Einsatz unbekannt bzw. für den Aufrufer unsichtbar → 404.
2. `vehicle_ids`: unbekannte ID → 400 `validation_error`; inaktives Fahrzeug → 409
   `vehicle_inactive`.
3. Der BF-Tag des Einsatzes muss `running` sein, sonst 409 `bf_day_not_running`.
4. Der Einsatz muss `draft` sein (Übergang nach `running`), sonst 409
   `invalid_state_transition` (verhindert auch einen zweiten Erstalarm durch Doppelklick).

Empfänger werden zum Auslösezeitpunkt aus der aktuellen Schicht eingefroren (gefiltert auf die
alarmierten Fahrzeuge, pro Person dedupliziert auf das erste Fahrzeug nach `sort_order`) und
ändern sich danach nicht mehr, auch wenn die Besatzung später wechselt. `has_device` = Person
hatte zum Auslösezeitpunkt mindestens ein nicht widerrufenes Gerät.

Antwort 201 (200 bei Wiederholung über `id`):

```json
{ "alarm": { "id": "…", "incident_id": "…", "state": "triggered", "scheduled_at": null,
             "triggered_at": "…", "vehicle_ids": ["…"],
             "recipients": [{ "person_id": "…", "display_name": "…", "vehicle_id": "…",
                              "function": "GF", "has_device": true, "acknowledged_at": null }],
             "push_delivered": 3, "push_rejected": 1 },
  "double_crewed": [{ "person_id": "…", "display_name": "…", "vehicle_ids": ["…", "…"] }] }
```

`vehicle_ids` nach `sort_order`; `recipients` nach Fahrzeug-`sort_order`, Funktion
(Standardreihenfolge wie `shift-json.ts`), `display_name`. `double_crewed` listet Personen, die
auf mehr als einem der alarmierten Fahrzeuge sitzen (bei Wiederholung über `id` leer). Ein
`Alarm` enthält nie das Drehbuch.

`push_delivered`/`push_rejected` ([ADR 0018](adr/0018-push-alarm-zustellung.md)): Der Handler
wartet den Push-Versand an alle Empfänger-Geräte ab (Gesamt-Timeout 10 s) und liefert die
Antwort erst danach mit den aktuellen Zählern aus. Bei der idempotenten Wiederholung (200) wird
nicht erneut gesendet, die Zähler bleiben die des ersten Versands.

#### Quittierung: `POST /alarms/{id}/acknowledge` (ADR 0017)

Jede angemeldete Person (kein Monitor: 403 `forbidden`), kein Body. Alarmierung unbekannt → 404.
Aufrufer nicht in den Empfängern → 403 `not_recipient`. Alarmierung nicht `triggered` oder
zugehöriger Einsatz nicht `running` → 409 `alarm_not_active`. Wiederholung ist idempotent (200
ohne weiteres Event). Antwort 200: der eigene Empfänger-Eintrag (gleiche Form wie in
`recipients` oben).

### Später

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| PATCH | `/alarms/{id}` | geplante Zeit oder Fahrzeuge ändern (Ticket 11) |
| POST | `/alarms/{id}/discard` | geplante Alarmierung verwerfen (Ticket 11) |
| GET/PUT | `/incidents/{id}/reports/{vehicle_id}` | Einsatzbericht (GF der Besatzung) |
| POST | `/incidents/{id}/reports/{vehicle_id}/approve` bzw. `/return` | Prüfung |
| POST | `/vehicles/{id}/talk-request` | Sprechaufforderung |
| POST | `/bf-days/{day}/announcements` | Durchsage `{ text, shift_id? }` |
| GET/POST/PATCH/DELETE | `/bf-days/{day}/program-items[/{id}]` | Tagesablauf |

### Eigenes Gerät und Snapshot

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| GET | `/me` | Person, `crew_assignments` (aktuelle Besatzungen: `{ shift_id, vehicle_id, function }`, immer vorhanden, ggf. leer) |
| PUT | `/me/device/push-token` | Push-Token aktualisieren ([ADR 0018](adr/0018-push-alarm-zustellung.md)): nur Geräte-Sitzungen (sonst 403 `forbidden`). Body `{ token: string (1–4096) }` → 204. Setzt `device.push_token` des eigenen Geräts; trägt ein anderes Gerät dasselbe Token, wird es dort auf `null` gesetzt |
| GET | `/snapshot` | laufender BF-Tag, aktive Einsätze (`incidents`, Zustand `running`, sortiert nach `number`, Drehbuch nur mit Berechtigung, ohne `alarms`), `alarms` (alle `triggered` Alarmierungen der `running` Einsätze des laufenden BF-Tags, sortiert nach `triggered_at`; `[]` ohne laufenden BF-Tag), Fahrzeuge mit Status, aktuelle Schicht mit Besatzungen, Folien, `seq` |

## WebSocket `/ws`

- Auth per Query-Parameter `?token=<Access-Token>`, nur beim Verbindungsaufbau geprüft. Fehlt
  das Token oder ist es ungültig, schließt der Server die Verbindung mit Close-Code **4401**
  (keine HTTP-Ablehnung des Upgrades, da Browser diese nicht auswerten können).
- Sofort nach erfolgreicher Authentifizierung: `{ "type": "hello", "seq": <aktuelle seq> }`.
- Danach `{ "type": "heartbeat", "seq": <aktuelle seq> }` alle `WS_HEARTBEAT_MS` (Standard
  25000 ms), zusätzlich zu WebSocket-Protokoll-Pings im gleichen Takt; bleibt ein Pong aus,
  beendet der Server die Verbindung.
- Events tragen eine fortlaufende `seq`. Bei einer Lücke lädt der Client den Snapshot neu.
- Für Events außerhalb der Berechtigung der Verbindung kommt statt des Events
  `{ "seq": N, "type": "skip" }` — `seq` bleibt dadurch pro Verbindung lückenlos, ohne Inhalte
  zu verraten.
- Reconnect mit Backoff bei fehlender Nachricht über 2 × Heartbeat-Intervall oder geschlossenem
  Socket.

```json
{ "seq": 1042, "type": "vehicle.status_changed", "at": "2026-10-07T18:12:03Z",
  "data": { "vehicle_id": "…", "status": 3 } }
```

| Typ | Daten | Empfänger |
|-----|-------|-----------|
| `incident.created` / `incident.updated` | Einsatz, Drehbuch nur für Einsatzvorbereitung/Leitstelle/Admin | Einsatzvorbereitung, Leitstelle, Admin immer; zusätzlich alle, wenn `state ∈ {running, closed}` (ohne Drehbuch) |
| `alarm.triggered` (ADR 0017) | `{ incident, alarm }` – `incident` pro Verbindung projiziert (Drehbuch nur mit Berechtigung), `alarm` ein `Alarm` (nie mit Drehbuch) | alle; läuft im selben `Realtime.mutate` direkt nach `incident.updated` |
| `alarm.acknowledged` (ADR 0017) | `{ alarm_id, incident_id, person_id, display_name, acknowledged_at }`, nur beim ersten Mal | alle |
| `alarm.push_reported` (ADR 0018) | `{ alarm_id, incident_id, push_delivered, push_rejected }`, nach Abschluss des Push-Versands (keine Personendaten); bei null Zielgeräten wird kein Event ausgelöst | alle |
| `alarm.planned` / `alarm.discarded` / `alarm.missed` | Alarmierung | Einsatzvorbereitung, Leitstelle, Admin (später, Ticket 11) |
| `incident.close_suggested` | `{ id }` | Leitstelle |
| `incident.closed` | `{ id }` | alle |
| `vehicle.status_changed` | `{ vehicle_id, status, at, source: 'app' \| 'dispatch' }` | alle |
| `bf_day.updated` | BF-Tag | alle |
| `shift.crew_changed` | Schicht + Besatzungen (auch bei Anlegen/Bearbeiten einer Schicht) | alle |
| `shift.deleted` | `{ id, bf_day_id }` | alle |
| `slides.changed` | `{ slides }` = alle aktiven Folien (ADR 0014) | alle |
| `session.revoked` | – | betroffenes Gerät (kein `seq`, Verbindung wird danach mit Close-Code **4403** geschlossen) |
| später: `announcement.created`, `incident.ready`, `vehicle.talk_request`, `report.submitted` | | |

## Fehlerformat

```json
{ "error": { "code": "incident_not_editable", "message": "Einsatz ist bereits abgeschlossen." } }
```

400 Validierung, 401 nicht angemeldet, 403 Berechtigung fehlt, 404, 409 Zustandskonflikt.
Zusätzliche Codes aus ADR 0017: 409 `vehicle_inactive`, 409 `bf_day_not_running`, 409
`invalid_state_transition`, 409 `conflict` (Idempotenz-`id` für anderen Einsatz), 403
`not_recipient`, 409 `alarm_not_active`.

## Client-Generierung

```
backend → openapi.json → openapi-generator (dart-dio) → packages/api_client
```

Die Dart-Typen der WebSocket-Events werden in `packages/core` von Hand gepflegt.
