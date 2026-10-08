# apps/mobile

Flutter-App für iOS und Android für Jugendfeuerwehrangehörige (Personen):
QR/Code-Kopplung an ein Gerät (Geräte-Sitzung, ADR 0010), Start-Screen mit
„Hallo <Anzeigename>“, Einstellungen mit „Gerät abmelden“.

- Funktionen und Screens: [docs/06-clients.md](../../docs/06-clients.md#mobile-app-appsmobile)
- Gerätekopplung: [docs/adr/0010-personen-kopplung-geraete.md](../../docs/adr/0010-personen-kopplung-geraete.md)
- Client-Protokoll (Realtime): [docs/adr/0009](../../docs/adr/)
- Push und Alarmton: [docs/05-alarmierung-push.md](../../docs/05-alarmierung-push.md)
- Store-Release: [docs/08-store-release.md](../../docs/08-store-release.md)

## Lokal starten

```sh
just mobile
# entspricht: cd apps/mobile && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

`10.0.2.2` ist die Android-Emulator-Adresse für den Host-Rechner; auf einem
echten Gerät/iOS-Simulator stattdessen die lokale Netzwerk-IP des Backends
verwenden.

## Architektur

- `bftag_core` (packages/core) stellt `PairedSessionController` (Pairing,
  Refresh, Logout, `session.revoked`), `RealtimeClient` und den Dio/Auth-
  Interceptor bereit.
- `SecureTokenStore` (hier) persistiert Refresh-Token + Device-ID über
  `flutter_secure_storage` (iOS Keychain / Android Keystore).
- Router: `PairedUnknown` → Splash, `PairedUnpaired`/`PairedOffline` →
  `/pair`, `Paired` → `/` (Start).
- Der QR-Scanner (`mobile_scanner`) läuft hinter `qrScannerBuilderProvider`,
  damit Widget-Tests ohne Kamera laufen.
