# 06 – Clients

Alle Clients sind Flutter-Apps und teilen sich `packages/core` und `packages/api_client`.

## Admin (`apps/web`, Route `/admin`)

Zielgerät: Laptop der Leitstelle, Desktop-Browser (Chrome/Edge/Firefox).

| Screen | Inhalt |
|--------|--------|
| Login | Benutzername, Passwort |
| Lage (Startseite) | aktive Einsätze, Fahrzeugstatus-Leiste, nächste geplante Alarme, Rückmeldungen live |
| Einsätze | Liste mit Filter (Entwurf / geplant / laufend / abgeschlossen) |
| Einsatz bearbeiten | Stichwort, Adresse, Meldebild, Fahrzeuge auswählen, „Jetzt alarmieren“, „Planen für …“ |
| Fahrzeuge | Liste, Bearbeiten, Besatzung zuordnen (Drag & Drop) |
| Mitglieder | Liste, Rolle, Geräte, „QR-Code erzeugen“ (druckbar) |
| Monitore | Liste, Kopplungscode erzeugen, sperren |
| Folien | Standby-Folien pflegen, Reihenfolge, Vorschau |

Tastenkürzel für die Leitstelle (später): `N` neuer Einsatz, `A` alarmieren.

## Monitor (`apps/web`, Route `/monitor`)

Zielgerät: Fernseher mit Fire-TV-Stick, Mini-PC oder Tablet; Browser im Vollbild/Kiosk-Modus.

Layout im **Einsatzfall**:

```
┌──────────────────────────────────────────────────────────┐
│ EINSATZ 7                                  18:12:03      │
│ B2 – WOHNUNGSBRAND                         seit 02:41    │
│ Musterstraße 1, Musterstadt                              │
├──────────────────────────────────┬───────────────────────┤
│ Meldebild:                       │ Rückmeldungen         │
│ Rauchentwicklung aus Fenster     │ ✓ Max M.   ✓ Lea K.   │
│ 2. OG, Person vermisst           │ ✓ Tim S.   ✗ Ben R.   │
├──────────────────────────────────┴───────────────────────┤
│ HLF 1 [3]   DLK [3]   RTW [2]   ELW [1]   MTW [6]        │
└──────────────────────────────────────────────────────────┘
```

Layout im **Standby**: große Uhr, Fahrzeugstatus-Leiste, rotierende Folien.

- Bei `incident.alarmed`: Gong/Alarmton abspielen (der Browser verlangt dafür eine einmalige
  Interaktion nach dem Laden, deshalb zeigt der Monitor beim Start „Zum Aktivieren tippen“).
- Wake Lock (Screen Wake Lock API), damit der Bildschirm nicht ausgeht.
- Bei Verbindungsverlust: deutlich sichtbares rotes Banner.
- Mehrere aktive Einsätze: Split-Ansicht oder Rotation.

## Mobile-App (`apps/mobile`)

Zielgeräte: Android 8+ (API 26), iOS 16+.

| Screen | Inhalt |
|--------|--------|
| Onboarding | QR-Code scannen oder Code eintippen → Berechtigungen (Push, DND, Akku) → Testalarm |
| Alarm (Vollbild in der App) | Stichwort, Adresse, Meldebild, große Buttons „Komme“ / „Komme nicht“ |
| Einsätze | laufende und vergangene Einsätze |
| Einsatzdetail | alles zum Einsatz, Rückmeldungen der anderen, alarmierte Fahrzeuge |
| Fahrzeug | eigenes Fahrzeug, FMS-Tasten 1–8 (groß, Funkgerät-Optik) |
| Einstellungen | Gerät abmelden, Testalarm, Hinweise zu Akku/Ton |

### Technik

- Push: `firebase_messaging` (nur Android) und ein APNs-Token über das native iOS-API
  (z. B. per Platform-Channel oder Paket `flutter_apns_only`). Alternative: `firebase_messaging`
  auch auf iOS, siehe ADR 0003.
- Lokale Darstellung bzw. Channel-Setup: `flutter_local_notifications`
- Token-Speicherung: `flutter_secure_storage`
- QR-Scan: `mobile_scanner`
- Deep Link aus der Notification direkt auf den Alarm-Screen

## Gemeinsamer Code (`packages/core`)

- `ApiClient`-Wrapper mit Token-Refresh (dio-Interceptor)
- `RealtimeClient`: WebSocket, Heartbeat, Reconnect mit Backoff, `seq`-Prüfung, Snapshot-Reload
- Riverpod-Provider: `incidentsProvider`, `vehiclesProvider`, `sessionProvider` …
- Domain: `FmsStatus` (mit Farbe, Text, Kurztext), `Role`, `IncidentState`
- Einheitliches Theme (Feuerwehr-Rot, hoher Kontrast für den Monitor)
