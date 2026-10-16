# Einsätze — Admin-Web

Grundlage: `docs/design/design-system.md`. Quelle: `apps/web/lib/screens/incidents_screen.dart`,
`apps/web/lib/widgets/alarm_dialog.dart`. Mockup: `docs/design/mockups/web-einsaetze.html`/`.png`.

## 1. Zweck

**Leitstelle/Einsatzvorbereitung während des BF-Tags, oft unter Zeitdruck.** Dies ist der zeitkritischste
Admin-Web-Screen überhaupt: hier wird ein Übungs-Einsatz vorbereitet (Entwurf) und dann **alarmiert** — die
Sekunden zwischen „ich will jetzt alarmieren“ und „Fahrzeuge sind alarmiert“ zählen für den Ablauf des BF-Tags.
Dieselbe Seite wird auch für Nachalarmierungen laufender Einsätze und zum Verwerfen nicht benötigter Entwürfe
benutzt. Entsprechend ist dieser Screen in der Konzeption am stärksten optimiert.

## 2. Usability-Probleme heute

Screenshots: `docs/design/screenshots/before/web/einsaetze-1440x900.png`,
`docs/design/screenshots/before/web/einsaetze-empty-1440x900.png`.

1. „Alarmieren“/„Nachalarmieren“ sind reine **Icon-Buttons** (`campaign`-Icon, 24 px, nur Tooltip) — die
   wichtigste Handlung der ganzen App ist optisch nicht von einem beliebigen Icon-Button zu unterscheiden,
   kein Text, keine Hervorhebung, keine Farbe, die auf die Dringlichkeit hinweist.
2. Zustands-Chip „laufend“/„Entwurf“/„abgeschlossen“ erscheint sowohl im Segmented-Filter oben als auch als
   Chip in jeder Zeile — bei einem gefilterten Blick auf „laufend“ steht in jeder Zeile redundant nochmal
   „laufend“, verschwendet Platz, der für die Adresse gebraucht würde.
3. Zeilentitel `#1 Stichwort – Adresse` ist ein einziger Fließtext ohne Hierarchie — bei langem Stichwort oder
   langer Adresse nicht klar, wo das eine endet und das andere beginnt; keine Typo-Abstufung.
4. BF-Tag-Dropdown trägt kein Label „BF-Tag“ davor (nur der Name selbst, im Test-Screenshot sogar doppelt
   „Screenshots screenshots“ sichtbar) — beim ersten Öffnen der Seite nicht sofort erkennbar, wofür das
   Dropdown steht.
5. Leerzustand (`einsaetze-empty-1440x900.png`) zeigt nur „Keine Einsätze vorhanden.“ klein mittig — in der
   Leitstelle, wo man unter Druck schnell einen Einsatz anlegen will, fehlt ein direkter Hinweis/CTA in
   Blicknähe (die FAB unten rechts ist weit vom Fokuspunkt der Meldung entfernt).
6. Im Anlege-/Bearbeiten-Dialog ist das Drehbuch (geheim) nur über eine amber/orange Fläche markiert — dieselbe
   Farbfamilie, die im neuen Designsystem für **Formularfehler** reserviert ist (`warning`-Token); Wieder-
   verwendung hier würde „Drehbuch“ wie einen Fehlerzustand aussehen lassen, ist aber nur eine Vertraulichkeits-
   Kennzeichnung — Bedeutungskollision.
7. Die „Doppelbesetzung“-Warnung im Alarmieren-Dialog ist ebenfalls Orange/Amber, aber inhaltlich tatsächlich
   eine Warnung (keine Fehlfunktion, aber relevanter Hinweis) — richtige Bedeutung, falsche/undokumentierte
   Farbe (Material-Named-Color statt Token).
8. Kein sichtbarer Unterschied zwischen „Alarmieren“ (Erstalarm, einschneidend) und „Nachalarmieren“ (Zusatz)
   außer dem Tooltip-Text — beide nutzen dasselbe Icon in gleicher Farbe.

## 3. Neues Layout

### 3.1 Liste (Hauptansicht)

```
┌───────────────────────────────────────────────────────────────────────────┐
│ Einsätze                 BF-Tag: [Alarmübung Herbst ▾]    [+ Einsatz anlegen] │
├───────────────────────────────────────────────────────────────────────────┤
│  (Entwurf)  (laufend ●)  (abgeschlossen)                                  │  Segmented, aktiv = primaryContainer
├───────────────────────────────────────────────────────────────────────────┤
│ ┌─ laufend ───────────────────────────────────────────────────────────┐ │  Karte je Einsatz
│ │ #1 B3 Großbrand Lagerhalle                            seit 12 min    │ │  titleLarge
│ │ Industriestraße 7                                                     │ │  bodyMedium, onSurfaceVariant
│ │                                        [ ⚠ Nachalarmieren ]          │ │  alarm-farbener FilledButton
│ └─────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
```

Siehe `web-einsaetze.html`/`.png` für die gerenderte Fassung (BF-Tag-Topbar + Filter + 3 Einsatzkarten in den
Zuständen Entwurf/laufend/abgeschlossen).

Änderungen:

- BF-Tag-Auswahl in den Topbar mit Label „BF-Tag:“ (wie Tagesablauf), „Einsatz anlegen“ als Topbar-Primärbutton
  statt FAB (gleiche Begründung wie bei Fahrzeuge — Konsistenz, kein Überlappungsrisiko).
- Jeder Einsatz wird eine **Karte** (`surfaceVariant`, `radiusLarge`) statt einer `ListTile`-Zeile: Titelzeile
  mit Stichwort (`titleLarge`, `onSurface`) und „#Nummer“ als vorangestelltes `labelLarge`-Badge; Adresse auf
  eigener Zeile (`bodyMedium`, `onSurfaceVariant`); rechts oben kompaktes Meta („seit 12 min“ für laufend).
  Der redundante Zustands-Chip entfällt **im gefilterten Zustand** (der Filter-Tab zeigt den Zustand bereits) —
  bleibt aber als kleines Label in der Kartenecke sichtbar, wenn eine zukünftige Gesamtansicht ohne Filter
  gebraucht würde (aktuell nicht der Fall, Filter ist immer aktiv).
- **Primäraktion wird text-tragender Button, nicht Icon:** „Alarmieren“ (Entwurf) bzw. „Nachalarmieren“
  (laufend) als `alarm`-farbener `FilledButton.icon` (Icon `notification_important` + Text), rechts unten in
  der Karte — größte, auffälligste interaktive Fläche der Zeile. „Verwerfen“ (nur Entwurf) bleibt als
  unauffälligerer `TextButton` links davon, damit die Blickführung eindeutig zur Alarm-Aktion geht.
  Die beiden Aktionen sind durch den Button-**Text** unterscheidbar („Alarmieren“ vs. „Nachalarmieren“), nicht
  nur durch Tooltip — löst Problem 1 und 8 zusammen.
- Leerzustand bekommt einen deutlich größeren, zentrierten Block mit Icon `local_fire_department` 48 px,
  „Keine Einsätze im Zustand {Filter}.“ und — nur im Zustand „Entwurf“ — direkt eine Primäraktion „Einsatz
  anlegen“ in Blicknähe der Meldung (zusätzlich zum Topbar-Button).

### 3.2 Dialog „Einsatz anlegen/bearbeiten“

Struktur bleibt (Meldebild-Felder, Karte, Drehbuch-Block), aber:

- Drehbuch-Block wechselt von Amber/`warning`-naher Farbe zu einer eigenen „Vertraulich“-Kennzeichnung:
  `surfaceContainer`-Fläche + 1 px `outline`-Rahmen + Schloss-Icon in `onSurfaceVariant` (nicht `warning`,
  nicht `alarm`) — Vertraulichkeit ist keine Fehler-/Alarmkategorie, braucht also keinen Status-Token, sondern
  nur klare Flächentrennung (Designsystem 4.3). Titel „Drehbuch — geheim, nie für die Mannschaft sichtbar“
  bleibt wortgleich erhalten.

### 3.3 Alarmieren-Dialog (`AlarmDialog`)

- „Doppelbesetzung“-Warnung wechselt von `Colors.orange` auf die `warning`-Tokenfarbe (Designsystem 2.1/5.10) —
  korrekte, dokumentierte Fläche für „kein Fehler, aber wichtiger Hinweis vor dem Absenden“.
- Submit-Button („Jetzt alarmieren“ / „Planen“) wird `alarm`-farben (Designsystem 5.1: Aktionen, die einen
  Alarm auslösen) statt der heutigen `primary`-Default-Farbe — macht die Tragweite des Klicks sichtbar, bevor
  er passiert, nicht erst danach.
- Fahrzeugauswahl, Zeitmodus (Sofort/Zeitpunkt/Relativ) bleiben inhaltlich unverändert, nur im neuen
  Komponentenstil (Designsystem 5.1/5.2).

## 4. Alle Zustände

- **Laden (Tage/Einsätze):** zentrierter `CircularProgressIndicator`.
- **Leer (keine BF-Tage):** „Keine BF-Tage angelegt.“
- **Leer (keine Einsätze im Filter):** siehe 3.1, mit Primäraktion bei „Entwurf“.
- **Fehler (Laden):** „BF-Tage konnten nicht geladen werden.“ / „Einsätze konnten nicht geladen werden.“ +
  „Erneut versuchen“.
- **Fehler (Anlegen/Bearbeiten/Verwerfen):** SnackBar mit `describeIncidentError`-Text.
- **Fehler (Alarmieren/Planen):** Inline-Fehlertext im Dialog (`_error`, `warning`-Farbe) statt Dialog-Schluss,
  bestehendes Verhalten — Ausnahme „Einsatz wurde bereits alarmiert.“, die den Dialog schließt und per SnackBar
  informiert (idempotenter Doppelklick-Schutz, bleibt unverändert).
- **Doppelbesetzung-Warnung:** `warningContainer`-Block im Alarmieren-Dialog, Liste betroffener Personen.
- **Destructive Confirmation (Verwerfen):** „Einsatz verwerfen“ / „Einsatz #… „…“ wirklich verwerfen?“ (+
  Hinweis auf mitverworfene geplante Alarmierungen, bestehender Text) — Titel/Text neutral, nur „Verwerfen“-
  Button `alarm`-farben.
- **Geplante Alarmierung ohne Erstalarm:** „Relativ zum Erstalarm“-Option im Dialog deaktiviert mit Hinweistext
  „Erst verfügbar, sobald es einen Erstalarm gibt.“ (bestehendes Verhalten, `onSurfaceVariant`-Text).
- **Read-only (abgeschlossener Einsatz):** Formularfelder `readOnly`, Karten-Aktionen (Pin entfernen,
  Adresssuche) ausgeblendet, „Speichern“-Button entfällt — bestehendes Verhalten.
- **Offline:** kein eigener Zustand auf diesem Screen selbst (Liste lädt einmalig; Verbindungsstatus wird in
  `vehicle_status_bar`/Lage behandelt).

## 5. Interaktionen

- Tab-Reihenfolge: BF-Tag-Dropdown → Filter-Segmente → „Einsatz anlegen“ → Karten (je Karte: Titel/Klickfläche
  → Verwerfen → Alarmieren/Nachalarmieren).
- Klick auf die Karte außerhalb der Buttons öffnet den Bearbeiten-Dialog (bestehendes `onTap` auf der Zeile,
  jetzt auf die ganze Karte erweitert außer den Aktionsbuttons selbst).
- `Enter`/`Leertaste` auf einem fokussierten Alarmieren-Button löst denselben Dialog aus wie ein Klick.
- Im Alarmieren-Dialog: Checkbox-Liste der Fahrzeuge vollständig tastaturbedienbar (`Tab`/`Leertaste`),
  Datum-/Zeit-Picker Flutter-Standard (tastaturbedienbar).

## 6. Testbare Akzeptanzkriterien

1. Filter-Segmente (Entwurf/laufend/abgeschlossen) zeigen jeweils nur Einsätze im gewählten Zustand.
2. „Einsatz anlegen“ (Topbar) öffnet den Anlegen-Dialog nur, wenn ein BF-Tag ausgewählt und nicht beendet ist.
3. Speichern im Anlegen-Dialog ruft `create()` mit Stichwort/Adresse/Meldebild/Drehbuch/Koordinaten auf.
4. Klick auf eine Karte (außerhalb der Buttons) öffnet den Bearbeiten-Dialog vorausgefüllt.
5. „Alarmieren“ ist nur bei Zustand `draft` und Berechtigung Leitstelle/Administrator sichtbar; öffnet den
   `AlarmDialog` mit `hasFirstAlarm: false`.
6. „Nachalarmieren“ ist nur bei Zustand `running` und Berechtigung Leitstelle/Administrator sichtbar; öffnet
   den `AlarmDialog` mit den bereits alarmierten Fahrzeug-IDs vorbelegt (deaktiviert, „bereits alarmiert“).
7. „Verwerfen“ ist nur bei Zustand `draft` sichtbar, öffnet die Bestätigung, ruft erst danach `discard()` auf.
8. Im `AlarmDialog`: Submit ist erst aktiv, wenn mindestens ein Fahrzeug gewählt ist (und im Zeitpunkt-/
   Relativ-Modus die jeweilige Zusatzangabe gültig ist).
9. Doppelbesetzung einer Person auf mehreren gewählten Fahrzeugen zeigt den Warnhinweis mit Namen.
10. Sofort-Modus ruft `trigger()` auf und schließt den Dialog mit `true` bei Erfolg; „bereits alarmiert“-Fehler
    schließt den Dialog ebenfalls mit `true` und zeigt die Meldung als SnackBar (kein doppelter Alarm).
11. Zeitpunkt-/Relativ-Modus ruft `plan()` mit den jeweiligen Zusatzangaben auf.
12. Leere Einsatzliste im Filter zeigt den Leerzustand; bei „Entwurf“ zusätzlich eine Primäraktion.
13. Ladefehler (BF-Tage/Einsätze) zeigt die jeweilige Fehlermeldung statt der Liste/des Dropdowns.
14. Abgeschlossene Einsätze zeigen im Bearbeiten-Dialog alle Felder `readOnly`, keinen „Speichern“-Button.

## 7. Zu erhaltende Keys + Semantics

Aus `apps/web/lib/screens/incidents_screen.dart`:

- `create-incident`, `bf-day-dropdown`, `incident-filter`, `incidents-list`
- `incident-${incident.id}` je Karte, `incident-state-${incident.id}` (Zustands-Chip)
- `alarm-incident-${incident.id}`, `nachalarmieren-incident-${incident.id}`, `discard-incident-${incident.id}`
- `confirm-dialog-confirm` (Verwerfen-Bestätigung, lokale `AlertDialog` in `_discard`)
- `incident-form-keyword`, `incident-form-address`, `incident-form-report`
- `incident-form-location-search`, `incident-form-location-search-button`, `incident-form-remove-pin`
- `script-section`, `incident-form-script`, `incident-form-submit`

Aus `apps/web/lib/widgets/alarm_dialog.dart`:

- `alarm-vehicle-${vehicle.id}` je Checkbox
- `alarm-double-crewed-warning`, `alarm-double-crewed-${d.personId}`
- `alarm-mode-immediate`, `alarm-mode-scheduled`, `alarm-mode-relative`
- `alarm-pick-date`, `alarm-pick-time`, `alarm-offset-minutes`
- `alarm-dialog-submit`

Tooltips/Semantics bleiben wortgleich: „Alarmieren“, „Nachalarmieren“, „Verwerfen“ — jetzt zusätzlich als
sichtbarer Button-Text, nicht nur als Tooltip (verstärkt, nicht ersetzt).

## 8. Flows

Keine Funktion fällt weg. Mapping gegen Regressionsinventar § Einsätze: anzeigen (Filter), anlegen, bearbeiten,
löschen (= Verwerfen), Fehlerzustand, Leerzustand — alle erhalten. Alarmieren/Nachalarmieren/Planen/Sofort-Logik
aus `AlarmDialog` bleibt vollständig erhalten (ADR 0017/0019/0022), nur die visuelle Gewichtung der
Primäraktion und die Statusfarben der Warnhinweise ändern sich — **keine Bestätigungsstufe wird entfernt oder
hinzugefügt**: „Alarmieren ohne Bestätigung“ bleibt ohne Bestätigung (laut Designsystem 5.1 bewusst
beibehalten), „Verwerfen“ bleibt mit Bestätigung.
