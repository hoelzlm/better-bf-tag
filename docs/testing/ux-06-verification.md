# ux-06 Tester-Verifikation — Admin-Web Betrieb (Einsätze, Durchsagen, Tagesablauf, Folien, Monitore)

Verifiziert auf `main` nach Merge von `t_f44b5931` (Einsätze), `t_3a658038` (Durchsagen+Tagesablauf),
`t_e5e4245f` (Folien+Monitore) — Commit `de2619c`. Alle drei Branches waren bereits via `--no-ff` auf `main`
gemerged; dieses Worktree stand bereits auf `main` (kein weiterer Merge nötig).

## 1. Ergebnis

- `just test` (Backend, nach `npm ci`): **336/336 grün**.
- `dart analyze packages/api_client` + `flutter analyze apps/web apps/mobile packages/core`: **keine Findings**.
- `flutter test` `packages/core`: **268/268 grün**. `apps/web`: **268/268 grün**. `apps/mobile`: **87/87 grün**.
- `just e2e`: **API 142/142, UI 48/48 grün**, inkl. kritischer Pfad Einsatz anlegen → Enter →
  AlarmDialog → Fahrzeug wählen → Jetzt alarmieren → Filter-Automatik verifiziert (AC15–AC19).
- `just screenshots after`: 40 Screenshots neu erzeugt (web, monitor), Docker-Stack sauber heruntergefahren.
- Keine hartcodierten Farben (`Color(0x…)`/`Colors.*`) in den fünf berührten Screens/`alarm_dialog.dart` außer
  dem vorbestehenden `Colors.transparent`-Material-Wrapper-Pattern (`incidents_screen.dart:564`,
  bereits vom Reviewer akzeptiert) und `alarmColors.*`-Zugriffen auf das Theme-Token `BftagAlarmColors`
  (kein Hardcoding, korrekte Token-Nutzung nach Designsystem 5.1).
- Keine Tests gelöscht: Testanzahl je Datei ist gegenüber `d7e1bfb` (vor ux-06) überall gestiegen
  (announcements 9→12, incidents 20→29, monitors 6→10, program 10→11, slides 13→21).
- Alle in §7 der fünf Konzeptdokumente gelisteten Keys/Semantics-Labels per grep im Code bestätigt (siehe §3).

**Keine Bugs gefunden. Karte wird mit `kanban_complete` abgeschlossen.**

## 2. AC-Abdeckungstabelle

### web-einsaetze.md (22 ACs + §3.4 kritischer Pfad)

| AC | Test |
|---|---|
| 1 Filter zeigt nur gewählten Zustand | `incidents_screen_test.dart` AC1 |
| 2 Einsatz anlegen nur mit BF-Tag/nicht beendet | `incidents_screen_test.dart` (dialog gating tests) |
| 3 Speichern ruft create() mit Feldern | `incidents_screen_test.dart` AC3 |
| 4 Klick auf Karte öffnet Bearbeiten vorausgefüllt | `incidents_screen_test.dart` (edit dialog test) |
| 5 Alarmieren nur draft+Leitstelle/Admin | `incidents_screen_test.dart` AC5 |
| 6 Nachalarmieren nur running+Leitstelle/Admin, vorbelegt | `incidents_screen_test.dart` (nachalarmieren test) |
| 7 Verwerfen nur draft, Bestätigung vor discard() | `incidents_screen_test.dart` AC7 |
| 8 AlarmDialog Submit erst mit ≥1 Fahrzeug | `incidents_screen_test.dart` AC8 |
| 9 Doppelbesetzung-Warnung mit Namen | `incidents_screen_test.dart` (double-crewed test) |
| 10 Sofort-Modus trigger(), "bereits alarmiert" schließt mit SnackBar | `incidents_screen_test.dart` (trigger/already-alarmed tests) |
| 11 Zeitpunkt/Relativ ruft plan() | `incidents_screen_test.dart` (plan tests) |
| 12 Leere Liste zeigt Leerzustand + Primäraktion bei Entwurf | `incidents_screen_test.dart` (empty state test) |
| 13 Ladefehler zeigt Fehlermeldung | `incidents_screen_test.dart` AC13 |
| 14 Abgeschlossen: readOnly, kein Speichern | `incidents_screen_test.dart` (closed/readonly test) |
| 15 Nach Anlegen: Filter→Entwurf, Karte scrollt+hervorgehoben | `incidents_screen_test.dart` AC15/AC16 |
| 16 Fokus auf Alarmieren-Button der neuen Karte | `incidents_screen_test.dart` AC15/AC16 |
| 17 AlarmDialog initialer Fokus auf erster Checkbox | `incidents_screen_test.dart` AC17/AC18 |
| 18 Enter löst Submit wie Klick; ungültig löst nichts aus | `incidents_screen_test.dart` AC17/AC18 |
| 19 Nach Sofort-Alarm: Filter→laufend, Label/Meta aktualisiert | `incidents_screen_test.dart` + `e2e/ui.mjs` (crit-path UI, AC19 in SHOT-Log) |
| 20 Zustands-Label immer sichtbar (`incident-state-${id}`) | `incidents_screen_test.dart` (state label test) + grep Key vorhanden |
| 21 "seit {Minuten} min"-Meta ab erstem `triggeredAt` | `incidents_screen_test.dart` (elapsed-meta test) |
| 22 Einsatzvorbereitung ohne Alarmieren/Nachalarmieren-Buttons | `incidents_screen_test.dart` AC22 |
| §3.4 kritischer Pfad gesamt | `e2e/ui.mjs` UI-Schritte 11–17 (SHOT ui-11…ui-17), 48/48 grün |

### web-durchsagen.md (9 ACs)

| AC | Test |
|---|---|
| 1 Ohne laufenden Tag: Formular deaktiviert + Banner | `announcements_screen_test.dart` (no-running-day test) |
| 2 Senden erst aktiv bei getrimmtem Text | `announcements_screen_test.dart` (enable test) |
| 3 Senden ruft create() mit Text+Schicht-ID | `announcements_screen_test.dart` AC3 (×2: Schicht, "Alle"→null) |
| 4 Nach Senden: Feld leer, Ziel zurück auf "Alle" | `announcements_screen_test.dart` (reset test) |
| 5 Fehler beim Senden: SnackBar, Text bleibt | `announcements_screen_test.dart` (error test) |
| 6 Liste zeigt alle, neueste zuerst, Zeit+Ziel | `announcements_screen_test.dart` AC6 |
| 7 Löschen: Bestätigung vor delete(), Abbrechen ohne Aktion | `announcements_screen_test.dart` AC7 (×2) |
| 8 Realtime-Event aktualisiert Liste | `announcements_screen_test.dart` (provider event test) |
| 9 Leere Liste zeigt "Noch keine Durchsagen." | `announcements_screen_test.dart` + Screenshot `after/web/durchsagen-1440x900.png` (zeigt befüllte Liste, Leerzustand separat getestet) |

### web-tagesablauf.md (8 ACs)

| AC | Test |
|---|---|
| 1 Sortierung nach Startzeit | `program_screen_test.dart` (sort test) |
| 2 Anlegen-Dialog, Speichern ruft create() | `program_screen_test.dart` (create test) |
| 3 Stift-Icon öffnet Bearbeiten vorausgefüllt, update() mit ID | `program_screen_test.dart` AC3 |
| 4 Mülleimer: Bestätigung vor delete() | `program_screen_test.dart` AC4 |
| 5 Beendeter Tag: keine Anlegen/Bearbeiten/Löschen sichtbar | `program_screen_test.dart` (read-only/locked test) |
| 6 Ladefehler zeigt Meldung | `program_screen_test.dart` AC6 (×3: BF-Tage, create, delete) |
| 7 Leerzustände (keine Tage/Punkte) | `program_screen_test.dart` AC7 (×2) |
| 8 Typ-Icon-Kachel korrekt je `ProgramItemType` | `program_screen_test.dart` (icon-tile test) |

### web-folien.md (12 ACs)

| AC | Test |
|---|---|
| 1 Liste zeigt alle inkl. inaktiv mit Titel/Vorschau/Dauer/Thumbnail | `slides_screen_test.dart` (list rendering test) |
| 2 "Folie anlegen" öffnet Dialog, create() bei gültiger Eingabe | `slides_screen_test.dart` AC2 |
| 3 Validierungsfehler (Titel/Text/Dauer) verhindern Absenden | `slides_screen_test.dart` (validation tests) |
| 4 Klick auf Zeile öffnet Bearbeiten, update() | `slides_screen_test.dart` (edit test) |
| 5 Aktiv-Schalter ruft update(active:), sofort gedimmt | `slides_screen_test.dart` (active switch test) |
| 6 Bild-Upload gültig ruft uploadImage() | `slides_screen_test.dart` (upload test) |
| 7 Bild-Upload ungültig zeigt Fehler, kein Aufruf | `slides_screen_test.dart` (upload error test) |
| 8 "Bild entfernen" ruft deleteImage() | `slides_screen_test.dart` (remove image test) |
| 9 Lösch-Icon: Bestätigung vor delete() | `slides_screen_test.dart` (delete confirm test) |
| 10 Ziehen ruft reorder() mit neuer ID-Reihenfolge | `slides_screen_test.dart` (reorder test) |
| 11 Ladefehler zeigt Meldung statt Liste | `slides_screen_test.dart` (load error test) |
| 12 Leere Liste zeigt Leerzustand + Primäraktion | `slides_screen_test.dart` (empty state test) |

### web-monitore.md (9 ACs)

| AC | Test |
|---|---|
| 1 Liste zeigt Name/Status/zuletzt gesehen | `monitors_screen_test.dart` (list test) |
| 2 "Monitor anlegen" ruft createMonitor(name:) | `monitors_screen_test.dart` AC2 |
| 3 Klick auf Zeile öffnet Umbenennen, updateMonitor() | `monitors_screen_test.dart` (rename test) |
| 4 Kopplungscode-Button ruft createPairingCode(), zeigt Code+Ablauf | `monitors_screen_test.dart` (pairing code test) + `e2e/ui.mjs` SHOT ui-18/19 |
| 5 "Sperren" nur sichtbar wenn nicht revoked | `monitors_screen_test.dart` (visibility test) |
| 6 "Sperren": Bestätigung vor revokeMonitor() | `monitors_screen_test.dart` (revoke confirm test) |
| 7 Ladefehler zeigt Meldung | `monitors_screen_test.dart` (load error test) |
| 8 Sortierung gekoppelt→nicht-gekoppelt→gesperrt | `monitors_screen_test.dart` (sort order test) |
| 9 Leeres Namensfeld zeigt Inline-Fehler | `monitors_screen_test.dart` (validation test) |

## 3. Keys/Semantics (grep-Verifikation)

Alle in §7 der fünf Konzeptdokumente gelisteten statischen und interpolierten Keys wurden per `grep` im
jeweiligen Screen-/Widget-Code bestätigt (siehe Terminal-Protokoll dieses Laufs):

- `incidents_screen.dart` / `alarm_dialog.dart`: alle 24 gelisteten Keys vorhanden, inkl.
  `incident-${id}`, `incident-state-${id}`, `alarm-incident-${id}`, `nachalarmieren-incident-${id}`,
  `discard-incident-${id}`.
- `announcements_screen.dart`: alle 5 statischen + 2 interpolierte Keys vorhanden.
- `program_screen.dart`: alle 8 statischen + 3 interpolierte Keys vorhanden.
- `slides_screen.dart`: alle 14 statischen Keys + `ValueKey(slide.id)` vorhanden.
- `monitors_screen.dart`: alle 8 statischen + `monitor-${id}` interpoliert vorhanden.

## 4. Screenshot-Sichtprüfung (nach Regenerierung)

`einsaetze-1440x900.png`, `durchsagen-1440x900.png`, `tagesablauf-1440x900.png`, `folien-1440x900.png`,
`monitore-1440x900.png` manuell gegen die Konzeptbeschreibungen geprüft: keine abgeschnittenen/überlaufenden
Texte, guter Kontrast, alle Primär-/Sekundärbuttons mit sichtbarem Text (nicht nur Icon), Zustands-Label und
„seit X min"-Meta sichtbar bei Einsätze, Megafon-Icon + „An:"-Label bei Durchsagen, Typ-Icon-Kacheln +
8px-Abstand Edit/Delete bei Tagesablauf, Dauer-Chip + Textvorschau + neutraler Platzhalter (kein Fehler-Look)
bei Folien, Status-Punkt + sichtbarer „Kopplungscode erzeugen"-Text + alarm-farbenes „Sperren" bei Monitore.
Keine Layout-Regressionen gegenüber den Mockups `docs/design/mockups/web-einsaetze*.png`, `web-folien.png`.
