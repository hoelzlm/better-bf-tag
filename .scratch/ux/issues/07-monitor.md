# ux-07 — Monitor: Kopplung, Standby, Einsatzansicht, Alarm

**What to build:** Der Monitor wird für den Fernseher (1920x1080, 5–10 m Leseabstand) umgebaut: dunkles
Monitor-Theme (`bftagMonitorTheme()`), Monitor-Typskala (`BftagMonitorTextStyles`), Standby, Einsatzansicht
mit Karte und Alarmzustand. Bestehende Keys und Semantics-Labels bleiben erhalten.

**Blocked by:** ux-06

**Owner:** Architekt (zerlegt in Coder-Karten), Coder, Reviewer, Tester

**Status:** done

- [x] Umgesetzt nach den Konzepten (Layout, alle Zustände, Interaktionen, Akzeptanzkriterien):
      `docs/design/screens/monitor-kopplung.md`, `monitor-standby.md`, `monitor-einsatz.md`,
      `monitor-alarm.md` (inkl. 20-s-Alarmphase und ihrer Randfälle)
- [x] Referenz-Mockups: `docs/design/mockups/monitor-kopplung.png`, `monitor-aktivierung.png`,
      `monitor-standby.png`, `monitor-einsatz.png`, `monitor-einsatz-fallback.png`, `monitor-alarm.png`
- [x] Jedes Akzeptanzkriterium der Konzepte ist durch einen Widget-/E2E-Test oder (rein visuell) durch die
      Nachher-Screenshots belegt
- [x] Kein Blinken des ganzen Screens; Reduced Motion schaltet Puls/Übergänge ab (Designsystem §7)
- [x] Bestehende Widget-`Key`s und Semantics-Labels bleiben erhalten (Abschnitt „Zu erhaltende Keys“ der
      Konzepte); kein Verhaltenstest gelöscht oder abgeschwächt, Anpassungen nur bei laut Konzept geändertem
      Text/Layout
- [x] Keine neuen Funktionen, keine Backend-/API-Änderungen; keine Funktion fällt weg (Abgleich mit
      `docs/testing/regression-inventory.md` und dem Regressions-Abschnitt der Konzepte)
- [x] Farben, Abstände, Radien und Schrift nur aus dem Theme (ux-03); keine harten Farbwerte in den
      betroffenen Dateien
- [x] `just screenshots after` erzeugt die Monitor-PNGs (committet); sie entsprechen sichtbar Konzept und Mockups
- [x] `just test`, `just analyze`, `just e2e` grün; CI auf GitHub grün
- [x] Tester-Verifikation abgeschlossen

Spec: `.scratch/ux/spec.md` · Designsystem: `docs/design/design-system.md` · ADR: `docs/adr/0027-designsystem-umsetzung.md` · Glossar: `CONTEXT.md`
