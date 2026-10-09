# 05 — BF-Tag, Teilnahme, Schichten und Besatzung

**What to build:** Der Administrator legt einen BF-Tag an, wählt die teilnehmenden Personen und startet ihn. Die Leitstelle teilt in Schichten Personen mit Funktion den Fahrzeugen zu. Der Monitor zeigt im Standby die aktuelle Schicht mit Besatzungen.

**Blocked by:** 03, 04

**Status:** done

- [x] BF-Tag anlegen mit Name und Zeitraum; Zustände in Planung → läuft → beendet; höchstens ein BF-Tag läuft gleichzeitig
- [x] Teilnahmen pflegen (Personen ↔ BF-Tag)
- [x] Ein neuer BF-Tag erhält automatisch eine Schicht über den ganzen Zeitraum; weitere Schichten mit Name und Zeitfenster
- [x] Besatzung: teilnehmende Person + Funktion (GF, MA, ATF, ATM, WTF, WTM, ME …) → Fahrzeug, per Drag & Drop im Web
- [x] Eine Person darf in einer Schicht mehreren Fahrzeugen angehören; das UI markiert die Doppelbesetzung
- [x] Nur teilnehmende Personen können eingeteilt werden
- [x] Event `shift.crew_changed`; Snapshot enthält laufenden BF-Tag und aktuelle Schicht mit Besatzungen
- [x] Monitor-Standby zeigt die aktuelle Schicht mit Besatzungen je Fahrzeug
- [x] Tests: höchstens ein laufender BF-Tag, aktuelle Schicht abhängig von der Uhr, Besatzungsregeln, Berechtigungen (Admin: BF-Tag/Teilnahme; Leitstelle: Schichten/Besatzung)

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
