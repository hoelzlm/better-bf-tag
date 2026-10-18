# ux-09 Tester-Verifikation — App Einsatz und Info (Einsätze, Einsatzdetail, Alarm, Tagesablauf, Durchsagen)

Branch verifiziert: lokaler `main` nach Merge von t_d591e15b (ux-09 A, Einsätze+Einsatzdetail),
t_381faf78 (ux-09 B, Alarm), t_af87cb1f (ux-09 C, Tagesablauf+Durchsagen) — alle drei waren beim Start
dieser Karte bereits mit `--no-ff` in `main` gemerged (verifiziert per `git log`: `d23963b` Merge ux-09 C,
`8135f14` Merge ux-09 B, `26cd99c` Merge ux-09 A). Tester-Worktree basiert direkt auf diesem `main`, keine
eigenen Nacharbeiten nötig außer Screenshots/diesem Dokument.

## 1. AC-Abdeckung je Konzept

### app-einsaetze.md §6 (AC1–7)
Alle 7 ACs durch `incidents_screen_test.dart` belegt: `running`-Chip `primaryContainer`/`primary` nie
`alarm`/`Colors.red` (AC1), `closed`-Chip `surfaceVariant`/`onSurfaceVariant` (AC2), Zeilenhöhe ≥48dp +
`outline`-Trenner (AC3), Fehlerzustand mit Pull-to-Refresh-Hinweistext (AC4), Leer-/Fehlerzustand bleiben
innerhalb eines `RefreshIndicator`-fähigen Containers (AC5), Tap navigiert zu `/einsaetze/<id>` (AC6). AC7
(Kontrast Chip-Text hell/dunkel) zusätzlich visuell bestätigt — Fehlerzustand-Screenshot zeigt lesbaren
Text+Icon auf neutraler Fläche in beiden Modi (die Chip-Kontraste selbst sind über
`meetsGuideline(textContrastGuideline)` in `incidents_screen_test.dart` geprüft, nicht nur visuell).

### app-einsatzdetail.md §6 (AC1–7)
Alle 7 ACs durch `incidents_screen_test.dart` (5 `IncidentDetailScreen`-Kombinationen) belegt:
Drehbuch-Card nur bei `incident.script != null` (AC1), Karten-Card nur bei `incident.location != null`
(AC2), Drehbuch-Card nutzt `primaryContainer`/`primary`, nicht `Colors.amber` (AC3), alle vier
Kombinationen rendern ohne Layout-Fehler (AC4), „Lagebeschreibung" nur bei nicht-leerem `report` (AC5),
fehlgeschlagene Navigation zeigt unveränderten SnackBar-Text (AC6). AC7 (Kontrast Drehbuch-Card hell/dunkel)
durch `meetsGuideline(textContrastGuideline)`-Tests (light+dark, mit Drehbuch+Karte) in
`incidents_screen_test.dart` belegt.

### app-alarm.md §6 (AC1–9)
Alle 9 ACs durch `alarm_screen_test.dart` belegt: Hintergrund exakt `alarm`-Token, nicht
`Colors.red.shade800` (AC1), Sequenz-Label zeigt exakten `alarmSequenceLabel(...)`-Text + eigenes Icon je
Zustand, nie unterschiedliche Flächenfarbe (AC2), Quittieren-Button bleibt fixer Footer bei jeder
Scrollposition (AC3), Button zeigt Spinner + ist während `_acknowledging` nicht antippbar (AC4), „Dein
Fahrzeug" direkt nach dem Stichwort vor Adresse/Lagebeschreibung (AC5), `PopScope(canPop: false)` bleibt
erhalten (AC6), Screen schließt automatisch wenn `myPendingAlarmProvider` den Alarm nicht mehr liefert
(AC7), Kontrast `onAlarm`-auf-`alarm` via `meetsGuideline(textContrastGuideline)` hell+dunkel (AC8), AC9
(„AC9: fades the screen in once within <= 250ms" + „AC9: no fade animation at all when
MediaQuery.disableAnimations is set") — Reduced-Motion-Fall belegt kein `AnimatedOpacity`-Widget wird
gebaut, kein Blinken.

### app-tagesablauf.md §6 (AC1–6)
Alle 6 ACs durch `program_screen_test.dart` belegt: aktuelle(r) Punkt(e) `primaryContainer`-Fläche +
„Jetzt"-Chip (AC1), vergangene 50% Opacity / zukünftige volle Deckkraft (AC2), Leerzustand mit Text + Icon
(AC3), Zeilenhöhe ≥48dp (AC4), automatische Neu-Hervorhebung alle 30s ohne Nutzerinteraktion (AC5). AC6
(Kontrast „Jetzt"-Chip hell/dunkel) durch `meetsGuideline(textContrastGuideline)` in
`program_screen_test.dart` belegt.

### app-durchsagen.md §6 (AC1–6)
Alle 6 ACs durch `announcements_screen_test.dart` belegt: Durchsage-Card `primaryContainer` + „campaign"-
Icon, nie `alarm`/Grau (AC1), SnackBar nutzt dasselbe Icon/Farbschema wie die Listen-Card (AC2, geteilte
`announcement_visuals.dart`), Leerzustand mit Text + Icon (AC3), neu eintreffende Durchsage erscheint
automatisch oben (AC4), SnackBar-Aktion „Anzeigen" navigiert zu `/durchsagen` (AC5). AC6 (Kontrast Text-auf-
`primaryContainer` hell/dunkel) durch `meetsGuideline(textContrastGuideline)` in
`announcements_screen_test.dart` belegt.

## 2. §7-Keys und Regression (§8)

Grep über die fünf betroffenen `lib`-Dateien nach allen in §7 der Konzepte geforderten Keys: alle
vorhanden, unverändert benannt.

```
apps/mobile/lib/screens/incidents_screen.dart:83:   key: const Key('settings'),
apps/mobile/lib/screens/incidents_screen.dart:127:  key: const Key('incidents-list'),
apps/mobile/lib/screens/incidents_screen.dart:136:  key: Key('incident-${incident.id}'),
apps/mobile/lib/screens/incident_detail_screen.dart:129: key: const Key('script-section'),
apps/mobile/lib/map/incident_location_card.dart:48:      key: const Key('start-navigation'),
apps/mobile/lib/screens/alarm_screen.dart:266:     key: const Key('alarm-sequence-label'),
apps/mobile/lib/screens/alarm_screen.dart:340:     key: const Key('acknowledge-button'),
apps/mobile/lib/screens/program_screen.dart:69:    key: const Key('program-list'),
apps/mobile/lib/screens/program_screen.dart:110:   key: Key('program-current-${item.id}'),
apps/mobile/lib/screens/program_screen.dart:120:   key: Key('program-past-${item.id}'),
apps/mobile/lib/screens/program_screen.dart:126:   key: Key('program-item-${item.id}'),
apps/mobile/lib/screens/announcements_screen.dart:42:   key: const Key('announcements-list'),
apps/mobile/lib/screens/announcements_screen.dart:50:   key: Key('announcement-${announcement.id}'),
```

`git diff --stat 26cd99c~1..d23963b -- apps/mobile/test`: 5 geänderte/neue Dateien
(`incidents_screen_test.dart`, `alarm_screen_test.dart`, `program_screen_test.dart`,
`announcements_screen_test.dart`, `incident_location_card_test.dart`), 1499 Insertions / 21 Deletions.
`testWidgets(`-Zahl je Datei ausschließlich gestiegen (incidents_screen_test.dart 8→31,
alarm_screen_test.dart 10→18, program_screen_test.dart 5→16, announcements_screen_test.dart 2→13) — **0**
entfernte Tests, die 21 Zeilenlöschungen sind reines Reindent/Anpassung an laut Konzept geänderten Text
(z. B. neue Drehbuch-Card-Farbassertion statt `Colors.amber`). Keine Abschwächung von
Verhaltens-Assertions.

`docs/testing/regression-inventory.md` Zeilen für Einsätze (243–244), Einsatzdetail (245), Alarm-Screen
(246–247), Tagesablauf (248–249), Durchsagen (250–251): alle weiterhin `ok`, keine Zeile auf `Lücke`
zurückgefallen.

## 3. Harte Farben

```
grep -nE "Colors\.|Color\(0x" apps/mobile/lib/screens/{incidents,incident_detail,alarm,program,announcements}_screen.dart \
  apps/mobile/lib/map/incident_location_card.dart apps/mobile/lib/announcements/*.dart
```
Keine Treffer (Exit-Code 1 / leere Ausgabe) — alle fünf Screens + `incident_location_card.dart` +
`announcements/*.dart` nutzen ausschließlich Theme-Token.

## 4. Alarm: Erstalarm/Nachalarmierung, Motion

`alarm_screen_test.dart` deckt alle drei `alarmSequenceLabel`-Zustände (Erstalarm/`<n>.
Nachalarmierung`/Alarmierung) mit je eigenem Material-Icon
(`notifications_active_outlined`/`add_alert_outlined`/`notifications_outlined`) auf identischer
`alarm`-Flächenfarbe ab — Unterscheidung ausschließlich über Label + Icon, nie Rotton (bestätigt per
Reviewer-Handoff t_381faf78 und per Code-Lesen des `alarmSequenceCaps`-Blocks in `alarm_screen.dart`).
Kein Blinken: „AC9: fades the screen in once within <= 250ms" prüft einen einmaligen `AnimatedOpacity` ohne
laufende Animation danach (`tester.hasRunningAnimations == false`); „AC9: no fade animation at all when
MediaQuery.disableAnimations is set" prüft, dass bei `FakeAccessibilityFeatures(disableAnimations: true)`
gar kein `AnimatedOpacity`-Widget gebaut wird (Reduced Motion vollständig respektiert, Designsystem 5.11/§7
erfüllt).

## 5. Testläufe (alle grün)

- `apps/mobile`: `flutter test` → **190/190** (vorher 172 vor ux-09; Zuwachs durch die o. g. neuen
  Testfälle)
- `packages/core`: `flutter test` → 268/268
- `apps/web`: `flutter test` → 315/315
- Backend: `cd backend && npm ci && npm test` → **336/336** (32 Testdateien) — `npm test` allein schlug
  initial mit `ERR_MODULE_NOT_FOUND vitest` fehl, da `node_modules` im frischen Worktree fehlte; nach
  `npm ci` lief die Suite grün (identisches, bereits aus ux-06 bekanntes Umgebungsverhalten, kein Produkt-
  Bug).
- `just analyze` (`dart analyze packages/api_client && flutter analyze apps/web apps/mobile
  packages/core`) → clean, keine Issues
- `./e2e/run.sh` (== `just e2e`) → API 142/142, UI 49/49, keine uncaught JS exceptions
- `just screenshots after` → SCREENSHOTS RESULT 44/44 (Web/Monitor) + App-Teil (`flutter test
  screenshot_test --dart-define=SCREENSHOT_DIR=...`) ohne Fehler

## 6. Screenshot-Diff-Disziplin

`just screenshots after` regeneriert auch Web-/Monitor-PNGs außerhalb des ux-09-App-Scopes. Per `git diff
--stat` geprüft: 5 Monitor-PNGs (`alarm`, `einsatz-fallback`, `einsatzansicht`, `standby`,
`standby-durchsage`) und 3 Web-PNGs (`bf-tage`, `durchsagen`, `tagesablauf`) unterschieden sich nur
pixelweise (nicht-deterministisches Rendering, z. B. Zeitstempel/IDs aus den E2E-Seed-Daten) — mit `git
checkout --` zurückgesetzt, nicht committet (gleiche Disziplin wie ux-08-Verifikation).

Committet sind ausschließlich die 20 App-PNGs unter `docs/design/screenshots/after/app/` für die fünf
betroffenen Screens: 10 geänderte Light-Varianten (`einsaetze`, `einsatzdetail`, `alarm-screen`,
`tagesablauf`, `durchsagen` je 390×844 und 360×640) + 10 neue Dark-Varianten derselben fünf Screens/Größen
(der Screenshot-Harness erzeugt pro Test sowohl die Light- als auch die Dark-Variante, siehe
`screenshots_test.dart`).

## 7. Visuelle Prüfung der ux-09-Nachher-Screenshots

| Screenshot | Ergebnis |
|---|---|
| `einsaetze-390x844.png` / `-360x640` / `-dark`-Varianten | Zeigt den Fehlerzustand (Testdaten lösen `incidentRepositoryProvider`, nicht die überschriebenen Stream-Provider, aus — identisch zum Vorher-Screenshot `before/app/einsaetze-390x844.png`, bestehendes Harness-Verhalten, keine Regression): warning-Icon (orange statt rot), Text „Einsätze konnten nicht geladen werden." + neuer Hinweis „Nach unten ziehen zum erneut Laden." (AC4) klar lesbar, kein Clipping, Navigationsleiste unten unverändert |
| `einsatzdetail-390x844.png` / `-360x640` / `-dark`-Varianten | Analog Fehlerzustand mit Zurück-Pfeil in der AppBar, gleiche Begründung wie oben, kein Clipping |
| `alarm-screen-390x844.png` / `-360x640` / `-dark`-Varianten | „ALARM" groß, „ERSTALARM"-Label mit Icon-Platzhalter (Icon-Font im Debug-Testlauf nicht geladen — bekanntes, bereits in `app-tagesablauf.md` §2 Punkt 1 dokumentiertes Harness-Verhalten, kein neuer Bug), „Dein Fahrzeug"-Karte direkt nach dem Stichwort vor Adresse/Lagebericht (AC5 visuell bestätigt), Quittieren-Button voller Breite unten, in der 360×640-Variante ohne Scrollen sichtbar, guter Kontrast hell (weiß auf Rot) und dunkel (dunkler Text auf hellerem Rot) |
| `tagesablauf-390x844.png` / `-360x640` / `-dark`-Varianten | Zeigt beide Testdaten-Programmpunkte als zukünftige Einträge (Testzeitpunkt `programNowProvider` = 10:00, beide Punkte liegen danach — korrekt kein „Jetzt"-Chip in diesem Snapshot, die „Jetzt"-Hervorhebung selbst ist über `program_screen_test.dart` AC1 abgedeckt, keine Lücke), Icon-Platzhalter aus demselben bekannten Font-Harness-Grund wie oben, kein Clipping, guter Kontrast dunkel |
| `durchsagen-390x844.png` / `-360x640` / `-dark`-Varianten | Durchsage-Card in `primaryContainer`-Fläche (helles Türkis hell / dunkles Petrol dunkel) mit Icon-Platzhalter + Zeitstempel „18:00", deutlich von einer neutralen Listenzeile abgesetzt, kein Clipping, guter Kontrast in beiden Modi |

**Beobachtung Icon-Font-Platzhalter (kein neuer Bug):** Mehrere Screenshots zeigen Material-Icons als
leere Quadrate statt der echten Glyphen. Das ist dasselbe, bereits in `app-tagesablauf.md` §2 Punkt 1 für
den Vorher-Zustand dokumentierte Font-Lade-Problem des Screenshot-Harness im Debug-Testlauf (kein
Produktionsverhalten) — Vergleich mit den Vorher-Screenshots (`before/app/tagesablauf-390x844.png`) zeigt
dasselbe Muster. Kein Bug-Ticket erstellt.

**Beobachtung Fehlerzustand bei Einsätze/Einsatzdetail (kein neuer Bug):** Die Screenshot-Harness-Overrides
für `pairedIncidentsProvider` erreichen nicht `IncidentsScreen._load()`, das über
`incidentRepositoryProvider` lädt (kein Backend im Widget-Test-Kontext vorhanden) — daher zeigt der
Snapshot den Fehlerzustand statt der gefüllten Liste. Identisches Verhalten bereits im Vorher-Screenshot
(`before/app/einsaetze-390x844.png`, pixelgleicher Text), also bestehendes Harness-Verhalten, keine
ux-09-Regression. Die gefüllte Listenansicht (Chips, Trenner, Chevron) ist über die
`incidents_screen_test.dart`-Widget-Tests (die `incidentRepositoryProvider` korrekt überschreiben) vollständig
abgedeckt — kein Bug-Ticket erstellt.

## Ergebnis

Keine neuen Bugs. Alle 35 testbaren ACs der fünf Konzepte (AC1–7 Einsätze, AC1–7 Einsatzdetail, AC1–9
Alarm, AC1–6 Tagesablauf, AC1–6 Durchsagen) durch benannte Widget-Tests oder (bei rein visuellen ACs) durch
die Nachher-Screenshots belegt. Keine Tests gelöscht/abgeschwächt (nur Reindent/Textanpassungen an laut
Konzept geändertem Text), alle „Zu erhaltenden Keys" vorhanden, keine harten Farben in den fünf Screens +
`incident_location_card.dart` + `announcements/*.dart`, Erstalarm/Nachalarmierung unterscheiden sich
ausschließlich über Label+Icon (nie Rotton), kein Blinken, Reduced Motion vollständig respektiert,
regression-inventory.md unverändert grün. Alle Suiten grün (`apps/mobile` 190/190, `packages/core`
268/268, `apps/web` 315/315, Backend 336/336, `flutter analyze`/`dart analyze` clean, `just e2e` API
142/142 + UI 49/49, `just screenshots after` 44/44 + App-Teil fehlerfrei). Zwei dokumentierte,
nicht-regressierende Beobachtungen (Icon-Font-Platzhalter im Harness, Fehlerzustand-Snapshot für
Einsätze/Einsatzdetail) — beide bereits vor ux-09 vorhanden, kein Bug-Ticket nötig.
