# v2-01 — Durchsage

**What to build:** Die Leitstelle schickt Durchsagen an alle oder an eine Schicht. Sie erscheinen in der App (Benachrichtigung ohne Alarmton + Liste) und als Banner auf dem Monitor. Details und Entscheidungen: `.scratch/v2/spec.md` Abschnitt „Durchsage“.

**Blocked by:** MVP-Ticket 18

**Status:** done

- [x] Migration `announcement` (`bf_day_id`, `shift_id null`, `text`, `created_by`, `created_at`), Drizzle-Schema
- [x] Routen `POST/GET /bf-days/{day}/announcements`, `DELETE /announcements/{id}` mit Berechtigungen und Zustandsprüfung
- [x] Sichtbarkeit nach Schicht in Routen, Snapshot (`announcements`, letzte 20) und WebSocket (`skip` für Unbeteiligte)
- [x] Events `announcement.created` / `announcement.deleted`
- [x] Push über eigenen Durchsage-Channel (Android) bzw. ohne `time-sensitive` (iOS), nicht blockierend
- [x] Anonymisierung löscht Durchsagen, Preview/Summary erweitert
- [x] Web: Durchsage-Seite für Leitstelle (Text, Zielgruppe alle/Schicht, Liste, Löschen)
- [x] Monitor: Banner 60 s, danach „Letzte Durchsage“ im Standby; Einsatzansicht hat Vorrang
- [x] App: Benachrichtigung + Liste „Durchsagen“; Android-Notification-Channel anlegen
- [x] `just gen-api`, Doku (`04-api`, `03-datenmodell`, `06-clients`, `05-alarmierung-push`), E2E-Schritt
- [x] Tests laut Spec „Testing Decisions“

Spec: `.scratch/v2/spec.md` · Glossar: `CONTEXT.md`
