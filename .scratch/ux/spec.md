# Spec: UX — UI/UX-Überarbeitung aller Oberflächen

**Status:** ready-for-agent

Fachbegriffe: `CONTEXT.md`. Baut auf dem fertigen Stand von MVP und v2 auf (`.scratch/mvp/`, `.scratch/v2/`).

## Problem Statement

Die Software ist funktional vollständig und benutzbar, sieht aber aus wie ein Flutter-Standardprojekt:
Material-3-Defaults mit rotem Seed (`ColorScheme.fromSeed(Colors.red)` in `packages/core/lib/src/theme.dart`,
die App hat zusätzlich ein eigenes `ThemeData` in `apps/mobile/lib/main.dart`). Rot ist überall, dadurch
sticht der Alarm nicht mehr heraus. Die Screens sind einzeln gewachsen, ohne gemeinsames Layout-,
Abstands- und Komponentensystem. Der Monitor ist für einen Fernseher in 5–10 m Entfernung nicht optimiert.

## Solution

Ein **UI/UX-Designer** (Agent) erarbeitet ein Designsystem und für **jeden Screen** von Admin-Web, Monitor
und App ein Konzept. Jedes Konzept wird mit dem **Architekten** besprochen (Review-Runde auf der Kanban-Karte).
Aus den abgenommenen Konzepten schreibt der Architekt Umsetzungs-Tickets für den Coder. Ein **Tester** baut
vorher ein Regressionsnetz und prüft jedes Umsetzungs-Ticket, damit keine neuen Fehler entstehen.

Schwerpunkt ist **Benutzbarkeit**; das Ergebnis soll zusätzlich modern und hochwertig aussehen.

## Entscheidungen (vorab getroffen, nicht erneut diskutieren)

- **Rot = Alarm.** Rot ist für Alarm, Erstalarm und destruktive Aktionen reserviert. Die Grundfarbe ist ein
  ruhiges, neutrales Schema (z. B. Schiefer/Anthrazit mit einer zurückhaltenden Akzentfarbe); die konkrete
  Palette legt der Designer fest.
- **Ein gemeinsames Designsystem** für Web und App in `packages/core` (`bftagTheme()` plus Theme-Extensions
  für Status-/Alarmfarben, Abstände, Radien). Das separate `ThemeData` in `apps/mobile/lib/main.dart` entfällt.
- **Monitor: dunkles Theme**, große Schrift, auf 1920x1080 aus 5–10 m lesbar.
- **App: hell und dunkel** nach Systemeinstellung. Der Alarm-Screen ist in beiden Modi vollflächig und eindeutig.
- **Admin-Web: Desktop zuerst** (ab 1280 px), bleibt auf Tablet-Breite bedienbar. Navigation als Seitenleiste.
- **FMS-Statusfarben** sind feste, überall gleiche Tokens (Monitor, Web, App).
- **Schrift als Asset** gebündelt (Inter oder vergleichbare OFL-Schrift), kein Laden zur Laufzeit
  (Datenschutz, Monitor offline-fähig).
- **Barrierefreiheit:** Kontrast mindestens WCAG AA (Monitor möglichst AAA), Touch-Ziele ≥ 48 dp,
  sichtbarer Fokus im Web, Semantics-Labels an Icon-Buttons.
- **App-Icon und Favicon** gehören zum Designsystem (gleiches Bildzeichen, einfach, auch klein erkennbar).
- **Keine neuen Funktionen.** Abläufe dürfen vereinfacht werden, wenn das Konzept es ausdrücklich begründet;
  keine Funktion fällt weg.
- **Stabile Test-Anker:** bestehende Widget-`Key`s und Semantics-Labels bleiben erhalten.

## Ablauf

1. **ux-01 Regressionsnetz und Screenshot-Baseline** (Tester): Inventar aller Screens und Funktionen, fehlende
   Verhaltenstests ergänzen, Screenshot-Harness, Vorher-Screenshots in `docs/design/screenshots/before/`.
2. **ux-02 Designsystem und Screen-Konzepte** (Designer ↔ Architekt): Designsystem, dann ein Konzept pro
   Screen, jeweils vom Architekten abgenommen. Abschluss: Architekt schreibt die Umsetzungs-Tickets
   `ux-03` ff. und legt deren Epics an.
3. **ux-03 ff. Umsetzung** (Coder, Review durch Reviewer, Abschluss durch Tester-Verifikation pro Ticket).
   Erstes Umsetzungs-Ticket ist immer das Designsystem (Theme, Schrift, Icon, gemeinsame Widgets).
4. **Letztes Ticket: Abschluss-Regression** (Tester): kompletter Durchlauf aller Suites, Screenshot-Vergleich
   aller Screens vorher/nachher, Bericht in `docs/design/review.md`.

## Screens im Umfang

- **Admin-Web** (`apps/web/lib/screens/`): Login, Lage, BF-Tage, Schichten, Personen, Fahrzeuge, Einsätze,
  Durchsagen, Tagesablauf, Folien, Monitore (Verwaltung), Navigation/Seitenleiste.
- **Monitor** (`apps/web/lib/screens/monitor_*`): Kopplung, Standby (Uhr, Fahrzeugstatus, Besatzung,
  Tagesablauf, Folien, Durchsage-Banner), Einsatzansicht mit Karte, Alarmzustand.
- **App** (`apps/mobile/lib/`): Onboarding, Kopplung, Mein Fahrzeug, Einsätze, Einsatzdetail, Alarm-Screen,
  Tagesablauf, Durchsagen, Einstellungen, Navigationsleiste.

## Testing Decisions

- Verhaltenstests suchen über `Key`/Semantics, prüfen Verhalten statt Farben oder Pixel. Sie entstehen in
  ux-01, **bevor** sich die Oberfläche ändert.
- Kein Test wird gelöscht oder abgeschwächt, um grün zu werden; Anpassungen nur dort, wo sich sichtbarer Text
  oder Layout laut Ticket ändert, und die Verhaltensprüfung bleibt.
- Screenshots: Web und Monitor über die E2E-Suite (Chrome, Produktions-Stack, ADR 0023), App über Widget-Tests
  mit geladenen echten Schriften (sonst Ahem-Blöcke). Größen: Desktop 1440x900, Monitor 1920x1080,
  Handy 390x844 und 360x640.
- `just test`, `just analyze`, `just e2e` bleiben grün; CI auf GitHub ebenfalls.

## Out of Scope

- Neue Funktionen, Backend- oder API-Änderungen (außer wenn ein Konzept zwingend ein Feld braucht: dann eigenes
  Ticket mit Begründung).
- Store-Grafiken, Marketing-Screenshots, Website.
- Mehrsprachigkeit (UI bleibt Deutsch).
