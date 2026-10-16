# Einsätze — Admin-Web

Grundlage: `docs/design/design-system.md`. Quelle: `apps/web/lib/screens/incidents_screen.dart`,
`apps/web/lib/widgets/alarm_dialog.dart`. Mockups: `docs/design/mockups/web-einsaetze.html`/`.png` (Filter
Entwurf), `web-einsaetze-laufend.html`/`.png` (Filter laufend), `web-einsaetze-alarm.html`/`.png`
(`AlarmDialog`).

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
│  (Entwurf ●)  (laufend)  (abgeschlossen)                                  │  Segmented, aktiv = primaryContainer
├───────────────────────────────────────────────────────────────────────────┤
│ ┌───────────────────────────────────────────────────────┬───────────────┐ │  Karte je Einsatz, ~96 px hoch
│ │ #1 B3 Großbrand Lagerhalle              [Entwurf]       │  Verwerfen    │ │  titleMedium + Status-Label
│ │ Industriestraße 7                                       │ [Alarmieren] │ │  bodyMedium, Aktionsspalte vertikal zentriert
│ └───────────────────────────────────────────────────────┴───────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
```

Siehe `web-einsaetze.html`/`.png` für die gerenderte Fassung im Filter „Entwurf“ (die für den kritischen Pfad
wichtigste Ansicht: Alarmieren + Verwerfen), `web-einsaetze-laufend.html`/`.png` für den Filter „laufend“
(Nachalarmieren, „seit X min“-Meta) und `web-einsaetze-alarm.html`/`.png` für den `AlarmDialog`
(Fahrzeug-Checkboxen, Doppelbesetzung-Warnung, roter „Jetzt alarmieren“-Button).

Änderungen:

- BF-Tag-Auswahl in den Topbar mit Label „BF-Tag:“ (wie Tagesablauf), „Einsatz anlegen“ als Topbar-Primärbutton
  statt FAB (gleiche Begründung wie bei Fahrzeuge — Konsistenz, kein Überlappungsrisiko).
- Jeder Einsatz wird eine **Karte** (`surfaceVariant`, `radiusLarge`) statt einer `ListTile`-Zeile, aber deutlich
  kompakter als eine normale Karte: Titelzeile mit Stichwort (`titleMedium`, `onSurface`) und „#Nummer“ als
  vorangestelltes `labelLarge`-Badge, Adresse direkt darunter (`bodyMedium`, `onSurfaceVariant`) — zusammen
  **eine** Zeile Zielhöhe von ca. 96 px statt der heutigen ~140 px für zwei Textzeilen (engerer vertikaler
  Abstand `BftagSpacing.sm` statt `md`, keine zusätzliche Leerzeile zwischen Titel und Adresse).
- **Zustands-Label ist immer sichtbar** (architektonische Entscheidung, nicht optional): jede Karte trägt
  rechts neben dem Titel ein kompaktes `Chip`-Label mit dem aktuellen Zustand (`incident-state-${id}`), auch
  wenn der Filter-Tab denselben Zustand bereits anzeigt. Begründung: der Zustand einer Karte kann sich *während*
  des Betrachtens ändern (Realtime-Reload nach Alarmieren/Nachalarmieren), ohne das Label wäre nicht erkennbar,
  dass eine Karte gerade den Filter „verlassen“ hat/verlassen wird, bevor die Liste neu lädt. Löst damit auch
  den Widerspruch aus Review-Runde 1 (Label vs. Key).
- Rechts von Titel/Adresse eine schmale, **vertikal zentrierte** Aktionsspalte (`CrossAxisAlignment.center` im
  `Row`, Breite fix ~160 px) statt der Positionierung „unten rechts“ — macht die Primäraktion unabhängig von der
  Textlänge immer auf gleicher Höhe, wichtig für schnelles Scannen vieler Einsätze.
- Nur bei Zustand „laufend“ zusätzlich ein kompaktes „seit {Minuten} min“-Meta über der Aktionsspalte
  (`labelMedium`, `onSurfaceVariant`, grüner Live-Punkt). **Datenquelle:** kein neues API-Feld — `Incident`
  selbst hat keinen Alarmzeitpunkt, aber der Screen beobachtet bereits `alarmsProvider` (ADR 0022, Zeile
  `ref.watch(alarmsProvider)` in `incidents_screen.dart`); „seit X min“ ist `DateTime.now().difference` zum
  frühesten `triggeredAt` unter allen `Alarm`s mit `incidentId == incident.id` (= Erstalarm). Existiert noch
  keine ausgelöste Alarmierung (nur geplant), entfällt das Meta ersatzlos — kein Platzhaltertext.
- **Primäraktion wird text-tragender Button, nicht Icon:** „Alarmieren“ (Entwurf) bzw. „Nachalarmieren“
  (laufend) als `alarm`-farbener `FilledButton.icon` (Icon `notification_important` + Text), oben in der
  Aktionsspalte — größte, auffälligste interaktive Fläche der Zeile. „Verwerfen“ (nur Entwurf) bleibt als
  unauffälligerer `TextButton` darüber, damit die Blickführung eindeutig zur Alarm-Aktion (unten, größer) geht.
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

### 3.4 Kritischer Pfad: Einsatz anlegen → alarmiert

Dies ist die Flow-Optimierung, die der Auftrag am stärksten verlangt. Keine neue Funktion (kein kombinierter
„Speichern & alarmieren“-Button) — nur Fokus-/Filter-Automatik auf bestehenden Schritten.

**Heute** (Leitstelle, BF-Tag bereits ausgewählt), mindestens 7 Interaktionen, davon 2 reine
Navigations-Leerschritte ohne Fachwert:

1. Klick „Einsatz anlegen“ (FAB).
2. Formular ausfüllen, Klick „Speichern“ — Einsatz wird angelegt, Dialog schließt.
3. **Navigations-Leerschritt:** Filter manuell auf „Entwurf“ wechseln (falls man vorher z. B. „laufend“
   betrachtet hat — der neue Einsatz ist `draft` und erscheint im aktuellen Filter nicht).
4. **Navigations-Leerschritt:** die neue Zeile in der Liste suchen/scrollen (kein Hervorhebung, keine
   automatische Position).
5. Klick auf den Alarmieren-Icon-Button der gefundenen Zeile.
6. Fahrzeug(e) in der Checkbox-Liste anklicken.
7. Klick auf „Jetzt alarmieren“ — und danach keine sichtbare Bestätigung außer dem Verschwinden der Zeile aus
   dem weiterhin aktiven „Entwurf“-Filter (der Einsatz ist jetzt `running`, also herausgefiltert — wirkt wie
   ein stiller Fehlschlag, wenn man das Filterverhalten nicht kennt).

**Neu**, 4 Interaktionen, keine Navigations-Leerschritte, nutzt ausschließlich bestehende Funktionen:

(a) Nach erfolgreichem `create()`: Filter schaltet automatisch auf „Entwurf“, die Liste scrollt die neue Karte
    sichtbar ins Blickfeld und hebt sie kurz (~700 ms, `primaryContainer`-Einblendung, dann Normalfarbe) hervor.
    Der Tastaturfokus wandert direkt auf den „Alarmieren“-Button dieser Karte — kein Suchen, kein Scrollen.
    Klick **oder** `Enter`/`Leertaste` (Fokus liegt bereits dort) auf „Alarmieren“ öffnet den `AlarmDialog`.
(b) Der `AlarmDialog` öffnet mit Tastaturfokus auf der ersten Fahrzeug-Checkbox (`alarm-vehicle-${id}` der
    ersten Zeile in `vehicles`); `Tab`/`Leertaste` wählt weitere Fahrzeuge ohne die Maus.
    `Enter` löst **denselben** Submit wie ein Klick auf „Jetzt alarmieren“ aus, sobald `_canSubmit` wahr ist
    (mind. ein Fahrzeug gewählt) — rein tastaturbasiert vom fokussierten Alarmieren-Button bis zur ausgelösten
    Alarmierung möglich, ohne die Maus zu benutzen.
(c) Nach erfolgreichem Sofort-Alarm (`trigger()` erfolgreich, kein „bereits alarmiert“-Fehler): Filter schaltet
    automatisch auf „laufend“ — der eben alarmierte Einsatz bleibt sichtbar, jetzt mit Zustands-Label „laufend“
    und „seit 0 min“-Meta statt spurlos aus der Ansicht zu verschwinden. Das ist die fehlende positive
    Rückmeldung von heute.

Damit sinkt der Weg von „Einsatz anlegen“-Klick bis ausgelöster Alarmierung von 7 auf 4 Schritte, und die
beiden Stellen, an denen der Bediener heute manuell nach der richtigen Ansicht/Zeile suchen muss, entfallen
vollständig — ohne eine neue Schaltfläche oder einen neuen Serveraufruf einzuführen.

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
- **Ohne Berechtigung:** Route `/admin/einsaetze` ist für **Mannschaft** gesperrt (`router.dart`:
  `isEinsaetzeRoute && person.permission == Permission.crew` → Redirect nach `/admin`); die Navigation blendet
  den Menüpunkt für Mannschaft entsprechend aus (`web-navigation.md`). **Einsatzvorbereitung, Leitstelle und
  Administrator** erreichen den Screen. Innerhalb des Screens gilt eine zweite, feinere Grenze (`canAlarm` in
  `incidents_screen.dart`): **Einsatzvorbereitung** sieht die volle Liste, kann Einsätze anlegen/bearbeiten/
  verwerfen, aber die Buttons „Alarmieren“ und „Nachalarmieren“ sind für sie **nicht vorhanden** (nicht nur
  deaktiviert) — nur Leitstelle und Administrator sehen diese beiden Buttons. Kein zusätzlicher Hinweistext
  nötig, da die fehlende Aktion selbsterklärend neben den vorhandenen Aktionen (Verwerfen) steht.

## 5. Interaktionen

- Tab-Reihenfolge: BF-Tag-Dropdown → Filter-Segmente → „Einsatz anlegen“ → Karten (je Karte: Titel/Klickfläche
  → Verwerfen → Alarmieren/Nachalarmieren).
- Klick auf die Karte außerhalb der Buttons öffnet den Bearbeiten-Dialog (bestehendes `onTap` auf der Zeile,
  jetzt auf die ganze Karte erweitert außer den Aktionsbuttons selbst).
- `Enter`/`Leertaste` auf einem fokussierten Alarmieren-Button löst denselben Dialog aus wie ein Klick.
- Nach erfolgreichem Anlegen wandert der Fokus programmatisch auf den „Alarmieren“-Button der neuen Karte
  (§3.4a) — danach gilt wieder die normale Tab-Reihenfolge ab dieser Position.
- Im Alarmieren-Dialog: Checkbox-Liste der Fahrzeuge vollständig tastaturbedienbar (`Tab`/`Leertaste`),
  initialer Fokus auf der ersten Checkbox, `Enter` löst den Submit aus (§3.4b); Datum-/Zeit-Picker
  Flutter-Standard (tastaturbedienbar).

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
15. Nach erfolgreichem Anlegen schaltet der Filter automatisch auf „Entwurf“, die neue Karte scrollt sichtbar
    ins Blickfeld und wird kurz hervorgehoben (kritischer Pfad, §3.4a).
16. Nach erfolgreichem Anlegen liegt der Tastaturfokus auf dem „Alarmieren“-Button der neuen Karte (§3.4a).
17. Beim Öffnen des `AlarmDialog` liegt der initiale Tastaturfokus auf der ersten Fahrzeug-Checkbox (§3.4b).
18. `Enter` im `AlarmDialog` löst denselben Submit wie ein Klick auf den Submit-Button aus, sobald
    `_canSubmit` wahr ist; bei ungültiger Eingabe (kein Fahrzeug gewählt) löst `Enter` nichts aus (§3.4b).
19. Nach erfolgreichem Sofort-Alarm (`trigger()`, kein „bereits alarmiert“-Fehler) schaltet der Filter
    automatisch auf „laufend“; der soeben alarmierte Einsatz bleibt mit aktualisiertem Zustands-Label und
    „seit 0 min“-Meta sichtbar (§3.4c). Nachalarmierung und Planen (Zeitpunkt/Relativ) ändern den Filter
    nicht (Einsatz ist bereits `running` bzw. bleibt `draft`).
20. Jede Karte zeigt unabhängig vom aktiven Filter ein Zustands-Label mit Key `incident-state-${id}` (§3.1).
21. Bei Zustand `running` mit mindestens einem ausgelösten `Alarm` zeigt die Karte „seit {Minuten} min“,
    berechnet aus dem frühesten `triggeredAt` dieses Einsatzes; ohne ausgelösten Alarm entfällt das Meta.
22. Für Berechtigung Einsatzvorbereitung sind „Alarmieren“ und „Nachalarmieren“ auf keiner Karte vorhanden,
    „Einsatz anlegen“, Bearbeiten und „Verwerfen“ bleiben verfügbar.

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
beibehalten), „Verwerfen“ bleibt mit Bestätigung. Der kritische Pfad (§3.4) fügt ebenfalls keine neue Funktion
hinzu: Filterwechsel, Scrollen-in-Sicht und Fokussteuerung sind reine Automatisierung von Schritten, die der
Bediener heute manuell selbst ausführt (Filter-Segment anklicken, scrollen, Tab zum Button) — jede dieser
Handlungen bleibt über die bestehenden Bedienelemente auch weiterhin möglich.
