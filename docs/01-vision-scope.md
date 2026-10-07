# 01 – Vision und Scope

Fachbegriffe: siehe [CONTEXT.md](../CONTEXT.md).

## Ziel

Beim BF-Tag erlebt die Jugendfeuerwehr 24 Stunden lang einen Berufsfeuerwehr-Alltag mit
simulierten Einsätzen. Die Software soll das realistisch abbilden:

- Die Einsatzvorbereitung plant Einsätze mit **Meldebild** (für alle) und **Drehbuch** (nur Betreuer).
- Die Leitstelle löst **Alarmierungen** manuell oder zeitgesteuert aus, inklusive Nachalarmierungen.
- Die **Besatzung** der alarmierten Fahrzeuge wird über ihre Handys alarmiert und **quittiert**.
  Ausgerückt wird über den **Fahrzeugstatus** 3, wie bei einer Berufsfeuerwehr.
- Ein **Monitor** in der Fahrzeughalle zeigt den laufenden Einsatz bzw. im Standby Uhr,
  Fahrzeugstatus, Besatzungen und Folien.

## Vorbild

[bf-tag.de](https://bf-tag.de) bietet Alarmmonitor, Einsatzplanung, Alarmierung, Fahrzeug-,
Benutzer- und Feuerwehrverwaltung, Dienstplan, Ausbildungsplanung, Einsatzberichte und Apps
(Android nur als APK). Wir bauen **den vollen Funktionsumfang nach, aber in Etappen**: Das MVP
läuft beim ersten BF-Tag, der Rest folgt. Das Domain-Modell berücksichtigt schon jetzt alles.

Zuordnung der bf-tag.de-Funktionen zu unseren Begriffen:

| bf-tag.de | bei uns |
|-----------|---------|
| Einsatzplanung | Einsatz (Meldebild + Drehbuch), Vorwarnung, Bereitmeldung |
| Alarmierung | Alarmierung (Erstalarm, Nachalarmierung), Quittierung |
| Statusverwaltung | Fahrzeugstatus, Sprechaufforderung |
| Fahrzeugverwaltung | Fahrzeug |
| Feuerwehrverwaltung | Feuerwehr |
| Benutzerverwaltung | Person, Personentyp, Berechtigung, Teilnahme |
| Dienstplan | **Schicht** + Besatzung (steuert die Alarmierung) und **Tagesablauf** (Anzeige) |
| Ausbildungsplanung | Programmpunkt vom Typ Ausbildung im Tagesablauf |
| Einsatzberichte | Einsatzbericht (pro Fahrzeug, mit Prüfung) |
| Alarmmonitor | Monitor, Folie |

## Etappen

### MVP (erster BF-Tag)

| Begriff | Umfang |
|---------|--------|
| BF-Tag, Teilnahme | anlegen, Zeitraum, Zustand |
| Feuerwehr | nur die eigene; im Modell vorhanden, im UI versteckt |
| Person | Personentyp, Berechtigung, Kopplung per QR-Code |
| Schicht, Besatzung, Funktion | standardmäßig eine Schicht über den ganzen BF-Tag |
| Fahrzeug, Fahrzeugstatus | Status setzen (Besatzung), überschreiben (Leitstelle) |
| Einsatz | Meldebild + Drehbuch, Abschlussvorschlag |
| Alarmierung | Erstalarm + Nachalarmierung, sofort + zeitgesteuert, verpasste Alarmierungen |
| Quittierung | quittiert / ausstehend / kein Gerät |
| Monitor | Einsatzansicht; Standby mit Uhr, Fahrzeugstatus, Besatzungen, Folien |
| Anonymisierung | manuell auslösbar |

### Danach

- Weitere Feuerwehren im UI
- Einsatzbericht mit Prüfung
- Vorwarnung und Bereitmeldung
- Sprechaufforderung
- Durchsage (an alle oder an eine Schicht), auch auf dem Monitor
- Tagesablauf mit Programmpunkten, auf Monitor und in der App
- Einsatz aus früherem BF-Tag kopieren
- Automatische Anonymisierung nach 8 Wochen
- Karte, Gong/TTS am Monitor, Statistik

## Nicht-Ziele

- Echter Einsatzbetrieb, Anbindung an echte Leitstellen, FMS/TETRA-Schnittstellen
- Mehrere Betreiber (Multi-Tenant). Andere Feuerwehren nehmen teil, betreiben aber kein eigenes System
- Mehrere Wachen bzw. Standorte (vorerst; alle Monitore zeigen alles)
- „Komme / komme nicht“-Rückmeldung (siehe [ADR 0006](adr/0006-quittierung-statt-rueckmeldung.md))
- Einsatzvorlagen-Bibliothek (stattdessen Einsätze kopieren)
- Öffentliche Registrierung
- Offline-Betrieb ohne Netz

## Erfolgskriterien

- Alarm erreicht ≥ 95 % der Geräte innerhalb von 5 Sekunden.
- Die Leitstelle sieht sofort, wessen Alarm nicht quittiert wurde.
- Der Monitor zeigt Statusänderungen in < 1 Sekunde.
- Einen Einsatz anlegen und auslösen dauert < 1 Minute.
- Das System läuft 24 h stabil auf einem kleinen VPS.
