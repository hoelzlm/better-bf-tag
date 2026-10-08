# Spec: MVP für den ersten BF-Tag

**Status:** ready-for-agent

Fachbegriffe: `CONTEXT.md`. Relevante ADRs: 0001 (Monorepo), 0002 (Backend-Sprache, noch offen),
0003 (Push), 0004 (eine Flutter-Web-App), 0005 (Kopplung per QR-Code), 0006 (Quittierung),
0007 (Personen dauerhaft, Anonymisierung).

## Problem Statement

Unsere Jugendfeuerwehr will einen BF-Tag durchführen: 24 Stunden Berufsfeuerwehr-Alltag mit
simulierten Einsätzen. bf-tag.de bietet genau das, aber die Android-App gibt es nur als APK
außerhalb des Play Stores, und Daten sowie Hosting liegen nicht in unserer Hand. Ohne Software
läuft die Alarmierung über Rufen, Funk und Zettel: Die Jugendlichen erfahren Einsätze nicht
realistisch, die Leitstelle weiß nicht, wen der Alarm erreicht hat, und die Betreuer verlieren den
Überblick über Fahrzeuge, Besatzungen und den Stand der Einsätze.

## Solution

Ein eigenes System auf unserem Hetzner-VPS mit drei Oberflächen:

- **Web** für Administrator, Leitstelle und Einsatzvorbereitung: Stammdaten, BF-Tag, Schichten
  und Besatzungen, Einsätze mit Meldebild und Drehbuch, Alarmierungen sofort oder zeitgesteuert,
  Lage mit Quittierungen und Fahrzeugstatus.
- **Monitor** im Browser auf der Wache: zeigt laufende Einsätze groß an, im Standby Uhr,
  Fahrzeugstatus, Besatzungen und Folien.
- **Mobile-App** (iOS über TestFlight, Android über Play Internal Testing): Kopplung per QR-Code,
  Push-Alarm mit Alarmton, Quittierung, Fahrzeugstatus des eigenen Fahrzeugs, Einsatzliste.

## User Stories

### Administrator: Stammdaten und Zugang

1. Als Administrator möchte ich mich im Web mit Benutzername und Passwort anmelden, damit nur Berechtigte Stammdaten ändern.
2. Als Administrator möchte ich beim ersten Start einen Administrator-Zugang über die Server-Konfiguration erhalten, damit ich das System ohne Datenbankzugriff einrichten kann.
3. Als Administrator möchte ich Personen mit Anzeigename, Personentyp und Berechtigung anlegen, damit jeder Mensch am BF-Tag im System vorkommt.
4. Als Administrator möchte ich, dass nur Betreuer die Berechtigung Administrator erhalten können, damit Jugendliche keine Stammdaten verwalten.
5. Als Administrator möchte ich Jugendlichen die Berechtigung Leitstelle geben können, damit ältere Jugendliche die Leitstelle besetzen.
6. Als Administrator möchte ich Personen mit Web-Berechtigung (Einsatzvorbereitung, Leitstelle, Administrator) einen Benutzernamen und ein Passwort geben, damit sie das Web nutzen können.
7. Als Administrator möchte ich für eine Person einen Kopplungscode als QR-Code und 8-stelligen Code erzeugen, damit sie ihr Handy ohne E-Mail-Adresse koppeln kann.
8. Als Administrator möchte ich die Kopplungscodes aller Teilnehmer als druckbare Liste erzeugen, damit ich sie beim BF-Tag austeilen kann.
9. Als Administrator möchte ich die Geräte einer Person sehen und einzeln sperren, damit ein verlorenes Handy keinen Zugriff mehr hat.
10. Als Administrator möchte ich Fahrzeuge mit Funkrufname, Kurzname, Typ und Reihenfolge anlegen, damit sie auf Monitor und Lage richtig erscheinen.
11. Als Administrator möchte ich Fahrzeuge deaktivieren statt löschen, damit vergangene Einsätze nachvollziehbar bleiben.
12. Als Administrator möchte ich einen Monitor anlegen und per Kopplungscode verbinden, damit ein Bildschirm ohne Tastatur-Login angezeigt werden kann.
13. Als Administrator möchte ich einen Monitor sperren, damit ein abhandengekommener Bildschirm nichts mehr anzeigt.
14. Als Administrator möchte ich Folien mit Titel, Text, optionalem Bild und Anzeigedauer pflegen, damit der Monitor im Standby Informationen zeigt.
15. Als Administrator möchte ich einen BF-Tag mit Name und Zeitraum anlegen, damit Einsätze, Schichten und Teilnahmen einer Veranstaltung zugeordnet sind.
16. Als Administrator möchte ich festlegen, welche Personen an einem BF-Tag teilnehmen, damit nur sie eingeteilt und alarmiert werden.
17. Als Administrator möchte ich einen BF-Tag starten und beenden, damit das System weiß, welcher BF-Tag gerade läuft.
18. Als Administrator möchte ich sicher sein, dass höchstens ein BF-Tag gleichzeitig läuft, damit Alarmierungen eindeutig zugeordnet sind.

### Leitstelle: Schichten und Besatzung

19. Als Leitstelle möchte ich, dass ein neuer BF-Tag automatisch eine Schicht über den ganzen Zeitraum hat, damit ich ohne Schichtplanung starten kann.
20. Als Leitstelle möchte ich weitere Schichten mit Name und Zeitfenster anlegen, damit ich Tag- und Nachtschicht abbilden kann.
21. Als Leitstelle möchte ich in einer Schicht teilnehmende Personen mit einer Funktion (GF, MA, ATF, ATM, WTF, WTM, ME …) Fahrzeugen zuordnen, damit feststeht, wer alarmiert wird.
22. Als Leitstelle möchte ich eine Person in einer Schicht mehreren Fahrzeugen zuordnen können, damit ein Betreuer Maschinist für zwei Fahrzeuge sein kann.
23. Als Leitstelle möchte ich eine Warnung sehen, wenn eine Person auf mehreren Fahrzeugen eingeteilt ist und diese gleichzeitig alarmiert werden, damit ich den Konflikt erkenne.

### Einsatzvorbereitung: Einsätze planen

24. Als Einsatzvorbereitung möchte ich einen Einsatz für einen BF-Tag mit Stichwort, Adresse und Lagebeschreibung (Meldebild) anlegen, damit die Alarmierten wissen, was sie erwartet.
25. Als Einsatzvorbereitung möchte ich zu jedem Einsatz ein Drehbuch erfassen, damit Aufbau, Darsteller und erwarteter Ablauf festgehalten sind.
26. Als Einsatzvorbereitung möchte ich, dass das Drehbuch in der Bearbeitung deutlich als geheim markiert ist, damit ich nichts versehentlich ins Meldebild schreibe.
27. Als Einsatzvorbereitung möchte ich Einsätze im Entwurf bearbeiten und verwerfen, damit ich die Planung anpassen kann.
28. Als Einsatzvorbereitung möchte ich Meldebild und Drehbuch auch bei einem laufenden Einsatz korrigieren können, damit Tippfehler behoben werden.
29. Als Einsatzvorbereitung möchte ich die Einsätze eines BF-Tags nach Entwurf, laufend und abgeschlossen filtern, damit ich den Überblick behalte.
30. Als Mannschaft möchte ich das Drehbuch nie zu sehen bekommen, weder in der App noch auf dem Monitor, damit die Übung realistisch bleibt.

### Leitstelle: Alarmieren

31. Als Leitstelle möchte ich für einen Einsatz eine Alarmierung mit ausgewählten Fahrzeugen sofort auslösen (Erstalarm), damit die Besatzungen ausrücken.
32. Als Leitstelle möchte ich eine Alarmierung mit Zeitpunkt planen, damit Einsätze automatisch nach Ablaufplan ausgelöst werden.
33. Als Leitstelle möchte ich Nachalarmierungen relativ zum Erstalarm planen (z. B. „DLK 8 Minuten nach Erstalarm“), damit das Szenario eskaliert, wie im Drehbuch vorgesehen.
34. Als Leitstelle möchte ich bei einem laufenden Einsatz spontan eine Nachalarmierung mit weiteren Fahrzeugen auslösen, damit ich auf den Verlauf reagieren kann.
35. Als Leitstelle möchte ich geplante Alarmierungen in Zeit und Fahrzeugen ändern oder verwerfen, damit ich den Ablauf anpassen kann.
36. Als Leitstelle möchte ich, dass ein versehentlicher Doppelklick keinen zweiten Alarm auslöst, damit niemand doppelt alarmiert wird.
37. Als Leitstelle möchte ich, dass eine geplante Alarmierung, die mehr als 10 Minuten überfällig ist (z. B. nach einem Serverausfall), nicht mehr automatisch auslöst, sondern als verpasst angezeigt wird, damit nachts kein veralteter Alarm kommt.
38. Als Leitstelle möchte ich verpasste Alarmierungen auf der Lage sehen und manuell auslösen oder verwerfen, damit ich die Kontrolle behalte.
39. Als Leitstelle möchte ich, dass alarmiert wird, wer zum Auslösezeitpunkt zur Besatzung der alarmierten Fahrzeuge gehört, und dass ein späterer Schichtwechsel daran nichts ändert, damit ein Einsatz über den Schichtwechsel hinweg stimmig bleibt.
40. Als Leitstelle möchte ich, dass Personen, die schon im Einsatz sind, bei einer Nachalarmierung keinen zweiten Alarm bekommen, damit keine Verwirrung entsteht.

### Leitstelle: Lage und Quittierungen

41. Als Leitstelle möchte ich eine Lage-Ansicht mit laufenden Einsätzen, Fahrzeugstatus, nächsten geplanten Alarmierungen und verpassten Alarmierungen, damit ich alles auf einen Blick sehe.
42. Als Leitstelle möchte ich pro Alarmierung für jeden Empfänger sehen, ob er quittiert hat, noch aussteht oder kein Gerät hat, damit ich sofort erkenne, wessen Handy nicht klingelt.
43. Als Leitstelle möchte ich, dass Personen ohne Gerät nicht als fehlende Quittierung zählen, damit das Signal „ausstehend“ aussagekräftig bleibt.
44. Als Leitstelle möchte ich sehen, wie viele Pushes zugestellt bzw. abgelehnt wurden, damit ich technische Probleme erkenne.
45. Als Leitstelle möchte ich den Fahrzeugstatus jedes Fahrzeugs überschreiben können, damit ich Fehleingaben korrigiere oder Fahrzeuge ohne Handy führe.
46. Als Leitstelle möchte ich einen Vorschlag zum Abschließen bekommen, sobald alle alarmierten Fahrzeuge Status 1 oder 2 melden und keine Alarmierung mehr geplant ist, damit ich keinen Einsatz offen vergesse.
47. Als Leitstelle möchte ich einen Einsatz schließen und dabei gewarnt werden, wenn noch geplante Alarmierungen verworfen werden, damit nichts unbeabsichtigt verloren geht.
48. Als Leitstelle möchte ich, dass Änderungen in unter einer Sekunde ohne Neuladen in der Lage erscheinen, damit ich in Echtzeit arbeite.

### Mannschaft: Mobile-App

49. Als Jugendlicher möchte ich mein Handy koppeln, indem ich einen QR-Code scanne oder einen Code abtippe, damit ich keine E-Mail-Adresse und kein Passwort brauche.
50. Als Jugendlicher möchte ich beim ersten Start durch die Berechtigungen (Benachrichtigungen, Nicht stören, Akku-Optimierung) geführt werden, damit mich der Alarm zuverlässig erreicht.
51. Als Jugendlicher möchte ich einen Testalarm auslösen, damit ich prüfen kann, ob Ton und Benachrichtigung funktionieren.
52. Als Jugendlicher möchte ich bei einer Alarmierung eine Benachrichtigung mit Alarmton bekommen, auch wenn die App geschlossen ist, damit ich den Alarm nicht verpasse.
53. Als Jugendlicher möchte ich beim Antippen der Benachrichtigung direkt den Alarm-Screen mit Stichwort, Adresse, Meldebild und alarmierten Fahrzeugen sehen, damit ich sofort weiß, worum es geht.
54. Als Jugendlicher möchte ich bei geöffneter App den Alarm sofort als Vollbild mit Alarmton sehen, damit es auch ohne Push funktioniert.
55. Als Jugendlicher möchte ich den Alarm mit einem großen Button quittieren, damit die Leitstelle weiß, dass er angekommen ist.
56. Als Person der Besatzung möchte ich auf „Mein Fahrzeug“ sehen, auf welchem Fahrzeug ich in welcher Funktion eingeteilt bin, damit ich weiß, wohin ich gehöre.
57. Als Person der Besatzung möchte ich den Fahrzeugstatus meines Fahrzeugs über große FMS-Tasten setzen, damit die Leitstelle den Stand sieht.
58. Als Person der Besatzung möchte ich Status 7 und 8 nur bei RTW/KTW angeboten bekommen, damit ich keinen unpassenden Status setze.
59. Als Person, die nicht zur aktuellen Besatzung eines Fahrzeugs gehört, möchte ich dessen Status nicht setzen können, damit niemand fremde Fahrzeuge verstellt.
60. Als Jugendlicher möchte ich die laufenden und vergangenen Einsätze des BF-Tags sehen, damit ich nachlesen kann, was passiert ist.
61. Als Einsatzvorbereitung bzw. Leitstelle möchte ich in der App auch das Drehbuch sehen, damit ich unterwegs nachschlagen kann.
62. Als Person möchte ich mein Gerät in den Einstellungen abmelden können, damit ich es weitergeben kann.
63. Als Person mit gesperrtem Gerät möchte ich sofort abgemeldet werden, damit klar ist, dass das Gerät keinen Zugriff mehr hat.

### Monitor

64. Als Monitor möchte ich per Kopplungscode verbunden werden und danach dauerhaft angemeldet bleiben, damit niemand am Fernseher tippen muss.
65. Als Person auf der Wache möchte ich bei einer Alarmierung auf dem Monitor Einsatznummer, Stichwort, Adresse, Meldebild, Laufzeit, alarmierte Fahrzeuge und Quittierungen sehen, damit ich ohne Handy informiert bin.
66. Als Person auf der Wache möchte ich bei einer Alarmierung einen Gong bzw. Alarmton am Monitor hören, damit auch Personen ohne Handy alarmiert werden.
67. Als Person auf der Wache möchte ich im Standby Uhr, Fahrzeugstatus, die aktuelle Schicht mit Besatzungen und rotierende Folien sehen, damit ich weiß, wer auf welchem Fahrzeug ist.
68. Als Person auf der Wache möchte ich bei mehreren laufenden Einsätzen alle nacheinander sehen, damit keiner untergeht.
69. Als Betreuer möchte ich, dass der Monitor bei Verbindungsverlust ein deutliches Warnbanner zeigt und sich selbst wieder verbindet, damit ich Ausfälle sofort bemerke.
70. Als Betreuer möchte ich, dass der Bildschirm des Monitors nicht in den Ruhezustand geht, damit er 24 h läuft.

### Datenschutz und Betrieb

71. Als Leitstelle möchte ich einen beendeten BF-Tag manuell anonymisieren, damit Personenbezüge nicht länger als nötig gespeichert bleiben.
72. Als Betreiber möchte ich, dass die Anonymisierung Teilnahmen, Besatzungen und Quittierungen löscht, den Personenbezug in der Statushistorie entfernt, Personen anderer Feuerwehren löscht und Einsätze mit Meldebild und Drehbuch behält, damit Szenarien wiederverwendbar bleiben.
73. Als Betreiber möchte ich, dass Pushes nur Stichwort, Adresse und IDs enthalten und nie Namen oder das Drehbuch, damit keine personenbezogenen Daten an Google oder Apple gehen.
74. Als Betreiber möchte ich das System per Docker Compose mit automatischem TLS auf dem Hetzner-VPS betreiben, damit Hosting und Daten in der EU und in unserer Hand liegen.
75. Als Betreiber möchte ich nächtliche verschlüsselte Datenbank-Backups auf einer Storage Box, damit kein Datenverlust droht.
76. Als Betreiber möchte ich einen Health-Endpunkt für Uptime-Checks, damit ich Ausfälle bemerke.
77. Als Betreiber möchte ich die App über Google Play Internal Testing und TestFlight verteilen, damit die Jugendlichen sie aus den regulären Stores installieren können.
78. Als Betreiber möchte ich, dass ungültige Push-Tokens automatisch entfernt werden, damit Fehler nicht dauerhaft auflaufen.

## Implementation Decisions

### Module

- **Backend** (eine Anwendung, ein Prozess): Module entlang des Glossars mit schmalen Schnittstellen
  - *Zugang*: Web-Login, Kopplung, Token-Refresh, Gerätesperre, Prüfung der Berechtigungen
  - *Stammdaten*: Feuerwehr (nur die eigene im UI), Person, Fahrzeug, Monitor, Folie
  - *BF-Tag*: BF-Tag, Teilnahme, Schicht, Besatzung
  - *Fahrzeugstatus*: Status setzen bzw. überschreiben, Statushistorie
  - *Einsatz*: Meldebild, Drehbuch, Zustandsautomat, Abschlussvorschlag
  - *Alarmierung*: Auslösen (idempotent), Planen über eine persistente Job-Queue in PostgreSQL, verpasste Alarmierungen, Empfänger einfrieren, Quittierung
  - *Push*: eine Schnittstelle „Push senden an Geräte“ mit Implementierungen für FCM HTTP v1 und APNs (Token-Auth) und einem Fake für Tests
  - *Echtzeit*: WebSocket-Broadcast mit fortlaufender `seq`, gefiltert nach Berechtigung, plus Snapshot-Endpunkt
  - *Anonymisierung*: manuell auslösbar pro BF-Tag
  - *Uhr*: eine injizierbare Zeitquelle, die von allen zeitabhängigen Modulen genutzt wird
- **Flutter** (Pub Workspace): ein gemeinsames Paket (API-Wrapper mit Token-Refresh, Echtzeit-Client mit Reconnect, `seq`-Prüfung und Snapshot-Reload, Domain-Typen im Glossar-Vokabular, Theme), ein generiertes API-Client-Paket aus OpenAPI, eine Web-App mit den Bereichen Admin und Monitor, eine Mobile-App.
- **Infra**: Docker Compose mit Caddy, Backend und PostgreSQL; Backup über restic; Deploy-Skript.

### Architektur

- REST unter `/api/v1` mit generierter OpenAPI-Spezifikation; WebSocket unter `/ws`. Eine Domain, Caddy liefert die Web-Builds aus und leitet `/api` und `/ws` an das Backend weiter.
- Clients halten keinen eigenen Wahrheitszustand: Beim (Re-)Connect laden sie den Snapshot und wenden danach Events an; bei einer Lücke in `seq` laden sie den Snapshot neu.
- Jede Änderung wird zuerst in PostgreSQL geschrieben, danach als Event verschickt.
- Backend-Sprache ist laut ADR 0002 noch offen (Empfehlung Node.js/TypeScript mit Fastify, Drizzle und pg-boss; Alternative Python/FastAPI). Der Spec gilt für beide Varianten.

### Schema (siehe docs/03-datenmodell.md)

- Dauerhaft: `fire_department`, `person` (Personentyp, Berechtigung; Administrator nur bei Betreuer), `device`, `pairing_code`, `vehicle`, `monitor_display`, `slide`.
- Pro BF-Tag: `bf_day` (planning/running/ended, `anonymized_at`), `participation`, `shift`, `crew_assignment` (PK aus Schicht, Fahrzeug und Person; eine Person darf auf mehreren Fahrzeugen stehen), `vehicle_status_event`, `incident` (Meldebild: `keyword`, `address`, `report`; Drehbuch: `script`; Zustand draft/running/closed/discarded), `alarm` (planned/triggered/missed/discarded), `alarm_vehicle`, `alarm_recipient` (eingefrorene Besatzung, `has_device`, `acknowledged_at`).
- Erstalarm und Nachalarmierung werden aus der Reihenfolge der ausgelösten Alarmierungen abgeleitet und nicht gespeichert.

### Zustandsautomaten

```
Einsatz:      draft → running (Erstalarm) → closed (Leitstelle)
              draft → discarded
Alarmierung:  planned → triggered | missed (> 10 min überfällig) | discarded
              (sofort ausgelöste Alarmierungen werden direkt als triggered angelegt)
```

- Übergänge sind bedingte Updates (`… WHERE state = <erwartet>`). Wiederholte Aufrufe ändern nichts und liefern 409 oder sind folgenlos.
- Beim Schließen eines Einsatzes werden geplante Alarmierungen verworfen und ihre Jobs gelöscht.
- Den Abschlussvorschlag gibt es, wenn alle Fahrzeuge aller ausgelösten Alarmierungen Status 1 oder 2 haben und keine Alarmierung mehr geplant ist.

### Berechtigungen

| Aktion | Mannschaft | Einsatzvorbereitung | Leitstelle | Administrator |
|---|:-:|:-:|:-:|:-:|
| Meldebild sehen, quittieren, Status eigenes Fahrzeug | ✓ | ✓ | ✓ | ✓ |
| Drehbuch sehen | | ✓ | ✓ | ✓ |
| Einsätze anlegen/bearbeiten | | ✓ | ✓ | ✓ |
| Alarmieren, Einsatz schließen, Status überschreiben | | | ✓ | ✓ |
| Schichten/Besatzungen pflegen | | | ✓ | ✓ |
| Anonymisierung auslösen | | | ✓ | ✓ |
| Stammdaten, BF-Tage, Teilnahmen, Monitore, Folien | | | | ✓ |

Das Drehbuch wird **serverseitig** aus allen Antworten und Events für Mannschaft und Monitore entfernt.

### API und Events

Endpunkte siehe docs/04-api.md (Abschnitte MVP). Events im MVP: `incident.created`,
`incident.updated`, `incident.close_suggested`, `incident.closed`, `alarm.planned`,
`alarm.triggered`, `alarm.missed`, `alarm.discarded`, `alarm.acknowledged`,
`vehicle.status_changed`, `vehicle.updated`, `shift.crew_changed`, `slides.changed`,
`session.revoked`.

### Push

- Android: FCM HTTP v1, Priorität high, TTL 300 s, eigener Notification Channel `alarm` mit eigenem Sound; kein Full-Screen-Intent.
- iOS: APNs direkt, `interruption-level: time-sensitive`, eigener Sound; keine Critical Alerts.
- Inhalt: Stichwort und Adresse aus dem Meldebild, `incident_id`, `alarm_id`. Ungültige Tokens (FCM `UNREGISTERED`, APNs `410`/`BadDeviceToken`) werden entfernt.
- Personen, die bereits Empfänger einer früheren Alarmierung desselben Einsatzes sind, erhalten bei Nachalarmierungen keinen Push.

### Authentifizierung

- Web: Benutzername und Passwort (Argon2id), Access-Token 15 min, Refresh-Token als HttpOnly-Cookie.
- App und Monitor: Einmal-Kopplungscode (24 h gültig) gegen ein langlebiges, rotierendes Refresh-Token.
- Ein gesperrtes Gerät verliert beim nächsten Refresh den Zugang und bekommt sofort `session.revoked`.
- Rate-Limiting auf den Auth-Endpunkten.

## Testing Decisions

- **Gute Tests** prüfen nur von außen beobachtbares Verhalten: HTTP-Antworten, WebSocket-Events, aufgezeichnete Pushes. Keine Tests auf interne Funktionen, Tabellen oder ORM-Aufrufe. Ein Refactoring des Backends darf keinen Test brechen.
- **Eine Hauptschnittstelle:** die öffentliche Backend-API (REST und WebSocket). Die Tests starten das Backend gegen eine echte PostgreSQL (Testcontainer) und agieren als Clients mit verschiedenen Berechtigungen.
- **Zwei Austauschpunkte an der Systemgrenze** werden beim Start eingeschleust:
  - *Push-Fake*: zeichnet Pushes pro Gerät auf und kann ungültige Tokens simulieren
  - *Steuerbare Uhr*: erlaubt es, geplante Alarmierungen, die 10-Minuten-Grenze für „verpasst“ und Token-Abläufe ohne Warten zu testen
- **Pflichtszenarien:**
  - Drehbuch erscheint nie in Antworten und Events für Mannschaft und Monitor
  - Empfänger werden eingefroren, ein Schichtwechsel ändert sie nicht
  - Doppelbesetzung führt zu einem Push und zu einer Warnung
  - Nachalarmierung ohne erneuten Alarm für Personen, die schon im Einsatz sind
  - doppeltes Auslösen ist folgenlos
  - nach einem simulierten Neustart werden überfällige Alarmierungen ausgelöst bzw. als verpasst markiert
  - Abschlussvorschlag und Verwerfen beim Schließen
  - Quittierungs-Zustände inklusive „kein Gerät“
  - Berechtigungsmatrix: jede Zeile positiv und negativ
  - Status setzen nur für die eigene Besatzung
  - Gerätesperre
  - Ergebnis der Anonymisierung
  - Snapshot plus `seq` sind konsistent
- **Flutter:** keine eigene Testebene für Fachlogik. Wenige Widget-Tests für Alarm-Screen und Monitor-Einsatzansicht, Drehbuch-Kennzeichnung nur, wo sie sicherheitsrelevant ist.
- **Manuell:** Probealarm mit echten Geräten (verschiedene Android-Hersteller, iPhone, stumm/Nicht stören), Lasttest mit 30 Geräten und 20 Einsätzen.
- **Prior Art:** keine, das Repo enthält noch keinen Code. Das erste Ticket legt die Test-Infrastruktur an.

## Out of Scope

- Weitere Feuerwehren im UI (im Modell schon vorhanden)
- Einsatzbericht und Prüfung
- Vorwarnung, Bereitmeldung, Sprechaufforderung, Durchsage
- Tagesablauf und Programmpunkte
- Einsätze aus früheren BF-Tagen kopieren
- Automatische Anonymisierung nach 8 Wochen (im MVP nur manuell)
- Mehrere Wachen, Karte, Routing, TTS, Statistik
- Zu- oder Absage „komme / komme nicht“ (ADR 0006)
- Production-Release im Play Store (12-Tester-/14-Tage-Regel), App-Store-Unlisted
- Echter Einsatzbetrieb, Leitstellen-Schnittstellen, Multi-Tenant, Offline-Betrieb

## Further Notes

- Zeitrahmen: 2 Wochen (docs/10-roadmap.md). Store-Accounts, Firebase-Projekt, APNs-Key und VPS sofort anlegen, weil es dabei Wartezeiten gibt.
- Datenschutz vor dem Betrieb mit dem Träger klären und die Einwilligung der Eltern einholen (docs/09-datenschutz.md).
- Family-Link-Konten können Play-Testtracks blockieren; früh testen, Plan B ist eine signierte APK.
- ADR 0002 (Backend-Sprache) muss vor dem ersten Ticket entschieden werden.
