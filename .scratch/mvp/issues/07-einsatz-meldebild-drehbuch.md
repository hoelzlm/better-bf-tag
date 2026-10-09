# 07 — Einsatz mit Meldebild und Drehbuch planen

**What to build:** Die Einsatzvorbereitung legt für den BF-Tag Einsätze an: Meldebild (Stichwort, Adresse, Lagebeschreibung) und ein deutlich als geheim markiertes Drehbuch. Die Mannschaft sieht in der App die Einsatzliste nur mit Meldebild, und das Drehbuch verlässt den Server nie in Richtung Mannschaft oder Monitor.

**Blocked by:** 05

**Status:** done

- [x] Einsätze anlegen (Entwurf), bearbeiten (auch laufend, nicht abgeschlossen), verwerfen (nur Entwurf); Nummerierung pro BF-Tag
- [x] Einsatzliste im Web mit Filter Entwurf/laufend/abgeschlossen
- [x] Editor: Drehbuch-Feld visuell klar als „geheim“ abgesetzt
- [x] Serverseitige Filterung: Drehbuch fehlt in allen Antworten, Snapshots und Events für Mannschaft und Monitor
- [x] App: Einsatzliste und Einsatzdetail mit Meldebild; Drehbuch nur bei Einsatzvorbereitung/Leitstelle/Administrator
- [x] Events `incident.created`, `incident.updated` (Empfänger nach Berechtigung)
- [x] Tests: Berechtigungen (Einsatzvorbereitung/Leitstelle anlegen, Mannschaft nicht), Drehbuch-Filter auf jedem Weg (REST-Liste, Detail, Snapshot, WebSocket), Zustandsregeln beim Bearbeiten/Verwerfen

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
