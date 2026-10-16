# ux-02 — Designsystem und Screen-Konzepte

**What to build:** Ein Designsystem und für jeden Screen von Admin-Web, Monitor und App ein abgenommenes
Konzept. Der Designer entwirft, der Architekt bespricht jedes Konzept mit ihm (Review auf der Kanban-Karte).
Danach schreibt der Architekt die Umsetzungs-Tickets. Details und vorab getroffene Entscheidungen:
`.scratch/ux/spec.md`.

**Blocked by:** ux-01 (der Designer arbeitet mit den echten Screenshots aus `docs/design/screenshots/before/`)

**Owner:** Architekt (zerlegt in Designer-Karten, reviewt sie), Designer

**Status:** done

- [x] `docs/design/design-system.md`: Farben (hell, dunkel, Monitor), Rot nur für Alarm/destruktiv,
      FMS-Statusfarben, Typografie-Skala, Abstände, Radien, Komponenten mit Zuständen, Icons, Bewegung,
      Barrierefreiheit, App-Icon/Favicon-Entwurf, Abbildung auf Flutter `ThemeData`/Theme-Extensions
- [x] Konzept je Screen unter `docs/design/screens/` (Admin-Web, Monitor, App; Liste in der Spec): Zweck,
      gefundene Usability-Probleme mit Screenshot-Beleg, neues Layout (Wireframe oder HTML-Mockup), alle
      Zustände, Interaktionen, testbare Akzeptanzkriterien, zu erhaltende `Key`s
- [x] Mockups der Schlüssel-Screens (mindestens Lage, Monitor-Standby, Monitor-Alarm, App-Alarm,
      Mein Fahrzeug) als HTML + PNG in `docs/design/mockups/`
- [x] Jedes Konzept vom Architekten abgenommen (max. 2 Änderungsrunden, danach entscheidet der Architekt
      und vermerkt es im Konzept)
- [x] Umsetzungs-Tickets `.scratch/ux/issues/03-…` ff.: zuerst Designsystem (Theme, Schrift, Icon,
      gemeinsame Widgets), dann je Bereich/Screen-Gruppe; letztes Ticket Abschluss-Regression (Tester).
      Jedes mit „Blocked by“, Verweis auf das Konzept und „Keys + Semantics bleiben erhalten“
- [x] Epics der Umsetzungs-Tickets auf dem Board angelegt, sequenziell verkettet; jedes Epic endet mit einer
      Tester-Verifikationskarte

Spec: `.scratch/ux/spec.md` · Glossar: `CONTEXT.md`
