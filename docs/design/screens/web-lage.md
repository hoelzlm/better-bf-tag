# Admin-Web — Lage

Quelle: `apps/web/lib/screens/lage_screen.dart` (Kind-Widgets `VehicleStatusBar`, `MissedAlarmsSection`,
`ScheduledAlarmsSection`, `RunningIncidentsSection` liegen in `apps/web/lib/widgets/`, sind nicht Teil dieser
Karte — ihr internes Verhalten bleibt unverändert, sie erben nur das neue Theme/die neuen Shared-Widgets).
Vorher: `docs/design/screenshots/before/web/lage-1440x900.png`. Referenz-Mockup bereits vorhanden:
`docs/design/mockups/lage.html`/`.png` (aus ux-02a) — dieses Konzept übernimmt es unverändert als Grundlage
und ergänzt nur die fehlenden Abschnitte/Zustände.

## 1. Zweck

Startseite der Leitstelle (`/admin`) während eines laufenden BF-Tags: auf einen Blick den Status aller
Fahrzeuge (FMS) und laufende Einsätze sehen, nachalarmieren oder einen Einsatz schließen. Höchste
Blickhäufigkeit aller Admin-Screens, oft im Hintergrund offen während andere Screens bearbeitet werden.

## 2. Usability-Probleme heute

1. **Navigation sitzt hier und nirgendwo sonst** (ausführlich in `web-navigation.md` Punkt 1–3) — betrifft
   diesen Screen direkt: die AppBar ist mit 9 Icons + Name + Logout überladen
   (`docs/design/screenshots/before/web/lage-1440x900.png`).
2. **FMS-Status 3 (Einsatz übernommen) ist orange, Status 2 grün ohne System** — Farben kommen aus
   `Colors.orange`/`Colors.green` direkt im Widget, nicht aus festen Tokens (vgl. design-system 2.4). Im
   Screenshot sind die drei Fahrzeugkarten uneinheitlich hoch/breit wirkend und ohne klare Kartenabgrenzung.
3. **Riesige leere Fläche unter dem Einsatz** — bei einem oder zwei Einsätzen bleibt der Rest der 900 px Höhe
   komplett leer (`lage-1440x900.png`, unterhalb y≈470 nur Hintergrundfarbe).
4. **Fahrzeugnamen/Besatzung abgeschnitten**: „Florian screen…“ in allen drei Karten (`lage-1440x900.png`) —
   `crew`-Text hat keinen Tooltip/keine Vollanzeige bei Überlänge.
5. **Quittierungsliste ohne Farbtrennung gegenüber dem restlichen Einsatzkarten-Text** — „ausstehend“ und
   „kein Gerät“ sind nur über den kleinen Punkt davor unterscheidbar, der Punkt selbst ist mit 6–8 px sehr
   klein für schnelles Scannen.

## 3. Neues Layout

Übernimmt `docs/design/mockups/lage.html` 1:1 als Zielbild (siehe PNG dort), eingebettet in die neue Sidebar
aus `web-navigation.md` (ersetzt die AppBar-Actions). Ergänzungen gegenüber dem ux-02a-Mockup:

```
┌──────────┬────────────────────────────────────────────────────────┐
│ Sidebar  │ Lage                                            ● live │
│ (aktiv:  ├────────────────────────────────────────────────────────┤
│  Lage)   │ (Offline-Banner von AdminShell, s. web-navigation.md)  │
│          │ Fahrzeugstatus                                         │
│          │ ┌─────────┐ ┌─────────┐ ┌─────────┐                    │
│          │ │ HLF-1   │ │ RTW-1   │ │ DLK-1   │  FMS-Badge je Karte│
│          │ │ Florian…│ │ Florian…│ │ Florian…│  (Tooltip = voller │
│          │ │  (3)    │ │  (2)    │ │  (2)    │   Besatzungsname)   │
│          │ └─────────┘ └─────────┘ └─────────┘                    │
│          │                                                        │
│          │ ⚠ Verpasste Alarmierungen (nur wenn vorhanden)          │
│          │ ┌────────────────────────────────────────────────────┐│
│          │ │ HLF-1 · verpasst vor 4 min   [Auslösen] [Verwerfen] ││
│          │ └────────────────────────────────────────────────────┘│
│          │                                                        │
│          │ Geplante Alarmierungen (nur wenn vorhanden)             │
│          │ ┌────────────────────────────────────────────────────┐│
│          │ │ RTW-1 · in 02:14   [Jetzt auslösen][Ändern][Verwerf]││
│          │ └────────────────────────────────────────────────────┘│
│          │                                                        │
│          │ Laufender Einsatz                                      │
│          │ ┌────────────────────────────────────────────────────┐│
│          │ │ [ERSTALARM] #1 B3 Großbrand … · seit 0 min          ││
│          │ │ [Nachalarmieren] [Einsatz schließen]                 ││
│          │ │ 0 quittiert · 1 ausstehend · 2 kein Gerät            ││
│          │ │ • Anna Jugend – HLF-1, GF (ausstehend)               ││
│          │ └────────────────────────────────────────────────────┘│
│          │                                                        │
│          │ (bei keinem Einsatz: Leerzustand statt leerer Fläche)  │
└──────────┴────────────────────────────────────────────────────────┘
```

Reihenfolge der vier Abschnitte (`VehicleStatusBar` → `MissedAlarmsSection` → `ScheduledAlarmsSection` →
`RunningIncidentsSection`, identisch zu `lage_screen.dart:131-134`) bleibt unverändert — diese Karte ändert
nur Theme/Farben/Flächen der drei Kind-Widgets, nicht ihre Reihenfolge oder Logik. „Verpasste Alarmierungen“
(`MissedAlarmsSection`) und „Geplante Alarmierungen“ (`ScheduledAlarmsSection`) rendern beide **nichts**
(`SizedBox.shrink()`), solange ihre jeweilige Liste leer ist (`missedAlarmsProvider`/
`nextPlannedAlarmsProvider`, unverändert in `missed_alarms_section.dart:17-18` und
`scheduled_alarms_section.dart:37-38`) — kein Platzhalter, kein leerer Rahmen, identisch zu heute.
„Verpasste Alarmierungen“ bekommt eine `alarm`-nahe, aber nicht identische Warnfläche (`Colors.red`-Ton,
bereits heute hart kodiert in `missed_alarms_section.dart:36-37` — diese Karte ersetzt das durch
design-system-Token, siehe Abschnitt 2 Zustände, bleibt aber visuell als „dringende Warnung“ erkennbar, da
eine verpasste Alarmierung tatsächlich ein ausgelassener Alarm ist). „Geplante Alarmierungen“ bekommt eine
neutrale `Card` (design-system 5.4), keine Warnfarbe — es ist noch nichts schiefgelaufen, nur eine
Vorschau.

Fahrzeugkarten: `Card` (design-system 5.4), FMS-Badge aus festen Tokens (fms1–fms8, 2.4), Fahrzeugname
`titleMedium`, Besatzung `bodyMedium`/`onSurfaceVariant` mit `Tooltip` bei Abschneidung (`TextOverflow.ellipsis`
+ `Tooltip(message: crewFullText)`). Einsatzkarte: `alarmContainer`-Fläche (Erstalarm/Nachalarmierung sind
„Alarm im Gange“, passt zu Grundprinzip 1), Badge „ERSTALARM“/„NACHALARMIERT“ in `alarm`/`onAlarm` (design-
system 5.11). Button „Nachalarmieren“ = Alarm-Button (`alarm`-Fläche, design-system 5.1), „Einsatz schließen“ =
Sekundärbutton. Quittierungszeilen: farbiger Punkt ersetzt/ergänzt durch kleines Status-Icon (z. B. `schedule`
für „ausstehend“, `phonelink_off` für „kein Gerät“, `check_circle` in `primary` für „quittiert“) — Farbe ist
nie alleiniger Träger (design-system 8).

## 4. Alle Zustände

- **Laden:** `VehicleStatusBar`/`RunningIncidentsSection` zeigen ihren eigenen Ladezustand (Kind-Widget,
  außerhalb dieser Karte) — Platzhalter: Skeleton-Fahrzeugkarten (design-system 5.10), kein Vollbild-Spinner,
  da Sidebar und Titel sofort sichtbar bleiben.
- **Keine verpassten Alarmierungen:** `MissedAlarmsSection` rendert `SizedBox.shrink()` (unverändert,
  `missed_alarms_section.dart:17-18`) — der Abschnitt nimmt dann keinen Platz ein, kein leerer Rahmen.
- **Verpasste Alarmierungen vorhanden:** Warnfläche mit Titel „Verpasste Alarmierungen“ + einer Zeile je
  verpasster Alarmierung, „Auslösen“/„Verwerfen“ nur für Leitstelle/Administrator (Einsatzvorbereitung sieht
  die Liste nur lesend, unverändert `missed_alarms_section.dart:28-29`).
- **Keine geplanten Alarmierungen:** `ScheduledAlarmsSection` rendert `SizedBox.shrink()` (unverändert,
  `scheduled_alarms_section.dart:37-38`).
- **Geplante Alarmierungen vorhanden:** Card mit Titel „Geplante Alarmierungen“ + einer Zeile je geplanter
  Alarmierung mit tickendem Countdown (`formatCountdown`, sekündlich über `monitorClockProvider`,
  unverändert), „Jetzt auslösen“/„Ändern“/„Verwerfen“ nur für Leitstelle/Administrator.
- **Kein laufender Einsatz:** Abschnitt „Laufender Einsatz“ entfällt oder zeigt Leerzustand „Kein laufender
  Einsatz“ (Icon + Kurztext, design-system 5.10) statt der leeren Fläche aus Problem 3 — delegiert an
  `RunningIncidentsSection`, hier nur die visuelle Behandlung festgelegt.
- **Mehrere laufende Einsätze:** Einsatzkarten stapeln sich vertikal mit `xl`-Abstand (24 px), jede in voller
  Breite — kein horizontales Scrollen.
- **Sehr lange Fahrzeug-/Besatzungsnamen:** `TextOverflow.ellipsis` + Tooltip (Punkt 4 oben); Kartenbreite
  bleibt fix (180 px wie im Mockup), kein Umbruch, der die Kartenreihe verzerrt.
- **Fehler beim Laden (Fahrzeuge/Einsätze):** vom Kind-Widget verantwortet, hier nur Platzierung: Fehlertext
  ersetzt den jeweiligen Abschnitt, Rest der Seite (Sidebar, Titel) bleibt bedienbar.
- **Offline/Reconnecting:** Kein eigener Zustand mehr auf dieser Karte — das gemeinsame
  `connection-banner` der `AdminShell` übernimmt diese Anzeige für alle `/admin/*`-Screens einheitlich (siehe
  `web-navigation.md` Abschnitt 4/6 AK 12). Auf der Lage bleibt zusätzlich der heutige, unveränderte kleine
  `connection-indicator`-Text/-Punkt von `VehicleStatusBar` bestehen (eigenes Kind-Widget, nicht Teil dieser
  Karte) — beide Anzeigen nutzen denselben `realtimeConnectionProvider`, sind aber unabhängige Widgets auf
  unterschiedlichen Ebenen (Shell vs. Fahrzeugstatus-Leiste); das ist kein neuer Verbindungsmechanismus,
  nur eine zusätzliche Anzeigeebene.
- **Ohne Berechtigung:** entfällt (Lage ist für alle angemeldeten Personen sichtbar, nur die Sidebar-Einträge
  variieren, s. `web-navigation.md`).

## 5. Interaktionen

- „Nachalarmieren“ öffnet denselben Bestätigungsdialog wie heute (unverändert, nur neu eingefärbt als
  Alarm-Button); „Einsatz schließen“ unverändert.
- Fahrzeugkarten sind nicht interaktiv (reine Statusanzeige) — kein neues Klickziel.
- Tab-Reihenfolge: Sidebar zuerst (s. `web-navigation.md`), dann Content von oben nach unten
  (Fahrzeugkarten → Einsatzkarten-Aktionen).
- Live-Indikator hat keinen eigenen Fokus/Klick (reiner Statuspunkt).

## 6. Testbare Akzeptanzkriterien

1. Die Lage-Seite rendert innerhalb der gemeinsamen Sidebar (aktiver Eintrag „Lage“), keine eigene AppBar mit
   Navigations-Icons mehr.
2. `nav-einsaetze` usw. sind nicht mehr Kinder von `LageScreen`s `AppBar` — sie existieren als Sidebar-Items
   (siehe `web-navigation.md` Akzeptanzkriterium 6), aber Navigation von Lage zu jedem Zielscreen funktioniert
   weiterhin identisch (Ziel-Route, Berechtigungs-Sichtbarkeit).
3. FMS-Badges verwenden die Tokenfarben aus design-system 2.4 (fms1…fms8), nicht `Colors.orange`/`Colors.green`
   direkt.
4. Bei keinem laufenden Einsatz zeigt der Bereich einen Leerzustand (Icon + Text), keine leere Fläche.
5. Ein Fahrzeugname/eine Besatzung, die abgeschnitten wird, zeigt bei Hover/Fokus den vollen Text (Tooltip).
6. Der bestehende Test „shows the signed-in person and Berechtigung“ (`lage_screen_test.dart`) bleibt grün —
   Name/Berechtigung sind jetzt in der Sidebar-Fußzeile statt im AppBar-Text sichtbar, aber weiterhin als Text
   auffindbar.
7. `missed-alarms-section` rendert genau dann, wenn `missedAlarmsProvider` nicht leer ist, direkt unterhalb
   von `vehicle-status-bar` und oberhalb von `scheduled-alarms-section` (Reihenfolge wie
   `lage_screen.dart:131-134`); analog `scheduled-alarms-section` für `nextPlannedAlarmsProvider`.
8. `missed-alarm-trigger-{id}`/`missed-alarm-discard-{id}` und
   `scheduled-alarm-trigger-{id}`/`scheduled-alarm-change-{id}`/`scheduled-alarm-discard-{id}` sind nur für
   Leitstelle/Administrator vorhanden (unverändert); Einsatzvorbereitung sieht beide Listen nur lesend.
9. Ein `scheduled-alarm-countdown-{id}` zeigt einen Text, der sich innerhalb von 2 Sekunden sichtbar ändert
   (sekündliches Tick, unverändert über `monitorClockProvider`).

## 7. Zu erhaltende Keys + Semantics labels

`lage_screen.dart` selbst hat außer den Navigations-Keys (die nach `web-navigation.md` in die Sidebar
wandern, siehe dort Abschnitt 7) keine eigenen interaktiven `Key`s. Die eigentlichen Funktionen der Lage
stecken in den vier Kind-Widgets aus `apps/web/lib/widgets/`, die diese Karte zwar nicht code-seitig anfasst,
deren Keys aber laut Architekt-Review hier aufgeführt werden, da sie die Funktionen dieser Seite darstellen
(der Coder dieser Karte baut die Widgets um, muss aber alle folgenden Keys/Tooltips unverändert erhalten):

- `vehicle_status_bar.dart`: `connection-indicator`, `vehicle-status-bar`, `status-option-{status.code}`,
  `vehicle-tile-{vehicle.id}`.
- `missed_alarms_section.dart`: `missed-alarms-section`, `missed-alarm-{sa.alarm.id}`,
  `missed-alarm-trigger-{alarm.id}`, `missed-alarm-discard-{alarm.id}`.
- `scheduled_alarms_section.dart`: `scheduled-alarms-section`, `scheduled-alarm-{sa.alarm.id}`,
  `scheduled-alarm-countdown-{alarm.id}`, `scheduled-alarm-trigger-{alarm.id}`,
  `scheduled-alarm-change-{alarm.id}`, `scheduled-alarm-discard-{alarm.id}`, sowie im „Ändern“-Dialog
  `change-alarm-vehicle-{vehicle.id}`, `change-alarm-offset-minutes`, `change-alarm-pick-date`,
  `change-alarm-pick-time`, `change-alarm-submit`.
- `running_incidents_section.dart`: `running-incidents-section`, `running-incident-{incident.id}`,
  `close-incident-confirm`, `incident-elapsed-{incident.id}`, `close-suggested-{incident.id}`,
  `nachalarmieren-incident-{incident.id}`, `close-incident-{incident.id}`, `alarm-label-{alarm.id}`,
  `alarm-summary-{alarm.id}`, `alarm-push-summary-{alarm.id}`, `alarm-recipient-{recipient.personId}`,
  `ack-icon-{recipient.personId}`.
- `alarm_dialog.dart` (Nachalarmieren-Dialog): `alarm-vehicle-{vehicle.id}`,
  `alarm-double-crewed-warning`, `alarm-double-crewed-{d.personId}`, `alarm-mode-immediate`,
  `alarm-mode-scheduled`, `alarm-mode-relative`, `alarm-pick-date`, `alarm-pick-time`,
  `alarm-offset-minutes`, `alarm-dialog-submit`.
- `confirm_dialog.dart`: `confirm-dialog-confirm` (Standard-Bestätigungs-Key, von mehreren Dialogen auf
  dieser Seite genutzt, z. B. „Einsatz schließen“).

Icons `check_circle`/`more_horiz`/`remove_circle_outline` (Quittierungsstatus in `running_incidents_section`)
bleiben exakt erhalten (von `running_incidents_section_test.dart` per `find.byIcon` geprüft, s. auch
`web-navigation.md` Abschnitt 3).

## 8. Flows

Keine funktionale Flow-Änderung gegenüber heute (Nachalarmieren/Einsatz schließen/Fahrzeugstatus-Anzeige/
Verpasste und geplante Alarmierungen bleiben exakt wie heute, inkl. Reihenfolge der vier Abschnitte) — die
einzige strukturelle Änderung (Navigation raus aus dem Screen) ist in `web-navigation.md` Abschnitt 8
begründet und gilt für alle Admin-Screens gemeinsam, nicht nur für Lage.

## 9. Zuordnung zum Regressionsinventar

Tabelle „Lage“ (`docs/testing/regression-inventory.md`, Abschnitt „### Lage (`lage_screen.dart`)“):

| Funktion (Inventar) | Test | Ort im neuen Layout |
|---|---|---|
| anzeigen | `lage_screen_test.dart`: shows the signed-in person and Berechtigung | Sidebar-Fußzeile (Abschnitt 3/6 AK 6), nicht mehr AppBar-Text. |
| anlegen/bearbeiten/löschen | n/a | n/a |
| Navigation | `router_test.dart` (Fahrzeuge/BF-Tage/Schichten/Durchsagen/Tagesablauf) + `lage_screen_test.dart` (Einsätze/Monitore/Folien/Personen, Berechtigungs-Ausblendung) | Sidebar-Items statt AppBar-Icons, identische Zielrouten/Sichtbarkeit (s. `web-navigation.md`). |
| Echtzeit-Updates/Fehlerzustand/Leerzustand/Offline | an Kind-Widgets delegiert (z. B. `VehicleStatusBar`), dort abgedeckt | Fahrzeugstatus (`VehicleStatusBar`), Verpasste/Geplante Alarmierungen (`MissedAlarmsSection`/`ScheduledAlarmsSection`) und Laufende Einsätze (`RunningIncidentsSection`) in der Reihenfolge aus Abschnitt 3; Offline zusätzlich als gemeinsames `connection-banner` der `AdminShell` (Abschnitt 4). |
