# ADR 0015 – „Mein Fahrzeug“: Fahrzeugstatus aus der App setzen

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 06: Eine Person der Besatzung setzt in der App den Fahrzeugstatus ihres Fahrzeugs.
`PUT /vehicles/{id}/status` war bisher nur für die Leitstelle offen (ADR 0009). Offen waren:
wer genau „Besatzung“ ist, wie Status 7/8 auf RTW/KTW beschränkt wird (das Feld `vehicle.type`
ist Freitext), welche `source` protokolliert wird, was `/me` liefert und wie die App live bleibt.

## Entscheidung

### Besatzung = aktuelle Schicht des laufenden BF-Tags

Eine Person gehört zur Besatzung eines Fahrzeugs genau dann, wenn es einen **laufenden** BF-Tag
gibt, dessen **aktuelle Schicht** (Regel aus ADR 0013, `currentShift`, Server-`Clock`) ein
`crew_assignment` (`vehicle_id`, `person_id`) enthält. Nach Schichtende, ohne laufenden BF-Tag
oder in einer anderen (nicht aktuellen, überlappenden) Schicht: keine Besatzung.
Backend-Helfer: `backend/src/shifts/current-crew.ts` mit
`loadCurrentCrewAssignments(db, now, personId?)` – genutzt von `/me` und der Statusprüfung.

### `PUT /vehicles/{id}/status`

Reihenfolge der Prüfungen (alle in `Realtime.mutate`, damit Prüfung und Schreiben atomar sind):

1. Nicht angemeldet → 401; Monitor-Token → 403 `forbidden` (wie bisher).
2. Fahrzeug unbekannt → 404 `not_found`; inaktiv → 409 `vehicle_inactive`.
3. Status 7 oder 8 und das Fahrzeug ist kein RTW/KTW → **409 `status_not_allowed`**. Gilt für
   **alle**, auch für die Leitstelle (Eigenschaft des Fahrzeugs, keine Berechtigungsfrage).
   RTW/KTW: `type.trim().toUpperCase()` ∈ {`RTW`, `KTW`}. Gleiche Regel in `packages/core`
   (`allowsPatientStatus(String vehicleType)`) und im Backend (`backend/src/vehicles/fms-rules.ts`).
4. Person ist Besatzung des Fahrzeugs (s. o.) → erlaubt, `source = 'app'`.
   Sonst Berechtigung `dispatch` oder `admin` → erlaubt, `source = 'dispatch'` (Überschreiben).
   Sonst → **403 `forbidden`**.

Die Route verliert `requirePermission('dispatch')` und prüft selbst. Antwort und Event
`vehicle.status_changed` `{ vehicle_id, status, at, source }` bleiben unverändert.

### `GET /me`

Antwort wird erweitert um `crew_assignments` (immer vorhanden, ggf. leer), sortiert nach
Fahrzeug-`sort_order`:

```json
{ "person": { … },
  "crew_assignments": [
    { "shift_id": "…", "vehicle_id": "…", "function": "GF" } ] }
```

Bei Doppelbesetzung mehrere Einträge. Fahrzeug- und Schichtdetails holt der Client aus dem
Snapshot (keine Duplikate im Schema).

### App: live aus dem Echtzeit-Client, nicht aus `/me`

Die App berechnet „Mein Fahrzeug“ selbst aus dem Echtzeit-Zustand (Snapshot + Events) des
`pairedRealtimeClientProvider`: `currentShift(shifts, now)` → Einträge der eigenen `person.id`
→ Fahrzeuge. Neu in `packages/core`: `myCrewAssignments(...)` (rein, testbar) und Provider
`pairedVehiclesProvider`, `pairedShiftsProvider`, `myVehiclesProvider` (re-evaluiert jede 30 s,
damit Schichtwechsel ohne Event sichtbar werden). `/me` bleibt die serverseitige Wahrheit für
andere Clients und Tests; die App braucht keinen zusätzlichen Request.

Statusänderungen werden **nicht optimistisch** angezeigt: Taste zeigt „läuft“, die Anzeige
ändert sich durch das `vehicle.status_changed`-Event. Fehler (403/409) → SnackBar.

### Screen „Mein Fahrzeug“

Route `/` der Mobile-App (ersetzt den Platzhalter-Startscreen). Ohne Besatzung: Hinweis
„Du bist aktuell keinem Fahrzeug zugeteilt.“ Bei Doppelbesetzung: Umschalter (SegmentedButton)
nach Kurzname. Inhalt: Funkrufname/Kurzname/Typ, eigene Funktion, aktueller Status, Besatzung
(„Funktion Name“) und das **FMS-Bedienteil**: dunkles Gehäuse, Tasten 1–6 (bei RTW/KTW 1–8) im
Raster, große Ziffer + kleine Bezeichnung, aktueller Status hervorgehoben. 7/8 werden bei
anderen Fahrzeugen **nicht angezeigt**.

Auch die Web-Statusleiste der Leitstelle bietet 7/8 nur noch bei RTW/KTW an.

## Konsequenzen

- Die RTW/KTW-Regel hängt am Freitext `type`; ein „RTW 2“ zählt nicht. Bewusst simpel, bis es
  ein echtes Typ-Enum gibt.
- Leitstellen-Personen, die selbst Besatzung sind, protokollieren aus der App als `app`.
- Sprechaufforderung (Status 5 → Antwort) ist nicht Teil dieses Tickets.
