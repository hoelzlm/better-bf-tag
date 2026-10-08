# 03 — Monitor koppeln, Standby mit Uhr und Fahrzeugstatus

**What to build:** Der Administrator legt einen Monitor an und erzeugt einen Kopplungscode. Am Fernseher wird `/monitor` geöffnet, der Code eingegeben, und der Monitor bleibt dauerhaft angemeldet. Im Standby zeigt er eine große Uhr und die Fahrzeugstatus-Leiste live.

**Blocked by:** 02

**Status:** done

- [x] Monitor anlegen, Kopplungscode (24 h, einmalig) erzeugen, Monitor sperren
- [x] Kopplung liefert ein langlebiges, rotierendes Refresh-Token; ein Monitor darf nur lesen
- [x] Ein gesperrter Monitor bekommt sofort `session.revoked` und zeigt wieder den Kopplungs-Screen
- [x] Standby: große Uhr, Fahrzeugstatus-Leiste live, hoher Kontrast
- [x] Rotes Warnbanner bei Verbindungsverlust, automatischer Reconnect
- [x] Screen Wake Lock; „Zum Aktivieren tippen“ beim Start (für späteren Ton)
- [x] Tests: Kopplung, Code nur einmal einlösbar, abgelaufener Code (steuerbare Uhr), Monitor kann nichts schreiben, Sperre

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
