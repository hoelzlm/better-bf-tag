# BF-Tag

Simulation eines Berufsfeuerwehr-Alltags für die Jugendfeuerwehr: Betreuer planen Übungseinsätze,
alarmieren Fahrzeugbesatzungen und verfolgen den Ablauf.

## Language

### Veranstaltung

**BF-Tag**:
Eine einzelne Veranstaltung mit festem Zeitraum (meist 24 h), zu der Einsätze, Schichten, Tagesablauf und Einsatzberichte gehören. Zustände: in Planung, läuft, beendet.
_Avoid_: Event, Übungstag, Veranstaltung (als Fachbegriff)

**Anonymisierung**:
Das Entfernen aller Personenbezüge aus einem beendeten BF-Tag; Einsätze und Berichtstexte bleiben erhalten, Personen anderer Feuerwehren werden gelöscht.
_Avoid_: Archivierung, Bereinigung, Löschung (für den Gesamtvorgang)

**Feuerwehr**:
Eine Organisation, der Fahrzeuge und Personen angehören. Die eigene Feuerwehr ist der Standard, weitere Feuerwehren können an einem BF-Tag teilnehmen.
_Avoid_: Organisation, Wehr, Tenant

### Einsatz

**Einsatz**:
Ein simulierter Übungseinsatz innerhalb eines BF-Tags, bestehend aus Meldebild und Drehbuch.
_Avoid_: Alarm (als Synonym), Incident, Szenario

**Meldebild**:
Der für die Alarmierten sichtbare Teil eines Einsatzes: Stichwort, Adresse und Lagebeschreibung.
_Avoid_: Beschreibung, Einsatztext

**Drehbuch**:
Der nur für Betreuer sichtbare Teil eines Einsatzes: Aufbau, Darsteller, Material, erwarteter Ablauf.
_Avoid_: Notizen, interne Beschreibung, Szenario

**Alarmierung**:
Ein Ereignis, das für einen Einsatz einen Satz Fahrzeuge alarmiert; die erste ist der **Erstalarm**, jede weitere eine **Nachalarmierung**. Kann sofort oder zeitgesteuert ausgelöst werden.
_Avoid_: Alarm (als Synonym für Einsatz), Nachforderung

**Quittierung**:
Die Bestätigung einer Person, dass sie eine Alarmierung erhalten hat. Keine Zu- oder Absage.
_Avoid_: Rückmeldung, Zusage, „komme / komme nicht“

**Fahrzeugstatus**:
Der aktuelle Status eines Fahrzeugs nach FMS (1–8); Status 3 bestätigt das Ausrücken.
_Avoid_: Status (allein, wenn mehrdeutig), FMS (als Begriff für das Fahrzeug)

**Vorwarnung**:
Ein Hinweis an die Einsatzvorbereitung, eine festgelegte Zeit vor einer geplanten Alarmierung. Kein Alarm, kein Alarmton.
_Avoid_: Voralarm

**Bereitmeldung**:
Die Meldung der Einsatzvorbereitung, dass der Aufbau eines Einsatzes vor Ort abgeschlossen ist.
_Avoid_: Freigabe, „fertig“

**Sprechaufforderung**:
Die Antwort der Leitstelle auf Fahrzeugstatus 5 (Sprechwunsch) an die Besatzung.
_Avoid_: Rückruf, „J“

**Einsatzbericht**:
Bericht einer Fahrzeugbesatzung zu einem Einsatz, geschrieben von der Person in der Funktion GF, mit Zeiten aus den Fahrzeugstatus. Ein Bericht pro Fahrzeug und Einsatz; wird von einem Betreuer geprüft (freigegeben oder zurückgegeben).
_Avoid_: Einsatzprotokoll, Rapport

### Kommunikation

**Monitor**:
Ein gekoppelter Bildschirm auf der Wache, der laufende Einsätze und im Standby Uhr, Fahrzeugstatus, Besatzungen und Folien zeigt.
_Avoid_: Alarmmonitor (nur in Fließtext), Display, Bildschirm

**Folie**:
Ein Standby-Inhalt des Monitors mit Anzeigedauer.
_Avoid_: Slide, Seite

**Durchsage**:
Eine Nachricht der Leitstelle an alle oder an eine Schicht, ohne Bezug zu einem Einsatz und ohne Alarmton.
_Avoid_: Nachricht, Info, Broadcast, Alarm

### Personen

**Person**:
Ein Mensch, der das System nutzt oder in einer Besatzung eingeteilt ist. Gehört einer Feuerwehr an und bleibt über BF-Tage hinweg bestehen.
_Avoid_: Mitglied, Benutzer, User, Teilnehmer

**Teilnahme**:
Die Zuordnung einer Person zu einem BF-Tag.
_Avoid_: Anmeldung, Registrierung

**Personentyp**:
Ob eine Person **Jugendlicher** (minderjähriges JF-Mitglied) oder **Betreuer** (Erwachsener, z. B. Maschinist) ist. Unabhängig von der Berechtigung.

**Berechtigung**:
Was eine Person im System tun darf: Mannschaft, Einsatzvorbereitung (sieht Drehbücher), Leitstelle (alarmiert), Administrator (Stammdaten). Administrator nur für Betreuer.
_Avoid_: Rolle (mehrdeutig mit Personentyp und Funktion), Teilnehmer

### Dienst

**Schicht**:
Ein Zeitfenster innerhalb eines BF-Tags, in dem festgelegt ist, welche Personen auf welchem Fahrzeug Dienst haben.
_Avoid_: Wachabteilung (nur verwenden, wenn feste Gruppen gemeint sind), Dienst

**Besatzung**:
Die Personen, die in einer Schicht einem Fahrzeug mit je einer Funktion zugeordnet sind. Für einen Einsatz gilt die Besatzung zum Zeitpunkt der Alarmierung, bis das Fahrzeug wieder einsatzbereit ist. Eine Person darf in einer Schicht mehreren Fahrzeugen angehören.
_Avoid_: Crew, Mannschaft (ist eine Berechtigung)

**Funktion**:
Die Aufgabe einer Person in einer Besatzung, z. B. GF, MA, ATF, ATM, WTF, WTM, ME.
_Avoid_: Position, Rolle

**Tagesablauf**:
Die Folge von Programmpunkten eines BF-Tags (Essen, Ausbildung, Fahrzeugpflege, Nachtruhe) zur Anzeige.
_Avoid_: Dienstplan (mehrdeutig), Zeitplan

**Programmpunkt**:
Ein Eintrag im Tagesablauf mit Zeitraum und Typ; Ausbildung ist ein Typ von Programmpunkt.
_Avoid_: Termin, Ausbildungsplanung (als eigenes Konzept)

## Flagged ambiguities

- „Dienstplan“ (bf-tag.de) meinte zwei Dinge. Aufgeteilt in **Schicht** (steuert die Alarmierung) und **Tagesablauf** (Anzeige).
- „Beschreibung“ eines Einsatzes. Aufgeteilt in **Meldebild** (sichtbar) und **Drehbuch** (geheim).
- „Rückmeldung (komme / komme nicht)“ ist Logik der Freiwilligen Feuerwehr. Beim BF-Tag ersetzt durch **Quittierung**; das Ausrücken bestätigt der **Fahrzeugstatus** 3.
- „Mitglied“ passte nicht auf Personen anderer Feuerwehren. Ersetzt durch **Person**.
