# 13 — Anonymisierung eines BF-Tags

**What to build:** Die Leitstelle anonymisiert einen beendeten BF-Tag manuell. Danach sind alle Personenbezüge entfernt, Einsätze mit Meldebild und Drehbuch bleiben aber für künftige BF-Tage erhalten (ADR 0007).

**Blocked by:** 08

**Status:** done

- [x] Anonymisierung nur für beendete BF-Tage; setzt `anonymized_at`; nicht wiederholbar
- [x] Löscht Teilnahmen, Besatzungen und Empfänger/Quittierungen des BF-Tags
- [x] Entfernt den Personenbezug in der Statushistorie
- [x] Löscht Personen anderer Feuerwehren ohne weitere Teilnahme
- [x] Behält Einsätze (Meldebild, Drehbuch), Alarmierungen und Fahrzeuge
- [x] Bestätigungsdialog im Web mit Zusammenfassung, was gelöscht wird
- [x] Tests: Ergebnis pro Datenart, Berechtigung (Leitstelle/Admin), laufender BF-Tag nicht anonymisierbar

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
