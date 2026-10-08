# ADR 0013 – BF-Tag, Teilnahme, Schichten, Besatzung

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 05 führt BF-Tag, Teilnahme, Schicht und Besatzung ein (docs/03-datenmodell.md,
docs/04-api.md). Offen waren: wie Zustandswechsel und „höchstens ein laufender BF-Tag“
umgesetzt werden, welche Schicht „aktuell“ ist (Schichten dürfen sich überlappen?), was mit
Schichten passiert, wenn sich der Zeitraum des BF-Tags ändert, welche Events es gibt und wie der
Snapshot zeitabhängige Daten liefert, ohne dass das Backend an Schichtgrenzen Events erzeugen muss.

## Entscheidung

### Tabellen (eine Migration)

- `bf_day`: `id` uuid PK, `name` text not null, `starts_at`/`ends_at` timestamptz not null
  (check `ends_at > starts_at`), `state` enum `bf_day_state` (`planning`, `running`, `ended`)
  default `planning`, `anonymized_at` timestamptz null, `created_at` timestamptz not null.
  **Partieller Unique-Index** `bf_day_single_running` auf `(state) WHERE state = 'running'`
  – die Datenbank garantiert „höchstens einer läuft“.
- `participation`: PK (`bf_day_id`, `person_id`), beide FK (`bf_day` on delete cascade,
  `person`).
- `shift`: `id` uuid PK, `bf_day_id` FK (cascade), `name` text not null, `starts_at`/`ends_at`
  timestamptz not null (check `ends_at > starts_at`), `created_at`. Index auf `bf_day_id`.
- `crew_assignment`: PK (`shift_id`, `vehicle_id`, `person_id`), `shift_id` FK (cascade),
  `vehicle_id` FK, `person_id` FK, `function` text not null.

### BF-Tag (nur Administrator schreibt)

- `GET /bf-days` (alle Personen; sortiert nach `starts_at` absteigend), `GET /bf-days/{day}`.
  `{day}` = UUID oder `current` (= laufender BF-Tag, sonst 404 `not_found`).
- `POST /bf-days { name, starts_at, ends_at }` → 201, Zustand `planning`. **In derselben
  Transaktion** entsteht die Standardschicht `name = "Schicht 1"` über den ganzen Zeitraum.
- `PATCH /bf-days/{id} { name?, starts_at?, ends_at? }` – nicht bei `ended` (409 `bf_day_ended`).
  Zeitraum ändern: Schichtgrenzen, die genau auf der alten Grenze lagen, wandern mit
  (`shift.starts_at == alt.starts_at` → neu, `shift.ends_at == alt.ends_at` → neu). Liegt danach
  eine Schicht nicht vollständig im neuen Zeitraum oder ist leer (`ends_at <= starts_at`):
  409 `shift_outside_bf_day`, nichts wird geändert.
- Zustandswechsel als eigene Aktionen: `POST /bf-days/{id}/start` (nur aus `planning`) und
  `POST /bf-days/{id}/end` (nur aus `running`); sonst 409 `invalid_state_transition`.
  Läuft schon ein anderer BF-Tag: 409 `bf_day_already_running` (die Route prüft vorab; der
  Unique-Index fängt Rennen ab und wird ebenfalls auf diesen Code abgebildet). Kein Zurück
  von `ended`. Starten ist auch vor `starts_at` erlaubt (der Administrator entscheidet).
- Antwortobjekt BF-Tag: `{ id, name, starts_at, ends_at, state, anonymized_at, created_at }`.

### Teilnahme

- `GET /bf-days/{day}/participants` – Administrator **und Leitstelle** (die Leitstelle braucht
  die Liste zum Einteilen). Antwort: Liste `{ person_id, display_name, person_type, permission,
  fire_department_id }`, sortiert nach `display_name`.
- `PUT /bf-days/{day}/participants { person_ids }` – nur Administrator, ersetzt die vollständige
  Menge (idempotent). Unbekannte oder deaktivierte Personen beim Hinzufügen: 400
  `validation_error`. Bei `ended`: 409 `bf_day_ended`.
- Wird eine Person entfernt, werden ihre `crew_assignment` in allen Schichten dieses BF-Tags in
  derselben Transaktion gelöscht und für jede betroffene Schicht `shift.crew_changed` gesendet.

### Schichten und Besatzung (Leitstelle; Administrator darf alles)

- `GET /bf-days/{day}/shifts` (alle Personen) → Liste der Schichten **mit Besatzung**, sortiert
  nach `starts_at`, dann `name`.
- `POST /bf-days/{day}/shifts { name, starts_at, ends_at }` → 201; `PATCH /bf-days/{day}/shifts/{id}`;
  `DELETE /bf-days/{day}/shifts/{id}` → 204. Die Schicht muss vollständig im Zeitraum des
  BF-Tags liegen (409 `shift_outside_bf_day`). Die letzte Schicht eines BF-Tags kann nicht
  gelöscht werden (409 `last_shift`). Bei `ended`: 409 `bf_day_ended`.
- **Überlappung ist erlaubt.** Die Standardschicht über den ganzen Tag bleibt so als Rückfall
  bestehen, eine „Nachtschicht 22–06“ überlagert sie.
- **Aktuelle Schicht** (nur für den laufenden BF-Tag): unter den Schichten mit
  `starts_at <= jetzt < ends_at` die mit dem **spätesten `starts_at`**; bei Gleichstand die mit
  dem früheren `ends_at`, dann kleinere `id`. Keine passende Schicht ⇒ keine aktuelle Schicht.
  Die Regel ist im Backend (`backend/src/shifts/current-shift.ts`) und in `packages/core`
  (`currentShift(shifts, now)`) gleich implementiert und in beiden getestet.
- `PUT /shifts/{id}/crew { assignments: [{ vehicle_id, person_id, function }] }` ersetzt die
  vollständige Besatzung der Schicht; Antwort 200 = Schicht mit Besatzung. Regeln:
  - `person_id` muss am BF-Tag der Schicht teilnehmen, sonst 409 `person_not_participant`.
  - `vehicle_id` muss existieren und aktiv sein, sonst 409 `vehicle_inactive` (unbekannt: 400
    `validation_error`).
  - `function`: getrimmt, 1–16 Zeichen, frei (Standardliste GF, MA, ATF, ATM, WTF, WTM, ME nur als
    Vorschlag im UI). Doppelte (`vehicle_id`, `person_id`) im Body: 400 `validation_error`.
  - Eine Person auf mehreren Fahrzeugen derselben Schicht ist **erlaubt** (nur das UI warnt).
- Antwortobjekt Schicht: `{ id, bf_day_id, name, starts_at, ends_at, crew: [{ vehicle_id,
  person_id, display_name, function }] }`; `crew` sortiert nach Fahrzeug-`sort_order`, dann
  Funktion in Standardreihenfolge (GF, MA, ATF, ATM, WTF, WTM, ME, sonstige alphabetisch), dann
  `display_name`.

### Events (alle Empfänger, Mutationen über `Realtime.mutate`)

| Typ | Daten | Auslöser |
|-----|-------|----------|
| `bf_day.updated` | BF-Tag | anlegen, bearbeiten, starten, beenden |
| `shift.crew_changed` | Schicht mit Besatzung | Schicht angelegt/bearbeitet, Besatzung ersetzt, Teilnahme entfernt |
| `shift.deleted` | `{ id, bf_day_id }` | Schicht gelöscht |

`shift.crew_changed` steht so in docs/04-api.md; dass es auch bei Anlegen/Bearbeiten einer
Schicht kommt, spart einen weiteren Event-Typ (der Client macht in beiden Fällen ein Upsert).

### Snapshot

`GET /snapshot` erhält zusätzlich:

- `bf_day`: der laufende BF-Tag oder `null`,
- `shifts`: **alle** Schichten des laufenden BF-Tags mit Besatzung (leer, wenn keiner läuft),
- `current_shift_id`: nach obiger Regel zum Zeitpunkt des Snapshots (Server-`Clock`) oder `null`.

Weil sich die aktuelle Schicht mit der Uhr ändert, ohne dass ein Event entsteht, rechnet der
Client sie selbst mit `currentShift(snapshot.shifts, now)` nach (Monitor: bei jedem Uhr-Tick).
Das Backend braucht dafür keinen Scheduler.

Client-Verhalten (`RealtimeClient`): `shift.crew_changed` → Upsert in `shifts`, wenn
`bf_day_id` zum laufenden BF-Tag gehört, sonst ignorieren; `shift.deleted` → entfernen;
`bf_day.updated` → Snapshot neu laden (selten, hält die Logik einfach).

### Web

- `/admin/bf-tage` (Administrator): Liste, anlegen/bearbeiten (Standard-Zeitraum 24 h),
  Starten/Beenden mit Bestätigung, Teilnahmen per Checkbox-Liste der aktiven Personen.
- `/admin/schichten` (Leitstelle, Administrator): BF-Tag-Auswahl (Standard: laufender, sonst
  nächster geplanter), Schichten als Tabs, Besatzungs-Board: links die teilnehmenden Personen,
  rechts je aktives Fahrzeug eine Drop-Zone. Drop ⇒ Funktion wählen ⇒ `PUT /shifts/{id}/crew`
  mit der vollständigen neuen Liste. Doppelbesetzung wird an der Person (Liste und Karten)
  markiert.
- Monitor-Standby: unter der Fahrzeugstatus-Leiste die aktuelle Schicht (Name, Zeitfenster) und
  je Fahrzeug die Besatzung „Funktion Name“. Ohne laufenden BF-Tag oder aktuelle Schicht:
  Bereich ausgeblendet.

## Konsequenzen

- Die Schichtregel existiert zweimal (TypeScript, Dart); gleiche Testfälle in beiden halten sie
  synchron.
- Überlappende Schichten sind bewusst erlaubt; Alarmierungen (Ticket 07) nehmen die Besatzung
  der nach obiger Regel aktuellen Schicht.
- Personen bleiben über BF-Tage bestehen; nur die Anonymisierung (später) löscht Teilnahmen und
  Besatzungen.
