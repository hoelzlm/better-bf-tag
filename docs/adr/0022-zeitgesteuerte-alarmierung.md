# ADR 0022 – Zeitgesteuerte Alarmierung, eigener Scheduler, verpasste Alarmierungen

- **Status:** Angenommen
- **Datum:** 2026-10-10

## Kontext

Ticket 11 führt geplante Alarmierungen ein (absoluter Zeitpunkt oder relativ zum Erstalarm),
die pünktlich auslösen, einen Neustart überleben und nach mehr als 10 Minuten Verspätung als
verpasst gelten. ADR 0002 sah dafür pg-boss vor. pg-boss rechnet aber mit der Datenbankzeit
(`now()` in PostgreSQL); die injizierbare `Clock` (ADR 0008) und damit die vom Spec geforderte
**steuerbare Uhr** in Tests wären umgangen. Offen waren außerdem: wie „relativ zum Erstalarm“
gespeichert wird, wer planen darf, welche Clients geplante Alarmierungen sehen und was beim
Auslösen passiert, wenn sich die Lage inzwischen geändert hat.

## Entscheidung

### Die Tabelle `alarm` ist die Job-Queue (kein pg-boss)

- Eine Alarmierung mit `state='planned'` und `scheduled_at` **ist** der Job. Singleton pro
  Alarmierung ergibt sich aus der Zeile selbst; Zeit oder Fahrzeuge ändern aktualisiert die Zeile
  (= ersetzt den Job); Verwerfen setzt `state='discarded'` (= löscht den Job). Keine zweite
  Wahrheit, die auseinanderlaufen kann. pg-boss wird nicht eingeführt (Abweichung von ADR 0002).
- `AlarmScheduler` (`backend/src/alarms/scheduler.ts`) mit `runDue(): Promise<{ triggered:
  string[]; missed: string[] }>`: wählt alle `planned` mit `scheduled_at <= clock.now()`
  (sortiert nach `scheduled_at`, `id`) und behandelt jede in einem eigenen `Realtime.mutate`
  mit bedingtem `UPDATE … WHERE id=$1 AND state='planned'` (doppelte Läufe sind harmlos).
- Zeitquelle ist ausschließlich `Clock`. Ein Intervall-Timer (Echtzeit) ruft `runDue()` auf,
  Standard alle 1000 ms (`ALARM_SCHEDULER_INTERVAL_MS`, `0` = kein Timer). Beim Start der App
  (Fastify-`onReady`) läuft `runDue()` einmal sofort – das ist das „Nachlaufen nach Neustart“.
  `onClose` stoppt den Timer. Tests setzen das Intervall auf 0 und rufen `runDue()` explizit
  (Testhilfe `TestApp.runScheduler()`); einzige Ausnahme vom Black-Box-Prinzip neben ADR 0008.
- **Verpasst:** `clock.now() - scheduled_at > 10 min` (genau 10 min löst noch aus) ⇒
  `state='missed'`, Event `alarm.missed`. Konstante `MISSED_AFTER_MS = 600_000`.
- **Auslösen nicht möglich** (BF-Tag nicht `running`, Einsatz nicht `draft`/`running`, ein
  Fahrzeug inaktiv) ⇒ ebenfalls `missed`. Die Leitstelle sieht es auf der Lage und entscheidet.
- Es gibt genau eine Backend-Instanz (ADR 0011); Mehrinstanz-Betrieb ist nicht vorgesehen,
  der bedingte Zustandswechsel verhindert trotzdem doppeltes Auslösen.

### Gemeinsamer Auslöse-Pfad

`triggerAlarm(tx, emit, deps, alarmRow)` in `backend/src/alarms/trigger.ts` – genutzt von
sofortiger Alarmierung, Scheduler und manuellem Auslösen: Einsatz `draft ⇒ running`
(Erstalarm, `incident.updated`), Empfänger einfrieren (ADR 0017/0019, ohne doppelte
Empfänger), `triggered_at = clock.now()`, `alarm.triggered`, Push (ADR 0018),
`computeCloseSuggested`-Vergleich (ADR 0019), Neuberechnung relativer Alarmierungen (s. u.).

### Planen: `POST /incidents/{id}/alarms` mit Zeitpunkt

- Body `{ id?, vehicle_ids, scheduled_at?: datetime, offset_minutes?: int 1..1440 }`;
  `scheduled_at` und `offset_minutes` schließen sich aus (400 `validation_error`). Ohne beide =
  sofort (wie bisher). Berechtigung wie Auslösen: `dispatch`, `admin`.
- Einsatz `draft` oder `running` (sonst 409 `incident_not_alarmable`); BF-Tag `planned` oder
  `running` (sonst 409 `bf_day_not_running` – Planen ist schon vor Beginn des BF-Tags erlaubt).
- **Fahrzeug höchstens einmal je Einsatz:** Ein Fahrzeug darf nicht in einer `triggered` **oder
  `planned`** Alarmierung desselben Einsatzes stehen (409 `vehicle_already_alarmed`; gilt jetzt
  auch für sofortige Alarmierungen und für `PATCH`). Fahrzeuge verpasster Alarmierungen sind frei.
- **Relativ:** Neue Spalten `alarm.relative_to_alarm_id uuid null` (FK `alarm`, set null) und
  `alarm.offset_minutes int null`. Basis ist der **Erstalarm**: die früheste `triggered`
  Alarmierung des Einsatzes (nach `triggered_at`, `id`), sonst die `planned` Alarmierung ohne
  Basis mit dem frühesten `scheduled_at`. Gibt es keine, 409 `no_first_alarm`.
  `scheduled_at = (basis.triggered_at ?? basis.scheduled_at) + offset_minutes`.
  - Basis ändert ihre Zeit (`PATCH`) ⇒ abhängige `planned` werden neu berechnet.
  - Basis löst aus (egal wann/wie) ⇒ abhängige `planned` = `triggered_at + offset`.
  - Basis wird verworfen ⇒ abhängige `planned` werden mit verworfen.
  - Basis wird verpasst ⇒ abhängige bleiben unverändert.
  - Jede Neuberechnung sendet `alarm.planned` mit dem aktualisierten Objekt.
- Ein (berechneter) Zeitpunkt muss in der Zukunft liegen (`> clock.now()`), sonst 409
  `scheduled_at_in_past`.
- Antwort 201 `{ alarm, double_crewed: [] }`; Event `alarm.planned`. Idempotenz über `id` wie
  ADR 0017.

### Ändern, Verwerfen, manuell Auslösen

- `PATCH /alarms/{id}` `{ scheduled_at? | offset_minutes?, vehicle_ids? }` – nur `planned`
  (409 `alarm_not_planned`). `scheduled_at` nur für absolute, `offset_minutes` nur für relative
  Alarmierungen (sonst 400 `validation_error`). Gleiche Prüfungen wie beim Planen. Event
  `alarm.planned` (Upsert-Semantik, kein eigenes `alarm.updated`).
- `POST /alarms/{id}/discard` – aus `planned` oder `missed` (sonst 409
  `invalid_state_transition`). Event `alarm.discarded`, Kaskade auf relative Alarmierungen.
- `POST /alarms/{id}/trigger` – aus `planned` („jetzt auslösen“) oder `missed` (sonst 409
  `invalid_state_transition`); Prüfungen wie beim sofortigen Auslösen (BF-Tag `running`,
  Fahrzeuge nicht bereits `triggered`). Antwort 200 `{ alarm, double_crewed }`.
- Alle drei: `dispatch`, `admin`; unbekannt 404.
- Nach jeder Änderung an geplanten Alarmierungen `computeCloseSuggested` vorher/nachher
  vergleichen (ADR 0019).

### Einsatz schließen oder verwerfen

`POST /incidents/{id}/close` und `POST /incidents/{id}/discard` setzen alle `planned` **und
`missed`** Alarmierungen auf `discarded` (= Jobs gelöscht) und senden je `alarm.discarded`.
`discard` antwortet weiterhin mit dem Einsatz; `close` liefert wie bisher
`discarded_alarm_ids`.

### Sichtbarkeit, Events, Snapshot

| Event | Audience | Daten |
|---|---|---|
| `alarm.planned` | `preparation`, `dispatch`, `admin` | `{ incident: Einsatz (mit Drehbuch), alarm: Alarm }` |
| `alarm.missed` | `preparation`, `dispatch`, `admin` | `{ incident, alarm }` |
| `alarm.discarded` | `preparation`, `dispatch`, `admin` | `{ alarm_id, incident_id }` |

- Mannschaft und Monitor erfahren von geplanten Alarmierungen nichts (Überraschungseffekt).
  `GET /incidents/{id}` liefert Alarmierungen in `planned`/`missed`/`discarded` nur an
  Aufrufer mit `canSeeScript`.
- `Alarm`-JSON erhält `relative_to_alarm_id` und `offset_minutes` (beide nullable).
- `GET /snapshot` erhält `scheduled_alarms: [{ incident, alarm }]`: alle `planned` und `missed`
  Alarmierungen der `draft`/`running` Einsätze des laufenden BF-Tags, sortiert nach
  `scheduled_at`, `id` – nur für `preparation`/`dispatch`/`admin`, sonst `[]`.
- Clients (`RealtimeClient`): `alarm.planned`/`alarm.missed` ⇒ Upsert in `scheduledAlarms`;
  `alarm.discarded` und `alarm.triggered` ⇒ aus `scheduledAlarms` entfernen.

### Anzeige (Web)

- Lage: Abschnitt „Geplante Alarmierungen“ (nächste zuerst, Countdown, Einsatz, Fahrzeuge,
  absolut/relativ) mit „Jetzt auslösen“, „Ändern“, „Verwerfen“; Abschnitt „Verpasste
  Alarmierungen“ (hervorgehoben) mit „Auslösen“ und „Verwerfen“.
- Alarmieren-Dialog: „sofort“ / „Zeitpunkt“ / „relativ zum Erstalarm (+ min)“.
- Schließen- und Verwerfen-Dialog des Einsatzes warnen mit der Anzahl geplanter (und verpasster)
  Alarmierungen.

## Konsequenzen

- ADR 0002 ist für Jobs überholt: kein pg-boss. Die spätere Vorwarnung kann aus
  `scheduled_at − prewarning_minutes` im selben Scheduler abgeleitet werden.
- docs/02, docs/04, docs/05 werden angepasst.
- Die Pünktlichkeit hängt vom Intervall ab (≤ 1 s Verspätung), ausreichend für Übungsalarme.
