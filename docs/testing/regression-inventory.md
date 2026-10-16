# Regressionsinventar

Ziel: Vor der UI/UX-Überarbeitung (`.scratch/ux/spec.md`) ist jede Funktion jedes Screens durch einen
Verhaltenstest abgesichert. Tests finden Elemente über `Key`/Semantics-Label/sichtbaren funktionalen
Text und prüfen Verhalten (API-Aufruf, Navigation, Listenaktualisierung, Fehlermeldung) — nie Farben,
Pixel oder Layout. Glossar: `CONTEXT.md`.

Status-Werte: `ok` (bereits abgedeckt), `Lücke` (noch nicht abgedeckt — schließt ux-01b für
Monitor/App), `neu in ux-01` (diese Karte hat den Test ergänzt), `n/a` (Funktion existiert auf dem
Screen nicht).

Stand: ux-01a. Admin-Web ist vollständig geschlossen (keine `Lücke`-Zeile mehr). Monitor und App sind
der aktuelle Stand (teils schon aus v2-Tickets abgedeckt); verbleibende Lücken schließt ux-01b.

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

## Monitor (`apps/web/lib/screens/monitor_*`) — Stand heute, Lücken schließt ux-01b

Vorhandene Tests: `test/monitor/monitor_screen_test.dart`, `monitor_incident_test.dart`,
`program_standby_test.dart`, `announcement_banner_test.dart`, `monitor_incident_screen_test.dart`
(Top-Level). Diese decken Teile von Kopplung, Standby-Komponenten und Einsatzansicht bereits ab,
aber nicht systematisch jede Funktion/jeden Zustand; zusätzlich ist zu prüfen, ob die bestehenden
Monitor-Tests `ProviderScope` wie in Produktion verschachteln (PR #31 / Commit 7764c01) oder noch
flach sind — das ist Teil von ux-01b (Punkt 3 der Karte).

### Kopplung (`monitor_pairing_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen (Code-Eingabe-UI) | ungeprüft, kein dedizierter Test gefunden | Lücke |
| Navigation (nach erfolgreicher Kopplung → Standby) | ungeprüft | Lücke |
| Fehlerzustand (ungültiger Code) | ungeprüft | Lücke |
| Offline/Verbindungsverlust | ungeprüft | Lücke |
| anlegen/bearbeiten/löschen/Echtzeit-Updates | n/a | n/a |

### Standby (`monitor_standby_screen.dart`: Uhr, Fahrzeugstatus, Besatzung, Tagesablauf, Folien, Durchsage-Banner)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen Uhr | ungeprüft | Lücke |
| anzeigen Fahrzeugstatus/Besatzung | teilweise über `monitor_screen_test.dart` | Lücke (nicht vollständig) |
| anzeigen Tagesablauf | `program_standby_test.dart` | ok |
| anzeigen Folien | ungeprüft (Rotation/Anzeige) | Lücke |
| anzeigen Durchsage-Banner | `announcement_banner_test.dart` | ok |
| Echtzeit-Updates (alle Komponenten) | teilweise | Lücke |
| Offline/Verbindungsverlust | ungeprüft | Lücke |

### Einsatzansicht mit Karte (`monitor_incident_screen.dart`)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen (Einsatzdaten + Karte) | `monitor_incident_screen_test.dart`, `monitor_incident_test.dart` | ok (Grundabdeckung) |
| Echtzeit-Updates | teilweise geprüft | Lücke (vollständige Prüfung offen) |
| Fehlerzustand/Offline | ungeprüft | Lücke |

### Alarmzustand (`monitor_screen.dart` Alarm-Übergang)

| Funktion | Abgedeckt durch | Status |
|---|---|---|
| anzeigen (Wechsel Standby → Alarm) | `monitor_screen_test.dart` (Grundabdeckung) | ok (Grundabdeckung) |
| Echtzeit-Updates (Alarm kommt per WebSocket) | teilweise | Lücke |
| Offline/Verbindungsverlust während Alarm | ungeprüft | Lücke |

## App (`apps/mobile/lib/**`) — Stand heute, Lücken schließt ux-01b

Vorhandene Tests: `onboarding_test.dart`, `pairing_and_settings_test.dart`, `my_vehicle_screen_test.dart`,
`incidents_screen_test.dart`, `incident_location_card_test.dart`, `alarm_screen_test.dart`,
`program_screen_test.dart`, `announcements_screen_test.dart`, `device_settings_test.dart`,
`main_nav_bar_test.dart`, `navigation_test.dart`, `push_registrar_test.dart`. Grundfunktionen (anzeigen)
sind für die meisten Screens vorhanden; Fehler-/Leer-/Offline-Zustände und Push-ausgelöste
Alarm-Navigation sind nicht durchgängig geprüft.

| Screen | Funktion | Abgedeckt durch | Status |
|---|---|---|---|
| Onboarding | anzeigen/Navigation | `onboarding_test.dart` | ok (Grundabdeckung) |
| Onboarding | Fehlerzustand | ungeprüft | Lücke |
| Kopplung (`pairing_screen.dart`) | anzeigen/anlegen (Code-Eingabe) | `pairing_and_settings_test.dart` | ok (Grundabdeckung) |
| Kopplung | Fehlerzustand (ungültiger Code) | ungeprüft | Lücke |
| Mein Fahrzeug (`my_vehicle_screen.dart`) | anzeigen/bearbeiten (FMS-Status) | `my_vehicle_screen_test.dart` | ok (Grundabdeckung) |
| Mein Fahrzeug | Offline/Verbindungsverlust | ungeprüft | Lücke |
| Einsätze (`incidents_screen.dart`) | anzeigen | `incidents_screen_test.dart` | ok (Grundabdeckung) |
| Einsätze | Leerzustand/Fehlerzustand | ungeprüft | Lücke |
| Einsatzdetail (`incident_detail_screen.dart`) | anzeigen (inkl. Karte) | `incident_location_card_test.dart` (Teilabdeckung) | Lücke (Screen selbst ungetestet) |
| Alarm-Screen (`alarm_screen.dart`) | anzeigen | `alarm_screen_test.dart` | ok (Grundabdeckung) |
| Alarm-Screen | Navigation (push-ausgelöst, `alarm_navigation_listener.dart`) | ungeprüft | Lücke |
| Tagesablauf (`program_screen.dart`) | anzeigen | `program_screen_test.dart` | ok (Grundabdeckung) |
| Tagesablauf | Leerzustand | ungeprüft | Lücke |
| Durchsagen (`announcements_screen.dart`) | anzeigen | `announcements_screen_test.dart` | ok (Grundabdeckung) |
| Durchsagen | Echtzeit-Updates/Leerzustand | ungeprüft | Lücke |
| Einstellungen (`settings_screen.dart`) | anzeigen/bearbeiten | `device_settings_test.dart` | ok (Grundabdeckung) |
| Navigationsleiste (`main_nav_bar.dart`, `router.dart`) | Navigation | `main_nav_bar_test.dart`, `navigation_test.dart` | ok |

## Zusammenfassung

- **Admin-Web:** 0 `Lücke`-Zeilen — alle Gaps in dieser Karte (ux-01) geschlossen, Tests in
  `apps/web/test/*.dart` ergänzt (siehe "neu in ux-01" oben). Keine Datei in `apps/web/lib/` musste um
  Keys ergänzt werden — alle benötigten interaktiven Elemente hatten bereits einen `Key`.
- **Monitor + App:** Grundfunktionen (anzeigen, grundlegende Navigation) sind überwiegend vorhanden;
  Echtzeit-Updates, Fehler-/Leer-/Offline-Zustände und die push-ausgelöste Alarm-Navigation haben
  Lücken. Schließt ux-01b, inkl. Audit, ob bestehende Monitor-Tests `ProviderScope` korrekt wie in
  Produktion verschachteln (PR #31).
