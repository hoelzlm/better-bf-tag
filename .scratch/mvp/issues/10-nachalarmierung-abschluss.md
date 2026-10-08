# 10 — Nachalarmierung und Abschluss des Einsatzes

**What to build:** Bei einem laufenden Einsatz löst die Leitstelle spontan eine Nachalarmierung mit weiteren Fahrzeugen aus. Wenn alle alarmierten Fahrzeuge wieder Status 1 oder 2 melden, schlägt das System den Abschluss vor, und die Leitstelle schließt den Einsatz. Der Monitor rotiert bei mehreren laufenden Einsätzen.

**Blocked by:** 08

**Status:** ready-for-agent

- [ ] Nachalarmierung für laufende Einsätze; Personen, die schon Empfänger einer früheren Alarmierung desselben Einsatzes sind, bekommen keinen erneuten Alarm/Push
- [ ] Erstalarm/Nachalarmierung werden aus der Reihenfolge abgeleitet und so angezeigt
- [ ] Abschlussvorschlag (`incident.close_suggested`), sobald alle Fahrzeuge aller ausgelösten Alarmierungen Status 1/2 haben und keine Alarmierung mehr geplant ist
- [ ] Einsatz schließen (`incident.closed`); Monitor kehrt in den Standby zurück, wenn kein Einsatz mehr läuft
- [ ] Monitor rotiert bei mehreren laufenden Einsätzen
- [ ] Tests: kein doppelter Alarm bei Nachalarmierung, Abschlussvorschlag erscheint/erscheint nicht, Schließen nur durch Leitstelle/Admin, geschlossene Einsätze nicht mehr alarmierbar

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
