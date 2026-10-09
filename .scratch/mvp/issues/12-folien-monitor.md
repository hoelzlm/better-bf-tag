# 12 — Folien im Monitor-Standby

**What to build:** Der Administrator pflegt Folien mit Titel, Text, optionalem Bild und Anzeigedauer. Der Monitor zeigt sie im Standby rotierend, und Änderungen erscheinen ohne Neuladen.

**Blocked by:** 03

**Status:** done

- [x] Folien anlegen, bearbeiten, sortieren, aktivieren/deaktivieren; Text als Markdown
- [x] Bild-Upload (Größe und Typ begrenzt), Auslieferung an Monitore
- [x] Monitor rotiert aktive Folien nach Anzeigedauer neben Uhr und Fahrzeugstatus
- [x] Event `slides.changed`
- [x] Tests: nur Administrator pflegt Folien, Upload-Validierung, Monitor erhält Folien im Snapshot

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
