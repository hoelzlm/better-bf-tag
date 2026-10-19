# ux-10 — Abschluss-Regression

**What to build:** Kompletter Abschluss-Durchlauf der UI/UX-Überarbeitung: alle Suites, Screenshot-Vergleich
vorher/nachher aller Screens, Bericht in `docs/design/review.md`. Gefundene Fehler gehen als Fix-Karten an den
Coder, bis der Bericht keine offenen Abweichungen mehr enthält.

**Blocked by:** ux-09

**Owner:** Tester (Fix-Karten: Coder, Review: Reviewer)

**Status:** done

- [x] `just test`, `just analyze`, `just e2e` grün; CI auf GitHub grün
- [x] `just screenshots after` vollständig: für jede PNG in `docs/design/screenshots/before/` existiert dieselbe
      Datei unter `after/`
- [x] `docs/design/review.md`: je Screen Vorher-/Nachher-Bild, Abgleich mit Konzept und Akzeptanzkriterien,
      Abweichungen mit Begründung oder Fix-Verweis
- [x] Regressions-Inventar (`docs/testing/regression-inventory.md`) ohne Lücke; keine Funktion fehlt
- [x] Keys und Semantics: alle in den Konzepten gelisteten `Key`s sind im Code vorhanden (Skript-Abgleich,
      Ergebnis im Bericht)
- [x] Keine harten Farben mehr in `apps/*/lib` (`grep -rnE "Colors\.(red|green|orange|blue|amber)|Color\(0x"`
      liefert nur begründete, im Bericht gelistete Ausnahmen); kein `ColorScheme.fromSeed`/`colorSchemeSeed`
- [x] Barrierefreiheit-Stichprobe: Fokusring im Web per Tab sichtbar, Touch-Ziele ≥ 48 dp und
      Semantics-Labels an Icon-Buttons (`meetsGuideline(androidTapTargetGuideline)` /
      `labeledTapTargetGuideline` in App-Widget-Tests)

Spec: `.scratch/ux/spec.md` · Designsystem: `docs/design/design-system.md` · ADR: `docs/adr/0027-designsystem-umsetzung.md` · Glossar: `CONTEXT.md`
