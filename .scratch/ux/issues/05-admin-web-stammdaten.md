# ux-05 — Admin-Web Stammdaten: BF-Tage, Schichten, Personen, Fahrzeuge

**What to build:** Die Stammdaten-Screens des Admin-Webs werden nach ihren Konzepten umgebaut (innerhalb der
`AdminShell` aus ux-04). Bestehende Keys und Semantics-Labels bleiben erhalten.

**Blocked by:** ux-04

**Owner:** Architekt (zerlegt in Coder-Karten), Coder, Reviewer, Tester

**Status:** ready-for-agent

- [ ] Umgesetzt nach den Konzepten (Layout, alle Zustände, Interaktionen, Akzeptanzkriterien):
      `docs/design/screens/web-bf-tage.md`, `web-schichten.md`, `web-personen.md`, `web-fahrzeuge.md`
- [ ] Referenz-Mockups: `docs/design/mockups/web-schichten.png`, `web-personen.png`
- [ ] Jedes Akzeptanzkriterium der Konzepte ist durch einen Widget-/E2E-Test oder (rein visuell) durch die
      Nachher-Screenshots belegt
- [ ] Bestehende Widget-`Key`s und Semantics-Labels bleiben erhalten (Abschnitt „Zu erhaltende Keys“ der
      Konzepte); kein Verhaltenstest gelöscht oder abgeschwächt, Anpassungen nur bei laut Konzept geändertem
      Text/Layout
- [ ] Keine neuen Funktionen, keine Backend-/API-Änderungen; keine Funktion fällt weg (Abgleich mit
      `docs/testing/regression-inventory.md` und dem Regressions-Abschnitt der Konzepte)
- [ ] Farben, Abstände, Radien und Schrift nur aus dem Theme (ux-03); keine harten Farbwerte in den
      betroffenen Dateien
- [ ] `just screenshots after` erzeugt die Nachher-PNGs des Bereichs (committet); sie entsprechen sichtbar
      Konzept und Mockups
- [ ] `just test`, `just analyze`, `just e2e` grün; CI auf GitHub grün
- [ ] Tester-Verifikation abgeschlossen

Spec: `.scratch/ux/spec.md` · Designsystem: `docs/design/design-system.md` · ADR: `docs/adr/0027-designsystem-umsetzung.md` · Glossar: `CONTEXT.md`
