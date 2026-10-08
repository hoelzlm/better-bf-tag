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
| Monitor | `POST /auth/pair` mit Kopplungscode | wie App, nur lesend |

Das JWT enthält `sub` (Person- oder Monitor-ID), `permission` und `device_id`.

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| POST | `/auth/login` | Web-Login |
| POST | `/auth/pair` | Code einlösen → Tokens |
| POST | `/auth/refresh` | Token erneuern |
| POST | `/auth/logout` | Refresh-Token widerrufen |

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
| GET/POST/PATCH/DELETE | `/persons[/{id}]` |
| POST | `/persons/{id}/pairing-code` |
| GET | `/persons/{id}/devices` |
| DELETE | `/devices/{id}` |
| GET/POST/PATCH/DELETE | `/vehicles[/{id}]` |
| GET/POST/DELETE | `/monitors[/{id}]`, `POST /monitors/{id}/pairing-code` |
| GET/POST/PATCH/DELETE | `/slides[/{id}]`, `POST /slides/{id}/image` |
| GET/POST/PATCH | `/bf-days[/{id}]` |
| POST | `/bf-days/{id}/anonymize` (auch Leitstelle) |

### Pro BF-Tag

| Methode | Pfad | Berechtigung |
|---------|------|--------------|
| GET/PUT | `/bf-days/{day}/participants` | Admin |
| GET | `/bf-days/{day}/shifts` | alle |
| POST/PATCH/DELETE | `/bf-days/{day}/shifts[/{id}]` | Leitstelle |
| PUT | `/shifts/{id}/crew` | Leitstelle; Body: Liste aus `{vehicle_id, person_id, function}` |

### Fahrzeugstatus

| Methode | Pfad | Berechtigung |
|---------|------|--------------|
| PUT | `/vehicles/{id}/status` | Besatzung der aktuellen Schicht oder Leitstelle |

### Einsätze und Alarmierungen

| Methode | Pfad | Berechtigung | Beschreibung |
|---------|------|--------------|--------------|
| GET | `/bf-days/{day}/incidents?state=…` | alle | Liste (Drehbuch je nach Berechtigung) |
| GET | `/incidents/{id}` | alle | inkl. Alarmierungen, Empfänger und Quittierungen |
| POST | `/bf-days/{day}/incidents` | Einsatzvorbereitung | anlegen (`draft`) |
| PATCH | `/incidents/{id}` | Einsatzvorbereitung | Meldebild/Drehbuch bearbeiten, solange nicht `closed` |
| POST | `/incidents/{id}/discard` | Einsatzvorbereitung | nur `draft` |
| POST | `/incidents/{id}/close` | Leitstelle | verwirft geplante Alarmierungen |
| POST | `/incidents/{id}/alarms` | Leitstelle | `{ vehicle_ids, scheduled_at? }`: ohne Zeit sofort, sonst geplant |
| PATCH | `/alarms/{id}` | Leitstelle | geplante Zeit oder Fahrzeuge ändern |
| POST | `/alarms/{id}/discard` | Leitstelle | geplante Alarmierung verwerfen |
| POST | `/alarms/{id}/acknowledge` | Empfänger | Quittierung |
| POST | `/incidents/{id}/copy` | Einsatzvorbereitung | in einen anderen BF-Tag kopieren (später) |
| POST | `/incidents/{id}/ready` | Einsatzvorbereitung | Bereitmeldung (später) |

### Später

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| GET/PUT | `/incidents/{id}/reports/{vehicle_id}` | Einsatzbericht (GF der Besatzung) |
| POST | `/incidents/{id}/reports/{vehicle_id}/approve` bzw. `/return` | Prüfung |
| POST | `/vehicles/{id}/talk-request` | Sprechaufforderung |
| POST | `/bf-days/{day}/announcements` | Durchsage `{ text, shift_id? }` |
| GET/POST/PATCH/DELETE | `/bf-days/{day}/program-items[/{id}]` | Tagesablauf |

### Eigenes Gerät und Snapshot

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| GET | `/me` | Person, aktuelle Besatzungen |
| PUT | `/me/device/push-token` | Push-Token aktualisieren |
| GET | `/snapshot` | laufender BF-Tag, aktive Einsätze, Fahrzeuge mit Status, aktuelle Schicht mit Besatzungen, Folien, `seq` |

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
| `incident.created` / `incident.updated` | Einsatz | Einsatzvorbereitung, Leitstelle, Admin |
| `alarm.planned` / `alarm.discarded` | Alarmierung | Einsatzvorbereitung, Leitstelle, Admin |
| `alarm.triggered` | Einsatz (Meldebild) + Alarmierung + Empfänger | alle |
| `alarm.missed` | Alarmierung | Leitstelle, Admin |
| `alarm.acknowledged` | `{ alarm_id, person_id, display_name }` | alle |
| `incident.close_suggested` | `{ id }` | Leitstelle |
| `incident.closed` | `{ id }` | alle |
| `vehicle.status_changed` | `{ vehicle_id, status, at }` | alle |
| `shift.crew_changed` | Schicht + Besatzungen | alle |
| `slides.changed` | – | Monitore |
| `session.revoked` | – | betroffenes Gerät |
| später: `announcement.created`, `incident.ready`, `vehicle.talk_request`, `report.submitted` | | |

## Fehlerformat

```json
{ "error": { "code": "incident_not_editable", "message": "Einsatz ist bereits abgeschlossen." } }
```

400 Validierung, 401 nicht angemeldet, 403 Berechtigung fehlt, 404, 409 Zustandskonflikt.

## Client-Generierung

```
backend → openapi.json → openapi-generator (dart-dio) → packages/api_client
```

Die Dart-Typen der WebSocket-Events werden in `packages/core` von Hand gepflegt.
