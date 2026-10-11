# 05 – Alarmierung und Push

Fachbegriffe: [CONTEXT.md](../CONTEXT.md) (Alarmierung, Erstalarm, Nachalarmierung, Quittierung, Besatzung).

## Ablauf einer Alarmierung

```mermaid
sequenceDiagram
    participant L as Leitstelle
    participant S as Scheduler
    participant B as Backend
    participant DB as PostgreSQL
    participant F as FCM / APNs
    participant H as Handy
    participant M as Monitor

    alt sofort
        L->>B: POST /incidents/{id}/alarms (ohne scheduled_at)
    else zeitgesteuert
        S->>B: Job "trigger-alarm" fällig
    end
    B->>DB: alarm.state=triggered, Empfänger aus Besatzung der aktiven Schicht einfrieren,<br/>Einsatz draft→running (beim Erstalarm), alles in einer Transaktion
    B-->>M: WS alarm.triggered
    B-->>H: WS alarm.triggered (falls App offen)
    B->>F: Push an alle Geräte der Empfänger
    F->>H: Notification (Alarmton)
    H->>B: POST /alarms/{id}/acknowledge
    B-->>M: WS alarm.acknowledged
    H->>B: PUT /vehicles/{id}/status (3 = ausgerückt)
```

### Empfänger

- Empfänger sind alle Personen, die in der **zum Auslösezeitpunkt aktiven Schicht** einem der
  alarmierten Fahrzeuge zugeordnet sind. Sie werden in `alarm_recipient` eingefroren.
- Steht eine Person in derselben Schicht auf mehreren alarmierten Fahrzeugen, bekommt sie einen
  Push. Die Leitstelle erhält eine Warnung, dass die Person doppelt besetzt ist.
- Bei einer **Nachalarmierung** werden nur die neuen Fahrzeuge alarmiert. Personen, die schon
  im Einsatz sind, bekommen keinen zweiten Alarm.

### Idempotenz

Eine Alarmierung wechselt nur `planned → triggered` per
`UPDATE alarm SET state='triggered' … WHERE id=$1 AND state='planned' RETURNING …`. Eine sofortige
Alarmierung wird direkt als `triggered` angelegt. Doppelklick oder Scheduler-Retry lösen so keinen
zweiten Alarm aus. Der Einsatz wechselt `draft → running` mit derselben Bedingung.

### Zeitgesteuerte Alarmierungen

- Eine geplante Alarmierung legt einen Job mit `start_after = scheduled_at` und dem Singleton-Key
  `alarm:<id>` an. Wird der Zeitpunkt geändert, wird der Job ersetzt.
- Verwerfen (manuell oder durch Schließen bzw. Verwerfen des Einsatzes) löscht den Job.
- Nach einem Server-Neustart laufen überfällige Jobs sofort nach. Ist eine Alarmierung mehr als
  **10 Minuten** überfällig, wird sie **nicht** ausgelöst, sondern als `missed` (verpasst)
  markiert. Die Leitstelle entscheidet dann selbst.
- Später: Die **Vorwarnung** ist ein zweiter Job bei `scheduled_at − prewarning_minutes`. Er
  schickt einen normalen Push ohne Alarmton an die Einsatzvorbereitung.

### Quittierung

Die Leitstelle sieht pro Empfänger drei Zustände:

| Zustand | Bedeutung |
|---------|-----------|
| quittiert | Person hat den Alarm bestätigt |
| ausstehend | Gerät vorhanden, noch keine Quittierung, also prüfen, ob das Handy stumm ist |
| kein Gerät | Person hat kein gekoppeltes Gerät; wird über Monitor und Gong alarmiert, zählt nicht als fehlend |

Eine Zu- oder Absage gibt es nicht ([ADR 0006](adr/0006-quittierung-statt-rueckmeldung.md)).
Das Ausrücken bestätigt der Fahrzeugstatus 3.

## Push-Zustellung

Entscheidung: [ADR 0003](adr/0003-push.md)

| Plattform | Weg | Credentials |
|-----------|-----|-------------|
| Android | FCM HTTP v1 API | Service-Account-JSON eines Firebase-Projekts (nur Messaging) |
| iOS | APNs direkt (HTTP/2, Token-Auth) | `.p8`-Key, Key-ID, Team-ID, Bundle-ID |

Ohne FCM geht es auf Android praktisch nicht: Nur FCM kann eine App zuverlässig aus dem
Hintergrund bzw. Doze-Modus wecken. Firebase dient hier **ausschließlich** als Push-Transport,
es speichert keine Daten von uns.

### Payload (datensparsam)

Im Push stehen nur Stichwort und Adresse aus dem Meldebild sowie die IDs. Keine Namen von Personen, **nie das Drehbuch**.

**Android (FCM, data + notification, Priorität `high`):**

```json
{
  "message": {
    "token": "<fcm-token>",
    "android": {
      "priority": "high",
      "ttl": "300s",
      "notification": {
        "channel_id": "alarm",
        "sound": "alarm",
        "tag": "incident-<id>"
      }
    },
    "notification": { "title": "B2 – Wohnungsbrand", "body": "Musterstraße 1" },
    "data": { "type": "alarm.triggered", "incident_id": "<id>", "alarm_id": "<id>" }
  }
}
```

**iOS (APNs):**

```json
{
  "aps": {
    "alert": { "title": "B2 – Wohnungsbrand", "body": "Musterstraße 1" },
    "sound": "alarm.wav",
    "interruption-level": "time-sensitive",
    "thread-id": "incident-<id>"
  },
  "incident_id": "<id>",
  "alarm_id": "<id>"
}
```

Header: `apns-push-type: alert`, `apns-priority: 10`, `apns-expiration: now+300`.

### Ungültige Tokens

- FCM antwortet mit `UNREGISTERED` bzw. `INVALID_ARGUMENT`, APNs mit `410 Unregistered` bzw.
  `BadDeviceToken`. Dann `device.push_token = null` setzen.
- Die App sendet bei jedem Start und bei `onTokenRefresh` ihr aktuelles Token per
  `PUT /me/device/push-token`.

## Durchsage-Push

Entscheidung: [ADR 0024](adr/0024-durchsage.md), Abschnitt „Push“.

Eine Durchsage (`POST /bf-days/{day}/announcements`) löst nach dem Commit einen eigenen, von der
Alarmierung unabhängigen Push aus — fire-and-forget (`void dispatchAnnouncementPushes(...).catch(log.warn)`
in `backend/src/push/announcement-push.ts`): die Antwort der Route wartet nicht auf den Push und
schlägt nie wegen eines Push-Fehlers fehl, selbst wenn der `PushSender` wirft oder einen Timeout
auslöst (10 s, wie bei der Alarmierung).

Empfänger: aktive Personen mit Teilnahme am BF-Tag, die die Durchsage sehen dürfen
(`shift_id = null` → alle; sonst nur die Besatzung dieser Schicht sowie Personen mit Berechtigung
`preparation`/`dispatch`/`admin`), mit nicht widerrufenem Gerät und gesetztem Push-Token, **ohne**
den Absender selbst.

Im Unterschied zur Alarmierung ist eine Durchsage **nicht zeitkritisch**: kein eigener Alarmton,
kein Vollbild, auf iOS ausdrücklich **ohne** Time Sensitive (`interruption-level`). Android nutzt
einen eigenen Channel `announcement` mit Standard-Ton statt `alarm`.

**Android (FCM):**

```json
{
  "message": {
    "token": "<fcm-token>",
    "android": {
      "priority": "normal",
      "ttl": "3600s",
      "notification": { "channel_id": "announcement", "tag": "announcement-<id>" }
    },
    "notification": { "title": "Durchsage", "body": "<text>" },
    "data": { "type": "announcement.created", "announcement_id": "<id>", "bf_day_id": "<id>" }
  }
}
```

**iOS (APNs):**

```json
{
  "aps": { "alert": { "title": "Durchsage", "body": "<text>" }, "sound": "default" },
  "type": "announcement.created",
  "announcement_id": "<id>",
  "bf_day_id": "<id>"
}
```

Header: `apns-push-type: alert`, `apns-priority: 5` (im Gegensatz zur `10` der Alarmierung).

Ungültige Tokens werden wie bei der Alarmierung behandelt (`device.push_token = null`); es gibt
kein `announcement.push_reported`-Gegenstück zu `alarm.push_reported` — der Push ist reine
Zustellung ohne Zähler in der API.

## Alarmton und Plattform-Einschränkungen

### Android

- Eigener **Notification Channel** `alarm` mit Importance `HIGH`, eigenem Sound
  (`res/raw/alarm.wav`) und Vibrationsmuster. Achtung: Sound und Importance eines Channels lassen
  sich nach dem Anlegen nicht mehr per Code ändern. Bei Änderungen eine neue Channel-ID wählen.
- **Nicht stören:** Ein Channel darf DND nur umgehen, wenn der Nutzer das erlaubt. Die App führt
  beim Onboarding in die Einstellungen (Benachrichtigungsrichtlinie / Channel-Einstellungen).
- **Full-Screen-Intent** (Alarm-Vollbild auf dem Sperrbildschirm): Ab Android 14 ist
  `USE_FULL_SCREEN_INTENT` für Play-Store-Apps auf Anruf- und Wecker-Apps beschränkt. Wir planen
  deshalb ohne ihn: Heads-up-Notification mit Alarmton. Die aktuelle Play-Richtlinie vor dem
  Release prüfen.
- **Akku-Optimierung:** Manche Hersteller (Xiaomi, Huawei, Samsung) beenden Hintergrund-Apps
  aggressiv. Im Onboarding auf das Abschalten der Akku-Optimierung hinweisen
  (Verweis auf dontkillmyapp.com).
- Android 13+: Laufzeit-Berechtigung `POST_NOTIFICATIONS` anfragen.

### iOS

- **Critical Alerts** (klingeln auch bei Stummschaltung) brauchen ein Sonder-Entitlement von
  Apple. Für eine Übungs-App wird das sehr wahrscheinlich nicht genehmigt, daher nicht eingeplant.
- **Time Sensitive Notifications** (Capability in Xcode aktivieren) durchbrechen Fokus-Modi,
  sofern der Nutzer das zulässt. Der Stummschalter wird aber respektiert.
- Eigener Sound als `alarm.wav` im App-Bundle (`ios/Runner/alarm.wav`), maximal 30 Sekunden.
- Hinweis an die Teilnehmer: Handy beim BF-Tag **nicht stumm** schalten.

Beide Sounddateien sind dieselbe ~10 s lange, synthetische Fassung des Alarmtons (ADR 0018,
reproduzierbar via `tool/make_alarm.py`) -- weicht damit vom ursprünglich geplanten
`alarm.ogg`/`alarm.caf` ab, da Android `res/raw` und iOS beide WAV/Linear PCM annehmen.

Android-FCM ist ohne die vier `FCM_*` `--dart-define`s (`FCM_API_KEY`, `FCM_APP_ID`,
`FCM_SENDER_ID`, `FCM_PROJECT_ID`) deaktiviert -- die App und CI bauen ohne sie normal, nur Push
ist dann aus. Es gibt kein `google-services.json` und kein
`com.google.gms.google-services`-Gradle-Plugin im Repo.

## Fallback

- Ist die App im Vordergrund, kommt der Alarm über den WebSocket. Die App spielt dann selbst den
  Alarmton und zeigt das Alarm-Overlay.
- Der Monitor in der Halle ist die zweite, unabhängige Alarmierung (Ton über die Lautsprecher
  des Fernsehers).
- Bei der Leitstelle ist pro Alarmierung sichtbar, wie viele Pushes zugestellt bzw. abgelehnt
  wurden und wer quittiert hat.
