# v2-02 — Tagesablauf

**What to build:** Die Leitstelle pflegt Programmpunkte eines BF-Tags. Der Monitor zeigt im Standby den aktuellen und nächsten Programmpunkt, die App den ganzen Tagesablauf. Details und Entscheidungen: `.scratch/v2/spec.md` Abschnitt „Tagesablauf“.

**Blocked by:** v2-01

**Status:** ready-for-agent

- [ ] Migration `program_item` (`bf_day_id`, `title`, `type`, `starts_at`, `ends_at`), Drizzle-Schema
- [ ] Routen `GET/POST /bf-days/{day}/program-items`, `PATCH/DELETE /program-items/{id}` mit Berechtigungen, Zeitraum- und Zustandsprüfung
- [ ] Event `program.changed` (komplette sortierte Liste), Snapshot `program_items`
- [ ] Bleibt bei der Anonymisierung erhalten (Test)
- [ ] Web: Seite „Tagesablauf“ für Leitstelle (Liste nach Zeit, anlegen/bearbeiten/löschen, Typ-Auswahl)
- [ ] Monitor-Standby: aktueller + nächster Programmpunkt, wechselt anhand der Uhr
- [ ] App: Bereich „Tagesablauf“, aktueller Punkt hervorgehoben, vergangene ausgegraut
- [ ] `just gen-api`, Doku (`04-api`, `03-datenmodell`, `06-clients`), E2E-Schritt
- [ ] Tests laut Spec „Testing Decisions“

Spec: `.scratch/v2/spec.md` · Glossar: `CONTEXT.md`
