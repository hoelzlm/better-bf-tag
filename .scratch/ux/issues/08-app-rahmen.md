# ux-08 — App Rahmen: Navigationsleiste, Onboarding, Kopplung, Mein Fahrzeug, Einstellungen

**What to build:** Die App erhält die neue Navigationsleiste und die überarbeiteten Einstiegs- und
Fahrzeug-Screens, in hell und dunkel. Bestehende Keys und Semantics-Labels bleiben erhalten.

**Blocked by:** ux-07

**Owner:** Architekt (zerlegt in Coder-Karten), Coder, Reviewer, Tester

**Status:** done

Hinweis: Kein Badge-Punkt an der Navigationsleiste (ADR 0027, `app-navigation.md` §4).

- [x] Umgesetzt nach den Konzepten (Layout, alle Zustände, Interaktionen, Akzeptanzkriterien):
      `docs/design/screens/app-navigation.md`, `app-onboarding.md`, `app-kopplung.md`,
      `app-mein-fahrzeug.md`, `app-einstellungen.md`
- [x] Referenz-Mockups: `docs/design/mockups/app-onboarding.png`, `app-mein-fahrzeug.png`
- [x] Jedes Akzeptanzkriterium der Konzepte ist durch einen Widget-Test oder (rein visuell) durch die
      Nachher-Screenshots belegt (390x844 und 360x640, hell und dunkel)
- [x] Touch-Ziele ≥ 48 dp, Semantics-Labels an Icon-Buttons (`meetsGuideline` in den Widget-Tests)
- [x] Bestehende Widget-`Key`s und Semantics-Labels bleiben erhalten (Abschnitt „Zu erhaltende Keys“ der
      Konzepte); kein Verhaltenstest gelöscht oder abgeschwächt, Anpassungen nur bei laut Konzept geändertem
      Text/Layout
- [x] Keine neuen Funktionen, keine Backend-/API-Änderungen; keine Funktion fällt weg (Abgleich mit
      `docs/testing/regression-inventory.md` und dem Regressions-Abschnitt der Konzepte)
- [x] Farben, Abstände, Radien und Schrift nur aus dem Theme (ux-03); keine harten Farbwerte in den
      betroffenen Dateien
- [x] `just screenshots after` erzeugt die App-PNGs des Bereichs (committet); sie entsprechen sichtbar
      Konzept und Mockups
- [x] `just test`, `just analyze`, `just e2e` grün; CI auf GitHub grün
- [x] Tester-Verifikation abgeschlossen

Spec: `.scratch/ux/spec.md` · Designsystem: `docs/design/design-system.md` · ADR: `docs/adr/0027-designsystem-umsetzung.md` · Glossar: `CONTEXT.md`
