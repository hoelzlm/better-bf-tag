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
Designsystem 3.2. Die Verbindungsanzeige ist **keine eigene Fußzeile mehr**, sondern dieselbe
Kopfzeilen-Komponente wie in `monitor-einsatz.md`/`monitor-alarm.md` — siehe „Verbindungsbanner“ unten
(Review-Runde 1 Punkt 7: eine Komponente, eine Position, eine Höhe auf allen drei Screens).

```
┌───────────────────────────────── 1920×1080 ──────────────────────────────────┐
│ Verbindungsbanner  y:0–56   (nur sichtbar, wenn nicht live — surfaceVariant) │
├────────────────────────────────────────────────────────────────────────────┤
│ Kopfzeile  y:56–196 (bzw. 0–140 ohne Banner)                       (surface) │
│  08:34:17            Samstag, 17. Oktober        [●] BF-Tag · Wache 1 (Name) │
│  monitorDisplay 64      monitorBody 28              monitorLabel 22, Marke   │
├───────────────────────────────┬────────────────────────────────────────────┤
│ Fahrzeugstatus + Besatzung    │ Tagesablauf (ohne Folien, volle Spalte)     │
│ (x:0–960, volle Resthöhe)     │ Jetzt  08:30  Ausbildung – Löschangriff     │
│ Zeile pro Fahrzeug:           │ Danach 12:00  Essen                         │
│ [HLF-1] Florian 46/1 ·        │ (bis zu 4 weitere künftige Punkte,          │
│   GF Max M. · MA Erika M. (76)│  gedämpft, NIE vergangene Punkte — s. §6)   │
│                     ((FMS 2)) │                                              │
│ ... weitere Fahrzeuge,        │  — ODER, wenn Folien vorhanden sind: —      │
│ vertikal, KEIN Scroll —       │ ┌ Tagesablauf kompakt (nur Jetzt+Danach),  │
│ s. Abschnitt 4 „viele Fzg.“   │ │ feste Höhe ≈260 px                        │
│                                │ ├ Folie (≥ 900×440 px, hier 960×580 px):   │
│                                │ │  Titel monitorHeadline 40, Body          │
│                                │ │  monitorBody 28, bis 6 Zeilen + Fade     │
├───────────────────────────────┴────────────────────────────────────────────┤
│ Fußzeile  y:980–1080  — genau EIN Inhalt gleichzeitig, in dieser Priorität:  │
│  1) Durchsage-Live-Banner  2) „Letzte Durchsage“  3) leer (dezente Leiste)   │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Verbindungsbanner** (neu, ersetzt die alte Fußzeilen-Variante aus der ersten Fassung): volle Breite, oben,
Höhe ≥ 56 px (vorher 32–100 px je Screen, uneinheitlich), Fläche `surfaceVariant`, Icon „cloud_off“,
Text `monitorBody` 28 px (vorher bis zu 18 px) — exakt dieselbe Komponente mit identischer Position/Höhe in
`monitor-standby.md`/`monitor-einsatz.md`/`monitor-alarm.md` (ein Betreuer lernt „graue Leiste oben = Netz
weg“ einmal, für alle drei Zustände). Keys `connection-banner-connecting`/`connection-banner-reconnecting`
bleiben. Ist sie sichtbar, schiebt sie Kopfzeile+Inhalt um 56 px nach unten (kein Overlay, keine
Verdeckung) — bewusst eine seltene, kurzlebige Zustandsänderung, kein Problem für das sonst feste Grid.
Durch den Wegfall aus der Fußzeile verschiebt sich die Fußzeilen-Priorität von vier auf drei Stufen (Rest
siehe unten).

Kopfzeile (140 px) immer identisch sichtbar: Uhrzeit links (`monitorDisplay` 64, Key `monitor-clock-time`
+ `monitor-clock-seconds` in `onSurfaceVariant` daneben), Datum darunter (`monitorLabel`-Größe 22,
Key `monitor-date`), rechts Verbindungspunkt (grün `fms2`-Grün wenn live, `onSurfaceVariant` + Icon
`sync_problem` wenn nicht) + Monitorname (`monitor-name`) jetzt `monitorLabel` 22 **in `onSurface`**, nicht
mehr 20 px grau — Teil der Kopfzeile, nicht Beiwerk.

**Fahrzeugstatus+Besatzung vereinigt** (behebt Problem 9) über ein **neues, Monitor-eigenes Widget**
`MonitorVehiclePanel` (`apps/web/lib/monitor/monitor_vehicle_panel.dart`, nicht `VehicleStatusBar` —
siehe Review-Runde 1 Punkt 4 und Abschnitt 7 für die genaue Begründung/Abgrenzung): eine Zeile pro
Fahrzeug, `surfaceVariant`-Karte, volle Breite der linken Spalte, Mindesthöhe 96 px: Fahrzeugkurzname links
(`monitorHeadline` 40, fixe Breite 220 px), Besatzung in der Mitte (`monitorBody` 28, `onSurfaceVariant`,
**1 Zeile, Ellipsis**, s. Abschnitt 4), FMS-Pille rechts (56 px, `radiusFull`, Token+1px-Rahmen nach
Designsystem 2.4/5.5, **nicht** `Colors.red` o. ä. — `BftagStatusColors.colorFor(status)`). Vertikal
gestapelt, `lg`-Abstand zwischen den Zeilen, **kein** horizontales Scrollen — stattdessen Verhalten bei
vielen Fahrzeugen in Abschnitt 4.

**Panel-Überschrift** (Review-Runde 1 Punkt 3 — behebt den Funktionsverlust der bisherigen
`<Schichtname> · HH:MM–HH:MM`-Zeile aus der ersten Fassung dieses Dokuments): Die linke Spalte bekommt eine
feste Überschriftenzeile **über** der Fahrzeugliste, Key `crew-panel-heading` (bleibt erhalten, wandert aus
`_CrewPanel` in die neue Panel-Überschrift): „Fahrzeugstatus & Besatzung“ ohne Zusatz, **außer** ein BF-Tag
läuft und eine Schicht ist aktiv — dann „Fahrzeugstatus & Besatzung · Schicht 2 · 08:00–12:00“ (identischer
Text/Format wie die bisherige `_CrewPanel`-Überschrift, nur jetzt Teil der gemeinsamen Panel-Überschrift
statt einer separaten Zeile über den Crew-Karten). `monitorHeadline`-Größe 28 (wie bisher), `onSurfaceVariant`.

**Tagesablauf** rechte Spalte, zwei Varianten je nachdem ob Folien vorhanden sind (löst zugleich Problem 5
und 6 — siehe Begründung unten):

- **Ohne Folien:** volle rechte Spalte. „Jetzt“ (hervorgehoben, `primaryContainer`-Hintergrund) + „Danach“
  wie heute, zusätzlich bis zu **4 weitere künftige** Punkte darunter in gedämpfter Farbe
  (`onSurfaceVariant`, `monitorBody` 28) — mehr Kontext als heute (heute nur „Jetzt“+„Danach“), ohne neue
  Funktion (Daten sind bereits aus `programItemsProvider` vorhanden, nur mehr Zeilen rendern). **Regel für
  vergangene Punkte (behebt Problem 6/Widerspruch): niemals angezeigt** — der Tagesablauf zeigt ausschließlich
  den laufenden und künftige Punkte, nie Vergangenes; ein Betreuer, der auf den Monitor schaut, braucht
  „was kommt noch“, nicht „was war schon“ (das steht im Drehbuch/der Admin-Web). Insgesamt max. 6 sichtbare
  Zeilen (Jetzt + Danach + 4 weitere).
- **Mit Folien:** rechte Spalte splittet sich: oben ein **kompakter** Tagesablauf-Block (feste Höhe ≈260 px)
  mit **nur** „Jetzt“+„Danach“ (keine der 4 weiteren Zeilen — dafür ist in diesem Modus kein Platz, und die
  Folie hat Vorrang vor zusätzlichem Tagesablauf-Kontext), darunter die Folienfläche volle Restbreite/-höhe
  (960×580 px, deutlich über dem geforderten Minimum 900×440 px — behebt Problem 5: die alte 200-px-Zeile
  zeigte nur eine Titelzeile, aus 5–10 m nicht als Inhalt lesbar). Folie zeigt Titel `monitorHeadline` 40 px
  SemiBold + Markdown-Body `monitorBody` 28 px (wie heute über `SlideRotator`), bei langem Body nach 6
  Zeilen Fade+„⌄“-Hinweis (identisches Muster wie Meldebild-Überlauf in `monitor-einsatz.md` Abschnitt 4 —
  ein Betreuer lernt das Überlauf-Symbol einmal für die ganze App).

**Fußzeile**: jetzt **drei** Prioritätsstufen (Verbindungsbanner ist nach Punkt 7 aus der Fußzeile
ausgezogen): 1) Durchsage-Live-Banner **`primaryContainer`**-Fläche (nicht mehr Gelb/Schwarz) mit Icon
„campaign“ (Megafon) — behebt Problem 6 der ersten Fassung; 2) „Letzte Durchsage“; 3) leere, dezente
`surfaceVariant`-Leiste ohne Text.

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
- **Offline/Reconnecting:** das Verbindungsbanner (siehe Abschnitt 3) erscheint oben, volle Breite,
  ≥ 56 px hoch — bestehender Text/Verhalten (`connection-banner-reconnecting`) bleibt, nur Farbe/Icon/
  Position/Höhe ändern sich (Review-Runde 1 Punkt 7, ersetzt die alte Fußzeilen-Variante).
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

1. `Key('crew-panel-vehicles')` (das neue `MonitorVehiclePanel`) ist kein horizontal scrollendes `ListView`
   mehr, sondern eine vertikale Liste ohne Nutzerscroll-Notwendigkeit bei ≤ 7 Fahrzeugen — Widget-Test: alle
   `crew-vehicle-<id>` sind gleichzeitig in der Baumstruktur vorhanden (`findsOneWidget` für jedes, ohne
   `scrollUntilVisible`).
2. Bei > 7 Fahrzeugen rotiert die Liste nach spätestens 10 s (Fake-Timer/`tester.pump`): ein Fahrzeug, das
   auf Seite 2 steht, ist nach dem Timer-Tick sichtbar, war vorher nicht sichtbar.
3. Kein Widget in `monitor_vehicle_panel.dart`/`monitor_standby_screen.dart` verwendet `Colors.red`,
   `Colors.orange`, `Colors.amber` direkt mehr für FMS- oder Durchsage-Flächen — nur
   `BftagStatusColors`/`ColorScheme`/`BftagAlarmColors`-Tokens (Grep-Test nach Umsetzung).
4. `Key('connection-banner-reconnecting')` rendert mit einer Fläche ≠ `Colors.red`/`alarm`-Token und einer
   Höhe ≥ 56 px, oberhalb der Kopfzeile, auf allen drei Monitor-Screens identisch (Farbwert- + Layout-
   Assertion im Widget-Test, geteilter Test-Helper über `monitor_standby_screen_test.dart`,
   `monitor_incident_screen_test.dart`, `monitor_alarm_screen_test.dart`).
5. `Key('announcement-banner')` rendert mit `primaryContainer`-Fläche, nicht `Colors.amber`.
6. `Key('monitor-name')` und `Key('monitor-date')` haben eine Schriftgröße ≥ 22 px (Designsystem-Minimum).
7. Jede Crew-Zeile begrenzt sich auf eine Zeile mit `TextOverflow.ellipsis` — Widget-Test mit einer sehr
   langen künstlichen Besatzungsliste prüft, dass die Zeilenhöhe des Fahrzeug-Panels konstant bleibt
   (keine zweite Textzeile im Layout).
8. `Key('crew-panel-heading')` zeigt „Fahrzeugstatus & Besatzung“ ohne BF-Tag/Schicht, und
   „Fahrzeugstatus & Besatzung · Schicht 2 · 08:00–12:00“ bei laufendem BF-Tag mit aktiver Schicht — Widget-
   Test mit beiden Fällen (ersetzt/erweitert den bestehenden Crew-Heading-Test aus `monitor_screen_test.dart`).
9. Tagesablauf-Spalte zeigt nie einen Programmpunkt, dessen `endsAt` bereits in der Vergangenheit liegt und
   der nicht der aktuelle ist — Widget-Test mit einem künstlichen vergangenen Punkt prüft dessen Abwesenheit.
10. Bei vorhandenen Folien hat die Folienfläche eine Mindestgröße von 900×440 px und zeigt sowohl Titel
    (`monitorHeadline`, ≥ 40 px) als auch Markdown-Body (`monitorBody`, ≥ 28 px) — Layout-Test gegen die
    `Expanded`/`SizedBox`-Constraints plus Textvorhandensein.
11. Bestehende Tests bleiben (mit angepassten Finder-Strings, falls sich sichtbarer Text/Keys ändert) grün:
    „clock shows hour:minute, seconds, and the date“, die drei Crew-Tests (Key-Umstellung
    `vehicle-tile-<id>` → `crew-vehicle-<id>` im Monitor-Kontext), „standby shows a slide from a fake
    snapshot“, `announcement_banner_test.dart`, „connection reconnecting shows the red banner; live hides
    it“ (Testname darf umbenannt werden, Verhalten — Banner erscheint/verschwindet — bleibt geprüft).

## 7. Zu erhaltende Keys + Semantics

Aus `monitor_standby_screen.dart`, `announcement_banner.dart` (grep-geprüft, keine `Semantics(...)`
vorhanden — reiner Anzeige-Screen ohne interaktive Icon-Buttons für Nicht-Dispatch-Betrachter):

- `Key('monitor-clock-time')`, `Key('monitor-clock-seconds')`, `Key('monitor-date')`, `Key('monitor-name')`
- `Key('crew-panel-heading')`, `Key('crew-panel-vehicles')`, `Key('crew-vehicle-${vehicle.id}')`
- `Key('program-standby-panel')`, `Key('monitor-program-current')`, `Key('monitor-program-next')`
- `Key('last-announcement-panel')`, `Key('last-announcement-text')`
- `Key('connection-banner-connecting')`, `Key('connection-banner-reconnecting')`
- `Key('announcement-banner')`, `Key('announcement-banner-text')`

**Review-Runde 1 Punkt 4 — wo landen `vehicle-status-bar`/`vehicle-tile-<id>`/`connection-indicator`:**

`VehicleStatusBar` (inkl. ihrer Keys `vehicle-status-bar`, `vehicle-tile-${vehicle.id}`,
`connection-indicator`, `status-option-${status.code}`) bleibt **ausschließlich** das Widget aus
`web-lage.md` (Admin-Web/Lage) — jenes Dokument legt ihre Keys final fest, dieses Dokument ändert daran
nichts. Der Monitor verwendet `VehicleStatusBar` ab sofort **nicht mehr**; er bekommt das oben beschriebene,
eigene `MonitorVehiclePanel`. Für den Monitor bedeutet das konkret:

- `Key('vehicle-status-bar')` kommt auf dem Monitor **nicht mehr vor** — ersetzt durch
  `Key('crew-panel-vehicles')` (dieselbe Rolle: Container der Fahrzeugliste, aber vertikal statt horizontal
  scrollend, siehe Problem 1/AC 1).
- `Key('vehicle-tile-${vehicle.id}')` kommt auf dem Monitor **nicht mehr vor** — ersetzt durch
  `Key('crew-vehicle-${vehicle.id}')` (dieselbe Rolle: eine Kachel/Zeile je Fahrzeug, jetzt inklusive
  Besatzung statt nur FMS-Status, da `MonitorVehiclePanel` Fahrzeugstatus+Besatzung von Anfang an vereint —
  siehe Problem 9 der ersten Fassung). Der bestehende Test in `monitor_screen_test.dart`
  (`find.byKey(const Key('vehicle-tile-v1'))`) wird auf `crew-vehicle-v1` umgestellt — das ist eine reine
  Testanpassung an den neuen, Monitor-eigenen Key, keine geprüfte Funktion geht verloren (dieselbe Prüfung,
  „ein Fahrzeug erscheint in der Liste“, bleibt grün, nur mit dem neuen Key).
- `Key('connection-indicator')` (die kleine „live“/„verbinde neu…“-Textzeile **innerhalb** der alten
  `VehicleStatusBar`) kommt auf dem Monitor **nicht mehr vor** — sie wird durch das eine, gemeinsame
  Verbindungsbanner am oberen Bildschirmrand (Abschnitt 3, Keys `connection-banner-connecting`/
  `-reconnecting`) ersetzt. Begründung: Mit dem alten Layout zeigte der Monitor den Verbindungsstatus an
  **zwei** Stellen gleichzeitig (kleiner Text in der `VehicleStatusBar` + Fußzeilen-Banner) — redundant und
  uneinheitlich (Problem 7 der ersten Fassung, jetzt durch Punkt 7 der Review endgültig vereinheitlicht).
  `status-option-${status.code}` entfällt ebenfalls vollständig auf dem Monitor, da `MonitorVehiclePanel`
  nie interaktiv ist (der Monitor hat nie `canDispatch`) — dieser Dialog existierte auf dem Monitor ohnehin
  nur als nicht genutzter Seiteneffekt der gemeinsamen `VehicleStatusBar`-Nutzung, nicht als eigene Funktion.

Neu empfohlen für die Fahrzeug-Rotation: `Key('vehicle-status-page-indicator')` und
`Key('vehicle-status-page-<n>')` je Seite, damit Tests einzelne Seiten gezielt ansteuern können.

## 8. Funktionsabgleich vs. `docs/testing/regression-inventory.md`

| Funktion (Inventar) | Bleibt erhalten als |
|---|---|
| anzeigen Uhr | Abschnitt 3 Kopfzeile, Keys unverändert |
| anzeigen Fahrzeugstatus/Besatzung | Abschnitt 3 „Fahrzeugstatus+Besatzung vereinigt“ — selbe Daten, neues `MonitorVehiclePanel` statt `VehicleStatusBar`+`_CrewPanel`, Schicht-Überschrift bleibt in `crew-panel-heading` |
| anzeigen Tagesablauf | Abschnitt 3 rechte Spalte, zusätzlich mehr Punkte sichtbar (ohne Folien), nie vergangene Punkte (keine Funktion entfernt, nur Regel präzisiert) |
| anzeigen Folien | Abschnitt 3 Folienfläche (jetzt ≥ 900×440 px statt 200 px hoch), `SlideRotator`-Mechanik unverändert |
| anzeigen Durchsage-Banner | Abschnitt 3 Fußzeile Priorität 1, Text/Timing unverändert, nur Farbe |
| Echtzeit-Updates (alle Komponenten) | unverändert, nur Darstellung je Komponente betroffen |
| Offline/Verbindungsverlust | Abschnitt 3 Verbindungsbanner (jetzt oben statt in der Fußzeile), Text unverändert, nur Farbe/Icon/Position |

Keine Funktion entfällt. Flow-Änderungen (begründet, siehe Designsystem-Vorgabe „Abläufe dürfen vereinfacht
werden, wenn das Konzept es ausdrücklich begründet“): (1) Fahrzeugliste rotiert bei > 7 Fahrzeugen statt
horizontal zu scrollen — notwendig, weil der Monitor keine Eingabe hat und eine nicht erreichbare
Scrollposition schlicht Informationsverlust bedeutet (Problem 1). (2) `vehicle-status-bar`/
`vehicle-tile-<id>`/`connection-indicator` existieren auf dem Monitor nicht mehr als eigenständige Keys,
sondern als `crew-panel-vehicles`/`crew-vehicle-<id>`/Verbindungsbanner — dieselbe Information bleibt
vollständig erhalten, nur konsolidiert in einem Monitor-eigenen Widget statt im geteilten
`VehicleStatusBar` (siehe Abschnitt 7, Review-Runde 1 Punkt 4).
