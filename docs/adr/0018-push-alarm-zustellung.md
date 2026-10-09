# ADR 0018 – Push-Alarm: Token-Registrierung, Versand, Zählung, App-Anbindung

- **Status:** Angenommen
- **Datum:** 2026-10-09

## Kontext

Ticket 09 setzt ADR 0003 (FCM für Android, APNs direkt für iOS) und docs/05-alarmierung-push.md
um. Offen waren: wann und wie der Versand relativ zur Transaktion läuft, wo die Zählung
„zugestellt/abgelehnt“ liegt, wie Credentials konfiguriert werden, wie die App ohne
eingecheckte Firebase-Dateien baut und wie iOS ohne Firebase an sein Token kommt.

## Entscheidung

### Token-Registrierung: `PUT /me/device/push-token`

- Nur Geräte-Sitzungen (Access-Token mit `device_id`), sonst 403 `forbidden`.
- Body `{ token: string (1–4096) }` → 204. Setzt `device.push_token` des eigenen Geräts.
- Trägt ein **anderes** Gerät dasselbe Token (Neuinstallation, Gerät neu gekoppelt), wird es dort
  auf `null` gesetzt – ein Token gehört genau einem Gerät.
- Die App ruft das bei jedem Start (sobald die Geräte-Sitzung steht) und bei Token-Refresh auf.

### Versand

- Der Versand läuft **nach dem Commit** der Alarmierung, nie innerhalb von `Realtime.mutate`
  (kein externes HTTP unter dem Mutex). WebSocket-Events (Monitor, App im Vordergrund) gehen
  also nicht später raus als bisher.
- Modul `backend/src/push/alarm-push.ts`: `dispatchAlarmPushes(deps, alarmId)` – wiederverwendbar
  für Ticket 10 (Nachalarmierung) und 11 (Scheduler).
- Ziel-Geräte: alle `device` der Personen aus `alarm_recipient` dieser Alarmierung mit
  `revoked_at IS NULL`, `push_token IS NOT NULL` und aktiver Person. Ein Push pro Gerät; durch
  den PK von `alarm_recipient` bekommt auch eine doppelt besetzte Person nur einen.
- Inhalt (`PushMessage.data`): `keyword`, `address` (aus dem Einsatz), `incident_id`,
  `alarm_id`. Nie Namen, nie Drehbuch. Titel = Stichwort, Text = Adresse.
- Der Handler von `POST /incidents/{id}/alarms` wartet den Versand ab (alle Geräte parallel,
  Gesamt-Timeout 10 s; was bis dahin nicht geantwortet hat, zählt als `rejected`) und antwortet
  dann mit der neu geladenen Alarmierung (inkl. Zähler). Bei der idempotenten Wiederholung
  (200) wird **nicht** erneut gesendet.
- Ergebnis je Gerät (`PushResult.outcome`): `delivered`, `rejected`, `invalid_token`.
  `invalid_token` ⇒ `UPDATE device SET push_token = NULL WHERE id = $1 AND push_token = $token`.
  Eine Ausnahme des Senders zählt als `rejected` (geloggt).

### Zählung

- Neue Spalten `alarm.push_delivered int not null default 0`, `alarm.push_rejected int not null
  default 0` (`rejected` = `rejected` + `invalid_token`). Keine Tabelle pro Gerät (YAGNI).
- `Alarm`-JSON erhält `push_delivered`, `push_rejected` (überall, wo `Alarm` vorkommt).
- Nach dem Versand in einem eigenen `Realtime.mutate`: Zähler setzen und Event
  `alarm.push_reported` an **alle** mit Daten `{ alarm_id, incident_id, push_delivered,
  push_rejected }` (nur Zahlen, keine Personendaten).
- Die Lage zeigt je Alarmierung „Push: X zugestellt · Y abgelehnt“.

### Sender und Konfiguration

- Schnittstelle `PushSender` in `backend/src/push/push-sender.ts` bleibt unverändert.
- `FcmPushSender` (`fcm-sender.ts`): FCM HTTP v1 über `fetch`; OAuth2-Access-Token per
  Service-Account-JWT (RS256, `jose`), gecacht bis 5 min vor Ablauf. Android-Payload wie in
  docs/05 (`priority high`, `ttl 300s`, `channel_id alarm`, `sound alarm`, `tag incident-<id>`,
  `data.type = alarm.triggered`). `UNREGISTERED` (404) bzw. `INVALID_ARGUMENT` zum Token ⇒
  `invalid_token`; andere Fehler ⇒ `rejected`.
- `ApnsPushSender` (`apns-sender.ts`): HTTP/2 über `node:http2`, Token-Auth (ES256-JWT mit
  Key-ID/Team-ID, gecacht 50 min). Header `apns-push-type: alert`, `apns-priority: 10`,
  `apns-expiration: now+300`, `apns-topic: <bundle id>`. Payload wie docs/05 mit
  `"sound": "alarm.wav"`. `410` oder `400 BadDeviceToken` ⇒ `invalid_token`.
- `PlatformPushSender` verteilt nach `platform`. Ist eine Plattform nicht konfiguriert, liefert
  sie `rejected` (Warnung beim Start) – der bisherige `noopPushSender` („delivered“) entfällt
  im Server.
- Umgebungsvariablen (alle optional): `FCM_SERVICE_ACCOUNT_FILE` (Pfad zur JSON-Datei),
  `APNS_KEY_FILE` (Pfad zur `.p8`), `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_BUNDLE_ID`,
  `APNS_PRODUCTION` (bool, Standard false = Sandbox). Endpunkte sind für Tests per
  Konstruktor überschreibbar; die Sender werden gegen lokale Fake-Server getestet.

### App

- **Android:** `firebase_core` + `firebase_messaging`. Initialisierung **ohne**
  `google-services.json`/Gradle-Plugin: `Firebase.initializeApp(options: …)` aus
  `--dart-define`s `FCM_API_KEY`, `FCM_APP_ID`, `FCM_PROJECT_ID`, `FCM_SENDER_ID`. Fehlen sie,
  ist Push aus (App funktioniert sonst normal, CI baut ohne Secrets). Der Channel `alarm`
  (Importance HIGH, Sound `res/raw/alarm.wav`, Vibrationsmuster) wird nativ in
  `MainActivity.kt` angelegt; `POST_NOTIFICATIONS` über `requestPermission()`.
- **iOS:** kein Firebase. Eigener MethodChannel `de.bftag/push` in `AppDelegate.swift`:
  Berechtigung (`alert`, `sound`, `badge`), `registerForRemoteNotifications`, natives
  APNs-Token (hex) an Flutter, Antippen einer Benachrichtigung → `alarm_id` an Flutter
  (auch beim Kaltstart). Capability Push + Time Sensitive (`Runner.entitlements`), Sound
  `alarm.wav` im Bundle.
- Dart-Schnittstelle `PushService` in `apps/mobile/lib/push/` mit `FcmPushService`,
  `ApnsPushService`, `NoopPushService`; `PushRegistrar` registriert das Token und navigiert
  bei Antippen auf `/alarm/<alarm_id>`. Widget-Tests nutzen einen Fake.
- **Ton:** Eine ~10 s lange Fassung des synthetischen Alarmtons (`tool/make_alarm.py`), als
  WAV für beide Plattformen (Android `res/raw` und iOS akzeptieren WAV/Linear PCM; ≤ 30 s).
  Damit weicht der Dateiname von docs/05 (`alarm.ogg`/`alarm.caf`) ab; docs/05 wird angepasst.

## Konsequenzen

- Die Antwort auf „Alarmieren“ kommt bis zu 10 s später, wenn FCM/APNs hängen; der Alarm selbst
  (WS, Monitor) ist davon unberührt.
- Ticket 10/11 rufen `dispatchAlarmPushes` nur für neu ausgelöste Alarmierungen und
  Empfänger auf.
- Echte Zustellung (Firebase-Projekt, APNs-Key, Geräte) ist nur von Hand prüfbar.
