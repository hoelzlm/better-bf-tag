# 11 — Zeitgesteuerte Alarmierung und verpasste Alarmierung

**What to build:** Die Leitstelle plant Alarmierungen mit Zeitpunkt, auch Nachalarmierungen relativ zum Erstalarm. Sie lösen pünktlich automatisch aus, überstehen einen Server-Neustart und werden als verpasst angezeigt statt ausgelöst, wenn sie mehr als 10 Minuten überfällig sind.

**Blocked by:** 10

**Status:** done

- [x] Alarmierung mit Zeitpunkt planen; Nachalarmierung relativ zum Erstalarm planen (z. B. +8 min)
- [x] Persistente Job-Queue in PostgreSQL; Singleton pro Alarmierung; Zeit oder Fahrzeuge ändern ersetzt den Job
- [x] Geplante Alarmierung verwerfen; beim Schließen/Verwerfen des Einsatzes werden geplante Alarmierungen verworfen (mit Warnung im UI)
- [x] Nach Neustart: überfällige Jobs laufen nach; > 10 min überfällig → Zustand verpasst, Event `alarm.missed`
- [x] Lage zeigt nächste geplante und verpasste Alarmierungen; verpasste manuell auslösen oder verwerfen
- [x] Events `alarm.planned`, `alarm.discarded`
- [x] Tests (steuerbare Uhr): Auslösen zum Zeitpunkt, relative Nachalarmierung, Neustart mit 5 und mit 15 min Verspätung, Verwerfen beim Schließen, Abschlussvorschlag erst ohne geplante Alarmierung

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
