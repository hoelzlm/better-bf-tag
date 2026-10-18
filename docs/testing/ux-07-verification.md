# ux-07 Tester-Verifikation — Monitor (Kopplung, Standby, Einsatzansicht, Alarm)

Branch verifiziert: lokaler `main` nach Merge von t_4c08a4e7 (Kopplung), t_241ef801 (Standby),
t_2b15e04f (Einsatzansicht), t_27a054d1 (Alarm) und t_d0a63eea (Fix Screenshot-Seed-Reihenfolge).
HEAD zum Zeitpunkt der Verifikation: `1b3120e`.

## 1. AC-Abdeckung je Konzept

### monitor-kopplung.md §6 (AC1–10)
Alle 10 ACs sind je einem benannten Test in `monitor_screen_test.dart` / `monitor_pairing_test.dart`
zugeordnet (siehe Reviewer-Checks t_4c08a4e7). Stichprobe erneut gelesen: Kopplungscode-Feld
autofocus, disabled/Spinner-Submit, Fehlertext als Warning-Token (nie Alarm/Rot),
`MonitorOffline`/`MonitorUnknown` → einheitlich "Verbinde …". Visuell bestätigt in
`docs/design/screenshots/after/monitor/kopplung-1920x1080.png` (Icon, Titel, Code-Eingabe mit
Fokusrahmen, Koppeln-Button, Hinweistext) und `aktivierung-1920x1080.png` (Tap-to-activate-Overlay).

### monitor-standby.md §6 (AC1–11)
Alle 11 ACs sind Tests in `monitor_standby_screen_test.dart` / `monitor_vehicle_panel_test.dart`
zugeordnet (siehe Reviewer-Checks t_241ef801): Grid-Layout, Fahrzeugpanel mit Paging >7 Fahrzeuge
alle 10s, einzeilige Besatzung mit Ellipsis, FMS-Pille, Tagesablauf mit Empty-State und
"nie Vergangenheit"-Regel, Folienfläche ≥900×440 mit ≤40/≤28px Text, Durchsage-Banner
(primaryContainer), gemeinsamer `MonitorConnectionBanner`. Visuell bestätigt in
`standby-1920x1080.png` (Uhr, Fahrzeugstatus & Besatzung HLF-1/RTW-1/DLK-1, Tagesablauf "Danach",
Willkommenstext) und `standby-durchsage-1920x1080.png` (zusätzlich DURCHSAGE-Banner am Fuß,
keine Einsatz-Markup mehr sichtbar — Fix aus t_d0a63eea greift).

### monitor-einsatz.md §6 (AC1–8)
Alle 8 ACs sind Tests in `monitor_incident_screen_test.dart` / `monitor/monitor_incident_test.dart`
zugeordnet (siehe Reviewer-Checks t_2b15e04f): Kartenbereich Expanded flex:4 ≥560px, Karten-Placeholder
mit "Keine Standortdaten" bei fehlendem Standort, keine harten Farben, Alarm-Label als neutraler Chip,
separater Quittierungs-Fortschritts-Chip, Fahrzeug-Chips mit Kurzname+Rufzeichen+FMS-Badge,
Meldebild-Trunkierung auf 6 Zeilen mit Fade, gemeinsamer `MonitorConnectionBanner`. Visuell bestätigt
in `einsatzansicht-1920x1080.png` (Einsatz 3, Meldebild, Quittiert-Panel, Fahrzeugchip DLK-1,
Fortschritts-Chip) und `einsatz-fallback-1920x1080.png` (Einsatz 4 "Kein GPS verfügbar" mit
"Keine Standortdaten"-Placeholder statt Karte).

### monitor-alarm.md §6 (AC1–13)
Alle 13 ACs sind Tests (fake-timer) in `monitor_alarm_screen_test.dart` zugeordnet (siehe
Reviewer-Checks t_27a054d1): volle Alarmfläche, Badge mit Puls (deaktiviert unter
`disableAnimations`), Stichwort-Autoskalierung Floor 64px, Meldebild ≥40px, Fahrzeug-Chip-Name
≥56px, Fahrzeuge exakt aus dem auslösenden Alarm, `MonitorConnectionBanner` oben, 20-s-Phase mit
Restart bei zweitem `alarm.triggered`, Pause/Neustart der 15-s-Rotation, sofortiger Abbruch bei
`incident.closed`. Visuell bestätigt in `alarm-1920x1080.png`: volle rote Fläche (`BftagAlarmColors.alarm`),
ERSTALARM-Badge, Stichwort "B2 KELLERBRAND", Adresse, Meldebild, Uhrzeit, Fahrzeugchip DLK-1 mit
"0/0 quittiert" — kein abgeschnittener/überlaufender Text.

## 2. §7-Keys und Regression (§8)

Keys je Datei (grep `Key(`): `monitor_pairing_screen.dart` (4), `monitor_screen.dart` (2),
`monitor_standby_screen.dart` (10), `monitor_vehicle_panel.dart` (5), `monitor_incident_screen.dart` (18),
`monitor_incident_parts.dart` (4), `monitor_alarm_screen.dart` (9), `monitor_connection_banner.dart` (2),
`announcement_banner.dart` (2) — alle in §7 der jeweiligen Konzepte geforderten Keys vorhanden
(bereits einzeln von den vier Reviewern bestätigt).

`git diff 8963819 -- apps/web/test`: 11 geänderte Dateien, 2369 Insertions / 340 Deletions, **0**
entfernte `test(` / `  test(` Deklarationen in allen vier Monitor-Testdateien (`monitor_screen_test.dart`,
`monitor_incident_test.dart`, `announcement_banner_test.dart`, `program_standby_test.dart`) — keine
Tests gelöscht. Zeilenlöschungen sind ausschließlich Anpassungen innerhalb bestehender Tests an laut
Konzept geänderte Keys/Texte (z.B. Standby-Panel-Umbenennungen, Alarm-Chip statt Alarm-Hintergrund),
keine Abschwächung von Assertions.

§8-Regressionszeilen (bestehende Funktionen) weiterhin grün: VehicleStatusBar (Admin-Lage-Widget)
unverändert, `monitor_screen.dart`-State-Machine (Standby↔Einsatz↔Alarm-Übergänge) unverändert bis auf
die 20-s-Phase, Pairing-Flow (ui-18/ui-19 in e2e) unverändert.

## 3. Harte Farben

```
grep -nE "Colors\.(red|orange|amber)|Color\(0x" apps/web/lib/screens/monitor_*.dart apps/web/lib/monitor/*.dart
```
Einziger Treffer: ein Kommentar in `monitor_connection_banner.dart:56`, der explizit dokumentiert,
*nicht* `BftagAlarmColors.alarm`/`Colors.red` zu verwenden — kein Code-Treffer. Keine harten Farbwerte
in den betroffenen Dateien.

## 4. Reduced Motion

`apps/web/lib/screens/monitor_alarm_screen.dart:300` liest `MediaQuery.maybeOf(context)?.disableAnimations`
und unterdrückt den Badge-Puls entsprechend (Kommentar Zeile 268–269: "never when
`MediaQuery.disableAnimations` is set"). Testbeleg: `monitor_alarm_screen_test.dart:505` setzt
`MediaQueryData(disableAnimations: true)` und prüft, dass kein Puls/Blinken der gesamten Fläche
stattfindet. Kein Screen blinkt vollflächig außerhalb der dokumentierten Alarm-Badge-Pulsation.

## 5. Testläufe (alle grün, HEAD 1b3120e)

- Backend: `just test` → 336/336 (32 Testdateien)
- `dart analyze packages/api_client && flutter analyze apps/web apps/mobile packages/core` → clean,
  keine Issues
- `flutter test` packages/core → 268/268
- `flutter test` apps/web → 315/315
- `flutter test` apps/mobile → 87/87
- `just e2e` → API 142/142, UI 48/48 (inkl. ui-18/ui-19 Monitor-Pairing, ui-20 Monitor-Alarm-Flow),
  keine uncaught JS exceptions, Docker-Stack sauber heruntergefahren (Trap im Skript)
- `just screenshots after` → 44/44 (inkl. der 7 Monitor-PNGs + assertStandbyScreen-Guards aus t_d0a63eea)

## 6. Visuelle Prüfung der Monitor-Nachher-Screenshots

Alle 7 PNGs unter `docs/design/screenshots/after/monitor/` per Vision gegen Konzept/Mockup geprüft:

| Screenshot | Ergebnis |
|---|---|
| `aktivierung-1920x1080.png` | Tap-to-activate-Overlay, zentriert, kein Clipping |
| `kopplung-1920x1080.png` | Code-Eingabe mit Fokusrahmen, Koppeln-Button, Hinweistext — entspricht Mockup |
| `standby-1920x1080.png` | Uhr, Fahrzeugstatus & Besatzung (3 Fahrzeuge), Tagesablauf, Willkommenstext; keine Einsatz-Markup |
| `standby-durchsage-1920x1080.png` | Wie Standby + DURCHSAGE-Banner am Fuß; keine Einsatz-Markup (Fix aus t_d0a63eea bestätigt) |
| `alarm-1920x1080.png` | Volle rote Fläche nur im Alarmzustand, Badge/Stichwort/Adresse/Meldebild/Uhr/Fahrzeugchip lesbar, kein Clipping |
| `einsatzansicht-1920x1080.png` | Einsatz-Header, Meldebild, Quittiert-Panel, Fahrzeugchip, Fortschritts-Chip — Layout korrekt. Kartenbereich zeigt OSM "403 Access blocked"-Kacheln (siehe unten) |
| `einsatz-fallback-1920x1080.png` | "Keine Standortdaten"-Placeholder korrekt statt Karte bei fehlendem GPS |

**Beobachtung Kartenkacheln (kein neuer Bug):** In `einsatzansicht-1920x1080.png` liefert der
öffentliche OSM-Tile-Server "403 Access blocked" (OSM-Nutzungsrichtlinie, automatisierte/gehäufte
Anfragen aus der CI-Umgebung ohne Caching-Proxy). Vergleich mit
`docs/design/screenshots/before/monitor/einsatzansicht-1920x1080.png` zeigt exakt dasselbe
Fehlerbild bereits vor dem ux-07-Rework — das ist bestehendes Umgebungsverhalten
(ADR 0026, kein eigener Tile-Proxy), keine Regression durch ux-07. Kein Bug-Ticket erstellt.

## Ergebnis

Keine neuen Bugs. Alle ACs aller vier Konzepte durch Tests oder Screenshots belegt, keine Tests
gelöscht/abgeschwächt, keine harten Farben, Reduced Motion funktioniert, alle Suiten grün.
