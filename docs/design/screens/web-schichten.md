# Admin-Web — Schichten

Quelle: `apps/web/lib/screens/shifts_screen.dart`. Vorher:
`docs/design/screenshots/before/web/schichten-1440x900.png`. Größter/komplexester Screen in dieser Karte —
rendertes Mockup: `docs/design/mockups/web-schichten.html` / `.png` (1440×900, zeigt auch die Sidebar aus
`web-navigation.md`).

## 1. Zweck

Leitstelle/Administrator teilen vor und während des BF-Tags Personen auf Fahrzeuge und Funktionen ein (ADR
0013), per Drag & Drop. Wird auch kurzfristig während eines laufenden BF-Tags geändert (Schichtwechsel,
Krankmeldung) — Klarheit über „wer ist wo eingeteilt“ und „wer fehlt noch“ ist entscheidend, Fehlbedienung
(falsches Fahrzeug) muss durch klare Drop-Zonen unwahrscheinlich sein.

## 2. Usability-Probleme heute

1. **Dropdown und Tabs ohne visuelle Fläche** — `docs/design/screenshots/before/web/schichten-1440x900.png`:
   das BF-Tag-Dropdown ist eine reine Unterstrichlinie, „Schicht 1 (aktuell)“ ein dünner Outline-Chip kaum
   unterscheidbar vom unausgewählten „Schicht 1“.
2. **Fahrzeugkarten sind reine graue 1 px-Rahmen-Boxen** ohne erkennbare Kartenfläche, Titel/Inhalt ohne
   Innenabstand-Konsistenz (Screenshot: HLF-1/RTW-1/DLK-1-Boxen wirken wie Platzhalter, nicht wie ein fertiges
   Zuteilungs-Board).
3. **Drop-Ziel-Hervorhebung nutzt hartcodiertes `Colors.blue`** (`shifts_screen.dart:672`) statt eines
   Theme-Tokens — inkonsistent mit jeder anderen Fokus-/Auswahlfarbe im Produkt.
4. **Doppelt eingeteilte Person nur über ein kleines oranges Warn-Icon markiert** (`Colors.orange`,
   `shifts_screen.dart:586,728`) — Tooltip zeigt den Grund, aber ohne Hover ist nicht ersichtlich, *warum* die
   Chip anders aussieht.
5. **„Nicht eingeteilt“-Chips grau eingefärbt** (`Colors.grey.shade300`, Zeile 589) ohne Bezug zum
   Theme — wirkt wie „deaktiviert“, dabei ist es die wichtigste Handlungsgruppe (wer muss noch eingeteilt
   werden).
6. **Riesige leere Fläche rechts/unten**, sobald wenige Fahrzeuge vorhanden sind (Screenshot: DLK-1-Karte endet
   bei x≈975, der Rest bis 1440 bleibt leer) — Board skaliert nicht mit, wirkt unfertig.
7. **Keine Navigation außer dem Titel** (siehe `web-navigation.md`).

## 3. Neues Layout

Rendertes Mockup: `docs/design/mockups/web-schichten.html`/`.png`.

```
┌──────────┬───────────────────────────────────────────────────────────────┐
│ Sidebar  │ Schichten                                                      │
│ (aktiv:  ├───────────────────────────────────────────────────────────────┤
│Schichten)│ BF-Tag: [Screenshots screenshots ▾]                            │
│          │                                                                 │
│          │ [Schicht 1]  [● Schicht 1 (aktuell)]        [+ Schicht]  ✏ 🗑  │
│          │ ───────────────────────────────────────────────────────────── │
│          │ Nicht eingeteilt        │ HLF-1          RTW-1        DLK-1    │
│          │  ┌───────────────┐      │ ┌─────────┐   ┌─────────┐  ┌───────┐│
│          │  │ Leitstelle    │      │ │GF Anna  ⋮│   │MA Clara⋮│  │  –    ││
│          │  │ Vorbereitung  │      │ │MA Ben   ⋮│   └─────────┘  └───────┘│
│          │  └───────────────┘      │ └─────────┘                          │
│          │ Eingeteilt               │                                     │
│          │  (leer, weil alle unten)│                                      │
└──────────┴───────────────────────────────────────────────────────────────┘
```

BF-Tag-Dropdown: `InputDecorationTheme`-Dropdown mit `outline`-Rahmen statt reiner Unterstrich-Linie
(design-system 5.2). Schicht-Tabs: `ChoiceChip` mit `primaryContainer`/`primary`-Fläche für die Auswahl
(design-system 5.3 Selektion). Fahrzeugkarten: `Card`-Komponente (design-system 5.4,
`surfaceVariant`/`radiusLarge`/`xl`-Padding), Titel `titleMedium`, Crew-Chips darunter. Drop-Ziel-Hervorhebung:
2 px `primary`-Rahmen statt `Colors.blue` (design-system 8, konsistent mit Fokus-Farbe). Doppelt-eingeteilt-
Warnung: Chip erhält zusätzlich einen 1 px `warning`-Rahmen (nicht nur das Icon), Icon-Farbe `warning` statt
`Colors.orange` — Grund ist ein Zuteilungs-Konflikt, kein Formularfehler, aber auch kein Alarm (Grundprinzip 1:
nur echter Alarm ist rot). „Nicht eingeteilt“-Chips: `surfaceVariant`-Fläche mit `outline`-Rahmen (neutral,
nicht „grau = deaktiviert“), „Eingeteilt“ bereits zugeordnete Personen weiterhin als Referenzliste sichtbar
(heutiges Verhalten: Chips erscheinen in beiden Spalten dort, wo zutreffend — unverändert). Fahrzeugkarten in
einem responsiven `Wrap` (wie heute, `vehicle-cards`-Key), aber mit fester Mindestbreite 220 px und `lg`-Gap
(16 px), sodass sie bei vielen Fahrzeugen in mehrere Zeilen umbrechen statt eine riesige Leerfläche zu lassen;
bei wenigen Fahrzeugen bleibt die Breite wie heute (kein künstliches Strecken einzelner Karten, das würde die
Drop-Zonen unübersichtlich groß machen).

## 4. Alle Zustände

- **Laden (BF-Tage):** Skeleton statt Vollbild-Spinner im Inhaltsbereich, Sidebar bleibt interaktiv.
- **Keine BF-Tage:** zentrierter Leerzustand „Keine BF-Tage angelegt.“ (design-system 5.10) statt reinem Text.
- **BF-Tag ausgewählt, Schichten laden:** `Expanded`-Bereich zeigt Spinner (wie heute, `_shifts == null`),
  Dropdown/Tabs-Zeile bleibt oben sichtbar.
- **Keine Schicht vorhanden:** Leerzustand „Keine Schicht vorhanden.“ im Board-Bereich (wie heute, visuell
  nach 5.10 aufgewertet) + bei `!dayEnded` weiterhin aktiver „Schicht anlegen“-Button sichtbar.
- **BF-Tag beendet (`dayEnded`):** „Schicht anlegen“/„bearbeiten“/„löschen“ deaktiviert mit Tooltip „BF-Tag ist
  beendet“ (unverändert aus `shifts_screen.dart:474-498`), visuell: Button-Disabled-Stil (38 % Opazität,
  design-system 5.1).
- **Drag über eine Drop-Zone:** 2 px `primary`-Rahmen um die Zielkarte (`candidateData.isNotEmpty`,
  unverändert in der Logik, nur die Farbe wechselt von `Colors.blue` zu `primary`).
- **Doppelt eingeteilte Person:** Chip mit `warning`-Icon + `warning`-Rahmen, Tooltip „auch auf …“ unverändert.
- **Fehler beim Setzen der Besatzung (409 o. ä.):** SnackBar mit Fehlermeldung, unverändert (bestehender Test
  „a 409 error from setCrew shows a SnackBar“).
- **Echtzeit-Update (ein `shiftsProvider`-Event):** Board aktualisiert sich automatisch (`_reloadSelectedDay`),
  unverändert.
- **Offline/Verbindung verloren:** Kein eigener Zustand auf dieser Karte — das gemeinsame `connection-banner`
  der `AdminShell` zeigt den Verbindungsverlust einheitlich für alle `/admin/*`-Screens (s. `web-navigation.md`
  Abschnitt 4/6 AK 12). Schichten haben kein eigenes Realtime-Abo für Drag & Drop selbst (`shiftsProvider`
  liefert nur Reload-Trigger, s. o.); während das Banner sichtbar ist, scheitert Drag & Drop/Dialoge bei
  fehlender Verbindung weiterhin über die bestehende SnackBar-Fehlerbehandlung (unverändert).
- **Dialoge:** Schicht anlegen/bearbeiten (Name, Start, Ende) und Funktion wählen (Chips + Freitext) nach
  design-system 5.6; Funktion-Chips (`standardCrewFunctions`) als `ActionChip`-Grid.
- **Validierungsfehler:** Funktion-Freitextfeld hat `maxLength: 16` (unverändert, zeigt Flutters
  Standard-Zähler); kein zusätzlicher Fehlerzustand nötig, da leere Eingabe einfach nichts submitted
  (`_submit`-Guard Zeile 913, unverändert).

## 5. Interaktionen

- Drag & Drop unverändert: `Draggable`/`DragTarget` aus Teilnehmer-Chips oder bestehenden Crew-Einträgen auf
  Fahrzeugkarten, danach Funktionsauswahl-Dialog (`_pickFunction`).
- `crew-menu-{vehicleId}-{personId}` (⋮-Menü) bietet weiterhin „Funktion ändern“/„entfernen“.
- Tab-Reihenfolge: Sidebar → BF-Tag-Dropdown → Schicht-Tabs → Schicht-anlegen/bearbeiten/löschen-Icons →
  Teilnehmer-Spalte → Fahrzeugkarten (Drag-Ziele sind nicht tastaturbedienbar — das ist eine **bestehende**
  Einschränkung, kein neues Problem dieser Karte; die Funktion „entfernen“/„Funktion ändern“ im ⋮-Menü bleibt
  der tastaturzugängliche Weg, Personen umzuteilen, ohne zu ziehen).
- Schicht-Wechsel per Klick auf Tab (`_selectShift`) unverändert, keine Tastatur-Pfeilnavigation nötig (Chips
  sind einzeln fokussierbar/aktivierbar).

## 6. Testbare Akzeptanzkriterien

1. `bf-day-dropdown`, `shift-tabs`, `shift-tab-{id}`, `create-shift`, `edit-shift`, `delete-shift`,
   `vehicle-cards`, `vehicle-dropzone-{id}`, `vehicle-card-{id}`, `unassigned-participants`,
   `assigned-participants` funktionieren identisch zu `shifts_screen_test.dart`.
2. Die Drop-Ziel-Hervorhebung einer Fahrzeugkarte während eines Drags verwendet `ColorScheme.primary`
   (per Theme-Lookup, kein hartcodiertes `Colors.blue`).
3. Eine doppelt eingeteilte Person zeigt sowohl das Warn-Icon als auch einen sichtbaren Rahmen in
   `warning`-Farbe auf ihrer Chip in **beiden** betroffenen Fahrzeugkarten.
4. Bei `dayEnded == true` sind `create-shift`, `edit-shift`, `delete-shift` deaktiviert (`onPressed: null`),
   Tooltip-Text enthält „beendet“.
5. Ohne Schichten zeigt das Board einen Text, der „Keine Schicht“ enthält.
6. Ohne BF-Tage zeigt der Screen einen Text, der „Keine BF-Tage“ enthält.
7. `crew-entry-{vehicleId}-{personId}` und `crew-menu-{vehicleId}-{personId}` bleiben für jede eingeteilte
   Person vorhanden und öffnen „Funktion ändern“/„entfernen“ wie bisher.
8. Ein `shiftsProvider`-Event während die Seite offen ist, aktualisiert sichtbar die Fahrzeugkarten, ohne dass
   die Auswahl (BF-Tag/Schicht) zurückgesetzt wird.

## 7. Zu erhaltende Keys + Semantics labels

Aus `shifts_screen.dart` (`grep -n "Key("`): `confirm-dialog-confirm`, `bf-day-dropdown`, `shift-tabs`,
`shift-tab-{s.id}`, `create-shift`, `edit-shift`, `delete-shift`, `vehicle-cards`, `vehicle-dropzone-{vehicle.id}`,
`vehicle-card-{vehicle.id}`, `unassigned-participants`, `assigned-participants`,
`participant-draggable-{p.personId}`, `crew-entry-{assignment.vehicleId}-{assignment.personId}`,
`crew-menu-{assignment.vehicleId}-{assignment.personId}`, `shift-form-name`, `shift-form-start`,
`shift-form-end`, `shift-form-submit`, `function-btn-{f}`, `function-freetext`, `function-submit`. Tooltips:
„BF-Tag ist beendet“/„Schicht bearbeiten“ auf `edit-shift`, „BF-Tag ist beendet“/„Schicht löschen“ auf
`delete-shift` — Text bleibt exakt erhalten.

## 8. Flows

Keine funktionale Flow-Änderung. Alle Interaktionen (Drag & Drop, Funktionswahl, Schicht-CRUD,
Teilnehmer-Zuordnung) bleiben exakt erhalten — ausschließlich Farben/Flächen/Abstände werden auf das
Designsystem umgestellt, um die in Abschnitt 2 beschriebenen Lesbarkeits-/Konsistenzprobleme zu beheben.

## 9. Zuordnung zum Regressionsinventar

Tabelle „Schichten“ (`docs/testing/regression-inventory.md`, Abschnitt „### Schichten (`shifts_screen.dart`)“):

| Funktion (Inventar) | Test | Ort im neuen Layout |
|---|---|---|
| anzeigen | `shifts_screen_test.dart`: renders shifts as tabs and crew per vehicle | BF-Tag-Dropdown + Schicht-Tabs + Fahrzeugkarten-Board (Abschnitt 3), gleiche Keys. |
| anlegen | `shifts_screen_test.dart`: create shift dialog calls createShift | `create-shift`-Button in der Tabs-Zeile (Abschnitt 3), Dialog unverändert. |
| bearbeiten | `shifts_screen_test.dart`: edit-shift calls updateShift with the new values | `edit-shift`-Icon neben den Tabs, Dialog unverändert. |
| löschen | `shifts_screen_test.dart`: delete-shift calls deleteShift only after confirm (+ Abbrechen) | `delete-shift`-Icon neben den Tabs, Bestätigungsdialog unverändert. |
| Navigation | n/a (BF-Tag/Schicht-Auswahl ist Teil des Screens) | n/a |
| Echtzeit-Updates | `shifts_screen_test.dart`: a shiftsProvider event reloads the shift list | Board aktualisiert sich automatisch (Abschnitt 4 „Echtzeit-Update“), unverändert. |
| Fehlerzustand | `shifts_screen_test.dart`: a 409 error from setCrew shows a SnackBar | SnackBar unverändert (Abschnitt 4). |
| Leerzustand | `shifts_screen_test.dart`: no shifts / no BF-Tage zeigt Meldung | Leerzustände „Keine BF-Tage“/„Keine Schicht vorhanden“ (Abschnitt 4), visuell nach 5.10 aufgewertet. |
| Offline | n/a (keine eigene UI) | Jetzt zusätzlich abgedeckt durch das gemeinsame `connection-banner` der `AdminShell` (Abschnitt 4), keine neue Schichten-spezifische Funktion. |
