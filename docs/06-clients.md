# 06 – Clients

Alle Clients sind Flutter-Apps und teilen sich `packages/core` und `packages/api_client`.
Fachbegriffe: [CONTEXT.md](../CONTEXT.md). Welche Berechtigung was darf: [04 – API](04-api.md#berechtigungen).

## Web (`apps/web`, Route `/admin`)

Zielgerät: Laptop bzw. Desktop-Browser. Was sichtbar ist, hängt von der Berechtigung ab.

| Screen | Berechtigung | Inhalt | Phase |
|--------|--------------|--------|-------|
| Login | – | Benutzername, Passwort | MVP |
| Lage (Startseite Leitstelle) | Leitstelle | laufende Einsätze, Fahrzeugstatus-Leiste, nächste geplante Alarmierungen, Quittierungen live (quittiert / ausstehend / kein Gerät), verpasste Alarmierungen, Abschlussvorschläge | MVP |
| Einsätze | Einsatzvorbereitung, Leitstelle | Liste je BF-Tag, Filter Entwurf/laufend/abgeschlossen | MVP |
| Einsatz bearbeiten | Einsatzvorbereitung, Leitstelle | Meldebild, Drehbuch (deutlich als „geheim“ markiert), Alarmierungen anlegen: Fahrzeuge + „sofort“ oder Zeitpunkt; Nachalarmierungen relativ zum Erstalarm planen | MVP |
| Schichten | Leitstelle | Schichten des BF-Tags, Besatzung per Drag & Drop (Person → Fahrzeug + Funktion), Warnung bei Doppelbesetzung | MVP |
| Anstehende Einsätze | Einsatzvorbereitung | Countdown bis zur geplanten Alarmierung, Drehbuch, Button „Bereitmeldung“ | später |
| Einsatzberichte | Leitstelle | eingereichte Berichte, Vergleich mit Drehbuch, freigeben/zurückgeben | später |
| Durchsage (`/admin/durchsagen`) | Leitstelle, Administrator | Formular: Text (max. 500 Zeichen, Zähler), Ziel „Alle“ oder Schicht des laufenden BF-Tags, „Senden“; Liste der Durchsagen des Tags (neueste zuerst, Uhrzeit, Ziel, Text), Löschen mit Rückfrage; ohne laufenden BF-Tag Hinweis „Kein laufender BF-Tag“ und deaktiviertes Formular | MVP |
| Tagesablauf (`/admin/tagesablauf`) | Leitstelle, Administrator | BF-Tag-Auswahl (Standard: laufend, sonst nächster geplanter, sonst letzter) wie bei Schichten; Liste der Programmpunkte nach Zeit (`HH:mm–HH:mm`, Typ-Icon + Label, Titel); Anlegen/Bearbeiten (Titel 1–80 Zeichen, Typ, Start/Ende)/Löschen mit Rückfrage; bei beendetem BF-Tag nur lesend | MVP |
| BF-Tage | Administrator | anlegen, Zeitraum, Teilnahmen, Anonymisierung | MVP |
| Personen | Administrator | Personentyp, Berechtigung, Feuerwehr, Geräte, QR-Codes drucken | MVP |
| Fahrzeuge | Administrator | Stammdaten, Sortierung | MVP |
| Feuerwehren | Administrator | weitere Feuerwehren | später |
| Monitore, Folien | Administrator | Kopplung, Standby-Folien | MVP |

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

Im **Standby**:
- MVP: große Uhr, Fahrzeugstatus-Leiste, **aktuelle Schicht mit Besatzungen** (wer sitzt auf
  welchem Fahrzeug), rotierende Folien
- MVP: Banner bei neuer Durchsage (`announcement.created`, 60 s, zeigt den Text; verschwindet
  sofort bei Löschung), danach Panel „Letzte Durchsage“ mit der neuesten Durchsage des Tags
  (Uhrzeit + Text) aus `snapshot.announcements`, leer wenn keine vorhanden; läuft ein Einsatz
  (Einsatzansicht), hat diese immer Vorrang – Banner und Panel werden dann nicht angezeigt
- MVP: Block „Jetzt“ / „Danach“ (ADR 0025) aus `snapshot.program_items` bzw. `program.changed`,
  Anzeige über `currentAndNext(programItems, now)` (`now` aus `monitorClockProvider`, rein
  zeitgesteuert – kein Event nötig, um von einem Programmpunkt zum nächsten zu wechseln); je
  Zeile `HH:mm–HH:mm  Titel` (Lokalzeit), fehlt „Jetzt“ oder „Danach“ wird die Zeile weggelassen;
  ohne Programmpunkte ist der Block ganz unsichtbar; eine laufende Einsatzansicht hat weiterhin
  Vorrang (der Block erscheint nur im Standby)

Technik: Gong bzw. Alarmton bei `alarm.triggered` (der Browser verlangt einmal „Zum Aktivieren
tippen“), Screen Wake Lock, rotes Banner bei Verbindungsverlust, Rotation bei mehreren laufenden
Einsätzen.

## Mobile-App (`apps/mobile`)

Zielgeräte: Android 8+ (API 26), iOS 16+. Für alle Personen; Funktionen je nach Berechtigung.

| Screen | Inhalt | Phase |
|--------|--------|-------|
| Onboarding | QR-Code scannen → Berechtigungen (Push, Nicht-stören, Akku) → Testalarm | MVP |
| Alarm (Vollbild) | Stichwort, Adresse, Meldebild, alarmierte Fahrzeuge, großer Button **„Quittieren“** | MVP |
| Mein Fahrzeug | aktuelle Besatzung und Funktion, FMS-Tasten 1–8 (Funkgerät-Optik) | MVP |
| Einsätze | laufende und vergangene Einsätze des BF-Tags | MVP |
| Einsatzdetail | Meldebild, Alarmierungen, Quittierungen; Drehbuch nur bei Berechtigung | MVP |
| Einsatzbericht | für die Funktion GF nach Status 1/2: Lage, Maßnahmen, Vorkommnisse; Zeiten automatisch | später |
| Vorwarnung / Bereitmeldung | für Einsatzvorbereitung | später |
| Durchsagen (`/durchsagen`) | Liste aus `snapshot.announcements`, neueste zuerst; dritter Eintrag der Navigationsleiste | MVP |
| Tagesablauf (`/tagesablauf`) | Liste aus `snapshot.program_items` (laufender BF-Tag), aktuelle Punkte hervorgehoben, vergangene ausgegraut; vierter Eintrag der Navigationsleiste | MVP |
| Einstellungen | Gerät abmelden, Testalarm, Hinweise zu Akku und Ton | MVP |

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

## Gemeinsamer Code (`packages/core`)

- API-Wrapper mit Token-Refresh (dio-Interceptor)
- `RealtimeClient`: WebSocket, Heartbeat, Reconnect, `seq`-Prüfung, Snapshot-Reload
- Riverpod-Provider pro Glossar-Begriff (`incidentsProvider`, `vehiclesProvider`, `currentShiftProvider` …)
- Domain-Typen im Glossar-Vokabular: `FmsStatus`, `Permission`, `PersonType`, `IncidentState`, `AlarmState`
- Theme (Feuerwehr-Rot, hoher Kontrast für den Monitor)
