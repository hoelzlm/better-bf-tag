# Designsystem BF-Tag

Status: Entwurf (ux-02a) · Grundlage für alle Screen-Konzepte (ux-02b–e) und die Umsetzung (ux-03 ff.)

Heute sehen alle drei Oberflächen aus wie ein unbearbeitetes Flutter-Beispielprojekt: `ColorScheme.fromSeed(Colors.red)`
in `packages/core/lib/src/theme.dart`, ein zweites, abweichendes `ThemeData` in `apps/mobile/lib/main.dart`, Rot
überall (Buttons, FMS-Status, Icons) — der Alarm sticht dadurch nicht mehr heraus. Screens haben kein gemeinsames
Abstands-/Komponentenraster; der Monitor ist nicht für 5–10 m Leseabstand ausgelegt (siehe
`docs/design/screenshots/before/`, geprüft für Lage, Monitor-Standby/Alarm, App-Alarm, Mein Fahrzeug).

Dieses Dokument legt die Tokens, Komponenten und die Flutter-Abbildung fest. Screen-spezifische Konzepte folgen
in `docs/design/screens/*.md` (separate Karten) und bauen strikt hierauf auf.

## 1. Grundprinzip

- **Rot ist ausschließlich für Alarm (inkl. Erstalarm) und destruktive Aktionen reserviert.** Keine andere
  Verwendung — kein Rot in Navigation, Primärbutton, Branding, Icons außerhalb dieser beiden Fälle.
- Neutrale Basis: Schiefer/Anthrazit-Graustufen, eine zurückhaltende Akzentfarbe (Petrol/Dunkelblau) für
  Primärhandlungen, Links, aktive Zustände.
- Ein gemeinsames System für Web und App über `packages/core`; der Monitor nutzt dieselben Tokens, aber nur die
  dunkle Variante in größerer Skala.

## 2. Farbpalette

### 2.1 Neutral- und Akzentfarben (Tokens)

| Token               | Hell       | Dunkel/Monitor | Verwendung                                  |
|---------------------|------------|-----------------|----------------------------------------------|
| `surface`           | `#FFFFFF`  | `#14181C`       | Seiten-/App-Hintergrund                      |
| `surfaceVariant`    | `#F1F3F5`  | `#1C2126`       | Karten, Seitenleiste, Tabellenkopf           |
| `surfaceContainer`  | `#E8EAED`  | `#242A30`       | Eingebettete Flächen, Dialoge                |
| `outline`           | `#C9CED3`  | `#3A4147`       | Trennlinien, Rahmen (default)                 |
| `onSurface`         | `#1B1F23`  | `#EDEFF1`       | Primärtext                                    |
| `onSurfaceVariant`  | `#4C555C`  | `#AAB2B8`       | Sekundärtext, Hinweise                        |
| `primary`           | `#0B5E6B`  | `#4FB8C9`       | Primärbutton, aktive Navigation, Links, Fokus |
| `onPrimary`         | `#FFFFFF`  | `#06262B`       | Text/Icon auf `primary`                       |
| `primaryContainer`  | `#D6EEF2`  | `#0E3A42`       | gefüllte Chips, ausgewählte Zeile             |
| `alarm`             | `#D32F2F`  | `#FF5449`       | Alarmfläche, Erstalarm, destruktive Buttons   |
| `onAlarm`           | `#FFFFFF`  | `#1A0000`       | Text/Icon auf `alarm`                         |
| `alarmContainer`    | `#FBE9E7`  | `#4A1410`       | Alarm-Badges, dezente Warnflächen             |
| `warning`           | `#B45309`  | `#F2A93B`       | Formular-/Validierungsfehler, Fehlerzustand   |
| `onWarning`         | `#FFFFFF`  | `#1A1100`       | Text/Icon auf `warning`                       |
| `warningContainer`  | `#FDECD2`  | `#4A2E08`       | Fehler-Banner, dezente Warnflächen            |

`warning` ist eine eigene Fläche für Formularfehler/Validierung (Gelb/Orange-Familie, **nicht** `alarm`-Rot) —
Begründung und Flutter-Mapping (`ColorScheme.error`) siehe Abschnitt 5.2/5.10. `alarm` bleibt ausschließlich für
echten Alarm und destruktive Aktionen reserviert (Grundprinzip 1) und lebt in Flutter nur in `BftagAlarmColors`,
nicht in `ColorScheme.error`.

Petrol (`#0B5E6B` / `#4FB8C9`) statt Blau vermeidet Verwechslung mit Status 7/8 (FMS-Blau, s. u.) und bleibt klar
von Rot getrennt. Alle Paarungen Text-auf-Fläche oben erreichen WCAG AA (≥ 4.5:1 für Fließtext, ≥ 3:1 für große
Schrift/Icons); die Monitor-Spalte erreicht AAA bis auf eine dokumentierte, bewusste Abweichung (siehe 2.3).

### 2.2 Dunkel-Modus: App und Monitor sind identisch

App-Dark nutzt exakt dieselben Tokenwerte wie die Spalte „Dunkel/Monitor“ in Tabelle 2.1 — keine zweite,
abweichende Palette. Das schließt alle dort gelisteten Rollen ein (`surface`, `surfaceVariant`,
`surfaceContainer`, `outline`, `onSurface`, `onSurfaceVariant`, `primary`, `onPrimary`, `primaryContainer`,
`alarm`, `onAlarm`, `alarmContainer`, `warning`, `onWarning`, `warningContainer`). Grund: ein Betreuer, der
abends zwischen App (Dunkel) und Monitor wechselt, soll dieselben Statusfarben wiedererkennen, nicht zwei leicht
verschobene Varianten lernen müssen. Die App folgt dem System-Theme (hell/dunkel über `ThemeMode.system`); der
Alarm-Screen ist in beiden Modi vollflächig `alarm`/`onAlarm` — siehe `docs/design/screens/app-alarm.md`.

### 2.3 Kontrastprüfung

Werte berechnet mit `docs/design/tools/contrast.py` (stdlib-only, WCAG-Formel über relative Luminanz, sRGB).
Bei jeder Änderung an einem Hex-Wert dieses Skript neu laufen lassen und die Tabelle aktualisieren — Werte hier
sind kein Schätzwert, sondern direkter Skript-Output.

| Kombination                                        | Verhältnis | Ziel     | Ergebnis |
|------------------------------------------------------|-----------:|----------|----------|
| `onSurface` #1B1F23 auf `surface` #FFFFFF (hell)     | 16.58:1    | AA 4.5:1 | ✅ AAA   |
| `onSurfaceVariant` #4C555C auf `surface` (hell)      | 7.61:1     | AA 4.5:1 | ✅ AAA   |
| `onPrimary` #FFFFFF auf `primary` #0B5E6B (hell)     | 7.43:1     | AA 4.5:1 | ✅ AAA   |
| `onAlarm` #FFFFFF auf `alarm` #D32F2F (hell)         | 4.98:1     | AA 4.5:1 | ✅ AA    |
| `onWarning` #FFFFFF auf `warning` #B45309 (hell)     | 5.02:1     | AA 4.5:1 | ✅ AA    |
| Monitor: `onSurface` #EDEFF1 auf `surface` #14181C   | 15.48:1    | AAA 7:1  | ✅ AAA   |
| Monitor: `onPrimary` #06262B auf `primary` #4FB8C9   | 6.84:1     | AAA 7:1  | ⚠️ AA (6.84:1), knapp unter AAA — akzeptiert, Primärfläche ist auf dem Monitor Navigation/Akzent, kein Fließtext |
| Monitor: `onAlarm` #1A0000 auf `alarm` #FF5449       | 6.34:1     | AAA 7:1 (knapp verfehlt) | ⚠️ AA (6.34:1), akzeptiert: helles Alarmrot muss auf 10 m sättigungsstark bleiben; Text zusätzlich fett + groß gesetzt (siehe 2.4/3.2) |
| Monitor: `onWarning` #1A1100 auf `warning` #F2A93B   | 9.35:1     | AAA 7:1  | ✅ AAA   |

Bekannte, bewusste Abweichung von AAA bleibt auf `onPrimary`/`primary` und `onAlarm`/`alarm` am Monitor begrenzt
(siehe Begründung oben); beide liegen weiterhin deutlich über dem AA-Minimum.

### 2.4 FMS-Statusfarben (fixe Tokens, Monitor/Web/App identisch)

Heutiger Code verwendet Material-Named-Colors inkonsistent (`vehicle_status_bar.dart`: `Colors.green/orange/red/
amber/grey/blue`) — u. a. ist FMS 4 „Am Einsatzort“ rot, kollidiert mit der Alarmfarbe. Neu: eigene Palette,
nirgends identisch mit `alarm`.

| FMS | Bedeutung               | Token  | Hex       | Text/Icon-Farbe | Kontrast (Text/Icon auf Fläche) |
|-----|--------------------------|--------|-----------|------------------|----------------------------------|
| 1   | Einsatzbereit über Funk  | `fms1` | `#2E7D32` | `#FFFFFF`        | 5.13:1 ✅ |
| 2   | Einsatzbereit auf Wache  | `fms2` | `#43A047` | `#0B1F0D`        | 5.23:1 ✅ |
| 3   | Einsatz übernommen       | `fms3` | `#F2A900` | `#1B1300`        | 9.17:1 ✅ |
| 4   | Am Einsatzort            | `fms4` | `#7A3FC2` | `#FFFFFF`        | 6.33:1 ✅ |
| 5   | Sprechwunsch             | `fms5` | `#AD1A72` | `#FFFFFF`        | 6.63:1 ✅ |
| 6   | Nicht einsatzbereit      | `fms6` | `#6B7280` | `#FFFFFF`        | 4.83:1 ✅ |
| 7   | Patient aufgenommen      | `fms7` | `#2660D1` | `#FFFFFF`        | 5.71:1 ✅ |
| 8   | Am Transportziel         | `fms8` | `#1455B0` | `#FFFFFF`        | 7.10:1 ✅ |

Werte aus `docs/design/tools/contrast.py`. FMS 4 wurde gegenüber dem ersten Entwurf dunkler gesetzt (`#8E5CD9`
verfehlte mit 4.48:1 WCAG AA); FMS 7 ebenfalls leicht dunkler (ursprünglich 4.55:1, jetzt 5.71:1), beide jetzt mit
klarer AA-Reserve. FMS 4 bewusst Lila/Violett, nicht Rot, um jede Verwechslung mit Alarm zu vermeiden.

**FMS 5 (Sprechwunsch) hat eine eigene Farbe (Magenta/Pink `#AD1A72`), nicht mehr dieselbe Fläche wie FMS 3.**
Begründung: FMS 5 ist der einzige Status, bei dem die Leitstelle aktiv reagieren muss (Fahrzeug will funken) —
er muss auf dem Monitor aus 10 m auffallen, ohne auf ein kleines Icon angewiesen zu sein. Die Farbe ist bewusst
weder Rot/Alarm-Orange noch in der Nähe von FMS 3 (Gelb/Orange), FMS 4 (Violett), FMS 7/8 (Blau) oder FMS 1/2
(Grün) angesiedelt, um auch bei Rot-Grün-Schwäche unterscheidbar zu bleiben. Zusätzlich immer mit Icon
„Sprechblase“ und Label, nie nur über Farbe (WCAG 1.4.1). Es gibt **keinen Blinkrahmen** — falls FMS 5 zusätzlich
betont wird, nur über den ≤ 1 Hz-Puls aus Abschnitt 7 (unter Reduced-Motion deaktiviert, dann bleibt die Fläche
statisch sichtbar).

**FMS-Fuellfarben gegen den dunklen Monitor-/App-Dark-Hintergrund (`#14181C`):** keine der acht Flächen erreicht
dort zuverlässig 3:1 Kontrast zur Fläche selbst (`docs/design/tools/contrast.py`, Messwerte 2.51–5.40:1, die
meisten unter 3:1 — z. B. `fms8` 2.51:1, `fms5` 2.69:1, `fms4` 2.82:1). Die Pille ist auf dunklem Grund trotzdem
klar erkennbar, weil (a) der Text/Icon-auf-Fläche-Kontrast aus der Tabelle oben überall ≥ 4.8:1 bleibt und die
Nummer/das Label die Information trägt, nicht die Flächenabgrenzung, und (b) jede FMS-Pille auf dunklem Grund
zusätzlich einen 1 px `onSurface`-bei-24%-Rahmen erhält (feste Regel in Abschnitt 5.5), der die Kante der Fläche
vom Hintergrund trennt, unabhängig vom Farbton. Auf hellem Grund (Admin-Web) entfällt dieser Rahmen, da dort
alle Flächen ausreichend Kontrast zum weißen Hintergrund haben.

## 3. Typografie

**Schrift:** Inter (SIL OFL 1.1), als Asset gebündelt — kein Laufzeit-Download. Zu bundlende Dateien unter
`packages/core/assets/fonts/` (Vorschlag für ux-03, Umsetzung):

- `Inter-Regular.ttf` (400)
- `Inter-Medium.ttf` (500)
- `Inter-SemiBold.ttf` (600)
- `Inter-Bold.ttf` (700)

Quelle: offizielles Inter-Repo (`rsms/inter`, OFL-lizenziert), statische Instanzen reichen (kein Variable Font
nötig, kleinere Asset-Größe, einfachere `FontWeight`-Zuordnung in Flutter). Lizenzhinweis (`OFL.txt`) mit
ausliefern.

### 3.1 Skala — Web/App

| Rolle              | Größe/Zeilenhöhe | Gewicht   | Verwendung                         |
|---------------------|------------------|-----------|-------------------------------------|
| `displaySmall`      | 32/40            | SemiBold  | Alarm-Titel (App-Alarmscreen)       |
| `headlineSmall`     | 24/32            | SemiBold  | Seitentitel (Web), Screentitel (App)|
| `titleLarge`        | 20/28            | SemiBold  | Kartentitel, Dialogtitel            |
| `titleMedium`       | 16/24            | Medium    | Abschnittsüberschriften, Listenkopf |
| `bodyLarge`         | 16/24            | Regular   | Standardtext                        |
| `bodyMedium`        | 14/20            | Regular   | Sekundärtext, Tabellenzellen        |
| `labelLarge`        | 14/20            | Medium    | Buttons, Tabs                        |
| `labelMedium`       | 12/16            | Medium    | Chips, Badges, Meta-Infos           |

### 3.2 Monitor-Skala (eigenständig, 1920×1080, 5–10 m Leseabstand)

Faustregel TV: ~26 mm Zeichenhöhe pro Meter Leseabstand für sichere Lesbarkeit entspricht bei 1920×1080 auf
einem 55″-Panel (≈ 1,22 m Breite, ≈ 0,044 mm/px) grob **28–32 px je Meter** Mindestschriftgröße. Für 10 m
Maximaldistanz:

| Rolle                  | px (1920×1080) | Gewicht   | Verwendung                              |
|-------------------------|----------------|-----------|-------------------------------------------|
| `monitorAlarmTitle`     | 96             | Bold      | Stichwort im Alarmzustand                  |
| `monitorDisplay`        | 64             | SemiBold  | Uhrzeit, Einsatzadresse                    |
| `monitorHeadline`       | 40             | SemiBold  | Einsatz-/Abschnittstitel, Fahrzeugkennung  |
| `monitorBody`           | 28             | Regular   | Meldebild, Besatzungsliste, Tagesablauf    |
| `monitorLabel`          | 22             | Medium    | Badges, Zeitstempel, Fußzeilen             |

Minimalgröße unter 22 px ist auf dem Monitor nicht zulässig (auch nicht für Fußnoten/Quellenangaben — diese
gehören ins Impressum der Admin-Web, nicht auf den Monitor).

## 4. Abstände, Radien, Elevation, Breakpoints

### 4.1 Abstandsraster (4/8-pt)

Token-Skala (identisch zu `BftagSpacing` in Abschnitt 10, eine Namensgebung für Dokument und Code):
`xs=4 sm=8 md=12 lg=16 xl=24 xxl=32 xxxl=48 huge=64` (px bzw. dp). Standardabstand zwischen Karten/Sektionen:
`xl`; innerer Karten-Padding: `lg`–`xl`; Formularfeld-Abstand: `lg`. Monitor verdoppelt effektiv (nutzt
`xxl`/`xxxl`/`huge` als Basis statt `xs`–`lg`).

### 4.2 Radien

| Token        | px  | Verwendung                              |
|--------------|-----|-------------------------------------------|
| `radiusSmall`  | 8   | Chips, Badges, kleine Buttons            |
| `radiusMedium` | 12  | Buttons, Textfelder, Listenzeilen        |
| `radiusLarge`  | 16  | Karten, Dialoge                           |
| `radiusFull`   | 999 | FMS-Statuspille, Avatar                   |

### 4.3 Elevation/Flächen

Statt Schatten (schlecht auf dunklem Monitor-Grund) primär **Flächentrennung über Farbe**: `surface` →
`surfaceVariant` → `surfaceContainer`, zusätzlich `outline` 1 px bei Bedarf. Dialoge/Popups erhalten einen
dezenten Schatten nur im hellen Web-Theme (`elevation: 3`, Material-3-Standardkurve); im Dunkel-/Monitor-Theme
keine Schatten, nur Flächenkontrast + 1 px `outline`.

### 4.4 Breakpoints

- Admin-Web: Desktop-first, Referenzbreite 1440 px, Mindestbreite 1280 px (volle Seitenleiste). Zwischen
  1024–1279 px: Seitenleiste kollabiert auf Icons (Tablet-Modus, siehe `docs/design/screens/web-navigation.md`).
  Unter 1024 px nicht Ziel dieses Projekts (kein Phone-Layout für Admin-Web).
- Monitor: fix 1920×1080, kein responsives Verhalten nötig.
- App: 360–430 px Breite, Referenzgrößen 360×640 (klein, Android-Minimum) und 390×844 (iPhone-Referenz).

## 5. Komponenten (mit Zuständen)

Alle Komponenten werden über `ThemeData`-Component-Themes (`FilledButtonThemeData`, `InputDecorationTheme`, …)
abgebildet, keine Custom-Paint-Widgets nötig.

### 5.1 Buttons

- **Primär** (`FilledButton`): `primary`-Fläche, `onPrimary`-Text, `radiusMedium`. Hover (Web): 8% Weiß/Schwarz-
  Overlay. Focus: 2 px `primary`-Ring außerhalb, 2 px Abstand. Pressed: 12% Overlay. Disabled: 38% Opazität,
  kein Hover/Focus. Loading: Text durch `CircularProgressIndicator` (16 px, `onPrimary`) ersetzt, Button bleibt
  in Originalgröße, nicht klickbar.
- **Sekundär** (`OutlinedButton`): `outline`-Rahmen 1 px, `onSurface`-Text. Hover: `surfaceVariant`-Füllung.
- **Alarm** (`FilledButton` mit `alarm`-Fläche/`onAlarm`-Text, eigenes `BftagAlarmColors`-Styling statt
  `ColorScheme`): für Aktionen, die einen Alarm auslösen oder verschärfen — „Alarmieren“, „Nachalarmieren“ —
  sowie für destruktive Aktionen mit Bestätigungsdialog (z. B. Einsatz löschen, Person entfernen). Rot markiert
  hier bewusst „diese Handlung löst etwas Alarm-Artiges aus/ist nicht rückgängig zu machen“, nicht nur
  „destruktiv“ — deshalb ein gemeinsamer Stil für beide Fälle (Grundprinzip 1: Rot = Alarm). Wo ein
  Bestätigungsschritt heute existiert, bleibt er erhalten (z. B. „Wirklich nachalarmieren?“-Dialog); wo „Alarmieren“
  bisher ohne Bestätigung ausgelöst wird, bleibt das Verhalten unverändert — nur die Farbe ändert sich (siehe
  `web-einsaetze.md` für das Detail-Konzept dieser Karte).
- Mindestgröße überall ≥ 48×48 dp (Touch), auf Web ≥ 36 px Höhe mit 48 dp Touch-Fläche inkl. Innenabstand.

### 5.2 Textfelder (`TextFormField`/`InputDecorationTheme`)

Default: `outline`-Rahmen 1 px, `radiusMedium`, Label außerhalb (floating). Focus: 2 px `primary`-Rahmen. Error:
1 px `warning`-Rahmen + Fehlertext in `warning` unter dem Feld + Icon (niemals `alarm`-Rot — ein Formularfehler
ist kein Alarm, siehe Grundprinzip 1 und Abschnitt 2.1). Disabled: `surfaceVariant`-Füllung, Text
`onSurfaceVariant` bei 60 %.

### 5.3 Tabellen/Listen

Zeilenhöhe ≥ 48 dp. Kopfzeile `surfaceVariant`, `titleMedium`. Zeilen abwechselnd `surface`/`surfaceVariant`
(sehr dezent, 4–6 % Unterschied) oder nur `outline`-Trenner (1 px) — Entscheidung pro Screen, Standard: nur
Trenner, kein Zebra (ruhiger). Hover-Zeile (Web): `surfaceVariant`. Selektierte Zeile: `primaryContainer`.
Leerzustand: zentriertes Icon (48 px, `onSurfaceVariant`) + Kurztext + ggf. Primäraktion.

### 5.4 Karten

`surfaceVariant`-Fläche, `radiusLarge`, Innenabstand `space24`, im hellen Theme `elevation 1`, im
Dunkel-/Monitor-Theme kein Schatten (nur Fläche). Titel `titleLarge`, Meta-Infos `bodyMedium`/`onSurfaceVariant`.

### 5.5 Status-Chip / FMS-Badge

Pille (`radiusFull`), Mindesthöhe 24 dp (Web/App) bzw. 56 px (Monitor), Fläche = FMS-Token, Text/Icon-Farbe
nach Tabelle 2.4, immer mit Status-Nummer + Kurzlabel, nie nur Farbfläche (Farbenblindheit). Fahrzeugname davor
in `onSurface`. Auf dunklem Grund (Monitor, App-Dark) erhält jede Pille zusätzlich einen 1 px Rahmen in
`onSurface` bei 24 % Deckkraft (s. Begründung Abschnitt 2.4) — auf hellem Grund (Admin-Web) kein Rahmen.

### 5.6 Dialoge

`surfaceContainer`-Fläche, `radiusLarge`, Titel `titleLarge`, Aktionen rechtsbündig (Web)/volle Breite
gestapelt (App, ≥ 48 dp je Button). Destruktive Bestätigung: Titel + Beschreibungstext schwarz/neutral (NICHT
rot — nur der bestätigende Button ist `alarm`-farben), damit Rot ausschließlich die auslösende Handlung markiert.

### 5.7 Snackbar/Banner (Durchsage)

Durchsagen sind **ausdrücklich kein Alarm** (siehe `CONTEXT.md`) — eigene, ruhige Darstellung: `primaryContainer`-
Fläche (nicht `alarm`, nicht neutral-grau, damit sie aus dem Alltagsgrau heraussticht aber klar von Alarmrot
getrennt bleibt), Icon „Megafon“, max. 3 Zeilen Text mit „mehr“-Erweiterung, Schließen-Icon, Auto-Dismiss nach
8 s (Web-Snackbar) / bleibt bis gelesen (App-Banner, Pull-to-dismiss). Monitor: eigene Bannerzeile unten, siehe
`docs/design/screens/monitor-standby.md`.

### 5.8 Seitenleiste (Admin-Web)

`surfaceVariant`-Fläche, feste Breite 240 px (voll) / 72 px (kollabiert), aktiver Eintrag `primaryContainer`-
Fläche + `primary`-Text + linker 3 px `primary`-Indikator, Fokusring sichtbar bei Tab-Navigation. Details:
`docs/design/screens/web-navigation.md`.

### 5.9 NavigationBar (App)

Material-3-`NavigationBar`, `surfaceVariant`-Fläche, aktives Icon/Label `primary`, inaktiv `onSurfaceVariant`,
Touch-Ziel 56 dp Höhe, Badge-Punkt (`alarm`) für ungelesene Durchsagen/aktive Alarme auf dem jeweiligen Tab.

### 5.10 Leer-/Fehler-/Ladezustand (geteiltes Muster, alle Oberflächen)

- **Laden:** `CircularProgressIndicator` (`primary`), zentriert, bei Listen: Skeleton-Zeilen (`surfaceVariant`-
  Balken, dezent pulsierend) statt Spinner, wenn Layout bereits bekannt ist.
- **Leer:** Icon 48 px + `titleMedium`-Text + `bodyMedium`-Erklärung + optionale Primäraktion.
- **Fehler:** Icon „warning“ in `warning`-Farbe (nicht `alarm` — ein Lade-/Serverfehler ist kein Alarm, siehe
  Grundprinzip 1 und Abschnitt 2.1), Kurztext + „Erneut versuchen“-Button.
- **Offline/Reconnecting:** schmales Banner oben (Web/Monitor) bzw. unter der AppBar (App), `surfaceVariant`-
  Fläche, Icon „cloud_off“, Text „Verbindung verloren — verbinde erneut …“, kein Rot (ist kein Alarm).

### 5.11 Alarm-Fläche

Vollflächig `alarm`/`onAlarm` (App-Alarmscreen, Monitor-Alarmzustand). Erstalarm vs. Nachalarmierung weiterer
Fahrzeuge wird NICHT über unterschiedliche Rottöne unterschieden (Verwechslungsgefahr), sondern über Label
„ERSTALARM“/„NACHALARMIERT“ + Icon. Details je Oberfläche in `docs/design/screens/{monitor,app}-alarm.md`.

## 6. Icons

Material Symbols (Outlined, 24 dp Grundraster, auf dem Monitor 40–56 dp). Keine Mischung mit anderen Icon-Sets.
Icon-Buttons erhalten immer `Semantics`/`tooltip` mit dem deutschen Aktionsnamen (z. B. „Durchsage senden“, nicht
„Icon Button“). Statusicons (FMS, Durchsage, Offline) sind fest zugeordnet und werden nicht pro Screen neu
gewählt — Liste folgt in den Screen-Konzepten, Grundsatz hier verbindlich.

## 7. Bewegung

- Standarddauer: 150 ms (Hover/Fokus), 200 ms (Ein-/Ausblenden von Karten/Dialogen), 300 ms (Seitenwechsel/
  Sidebar-Kollaps). Kurve: `Curves.easeOutCubic` (rein), `Curves.easeInOutCubic` (hin und zurück).
- Alarm-Eintritt (Monitor/App): kein Blinken des gesamten Screens (Epilepsie-Risiko, Lesbarkeit) — stattdessen
  einmaliger Fade-in der Fläche (250 ms) + pulsierendes Icon/Badge (nicht der Volltext), Frequenz ≤ 1 Hz.
- `MediaQuery.disableAnimations`/Reduced-Motion: alle Übergänge auf 0 ms, kein Puls (statisches Badge statt
  Animation), Fokus bleibt aber weiterhin sofort sichtbar.

## 8. Barrierefreiheit

- Kontrast: WCAG AA minimal überall, Monitor AAA angestrebt (siehe Tabelle 2.3; eine bekannte Abweichung bei
  `onAlarm`/`alarm` auf Monitor ist dokumentiert und bewusst, kompensiert durch Größe/Gewicht).
- Touch-Ziele ≥ 48×48 dp überall (App und Web-Icon-Buttons).
- Web: sichtbarer Fokusring (2 px `primary`, 2 px Außenabstand) auf jedem interaktiven Element, keine
  `outline: none` ohne Ersatz.
- Alle Icon-Buttons erhalten `Semantics(label: ...)`/`tooltip`; bestehende Labels aus dem Code bleiben erhalten
  (siehe Screen-Konzepte, Abschnitt „Zu erhaltende Keys + Semantics“).
- Farbe ist nie der einzige Träger einer Information (FMS-Badges, Fehler-/Erfolgszustände immer zusätzlich mit
  Text/Icon).

## 9. App-Icon und Favicon

Ein Bildzeichen für App-Icon und Favicon: ein schlichtes Schild-/Hausformular mit einem stilisierten „F“ (für
BF-Tag) in der Mitte, einfarbig auf `primary`-Grund — bewusst **nicht** in Alarmrot, damit das Icon nicht wie ein
Warnsymbol wirkt (es ist die App, kein Alarmzustand). Erkennbar bei 16 px durch wenige, dicke Formen (keine
dünnen Linien, kein Text außer dem reduzierten „F“).

Dateien:

- `docs/design/icon/app-icon.svg` — Vollfarbversion (`primary` #0B5E6B Hintergrund, `onPrimary` Weiß Symbol),
  1024×1024 Viewbox, abgerundetes Quadrat (iOS/Android adaptive-icon-tauglich: Motiv in sicherer 66%-Mittelzone).
- `docs/design/icon/favicon.svg` — identisches Motiv ohne Hintergrund-Rundung (volles Quadrat, da Browser selbst
  runden), für `<link rel="icon">`.
- `docs/design/icon/app-icon-mono.svg` — einfarbige Variante (nur Pfad, transparenter Hintergrund) für
  Monochrome-Launcher-Icons (Android 13+) und Favicon-Dark-Mode.
- PNG-Vorschauen: `app-icon-16.png`, `app-icon-32.png`, `app-icon-192.png`, `app-icon-512.png`, `app-icon-1024.png`
  (aus dem SVG gerendert, siehe unten).

## 10. Abbildung auf Flutter

Ein gemeinsames Theme-Modul in `packages/core/lib/src/theme.dart` (ersetzt den aktuellen 9-Zeiler und das
separate `ThemeData` in `apps/mobile/lib/main.dart`, das in ux-03 entfällt).

```dart
// packages/core/lib/src/theme.dart — Signaturskizze, Umsetzung in ux-03

enum BftagThemeMode { light, dark, monitor }

ThemeData bftagTheme(BftagThemeMode mode) { ... }

ThemeData bftagLightTheme();   // Admin-Web, App hell
ThemeData bftagDarkTheme();    // App dunkel
ThemeData bftagMonitorTheme(); // Monitor: dunkel + Monitor-Typskala

@immutable
class BftagStatusColors extends ThemeExtension<BftagStatusColors> {
  const BftagStatusColors({
    required this.fms1, required this.fms2, required this.fms3, required this.fms4,
    required this.fms5, required this.fms6, required this.fms7, required this.fms8,
    required this.onFms1, /* … onFmsN je Fläche … */
  });
  final Color fms1, fms2, fms3, fms4, fms5, fms6, fms7, fms8;
  final Color onFms1, onFms2, onFms3, onFms4, onFms5, onFms6, onFms7, onFms8;

  Color colorFor(FmsStatus status) { ... }   // switch über FmsStatus → fmsN
  Color onColorFor(FmsStatus status) { ... }

  @override
  BftagStatusColors copyWith({ ... });
  @override
  BftagStatusColors lerp(ThemeExtension<BftagStatusColors>? other, double t);
}

@immutable
class BftagAlarmColors extends ThemeExtension<BftagAlarmColors> {
  const BftagAlarmColors({required this.alarm, required this.onAlarm, required this.alarmContainer});
  final Color alarm, onAlarm, alarmContainer;
  @override
  BftagAlarmColors copyWith({ ... });
  @override
  BftagAlarmColors lerp(ThemeExtension<BftagAlarmColors>? other, double t);
}

@immutable
class BftagSpacing extends ThemeExtension<BftagSpacing> {
  const BftagSpacing({
    this.xs = 4, this.sm = 8, this.md = 12, this.lg = 16, this.xl = 24, this.xxl = 32, this.xxxl = 48,
    this.huge = 64,
  });
  final double xs, sm, md, lg, xl, xxl, xxxl, huge;
  @override
  BftagSpacing copyWith({ ... });
  @override
  BftagSpacing lerp(ThemeExtension<BftagSpacing>? other, double t);
}

@immutable
class BftagRadii extends ThemeExtension<BftagRadii> {
  const BftagRadii({this.small = 8, this.medium = 12, this.large = 16, this.full = 999});
  final double small, medium, large, full;
  @override
  BftagRadii copyWith({ ... });
  @override
  BftagRadii lerp(ThemeExtension<BftagRadii>? other, double t);
}

// Monitor-Typskala als eigene Extension, da sie keine ColorScheme-Rolle hat:
@immutable
class BftagMonitorTextStyles extends ThemeExtension<BftagMonitorTextStyles> {
  const BftagMonitorTextStyles({
    required this.alarmTitle, required this.display, required this.headline,
    required this.body, required this.label,
  });
  final TextStyle alarmTitle, display, headline, body, label;
  @override
  BftagMonitorTextStyles copyWith({ ... });
  @override
  BftagMonitorTextStyles lerp(ThemeExtension<BftagMonitorTextStyles>? other, double t);
}
```

Zugriff überall per `Theme.of(context).extension<BftagStatusColors>()!` usw. `ColorScheme` deckt Primär-/Oberflächen-
rollen ab (`ColorScheme.fromSeed` entfällt zugunsten expliziter `ColorScheme(...)`-Konstruktion aus Tabelle 2.1,
damit die Hex-Werte exakt den hier dokumentierten entsprechen statt algorithmisch abgeleitet zu werden).
`ColorScheme.error`/`onError`/`errorContainer` werden auf die `warning`-Tokens aus Tabelle 2.1 gemappt (Formular-/
Validierungsfehler) — `alarm`/`onAlarm`/`alarmContainer` existieren ausschließlich in `BftagAlarmColors` und
werden von keinem Standard-Widget automatisch verwendet, damit ein versehentliches `ColorScheme.error`-Rot für
Alarm ausgeschlossen ist (Grundprinzip 1).
`fontFamily: 'Inter'` global über `ThemeData.textTheme`/`fontFamily`, `TextTheme` aus Tabelle 3.1 (Monitor:
zusätzlich `BftagMonitorTextStyles`, NICHT über `TextTheme`, da Monitor keine eigene `MaterialApp`-Instanz mit
anderer `TextTheme`-Semantik braucht, sondern dieselbe App in einem dritten Modus).

`apps/mobile/lib/main.dart` ruft künftig `theme: bftagLightTheme(), darkTheme: bftagDarkTheme(), themeMode:
ThemeMode.system` statt des eigenen `ThemeData(colorSchemeSeed: Colors.red, ...)`.

Kein Custom-Render-Code nötig: Fonts über `pubspec.yaml`-`fonts:`-Block, Farben/Radien/Spacing über
`ColorScheme` + `ThemeExtension`, Komponenten über Standard-`*ThemeData`-Klassen (`FilledButtonThemeData`,
`OutlinedButtonThemeData`, `InputDecorationTheme`, `CardThemeData`, `NavigationBarThemeData`, `DialogThemeData`,
`SnackBarThemeData`).

## 11. Mockups

Schlüssel-Screens als statisches HTML/CSS (lokale Schriftdateien, keine CDN) unter `docs/design/mockups/`,
gerendert mit `/usr/bin/google-chrome --headless --screenshot=<name>.png --window-size=<W>,<H> file://<pfad>.html`:

- `lage.html`/`.png` — 1440×900, Admin-Web mit Seitenleiste.
- `monitor-standby.html`/`.png` — 1920×1080.
- `monitor-alarm.html`/`.png` — 1920×1080.
- `app-alarm-light.html`/`.png`, `app-alarm-dark.html`/`.png` — 390×844.
- `app-mein-fahrzeug.html`/`.png` — 390×844.

Diese Mockups sind Referenz für die Screen-Konzepte (ux-02b–e), die sie vertiefen/vervollständigen dürfen, aber
nicht in den Grundtokens widersprechen sollen.
