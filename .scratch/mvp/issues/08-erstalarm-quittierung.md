# 08 — Erstalarm sofort: Monitor, App im Vordergrund, Quittierung

**What to build:** Die Leitstelle löst für einen Einsatz sofort eine Alarmierung mit ausgewählten Fahrzeugen aus. Der Monitor springt mit Gong auf die Einsatzansicht, die geöffnete App zeigt das Alarm-Vollbild mit Ton und einem Quittieren-Button, und die Lage zeigt pro Empfänger quittiert / ausstehend / kein Gerät. Push folgt in Ticket 09.

**Blocked by:** 03, 06, 07

**Status:** done

- [x] Alarmierung sofort auslösen: Einsatz Entwurf → laufend beim Erstalarm; bedingte Zustandsübergänge, Doppelklick löst nichts doppelt aus
- [x] Empfänger = Besatzung der alarmierten Fahrzeuge in der zum Auslösezeitpunkt aktiven Schicht, eingefroren; `has_device` je Empfänger
- [x] Warnung an die Leitstelle, wenn eine Person auf mehreren gleichzeitig alarmierten Fahrzeugen sitzt; sie ist nur einmal Empfänger
- [x] Quittierung durch Empfänger; Event `alarm.acknowledged`
- [x] Event `alarm.triggered` mit Meldebild (ohne Drehbuch für Mannschaft/Monitor), Alarmierung und Empfängern
- [x] Monitor: Einsatzansicht (Nummer, Stichwort, Adresse, Meldebild, Laufzeit, Fahrzeuge mit Status, Quittierungen), Gong
- [x] App im Vordergrund: Alarm-Vollbild mit Ton und großem Quittieren-Button
- [x] Lage: laufende Einsätze, Quittierungs-Zustände je Empfänger; „kein Gerät“ zählt nicht als ausstehend
- [x] Tests: Empfänger eingefroren (späterer Schichtwechsel ändert nichts), Doppelbesetzung, Idempotenz, Quittierung nur durch Empfänger, Drehbuch nicht im Event für Mannschaft/Monitor, nur Leitstelle/Admin darf alarmieren

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
