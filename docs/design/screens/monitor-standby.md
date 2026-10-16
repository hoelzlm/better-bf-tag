# Monitor — Standby

Grundlage: `docs/design/design-system.md`, Mockup `docs/design/mockups/monitor-standby.html`/`.png`
(ux-02a, wird hier vervollständigt — neue Fassung in Abschnitt 3). Quelle:
`apps/web/lib/screens/monitor_standby_screen.dart`, `monitor_screen.dart` (Umschaltung),
`apps/web/lib/widgets/vehicle_status_bar.dart`, `apps/web/lib/monitor/announcement_banner.dart`.

## 1. Zweck

Dauerzustand des Monitors, solange kein Einsatz alarmiert ist (meist den ganzen BF-Tag über). Unbeaufsichtigt,
aus 5–10 m zu lesen: „Wie spät ist es, wie weit sind wir im Tagesablauf, welches Fahrzeug ist einsatzbereit,
wer sitzt drauf, gibt es gerade eine Durchsage?“ — alles ohne Interaktion, nur per Blick.

## 2. Usability-Probleme heute (Screenshots `standby-1920x1080.png`, `standby-durchsage-1920x1080.png`)

1. **Horizontales Scrollen für Fahrzeuge** (`VehicleStatusBar`, `ListView(scrollDirection: horizontal)`):
   Der Monitor hat keine Eingabe außer Kopplung — ein Betreuer kann nicht scrollen. Bei mehr Fahrzeugen, als
   in die sichtbare Breite passen, sind diese schlicht unsichtbar (kein Hinweis „weitere →“). Kritischer
   Funktionsverlust bei > 6–7 Fahrzeugen.
2. Fahrzeugstatus-Farben kommen aus `_statusColor()`/`_vehicleStatusColor()` mit rohen Material-Farben
   (`Colors.red` für FMS 4 „Am Einsatzort“) — kollidiert mit der Alarmfarbe (Designsystem 2.4, bereits als
   Problem dokumentiert). Keine feste FMS-Palette, jede Codestelle (Standby, Einsatzansicht, App) hat ihre
   eigene Zuordnung.
3. Uhrzeit/Datum/Fahrzeugstatus/Besatzung/Tagesablauf/Durchsage sind alle in einer vertikal zentrierten
   `Column` gestapelt (`Center(child: clockAndStatus)`), nicht in einem festen Grid. Ergebnis: Je nachdem,
   wie viele Panels gerade sichtbar sind (Crew nur bei laufendem BF-Tag+aktiver Schicht, Programm nur bei
   vorhandenen Programmpunkten, Durchsage nur bei vorhandenen Durchsagen), rutscht alles unterschiedlich
   hoch/runter — unruhiges, nicht wiedererkennbares Layout von Tag zu Tag.
4. Crew-Text ohne `maxLines`/`overflow` (`'${assignment.function} ${assignment.displayName}'` als einfacher
   `Text`) — eine lange Namensliste oder ein langer Name sprengt die 200 px breite Karte ungebremst.
5. Bei Folien ist die Aufteilung 2:3 (`Expanded(flex: 2)` Uhr+Status / `Expanded(flex: 3)` Folie) — bei vielen
   Fahrzeugen/Crew-Karten wird die linke Spalte zu schmal, Karten brechen auf mehrere Zeilen um, nichts fängt
   das sauber ab (kein Max-Breite/Scroll/Kürzung definiert).
6. **Durchsage-Banner (`AnnouncementBanner`) ist knallgelb/schwarz** (`Colors.amber`) — liest sich aus der
   Ferne wie ein Warn-/Fehlerzustand, nicht wie eine ruhige Dienstmitteilung. Design-Grundsatz „Durchsage ist
   kein Alarm“ (CONTEXT.md, Designsystem 5.7) wird farblich nicht eingehalten.
7. **Verbindungsbanner nutzt `Colors.red`** für „Keine Verbindung – verbinde neu …“ (`_ConnectionBanner`) —
   verstößt gegen Grundprinzip 1 (Rot = Alarm): ein Verbindungsproblem ist kein Alarm und darf nicht wie
   einer aussehen (Designsystem 5.10 verlangt ausdrücklich „kein Rot“ für Offline/Reconnecting).
8. Name des Monitors (`monitor-name`) ist 20 px grau in der oberen rechten Ecke, kaum lesbar aus der Ferne,
   und wirkt wie Metadaten, nicht wie Teil der Kopfzeile.
9. Keine erkennbare Verbindung zwischen „Fahrzeugstatus“ und „Besatzung“ — heute zwei getrennte visuelle
   Blöcke (`VehicleStatusBar` oben als Kartenreihe, `_CrewPanel` darunter als eigene, andersartige Karten),
   obwohl beide dieselben Fahrzeuge betreffen. Ein Betreuer muss zweimal nachschauen, um „welches Fahrzeug,
   welcher Status, welche Besatzung“ zusammenzuführen.

## 3. Neues Layout

Festes Grid, unabhängig davon, welche Panels gerade Inhalt haben (behebt Problem 3). Kein horizontales
Scrollen irgendwo (behebt Problem 1). Alle Flächen `surface`/`surfaceVariant`, Typografie nach
Designsystem 3.2.

```
┌───────────────────────────────── 1920×1080 ──────────────────────────────────┐
│ Kopfzeile  y:0–140                                                 (surface) │
│  08:34:17            Samstag, 17. Oktober        [●] BF-Tag · Wache 1 (Name) │
│  monitorDisplay 64      monitorBody 28              monitorLabel 22, Marke   │
├───────────────────────────────┬────────────────────────────────────────────┤
│ Fahrzeugstatus + Besatzung    │ Tagesablauf                                 │
│ (y:140–780, x:0–960)          │ (y:140–780, x:960–1920)                     │
│ eine Zeile je Fahrzeug:       │ Jetzt  08:30  Ausbildung – Löschangriff     │
│ [HLF-1] Florian 46/1 ·        │ Danach 12:00  Essen                         │
│   GF Max M. · MA Erika M. (76)│ (restliche Punkte darunter, kleiner,        │
│                     ((FMS 2)) │  `onSurfaceVariant`, max. 6 sichtbar)       │
│ ... weitere Fahrzeuge,        │                                              │
│ vertikal, KEIN Scroll —       │                                              │
│ s. Abschnitt 4 „viele Fzg.“   │                                              │
├───────────────────────────────┴────────────────────────────────────────────┤
│ Folien-/Leerfläche  y:780–980               (nur sichtbar, wenn Folien da)  │
│   Folie: Verhalten im Brandfall – Übersicht  (monitorBody 28, zentriert)    │
├──────────────────────────────────────────────────────────────────────────────┤
│ Fußzeile  y:980–1080  — genau EIN Inhalt gleichzeitig, in dieser Priorität:  │
│  1) Verbindungsbanner (falls nicht live)  2) Durchsage-Live-Banner           │
│  3) „Letzte Durchsage“  4) leer (dezente surfaceVariant-Leiste, kein Text)   │
└──────────────────────────────────────────────────────────────────────────────┘
```

Kopfzeile (140 px) immer identisch sichtbar: Uhrzeit links (`monitorDisplay` 64, Key `monitor-clock-time`
+ `monitor-clock-seconds` in `onSurfaceVariant` daneben), Datum darunter (`monitorLabel`-Größe 22,
Key `monitor-date`), rechts Verbindungspunkt (grün `fms2`-Grün wenn live, `onSurfaceVariant` + Icon
`sync_problem` wenn nicht) + Monitorname (`monitor-name`) jetzt `monitorLabel` 22 **in `onSurface`**, nicht
mehr 20 px grau — Teil der Kopfzeile, nicht Beiwerk.

**Fahrzeugstatus+Besatzung vereinigt** (behebt Problem 9): eine Zeile pro Fahrzeug, `surfaceVariant`-Karte,
volle Breite der linken Spalte, Mindesthöhe 96 px: Fahrzeugkurzname links (`monitorHeadline` 40, fixe Breite
220 px), Besatzung in der Mitte (`monitorBody` 28, `onSurfaceVariant`, **1 Zeile, Ellipsis**, s. Abschnitt 4),
FMS-Pille rechts (56 px, `radiusFull`, Token+1px-Rahmen nach Designsystem 2.4/5.5, **nicht** `Colors.red` o.ä.
— `BftagStatusColors.colorFor(status)`). Vertikal gestapelt, `lg`-Abstand zwischen den Zeilen, **kein**
horizontales Scrollen — stattdessen Verhalten bei vielen Fahrzeugen in Abschnitt 4.

**Tagesablauf** rechte Spalte: „Jetzt“/„Danach“ wie heute hervorgehoben (`primaryContainer`-Hintergrund für
die aktuelle Zeile), zusätzlich bis zu 4 weitere kommende Punkte darunter in gedämpfter Farbe
(`onSurfaceVariant`, `monitorBody` 28) — mehr Kontext als heute (heute nur „Jetzt“+„Danach“), ohne neue
Funktion (Daten sind bereits aus `programItemsProvider` vorhanden, nur mehr Zeilen rendern).

**Folien-Reihe**: eigene, feste 200-px-Zeile zwischen Hauptraster und Fußzeile, erscheint nur, wenn
`slidesProvider` nicht leer ist (sonst entfällt die Zeile komplett und das Hauptraster wird 140–980 statt
140–780 hoch — kein leerer Platzhalter). Folieninhalt zentriert, Markdown-Body wie heute über `SlideRotator`.

**Fußzeile**: ersetzt die bisherige freie Stapelung von Verbindungsbanner/Durchsage/Letzte-Durchsage durch
eine feste 100-px-Leiste mit eindeutiger Priorität (oben). Durchsage-Live-Banner **`primaryContainer`**-
Fläche (nicht mehr Gelb/Schwarz) mit Icon „campaign“ (Megafon) — behebt Problem 6. Verbindungsbanner
**`surfaceVariant`**-Fläche mit Icon „cloud_off“, **kein Rot** — behebt Problem 7 (Text bleibt
„Keine Verbindung – verbinde neu …“, nur die Farbe ändert sich).

## 4. Alle Zustände

- **Kein BF-Tag läuft:** Fahrzeugstatus-Spalte bleibt sichtbar (Fahrzeuge existieren unabhängig vom BF-Tag),
  Besatzungsteil pro Zeile zeigt „—“ (wie heute `_CrewVehicleCard` bei leerer Crew) statt Namen. Tagesablauf-
  Spalte zeigt Leerzustand: Icon „event_note“ 48 px + „Kein Tagesablauf für heute.“ (Designsystem 5.10).
- **BF-Tag läuft, aber keine aktive Schicht:** wie heute (`_CrewPanel` blendet sich komplett aus) — hier:
  Besatzungsteil pro Zeile zeigt „—“, kein Schichtname/-zeitraum in der Kopfzeile des Panels (entfällt, da
  es keine eigene Kopfzeile pro Panel mehr gibt, die Information steckt jetzt in den Zeilen selbst).
- **Viele Fahrzeuge (> 7, mehr als die linke Spalte ohne Zoomen fasst):** Liste **rotiert** seitenweise
  (wie die Folien, gleicher Mechanismus `SlideRotator`-Muster): je 7 Fahrzeuge eine „Seite“, Wechsel alle
  10 s, kleine Punktreihe unten im Panel (`•••`, aktiver Punkt `primary`) zeigt Seite X/Y. Kein Scrollen,
  keine Schriftverkleinerung unter `monitorBody` 28 (Designsystem 3.2 Mindestgröße). Dies ist eine bewusste
  Ablaufänderung (von „alles gleichzeitig, aber unsichtbar abgeschnitten“ zu „alles sichtbar, nacheinander“)
  — keine Funktion geht verloren, nur die Gleichzeitig-Darstellung ändert sich.
- **Lange Besatzungsliste pro Fahrzeug (> 3 Personen):** Namen durch `·` getrennt in einer Zeile,
  `TextOverflow.ellipsis` nach einer Zeile (behebt Problem 4); Gesamtzahl bleibt über den Fahrzeugstatus
  hinaus nirgends versteckt, da die GF-Funktion (wichtigste Person) laut bestehender Sortierung
  (`compareCrewFunctions`) immer zuerst erscheint und damit vor der Kürzung sichtbar bleibt.
- **Lange Durchsage (> 2 Zeilen):** Banner zeigt max. 2 Zeilen `monitorBody` 28, danach Wortumbruch-Ellipsis
  — der Monitor kann nicht wie Web/App „mehr“ anzeigen (keine Interaktion), das ist eine bewusste
  Einschränkung: vollständiger Text bleibt in Admin-Web/App abrufbar, der Monitor zeigt den Anfang als
  Hinweis „es gibt eine Durchsage, Details woanders nachlesen“.
- **Offline/Reconnecting:** Fußzeile zeigt den `surfaceVariant`/„cloud_off“-Banner (Priorität 1, verdrängt
  Durchsage/Letzte-Durchsage so lange, wie die Verbindung tot ist) — bestehender Text/Verhalten
  (`connection-banner-reconnecting`) bleibt, nur Farbe/Icon ändern sich.
- **Leer/Erststart (kein Fahrzeug, kein Tagesablauf, keine Folie, keine Durchsage):** Kopfzeile bleibt immer
  (Uhrzeit ist nie leer), beide Spalten zeigen ihren jeweiligen Leerzustand, Folien-Reihe entfällt, Fußzeile
  zeigt die leere, dezente Variante (keine der drei Banner-Prioritäten greift) — nie ein komplett schwarzer/
  leerer Bildschirm wie potenziell heute bei minimalen Daten.

## 5. Interaktionen/Übergänge

- Keine Interaktion (TV, unbeaufsichtigt). Übergänge: Fade 200 ms beim Wechsel zwischen Zuständen (Folie
  erscheint/verschwindet, Fußzeile-Priorität wechselt), Rotation der Fahrzeugliste mit Cross-Fade 300 ms
  (keine harten Schnitte, kein Blinken — Designsystem 7).
- Standby → Alarm: siehe `monitor-alarm.md` (Übergang ausgelöst durch `alarm.triggered`, sofortiger,
  ungedämpfter Wechsel — hier bewusst **kein** Fade, da der Alarm sofort unübersehbar sein muss).
- Standby → Einsatzansicht ohne neue Alarmierung (z. B. Zurückkehren aus der Rotation mehrerer laufender
  Einsätze): bleibt wie heute dem `MonitorScreen`-State überlassen, kein eigenes Übergangsverhalten hier.

## 6. Testbare Akzeptanzkriterien

1. `Key('vehicle-status-bar')` ist kein horizontal scrollendes `ListView` mehr, sondern eine vertikale Liste
   (`Column`/`ListView(scrollDirection: vertical)` ohne Nutzerscroll-Notwendigkeit bei ≤ 7 Fahrzeugen) —
   Widget-Test: alle `vehicle-tile-<id>` sind gleichzeitig in der Baumstruktur vorhanden (`findsOneWidget`
   für jedes, ohne `scrollUntilVisible`).
2. Bei > 7 Fahrzeugen rotiert die Liste nach spätestens 10 s (Fake-Timer/`tester.pump`): ein Fahrzeug, das
   auf Seite 2 steht, ist nach dem Timer-Tick sichtbar, war vorher nicht sichtbar.
3. Kein Widget in `vehicle_status_bar.dart`/`monitor_standby_screen.dart` verwendet `Colors.red`,
   `Colors.orange`, `Colors.amber` direkt mehr für FMS- oder Durchsage-Flächen — nur
   `BftagStatusColors`/`ColorScheme`/`BftagAlarmColors`-Tokens (Grep-Test nach Umsetzung).
4. `Key('connection-banner-reconnecting')` rendert mit einer Fläche ≠ `Colors.red`/`alarm`-Token (Farbwert-
   Assertion im Widget-Test).
5. `Key('announcement-banner')` rendert mit `primaryContainer`-Fläche, nicht `Colors.amber`.
6. `Key('monitor-name')` und `Key('monitor-date')` haben eine Schriftgröße ≥ 22 px (Designsystem-Minimum).
7. Jede Crew-Zeile begrenzt sich auf eine Zeile mit `TextOverflow.ellipsis` — Widget-Test mit einer sehr
   langen künstlichen Besatzungsliste prüft, dass die Zeilenhöhe des Fahrzeug-Panels konstant bleibt
   (keine zweite Textzeile im Layout).
8. Bestehende Tests bleiben (mit angepassten Finder-Strings, falls sich sichtbarer Text ändert) grün:
   „clock shows hour:minute, seconds, and the date“, die drei Crew-Tests, „standby shows a slide from a
   fake snapshot“, `announcement_banner_test.dart`, „connection reconnecting shows the red banner; live
   hides it“ (Testname darf umbenannt werden, Verhalten — Banner erscheint/verschwindet — bleibt geprüft).

## 7. Zu erhaltende Keys + Semantics

Aus `monitor_standby_screen.dart`, `vehicle_status_bar.dart`, `announcement_banner.dart` (grep-geprüft,
keine `Semantics(...)` vorhanden — reiner Anzeige-Screen ohne interaktive Icon-Buttons für
Nicht-Dispatch-Betrachter; `_openStatusPicker`-Dialog-Optionen behalten ihre Keys):

- `Key('monitor-clock-time')`, `Key('monitor-clock-seconds')`, `Key('monitor-date')`, `Key('monitor-name')`
- `Key('crew-panel-heading')`, `Key('crew-panel-vehicles')`, `Key('crew-vehicle-${vehicle.id}')`
- `Key('program-standby-panel')`, `Key('monitor-program-current')`, `Key('monitor-program-next')`
- `Key('last-announcement-panel')`, `Key('last-announcement-text')`
- `Key('connection-banner-connecting')`, `Key('connection-banner-reconnecting')`
- `Key('connection-indicator')`, `Key('vehicle-status-bar')`, `Key('vehicle-tile-${vehicle.id}')`,
  `Key('status-option-${status.code}')` (im Status-Picker-Dialog, Admin-/Dispatch-Interaktion — bleibt
  unverändert, ist kein Monitor-eigener Fall, da nur bei `canDispatch` nutzbar; der Monitor selbst hat nie
  Dispatch-Berechtigung, dieser Pfad existiert nur, weil `VehicleStatusBar` auch in Admin-Web verwendet wird)
- `Key('announcement-banner')`, `Key('announcement-banner-text')`

Neu empfohlen für die Fahrzeug-Rotation: `Key('vehicle-status-page-indicator')` und
`Key('vehicle-status-page-<n>')` je Seite, damit Tests einzelne Seiten gezielt ansteuern können.

## 8. Funktionsabgleich vs. `docs/testing/regression-inventory.md`

| Funktion (Inventar) | Bleibt erhalten als |
|---|---|
| anzeigen Uhr | Abschnitt 3 Kopfzeile, Keys unverändert |
| anzeigen Fahrzeugstatus/Besatzung | Abschnitt 3 „Fahrzeugstatus+Besatzung vereinigt“ — selbe Daten, ein Panel statt zwei |
| anzeigen Tagesablauf | Abschnitt 3 rechte Spalte, zusätzlich mehr Punkte sichtbar (keine Funktion entfernt) |
| anzeigen Folien | Abschnitt 3 Folien-Reihe, `SlideRotator`-Mechanik unverändert |
| anzeigen Durchsage-Banner | Abschnitt 3 Fußzeile Priorität 2, Text/Timing unverändert, nur Farbe |
| Echtzeit-Updates (alle Komponenten) | unverändert, nur Darstellung je Komponente betroffen |
| Offline/Verbindungsverlust | Abschnitt 3 Fußzeile Priorität 1, Text unverändert, nur Farbe/Icon |

Keine Funktion entfällt. Flow-Änderung (zu begründen, siehe Designsystem-Vorgabe „Abläufe dürfen
vereinfacht werden, wenn das Konzept es ausdrücklich begründet“): Fahrzeugliste rotiert bei > 7 Fahrzeugen
statt horizontal zu scrollen — notwendig, weil der Monitor keine Eingabe hat und eine nicht erreichbare
Scrollposition schlicht Informationsverlust bedeutet (Problem 1).
