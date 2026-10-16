# ADR 0027 – Designsystem: Umsetzung in Flutter und Ticket-Schnitt

- **Status:** Angenommen
- **Datum:** 2026-10-16

## Kontext

ux-02 hat das Designsystem (`docs/design/design-system.md`) und 27 Screen-Konzepte (`docs/design/screens/`)
abgenommen. Offen für die Umsetzung (ux-03 ff.) waren: wo Theme, Schrift und gemeinsame Widgets liegen, wie
der Monitor sein dunkles Theme bekommt (Web-App und Monitor teilen sich eine `MaterialApp`), wie App-Icon und
Favicon in die Plattformprojekte kommen, wie Tests mit dem neuen Theme umgehen und welcher Badge-Vorschlag
aus Designsystem 5.9 umgesetzt wird.

## Entscheidung

### Theme und Schrift

- `packages/core/lib/src/theme.dart` (bei Bedarf aufgeteilt in `packages/core/lib/src/theme/`) implementiert die
  API aus Designsystem §10 exakt: `enum BftagThemeMode`, `bftagTheme(BftagThemeMode)`, `bftagLightTheme()`,
  `bftagDarkTheme()`, `bftagMonitorTheme()` sowie die Extensions `BftagStatusColors`, `BftagAlarmColors`,
  `BftagSpacing`, `BftagRadii`, `BftagMonitorTextStyles`. `ColorScheme` wird explizit aus Tabelle 2.1 gebaut
  (kein `fromSeed`). `ColorScheme.error` = `warning`-Token; Alarmrot nur in `BftagAlarmColors`.
- Die parameterlose Altsignatur `bftagTheme()` entfällt; alle Aufrufer werden umgestellt.
- Inter (OFL, die TTFs aus `docs/design/mockups/fonts/`) wird als Font-Asset in `packages/core` gebündelt
  (Ziel `packages/core/assets/fonts/` inkl. `OFL.txt`, Gewichte 400/500/600/700, `pubspec.yaml`
  `fonts:`-Block, Familie `Inter`; im Theme `fontFamily: 'Inter', package: 'bftag_core'` bzw.
  `'packages/bftag_core/Inter'`). Icons: Flutter-Standard `Icons.*` (Material Icons, mit Flutter gebündelt,
  kein Laufzeit-Laden); Outlined-Varianten (`Icons.*_outlined`) wo vorhanden (Designsystem §6).

### Monitor-Theme

Die Web-App behält **eine** `MaterialApp` (`theme: bftagLightTheme()`). Die Monitor-Routen (`/monitor…`)
werden in `Theme(data: bftagMonitorTheme(), child: …)` gehüllt; so bleibt das Routing unverändert und der
Monitor ist immer dunkel, unabhängig vom Betriebssystem-Modus.

### App

`apps/mobile/lib/main.dart`: `theme: bftagLightTheme(), darkTheme: bftagDarkTheme(), themeMode:
ThemeMode.system`. Das eigene `ThemeData(colorSchemeSeed: Colors.red …)` entfällt.

### Gemeinsame Widgets

Neu in `packages/core/lib/src/widgets/` (exportiert über die Paket-Bibliothek), rein darstellend, ohne
Provider-Abhängigkeit:

- `FmsBadge` – FMS-Status als Fläche + Ziffer + Text (Designsystem 5.5), Farben aus `BftagStatusColors`.
- `BftagStateView` – Lade-/Leer-/Fehlerzustand (Designsystem 5.10) mit benannten Konstruktoren
  `.loading()`, `.empty(...)`, `.error(..., onRetry)`.
- `ConnectionBanner` – Offline-/Verbindungsbanner (Designsystem 5.10), Eingabe ist ein `bool`/Status,
  die Provider-Anbindung macht die jeweilige Oberfläche.

Bereichsspezifische Bausteine (`AdminShell`, Monitor-Alarmfläche, App-Alarmfläche) entstehen in den
Bereichstickets in der jeweiligen App.

### App-Icon und Favicon

Quelle ist `docs/design/icon/`. Web: `apps/web/web/favicon.png`, `icons/Icon-*.png` und `manifest.json`
(`theme_color`/`background_color` = `primary`) werden aus den SVGs neu erzeugt, zusätzlich `favicon.svg`
in `index.html`. App: Android-Launcher-Icons (inkl. adaptive + monochrom) und iOS-AppIcon-Set werden aus
den PNG-/SVG-Quellen erzeugt. Ein Generator (z. B. `flutter_launcher_icons` als dev-dependency) ist erlaubt,
die erzeugten Dateien werden committet.

### Tests

Verhaltenstests bleiben unangetastet, außer wo ein Konzept sichtbaren Text/Layout ändert (Spec, „Testing
Decisions“). Neue Unit-/Widget-Tests für Theme (Kontrast-Stichproben, `ColorScheme.error != alarm`,
Extensions vorhanden in allen drei Modi) und für die gemeinsamen Widgets. Screenshot-Harness lädt Inter
statt Ahem. Nach jedem Bereichsticket erzeugt `just screenshots after` den Nachher-Stand für den Bereich.

### Badge an der App-Navigationsleiste

Designsystem 5.9 erwähnt einen Badge-Punkt für ungelesene Durchsagen/aktive Alarme. Dafür fehlen Daten
(kein Lese-Status). Er wird **nicht** umgesetzt (Spec: keine neuen Funktionen); `app-navigation.md` §4 gilt.

### Ticket-Schnitt

ux-03 Designsystem im Code → ux-04 Admin-Web Rahmen (Navigation, Login, Lage) → ux-05 Admin-Web Stammdaten
(BF-Tage, Schichten, Personen, Fahrzeuge) → ux-06 Admin-Web Betrieb (Einsätze, Durchsagen, Tagesablauf,
Folien, Monitore) → ux-07 Monitor → ux-08 App Rahmen (Navigation, Onboarding, Kopplung, Mein Fahrzeug,
Einstellungen) → ux-09 App Einsatz und Info (Einsätze, Einsatzdetail, Alarm, Tagesablauf, Durchsagen) →
ux-10 Abschluss-Regression. Sequenziell, damit sich parallele Zweige nicht in `router.dart`, `main.dart`
und den gemeinsamen Widgets überschneiden.

## Konsequenzen

- Jede Oberfläche bezieht Farben, Abstände und Radien nur noch aus dem Theme; harte `Colors.red` u. ä.
  in `apps/` sind nach ux-09 nicht mehr zulässig (ux-10 prüft das per `grep`).
- `packages/core` wird größer (Fonts ca. 1–2 MB); dafür keine Laufzeit-Downloads (Datenschutz, Monitor offline).
- Der Monitor kann nicht versehentlich hell werden; ein späterer heller Monitor-Modus wäre eine neue Funktion.
