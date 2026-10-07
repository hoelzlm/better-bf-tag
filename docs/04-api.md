# 04 – API

Basis-URL: `https://<domain>/api/v1`. Format: JSON. Die maßgebliche Spezifikation ist die aus dem
Backend generierte OpenAPI-Datei (`/api/v1/openapi.json`). Dieses Dokument ist der Entwurf.

## Authentifizierung

Details zur Entscheidung: [ADR 0005](adr/0005-authentifizierung.md)

| Client | Login | Token |
|--------|-------|-------|
| Admin (Web) | `POST /auth/login` mit Benutzername + Passwort | Access-Token (15 min) + Refresh-Token als HttpOnly-Cookie |
| Mobile-App | `POST /auth/pair` mit Kopplungscode aus dem QR-Code | Access-Token (15 min) + Refresh-Token (lange gültig, im Secure Storage) |
| Monitor | `POST /auth/pair` mit Kopplungscode | wie Mobile-App, Rolle `monitor` (nur lesend) |

Das Access-Token ist ein JWT mit `sub` (member- oder monitor-ID), `role` und `device_id`.
Wird ein Gerät im Admin gesperrt, schlägt der nächste Refresh fehl.

### Endpunkte

| Methode | Pfad | Rolle | Beschreibung |
|---------|------|-------|--------------|
| POST | `/auth/login` | – | Web-Login |
| POST | `/auth/pair` | – | Code einlösen → Tokens |
| POST | `/auth/refresh` | – | Token erneuern |
| POST | `/auth/logout` | alle | Refresh-Token widerrufen |

## Ressourcen

### Mitglieder

| Methode | Pfad | Rolle |
|---------|------|-------|
| GET | `/members` | admin, dispatcher |
| POST | `/members` | admin |
| PATCH | `/members/{id}` | admin |
| DELETE | `/members/{id}` | admin |
| POST | `/members/{id}/pairing-code` | admin → liefert Code + QR-Inhalt |
| GET | `/members/{id}/devices` | admin |
| DELETE | `/devices/{id}` | admin (Gerät sperren) |

### Eigenes Gerät

| Methode | Pfad | Rolle | Beschreibung |
|---------|------|-------|--------------|
| GET | `/me` | member+ | eigenes Profil, eigene Fahrzeuge |
| PUT | `/me/device/push-token` | member+ | FCM/APNs-Token hinterlegen bzw. aktualisieren |

### Fahrzeuge

| Methode | Pfad | Rolle |
|---------|------|-------|
| GET | `/vehicles` | alle |
| POST | `/vehicles` | admin |
| PATCH | `/vehicles/{id}` | admin |
| DELETE | `/vehicles/{id}` | admin |
| PUT | `/vehicles/{id}/crew` | admin |
| PUT | `/vehicles/{id}/status` | dispatcher+, member (nur eigenes Fahrzeug) |

### Einsätze

| Methode | Pfad | Rolle | Beschreibung |
|---------|------|-------|--------------|
| GET | `/incidents?state=…` | alle | Liste |
| GET | `/incidents/{id}` | alle | Detail inkl. Fahrzeuge und Rückmeldungen |
| POST | `/incidents` | dispatcher+ | anlegen (`draft`) |
| PATCH | `/incidents/{id}` | dispatcher+ | bearbeiten, solange nicht `closed` |
| POST | `/incidents/{id}/schedule` | dispatcher+ | `{ "scheduled_at": "…" }` |
| POST | `/incidents/{id}/unschedule` | dispatcher+ | |
| POST | `/incidents/{id}/alarm` | dispatcher+ | sofort alarmieren |
| POST | `/incidents/{id}/close` | dispatcher+ | |
| POST | `/incidents/{id}/cancel` | dispatcher+ | |
| PUT | `/incidents/{id}/response` | member+ | `{ "response": "coming" }` |

### Monitor

| Methode | Pfad | Rolle |
|---------|------|-------|
| GET | `/monitors` | admin |
| POST | `/monitors` | admin |
| POST | `/monitors/{id}/pairing-code` | admin |
| DELETE | `/monitors/{id}` | admin |
| GET | `/slides` | alle |
| POST/PATCH/DELETE | `/slides[/{id}]` | admin |
| POST | `/slides/{id}/image` | admin (multipart) |

### Snapshot

| Methode | Pfad | Rolle | Beschreibung |
|---------|------|-------|--------------|
| GET | `/snapshot` | alle | aktive Einsätze, alle Fahrzeuge mit Status, Rückmeldungen, Slides, aktuelle `seq` |

## WebSocket `/ws`

- Verbindung mit `?token=<access_token>` oder Auth-Nachricht als erste Nachricht.
- Server → Client: Events. Client → Server: nur `ping` und `auth`.
- Heartbeat alle 25 s. Der Client verbindet sich mit exponentiellem Backoff neu.

### Event-Format

```json
{
  "seq": 1042,
  "type": "vehicle.status_changed",
  "at": "2026-10-07T18:12:03Z",
  "data": { "vehicle_id": "…", "status": 3 }
}
```

### Event-Typen

| Typ | Daten | Empfänger |
|-----|-------|-----------|
| `incident.created` | Einsatz | admin, dispatcher |
| `incident.updated` | Einsatz | admin, dispatcher; alle, falls alarmiert |
| `incident.alarmed` | Einsatz inkl. Fahrzeuge | alle |
| `incident.closed` | `{ id }` | alle |
| `incident.response` | `{ incident_id, member_id, display_name, response }` | alle |
| `vehicle.status_changed` | `{ vehicle_id, status, at }` | alle |
| `vehicle.updated` | Fahrzeug | alle |
| `slides.changed` | – | monitor |
| `session.revoked` | – | betroffenes Gerät |

## Fehlerformat

```json
{ "error": { "code": "incident_not_editable", "message": "Einsatz ist bereits abgeschlossen." } }
```

HTTP-Statuscodes: 400 Validierung, 401 nicht angemeldet, 403 Rolle fehlt, 404, 409 Zustandskonflikt.

## Client-Generierung

```
backend → openapi.json → openapi-generator (dart-dio) → packages/api_client
```

Die WebSocket-Events sind nicht Teil von OpenAPI. Ihre Dart-Typen werden in `packages/core`
von Hand gepflegt, die Schemas im Backend sind die Referenz.
