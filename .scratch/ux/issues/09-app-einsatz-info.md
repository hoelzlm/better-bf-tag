# ux-09 — App Einsatz und Info: Einsätze, Einsatzdetail, Alarm, Tagesablauf, Durchsagen

**What to build:** Die Einsatz- und Informations-Screens der App werden umgebaut; der Alarm-Screen ist in
hell und dunkel vollflächig und eindeutig. Bestehende Keys und Semantics-Labels bleiben erhalten.

**Blocked by:** ux-08

**Owner:** Architekt (zerlegt in Coder-Karten), Coder, Reviewer, Tester

**Status:** ready-for-agent

- [ ] Umgesetzt nach den Konzepten (Layout, alle Zustände, Interaktionen, Akzeptanzkriterien):
      `docs/design/screens/app-einsaetze.md`, `app-einsatzdetail.md`, `app-alarm.md`,
      `app-tagesablauf.md`, `app-durchsagen.md`
- [ ] Referenz-Mockups: `docs/design/mockups/app-einsatzdetail.png`, `app-alarm-light.png`,
      `app-alarm-dark.png`
- [ ] Jedes Akzeptanzkriterium der Konzepte ist durch einen Widget-Test oder (rein visuell) durch die
      Nachher-Screenshots belegt (390x844 und 360x640, hell und dunkel)
- [ ] Alarm-Screen: Erstalarm/Nachalarmierung über Label + Icon unterschieden, nicht über Rottöne;
      kein Blinken, Reduced Motion respektiert (Designsystem 5.11, §7)
- [ ] Touch-Ziele ≥ 48 dp, Semantics-Labels an Icon-Buttons (`meetsGuideline` in den Widget-Tests)
- [ ] Bestehende Widget-`Key`s und Semantics-Labels bleiben erhalten (Abschnitt „Zu erhaltende Keys“ der
      Konzepte); kein Verhaltenstest gelöscht oder abgeschwächt, Anpassungen nur bei laut Konzept geändertem
      Text/Layout
- [ ] Keine neuen Funktionen, keine Backend-/API-Änderungen; keine Funktion fällt weg (Abgleich mit
      `docs/testing/regression-inventory.md` und dem Regressions-Abschnitt der Konzepte)
- [ ] Farben, Abstände, Radien und Schrift nur aus dem Theme (ux-03); keine harten Farbwerte in den
      betroffenen Dateien
- [ ] `just screenshots after` erzeugt die App-PNGs des Bereichs (committet); sie entsprechen sichtbar
      Konzept und Mockups
- [ ] `just test`, `just analyze`, `just e2e` grün; CI auf GitHub grün
- [ ] Tester-Verifikation abgeschlossen

Spec: `.scratch/ux/spec.md` · Designsystem: `docs/design/design-system.md` · ADR: `docs/adr/0027-designsystem-umsetzung.md` · Glossar: `CONTEXT.md`
