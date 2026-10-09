# 09 — Push-Alarm auf Android und iOS

**What to build:** Bei einer Alarmierung bekommen alle Empfänger mit Gerät einen Push mit Alarmton, auch wenn die App geschlossen ist. Antippen öffnet direkt den Alarm-Screen. Die Leitstelle sieht, wie viele Pushes zugestellt bzw. abgelehnt wurden.

**Blocked by:** 08

**Status:** done

- [x] App registriert ihr Push-Token bei jedem Start und bei Token-Refresh (FCM auf Android, natives APNs-Token auf iOS)
- [x] Push-Schnittstelle im Backend mit Implementierungen für FCM HTTP v1 und APNs (Token-Auth) sowie dem Fake für Tests
- [x] Android: Notification Channel `alarm` mit eigenem Sound und Vibration, Priorität high, TTL 300 s; Laufzeitberechtigung für Benachrichtigungen
- [x] iOS: Time Sensitive Notifications, eigener Sound (≤ 30 s), APNs-Priorität 10
- [x] Push-Inhalt nur Stichwort, Adresse, `incident_id`, `alarm_id`; nie Namen oder Drehbuch
- [x] Deep Link aus der Benachrichtigung auf den Alarm-Screen
- [x] Ungültige Tokens (FCM UNREGISTERED, APNs 410/BadDeviceToken) werden entfernt
- [x] Lage zeigt zugestellte/abgelehnte Pushes je Alarmierung
- [x] Tests (mit Push-Fake): richtige Geräte erhalten genau einen Push, Inhalt ohne Drehbuch/Namen, ungültiges Token wird entfernt, gesperrte Geräte erhalten nichts

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
