# ux-08 Tester-Verifikation — App Rahmen (Navigationsleiste, Onboarding, Kopplung, Mein Fahrzeug, Einstellungen)

Branch verifiziert: lokaler `main` nach Merge von t_8b88d76e (ux-08a Nav-Leiste/Mein Fahrzeug/FMS-Panel),
t_6a621223 (ux-08b Onboarding), t_93b8d122 (ux-08c Kopplung/Einstellungen). HEAD zum Zeitpunkt der
Verifikation: `2e370d0`. Tester-Worktree basiert direkt auf diesem `main` (keine eigenen Commits nötig
außer Screenshots/diesem Dokument).

## 1. AC-Abdeckung je Konzept

### app-navigation.md §6 (AC1–7)
Alle 7 ACs durch `main_nav_bar_test.dart`/`navigation_test.dart` belegt: 4 Tabs in korrekter
Reihenfolge mit den festgelegten Icons/Labels (AC1), aktiver Tab `primary`+gefülltes Icon (AC2),
Touch-Fläche ≥48×48dp (AC3, zusätzlich per `androidTapTargetGuideline` geprüft in den Screen-Tests),
Leiste fehlt auf `/onboarding`,`/pair`,`/einsaetze/:id`,`/alarm/:alarmId`,`/settings` (AC4, grep über
`bottomNavigationBar: const MainNavBar` bestätigt nur 4 Vorkommen in `my_vehicle_screen.dart`,
`incidents_screen.dart`, `program_screen.dart`, `announcements_screen.dart`), Tap-Navigation/kein
Rebuild-Loop auf aktivem Tab (AC5), Kontrast hell/dunkel (AC6, visuell in den Nachher-Screenshots
bestätigt, kein separates Kontrast-Script für die App im Repo), kein Badge gerendert (AC7, Kommentar
`// always shown, no badge (ADR 0027 ...)` + grep nach `badge`/`Badge` in `main_nav_bar.dart` leer).

### app-mein-fahrzeug.md §6 (AC1–9)
Alle 9 ACs durch `my_vehicle_screen_test.dart` belegt (Touch-Fläche ≥48dp, 16px-Spacing, aktive
Kachel farbig/inaktive `surfaceContainer`, 6 vs. 8 Kacheln nach Fahrzeugtyp, Pending-Spinner nur auf
betroffener Kachel, Fehler-SnackBar mit `describeSetStatusError`-Text, 360×640 ohne Scrollen für 6
Kacheln, kein Offline-Banner, WCAG-Kontrast). AC7 (360×640, 6 Kacheln ohne Scrollen) zusätzlich visuell
bestätigt in `mein-fahrzeug-360x640.png`/`mein-fahrzeug-dark-360x640.png`: alle 6 Kacheln + Kopfbereich +
Navigationsleiste sichtbar, kein Clipping.

### app-onboarding.md §6 (AC1–9)
Alle 9 ACs durch `onboarding_test.dart` belegt: korrekte Schrittzahl je Plattform (AC1), Spinner statt
Fortschrittsbalken solange `_loaded==false` (AC2), Status-Chip `warningContainer`/`warning` vs.
`primaryContainer`/`primary`, nie `alarm`-Rot (AC3), "Einstellungen öffnen" erst nach erstem
"Erlauben"-Versuch (AC4), Hersteller-Hinweis nur im Akku-Schritt/Android (AC5), Testalarm-Buttons
disabled während `_busy` (AC6), Sperrbildschirm-Hinweis nur nach verzögertem Testalarm (AC7), "Fertig"
markiert `onboardingCompletedProvider` und verlässt den Screen (AC8). AC9 (WCAG-Kontrast Status-Chip +
Hersteller-Hinweis, hell/dunkel) ist die einzige rein visuelle AC — zusätzlich zum bestehenden
Kontrast-Test (`meetsGuideline`/`androidTapTargetGuideline` bei 390×844/360×640 hell+dunkel, von der
Coder-Karte ergänzt nach Reviewer-Feedback Runde 1) visuell bestätigt in
`onboarding-390x844.png`/`onboarding-dark-390x844.png`/`onboarding-360x640.png`/`onboarding-dark-360x640.png`.

### app-kopplung.md §6 (AC1–7)
Alle 7 ACs durch `pairing_and_settings_test.dart` belegt: Kamera + manuelle Eingabe gleichzeitig
bedienbar (AC1, `AspectRatio`-Kamerafläche über `LayoutBuilder` statt fixer `SizedBox`), Scan löst
denselben `_pair()`-Aufruf wie manuelle Eingabe (AC2), Submit-Button disabled + Spinner während
`_isSubmitting` (AC3), `pair-error` nur sichtbar wenn Text vorhanden und Farbe `warning` nie `alarm`
(AC4), SnackBar "Dieses Gerät wurde abgemeldet." genau einmal bei `revoked:true` (AC5). AC6 (360×640,
Kamerafläche kleiner, Eingabe+Button ohne Scrollen) visuell bestätigt in `kopplung-360x640.png`/
`kopplung-dark-360x640.png`: Kamera-Platzhalter, Trenner "oder Code eingeben", Eingabefeld und
"Koppeln"-Button alle ohne Scrollen sichtbar. AC7 (Kontrast Fehlerzeile/Eingabefeld-Label hell/dunkel)
visuell bestätigt in allen vier Kopplung-Screenshots (lesbarer Text auf hell/dunkel).

### app-einstellungen.md §6 (AC1–6)
Alle 6 ACs durch `pairing_and_settings_test.dart` belegt: "Gerät abmelden" nutzt `alarm`-FilledButton-
Stil nicht `primary` (AC1), Dialog zeigt Titel/Text neutral, nur "Abmelden" alarmfarben (AC2),
"Einrichtung erneut öffnen" nutzt `OutlinedButton` (AC3), Testalarm-Buttons `primary` (AC4),
"Abbrechen" schließt ohne `logout()`-Aufruf (AC5, Test prüft `logoutCalls==0`). AC6 (Kontrast aller
Button-Beschriftungen hell/dunkel) visuell bestätigt in `einstellungen-390x844.png`/
`einstellungen-dark-390x844.png`/`einstellungen-360x640.png`/`einstellungen-dark-360x640.png`: klare
Hierarchie Outlined (sekundär) → Primary (Testalarm) → Alarm-Rot (Abmelden), guter Kontrast in beiden
Modi.

## 2. §7-Keys und Regression (§8)

Grep über `apps/mobile/lib` nach allen in §7 der fünf Konzepte geforderten Keys (`main-nav-bar`,
`nav-my-vehicle`, `nav-incidents`, `nav-announcements`, `nav-program`, `settings`, `vehicle-switcher`,
`fms-panel`, `onboarding-action-notifications-allow`, `onboarding-action-notifications-settings`,
`onboarding-action-dnd-settings`, `onboarding-battery-hint`, `onboarding-action-battery-request`,
`onboarding-mute-hint`, `onboarding-next`, `onboarding-finish`, `test-alarm-now`, `test-alarm-delayed`,
`test-alarm-lock-hint`, `test-alarm-result`, `pair-code`, `pair-submit`, `pair-error`, `logout-cancel`,
`logout-confirm`, `reopen-onboarding`, `logout-button`): alle vorhanden, in den erwarteten Dateien
(`main_nav_bar.dart`, `fms_panel.dart`, `onboarding/*.dart`, `my_vehicle_screen.dart`,
`settings_screen.dart`, `pairing_screen.dart`).

`git diff 9e18c7e..HEAD -- apps/mobile/test`: 4 geänderte Dateien (`main_nav_bar_test.dart`,
`my_vehicle_screen_test.dart`, `onboarding_test.dart`, `pairing_and_settings_test.dart`), 1122
Insertions / 57 Deletions, **0** entfernte `testWidgets(`-Deklarationen. Zeilenlöschungen sind
ausschließlich (a) Reindent/Refactor bestehender Testkörper ohne Assertion-Verlust (z. B.
`main_nav_bar_test.dart`: ungenutzter Default-Parameter aus Helper entfernt) oder (b) Anpassungen von
Text-Assertions an laut Konzept geänderten Text (`my_vehicle_screen_test.dart`:
`'Deine Funktion: GF'` → `'Funktion: GF · Status: 2 – Einsatzbereit auf Wache'`, entspricht
app-mein-fahrzeug.md §3 neuer Kopfbereich-Hierarchie). Keine Abschwächung von Verhaltens-Assertions.

`docs/testing/regression-inventory.md` Zeilen für Onboarding (237–238), Kopplung (239–240), Mein
Fahrzeug (241–242), Einstellungen (252), Navigationsleiste (253): alle weiterhin `ok`, keine Zeile auf
`Lücke` zurückgefallen.

## 3. Harte Farben / Badge-Check

```
grep -nE "Color\(0x|Colors\." apps/mobile/lib/widgets/main_nav_bar.dart apps/mobile/lib/widgets/fms_panel.dart \
  apps/mobile/lib/screens/my_vehicle_screen.dart apps/mobile/lib/screens/pairing_screen.dart \
  apps/mobile/lib/screens/settings_screen.dart apps/mobile/lib/onboarding/*.dart
```
Zwei Treffer, beide kein harter Farbwert: `fms_panel.dart:53`/`:56` rufen
`statusColors.colorFor(status)`/`statusColors.onColorFor(status)` auf — Methodenaufrufe auf das
Theme-Extension-Objekt `BftagFmsStatusColors`, keine `Colors.*`/`Color(0x...)`-Literale. Keine
weiteren Treffer, insbesondere kein `Colors.red`/`Colors.amber` mehr in `my_vehicle_screen.dart`.

`grep -n "badge\|Badge" apps/mobile/lib/widgets/main_nav_bar.dart`: ein Kommentar
("always shown, no badge (ADR 0027 ...)"), kein Badge-Widget im Code — entspricht AC7/ADR 0027.

## 4. Testläufe (alle grün)

- Backend: `just test` → 336/336 (32 Testdateien)
- `just analyze` (`dart analyze packages/api_client && flutter analyze apps/web apps/mobile
  packages/core`) → clean, keine Issues
- `flutter test` apps/mobile → 124/124
- `just e2e` → UI-Lauf 1: 47/47 + 1 Flake (`page /admin renders` — Admin-Web-Screen, außerhalb des
  ux-08-Scopes, zeigte kurzzeitig `/admin/login` statt `/admin`); UI-Lauf 2 (Wiederholung): **48/48**,
  keine uncaught JS exceptions. Der Flake betrifft eine Web-Admin-Seite, nicht App-Rahmen, und trat auf
  einer Session-Timing-Flanke auf, nicht reproduzierbar — kein Bug-Ticket für ux-08 nötig (liegt
  außerhalb des Scopes dieser Karte).
- `just screenshots after` → SCREENSHOTS RESULT 44/44 (Web/Monitor) + `flutter test screenshot_test`
  App-Teil ohne Fehler.

## 5. Screenshot-Diff-Disziplin

`just screenshots after` regeneriert auch Web-/Monitor-PNGs außerhalb des ux-08-Scopes. Per
`cmp` gegen den vorherigen Commit-Stand geprüft: 5 Monitor-PNGs und 3 Web-PNGs
(`bf-tage`, `durchsagen`, `tagesablauf`) unterschieden sich pixel-weise (nicht-deterministisches
Rendering, z. B. Uhrzeiten/IDs) — diese wurden laut Vorgabe ("andere Bereiche: revert, außer
unverändert-Diff") mit `git checkout --` zurückgesetzt. Ebenso wurden 10 neu erzeugte Dark-Mode-PNGs
außerhalb des App-Rahmen-Scopes (`alarm-screen-dark-*`, `durchsagen-dark-*`, `einsaetze-dark-*`,
`einsatzdetail-dark-*`, `tagesablauf-dark-*` — Artefakte eines App-weiten Dark-Mode-Screenshot-Laufs,
nicht Teil dieser Karte) gelöscht/nicht committet. Committet sind ausschließlich die 16 App-Rahmen-PNGs
unter `docs/design/screenshots/after/app/{mein-fahrzeug,onboarding,kopplung,einstellungen}*.png`
(8 geänderte Light-Varianten + 8 neue Dark-Varianten, je 390×844 und 360×640).

## 6. Visuelle Prüfung der App-Rahmen-Nachher-Screenshots

| Screenshot | Ergebnis |
|---|---|
| `mein-fahrzeug-390x844.png` / `-dark` | Kopfbereich mit Fahrzeug/Funktion/Status-Hierarchie, Zahnrad-Icon in AppBar (vom Flutter-Debug-Banner teils überlagert — Debug-Artefakt, siehe unten, bereits im Vorher-Screenshot vorhanden), 2×3-FMS-Grid mit gelb hervorgehobener aktiver Kachel (Status 3), 16px-Abstand, Navigationsleiste mit 4 Tabs unten, kein Clipping |
| `mein-fahrzeug-360x640.png` / `-dark` | Alle 6 FMS-Kacheln + Kopfbereich ohne Scrollen sichtbar, Navigationsleiste fix unten sichtbar — entspricht AC7/Konzept-Rechnung (≈574px von 640px) |
| `onboarding-390x844.png` / `-360x640` / `-dark`-Varianten | Fortschrittsbalken "Schritt 1 von 5", Titel, Status-Chip, Beschreibung, "Weiter"-Button unten rechts — kein abgeschnittener Text, guter Kontrast in beiden Modi |
| `kopplung-390x844.png` / `-360x640` / `-dark`-Varianten | Kamera-Platzhalter (radiusLarge), Trenner "oder Code eingeben", Eingabefeld, "Koppeln"-Button — auf 360×640 alle Elemente ohne Scrollen sichtbar |
| `einstellungen-390x844.png` / `-360x640` / `-dark`-Varianten | Klare Button-Hierarchie: Outlined ("Einrichtung erneut öffnen") → Primary (Testalarm-Buttons) → Alarm-Rot ("Gerät abmelden"), guter Kontrast hell/dunkel, kein Clipping |

**Beobachtung Debug-Ribbon (kein neuer Bug):** Der rote "DEBUG"-Eckbanner oben rechts in allen
`mein-fahrzeug-*`-Screenshots ist Flutters Standard-Debug-Banner (Widget-Test läuft im Debug-Modus),
überlagert dort teilweise das Zahnrad-Icon. Vergleich mit
`docs/design/screenshots/before/app/mein-fahrzeug-390x844.png` zeigt denselben Banner bereits vor dem
ux-08-Rework — bestehendes Testumgebungsverhalten, keine Regression. Der Key `settings` existiert laut
§2 (Keys-Grep) unverändert im Code und ist über `main_nav_bar_test.dart`/`my_vehicle_screen_test.dart`
abgedeckt. Kein Bug-Ticket erstellt.

## Ergebnis

Keine neuen Bugs. Alle 38 testbaren ACs der fünf Konzepte (AC1–7 Navigation, AC1–9 Mein Fahrzeug,
AC1–9 Onboarding, AC1–7 Kopplung, AC1–6 Einstellungen) durch benannte Widget-Tests oder (bei rein
visuellen ACs) durch die Nachher-Screenshots belegt. Keine Tests gelöscht/abgeschwächt, alle
"Zu erhaltenden Keys" vorhanden, keine harten Farben, kein Nav-Bar-Badge, regression-inventory.md
unverändert grün. Alle Suiten grün (Backend 336/336, `flutter analyze`/`dart analyze` clean,
`flutter test` apps/mobile 124/124, `just e2e` 48/48 nach einem einmaligen, scope-fremden Flake,
`just screenshots after` 44/44 + App-Teil fehlerfrei).
