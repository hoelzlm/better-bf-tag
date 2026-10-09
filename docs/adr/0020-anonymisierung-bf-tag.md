# ADR 0020 – Anonymisierung eines BF-Tags

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 13 setzt die manuelle Anonymisierung aus ADR 0007 um. Offen waren: wie Einträge der
Statushistorie einem BF-Tag zugeordnet werden (`vehicle_status_event` hat keinen BF-Tag-Bezug,
und ein BF-Tag kann nach seinem geplanten `ends_at` beendet werden), welche Personen anderer
Feuerwehren genau gelöscht werden, wie die Zusammenfassung im Bestätigungsdialog entsteht und wo
die Leitstelle die Aktion im Web findet (die BF-Tage-Seite war bisher nur für Administratoren).

## Entscheidung

### Statushistorie bekommt `bf_day_id`

- Neue Spalte `vehicle_status_event.bf_day_id` uuid **null**, FK `bf_day` on delete set null,
  Index `vehicle_status_event_bf_day_idx`.
- Beim Statuswechsel (`PATCH /vehicles/{id}/status`) wird die Id des **laufenden** BF-Tags
  gespeichert, sonst `null`.
- Die Migration füllt Altdaten über das Zeitfenster: `created_at` zwischen `starts_at` und
  `ends_at` eines BF-Tags (bei Überlappung beliebiger Treffer).
- Anonymisierung setzt `person_id = null` für alle Ereignisse mit `bf_day_id = <BF-Tag>`.
  Status, Quelle und Zeit bleiben erhalten.

### Ablauf (eine Transaktion, `realtime.mutate`)

`POST /bf-days/{id}/anonymize`, Berechtigung **Leitstelle oder Administrator**
(`requirePermission('dispatch')`).

1. 404 `bf_day_not_found`; 409 `bf_day_not_ended`, wenn `state <> 'ended'`;
   409 `bf_day_already_anonymized`, wenn `anonymized_at` gesetzt ist. Die Zeile wird mit
   `SELECT … FOR UPDATE` gesperrt (Doppelklick).
2. Kandidaten merken: Personen mit Teilnahme an diesem BF-Tag, deren Feuerwehr nicht
   `is_own` ist.
3. Löschen: `alarm_recipient` aller Alarmierungen der Einsätze dieses BF-Tags, `crew_assignment`
   aller Schichten dieses BF-Tags, `participation` dieses BF-Tags.
4. Statushistorie: `person_id = null` wie oben.
5. Personen löschen: Kandidaten, die danach **keine** `participation`, `crew_assignment` oder
   `alarm_recipient` mehr haben und nicht die auslösende Person sind. Vorher ihre
   `pairing_code`-Zeilen (`target_type = 'person'`) löschen; `device` und `web_session`
   gehen per Cascade, `vehicle_status_event.person_id` per set null.
   Personen anderer Feuerwehren ohne Teilnahme an diesem BF-Tag bleiben unberührt (sie können
   für einen kommenden BF-Tag vorbereitet sein).
6. `anonymized_at = clock.now()`, `emit('bf_day.updated', bfDayJson)`.

Erhalten bleiben: BF-Tag (Name, Zeiten), Schichten, Einsätze (Meldebild, Drehbuch, Bericht),
Alarmierungen, `alarm_vehicle`, Fahrzeuge, Personen der eigenen Feuerwehr.

Antwort 200: `{ bf_day: BfDay, summary: AnonymizationSummary }`.

### Zusammenfassung vorab

`GET /bf-days/{id}/anonymization-preview` (gleiche Berechtigung, gleiche 404/409-Regeln)
liefert dieselben Zahlen, die die Anonymisierung erzeugen würde, ohne zu schreiben:

```
AnonymizationSummary = {
  participations: int,        // gelöschte Teilnahmen
  crew_assignments: int,      // gelöschte Besatzungseinträge
  alarm_recipients: int,      // gelöschte Empfänger/Quittierungen
  status_events: int,         // Statushistorie-Einträge mit entferntem Personenbezug (person_id war gesetzt)
  persons_deleted: int        // gelöschte Personen anderer Feuerwehren
}
```

Vorschau und Ausführung teilen sich eine Funktion im Modul `backend/src/bf-days/anonymize.ts`
(`computeAnonymization(tx, bfDayId, actorPersonId)` für Zahlen + Personen-Ids,
`anonymizeBfDay(tx, bfDayId, actorPersonId, now)` für die Ausführung).

### Web

- `/admin/bf-tage` ist für Leitstelle **und** Administrator erreichbar. Anlegen, Bearbeiten,
  Starten, Beenden und Teilnehmer bleiben nur für Administratoren sichtbar.
- Beendete, nicht anonymisierte BF-Tage zeigen „Anonymisieren“. Der Bestätigungsdialog lädt die
  Vorschau und listet, was gelöscht wird und was erhalten bleibt; Hinweis „nicht umkehrbar“.
- Anonymisierte BF-Tage zeigen „Anonymisiert am …“ statt der Aktion.

## Konsequenzen

- Die automatische Anonymisierung nach 8 Wochen (ADR 0007, nicht im MVP) kann
  `anonymizeBfDay` direkt aufrufen.
- Statuswechsel ohne laufenden BF-Tag (Leitstelle außerhalb eines BF-Tags) werden nie
  anonymisiert; sie enthalten nur Personen der eigenen Feuerwehr mit Berechtigung Leitstelle.
- Nach der Anonymisierung zeigen Alarmierungen des BF-Tags keine Empfänger mehr.
