# ADR 0021 – App-Onboarding und Testalarm

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 14: Nach der Kopplung soll die App durch alle Einstellungen führen, die ein zuverlässiger
Alarm braucht, und einen Testalarm über den echten Push-Weg (ADR 0018) auslösen lassen. Offen
waren: API des Testalarms, wie er sich von einer Alarmierung unterscheidet, wie man den Ton bei
gesperrtem Bildschirm prüft (die App ist beim Antippen des Buttons im Vordergrund), wie die App
den Zustand der System-Einstellungen liest und wo „Onboarding erledigt“ gespeichert wird.

## Entscheidung

### Backend: `POST /me/device/test-alarm`

- Nur Geräte-Sitzungen (Access-Token mit `device_id`), sonst 403 `forbidden`.
- Body `{ delay_seconds?: integer 0–30 }`, Standard 0.
- Eigenes Gerät ohne `push_token`: 409 `no_push_token`.
- Läuft für dieses Gerät schon ein verzögerter Testalarm oder liegt der letzte Versand < 10 s
  zurück: 429 `test_alarm_cooldown`. (In-Memory pro Prozess, ein Backend-Prozess genügt.)
- `delay_seconds = 0`: sofort senden, Antwort 200 `{ outcome: delivered|rejected|invalid_token }`.
- `delay_seconds > 0`: 202 `{ scheduled: true }`; der Versand läuft per Timer im
  `TestAlarmScheduler` (`backend/src/push/test-alarm.ts`). Beim Auslösen wird das Gerät neu
  gelesen: gesperrt oder kein Token mehr ⇒ nichts senden. Timer werden beim Schließen der App
  (`onClose`) verworfen; ein Neustart verliert sie (unkritisch).
- Ziel ist **nur das aufrufende Gerät** – nicht weitere Geräte derselben Person.
- Kein Einsatz, keine Alarmierung, keine Zeile in einer Tabelle, kein `Realtime`-Event, keine
  `seq`. Einzige Schreiboperation: `invalid_token` ⇒ Token des Geräts löschen (wie ADR 0018).

### Push-Nachricht

`PushMessage.data` wird eine diskriminierte Union über `type`:

- `{ type: 'alarm.triggered', incident_id, alarm_id, keyword, address }` (bisher, unverändert im Inhalt)
- `{ type: 'test_alarm' }`

Testalarm-Payload: Titel „Testalarm“, Text „Wenn du das hörst, funktioniert der Alarm.“,
gleicher Kanal/Ton/Priorität wie der Alarm (Android `channel_id alarm`, `sound alarm`,
`tag test-alarm`, `data.type = test_alarm`; iOS `sound alarm.wav`,
`interruption-level time-sensitive`, `thread-id test-alarm`, `type: test_alarm`). Kein
`alarm_id` ⇒ Antippen öffnet keinen Alarm-Screen.

### App: Testalarm im Vordergrund

- `PushService` erhält `Stream<void> get onTestAlarmReceived`. Android: aus
  `FirebaseMessaging.onMessage` mit `data.type == 'test_alarm'`. iOS: `willPresent` zeigt
  `test_alarm` als Banner **mit Ton** (`.banner, .sound`) und meldet es zusätzlich über den
  Push-Channel an Dart. Die App zeigt dann „Testalarm empfangen“ und spielt auf Android den
  Alarmton (`AlarmSound`), weil FCM im Vordergrund nichts anzeigt.
- Zum Test bei gesperrtem Bildschirm bietet die App „Testalarm in 10 Sekunden“ (`delay_seconds: 10`)
  mit dem Hinweis, jetzt den Bildschirm zu sperren.

### App: System-Einstellungen

MethodChannel `de.bftag/device_settings` (Android `MainActivity.kt`, iOS `AppDelegate.swift`),
Dart-Schnittstelle `DeviceSettings` in `apps/mobile/lib/onboarding/device_settings.dart`:

| Methode | Android | iOS |
|---|---|---|
| `notificationsEnabled` → bool | `NotificationManagerCompat.areNotificationsEnabled` | `authorizationStatus == .authorized` |
| `bypassesDnd` → bool | Kanal `alarm`: `canBypassDnd()` | `timeSensitiveSetting == .enabled` |
| `batteryOptimizationIgnored` → bool | `PowerManager.isIgnoringBatteryOptimizations` | immer true |
| `manufacturer` → String | `Build.MANUFACTURER` | `"apple"` |
| `openNotificationSettings` | `ACTION_APP_NOTIFICATION_SETTINGS` | `openNotificationSettingsURLString` |
| `openDndSettings` | `ACTION_CHANNEL_NOTIFICATION_SETTINGS` (Kanal `alarm`) | wie oben |
| `requestIgnoreBatteryOptimization` | `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (+ Manifest-Permission) | no-op |

Eine App kann „Nicht stören überschreiben“ nicht selbst setzen; die Person schaltet es in den
Kanal-Einstellungen ein. Der Status wird bei `AppLifecycleState.resumed` neu gelesen.

### App: Onboarding

- Route `/onboarding`, Schritte: Benachrichtigungen → Nicht stören umgehen → Akku-Optimierung
  (nur Android, mit Hersteller-Hinweis) → „Nicht stumm schalten“ (nur iOS) → Testalarm → Fertig.
  Jeder Schritt zeigt den Status (✓/✗), eine Aktion und „Weiter“ (Überspringen erlaubt).
- Hersteller-Hinweise sind statischer Text je `manufacturer` (Samsung, Xiaomi/Redmi/POCO,
  Huawei/Honor, OnePlus/Oppo/Realme, Vivo, Sonstige) mit Verweis auf `dontkillmyapp.com`.
- „Erledigt“-Flag im Secure Storage (`OnboardingStore`), beim Abmelden gelöscht.
- Redirect: Gekoppelt, Flag nicht gesetzt und Ziel `/` oder `/pair` ⇒ `/onboarding`. Andere
  Ziele (v. a. `/alarm/:id`) werden nie umgeleitet.
- Einstellungen: „Einrichtung erneut öffnen“ und „Testalarm senden“.

## Konsequenzen

- Kein persistenter Zustand für Testalarme; Missbrauch ist durch Geräte-Sitzung + Cooldown begrenzt.
- Ob DND-Umgehung, Akku-Ausnahme und Ton wirklich greifen, ist nur auf echten Geräten prüfbar.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` ist im Play Store begründungspflichtig (Alarm-App –
  zulässiger Fall); Ticket 16 berücksichtigt das.
