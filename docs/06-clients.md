# 06 – Clients

Alle Clients sind Flutter-Apps und teilen sich `packages/core` und `packages/api_client`.
Fachbegriffe: [CONTEXT.md](../CONTEXT.md). Welche Berechtigung was darf: [04 – API](04-api.md#berechtigungen).

## Web (`apps/web`, Route `/admin`)

Zielgerät: Laptop bzw. Desktop-Browser. Was sichtbar ist, hängt von der Berechtigung ab.

| Screen                             | Berechtigung                    | Inhalt                                                                                                                                                                                                                                                                                                                                                                                                                                   | Phase  |
| ---------------------------------- | ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Login                              | –                               | Benutzername, Passwort                                                                                                                                                                                                                                                                                                                                                                                                                   | MVP    |
| Lage (Startseite Leitstelle)       | Leitstelle                      | laufende Einsätze, Fahrzeugstatus-Leiste, nächste geplante Alarmierungen, Quittierungen live (quittiert / ausstehend / kein Gerät), verpasste Alarmierungen, Abschlussvorschläge                                                                                                                                                                                                                                                         | MVP    |
| Einsätze                           | Einsatzvorbereitung, Leitstelle | Liste je BF-Tag, Filter Entwurf/laufend/abgeschlossen                                                                                                                                                                                                                                                                                                                                                                                    | MVP    |
| Einsatz bearbeiten                 | Einsatzvorbereitung, Leitstelle | Meldebild, Drehbuch (deutlich als „geheim“ markiert), Alarmierungen anlegen: Fahrzeuge + „sofort“ oder Zeitpunkt; Nachalarmierungen relativ zum Erstalarm planen; Karte mit Einsatz-Pin ([ADR 0026](adr/0026-karte.md), siehe unten)                                                                                                                                                                                                     | MVP    |
| Schichten                          | Leitstelle                      | Schichten des BF-Tags, Besatzung per Drag & Drop (Person → Fahrzeug + Funktion), Warnung bei Doppelbesetzung                                                                                                                                                                                                                                                                                                                             | MVP    |
| Anstehende Einsätze                | Einsatzvorbereitung             | Countdown bis zur geplanten Alarmierung, Drehbuch, Button „Bereitmeldung“                                                                                                                                                                                                                                                                                                                                                                | später |
| Einsatzberichte                    | Leitstelle                      | eingereichte Berichte, Vergleich mit Drehbuch, freigeben/zurückgeben                                                                                                                                                                                                                                                                                                                                                                     | später |
| Durchsage (`/admin/durchsagen`)    | Leitstelle, Administrator       | Formular: Text (max. 500 Zeichen, Zähler), Ziel „Alle“ oder Schicht des laufenden BF-Tags, „Senden“ (primary, Megafon-Icon); Liste der Durchsagen des Tags (neueste zuerst, Uhrzeit, Ziel, Text; leer: „Noch keine Durchsagen.“), Löschen mit Rückfrage; ohne laufenden BF-Tag Hinweis-Banner und deaktiviertes Formular                                                                                                                 | MVP    |
| Tagesablauf (`/admin/tagesablauf`) | Leitstelle, Administrator       | Topbar: BF-Tag-Auswahl (Standard: laufend, sonst nächster geplanter, sonst letzter) wie bei Schichten, „Programmpunkt anlegen“ (primary); Liste der Programmpunkte nach Zeit (`HH:mm–HH:mm`, Typ-Icon in farbiger Kachel + Label, Titel); Anlegen/Bearbeiten (Titel 1–80 Zeichen, Typ, Start/Ende, Ende muss nach Start liegen)/Löschen mit Rückfrage; bei beendetem BF-Tag nur lesend (Schloss-Hinweis im Topbar, Formular deaktiviert) | MVP    |
| BF-Tage                            | Administrator                   | anlegen, Zeitraum, Teilnahmen, Anonymisierung                                                                                                                                                                                                                                                                                                                                                                                            | MVP    |
| Personen                           | Administrator                   | Personentyp, Berechtigung, Feuerwehr, Geräte, QR-Codes drucken                                                                                                                                                                                                                                                                                                                                                                           | MVP    |
| Fahrzeuge                          | Administrator                   | Stammdaten, Sortierung                                                                                                                                                                                                                                                                                                                                                                                                                   | MVP    |
| Feuerwehren                        | Administrator                   | weitere Feuerwehren                                                                                                                                                                                                                                                                                                                                                                                                                      | später |
| Monitore, Folien                   | Administrator                   | Kopplung, Standby-Folien                                                                                                                                                                                                                                                                                                                                                                                                                 | MVP    |

## Monitor (`apps/web`, Route `/monitor`)

Zielgerät: Fernseher mit Fire-TV-Stick, Mini-PC oder Tablet im Kiosk-Modus. Zeigt alles, eine
Trennung nach Wachen gibt es vorerst nicht. **Das Drehbuch zeigt er nie.**

Bei einem **laufenden Einsatz**:

```
┌──────────────────────────────────────────────────────────┐
│ EINSATZ 7                                  18:12:03      │
│ B2 – WOHNUNGSBRAND                         seit 02:41    │
│ Musterstraße 1, Musterstadt                              │
├──────────────────────────────────┬───────────────────────┤
│ Meldebild:                       │ Quittiert             │
│ Rauchentwicklung aus Fenster     │ ✓ Max M.   ✓ Lea K.   │
│ 2. OG, Person vermisst           │ ✓ Tim S.   … Ben R.   │
├──────────────────────────────────┴───────────────────────┤
│ HLF 1 [3]   DLK [3]   RTW [2]   ELW [1]   MTW [6]        │
└──────────────────────────────────────────────────────────┘
```

Im **Standby** (Redesign `docs/design/screens/monitor-standby.md`, festes Grid statt
content-abhängiger Höhen):

- Kopfzeile: Uhrzeit (`HH:mm`, Sekunden kleiner daneben), Datum, Verbindungspunkt + Monitorname.
- Linke Spalte `MonitorVehiclePanel` (vereint die frühere Fahrzeugstatus-Leiste und die
  Schicht-Besatzung in ein Panel): vertikale, nicht scrollende Liste, eine Zeile pro Fahrzeug
  (Kurzname, Besatzung „Funktion Name“ durch `·` getrennt in einer Zeile mit Ellipsis, FMS-Pille);
  Panel-Überschrift „Fahrzeugstatus & Besatzung“, mit „ · Schicht N · HH:mm–HH:mm“, sobald ein
  BF-Tag läuft und eine Schicht aktiv ist; bei mehr als 7 Fahrzeugen seitenweises Blättern (Punkte
  unten, Wechsel alle 10 s) statt Scrollen.
- Rechte Spalte „Tagesablauf“ (ADR 0025): immer sichtbar (kein leerer Bildschirm), zeigt „Jetzt“ /
  „Danach“ (`currentAndNext(programItems, now)`, `now` aus `monitorClockProvider`) plus – ohne
  aktive Folien – bis zu 4 weitere künftige Programmpunkte; nie ein Programmpunkt, dessen Ende
  bereits vergangen ist, außer dem aktuellen; ohne Programmpunkte zeigt das Panel einen
  Leerzustand-Hinweis „Kein Tagesablauf für heute.“ statt ganz zu verschwinden. Mit aktiven Folien
  wird der Block kompakt (nur „Jetzt“/„Danach“) und eine Folienfläche (≥ 900×440 px) rotiert
  darunter.
- Fußzeile mit drei Prioritäten: 1) laufende, live empfangene Durchsage (`announcement.created`,
  60 s, Banner in `primaryContainer`-Farbe – nie Amber/Rot, eine Durchsage ist kein Alarm), 2)
  sonst „Letzte Durchsage“ aus `snapshot.announcements` (Uhrzeit + Text), 3) sonst eine leere,
  dezente Leiste; läuft ein Einsatz (Einsatzansicht), hat diese immer Vorrang – Fußzeile und
  Tagesablauf werden dann nicht angezeigt.

Technik: Gong bzw. Alarmton bei `alarm.triggered` (der Browser verlangt einmal „Zum Aktivieren
tippen“), Screen Wake Lock, rotes Banner bei Verbindungsverlust, Rotation bei mehreren laufenden
Einsätzen.

Bei einem **live** `alarm.triggered` (nicht bei einem per Snapshot bereits laufenden Einsatz)
zeigt der Monitor für 20 s einen Alarmzustand (Redesign `docs/design/screens/monitor-alarm.md`):
Vollbild in `BftagAlarmColors.alarm`, Badge mit Alarmstufe („ERSTALARM“ / „N. NACHALARMIERUNG“,
pulsierendes Icon, deaktiviert bei reduzierter Bewegung), Stichwort, Adresse, Meldebild, Uhrzeit
und Laufzeit, sowie genau die mit diesem Alarm alarmierten Fahrzeuge (`Alarm.vehicleIds`, nicht
alle Fahrzeuge des Einsatzes) mit Quittierungsfortschritt. Währenddessen pausiert die
Einsatz-Rotation vollständig; ein erneuter `alarm.triggered` für denselben Einsatz startet die
20 s neu, ein `incident.closed` während der Phase beendet sie sofort. Danach (oder ohne weiteren
Live-Alarm) folgt die ruhige Einsatzansicht.

## Mobile-App (`apps/mobile`)

Zielgeräte: Android 8+ (API 26), iOS 16+. Für alle Personen; Funktionen je nach Berechtigung.

| Screen                       | Inhalt                                                                                                                                             | Phase  |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | ------ |
| Onboarding                   | QR-Code scannen → Berechtigungen (Push, Nicht-stören, Akku) → Testalarm                                                                            | MVP    |
| Alarm (Vollbild)             | Stichwort, Adresse, Meldebild, alarmierte Fahrzeuge, großer Button **„Quittieren“**                                                                | MVP    |
| Mein Fahrzeug                | aktuelle Besatzung und Funktion, FMS-Tasten 1–8 (Funkgerät-Optik)                                                                                  | MVP    |
| Einsätze                     | laufende und vergangene Einsätze des BF-Tags                                                                                                       | MVP    |
| Einsatzdetail                | Meldebild, Alarmierungen, Quittierungen; Drehbuch nur bei Berechtigung                                                                             | MVP    |
| Einsatzbericht               | für die Funktion GF nach Status 1/2: Lage, Maßnahmen, Vorkommnisse; Zeiten automatisch                                                             | später |
| Vorwarnung / Bereitmeldung   | für Einsatzvorbereitung                                                                                                                            | später |
| Durchsagen (`/durchsagen`)   | Liste aus `snapshot.announcements`, neueste zuerst; dritter Eintrag der Navigationsleiste                                                          | MVP    |
| Tagesablauf (`/tagesablauf`) | Liste aus `snapshot.program_items` (laufender BF-Tag), aktuelle Punkte hervorgehoben, vergangene ausgegraut; vierter Eintrag der Navigationsleiste | MVP    |
| Einstellungen                | Gerät abmelden, Testalarm, Hinweise zu Akku und Ton                                                                                                | MVP    |

### Technik

- Push: `firebase_messaging` (Android) und natives APNs-Token (iOS), siehe ADR 0003
- `flutter_local_notifications` für Channel-Setup und Anzeige im Vordergrund
- `flutter_secure_storage` für Tokens, `mobile_scanner` für den QR-Code
- Deep Link aus der Notification auf den Alarm-Screen

### Durchsagen (ADR 0024)

- Android-Notification-Channel `announcement` ("Durchsagen"), `IMPORTANCE_DEFAULT`, Standard-Ton,
  **kein** `setBypassDnd` -- angelegt in `MainActivity.kt` neben dem bestehenden `alarm`-Channel.
- App im Vordergrund: ein live empfangenes `announcement.created` (nie aus dem Snapshot, siehe
  `pairedAnnouncementCreatedProvider`) zeigt eine SnackBar "Durchsage: …" mit Aktion "Anzeigen",
  die zu `/durchsagen` navigiert. Der Listener (`AnnouncementSnackbarListener`) sitzt app-weit neben
  `AlarmNavigationListener`.
- Tippen auf eine Durchsage-Push-Benachrichtigung öffnet `/durchsagen`, sowohl bei laufender App
  (`PushService.onAnnouncementOpened`) als auch beim Kaltstart aus der Benachrichtigung (FCM
  `getInitialMessage`). Auf iOS ist dieser Stream vorerst ein No-op (TODO, natives APNs-Channel-
  Wiring fehlt noch). Alarm- und Durchsage-Pushes schließen sich gegenseitig aus:
  `PushService.onAlarmOpened` ignoriert `type: 'announcement.created'`.

### Navigation & "Mein Fahrzeug" (ADR 0027, T07-3)

- Die Navigationsleiste (`MainNavBar`) hat einen 1px `outline`-Trenner oben, keinen
  Schatten/Elevation-Tint (`navigationBarTheme.elevation: 0`, `surfaceTintColor: transparent`),
  Labels immer sichtbar und kein Badge (keine Datenquelle für ungelesen). Sie erscheint nur auf
  den vier Top-Level-Screens (`/`, `/einsaetze`, `/durchsagen`, `/tagesablauf`), nicht auf
  Onboarding/Pairing/Einsatzdetail/Alarm/Einstellungen.
- `MyVehicleScreen`: Fahrzeugname `headlineSmall`, Typ-Zeile `bodyMedium`/`onSurfaceVariant`,
  kombinierte Zeile "Funktion: … · **Status:** …" (`bodyLarge`, "Status:" fett). Der
  Einstellungen-Button hat jetzt das Tooltip "Einstellungen". Der leere Zustand (kein
  zugeteiltes Fahrzeug) nutzt `BftagStateView.empty` mit einem 48dp
  `local_shipping_outlined`-Icon; der Text ist unverändert.
- `FmsPanel`: Kacheln sind mind. 96dp hoch mit 16px Abstand (`BftagSpacing.lg`) in beide
  Richtungen. Inaktive Kacheln: `surfaceContainerHighest`/`onSurface`; die aktive Kachel nutzt die
  feste FMS-Token-Farbe (`BftagStatusColors`). Im Dark Mode haben alle Kacheln einen 1px
  `onSurface`-bei-24%-Rahmen (Designsystem §2.4/§5.5).

### Tagesablauf (ADR 0025)


- `ProgramScreen` (`/tagesablauf`, vierter Eintrag der Navigationsleiste "Ablauf") listet die
  sortierten Programmpunkte des laufenden BF-Tags aus `pairedProgramItemsProvider` -- kein eigener
  Fetch, nur der Realtime-Snapshot-State. Jede Zeile zeigt `HH:mm–HH:mm` (lokale Zeit), ein
  Typ-Icon (Essen, Ausbildung, Fahrzeugpflege, Ruhe, Sonstiges) und den Titel.
- Aktuelle Punkte (`isCurrentProgramItem`) werden als Card in `primaryContainer`-Farbe mit einem
  "Jetzt"-Chip hervorgehoben, vergangene (`isPastProgramItem`) ausgegraut (reduzierte Opazität).
  Ohne Programmpunkte zeigt der Screen "Kein Tagesablauf vorhanden."
- `programNowProvider` tickt alle 30 s (startet mit `DateTime.now()`) und treibt die
  Hervorhebung, unabhängig von Realtime-Events; Tests überschreiben ihn für einen deterministischen
  Ablauf.

## Karte ([ADR 0026](adr/0026-karte.md))

Gemeinsames Widget `IncidentMap` in `packages/core/lib/src/map/incident_map.dart` auf Basis von
`flutter_map` (plus `latlong2`): Kacheln von `https://tile.openstreetmap.org/{z}/{x}/{y}.png`,
`userAgentPackageName: 'de.bftag.app'`, `maxZoom 19`, dauerhaft sichtbare Attribution
„© OpenStreetMap-Mitwirkende“. Einsatz-Pin rot (`Icons.location_on`), Wache als eigenes Symbol
(`Icons.home`). Mit Wache passt die Kamera beide Punkte ein (max. Zoom 16), ohne Wache zeigt sie
nur den Einsatz-Pin (Zoom 15). Der `TileProvider` ist injizierbar, damit Widget-Tests ohne Netz
laufen. Kein Routing, kein API-Key.

- **Monitor-Einsatzansicht:** mit Koordinaten erscheint die Karte neben bzw. unter dem
  Meldebild, nicht interaktiv; ohne Koordinaten bleibt die Ansicht unverändert.
- **Web-Einsatzformular:** Adresssuche über `GET /geocode` (Button „Suchen“, Vorschläge als
  Liste; Auswahl setzt den Pin und zentriert die Karte, überschreibt aber nicht das
  Adress-Textfeld — der Pin ist nur ein Vorschlag), Klick auf die Karte setzt/versetzt den Pin,
  Button „Pin entfernen“. Startansicht ohne Pin: Wache (Zoom 13) sofern konfiguriert, sonst
  Mitte Deutschland.
- **App (Alarm-Screen, Einsatzdetail):** kleine Karte (Höhe ca. 180) wenn Koordinaten
  vorhanden, darunter Button „Navigation starten“. URI über die reine Funktion
  `navigationUri(lat, lng, platform)`: Android `geo:<lat>,<lng>?q=<lat>,<lng>`, iOS
  `https://maps.apple.com/?daddr=<lat>,<lng>`; Start über `url_launcher`
  (`LaunchMode.externalApplication`). Das Android-Manifest deklariert `<queries>` für
  `geo`-Intents.

## Gemeinsamer Code (`packages/core`)

- API-Wrapper mit Token-Refresh (dio-Interceptor)
- `RealtimeClient`: WebSocket, Heartbeat, Reconnect, `seq`-Prüfung, Snapshot-Reload
- Riverpod-Provider pro Glossar-Begriff (`incidentsProvider`, `vehiclesProvider`, `currentShiftProvider` …)
- Domain-Typen im Glossar-Vokabular: `FmsStatus`, `Permission`, `PersonType`, `IncidentState`, `AlarmState`
- Theme (Feuerwehr-Rot, hoher Kontrast für den Monitor)
