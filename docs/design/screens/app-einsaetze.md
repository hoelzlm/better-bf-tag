# App – Einsätze (`screens/incidents_screen.dart`)

Status: Entwurf (ux-02e) · baut auf `docs/design/design-system.md`

## 1. Zweck

Liste aller Einsätze des laufenden BF-Tags (`running` und `closed`, serverseitig bereits nach Berechtigung
gefiltert). Primäre Aufgabe: schneller Überblick "gibt es Neues, worum geht's, ist es noch aktiv" und Sprung
ins Einsatzdetail.

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/einsaetze-390x844.png` zeigt den Fehlerzustand "Einsätze konnten
   nicht geladen werden." zentriert in sehr viel Leerraum, kein "Erneut versuchen"-Button sichtbar (Code hat
   nur `RefreshIndicator`/Pull-to-Refresh als Wiederholungsweg, keinen eigenen Button) — auf den ersten Blick
   nicht erkennbar, dass man nach unten ziehen kann, um es erneut zu versuchen.
2. `_StateChip` für den Einsatzstatus nutzt `Colors.red.shade600` für `running` (aktiver Einsatz) — kollidiert
   direkt mit der Grundregel "Rot = Alarm" (Designsystem Grundprinzip 1): ein laufender *Übungseinsatz* ist
   kein Alarmzustand der App, sondern reine Statusinfo, sollte also nicht dieselbe Signalfarbe wie der
   Alarm-Screen tragen.
3. Listenzeilen sind Standard-`ListTile`s ohne erkennbare Tap-Affordanz (kein Chevron/Pfeil), auf dem hell-
   rosa Flutter-Demo-Hintergrund kaum von der Fläche abgesetzt.

## 3. Neues Layout

ASCII-Wireframe (390×844, gefüllte Liste):

```
┌──────────────────────────────────────────┐
│  Einsätze                          ⚙     │  AppBar
├──────────────────────────────────────────┤
│  #3 B3 Großbrand Lagerhalle    [Laufend] │  ListTile, outline-Trenner, 56dp Höhe,
│  Industriestraße 7              ›        │  Status-Chip primaryContainer/primary
│──────────────────────────────────────────│  (NICHT alarm-rot), Chevron rechts
│  #2 H1 Verkehrsunfall          [Beendet] │
│  Hauptstraße 12                  ›        │  Chip neutral: surfaceVariant/
│──────────────────────────────────────────│  onSurfaceVariant für "Beendet"
├──────────────────────────────────────────┤
│  🚒 Fahrzeug  📢 Einsätze  💬 ..  📅 ..   │  Navigationsleiste
└──────────────────────────────────────────┘
```

Kein eigenes HTML-Mockup für diesen Screen Pflicht (nicht in der "mindestens"-Liste); Token-Anwendung ist
1:1 aus der Listen-/Karten-Spezifikation des Designsystems (5.3) ableitbar.

## 4. Alle Zustände

- **Laden** (`_LoadState.loading`): zentrierter `CircularProgressIndicator` (`primary`).
- **Kein laufender BF-Tag** (`_LoadState.noRunningBfDay`, 404): Text „Kein laufender BF-Tag." in scrollbarem
  Container (damit Pull-to-Refresh weiter funktioniert, unverändert), ergänzt um 48px-Icon
  (`event_busy_outlined`, `onSurfaceVariant`) nach Leerzustandsmuster 5.10.
- **Fehler** (`_LoadState.error`): Text „Einsätze konnten nicht geladen werden." + Fehler-Icon (`warning`,
  nicht `alarm`) + zusätzlicher Hinweistext „Nach unten ziehen zum erneut Laden" (neu, rein erklärend —
  kein neuer Mechanismus, derselbe `RefreshIndicator` wird nur sichtbar kommuniziert statt stillschweigend
  vorauszusetzen, dass die Person Pull-to-Refresh kennt).
- **Leer** (`_LoadState.loaded`, Liste leer): Text „Noch keine Einsätze." + 48px-Icon (`campaign_outlined`
  o. ä., `onSurfaceVariant`) nach Leerzustandsmuster.
- **Gefüllt:** Liste mit Status-Chip je Zeile — `running` = `primaryContainer`/`primary` Chip „Laufend",
  `closed` = `surfaceVariant`/`onSurfaceVariant` Chip „Beendet" (farblich neutral, da ein beendeter
  Übungseinsatz keine Aktion mehr erfordert). `draft`/`discarded` erscheinen laut Backend-Filterung ohnehin
  nie in dieser App-Liste (nur Mannschaft-Berechtigung sieht diesen Screen).
- **Pull-to-Refresh:** `RefreshIndicator` bleibt, Spinner-Farbe `primary` statt Flutter-Default.
- **Hell/Dunkel:** Listen-/Chip-Token nach Tabelle 2.1, Trennlinien `outline` in beiden Modi.
- **Offline:** kein eigener Offline-Indikator auf diesem Screen im aktuellen Code — Verbindungsverlust läuft
  über denselben Fehlerzustand wie ein Ladefehler (`_LoadState.error`), kein neues Banner eingeführt.

## 5. Interaktionen

- Tap auf eine Zeile navigiert zu `/einsaetze/:id` (Einsatzdetail).
- Pull-to-Refresh lädt neu (`_load()`).
- Zahnrad-Icon navigiert zu `/settings`.
- Realtime-Update (`pairedIncidentsProvider`-Änderung) löst automatisch `_load()` erneut aus (Listener in
  `build()`), kein manuelles Eingreifen nötig — unverändert.

## 6. Testbare Akzeptanzkriterien

1. Der Status-Chip für `running`-Einsätze verwendet `primaryContainer`/`primary`, niemals `alarm`/`onAlarm`
   oder `Colors.red`.
2. Der Status-Chip für `closed`-Einsätze verwendet `surfaceVariant`/`onSurfaceVariant`.
3. Jede Listenzeile hat Mindesthöhe 48 dp und einen sichtbaren Trenner (`outline`, 1px) zur nächsten Zeile.
4. Der Fehlerzustand zeigt einen erklärenden Hinweis auf Pull-to-Refresh als Wiederholungsweg.
5. Leer- und Fehlerzustand bleiben weiterhin innerhalb eines `RefreshIndicator`-fähigen scrollbaren
   Containers (Pull-to-Refresh funktioniert auch bei leerer/fehlerhafter Liste).
6. Tap auf eine Zeile navigiert korrekt zu `/einsaetze/<id>`.
7. Alle Chip-Text-auf-Fläche-Kombinationen erreichen WCAG AA in hell und dunkel.

## 7. Zu erhaltende Keys + Semantics labels

Aus `screens/incidents_screen.dart` (keine `Semantics`/`tooltip` im Quellcode):

- `Key('settings')` — Zahnrad-IconButton in der AppBar.
- `Key('incidents-list')` — die `ListView`.
- `Key('incident-${incident.id}')` dynamisch — jede Listenzeile.

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Einsätze: anzeigen — `incidents_screen_test.dart` | Gleiche Liste, gleiche Keys, neue Chip-Farben | Ja |
| Einsätze: Leerzustand/Fehlerzustand — „Kein laufender BF-Tag."/„Noch keine Einsätze." | Gleiche Texte, ergänzt um Icon + (im Fehlerfall) Pull-to-Refresh-Hinweis | Ja |

Keine Funktion entfällt.
