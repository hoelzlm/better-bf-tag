# Monitor — Alarmzustand

Grundlage: `docs/design/design-system.md` Abschnitt 5.11 (Alarm-Fläche) und 7 (Bewegung). Baut auf
`docs/design/mockups/monitor-alarm.html`/`.png` (ux-02a) auf und vervollständigt es. Betrifft
`apps/web/lib/screens/monitor_screen.dart` (Umschaltung/Timer) und einen **neuen** Screen
`monitor_alarm_screen.dart` (Vorschlag für ux-03 — existiert heute nicht als eigene Datei, siehe Abschnitt 2).

## 1. Zweck

Der Moment, in dem ein Einsatz alarmiert wird (Erstalarm) oder ein bereits laufender Einsatz weitere
Fahrzeuge nachalarmiert. Muss aus 10 m Entfernung unmissverständlich sein, bevor noch irgendjemand den
Monitor bewusst ansieht — die lauteste, deutlichste Fläche der gesamten Software. Geht nach einer festen
Anzeigedauer automatisch in die ruhigere `monitor-einsatz.md`-Ansicht über.

## 2. Usability-Probleme heute (Screenshot `alarm-1920x1080.png` — identisch mit `einsatzansicht-1920x1080.png`)

1. **Es gibt keinen eigenen Alarmzustand.** `monitor_screen.dart` zeigt bei jedem `alarm.triggered` direkt
   `MonitorIncidentScreen` — dieselbe ruhige, schwarze Einsatzansicht, die auch nach 40 Minuten laufendem
   Einsatz zu sehen ist. Der einzige Unterschied ist ein kleiner gelber Badge oben rechts
   (`monitor-incident-alarm-label`, „ERSTALARM“, ca. 120×36 px auf 1920×1080). Das ist das mit Abstand
   größte Usability-Problem dieser Karte: Ein Betreuer, der zufällig in den Raum kommt, **kann einen gerade
   ausgelösten Alarm nicht von einem seit Stunden laufenden Einsatz unterscheiden**, wenn er nicht gezielt in
   die obere rechte Ecke schaut.
2. Hintergrund bleibt in beiden Fällen Schwarz (`Scaffold(backgroundColor: Colors.black)`) — die für Alarm
   reservierte Farbe (Designsystem Grundprinzip 1, 5.11: „vollflächig alarm/onAlarm“) kommt auf dem Monitor
   **nirgends vor**. Rot taucht nur im Stichwort-Text auf (`Colors.redAccent`, 56 px) — Textfarbe, keine
   Fläche, aus 10 m kaum als „ALARM“ lesbar, eher wie ein hervorgehobenes Wort.
3. Kein Ton-Hinweis in der UI selbst (der Gong spielt zwar, `alarm_sound.dart`, aber visuell gibt es keine
   Bestätigung, *dass* gerade etwas Alarmierendes passiert — bei stummgeschaltetem/lautlosem Raum bleibt nur
   der unauffällige gelbe Badge).
4. Erstalarm und Nachalarmierung sehen **identisch** aus (derselbe Screen, derselbe Badge-Mechanismus über
   `alarmSequenceLabel`) — beide Fälle sind laut CONTEXT.md unterschiedlich wichtig („Nachalarmierung“ auf
   einen bereits laufenden, bekannten Einsatz ist für einen Betreuer, der den Einsatz schon kennt, weniger
   überraschend als ein komplett neuer Erstalarm), aber visuell nicht unterscheidbar genug.

## 3. Neues Layout

Neuer, eigenständiger Screen (volle Fläche `alarm`/`onAlarm`, Designsystem 2.1/5.11), zeitlich begrenzt
(Abschnitt 5), danach automatischer Übergang zu `monitor-einsatz.md`. Vervollständigt
`docs/design/mockups/monitor-alarm.html` (gerendert, s. u.) um Meldebild-Mehrzeiler, Fahrzeugliste mit
FMS-Pillen und Quittiert-Fortschritt, passend zur Einsatzansicht-Fassung.

```
┌───────────────────────────────── 1920×1080 ──────────────────────────────────┐
│  ████████████████████████████ Vollfläche `alarm` #FF5449 ███████████████████│
│                                                                                │
│  [ERSTALARM]  (pulsierendes Icon „notification_important“)        08:34:40   │
│   monitorHeadline 40, onAlarm-auf-onAlarm-Pille, ≤1Hz-Puls          monitorDisplay 64
│                                                                                │
│  B3 GROSSBRAND LAGERHALLE                                                     │
│  monitorAlarmTitle 96, Bold, onAlarm                                          │
│  Industriestraße 7                                monitorDisplay 64, onAlarm  │
│  Starke Rauchentwicklung aus dem Dach.            monitorBody 28, onAlarm     │
│                                                                                │
│  [ HLF-1  alarmiert ]   [ RTW-1  alarmiert ]   [ DLK-1  alarmiert ]           │
│   onAlarm-auf-alarm-Pille, monitorAlarmTitle 56 Name + monitorLabel 28 „alarmiert“│
│                                                                                │
│                                                                                │
│  seit 00:08 · 0/3 quittiert                        monitorBody 28, onAlarm 90%│
└──────────────────────────────────────────────────────────────────────────────┘
```

Badge „ERSTALARM“/„N. NACHALARMIERUNG“ (Text via `alarmSequenceLabel(...).toUpperCase()`, bestehende
Funktion wiederverwendet) links oben, Pille in `onAlarm`-auf-`alarm` mit 24 % Deckkraft-Fläche (dunkler
Akzent auf der hellen Alarmfläche) + Icon „notification_important“, das mit ≤ 1 Hz pulsiert (Designsystem 7
— **nicht** die ganze Fläche blinkt, nur dieses eine Icon/Badge). Uhrzeit rechts oben, `monitorDisplay` 64.

Stichwort in `monitorAlarmTitle` 96 px Bold — die einzige Stelle in der gesamten Oberfläche, die diese
Rolle nutzt (Designsystem 3.2: „Stichwort im Alarmzustand“ ist exakt dafür vorgesehen). Adresse direkt
darunter, dann Meldebild (**mindestens 40 px** `monitorBody`-Stufe, vorher 28 px — Review-Runde 1 Punkt 10:
auf der lautesten, am wenigsten mit Inhalt gefüllten Fläche der App darf kein Text kleiner sein als auf den
ruhigeren Screens; max. 3 Zeilen, danach Kürzung mit „…“ — in diesem Zustand ist nur das Nötigste wichtig,
der vollständige Text ist ohnehin in `monitor-einsatz.md` nach dem Übergang zu sehen).

Fahrzeugchips: Fahrzeugname **in `monitorAlarmTitle` 56 px** (vorher `monitorHeadline` 40 — Review-Runde 1
Punkt 10, die Fläche hatte laut Mockup ca. 45 % ungenutzten Leerraum, der jetzt in größere, aus 10 m noch
leichter lesbare Chips fließt) + Label „alarmiert“ (`monitorLabel` **28 px**, Review-Runde 2 Punkt 2 — vorher
22 px im Raster angegeben, das widersprach dem 40-px-Mindestmaß für Fließtext auf dieser Fläche; im Mockup
die HTML-Klasse `.sub`) auf `onAlarm`-bei-16%-Fläche-Pille (dunkler Ton auf hellem Alarmrot, wie im
bestehenden Mockup) — bewusst **keine FMS-Pille** hier (die Fahrzeuge haben in diesem Moment typischerweise
noch FMS 3 „Einsatz übernommen“ oder sind mitten im Statuswechsel; die FMS-Farbpalette hier einzublenden
würde zwei Farbsysteme auf einer Fläche mischen und die Lesbarkeit aus 10 m verschlechtern) — FMS-Status
erscheint erst wieder in der ruhigeren Einsatzansicht.

**Datenquelle der Fahrzeugliste** (Review-Runde 2 Punkt 1d): die im Alarmzustand gezeigten Fahrzeuge sind
exakt `Alarm.vehicleIds` (`packages/core/lib/src/domain/alarm.dart:160`) der **auslösenden** Alarmierung —
also des `Alarm`-Objekts, dessen `alarm.triggered`-Event den aktuell laufenden 20-s-Timer gestartet (oder neu
gestartet) hat. Keine neue Datenquelle, keine serverseitige Erweiterung: `vehicleIds` existiert bereits exakt
für diesen Zweck und wird vom bestehenden `Alarm`-Modell unverändert übernommen.

Fußzeile: „seit mm:ss“ (Laufzeit seit `triggeredAt` **dieser** Alarmierung, nicht des Einsatzes insgesamt —
bei einer Nachalarmierung ist das die Zeit seit der Nachalarmierung, nicht seit dem Erstalarm) + „X/Y
quittiert“ (lebt von denselben Daten wie in `monitor-einsatz.md`, hier kleiner/zurückhaltender dargestellt,
da in den ersten Sekunden ohnehin kaum jemand quittiert haben wird).

## 4. Alle Zustände

- **Erstalarm:** Badge „ERSTALARM“, wie oben.
- **Nachalarmierung:** Badge „N. NACHALARMIERUNG“ (z. B. „1. NACHALARMIERUNG“, Text aus
  `alarmSequenceLabel`), sonst identisches Layout — der Unterschied liegt ausschließlich im Badge-Text, nicht
  in Farbe/Ton (Designsystem 5.11: „NICHT über unterschiedliche Rottöne unterscheiden“). Die
  Fahrzeugliste zeigt nur die **neu** alarmierten Fahrzeuge dieser Nachalarmierung (nicht die bereits zuvor
  alarmierten) — macht sofort klar, *was* sich gerade geändert hat.
- **Viele neu alarmierte Fahrzeuge (> 6):** Chips umbrechen zweizeilig (`Wrap`), bei > 10 zusätzlich auf
  `monitorHeadline`-Größe 32 px verkleinert (bleibt über Designsystem-Minimum 22 px) statt die Fläche zu
  sprengen.
- **Langes Meldebild:** wie Abschnitt 3 beschrieben, nach 3 Zeilen Kürzung mit „…“ — kein Mehr-Lesen-Hinweis
  nötig, da der Übergang zur ausführlichen Einsatzansicht ohnehin automatisch und zeitnah erfolgt.
  **Langes Stichwort** (> 1 Zeile bei 96 px auf 1920 px Breite, ca. 28 Zeichen): `FittedBox`/automatische
  Skalierung bis minimal 64 px (`monitorDisplay`-Stufe), danach Umbruch auf 2 Zeilen — niemals kleiner als
  64 px für das Stichwort, auch nicht bei sehr langen Einsatzstichworten.
- **Reduced-Motion aktiv:** kein Puls am Badge-Icon, Icon bleibt statisch sichtbar (Designsystem 7) — der
  Fade-in beim Erscheinen entfällt ebenfalls (0 ms, Fläche erscheint sofort), damit Alarmierung bei
  deaktivierten Animationen nicht verzögert wirkt.
- **Verbindungsverlust während des Alarmzustands:** dasselbe Verbindungsbanner wie in
  `monitor-standby.md`/`monitor-einsatz.md` (Abschnitt 3 dort — volle Breite, ≥ 56 px, `surfaceVariant`,
  Review-Runde 1 Punkt 7: eine Komponente, eine Höhe, eine Position auf allen drei Monitor-Screens) —
  erscheint **über** der Alarmfläche, verdrängt nichts von Stichwort/Adresse (die beginnen entsprechend
  56 px tiefer). Der Alarm bleibt trotz Verbindungsproblem vollständig sichtbar — anders als bei
  Standby/Einsatzansicht hat ein Verbindungsproblem hier keine Priorität vor der Alarmdarstellung selbst.
- **Alarm läuft ab, während bereits ein anderer Alarmzustand gezeigt wird** (zweiter, unabhängiger Einsatz
  wird mitten im ersten Alarmzustand ausgelöst): der neue Alarm ersetzt sofort den alten (gleiches
  Verhalten wie heute bei `_shownIncidentId`-Überschreibung durch `liveAlarmTriggeredProvider`), der alte
  Einsatz ist weiterhin über die normale Rotation der Einsatzansicht erreichbar, verliert aber keine Daten.
- **Zwei/mehrere `alarm.triggered`-Events für denselben Einsatz kurz hintereinander, innerhalb der
  laufenden 20-s-Anzeigedauer** (Review-Runde 1 Punkt 11, Randfall des 20-s-Timers — bisher nicht
  spezifiziert): der laufende 20-s-Timer **wird neu gestartet** (nicht verlängert/addiert, nicht ignoriert)
  — jede neue Alarmierung verdient volle 20 s eigene Sichtbarkeit, sonst könnte eine schnell aufeinander
  folgende Nachalarmierung bei schlechtem Timing weniger als die vollen 20 s zu sehen bekommen. Badge-Text/
  Fahrzeugliste aktualisieren sich dabei sofort auf den neuesten Stand (wie im bestehenden Verhalten „neuer
  Alarm ersetzt den alten“ oben).
- **`alarm.triggered` für einen komplett anderen Einsatz, während der 20-s-Timer für Einsatz A noch läuft**
  (Randfall, Abgrenzung zum vorherigen Punkt): wie im bereits bestehenden Zustand „Alarm läuft ab, während
  bereits ein anderer Alarmzustand gezeigt wird“ oben beschrieben — der neue Einsatz B ersetzt sofort die
  Anzeige, bekommt seine eigenen vollen 20 s, Einsatz A bleibt über die Rotation der Einsatzansicht
  erreichbar.
- **Monitor koppelt/lädt neu, während serverseitig ein `alarm.triggered` im Snapshot-Fenster liegt** (Randfall
  der bestehenden Snapshot-Ausnahme aus Abschnitt 5 „Auslöser“): zeigt **nicht** den lauten Alarmzustand
  (kein Timer startet), sondern direkt `MonitorIncidentScreen` — konsistent mit der bestehenden Regel
  „Alarms arriving via the initial snapshot never ring the gong“, hier erweitert um „... und lösen auch
  keinen visuellen Alarmzustand aus“, da beide Signale (Ton + Vollflächen-Alarm) dieselbe Bedingung teilen
  (ein frisch koppelnder Monitor darf nicht rückwirkend für längst erfolgte Alarmierungen alarmieren).
- **Browser-Tab/Gerät verliert währenddessen den Fokus/wird minimiert** (kein praktischer Fall auf einem
  fest verbauten Monitor-TV, aber zur Vollständigkeit): der 20-s-Timer läuft serverseitig/im App-State
  unverändert weiter (`Timer`, kein `AnimationController`, der bei fehlendem Vsync pausieren könnte) — beim
  Zurückkehren in den Vordergrund zeigt der Screen korrekt den Zustand, der zur verstrichenen Zeit passt
  (Alarm oder bereits die ruhige Einsatzansicht), kein Nachholen/Wiederholen der 20 s.
- **Der Einsatz wird geschlossen (`incident.closed`), während der 20-s-Alarmzustand noch läuft** (Review-
  Runde 2 Punkt 1a, bisher nicht spezifiziert): der laufende `_alarmFlashDuration`-Timer wird sofort
  **abgebrochen** (nicht abgewartet) — derselbe Mechanismus, mit dem `MonitorIncidentScreen` heute schon auf
  einen nicht mehr gültigen `_shownIncidentId` reagiert (Abschnitt „stillValid“ in `monitor_screen.dart`,
  Zeilen 188–191). Gibt es zu diesem Zeitpunkt einen anderen offenen Einsatz mit Alarmierung (einen weiteren
  `candidates`-Eintrag), springt der Monitor direkt in dessen ruhige `MonitorIncidentScreen`-Ansicht — **nicht**
  erneut in den lauten Alarmzustand, denn für diesen anderen Einsatz liegt kein neues `alarm.triggered`-Event
  vor, nur das bereits bekannte. Gibt es keinen weiteren offenen Einsatz mit Alarmierung, geht der Monitor
  direkt zu `MonitorStandbyScreen` über — ohne Zwischenstopp in der (dann ohnehin leeren) Einsatzansicht.
- **Die 15-s-Rotation zwischen mehreren offenen Einsätzen pausiert während des 20-s-Alarmzustands** (Review-
  Runde 2 Punkt 1c, Ergänzung zum bestehenden Punkt „Rotation löst den Alarmzustand nicht erneut aus“ in
  Abschnitt 5): Der `_incidentRotationInterval`-Timer (15 s, in `monitor_screen.dart`) läuft während der
  Vollflächen-Alarmanzeige **nicht** — es wäre widersinnig, während der lautesten, wichtigsten 20 Sekunden im
  Hintergrund zu einem anderen Einsatz weiterzurotieren, den der Betreuer in diesem Moment ohnehin nicht sieht.
  Nach dem automatischen Übergang zur Einsatzansicht (Abschnitt 5) läuft die Rotation normal weiter, als wäre
  sie nie unterbrochen worden (kein Nachholen verpasster Zeit, einfach neu gestartet).

## 5. Interaktionen/Übergänge

**Lebenszyklus des 20-s-Alarmzustands (Review-Runde 1 Punkt 11, Zusammenfassung aller Randfälle):**
jedes `alarm.triggered` außerhalb des initialen Snapshots startet (oder **neu startet**, falls bereits
einer läuft) einen 20-s-Timer und zeigt die Vollflächen-Alarmfläche für genau diesen Einsatz/diese
Alarmierung; läuft der Timer ab, ohne dass ein neueres Event ihn zurückgesetzt hat, folgt der automatische
Cross-Fade zu `MonitorIncidentScreen`. Es existiert zu jedem Zeitpunkt höchstens ein aktiver 20-s-Timer.
Details/Randfälle siehe Abschnitt 4.

**Gesamter Kreislauf (Review-Runde 2 Punkt 1, kurze Zusammenfassung):**

```
Standby ──alarm.triggered──▶ Alarm (20 s) ──Timer abgelaufen──▶ Einsatzansicht ──incident.closed──▶ Standby
                                   │                                    │         (oder: weiterer offener
                                   └──incident.closed (Abschnitt 4)─────┘          Einsatz → Einsatzansicht)
```

Jeder Zustand kann jederzeit erneut in „Alarm“ unterbrochen werden, sobald ein neues `alarm.triggered`
eintrifft (auch während „Einsatzansicht“ oder sogar während eines bereits laufenden anderen „Alarm“ —
Abschnitt 4). Der Kreis schließt sich erst, wenn kein offener Einsatz mit Alarmierung mehr existiert
(`candidates.isEmpty`), dann zurück zu Standby.

- **Auslöser:** jedes live empfangene `alarm.triggered`-Event (Erstalarm oder Nachalarmierung) — **nicht**
  Alarme, die bereits im initialen Snapshot enthalten waren (bestehende Unterscheidung bleibt: „Alarms
  arriving via the initial snapshot never ring the gong“ — dieselbe Bedingung schaltet auch nicht in den
  Alarmzustand, sondern direkt in die ruhige Einsatzansicht, falls der Monitor gerade erst neu lädt/koppelt).
- **Anzeigedauer:** fest 20 s (neue Konstante, z. B. `_alarmFlashDuration = Duration(seconds: 20)`, parallel
  zum bestehenden `_incidentRotationInterval`-Muster in `monitor_screen.dart`). Nach Ablauf: automatischer,
  mit 200 ms Cross-Fade abgefederter Übergang zu `MonitorIncidentScreen` (`monitor-einsatz.md`) für denselben
  Einsatz — **kein** Zurückspringen zu Standby, der Einsatz läuft ja weiter.
- **Kein vorzeitiges Verlassen durch Quittierung:** Die Anzeigedauer ist fest, unabhängig davon, ob/wie
  schnell Empfänger quittieren — bewusste Vereinfachung für deterministisches, testbares Verhalten (siehe
  Akzeptanzkriterium 2). Begründung: Quittierung bestätigt nur den Empfang, nicht „Betreuer hat den Monitor
  gesehen“ (CONTEXT.md, „Quittierung“) — ein früherer Abbruch wäre kein verlässliches Signal.
- **Eintritt:** kein Fade-in (Designsystem 7 verlangt hier maximale Dringlichkeit) — Fläche erscheint sofort
  in voller Farbe, nur das Badge-Icon pulsiert danach weiter (≤ 1 Hz).
- **Gong:** bestehendes `alarm_sound.dart`-Verhalten (`unawaited(ref.read(alarmSoundProvider).play())`)
  bleibt unverändert, läuft weiterhin genau einmal pro `alarm.triggered`, unabhängig vom neuen visuellen
  Zustand.
- **Rotation zwischen mehreren bereits laufenden (nicht gerade neu alarmierten) Einsätzen:** bleibt
  ausschließlich Aufgabe der ruhigen Einsatzansicht (15-s-Rotation) — der laute Alarmzustand wird dadurch
  **nicht** erneut ausgelöst, nur durch ein echtes neues `alarm.triggered`-Event. Zusätzlich (Review-Runde 2
  Punkt 1c, Details in Abschnitt 4): diese 15-s-Rotation **pausiert vollständig**, solange der 20-s-
  Alarmzustand aktiv ist, und läuft nach dem automatischen Übergang zur Einsatzansicht unverändert weiter.

## 6. Testbare Akzeptanzkriterien

1. Bei einem live empfangenen `alarm.triggered` zeigt der Monitor für genau `_alarmFlashDuration` (20 s) eine
   Vollflächen-`alarm`-Ansicht, danach automatisch `MonitorIncidentScreen` für denselben Einsatz — Fake-Timer-
   Test (`tester.pump(const Duration(seconds: 20))`) prüft beide Phasen.
2. Alarme aus dem initialen Snapshot lösen **keinen** Alarmzustand aus (zeigen direkt die ruhige
   Einsatzansicht) — bestehender Test „without playing the gong“ bleibt gültig und wird um die Prüfung
   erweitert, dass dabei auch keine Vollflächen-Alarmfläche erscheint.
3. Badge-Text ist „ERSTALARM“ bei der ersten Alarmierung eines Einsatzes, „N. NACHALARMIERUNG“ bei jeder
   weiteren (Wert aus `alarmSequenceLabel(...).toUpperCase()`) — Widget-Test mit zwei nacheinander
   ausgelösten `alarm.triggered` für denselben Einsatz.
4. Hintergrundfarbe des Alarmzustands entspricht exakt `BftagAlarmColors.alarm` (Monitor-Variante `#FF5449`)
   — keine andere Rotfläche/kein `Colors.red` im Baum (Grep- + Farbwert-Test).
5. Größtes Textelement (Stichwort) ist ≥ 64 px auch bei langen Stichworten (automatische Skalierung,
   Abschnitt 4) — nie kleiner.
6. Bei Reduced-Motion (`MediaQuery.disableAnimations`) pulsiert das Badge-Icon nicht und der Eintritt erfolgt
   ohne Verzögerung (0 ms) — Widget-Test mit `MediaQueryData(disableAnimations: true)`.
7. Fahrzeugliste im Alarmzustand zeigt bei einer Nachalarmierung **nur** die in dieser Alarmierung neu
   hinzugekommenen Fahrzeuge, nicht die des vorherigen Erstalarms — Widget-Test mit zwei Alarmen
   unterschiedlicher `vehicleIds`-Mengen für denselben Einsatz.
8. Gong (`alarmSoundProvider.play()`) wird weiterhin genau einmal pro `alarm.triggered` aufgerufen,
   unabhängig vom neuen visuellen Zustand — bestehender Test „rings the gong exactly once“ bleibt grün.
9. Trifft ein zweites `alarm.triggered` für denselben Einsatz ein, während der 20-s-Timer noch läuft, startet
   der Timer neu bei 20 s (Fake-Timer-Test: nach 15 s zweites Event, danach muss der Übergang erst bei
   `15+20=35` s Gesamtzeit erfolgen, nicht bei den ursprünglichen 20 s) — Abschnitt 4/5 „Lebenszyklus“.
10. Meldebild-Text im Alarmzustand ist ≥ 40 px, Fahrzeugchip-Name ≥ 56 px (Layout-/Schriftgrößen-Test gegen
    die `TextStyle`-Werte) — Review-Runde 1 Punkt 10.
11. Wird der Einsatz während des laufenden 20-s-Alarmzustands geschlossen (`incident.closed`), bricht der
    Timer sofort ab und der Monitor zeigt sofort `MonitorIncidentScreen` für einen verbleibenden offenen
    Einsatz mit Alarmierung, oder `MonitorStandbyScreen`, falls keiner mehr existiert — Fake-Timer-Test: nach
    5 s von 20 s `incident.closed` auslösen, prüfen, dass bei `candidates.isEmpty` sofort Standby erscheint
    und bei vorhandenem zweiten Kandidaten sofort dessen `MonitorIncidentScreen`, beides **ohne** auf die
    verbleibenden 15 s zu warten — Review-Runde 2 Punkt 1a.
12. Während der 20-s-Alarmzustand läuft, feuert der `_incidentRotationInterval`-Timer (15 s) nicht — Fake-
    Timer-Test: zwei offene Einsätze mit Alarmierung, Alarm für Einsatz A läuft; nach 15 s (während die
    Alarmanzeige für A noch bis 20 s läuft) ist weiterhin A sichtbar, nicht Einsatz B; nach dem automatischen
    Übergang bei 20 s läuft die Rotation normal mit vollen 15 s weiter — Review-Runde 2 Punkt 1c.
13. Die im Alarmzustand gezeigte Fahrzeugliste stammt exakt aus `Alarm.vehicleIds` des auslösenden
    `Alarm`-Objekts (kein zusätzliches/anderes Feld, keine Ableitung aus `Incident`) — Widget-Test, der ein
    `Alarm` mit bekannten `vehicleIds` injiziert und die gerenderten Chip-Keys gegen genau diese Liste prüft
    — Review-Runde 2 Punkt 1d.

## 7. Zu erhaltende Keys + Semantics

Es gibt heute **keine eigene Datei** für den Alarmzustand — der bestehende Key
`Key('monitor-incident-alarm-label')` aus `monitor_incident_screen.dart` ist der einzige vorhandene Anker
für „es ist gerade alarmiert“. Er wandert laut `monitor-einsatz.md` Abschnitt 7 in den ruhigen
Fortschritts-Chip der Einsatzansicht; **für den neuen, lauten Alarmzustand** wird daher ein neuer Satz Keys
benötigt (Vorschlag, vom Coder in `monitor_alarm_screen.dart` zu vergeben):

- `Key('monitor-alarm-badge')` (Erstalarm/Nachalarmierung-Text)
- `Key('monitor-alarm-keyword')`, `Key('monitor-alarm-address')`, `Key('monitor-alarm-report')`
- `Key('monitor-alarm-clock')`, `Key('monitor-alarm-runtime')`
- `Key('monitor-alarm-vehicles')`, je Chip `Key('monitor-alarm-vehicle-${vehicle.id}')`
- `Key('monitor-alarm-ack-progress')`

Bestehende Funktions-Keys aus `alarmSequenceLabel`/`triggeredAlarmsInOrder` (`packages/core/lib/src/domain/
alarm.dart`) werden unverändert wiederverwendet (reine Logik, kein UI-Key).

## 8. Funktionsabgleich vs. `docs/testing/regression-inventory.md`

| Funktion (Inventar, Abschnitt „Alarmzustand“) | Bleibt erhalten als |
|---|---|
| anzeigen (Wechsel Standby → Alarm) | Abschnitt 3+5 — jetzt ein eigener, lauter Zwischenzustand statt direktem Sprung in die ruhige Ansicht |
| Echtzeit-Updates (Alarm kommt per WebSocket) | Abschnitt 5 „Auslöser“ — unverändert dasselbe Event |
| Offline/Verbindungsverlust während Alarm | Abschnitt 4 „Verbindungsverlust während des Alarmzustands“ |

Keine Funktion entfällt. Dies ist die einzige Karte des Pakets mit einer echten **neuen UI-Komponente**
(ein zusätzlicher Zwischenzustand) statt einer reinen Umgestaltung — ausdrücklich begründet in Abschnitt 2
Punkt 1 als das schwerwiegendste gefundene Problem: ein nicht unterscheidbarer Alarm widerspricht der in
diesem Ticket vorgegebenen Anforderung „Alarmzustand … muss aus 10 m unmissverständlich sein“ direkt und
lässt sich nicht durch bloße Farb-/Schriftanpassung der bestehenden Einsatzansicht lösen, ohne diese selbst
während des Normalbetriebs unnötig laut zu machen.
