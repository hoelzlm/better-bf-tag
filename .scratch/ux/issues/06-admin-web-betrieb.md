# ux-06 — Admin-Web Betrieb: Einsätze, Durchsagen, Tagesablauf, Folien, Monitore

**What to build:** Die Betriebs-Screens des Admin-Webs werden nach ihren Konzepten umgebaut, inkl. des
verkürzten kritischen Alarmierungs-Pfads (`web-einsaetze.md` §3.4). Bestehende Keys und Semantics-Labels
bleiben erhalten.

**Blocked by:** ux-05

**Owner:** Architekt (zerlegt in Coder-Karten), Coder, Reviewer, Tester

**Status:** ready-for-agent

- [ ] Umgesetzt nach den Konzepten (Layout, alle Zustände, Interaktionen, Akzeptanzkriterien):
      `docs/design/screens/web-einsaetze.md`, `web-durchsagen.md`, `web-tagesablauf.md`, `web-folien.md`,
      `web-monitore.md`
- [ ] Referenz-Mockups: `docs/design/mockups/web-einsaetze.png`, `web-einsaetze-alarm.png`,
      `web-einsaetze-laufend.png`, `web-folien.png`
- [ ] Jedes Akzeptanzkriterium der Konzepte ist durch einen Widget-/E2E-Test oder (rein visuell) durch die
      Nachher-Screenshots belegt; der kritische Pfad (Einsatz anlegen → alarmieren) läuft in `just e2e`
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
