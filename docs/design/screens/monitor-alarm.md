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
│   onAlarm-auf-alarm-Pille, monitorHeadline 40 Name + monitorLabel 22 „alarmiert“│
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
darunter, dann Meldebild (max. 3 Zeilen, danach Kürzung mit „…“ — in diesem Zustand ist nur das Nötigste
wichtig, der vollständige Text ist ohnehin in `monitor-einsatz.md` nach dem Übergang zu sehen).

Fahrzeugchips: Fahrzeugname (`monitorHeadline` 40) + Label „alarmiert“ (`monitorLabel` 22) auf
`onAlarm`-bei-16%-Fläche-Pille (dunkler Ton auf hellem Alarmrot, wie im bestehenden Mockup) — bewusst
**keine FMS-Pille** hier (die Fahrzeuge haben in diesem Moment typischerweise noch FMS 3 „Einsatz
übernommen“ oder sind mitten im Statuswechsel; die FMS-Farbpalette hier einzublenden würde zwei Farbsysteme
auf einer Fläche mischen und die Lesbarkeit aus 10 m verschlechtern) — FMS-Status erscheint erst wieder in
der ruhigeren Einsatzansicht.

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
- **Verbindungsverlust während des Alarmzustands:** schmale `surfaceVariant`/„cloud_off“-Leiste oben
  (32 px, dieselbe wie in den anderen Monitor-Screens) — erscheint **über** der Alarmfläche, verdrängt
  nichts von Stichwort/Adresse (die beginnen entsprechend 32 px tiefer). Der Alarm bleibt trotz
  Verbindungsproblem vollständig sichtbar — anders als bei Standby/Einsatzansicht hat ein Verbindungsproblem
  hier keine Priorität vor der Alarmdarstellung selbst.
- **Alarm läuft ab, während bereits ein anderer Alarmzustand gezeigt wird** (zweiter, unabhängiger Einsatz
  wird mitten im ersten Alarmzustand ausgelöst): der neue Alarm ersetzt sofort den alten (gleiches
  Verhalten wie heute bei `_shownIncidentId`-Überschreibung durch `liveAlarmTriggeredProvider`), der alte
  Einsatz ist weiterhin über die normale Rotation der Einsatzansicht erreichbar, verliert aber keine Daten.

## 5. Interaktionen/Übergänge

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
  **nicht** erneut ausgelöst, nur durch ein echtes neues `alarm.triggered`-Event.

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
