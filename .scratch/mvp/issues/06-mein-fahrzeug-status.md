# 06 — „Mein Fahrzeug“ in der App: Status setzen

**What to build:** Eine Person der Besatzung sieht in der App, auf welchem Fahrzeug sie in welcher Funktion eingeteilt ist, und setzt über große FMS-Tasten dessen Fahrzeugstatus. Monitor und Lage zeigen die Änderung sofort.

**Blocked by:** 05

**Status:** done

- [x] `/me` liefert die aktuellen Besatzungen der Person (bei Doppelbesetzung mehrere Fahrzeuge)
- [x] Screen „Mein Fahrzeug“: Fahrzeug, Funktion, Besatzung, FMS-Tasten 1–8 in Funkgerät-Optik
- [x] Status 7/8 nur bei RTW/KTW angeboten und serverseitig geprüft
- [x] Nur Personen der aktuellen Besatzung des Fahrzeugs dürfen den Status setzen; Leitstelle darf überschreiben
- [x] Die App aktualisiert sich live über den Echtzeit-Client
- [x] Tests: Status setzen als Besatzung erlaubt, als fremde Person verboten, nach Schichtende verboten (steuerbare Uhr), 7/8-Regel

Spec: `.scratch/mvp/spec.md` · Glossar: `CONTEXT.md`
