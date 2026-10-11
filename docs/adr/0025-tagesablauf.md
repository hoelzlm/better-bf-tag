# ADR 0025 – Tagesablauf: Programmpunkte, Echtzeit, Monitor-Standby, App

- **Status:** Angenommen
- **Datum:** 2026-10-11

## Kontext

Ticket v2-02 (`.scratch/v2/issues/02-tagesablauf.md`) und `.scratch/v2/spec.md` Abschnitt „Tagesablauf“
geben Felder, Routen, Berechtigungen, Zustandsregel, Event und Anonymisierung vor. Offen waren:
Tabellenform, Sortierung, PATCH-Semantik, was beim Ändern des BF-Tag-Zeitraums passiert, für welche
BF-Tage `program.changed` gesendet wird, wie „aktuell“ und „nächster“ definiert sind und wo die Seiten
in Web und App hängen.

## Entscheidung

### Datenmodell

Enum `program_item_type` (`meal`, `training`, `maintenance`, `rest`, `other`). Tabelle `program_item`:
`id uuid pk`, `bf_day_id → bf_day on delete cascade`, `title varchar(80) not null`,
`type program_item_type not null`, `starts_at timestamptz not null`, `ends_at timestamptz not null`,
`check (ends_at > starts_at)`. Index `(bf_day_id, starts_at)`. Kein Personenbezug, kein `created_by`.

Sortierung überall (GET, Event, Snapshot): `starts_at`, dann `ends_at`, dann `id` aufsteigend.

### API

- `GET /bf-days/{day}/program-items` – alle Personen und Monitore, jeder Zustand des BF-Tags; sortierte
  Liste, ohne Paging. Unbekannter BF-Tag → 404.
- `POST /bf-days/{day}/program-items` – `dispatch`, `admin`. Body `{ title (trim, 1–80), type,
  starts_at, ends_at }`. Antwort 201 mit Programmpunkt-JSON.
- `PATCH /program-items/{id}` – `dispatch`, `admin`. Alle Felder optional; geprüft wird das
  **zusammengeführte** Ergebnis. Antwort 200.
- `DELETE /program-items/{id}` – `dispatch`, `admin`. Antwort 204.
- Prüfungen: `ends_at <= starts_at` oder Zeitraum nicht vollständig in `[bf_day.starts_at,
  bf_day.ends_at]` → 400 `validation_error`. BF-Tag `ended` → 409 `bf_day_ended` (POST, PATCH,
  DELETE). Unbekannter Programmpunkt → 404. Überschneidungen sind erlaubt.
- JSON: `{ id, bf_day_id, title, type, starts_at, ends_at }`.
- **BF-Tag-Zeitraum ändern** (`PATCH /bf-days/{day}`): Programmpunkte werden nicht verschoben. Läge
  danach ein Programmpunkt nicht mehr vollständig im Zeitraum → 409 `program_item_outside_bf_day`,
  nichts wird geändert (analog `shift_outside_bf_day`).

### Echtzeit

- `program.changed { bf_day_id, items }` nach jedem POST/PATCH/DELETE in derselben `mutate`, Audience
  alle (wie `slides.changed`), **für jeden BF-Tag**, nicht nur den laufenden.
- Snapshot: `program_items` = sortierte Liste des laufenden BF-Tags, sonst `[]`.
- Clients übernehmen `program.changed` nur, wenn `bf_day_id` der laufende BF-Tag aus dem Snapshot ist.
  Startet ein BF-Tag, lädt `bf_day.updated` ohnehin den Snapshot neu (ADR 0013).

### Aktuell / nächster / vergangen

Reine Funktion in `packages/core` (geteilt von Web und App), Zeitvergleich in UTC:
- **aktuell:** `starts_at <= now < ends_at`. Bei Überschneidung zeigt der Monitor den mit dem
  spätesten `starts_at` (bei Gleichstand der erste der sortierten Liste); die App hebt alle aktuellen hervor.
- **nächster:** der erste der sortierten Liste mit `starts_at > now`.
- **vergangen:** `ends_at <= now`.

Typ-Bezeichnungen (Deutsch, in `core`): meal „Essen“, training „Ausbildung“, maintenance
„Fahrzeugpflege“, rest „Ruhe“, other „Sonstiges“.

### Clients

- Web: Seite „Tagesablauf“ (`/admin/tagesablauf`) für `dispatch`/`admin`, BF-Tag-Auswahl wie die
  Schichten-Seite (Standard: laufender, sonst nächster geplanter), Liste nach Zeit, Anlegen/Bearbeiten/
  Löschen per Dialog, Typ-Auswahl. Bei `ended` nur lesend.
- Monitor-Standby: Block „Jetzt“ / „Danach“ mit Uhrzeit (`HH:mm–HH:mm`) und Titel, aus
  `snapshot.program_items` + `monitorClockProvider`; wechselt allein durch die Uhr. Ohne Programmpunkte
  entfällt der Block. Einsatzansicht und Durchsage-Banner haben Vorrang (unverändert).
- App: Bereich „Tagesablauf“ (`/tagesablauf`, vierter Eintrag der Navigationsleiste „Ablauf“), Liste
  aus dem Snapshot-State, aktuelle Punkte hervorgehoben, vergangene ausgegraut; eine Uhr (Tick alle
  30 s, im Test überschreibbar) aktualisiert die Markierung.

### Anonymisierung

`program_item` bleibt erhalten; Preview/Summary ändern sich nicht.

## Konsequenzen

- Ein Programmpunkt kann einer BF-Tag-Zeitraumänderung im Weg stehen; die Leitstelle passt ihn vorher an.
- Programmpunkte geplanter BF-Tage erzeugen Events, die laufende Clients verwerfen (geringe Last).
