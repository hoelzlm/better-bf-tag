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
| GET | `/bf-days/{id}/anonymization-preview` (auch Leitstelle; gleiche Response-`summary` wie `/anonymize`) |

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

Einsatzzustände: `draft` → `running` (Erstalarm, Ticket 08) → `closed` (Leitstelle/Admin, Ticket
10, [ADR 0019](adr/0019-nachalarmierung-abschluss.md)); ein Entwurf kann stattdessen nach
`discarded` verworfen werden. Nummer pro BF-Tag (`number`), fortlaufend ab 1, verworfene Nummern
werden nicht wiederverwendet. Drehbuch (`script`) nur für Einsatzvorbereitung, Leitstelle, Admin —
für Mannschaft/Monitor fehlt der Schlüssel `script` in der Antwort ganz (ADR 0016). Mannschaft/
Monitor sehen in Liste und Einzelabruf nur `running`/`closed` (Entwürfe und Verworfene filtert die
Liste, der Einzelabruf antwortet 404 `not_found`).

| Methode | Pfad | Berechtigung | Beschreibung |
|---------|------|--------------|--------------|
| GET | `/bf-days/{day}/incidents?state=draft\|running\|closed\|discarded` | alle | Liste, sortiert nach `number` (Drehbuch je nach Berechtigung, Zustandsfilter nach Sichtbarkeit); ohne `alarms` |
| GET | `/incidents/{id}` | alle | Einzelabruf, inkl. `alarms: Alarm[]` (nach `triggered_at`, dann `created_at`); Mannschaft/Monitor 404 für `draft`/`discarded` |
| POST | `/bf-days/{day}/incidents` | Einsatzvorbereitung, Leitstelle, Admin | `{ keyword, address, report?, script? }` → 201 `draft`; 409 `bf_day_ended` |
| PATCH | `/incidents/{id}` | Einsatzvorbereitung, Leitstelle, Admin | Meldebild/Drehbuch bearbeiten, nur `draft`/`running`; sonst 409 `incident_not_editable` |
| POST | `/incidents/{id}/discard` | Einsatzvorbereitung, Leitstelle, Admin | nur `draft`, sonst 409 `invalid_state_transition` |
| POST | `/incidents/{id}/close` | Leitstelle, Admin | Einsatz schließen (ADR 0019), siehe unten |
| POST | `/incidents/{id}/alarms` | Leitstelle, Admin | Erstalarm, Nachalarmierung und Planung (ADR 0017, ADR 0019, [ADR 0022](adr/0022-zeitgesteuerte-alarmierung.md)), siehe unten |
| PATCH | `/alarms/{id}` | Leitstelle, Admin | geplante Alarmierung ändern (ADR 0022), siehe unten |
| POST | `/alarms/{id}/discard` | Leitstelle, Admin | geplante/verpasste Alarmierung verwerfen (ADR 0022), siehe unten |
| POST | `/alarms/{id}/trigger` | Leitstelle, Admin | geplante/verpasste Alarmierung manuell auslösen (ADR 0022), siehe unten |
| POST | `/alarms/{id}/acknowledge` | Empfänger | Quittierung (ADR 0017), siehe unten |
| POST | `/incidents/{id}/copy` | Einsatzvorbereitung | in einen anderen BF-Tag kopieren (später) |
| POST | `/incidents/{id}/ready` | Einsatzvorbereitung | Bereitmeldung (später) |

#### Erstalarm, Nachalarmierung und Planung: `POST /incidents/{id}/alarms` (ADR 0017, [ADR 0019](adr/0019-nachalarmierung-abschluss.md), [ADR 0022](adr/0022-zeitgesteuerte-alarmierung.md))

Body `{ id?: uuid, vehicle_ids: uuid[], scheduled_at?: string, offset_minutes?: number }`.
`scheduled_at` (absoluter Zeitpunkt) und `offset_minutes` (relativ zum Erstalarm/zur frühesten
geplanten Alarmierung ohne eigene Basis) schließen sich gegenseitig aus (400 `validation_error`,
wenn beide gesetzt sind). Werden beide ausgelassen, wird sofort alarmiert (bisheriges Verhalten).
`id` ist ein vom Client erzeugter Idempotenz-Schlüssel: existiert bereits eine Alarmierung mit
dieser `id` für denselben Einsatz, antwortet der Server 200 mit genau dieser Alarmierung, ohne
Event; für einen anderen Einsatz 409 `conflict`.

Zustandsprüfungen (in dieser Reihenfolge, alles in einer Transaktion):

1. Einsatz unbekannt bzw. für den Aufrufer unsichtbar → 404.
2. `vehicle_ids`: unbekannte ID → 400 `validation_error`; inaktives Fahrzeug → 409
   `vehicle_inactive`.
3. Planen (`scheduled_at`/`offset_minutes` gesetzt) ist bereits vor Beginn des BF-Tags erlaubt
   (BF-Tag `planning` oder `running`); sofortiges Alarmieren weiterhin nur während der BF-Tag
   `running` ist. Sonst 409 `bf_day_not_running`.
4. Idempotenz-`id`-Wiederholung zuerst (s.o.), danach: Einsatz `closed`/`discarded` → 409
   `incident_not_alarmable`. Einsatz `draft` → Erstalarm, Zustandswechsel nach `running` (löst
   `incident.updated` aus). Einsatz `running` → **Nachalarmierung**, kein Zustandswechsel, kein
   `incident.updated` — nur `alarm.triggered`. Planung löst keinen Zustandswechsel aus, egal
   welchen Zustand der Einsatz hat.
5. Steht eines der `vehicle_ids` bereits in einer `triggered` **oder `planned`** Alarmierung
   desselben Einsatzes → 409 `vehicle_already_alarmed`. Das ersetzt für Nachalarmierungen den
   Doppelklick-Schutz, den der Zustandswechsel beim Erstalarm bietet, und verhindert, dass ein
   Fahrzeug doppelt eingeplant wird.
6. Bei `offset_minutes`: gibt es keinen Erstalarm (`triggered`) und keine geplante Alarmierung
   ohne eigene Basis (`planned`, `relative_to_alarm_id = null`) für den Einsatz → 409
   `no_first_alarm`.
7. Der berechnete bzw. übergebene `scheduled_at` liegt nicht in der Zukunft → 409
   `scheduled_at_in_past`.

Eine geplante Alarmierung (`state: "planned"`) hat keine Empfänger und löst keinen Push/keine
Benachrichtigung aus. Sie wird zum `scheduled_at`-Zeitpunkt von einem Scheduler ausgelöst (Ticket
11-2) und durchläuft dann denselben Auslöse-Pfad wie eine sofortige Alarmierung (Empfänger
einfrieren, Push, `alarm.triggered`). Wird der Zeitpunkt verpasst (Einsatz schließt vorher, oder
der Scheduler erreicht sie nicht mehr rechtzeitig), wechselt sie nach `missed` und danach auf
`discarded`, sobald sie explizit verworfen wird oder der Einsatz schließt.

Sichtbarkeit: `planned`/`missed`/`discarded` Alarmierungen erscheinen nur im vollen Drehbuch
(Einsatzvorbereitung/Leitstelle/Admin, `GET /incidents/{id}`, `GET /snapshot` → `scheduled_alarms`)
— für Mannschaft/Monitor sind in `alarms` nur `triggered` Alarmierungen enthalten. `alarm.planned`
und `alarm.discarded` Events gehen nur an dieses Drehbuch-Publikum.

Empfänger werden zum Auslösezeitpunkt aus der aktuellen Schicht eingefroren (gefiltert auf die
alarmierten Fahrzeuge, pro Person dedupliziert auf das erste Fahrzeug nach `sort_order`) und
ändern sich danach nicht mehr, auch wenn die Besatzung später wechselt. `has_device` = Person
hatte zum Auslösezeitpunkt mindestens ein nicht widerrufenes Gerät. Bei einer Nachalarmierung
werden außerdem Personen ausgelassen, die bereits Empfänger einer `triggered` Alarmierung
desselben Einsatzes sind (kein zweiter Empfänger-Eintrag, kein erneutes Alarm-Vollbild/Ton/Push);
`double_crewed` wird dadurch nur über die neuen Empfänger berechnet.

Antwort 201 (200 bei Wiederholung über `id`):

```json
{ "alarm": { "id": "…", "incident_id": "…", "state": "triggered", "scheduled_at": null,
             "triggered_at": "…", "relative_to_alarm_id": null, "offset_minutes": null,
             "vehicle_ids": ["…"],
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
nicht erneut gesendet, die Zähler bleiben die des ersten Versands. Für geplante Alarmierungen
entfällt das (keine Empfänger vor dem Auslösen).

#### Geplante Alarmierung ändern: `PATCH /alarms/{id}` ([ADR 0022](adr/0022-zeitgesteuerte-alarmierung.md))

Body `{ vehicle_ids?: uuid[], scheduled_at?: string, offset_minutes?: number }`. Nur für
Alarmierungen im Zustand `planned`, sonst 409 `alarm_not_planned`. `scheduled_at` ist nur für
absolute Alarmierungen (ohne `relative_to_alarm_id`) erlaubt, `offset_minutes` nur für relative
(400 `validation_error` sonst). Dieselben Prüfungen wie beim Anlegen (Fahrzeuge, BF-Tag-Zustand,
`scheduled_at_in_past`, `vehicle_already_alarmed`). Ändert sich der Zeitpunkt, werden alle
relativen Alarmierungen, die sich auf diese Alarmierung beziehen (`relative_to_alarm_id`), in
derselben Transaktion neu berechnet und per `alarm.planned` gemeldet. Antwort 200 `{ alarm }`.

#### Geplante/verpasste Alarmierung verwerfen: `POST /alarms/{id}/discard` ([ADR 0022](adr/0022-zeitgesteuerte-alarmierung.md))

Nur für `planned`/`missed`, sonst 409 `invalid_state_transition`. Setzt `state: "discarded"` und
kaskadiert auf alle `planned` Alarmierungen, die sich relativ auf diese beziehen (werden ebenfalls
`discarded`, je ein eigenes `alarm.discarded` Event). Antwort 200 `{ alarm }`.

#### Geplante/verpasste Alarmierung manuell auslösen: `POST /alarms/{id}/trigger` ([ADR 0022](adr/0022-zeitgesteuerte-alarmierung.md))

Kein Body. Unbekannte Alarmierung → 404 `not_found`. Nur für `planned`/`missed`, sonst 409
`invalid_state_transition`. Dieselben Zustandsprüfungen wie beim `AlarmScheduler` (gleicher
Auslöse-Pfad): BF-Tag nicht `running` → 409 `bf_day_not_running`; Einsatz nicht `draft`/`running` →
409 `incident_not_alarmable`; eines der Fahrzeuge bereits in einer `triggered` Alarmierung
desselben Einsatzes → 409 `vehicle_already_alarmed`. Erfolgreich: derselbe Auslöse-Pfad wie beim
Scheduler (Empfänger einfrieren, Push, `alarm.triggered`, ggf. `incident.updated` beim Erstalarm).
Antwort 200 `{ alarm, double_crewed }` (gleiche Form wie `POST /incidents/{id}/alarms`).

#### Quittierung: `POST /alarms/{id}/acknowledge` (ADR 0017)

Jede angemeldete Person (kein Monitor: 403 `forbidden`), kein Body. Alarmierung unbekannt → 404.
Aufrufer nicht in den Empfängern → 403 `not_recipient`. Alarmierung nicht `triggered` oder
zugehöriger Einsatz nicht `running` → 409 `alarm_not_active` (z. B. auch nach dem Schließen des
Einsatzes: die Alarmierung selbst bleibt `triggered`, aber der Einsatz ist nicht mehr `running`).
Wiederholung ist idempotent (200 ohne weiteres Event). Antwort 200: der eigene Empfänger-Eintrag
(gleiche Form wie in `recipients` oben).

#### Einsatz schließen: `POST /incidents/{id}/close` (ADR 0019)

Berechtigung Leitstelle, Admin; Einsatzvorbereitung und Mannschaft → 403 `forbidden`. Unbekannter
Einsatz → 404 `not_found`. Kein Body.

Nur aus `running`, sonst 409 `invalid_state_transition` (auch bei zweitem Aufruf). Setzt
`incident.state = 'closed'`, `incident.closed_at = now`; alle `planned` Alarmierungen des
Einsatzes werden `discarded` (Löschen zugehöriger Jobs kommt mit Ticket 11). Antwort 200:

```json
{ "incident": { "...": "...", "state": "closed", "closed_at": "…" },
  "discarded_alarm_ids": ["…"] }
```

`incident` wie bei `GET /incidents/{id}` (inkl. Drehbuch für den Aufrufer). Events in dieser
Reihenfolge: `incident.updated` (Zustand `closed`, projiziert wie gewohnt — Mannschaft/Monitor
ohne Drehbuch), dann `incident.closed`. War der Einsatz zuvor abschlussreif
([ADR 0019](adr/0019-nachalarmierung-abschluss.md) „Abschlussvorschlag“), folgt ein drittes Event
`incident.close_suggested { id, suggested: false }`.

Folgen: Der Einsatz verlässt `running` ⇒ Monitor/App entfernen ihn und seine Alarmierungen aus der
aktiven Ansicht, Quittieren einer seiner Alarmierungen antwortet danach 409 `alarm_not_active`.

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
| POST | `/me/device/test-alarm` | Testalarm auslösen ([ADR 0021](adr/0021-onboarding-testalarm.md)): nur Geräte-Sitzungen (sonst 403 `forbidden`). Body `{ delay_seconds?: integer 0–30 }`. Ohne Push-Token → 409 `no_push_token`. Läuft bereits ein Timer oder war der letzte Versand vor < 10 s → 429 `test_alarm_cooldown`. `delay_seconds` 0 (Default): sendet sofort, 200 `{ outcome: "delivered" \| "rejected" \| "invalid_token" }`. `delay_seconds` > 0: 202 `{ scheduled: true }`, Versand erfolgt verzögert auf demselben Gerät; weder Einsatz/Alarm/Event noch `seq`-Änderung |
| GET | `/snapshot` | laufender BF-Tag, aktive Einsätze (`incidents`, Zustand `running`, sortiert nach `number`, Drehbuch nur mit Berechtigung, ohne `alarms`), `alarms` (alle `triggered` Alarmierungen der `running` Einsätze des laufenden BF-Tags, sortiert nach `triggered_at`; `[]` ohne laufenden BF-Tag), `close_suggested_incident_ids` ([ADR 0019](adr/0019-nachalarmierung-abschluss.md) „Abschlussvorschlag“: IDs der abschlussreifen `running` Einsätze, nur für Leitstelle/Admin berechnet, sonst immer `[]`), Fahrzeuge mit Status, aktuelle Schicht mit Besatzungen, Folien, `seq` |

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
| `incident.close_suggested` ([ADR 0019](adr/0019-nachalarmierung-abschluss.md)) | `{ id, suggested: boolean }`, bei jedem Wechsel | Leitstelle, Admin |
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
`not_recipient`, 409 `alarm_not_active`. Aus [ADR 0019](adr/0019-nachalarmierung-abschluss.md):
409 `incident_not_alarmable` (Alarm auf `closed`/`discarded` Einsatz), 409
`vehicle_already_alarmed` (Fahrzeug schon in einer `triggered` Alarmierung des Einsatzes).

## Client-Generierung

```
backend → openapi.json → openapi-generator (dart-dio) → packages/api_client
```

Die Dart-Typen der WebSocket-Events werden in `packages/core` von Hand gepflegt.
