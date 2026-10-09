# ADR 0016 – Einsatz: Meldebild, Drehbuch und Drehbuch-Filter

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 07 führt den Einsatz mit Meldebild und Drehbuch ein (docs/03-datenmodell.md,
docs/04-api.md). Offen waren: Nummerierung, welche Einsätze die Mannschaft überhaupt sieht
(Entwürfe verraten das Szenario), wie das Drehbuch zuverlässig aus jeder Antwort und jedem Event
für Mannschaft und Monitor verschwindet, und wer `incident.created`/`incident.updated` bekommt.

## Entscheidung

### Tabelle `incident` (eine Migration)

- `id` uuid PK, `bf_day_id` FK `bf_day` (on delete cascade), `number` integer not null,
  `keyword` text not null, `address` text not null, `report` text not null default `''`,
  `script` text not null default `''`, `state` enum `incident_state`
  (`draft`, `running`, `closed`, `discarded`) default `draft`, `created_at`, `updated_at`
  timestamptz not null. Unique (`bf_day_id`, `number`), Index auf (`bf_day_id`, `state`).
- **Nummer pro BF-Tag:** `max(number) + 1` innerhalb von `Realtime.mutate` (Mutex serialisiert),
  der Unique-Index fängt Fehler ab. Nummern verworfener Einsätze werden nicht wiederverwendet.
- Validierung (getrimmt): `keyword` 1–80, `address` 1–200, `report` ≤ 4000, `script` ≤ 20000
  Zeichen; sonst 400 `validation_error`.

### Zustandsregeln in diesem Ticket

- Anlegen nur, wenn der BF-Tag nicht `ended` ist (409 `bf_day_ended`); Zustand `draft`.
- `PATCH /incidents/{id}` (Meldebild/Drehbuch, alle Felder optional) bei `draft` und `running`;
  bei `closed`/`discarded` 409 `incident_not_editable`.
- `POST /incidents/{id}/discard` nur aus `draft`, sonst 409 `invalid_state_transition`.
- `draft → running` (Erstalarm, Ticket 08) und `running → closed` (Leitstelle) kommen später.
- Berechtigung zum Anlegen/Bearbeiten/Verwerfen: `preparation`, `dispatch`, `admin`.

### Sichtbarkeit

- **Drehbuch sehen** (`canSeeScript`): Personen mit `preparation`, `dispatch`, `admin`.
  Mannschaft und Monitore nie.
- **Einsätze sehen:** Wer das Drehbuch sehen darf, sieht alle Zustände. Mannschaft sieht nur
  `running` und `closed` – Entwürfe und verworfene Einsätze existieren für sie nicht
  (Liste filtert, Detail antwortet 404 `not_found`), sonst wäre das Szenario vorab bekannt.
- Monitore dürfen weiterhin nur `/snapshot`, `/monitor/me`, `/ws` (ADR 0012).

### Ein Serialisierer, Feld fehlt statt `null`

- `backend/src/incidents/incident-json.ts`: `toIncidentJson(row, { includeScript })` ist der
  **einzige** Weg, einen Einsatz nach außen zu geben. Ohne `includeScript` fehlt der Schlüssel
  `script` ganz (nicht `null`, nicht leer). Im OpenAPI-Schema ist `script` optional.
- `backend/src/incidents/visibility.ts`: `canSeeScript(principal)` und `canSeeIncident(principal,
  state)`; Monitore zählen als Mannschaft.

### Events: Projektion pro Verbindung

`Realtime`-Events erhalten zusätzlich zu `audience` eine optionale Projektion
`project?: (permission) => unknown`. `ws.ts` sendet `project ? project(permission) : data`
(Monitore laufen dort bereits als `crew`). So geht **ein** Event mit **einer** `seq` an alle,
und jede Verbindung bekommt nur ihre Sicht.

| Event | Audience | Daten |
|---|---|---|
| `incident.created` | `preparation`, `dispatch`, `admin` (immer Entwurf) | Einsatz mit Drehbuch |
| `incident.updated` | wie oben; zusätzlich Mannschaft/Monitor, wenn `state ∈ {running, closed}` | privilegiert mit Drehbuch, sonst ohne |

`incident.updated` entsteht bei Bearbeiten und Verwerfen. Alle anderen bekommen `skip`.

### Snapshot

`GET /snapshot` erhält `incidents`: die `running` Einsätze des laufenden BF-Tags, sortiert nach
`number`; mit Drehbuch nur für Personen mit `canSeeScript`. Ohne laufenden BF-Tag: `[]`.
`RealtimeClient` hält `incidents` und wendet `incident.created`/`incident.updated` an: Upsert,
wenn `state == running` und `bf_day_id` zum laufenden BF-Tag gehört, sonst entfernen.

### Clients

- Web `/admin/einsaetze` (Einsatzvorbereitung, Leitstelle, Administrator): BF-Tag-Auswahl wie
  im Schichten-Screen, Filter Entwurf / laufend / abgeschlossen (verworfen ausgeblendet),
  Editor mit Meldebild-Bereich und einem deutlich abgesetzten Drehbuch-Bereich
  (Warnfarbe, Schloss-Symbol, Überschrift „Drehbuch – GEHEIM, nie für die Mannschaft sichtbar“).
- App: Einsatzliste (`GET /bf-days/current/incidents`) und Einsatzdetail. Das Drehbuch wird
  angezeigt, **wenn der Server es liefert** – die App entscheidet nicht selbst über Sichtbarkeit.

### Tests

Ein Test-Helfer prüft für Mannschaft und Monitor auf jedem Weg (REST-Liste, Detail, Snapshot,
WebSocket), dass weder der Schlüssel `script` noch der Drehbuch-Text im rohen JSON vorkommt.

## Konsequenzen

- Neue Lesewege für Einsätze müssen `toIncidentJson` benutzen; ein direkter Row-Export wäre ein
  Leck. Ticket 08 (`alarm.triggered`) nutzt denselben Serialisierer ohne Drehbuch.
- docs/04-api.md wird angepasst: `incident.updated` geht gefiltert auch an alle.
