# 11 — Zeitgesteuerte Alarmierung und verpasste Alarmierung

**What to build:** Die Leitstelle plant Alarmierungen mit Zeitpunkt, auch Nachalarmierungen relativ zum Erstalarm. Sie lösen pünktlich automatisch aus, überstehen einen Server-Neustart und werden als verpasst angezeigt statt ausgelöst, wenn sie mehr als 10 Minuten überfällig sind.

**Blocked by:** 10

**Status:** ready-for-agent

- [ ] Alarmierung mit Zeitpunkt planen; Nachalarmierung relativ zum Erstalarm planen (z. B. +8 min)
- [ ] Persistente Job-Queue in PostgreSQL; Singleton pro Alarmierung; Zeit oder Fahrzeuge ändern ersetzt den Job
- [ ] Geplante Alarmierung verwerfen; beim Schließen/Verwerfen des Einsatzes werden geplante Alarmierungen verworfen (mit Warnung im UI)
- [ ] Nach Neustart: überfällige Jobs laufen nach; > 10 min überfällig → Zustand verpasst, Event `alarm.missed`
- [ ] Lage zeigt nächste geplante und verpasste Alarmierungen; verpasste manuell auslösen oder verwerfen
- [ ] Events `alarm.planned`, `alarm.discarded`
- [ ] Tests (steuerbare Uhr): Auslösen zum Zeitpunkt, relative Nachalarmierung, Neustart mit 5 und mit 15 min Verspätung, Verwerfen beim Schließen, Abschlussvorschlag erst ohne geplante Alarmierung

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
