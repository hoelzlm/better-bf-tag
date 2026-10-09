# ADR 0019 – Nachalarmierung, Abschlussvorschlag, Einsatz schließen

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 10 baut auf ADR 0017 (Erstalarm) auf: spontane Nachalarmierung bei laufendem Einsatz,
Abschlussvorschlag und Schließen. Offen waren: wie ein Doppelklick ohne Idempotenz-`id` jetzt
abgefangen wird (der Zustandswechsel `draft → running` greift bei Nachalarmierungen nicht mehr),
wann genau ein Fahrzeug „wieder Status 1/2“ hat (direkt nach dem Alarm stehen alle Fahrzeuge
noch auf 2), wie der Vorschlag nach einem Reload und beim Zurücknehmen bei den Clients ankommt,
und wie Erstalarm/Nachalarmierung angezeigt werden.

## Entscheidung

### Nachalarmierung: weiterhin `POST /incidents/{id}/alarms`

- Zustand `draft` ⇒ Erstalarm (wie ADR 0017, inkl. `incident.updated`). Zustand `running` ⇒
  Nachalarmierung (kein Zustandswechsel, kein `incident.updated`). `closed`/`discarded` ⇒ 409
  `incident_not_alarmable`. Die Reihenfolge der Prüfungen aus ADR 0017 bleibt; Idempotenz über
  `id` zuerst.
- **Fahrzeuge nur einmal pro Einsatz:** Ist eines der `vehicle_ids` bereits in einer
  `triggered` Alarmierung desselben Einsatzes, 409 `vehicle_already_alarmed`. Das ersetzt für
  Nachalarmierungen den Doppelklick-Schutz des Zustandswechsels und entspricht docs/05
  („nur die neuen Fahrzeuge werden alarmiert“).
- **Keine doppelten Empfänger:** Beim Einfrieren werden Personen ausgelassen, die bereits in
  `alarm_recipient` einer `triggered` Alarmierung desselben Einsatzes stehen. Sie bekommen keinen
  Empfänger-Eintrag ⇒ kein Alarm-Vollbild, kein Ton, kein Push (Push läuft ausschließlich über
  `alarm_recipient`, ADR 0018). `double_crewed` wird nur über die neuen Empfänger berechnet.
- Der Monitor-Gong ertönt bei jeder live empfangenen `alarm.triggered`, also auch bei
  Nachalarmierungen (er alarmiert die Wache, nicht Personen).

### Erstalarm / Nachalarmierung anzeigen

Nicht gespeichert, nicht vom Server geliefert. `packages/core` leitet es ab: ausgelöste
Alarmierungen eines Einsatzes sortiert nach `triggered_at`, dann `id`; Index 0 = „Erstalarm“,
Index n ≥ 1 = „n. Nachalarmierung“. Ein Helfer für alle Clients (Lage, Monitor, App).

### Abschlussvorschlag

Ein laufender Einsatz ist **abschlussreif**, wenn

1. er mindestens eine `triggered` Alarmierung hat,
2. keine Alarmierung `planned` ist (ab Ticket 11 relevant),
3. jedes Fahrzeug aller `triggered` Alarmierungen `status ∈ {1, 2}` hat **und**
   `status_changed_at` später ist als das `triggered_at` der ersten Alarmierung, in der es
   alarmiert wurde (es hat sich nach dem Alarm wieder einsatzbereit gemeldet; ein Fahrzeug, das
   nie ausgerückt ist, muss die Leitstelle per Status-Überschreiben auf 1/2 setzen oder den
   Einsatz ohne Vorschlag schließen).

- Funktion `computeCloseSuggested(tx, incidentIds): Promise<Set<string>>` in
  `backend/src/incidents/close-suggestion.ts` – die einzige Stelle mit dieser Regel.
- **Event bei jedem Wechsel:** `incident.close_suggested` mit `{ id, suggested: boolean }`,
  Audience `dispatch`, `admin`. Es wird in derselben Transaktion vor/nach der Änderung
  verglichen und nur bei einem Wechsel gesendet:
  - `PUT /vehicles/{id}/status`: für alle `running` Einsätze, in deren `triggered`
    Alarmierungen das Fahrzeug steht.
  - `POST /incidents/{id}/alarms` (Nachalarmierung): neue Fahrzeuge ⇒ meist `false`.
  - Ticket 11 (Planen/Verwerfen/Auslösen geplanter Alarmierungen) ruft dasselbe auf.
  (docs/04 nannte nur `{ id }`; mit `suggested` kann der Vorschlag auch zurückgenommen werden.)
- **Snapshot:** `close_suggested_incident_ids: string[]` – für `dispatch`/`admin` berechnet,
  für alle anderen immer `[]`.

### Einsatz schließen: `POST /incidents/{id}/close`

- Berechtigung `dispatch`, `admin` (Einsatzvorbereitung und Mannschaft 403 `forbidden`).
  Unbekannt 404. Nur aus `running`, sonst 409 `invalid_state_transition`. Kein Vorschlag nötig.
- In einem `Realtime.mutate`: `UPDATE incident SET state='closed', closed_at=now,
  updated_at=now WHERE id AND state='running' RETURNING`; alle `planned` Alarmierungen des
  Einsatzes ⇒ `discarded` (Jobs löschen kommt mit Ticket 11).
- Neue Spalte `incident.closed_at timestamptz null`; `Incident`-JSON erhält `closed_at`.
- Antwort 200 `{ incident: Incident (mit Drehbuch), discarded_alarm_ids: string[] }`.
- Events in dieser Reihenfolge: `incident.updated` (state `closed`, projiziert wie ADR 0016),
  `incident.closed` `{ id }` an alle, und – falls der Einsatz vorher abschlussreif war –
  `incident.close_suggested { id, suggested: false }`.
- Folgen über bestehende Regeln: Der Einsatz verlässt `running` ⇒ `RealtimeClient` entfernt ihn
  und seine Alarmierungen ⇒ Monitor rotiert ohne ihn bzw. kehrt in den Standby zurück, das
  Alarm-Vollbild schließt sich, Quittieren antwortet 409 `alarm_not_active`.
- Web: Schließen mit Bestätigungsdialog; gibt es geplante Alarmierungen, nennt der Dialog deren
  Anzahl als Warnung (ab Ticket 11 sichtbar).

## Konsequenzen

- Ticket 11 muss `computeCloseSuggested` nach jeder Änderung an geplanten Alarmierungen aufrufen
  und beim Schließen die Jobs der verworfenen Alarmierungen löschen.
- docs/04-api.md und docs/03-datenmodell.md werden angepasst.
