# Monitor — Einsatzansicht mit Karte

Grundlage: `docs/design/design-system.md`. Quelle: `apps/web/lib/screens/monitor_incident_screen.dart`.
Siehe `monitor-alarm.md` für den vorgelagerten, lauten Alarmzustand, in den dieser Screen übergeht/aus dem
er hervorgeht — beide Dokumente zusammen beschreiben den vollständigen Lebenszyklus eines alarmierten
Einsatzes auf dem Monitor.

## 1. Zweck

Ruhige, dauerhafte Ansicht eines laufenden (bereits alarmierten) Einsatzes: wo, was, wer ist alarmiert, wer
hat quittiert, wo befindet sich der Einsatzort. Läuft, solange der Einsatz offen ist (bis `incident.closed`),
rotiert bei mehreren gleichzeitig laufenden Einsätzen alle 15 s durch (`_incidentRotationInterval`,
unverändert). Im Unterschied zur `monitor-alarm.md` ist dies der **Normalzustand während** eines Einsatzes,
nicht der Moment des Eintreffens.

## 2. Usability-Probleme heute (Screenshots `einsatzansicht-1920x1080.png`, auch `alarm-1920x1080.png` zeigt
denselben Screen, da heute kein eigener Alarmzustand existiert — siehe `monitor-alarm.md` Abschnitt 2)

1. **Riesige leere Fläche** in der Bildschirmmitte (ca. y:200–760, nahezu die halbe Fläche): Meldebild-Text
   ist kurz, aber die Spalte ist auf volle Höhe angelegt, „Quittiert“-Spalte bei wenigen Empfängern ebenso —
   nichts füllt den Raum sinnvoll, nichts nutzt ihn für die Karte (die stattdessen ganz unten, klein, hockt).
2. **Kartenfläche ist praktisch unbrauchbar**: In der Vorher-Aufnahme zeigt sie sieben Kacheln mit dem Text
   „OpenStreetMap's volunteer-run servers: osm.wiki/Blocked“ statt echter Kartenkacheln — kein Pin, keine
   erkennbare Umgebung, nur Fehlertext in Kachelgröße. Selbst wenn Kacheln laden: feste Höhe 160 px ist für
   „wo muss ich hinschauen, wenn ich rausfahre“ aus 5–10 m zu klein, um Straßen/Landmarken zu erkennen.
3. Kein Platzhalter/Fehlerzustand für den Fall, dass Kartenkacheln nicht laden (Offline, Tile-Server down) —
   es erscheint, was der Tile-Provider zurückgibt, ungefiltert (siehe Punkt 2). Kein eigenes „Karte nicht
   verfügbar“-Design.
4. Alarm-Badge oben rechts (`monitor-incident-alarm-label`, heute dauerhaft `Colors.amberAccent`) bleibt die
   **gesamte Laufzeit** des Einsatzes sichtbar, nicht nur beim Eintreffen — ein Betreuer kann „gerade neu
   alarmiert“ nicht von „läuft schon seit 40 Minuten“ unterscheiden, beides zeigt denselben gelben Badge.
5. Fahrzeug-Chips unten zeigen nur Kurzname + kleinen FMS-Kreis (`CircleAvatar`, 32 px Durchmesser,
   `_vehicleStatusColor` mit rohen Material-Farben, u. a. **Rot für FMS 4** — kollidiert mit Alarmfarbe,
   identisches Problem wie in `monitor-standby.md` Punkt 2) — kein Label, nur eine Zahl im Kreis, auf 5–10 m
   nicht lesbar.
6. „Quittiert“-Liste zeigt nur Namen + Status-Icon, keine Gesamtzahl/Fortschritt („3 von 5 quittiert“) —
   ein Betreuer muss die Icons einzeln zählen.
7. Divider/VerticalDivider in `Colors.white24` sind das einzige Strukturelement zwischen den zwei Spalten —
   keine Flächentrennung (Designsystem 4.3: Trennung über Farbe, nicht nur 1-px-Linien auf Schwarz).

## 3. Neues Layout

Gleiches Grundraster wie Standby (Kopfzeile fix 140 px), damit der Übergang zwischen beiden Screens sich wie
derselbe Monitor anfühlt, nicht wie ein Appwechsel.

```
┌───────────────────────────────── 1920×1080 ──────────────────────────────────┐
│ Kopfzeile y:0–140  (surface)                                                 │
│  EINSATZ 3 · B2 Kellerbrand         08:34:40      seit 00:42   [2/5 quittiert]│
│  monitorHeadline 40     keyword in `alarm` monitorHeadline 40   monitorLabel 22│
│  (kleiner, ruhiger Status-Chip statt lautem Badge, s.u.)                      │
├───────────────────────────────┬──────────────────────────────────────────────┤
│ Meldebild  (x:0–960)          │ Karte  (x:960–1920, y:140–760, 620 px hoch)   │
│ y:140–460                      │ echte Kartenkachel + Marker Einsatzort,      │
│ monitorBody 28, max 6 Zeilen,  │ Marker Station (falls bekannt), Fallback s.u.│
│ danach Scroll-Indikator „⌄“    │                                              │
│ (kein echtes Scrollen, nur     │                                              │
│  Hinweis, dass mehr Text da ist│                                              │
│  — s. Abschnitt 4)             │                                              │
├───────────────────────────────┤                                              │
│ Quittiert  y:460–760           │                                              │
│ Fortschritt „2/5 quittiert“     │                                              │
│ (groß, monitorHeadline 40)      │                                              │
│ Namenliste darunter, 2-spaltig,│                                              │
│ Icon je Person, monitorBody 28 │                                              │
├───────────────────────────────┴──────────────────────────────────────────────┤
│ Fahrzeuge  y:760–1080 (volle Breite, surfaceVariant-Flächenkarten)            │
│  [HLF-1  FMS 4 ●]   [RTW-1  FMS 3 ●]   [DLK-1  FMS 2 ●]   ...                 │
│  monitorHeadline 40 Name, FMS-Pille 56px nach Designsystem 5.5 (Tokens!)      │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Kopfzeile**: Einsatznummer+Stichwort in einer Zeile (`monitorHeadline` 40, Stichwort in `alarm`-Farbe auf
dunklem `surface` — bewusst die einzige Stelle außerhalb des Alarmzustands, an der Alarmrot als *Text*
erscheint: markiert „dies ist ein alarmierter Einsatz“, ohne die Fläche zu fluten, siehe Designsystem
Grundprinzip 1 — Textfarbe, nicht Vollflächen-Alarm). Adresse direkt darunter in `onSurfaceVariant`
`monitorBody` 28 (heute separat als dritte Zeile, bleibt). Uhrzeit + Laufzeit rechtsbündig. Der bisherige
laute Alarm-Badge (`monitor-incident-alarm-label`) wird zu einem **ruhigen Status-Chip** „2/5 quittiert“ in
`primaryContainer` (behebt Problem 4 und 6 gleichzeitig: ersetzt den dauerhaften „ERSTALARM“-Look durch den
tatsächlich relevanten Fortschritt; das laute Label existiert weiterhin, aber nur im separaten
Alarmzustand kurz nach dem Auslösen, siehe `monitor-alarm.md`).

**Karte**: 620 px hoch (vorher 160 px), rechte Bildschirmhälfte — der mit Abstand größte Zugewinn an
Nutzwert, da „wohin muss das Fahrzeug fahren“ visuell der Kern der Einsatzansicht ist. Marker für
Einsatzort (Stecknadel, `alarm`-Farbe) und optional Wache (Hausmarker, `primary`-Farbe), `interactive: false`
bleibt (kein Touch/Zoom auf dem Monitor). **Fallback, wenn Kacheln nicht laden oder `incident.location`
fehlt**: neutrale `surfaceVariant`-Fläche mit Icon „location_off“ 48 px + Text „Karte nicht verfügbar“ bzw.
„Keine Standortdaten“ (zwei unterschiedliche Texte für die zwei Ursachen) — niemals die rohe
Tile-Provider-Fehlermeldung anzeigen (behebt Problem 2/3).

**Meldebild+Quittiert**: linke Spalte jetzt in zwei Zeilen übereinander (nicht mehr nebeneinander) —
Meldebild oben (meist kurz), Quittiert-Fortschritt+Liste darunter, damit beide den tatsächlich benötigten
Raum bekommen statt beide auf volle Höhe gestreckt zu werden (behebt Problem 1). Flächentrennung über
`surfaceVariant`-Hintergrund der Quittiert-Karte statt nur einer Linie (behebt Problem 7).

**Fahrzeugkarten** unten: volle Fahrzeugkurzname + Rufname + FMS-Pille (Token+Rahmen, Designsystem 5.5,
nicht mehr der kleine Zahlenkreis) — identische Pillen-Komponente wie im Standby-Panel, ein Betreuer lernt
die FMS-Darstellung nur einmal.

## 4. Alle Zustände

- **Kein Standort (`incident.location == null`):** Kartenfläche zeigt den Fallback „Keine Standortdaten“
  (Abschnitt 3), Rest des Layouts unverändert — bestehende Bedingung `if (incident.location != null)` bleibt
  erhalten, nur dass jetzt ein sichtbarer Platzhalter statt Weglassen der Karte erscheint (vorher: Karte
  verschwand komplett und die rechte Spalte blieb leer — neu: der Platzhalter macht sichtbar, *warum* keine
  Karte da ist, statt stumm wegzulassen).
- **Kartenkacheln laden nicht (Offline/Tile-Fehler):** Fallback „Karte nicht verfügbar“ + Icon, Marker-
  Positionsdaten bleiben im Hintergrund vorgehalten (kein Datenverlust, nur kein Kachelbild) — sobald Kacheln
  wieder laden, ersetzt die echte Karte den Platzhalter ohne Neuladen des restlichen Screens.
- **Sehr langes Meldebild (> 6 Zeilen):** Text wird auf 6 Zeilen begrenzt, danach Farbverlauf-Fade am unteren
  Rand der Meldebild-Box + kleines „⌄“-Symbol, das signalisiert „es gibt mehr Text“ — der Monitor kann nicht
  scrollen (keine Interaktion), vollständiger Text bleibt in Admin-Web/Drehbuch-Kontext abrufbar. Das ist
  dieselbe bewusste Grenze wie bei der Durchsage im Standby (`monitor-standby.md` Abschnitt 4).
- **Viele Empfänger/viele Fahrzeuge (> 10 Quittierte, > 6 Fahrzeuge):** Quittiert-Liste wird zweispaltig
  (bereits im Layout vorgesehen) und bei Bedarf auf eine feste Höhe mit Fade-Ausblenden am unteren Rand
  begrenzt (keine Kürzung der Zahl im Fortschritts-Chip „X/Y quittiert“ — die bleibt immer korrekt und
  vollständig, nur die Namensliste darunter kann nicht unbegrenzt wachsen). Fahrzeugkarten umbrechen in der
  vollen Breite (`Wrap`, bestehendes Verhalten bleibt), bei > 8 Fahrzeugen zusätzlich leicht kompaktere Pille
  (48 px statt 56 px) — bleibt über der Designsystem-Mindestgröße von 22 px Text.
- **Einsatz wird quittiert/aktualisiert (Echtzeit):** Ack-Icon pro Empfänger wechselt live (bestehendes
  Verhalten über `alarm.acknowledged`), zusätzlich der Fortschritts-Chip in der Kopfzeile zählt live mit —
  keine neue Datenquelle nötig, beide Werte kommen aus `recipients`.
- **Einsatz wird geschlossen (`incident.closed`):** Screen verschwindet (Übergabe an `MonitorScreen`-Logik,
  Rotation zur nächsten Einsatz oder zurück zu Standby) — unverändert.
- **Verbindungsverlust während des Einsatzes:** Einsatzdaten bleiben sichtbar (bestehender Test „connection
  loss ... does not drop the Einsatz“ bleibt grün), zusätzlich erscheint dieselbe neutrale
  `surfaceVariant`/„cloud_off“-Leiste wie im Standby oben in der Kopfzeile (schmal, 32 px, verdrängt nichts).

## 5. Interaktionen/Übergänge

- Keine Interaktion. Rotation zwischen mehreren laufenden Einsätzen: Cross-Fade 300 ms (Designsystem 7),
  kein harter Schnitt — behält die bestehende 15-s-Taktung (`_incidentRotationInterval`) bei.
- Live-Ack-Updates (Icon-Wechsel) animieren mit 150 ms Farb-/Icon-Fade, kein Blinken.
- Übergang aus dem Alarmzustand (`monitor-alarm.md`) in diese Ansicht: siehe dortiges Dokument Abschnitt 5 —
  nach Ablauf der festen Anzeigedauer, automatisch, kein harter Schnitt (200 ms Cross-Fade von Vollfläche
  `alarm` zu `surface`-Kopfzeile).

## 6. Testbare Akzeptanzkriterien

1. Kartenbereich (`IncidentMap`-Wrapper) hat eine feste Höhe ≥ 560 px auf 1920×1080 (Layout-Test gegen den
   `SizedBox`/`Expanded`-Constraint) statt der bisherigen 160 px.
2. Wenn `incident.location == null`, zeigt der Screen einen Platzhalter mit Text „Keine Standortdaten“
   (neuer Key, z. B. `Key('monitor-incident-map-placeholder')`) statt die Karte komplett wegzulassen —
   Widget-Test prüft, dass dieser Platzhalter-Key bei `location: null` existiert.
3. Kein Widget in `monitor_incident_screen.dart` verwendet `Colors.red`/`Colors.amberAccent` direkt für FMS-
   oder Alarm-Label-Flächen mehr — nur `BftagStatusColors`/`BftagAlarmColors` (Grep-Test).
4. `Key('monitor-incident-recipients')` wird von einem sichtbaren Fortschrittstext begleitet, der Format
   „X/Y quittiert“ zeigt und sich live aktualisiert, wenn ein `alarm.acknowledged`-Event eintrifft
   (bestehender Live-Test „a live alarm.acknowledged event updates the recipient ack icon“ erweitert um
   eine Prüfung des Fortschrittstexts).
5. `Key('monitor-incident-vehicles')`-Chips zeigen Fahrzeugname **und** FMS-Pille mit Status-Nummer+Text-
   Kontrast ≥ AA (nicht nur Farbe) — Accessibility-Test/manuelle Kontrollliste.
6. Meldebild-Text wird bei > 6 Zeilen auf 6 Zeilen begrenzt und zeigt den Mehr-Indikator — Widget-Test mit
   künstlich langem `incident.report`.
7. Bestehende Tests bleiben grün (ggf. mit angepassten Finder-Strings für neue Layout-Positionen, Verhalten
   unverändert): `monitor_incident_screen_test.dart`, `monitor_incident_test.dart` inkl. „a live
   alarm.acknowledged event updates the recipient ack icon“ und „connection loss (reconnecting) ... does
   not drop the Einsatz“.

## 7. Zu erhaltende Keys + Semantics

Aus `apps/web/lib/screens/monitor_incident_screen.dart` (grep-geprüft, keine `Semantics(...)` vorhanden):

- `Key('monitor-incident-number')`, `Key('monitor-incident-clock')`, `Key('monitor-incident-keyword')`,
  `Key('monitor-incident-runtime')`, `Key('monitor-incident-address')`, `Key('monitor-incident-report')`
- `Key('monitor-incident-recipients')`, `Key('incident-recipient-${recipient.personId}')`,
  `Key('incident-ack-icon-${recipient.personId}')`
- `Key('monitor-incident-vehicles')`, `Key('incident-vehicle-${vehicle.id}')`
- `Key('monitor-incident-alarm-label')` — **bleibt als Key erhalten**, wandert aber inhaltlich/visuell in den
  ruhigen Fortschritts-Chip der Kopfzeile (Abschnitt 3); der laute „ERSTALARM“-Badge-Look existiert weiterhin,
  nur nicht mehr auf diesem Screen (siehe `monitor-alarm.md`).

Neu empfohlen: `Key('monitor-incident-map-placeholder')` (Kriterium 2), `Key('monitor-incident-ack-progress')`
für den Fortschrittstext.

## 8. Funktionsabgleich vs. `docs/testing/regression-inventory.md`

| Funktion (Inventar) | Bleibt erhalten als |
|---|---|
| anzeigen (Einsatzdaten + Karte) | Abschnitt 3, alle Felder vorhanden, Karte deutlich größer + mit Fallback |
| Echtzeit-Updates (`alarm.acknowledged`) | Abschnitt 4 „Einsatz wird quittiert“, Ack-Icon + neuer Fortschrittstext |
| Fehlerzustand/Offline | Abschnitt 4 „Verbindungsverlust während des Einsatzes“, unverändertes Kernverhalten |

Keine Funktion entfällt. `monitor-incident-alarm-label` bleibt als Key bestehen, zeigt aber inhaltlich den
Quittierungs-Fortschritt statt dauerhaft „ERSTALARM“ — begründet in Abschnitt 2 Punkt 4/6 (ein Label, das die
ganze Einsatzdauer über „ERSTALARM“ zeigt, ist irreführend und verdrängt die eigentlich relevante Information).
