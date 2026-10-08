# 13 — Anonymisierung eines BF-Tags

**What to build:** Die Leitstelle anonymisiert einen beendeten BF-Tag manuell. Danach sind alle Personenbezüge entfernt, Einsätze mit Meldebild und Drehbuch bleiben aber für künftige BF-Tage erhalten (ADR 0007).

**Blocked by:** 08

**Status:** ready-for-agent

- [ ] Anonymisierung nur für beendete BF-Tage; setzt `anonymized_at`; nicht wiederholbar
- [ ] Löscht Teilnahmen, Besatzungen und Empfänger/Quittierungen des BF-Tags
- [ ] Entfernt den Personenbezug in der Statushistorie
- [ ] Löscht Personen anderer Feuerwehren ohne weitere Teilnahme
- [ ] Behält Einsätze (Meldebild, Drehbuch), Alarmierungen und Fahrzeuge
- [ ] Bestätigungsdialog im Web mit Zusammenfassung, was gelöscht wird
- [ ] Tests: Ergebnis pro Datenart, Berechtigung (Leitstelle/Admin), laufender BF-Tag nicht anonymisierbar

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
