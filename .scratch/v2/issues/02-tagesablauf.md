# v2-02 — Tagesablauf

**What to build:** Die Leitstelle pflegt Programmpunkte eines BF-Tags. Der Monitor zeigt im Standby den aktuellen und nächsten Programmpunkt, die App den ganzen Tagesablauf. Details und Entscheidungen: `.scratch/v2/spec.md` Abschnitt „Tagesablauf“.

**Blocked by:** v2-01

**Status:** done

- [x] Migration `program_item` (`bf_day_id`, `title`, `type`, `starts_at`, `ends_at`), Drizzle-Schema
- [x] Routen `GET/POST /bf-days/{day}/program-items`, `PATCH/DELETE /program-items/{id}` mit Berechtigungen, Zeitraum- und Zustandsprüfung
- [x] Event `program.changed` (komplette sortierte Liste), Snapshot `program_items`
- [x] Bleibt bei der Anonymisierung erhalten (Test)
- [x] Web: Seite „Tagesablauf“ für Leitstelle (Liste nach Zeit, anlegen/bearbeiten/löschen, Typ-Auswahl)
- [x] Monitor-Standby: aktueller + nächster Programmpunkt, wechselt anhand der Uhr
- [x] App: Bereich „Tagesablauf“, aktueller Punkt hervorgehoben, vergangene ausgegraut
- [x] `just gen-api`, Doku (`04-api`, `03-datenmodell`, `06-clients`), E2E-Schritt
- [x] Tests laut Spec „Testing Decisions“

Spec: `.scratch/v2/spec.md` · Glossar: `CONTEXT.md`
