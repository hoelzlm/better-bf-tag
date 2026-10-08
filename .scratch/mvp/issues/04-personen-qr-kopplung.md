# 04 — Personen anlegen, Handy per QR-Code koppeln

**What to build:** Der Administrator legt Personen an und druckt eine Liste mit QR-Codes. Eine Person scannt ihren QR-Code mit der neuen Mobile-App und ist danach angemeldet („Hallo Max M.“). Der Administrator sieht die Geräte jeder Person und kann sie sperren.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Personen anlegen, bearbeiten, deaktivieren: Anzeigename, Personentyp (Jugendlicher/Betreuer), Berechtigung (Mannschaft/Einsatzvorbereitung/Leitstelle/Administrator)
- [ ] Berechtigung Administrator nur bei Personentyp Betreuer (serverseitig erzwungen)
- [ ] Web-Zugang (Benutzername + Passwort) für Einsatzvorbereitung, Leitstelle und Administrator vergeben
- [ ] Kopplungscode pro Person (QR + 8 Zeichen, 24 h, einmalig) und druckbare Liste für alle Personen
- [ ] Mobile-App-Gerüst (iOS + Android) im Monorepo: QR-Scan oder Code abtippen, Tokens im Secure Storage, Startscreen mit Anzeigename
- [ ] Geräteliste pro Person; Gerät sperren führt sofort zu `session.revoked`, die App zeigt wieder die Kopplung
- [ ] Einstellungen in der App: Gerät abmelden
- [ ] Tests: Berechtigungsregel Administrator/Betreuer, Kopplung, Code-Wiederverwendung, Sperre, Abmelden, Login nur mit Web-Berechtigung

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
