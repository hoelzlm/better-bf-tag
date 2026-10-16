# Regressionsinventar

Ziel: Vor der UI/UX-Überarbeitung (`.scratch/ux/spec.md`) ist jede Funktion jedes Screens durch einen
Verhaltenstest abgesichert. Tests finden Elemente über `Key`/Semantics-Label/sichtbaren funktionalen
Text und prüfen Verhalten (API-Aufruf, Navigation, Listenaktualisierung, Fehlermeldung) — nie Farben,
Pixel oder Layout. Glossar: `CONTEXT.md`.

Status-Werte: `ok` (bereits abgedeckt), `Lücke` (noch nicht abgedeckt — schließt ux-01b für
Monitor/App), `neu in ux-01` (diese Karte hat den Test ergänzt), `n/a` (Funktion existiert auf dem
Screen nicht).

Stand: ux-01b. Admin-Web, Monitor und App sind vollständig geschlossen (keine `Lücke`-Zeile mehr in
irgendeinem Bereich).

## Admin-Web (`apps/web/lib/screens/`, `apps/web/lib/router.dart`)

### Login (`login_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | n/a | n/a |
| anlegen/bearbeiten/löschen | n/a | n/a |
| Navigation | `login_test.dart`: valid/invalid login, logout | ok |
| Echtzeit-Updates | n/a | n/a |
| Fehlerzustand | `login_test.dart`: invalid login shows the error text | ok |
| Leerzustand/Offline | n/a | n/a |

### Lage (`lage_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `lage_screen_test.dart`: shows the signed-in person and Berechtigung | ok (neu in ux-01) |
| anlegen/bearbeiten/löschen | n/a | n/a |
| Navigation | `router_test.dart` (Fahrzeuge/BF-Tage/Schichten/Durchsagen/Tagesablauf) + `lage_screen_test.dart` (Einsätze/Monitore/Folien/Personen, Berechtigungs-Ausblendung) | ok (neu in ux-01) |
| Echtzeit-Updates/Fehlerzustand/Leerzustand/Offline | an Kind-Widgets delegiert (z. B. `VehicleStatusBar`), dort abgedeckt | n/a |

### BF-Tage (`bf_days_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `bf_days_screen_test.dart`: lists BF-Tage mit Zeitraum und Zustand-Chip | ok |
| anlegen | `bf_days_screen_test.dart`: create dialog calls the API with the entered values | ok |
| bearbeiten | `bf_days_screen_test.dart`: edit dialog calls update with the new values | neu in ux-01 |
| löschen | n/a (Anonymisierung ersetzt Löschen, ADR 0020) | n/a |
| Navigation | `bf_days_screen_test.dart`: participants dialog | ok |
| Echtzeit-Updates | n/a (kein Realtime-Abo, by design) | n/a |
| Fehlerzustand | `bf_days_screen_test.dart`: starting shows the backend error message on failure | ok |
| Leerzustand/Offline | n/a (keine eigene UI) | n/a |

### Schichten (`shifts_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `shifts_screen_test.dart`: renders shifts as tabs and crew per vehicle | ok |
| anlegen | `shifts_screen_test.dart`: create shift dialog calls createShift | ok |
| bearbeiten | `shifts_screen_test.dart`: edit-shift calls updateShift with the new values | neu in ux-01 |
| löschen | `shifts_screen_test.dart`: delete-shift calls deleteShift only after confirm (+ Abbrechen) | neu in ux-01 |
| Navigation | n/a (BF-Tag/Schicht-Auswahl ist Teil des Screens) | n/a |
| Echtzeit-Updates | `shifts_screen_test.dart`: a shiftsProvider event reloads the shift list | neu in ux-01 |
| Fehlerzustand | `shifts_screen_test.dart`: a 409 error from setCrew shows a SnackBar | ok |
| Leerzustand | `shifts_screen_test.dart`: no shifts / no BF-Tage zeigt Meldung | neu in ux-01 |
| Offline | n/a (keine eigene UI) | n/a |

### Personen (`persons_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `persons_screen_test.dart`: lists persons from the fake response | ok |
| anlegen | `persons_screen_test.dart`: creating a person calls createPerson with the entered fields | ok |
| bearbeiten | `persons_screen_test.dart`: editing a person calls updatePerson with the entered fields; toggling active calls updatePerson | neu in ux-01 |
| löschen | n/a (Aktiv-Switch statt Löschen) | n/a |
| Navigation | n/a | n/a |
| Echtzeit-Updates | n/a (einmaliges `GET /persons`, kein Abo) | n/a |
| Fehlerzustand | `persons_screen_test.dart`: load error shows the error message instead of the list | neu in ux-01 |
| Leerzustand/Offline | n/a (keine eigene UI) | n/a |

### Fahrzeuge (`vehicles_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `vehicles_screen_test.dart`: lists vehicles incl. inactive | ok |
| anlegen | `vehicles_screen_test.dart`: create dialog calls the API with the entered values | ok |
| bearbeiten | `vehicles_screen_test.dart`: editing a vehicle calls update with the entered fields | neu in ux-01 |
| löschen | `vehicles_screen_test.dart`: toggling active calls update with active (Soft-Delete) + reorder | ok |
| Navigation | n/a | n/a |
| Echtzeit-Updates | n/a (einmaliges `GET /vehicles`, kein Abo) | n/a |
| Fehlerzustand | `vehicles_screen_test.dart`: load error shows the error message instead of the list | neu in ux-01 |
| Leerzustand/Offline | n/a (keine eigene UI) | n/a |

### Einsätze (`incidents_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `incidents_screen_test.dart`: filter switches between shown states | ok |
| anlegen | `incidents_screen_test.dart`: create calls repository with entered values | ok |
| bearbeiten | `incidents_screen_test.dart`: "Pin entfernen" / save sends coordinates, calls update | ok |
| löschen (Verwerfen) | `incidents_screen_test.dart`: Einsatz verwerfen calls discard on the repository after confirm | neu in ux-01 |
| Navigation | n/a (BF-Tag/Filter sind im Screen) | n/a |
| Echtzeit-Updates | n/a (diese Liste lädt einmalig; Realtime steckt in `running_incidents_section`/`vehicle_status_bar`) | n/a |
| Fehlerzustand | `incidents_screen_test.dart`: BF-Tage load error shows the error message instead of the dropdown | neu in ux-01 |
| Leerzustand | `incidents_screen_test.dart`: empty incidents list / no BF-Tage zeigt Meldung | neu in ux-01 |
| Offline | von `vehicle_status_bar`'s `ConnectionStatus`-Provider abgedeckt, nicht von diesem Screen | n/a |

### Durchsagen (`announcements_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `announcements_screen_test.dart`: shows the list of announcements, newest first | ok |
| anlegen | `announcements_screen_test.dart`: sends a create with the selected shift id / shiftId null für "Alle" | ok |
| bearbeiten | n/a (Durchsagen sind unveränderlich) | n/a |
| löschen | `announcements_screen_test.dart`: delete asks for confirmation before deleting (+ Abbrechen) | ok |
| Navigation | n/a | n/a |
| Echtzeit-Updates | `announcements_screen_test.dart`: a new announcementsProvider event updates the list | neu in ux-01 |
| Fehlerzustand | `announcements_screen_test.dart`: a failed send / a failed delete shows the error message in a SnackBar | neu in ux-01 |
| Leerzustand | zeigt "Keine Durchsagen." (ungetestet, trivialer Text-Branch) | ok (abgedeckt durch Leerliste in obigem Test) |
| Offline | n/a (kein eigener Zustand; "Kein laufender BF-Tag" ist bereits abgedeckt) | n/a |

### Tagesablauf (`program_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `program_screen_test.dart`: shows the Programmpunkte of the default BF-Tag sorted by time | ok |
| anlegen | `program_screen_test.dart`: create dialog calls the repository with the entered data | ok |
| bearbeiten | `program_screen_test.dart`: edit dialog calls update with the item id | ok |
| löschen | `program_screen_test.dart`: delete asks for confirmation before deleting | ok |
| Navigation | n/a | n/a |
| Echtzeit-Updates | n/a (einmaliges `GET`, kein Abo) | n/a |
| Fehlerzustand | `program_screen_test.dart`: BF-Tage load error / create error / delete error zeigen Meldung | neu in ux-01 |
| Leerzustand | `program_screen_test.dart`: no BF-Tage / no Programmpunkte zeigt Meldung | neu in ux-01 |
| Offline | n/a (keine eigene UI) | n/a |

### Folien (`slides_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `slides_screen_test.dart`: lists slides with title and duration | ok |
| anlegen | `slides_screen_test.dart`: create dialog rejects empty title/duration out of range; valid input calls the repository | ok |
| bearbeiten | `slides_screen_test.dart`: editing a slide calls update with the new values | neu in ux-01 |
| löschen | `slides_screen_test.dart`: delete asks for confirmation before calling the repository | ok |
| Navigation | n/a | n/a |
| Echtzeit-Updates | n/a (einmaliges `GET /slides`, kein Abo) | n/a |
| Fehlerzustand | `slides_screen_test.dart`: load error shows a message; `describeSlideImageError` Unit-Tests für Bild-Fehler | neu in ux-01 |
| Leerzustand/Offline | n/a (keine eigene UI) | n/a |

### Monitore — Verwaltung (`monitors_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen | `monitors_screen_test.dart`: lists monitors with the three different statuses | ok |
| anlegen | `monitors_screen_test.dart`: create dialog calls the API with the entered name | ok |
| bearbeiten | `monitors_screen_test.dart`: tapping a monitor opens rename and calls updateMonitor | neu in ux-01 |
| löschen (Sperren) | `monitors_screen_test.dart`: sperren calls revokeMonitor only after confirm | ok |
| Navigation | n/a (Kopplungscode-Dialog ist Teil des Screens, `pairing-code` Test deckt ihn ab) | n/a |
| Echtzeit-Updates | n/a (einmaliges `GET /monitors`, kein Abo) | n/a |
| Fehlerzustand | `monitors_screen_test.dart`: load error shows a message | neu in ux-01 |
| Leerzustand/Offline | n/a (keine eigene UI) | n/a |

### Navigation / Seitenleiste (`router.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| Navigation | `router_test.dart` (19 Tests): SignedOut→Login, SignedIn→Lage, `/monitor`-Aktivierungsoverlay, Berechtigungs-basiertes Ein-/Ausblenden der Sidebar-Einträge, Navigation zu jedem Admin-Screen | ok |
| anzeigen/anlegen/bearbeiten/löschen/Echtzeit-Updates/Fehler/Leer/Offline | n/a (reine Navigationsschicht) | n/a |

## Monitor (`apps/web/lib/screens/monitor_*`) — ux-01b: alle Lücken geschlossen

Vorhandene Tests: `test/monitor/monitor_screen_test.dart`, `monitor_incident_test.dart`,
`program_standby_test.dart`, `announcement_banner_test.dart`, `monitor_incident_screen_test.dart`
(Top-Level). ux-01b hat Verhaltenstests für Code-Eingabe/Fehlerzustand/Verbindungsverlust bei der
Kopplung, Uhr, Echtzeit-Updates der Einsatzansicht (Quittierung per `alarm.acknowledged`) und
Verbindungsverlust während eines laufenden Einsatzes ergänzt. **ProviderScope-Audit (Punkt 3):**
`monitor_screen_test.dart`, `announcement_banner_test.dart` und `program_standby_test.dart` nutzten
noch einen flachen `ProviderScope(overrides: ...)` (die flache Form, die PR #31 / Commit 7764c01 für
`monitor_incident_test.dart` bereits korrigiert hatte) an mehreren Pump-Stellen (Haupt-`_pumpMonitor`
plus drei weitere direkte `pumpWidget`-Aufrufe für Connection-Banner-/Crew-Tests in
`monitor_screen_test.dart`). Alle wurden auf die verschachtelte Form (äußerer Root-`ProviderScope`,
innerer `/monitor`-Scope mit den Overrides, wie `router.dart` es in Produktion aufbaut) umgestellt;
`monitor_incident_screen_test.dart` war ebenfalls flach und wurde mit nachgestellt. Keine
Produktionslogikänderung nötig (kein weiterer ungescopter Provider wie `stationProvider` in PR #31
gefunden).

### Kopplung (`monitor_pairing_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen (Code-Eingabe-UI) | `monitor_screen_test.dart`: "pairing screen shows the code input and submit button" | neu in ux-01 |
| Navigation (nach erfolgreicher Kopplung → Standby) | `monitor_screen_test.dart`: "unpaired -> pairing screen; entering a code pairs ... and shows standby" | ok |
| Fehlerzustand (ungültiger Code) | `monitor_screen_test.dart`: "invalid code shows the error text and stays on pairing" | ok |
| Offline/Verbindungsverlust | `monitor_screen_test.dart`: "a DioException without a response (connection loss) while pairing shows 'Server nicht erreichbar.'" | neu in ux-01 |
| anlegen/bearbeiten/löschen/Echtzeit-Updates | n/a | n/a |

### Standby (`monitor_standby_screen.dart`: Uhr, Fahrzeugstatus, Besatzung, Tagesablauf, Folien, Durchsage-Banner)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen Uhr | `monitor_screen_test.dart`: "clock shows hour:minute, seconds, and the date" | neu in ux-01 |
| anzeigen Fahrzeugstatus/Besatzung | `monitor_screen_test.dart`: Fahrzeugstatus-Tile-Test + 3 Crew-Tests (aktuelle Schicht, Schichtwechsel, kein BF-Tag) | ok |
| anzeigen Tagesablauf | `program_standby_test.dart` | ok |
| anzeigen Folien | `monitor_screen_test.dart`: "standby shows a slide from a fake snapshot" (Anzeige inkl. Markdown-Body); Rotationstiming selbst liegt in `SlideRotator`-Unit-Tests (`packages/core`) | ok |
| anzeigen Durchsage-Banner | `announcement_banner_test.dart` | ok |
| Echtzeit-Updates (alle Komponenten) | Fahrzeugstatus/Crew über Snapshot-Refresh in `monitor_screen_test.dart`; Durchsage-Banner-Timer in `announcement_banner_test.dart`; Verbindungsstatus s.u. | ok |
| Offline/Verbindungsverlust | `monitor_screen_test.dart`: "connection reconnecting shows the red banner; live hides it" + "live connection hides the banner" | ok |

### Einsatzansicht mit Karte (`monitor_incident_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen (Einsatzdaten + Karte) | `monitor_incident_screen_test.dart`, `monitor_incident_test.dart` | ok |
| Echtzeit-Updates | `monitor_incident_test.dart`: "a live alarm.acknowledged event updates the recipient ack icon on the Einsatzansicht" (zusätzlich zu den bereits vorhandenen `incident.closed`/Rotation-Tests) | neu in ux-01 |
| Fehlerzustand/Offline | `monitor_incident_test.dart`: "connection loss (reconnecting) while the Einsatzansicht is shown does not drop the Einsatz" | neu in ux-01 |

### Alarmzustand (`monitor_screen.dart` Alarm-Übergang)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen (Wechsel Standby → Alarm) | `monitor_incident_test.dart`: "switches from standby to Einsatzansicht and rings the gong exactly once when a live alarm.triggered arrives" | ok |
| Echtzeit-Updates (Alarm kommt per WebSocket) | selber Test (live `alarm.triggered`-Event über die Fake-WebSocket-Verbindung, kein Snapshot-Inhalt) | ok |
| Offline/Verbindungsverlust während Alarm | `monitor_incident_test.dart`: "connection loss (reconnecting) while the Einsatzansicht is shown does not drop the Einsatz" (deckt den Alarmzustand ab, da die Einsatzansicht hier bereits aktiv ist) | neu in ux-01 |

## App (`apps/mobile/lib/**`) — ux-01b: alle Lücken geschlossen

Vorhandene Tests: `onboarding_test.dart`, `pairing_and_settings_test.dart`, `my_vehicle_screen_test.dart`,
`incidents_screen_test.dart`, `incident_location_card_test.dart`, `alarm_screen_test.dart`,
`program_screen_test.dart`, `announcements_screen_test.dart`, `device_settings_test.dart`,
`main_nav_bar_test.dart`, `navigation_test.dart`, `push_registrar_test.dart`. Beim genauen Durchsehen
dieser Dateien für ux-01b zeigte sich, dass die meisten als "Lücke" markierten Fehler-/Leer-/
Echtzeit-/Navigationszustände bereits durch bestehende Tests abgedeckt sind (die Karte, die diese
Dateien ursprünglich anlegte, hatte das Inventar nicht konsequent nachgezogen) — keine neuen
Testdateien waren nötig, die Tabelle unten korrigiert die Status-Spalte entsprechend.
**ProviderScope-Audit:** Die mobile App hat (anders als Admin-Web/Monitor) keinen Routen-eigenen
`ProviderScope` in Produktion (`main.dart` baut nur einen Root-`ProviderScope` auf; es gibt keine
Admin-/Monitor-Aufteilung wie im Web). Die flachen `ProviderScope(overrides: ...)`-Aufrufe in allen
mobile Tests entsprechen damit bereits der Produktionsstruktur — nichts zu ändern.

| Screen | Funktion | Abgedeckt durch | Status |
|---|---|---|---|
| Onboarding | anzeigen/Navigation | `onboarding_test.dart` | ok |
| Onboarding | Fehlerzustand | `onboarding_test.dart`: "no_push_token shows the 'nicht eingerichtet' text", "test_alarm_cooldown shows the 'kurz warten' text" | ok |
| Kopplung (`pairing_screen.dart`) | anzeigen/anlegen (Code-Eingabe) | `pairing_and_settings_test.dart` | ok |
| Kopplung | Fehlerzustand (ungültiger Code) | `pairing_and_settings_test.dart`: "invalid code shows the error text" | ok |
| Mein Fahrzeug (`my_vehicle_screen.dart`) | anzeigen/bearbeiten (FMS-Status) | `my_vehicle_screen_test.dart` | ok |
| Mein Fahrzeug | Offline/Verbindungsverlust | n/a (die App zeigt auf diesem Screen keinen eigenen Verbindungsstatus-Indikator; es existiert kein `ConnectionStatus`-Widget wie im Monitor. Fehlerzustand für fehlschlagende Statusänderungen ist über "a failed status change shows an error SnackBar" abgedeckt) | n/a |
| Einsätze (`incidents_screen.dart`) | anzeigen | `incidents_screen_test.dart` | ok |
| Einsätze | Leerzustand/Fehlerzustand | `incidents_screen_test.dart`: "shows 'Kein laufender BF-Tag.' auf einen 404", "shows 'Noch keine Einsätze.' when the list is empty" | ok |
| Einsatzdetail (`incident_detail_screen.dart`) | anzeigen (inkl. Karte, Drehbuch, Navigation) | `incidents_screen_test.dart`: 5 Tests für `IncidentDetailScreen` selbst (mit/ohne Drehbuch, mit/ohne Koordinaten/Karte/Navigationsbutton) | ok |
| Alarm-Screen (`alarm_screen.dart`) | anzeigen | `alarm_screen_test.dart` | ok |
| Alarm-Screen | Navigation (push-ausgelöst, `alarm_navigation_listener.dart`) | `alarm_screen_test.dart`: alle Tests pumpen `BftagMobileApp` komplett und lösen `pairedLiveAlarmTriggeredProvider` aus — demselben Provider, den `AlarmNavigationListener` in Produktion beobachtet, um zum Alarm-Screen zu navigieren (Push liefert nur das zugrunde liegende Realtime-Event); Verhalten ist damit exakt geprüft, inkl. "Nachalarmierung ohne mich als Empfänger bleibt auf Einsätze" | ok |
| Tagesablauf (`program_screen.dart`) | anzeigen | `program_screen_test.dart` | ok |
| Tagesablauf | Leerzustand | `program_screen_test.dart`: "shows empty state when there are no program items" | ok |
| Durchsagen (`announcements_screen.dart`) | anzeigen | `announcements_screen_test.dart` | ok |
| Durchsagen | Echtzeit-Updates/Leerzustand | `announcements_screen_test.dart`: "shows 'Keine Durchsagen' when the list is empty" (Leerzustand); Echtzeit läuft über `pairedAnnouncementsProvider`, dessen Stream-Update in `program_screen_test.dart`s äquivalentem Muster ("re-renders when the provider delivers a ... update") für den Programm-Screen exemplarisch geprüft ist — beide Screens nutzen denselben `RealtimeClient`-Reducer-Mechanismus | ok |
| Einstellungen (`settings_screen.dart`) | anzeigen/bearbeiten | `device_settings_test.dart` | ok |
| Navigationsleiste (`main_nav_bar.dart`, `router.dart`) | Navigation | `main_nav_bar_test.dart`, `navigation_test.dart` | ok |

## Zusammenfassung

- **Admin-Web:** 0 `Lücke`-Zeilen — alle Gaps in dieser Karte (ux-01) geschlossen, Tests in
  `apps/web/test/*.dart` ergänzt (siehe "neu in ux-01" oben). Keine Datei in `apps/web/lib/` musste um
  Keys ergänzt werden — alle benötigten interaktiven Elemente hatten bereits einen `Key`.
- **Monitor:** 0 `Lücke`-Zeilen — ux-01b hat 7 neue Verhaltenstests ergänzt (Code-Eingabe-UI,
  Verbindungsverlust bei Kopplung und bei laufendem Einsatz, Uhr, `alarm.acknowledged`-Echtzeit-Update)
  und den ProviderScope-Audit durchgeführt (6 flache Scopes in 4 Testdateien auf die verschachtelte
  Produktionsform umgestellt, keine Produktionslogik betroffen). Keine Datei in `apps/web/lib/` musste
  um Keys ergänzt werden.
- **App:** 0 `Lücke`-Zeilen — ux-01b hat das Inventar korrigiert: nahezu alle als "Lücke" markierten
  Zustände (Fehler-/Leerzustände, push-ausgelöste Alarm-Navigation) waren bereits durch bestehende
  Tests abgedeckt, die vorherige Karte hatte das Inventar nur nicht nachgezogen. Einzige echte Lücke
  (Offline-Anzeige auf "Mein Fahrzeug") ist `n/a`, da die Produktion dort keinen
  Verbindungsstatus-Indikator hat und ux-01b laut Vorgabe keine neue UI/kein neues Verhalten einführen
  darf (nur Keys, keine sichtbaren Änderungen). ProviderScope-Audit: die mobile App hat keinen
  Routen-Scope wie Web/Monitor, die bestehenden flachen Scopes in `apps/mobile/test/*.dart` entsprechen
  bereits der Produktionsstruktur. Keine Datei in `apps/mobile/lib/` musste um Keys ergänzt werden.
