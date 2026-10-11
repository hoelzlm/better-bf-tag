# Spec: v2 — Tagesbetrieb (Durchsage, Tagesablauf, Karte)

**Status:** ready-for-agent

Fachbegriffe: `CONTEXT.md` (**Durchsage**, **Tagesablauf**, **Programmpunkt**). Datenmodell-Entwurf:
`docs/03-datenmodell.md` (`announcement`, `program_item`). API-Entwurf: `docs/04-api.md` Abschnitt „Später“.
Baut auf dem fertigen MVP auf (`.scratch/mvp/`), Ticket 18 (E2E-Suite) ist vorher fertig.

## Problem Statement

Am BF-Tag selbst laufen zwischen den Einsätzen Essen, Ausbildung, Fahrzeugpflege und Nachtruhe.
Heute muss die Leitstelle dafür durch die Wache rufen oder alle einzeln anschreiben, und die
Jugendlichen wissen nicht, was als Nächstes kommt. Die Software kennt nur Einsätze.

## Solution

1. **Durchsage**: Die Leitstelle schickt eine Textnachricht an alle Teilnehmer oder an eine Schicht.
   Sie erscheint in der App (normale Benachrichtigung, **kein** Alarmton, kein Vollbild) und als Banner
   auf dem Monitor.
2. **Tagesablauf**: Die Leitstelle pflegt Programmpunkte (Zeitraum, Typ, Titel). Der Monitor zeigt im
   Standby den aktuellen und nächsten Programmpunkt, die App den ganzen Tagesablauf.
3. **Karte**: Ein Einsatz bekommt einen Ort. Der Monitor zeigt ihn wie ein echter Alarmmonitor auf einer Karte,
   die App auf dem Alarm-Screen mit Navigation.

## User Stories

1. Als Leitstelle möchte ich eine Durchsage an alle oder an eine Schicht schicken, damit ich niemanden einzeln suchen muss.
2. Als Mannschaft möchte ich Durchsagen auf dem Handy bekommen, ohne dass sie wie ein Alarm klingen.
3. Als Mannschaft möchte ich die letzten Durchsagen in der App nachlesen.
4. Als Leitstelle möchte ich eine falsche Durchsage löschen; sie verschwindet dann auch vom Monitor und aus der App-Liste.
5. Als Monitor-Betrachter möchte ich eine neue Durchsage groß sehen; ein Alarm hat immer Vorrang.
6. Als Leitstelle möchte ich Programmpunkte anlegen, ändern und löschen.
7. Als Monitor-Betrachter möchte ich im Standby sehen, was gerade läuft und was als Nächstes kommt.
8. Als Mannschaft möchte ich den Tagesablauf in der App sehen, der aktuelle Punkt hervorgehoben.
9. Als Einsatzvorbereitung möchte ich zur Adresse eines Einsatzes einen Pin setzen, per Suche oder frei auf der Karte (Übungen finden oft auf dem Gelände oder an erfundenen Adressen statt).
10. Als Monitor-Betrachter möchte ich sehen, wo der Einsatz relativ zur Wache liegt.
11. Als Mannschaft möchte ich auf dem Alarm-Screen sehen, wo es hingeht, und die Navigation starten können.

## Entscheidungen (vorgegeben, Rest entscheidet der Architekt per ADR)

- **Durchsage**
  - Anlegen und Löschen: Leitstelle, Administrator. Kein Bearbeiten.
  - `POST /bf-days/{day}/announcements { text (1–500), shift_id? }`, nur wenn der BF-Tag `running` ist (sonst 409 `bf_day_not_running`).
    `GET /bf-days/{day}/announcements` (für den Aufrufer sichtbare, neueste zuerst), `DELETE /announcements/{id}`.
  - Sichtbar: `shift_id = null` → alle (auch Monitor). Mit Schicht → Besatzung dieser Schicht, dazu immer
    Einsatzvorbereitung, Leitstelle, Admin und Monitor. Andere bekommen per WebSocket `skip`.
  - Events `announcement.created` / `announcement.deleted { id }`. Snapshot: `announcements` (die letzten 20 sichtbaren des laufenden BF-Tags).
  - Push: normale Priorität, eigener Android-Channel „Durchsagen“ (ohne Alarmton, ohne Nicht-stören-Umgehung), iOS ohne
    `time-sensitive`. Push-Fehler blockieren die Antwort nicht (anders als bei der Alarmierung).
  - Monitor: neue Durchsage als Banner (Standard 60 s, danach als „Letzte Durchsage“ im Standby); läuft ein Einsatz oder kommt ein
    Alarm, hat die Einsatzansicht Vorrang.
  - Anonymisierung (ADR 0020) löscht die Durchsagen des BF-Tags (Freitext kann Namen enthalten). Preview/Summary um `announcements` erweitern.
- **Tagesablauf**
  - CRUD: Leitstelle, Administrator. Lesen: alle inkl. Monitor.
  - `GET/POST /bf-days/{day}/program-items`, `PATCH/DELETE /program-items/{id}`. Felder: `title` (1–80), `type`
    (`meal` | `training` | `maintenance` | `rest` | `other`), `starts_at`, `ends_at` (> `starts_at`). Muss innerhalb des
    BF-Tag-Zeitraums liegen (400 `validation_error`). Überschneidungen erlaubt.
  - Erlaubt in `planning` und `running`, nicht `ended` (409 `bf_day_ended`).
  - Event `program.changed { bf_day_id, items }` (komplette Liste, sortiert nach `starts_at`, wie `slides.changed`).
    Snapshot: `program_items` des laufenden BF-Tags.
  - Bleibt bei der Anonymisierung erhalten (kein Personenbezug).
  - Monitor-Standby: aktueller und nächster Programmpunkt mit Uhrzeit, wechselt automatisch (Clock, kein Event nötig).
  - App: neuer Bereich „Tagesablauf“ (Liste, aktueller Punkt hervorgehoben, vergangene ausgegraut).

- **Karte**
  - `incident.latitude` / `incident.longitude` (nullable, nur gemeinsam). Gehören zum Meldebild: sichtbar für alle, die den Einsatz sehen.
  - Geocoding nur über das Backend (`GET /geocode?q=`, Nominatim, eigener User-Agent, ≤ 1 Anfrage/s, Cache); Clients rufen
    Nominatim nie direkt. Ergebnis ist nur ein Vorschlag, der Pin ist immer frei setzbar.
  - Kacheln: OpenStreetMap über `flutter_map`, Attribution sichtbar. Keine kostenpflichtigen Dienste, kein API-Key.
  - Wache-Standort aus Config (`STATION_LATITUDE` / `STATION_LONGITUDE`), optional.
  - Kein Routing, keine Fahrzeit, keine Fahrzeugpositionen.

## Testing Decisions

- Backend: Integrationstests (Testcontainers) für Berechtigungsmatrix positiv/negativ, Sichtbarkeit nach Schicht inkl.
  `skip`-Events, Zustandsregeln des BF-Tags, Anonymisierung, Snapshot-Inhalt.
- Push-Fake: Durchsage geht nur an Geräte der Zielgruppe, mit Durchsage-Channel, nie mit Alarm-Kategorie.
- Flutter: Widget-Tests für Monitor-Banner (inkl. Vorrang Einsatz) und App-Tagesablauf.
- `just gen-api` + `docs/04-api.md` + `docs/03-datenmodell.md` + `docs/06-clients.md` aktualisieren.
- E2E (`just e2e` aus Ticket 18) um je einen Durchsage- und Tagesablauf-Schritt erweitern.

## Out of Scope

Vorwarnung, Bereitmeldung, Sprechaufforderung, Einsatzbericht, Einsatz kopieren, automatische Anonymisierung,
Routing/Fahrzeit/Fahrzeugpositionen, Durchsage per TTS/Gong, Lesebestätigung von Durchsagen, wiederkehrende Programmpunkte.
