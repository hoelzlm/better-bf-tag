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
│  Lage)   │ Fahrzeugstatus                                         │
│          │ ┌─────────┐ ┌─────────┐ ┌─────────┐                    │
│          │ │ HLF-1   │ │ RTW-1   │ │ DLK-1   │  FMS-Badge je Karte│
│          │ │ Florian…│ │ Florian…│ │ Florian…│  (Tooltip = voller │
│          │ │  (3)    │ │  (2)    │ │  (2)    │   Besatzungsname)   │
│          │ └─────────┘ └─────────┘ └─────────┘                    │
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
- **Kein laufender Einsatz:** Abschnitt „Laufender Einsatz“ entfällt oder zeigt Leerzustand „Kein laufender
  Einsatz“ (Icon + Kurztext, design-system 5.10) statt der leeren Fläche aus Problem 3 — delegiert an
  `RunningIncidentsSection`, hier nur die visuelle Behandlung festgelegt.
- **Mehrere laufende Einsätze:** Einsatzkarten stapeln sich vertikal mit `xl`-Abstand (24 px), jede in voller
  Breite — kein horizontales Scrollen.
- **Sehr lange Fahrzeug-/Besatzungsnamen:** `TextOverflow.ellipsis` + Tooltip (Punkt 4 oben); Kartenbreite
  bleibt fix (180 px wie im Mockup), kein Umbruch, der die Kartenreihe verzerrt.
- **Fehler beim Laden (Fahrzeuge/Einsätze):** vom Kind-Widget verantwortet, hier nur Platzierung: Fehlertext
  ersetzt den jeweiligen Abschnitt, Rest der Seite (Sidebar, Titel) bleibt bedienbar.
- **Offline/Reconnecting:** schmales Banner direkt unter dem Topbar-Titel, volle Content-Breite,
  `surfaceVariant`-Fläche, Icon `cloud_off`, Text „Verbindung verloren — verbinde erneut …“ (design-system
  5.10) — ersetzt nicht die Sidebar, nur den Live-Punkt im Topbar wechselt von grün auf `onSurfaceVariant`.
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

## 7. Zu erhaltende Keys + Semantics labels

Keine eigenen interaktiven `Key`s in `lage_screen.dart` außer den Navigations-Keys (die nach
`web-navigation.md` in die Sidebar wandern — siehe dort Abschnitt 7). Keys der Kind-Widgets
(`VehicleStatusBar`, `RunningIncidentsSection` usw.) sind nicht Teil dieser Datei und bleiben unverändert, da
diese Karte ihren Code nicht anfasst — nur das Theme/die Shared-Components, die sie konsumieren, ändern sich.

## 8. Flows

Keine funktionale Flow-Änderung gegenüber heute (Nachalarmieren/Einsatz schließen/Fahrzeugstatus-Anzeige
bleiben exakt wie heute) — die einzige strukturelle Änderung (Navigation raus aus dem Screen) ist in
`web-navigation.md` Abschnitt 8 begründet und gilt für alle Admin-Screens gemeinsam, nicht nur für Lage.
