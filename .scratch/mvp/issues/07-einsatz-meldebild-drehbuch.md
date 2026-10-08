# 07 — Einsatz mit Meldebild und Drehbuch planen

**What to build:** Die Einsatzvorbereitung legt für den BF-Tag Einsätze an: Meldebild (Stichwort, Adresse, Lagebeschreibung) und ein deutlich als geheim markiertes Drehbuch. Die Mannschaft sieht in der App die Einsatzliste nur mit Meldebild, und das Drehbuch verlässt den Server nie in Richtung Mannschaft oder Monitor.

**Blocked by:** 05

**Status:** ready-for-agent

- [ ] Einsätze anlegen (Entwurf), bearbeiten (auch laufend, nicht abgeschlossen), verwerfen (nur Entwurf); Nummerierung pro BF-Tag
- [ ] Einsatzliste im Web mit Filter Entwurf/laufend/abgeschlossen
- [ ] Editor: Drehbuch-Feld visuell klar als „geheim“ abgesetzt
- [ ] Serverseitige Filterung: Drehbuch fehlt in allen Antworten, Snapshots und Events für Mannschaft und Monitor
- [ ] App: Einsatzliste und Einsatzdetail mit Meldebild; Drehbuch nur bei Einsatzvorbereitung/Leitstelle/Administrator
- [ ] Events `incident.created`, `incident.updated` (Empfänger nach Berechtigung)
- [ ] Tests: Berechtigungen (Einsatzvorbereitung/Leitstelle anlegen, Mannschaft nicht), Drehbuch-Filter auf jedem Weg (REST-Liste, Detail, Snapshot, WebSocket), Zustandsregeln beim Bearbeiten/Verwerfen

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
