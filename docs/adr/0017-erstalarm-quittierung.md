# ADR 0017 – Erstalarm, Empfänger, Quittierung, Alarm-Anzeige

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 08 führt die sofortige Alarmierung (Erstalarm), die eingefrorenen Empfänger, die
Quittierung und die Anzeige auf Monitor, App und Lage ein (docs/03-datenmodell.md,
docs/04-api.md, docs/05-alarmierung-push.md). Offen waren: Primärschlüssel der Empfänger bei
Doppelbesetzung, was „hat ein Gerät“ heißt, wie ein Doppelklick abgefangen wird, die Form von
`alarm.triggered`, wie die App bei geöffneter App entscheidet, ob sie das Alarm-Vollbild zeigt,
und wie Ton/Gong technisch abgespielt werden. Push (Ticket 09), Nachalarmierung/Abschluss
(Ticket 10) und Planung (Ticket 11) kommen später und bauen hierauf auf.

## Entscheidung

### Tabellen (eine Migration)

- `alarm`: `id` uuid PK, `incident_id` FK `incident` (cascade), `state` enum `alarm_state`
  (`planned`, `triggered`, `missed`, `discarded`), `scheduled_at` timestamptz null,
  `triggered_at` timestamptz null, `created_at` timestamptz not null. Index (`incident_id`).
- `alarm_vehicle`: PK (`alarm_id`, `vehicle_id`), FK `alarm` (cascade), FK `vehicle`.
- `alarm_recipient`: **PK (`alarm_id`, `person_id`)** – eine Person ist pro Alarmierung genau
  einmal Empfänger. `vehicle_id` FK und `function` text not null = das erste der alarmierten
  Fahrzeuge (nach `sort_order`), auf dem sie in der Schicht sitzt; `has_device` bool not null;
  `acknowledged_at` timestamptz null. FK `alarm` (cascade), FK `person`.
  (docs/03-datenmodell.md nannte PK (alarm, person, vehicle); das widerspricht „nur einmal
  Empfänger“ und wird angepasst.)

### Erstalarm auslösen: `POST /incidents/{id}/alarms`

- Berechtigung: `dispatch`, `admin` (sonst 403 `forbidden`; Einsatzvorbereitung darf nicht).
- Body: `{ id?: uuid, vehicle_ids: uuid[] }`. `scheduled_at` ist in diesem Ticket **nicht**
  erlaubt (400 `validation_error`; kommt mit Ticket 11).
  - `vehicle_ids`: 1–50, ohne Duplikate (400), alle existierend (400) und aktiv (409
    `vehicle_inactive`).
  - `id` ist ein vom Client erzeugter **Idempotenz-Schlüssel**: Existiert bereits eine
    Alarmierung mit dieser `id` für denselben Einsatz, antwortet der Server 200 mit genau dieser
    Alarmierung, ohne Event (für einen anderen Einsatz: 409 `conflict`). Web erzeugt die `id`
    einmal beim Öffnen des Alarmieren-Dialogs.
- Zustandsprüfungen (in dieser Reihenfolge, alles in **einem** `Realtime.mutate`):
  1. Einsatz unbekannt bzw. für den Aufrufer unsichtbar → 404.
  2. Der BF-Tag des Einsatzes muss `running` sein, sonst 409 `bf_day_not_running`.
  3. `UPDATE incident SET state='running', updated_at=now WHERE id=$1 AND state='draft'
     RETURNING *` – trifft das keine Zeile, 409 `invalid_state_transition` (in Ticket 08 gibt es
     nur den Erstalarm; Ticket 10 erlaubt `running` für Nachalarmierungen). Zusammen mit dem
     Mutex verhindert das einen zweiten Erstalarm durch Doppelklick, auch ohne `id`.
- Die Alarmierung wird direkt mit `state='triggered'`, `triggered_at = clock.now()`,
  `scheduled_at = null` angelegt.
- **Empfänger einfrieren:** Besatzung der zum Auslösezeitpunkt aktuellen Schicht
  (`loadCurrentCrewAssignments(tx, now)` aus `backend/src/shifts/current-crew.ts`, ADR 0013)
  gefiltert auf die alarmierten Fahrzeuge, pro Person dedupliziert (erstes Fahrzeug nach
  `sort_order`). Ohne aktuelle Schicht: keine Empfänger (Alarmierung trotzdem gültig, Monitor
  und Gong alarmieren).
- **`has_device`** = die Person hat zum Auslösezeitpunkt mindestens ein `device` mit
  `revoked_at IS NULL` (Push-Token egal – das prüft Ticket 09). Eingefroren.
- Antwort 201 (bzw. 200 bei Wiederholung): `{ alarm: Alarm, double_crewed: [{ person_id,
  display_name, vehicle_ids }] }` – `double_crewed` listet Personen, die auf mehr als einem der
  alarmierten Fahrzeuge sitzen (bei Wiederholung neu berechnet aus den Empfängern: leer).

### Objekt `Alarm`

```json
{ "id": "…", "incident_id": "…", "state": "triggered", "scheduled_at": null,
  "triggered_at": "…", "vehicle_ids": ["…"],
  "recipients": [{ "person_id": "…", "display_name": "…", "vehicle_id": "…",
                   "function": "GF", "has_device": true, "acknowledged_at": null }] }
```

`vehicle_ids` nach `sort_order`; `recipients` nach Fahrzeug-`sort_order`, Funktion
(Standardreihenfolge wie `shift-json.ts`), `display_name`. Serialisierer:
`backend/src/alarms/alarm-json.ts` (`toAlarmJson`). Alarmierungen enthalten nie das Drehbuch.

### Quittierung: `POST /alarms/{id}/acknowledge`

- Jede angemeldete Person (kein Monitor: 403). Kein Body.
- Alarmierung unbekannt → 404. Aufrufer nicht in `alarm_recipient` → 403 `not_recipient`.
  Alarmierung nicht `triggered` oder Einsatz nicht `running` → 409 `alarm_not_active`.
- Bedingtes `UPDATE … SET acknowledged_at=now WHERE alarm_id AND person_id AND
  acknowledged_at IS NULL RETURNING`: nur beim ersten Mal Event `alarm.acknowledged`;
  Wiederholung → 200 ohne Event (idempotent). Antwort 200: der eigene Empfänger-Eintrag.
- Die Quittierung gilt auch, wenn `has_device=false` war (z. B. später gekoppelt).

### Events

| Event | Audience | Daten |
|---|---|---|
| `incident.updated` | wie ADR 0016 (jetzt `running` ⇒ alle, Mannschaft ohne Drehbuch) | Einsatz |
| `alarm.triggered` | alle | `{ incident: Einsatz (projiziert: Drehbuch nur mit canSeeScript), alarm: Alarm }` |
| `alarm.acknowledged` | alle | `{ alarm_id, incident_id, person_id, display_name, acknowledged_at }` |

Beim Erstalarm entstehen in **einer** Transaktion zuerst `incident.updated`, dann
`alarm.triggered`. Der Einsatz in `alarm.triggered` geht über `toIncidentJson` mit
`project` pro Verbindung (ADR 0016) – Mannschaft und Monitor sehen den Schlüssel `script` nie.

### Lesewege

- `GET /snapshot` erhält `alarms`: alle `triggered` Alarmierungen der `running` Einsätze des
  laufenden BF-Tags (sortiert nach `triggered_at`), als `Alarm`. Ohne laufenden BF-Tag `[]`.
- `GET /incidents/{id}` erhält `alarms: Alarm[]` (nach `triggered_at`, dann `created_at`).
  Die Liste `GET /bf-days/{day}/incidents` bleibt ohne Alarmierungen.

### Clients (`packages/core`)

- Domain: `AlarmState`, `Alarm`, `AlarmRecipient` (+ `AckState { acknowledged, pending,
  noDevice }`: `acknowledged_at != null` ⇒ quittiert; sonst `has_device` ⇒ ausstehend, sonst
  kein Gerät). „Kein Gerät“ zählt nie als ausstehend.
- `RealtimeClient` hält `alarms`: `alarm.triggered` → Upsert Alarm und Einsatz;
  `alarm.acknowledged` → `acknowledged_at` beim Empfänger setzen; Einsatz verlässt `running` ⇒
  seine Alarmierungen entfernen.
- Zusätzlich ein Stream/Callback `alarmTriggered` für **live** empfangene `alarm.triggered`
  (nicht aus dem Snapshot) – nur er löst Ton/Gong aus. So klingelt nach einem Reload nichts
  erneut.
- `AlarmRepository`: `trigger(incidentId, vehicleIds, {id})`, `acknowledge(alarmId)`.

### Anzeige

- **Monitor:** Gibt es mindestens einen `running` Einsatz mit Alarmierung, zeigt `/monitor` die
  Einsatzansicht (Layout docs/06-clients.md: Nummer, Stichwort, Adresse, Meldebild, Laufzeit seit
  dem ersten `triggered_at`, alarmierte Fahrzeuge mit Status, Quittierungen mit ✓/…/–); mehrere
  Einsätze rotieren alle 15 s; sonst Standby. Gong bei jedem live empfangenen
  `alarm.triggered`. Das vorhandene „Zum Aktivieren tippen“ entsperrt zugleich die Audio-Wiedergabe.
- **App im Vordergrund:** Das Alarm-Vollbild (Route `/alarm/:alarmId`) erscheint, solange es
  eine Alarmierung eines `running` Einsatzes gibt, in der die eigene Person Empfänger ist und
  noch nicht quittiert hat (abgeleitet aus Snapshot + Events, nicht nur aus dem Event). Ton läuft
  in Schleife, bis quittiert wurde; Ton startet nur bei live empfangenem `alarm.triggered`. Nach
  der Quittierung schließt sich das Vollbild.
- **Lage:** Liste laufender Einsätze; je Alarmierung Zähler quittiert / ausstehend / kein Gerät
  und je Empfänger der Zustand. „Alarmieren“-Dialog in `/admin/einsaetze` für Entwürfe
  (Leitstelle/Admin): Fahrzeuge auswählen, Vorabwarnung bei Doppelbesetzung aus der aktuellen
  Schicht (`currentShift`), nach dem Auslösen Warnung aus `double_crewed`.
- **Ton:** Paket `audioplayers` in `apps/web` und `apps/mobile`, hinter einer kleinen
  Schnittstelle (`AlarmSound { Future<void> play({bool loop}); Future<void> stop(); }`) als
  Riverpod-Provider, in Widget-Tests durch eine Fake-Implementierung ersetzt. Die Tondateien
  (`assets/sounds/gong.wav`, `assets/sounds/alarm.wav`) werden synthetisch erzeugt (keine
  Lizenzfragen). Der native Benachrichtigungston für Push folgt mit Ticket 09.

## Konsequenzen

- Ticket 10 lockert Schritt 3 (Nachalarmierung bei `running`) und filtert Personen, die schon
  Empfänger einer früheren Alarmierung sind; die Idempotenz über `id` trägt dann weiter.
- Ticket 11 erlaubt `scheduled_at` und legt `planned`-Alarmierungen an.
- Die Anonymisierung (Ticket 13) muss `alarm_recipient` löschen.
