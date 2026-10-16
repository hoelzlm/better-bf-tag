# Tagesablauf — Admin-Web

Grundlage: `docs/design/design-system.md`. Quelle: `apps/web/lib/screens/program_screen.dart`.

## 1. Zweck

Betreuer in der Einsatzvorbereitung pflegt den Tagesablauf (Essen, Ausbildung, Fahrzeugpflege, Nachtruhe,
Sonstiges) vor bzw. während des BF-Tags — wird auf dem Monitor und in der App angezeigt. Ruhige Planungsaufgabe,
kein Zeitdruck wie Einsätze/Alarmierung.

## 2. Usability-Probleme heute

Screenshot: `docs/design/screenshots/before/web/tagesablauf-1440x900.png`.

1. „Programmpunkt anlegen“-Button ist in der hellen Seed-Rot-Akzentfarbe gehalten — sieht wie eine
   alarmnahe/destruktive Aktion aus, obwohl es die harmloseste Aktion auf der Seite ist (Grundprinzip „Rot =
   Alarm“ aus dem Designsystem wird hier verletzt).
2. Liste ist eine nackte `ListTile`-Spalte, Icon je Typ (Besteck, Mütze, …) klein (24 px) und ohne Farbcodierung
   — alle Typen sehen in der Icon-Farbe gleich aus, nur an der Form unterscheidbar.
3. Zeitspanne und Typ stehen in einer Zeile mit `·`-Trenner als reiner Fließtext — bei einem vollen Tagesablauf
   (viele Punkte) ist die Startzeit nicht klar ausgerichtet, schwer vertikal zu scannen/vergleichen.
4. Bearbeiten-/Löschen-Icons (Stift/Mülleimer, je 24 px) hängen ohne Abstand nebeneinander rechts, kleine
   Klickfläche, Verwechslungsgefahr bei Eile.
5. Kein visueller Hinweis auf die Reihenfolge/zeitliche Lücken zwischen Programmpunkten (z. B. Leerzeit
   zwischen zwei Punkten) — Liste wirkt wie eine beliebige Aufzählung, nicht wie ein Tagesablauf.

## 3. Neues Layout

```
┌───────────────────────────────────────────────────────────────────────────┐
│ Tagesablauf                     BF-Tag: [Alarmübung Herbst ▾]  [+ Programmpunkt anlegen] │
├───────────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ 09:04–09:34   🍴  Mittagessen                               ✎  🗑     │ │ Zeitspalte fix 96px, outline-Trenner
│ │               Essen                                                   │ │
│ ├─────────────────────────────────────────────────────────────────────┤ │
│ │ 09:44–10:44   🎓  Ausbildung Löschtechnik                   ✎  🗑     │ │
│ │               Ausbildung                                              │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────────┘
```

Änderungen:

- „Programmpunkt anlegen“ wird `primary`-farbener `FilledButton.icon` (nicht `alarm`) — korrigiert die
  Farbverletzung, wandert in den Topbar neben die BF-Tag-Auswahl (gleiche Konvention wie die anderen Screens
  dieser Karte).
- BF-Tag-Dropdown wandert ebenfalls in den Topbar mit vorangestelltem Label „BF-Tag:“ (statt separat im
  Content, spart eine Zeile, macht den Kontext sofort sichtbar).
- Liste: feste Zeitspalte links (`monitorBody`-ähnliches, aber Web-`bodyLarge`/`titleMedium` je nach Dichte),
  Typ-Icon in einer farbigen `radiusSmall`-Kachel (`primaryContainer`-Fläche, `primary`-Icon) statt nacktem
  Icon — bessere Scanbarkeit nach Typ.
- Bearbeiten/Löschen-Icons bekommen 8 px Abstand (`BftagSpacing.sm`) und size ≥ 40 px Klickfläche
  (Touch-Ziel-Reserve auch auf Tablet-Breite).
- Read-only bei beendetem BF-Tag: Icons verschwinden (bestehendes Verhalten, `trailing: null`), zusätzlich
  kleines Schloss-Icon + „Dieser BF-Tag ist beendet — nur lesend“ im Topbar (neu, macht den Grund sichtbar
  statt implizit über fehlende Buttons).

## 4. Alle Zustände

- **Laden:** zentrierter `CircularProgressIndicator`.
- **Leer (keine BF-Tage):** „Keine BF-Tage angelegt.“ zentriert (bestehender Text, neu gerahmt nach
  Designsystem 5.10).
- **Leer (keine Programmpunkte):** Icon `event_note` 48 px + „Keine Programmpunkte vorhanden.“ + Primäraktion
  „Programmpunkt anlegen“ (sofern Tag nicht beendet).
- **Fehler:** „BF-Tage konnten nicht geladen werden.“ bzw. „Programmpunkte konnten nicht geladen werden.“ +
  „Erneut versuchen“.
- **Fehler bei Anlegen/Bearbeiten/Löschen:** SnackBar mit `describeProgramItemError`-Text, Dialog/Liste bleibt
  wie zuvor.
- **Dialog Anlegen/Bearbeiten:** Titel (≤ 80 Zeichen, Zähler), Typ-Dropdown, Start-/Ende-Auswahl je als
  `ListTile` mit Kalender-Icon (bestehend) — Start/Ende bekommen in ux-03 eine Prüfung „Ende nach Start“
  (neu, verhindert einen sonst stillen Logikfehler; keine Funktionsänderung, nur zusätzliche Validierung).
- **Destructive Confirmation (Löschen):** „Programmpunkt löschen“ / „„{Titel}“ wirklich löschen?“ — Titel/Text
  neutral, nur „Löschen“-Button `alarm`-farben.
- **Read-only (BF-Tag beendet):** keine Anlegen-/Bearbeiten-/Löschen-Aktionen sichtbar, Hinweis im Topbar.
- **Offline:** kein eigener Zustand (kein Realtime-Abo).
- **Ohne Berechtigung:** Route `/admin/tagesablauf` ist für **Mannschaft und Einsatzvorbereitung** gesperrt
  (`router.dart`: `isTagesablaufRoute && person.permission != Permission.admin && person.permission !=
  Permission.dispatch` → Redirect nach `/admin`); nur **Leitstelle und Administrator** erreichen den Screen,
  Navigation blendet den Menüpunkt für die anderen beiden aus (`web-navigation.md`).

## 5. Interaktionen

- Tab-Reihenfolge: BF-Tag-Dropdown → „Programmpunkt anlegen“ → Liste (je Zeile: Bearbeiten → Löschen).
- Klick auf eine Zeile außerhalb der Icons öffnet **nicht** automatisch den Bearbeiten-Dialog (anders als
  Fahrzeuge/Monitore) — bestehendes Verhalten erhalten, da hier zwei getrennte Icon-Aktionen existieren statt
  einer impliziten „Zeile = bearbeiten“-Konvention; nur das Stift-Icon öffnet Bearbeiten.
- Start-/Ende-Picker: Flutter-Standard-`showDatePicker`/`showTimePicker`, vollständig tastaturbedienbar.

## 6. Testbare Akzeptanzkriterien

1. Programmpunkte werden nach Startzeit sortiert angezeigt.
2. „Programmpunkt anlegen“ öffnet den Anlegen-Dialog; Speichern ruft `create()` mit Titel/Typ/Start/Ende auf.
3. Stift-Icon öffnet den Bearbeiten-Dialog vorausgefüllt; Speichern ruft `update()` mit der Item-ID auf.
4. Mülleimer-Icon öffnet die Bestätigung; erst nach Bestätigen wird `delete()` aufgerufen.
5. Bei beendetem BF-Tag sind weder „Programmpunkt anlegen“ noch Bearbeiten-/Löschen-Icons sichtbar/aktiv.
6. Ladefehler bei BF-Tagen bzw. beim Anlegen/Löschen zeigt die jeweilige Fehlermeldung.
7. Keine BF-Tage / keine Programmpunkte zeigen den jeweiligen Leerzustand.
8. Typ-Icon-Kachel zeigt die richtige Farbe/Form je `ProgramItemType` (meal/training/maintenance/rest/other).

## 7. Zu erhaltende Keys + Semantics

Aus `apps/web/lib/screens/program_screen.dart`:

- `bf-day-dropdown`
- `program-add`
- `program-list`
- `program-item-${item.id}` je Zeile
- `program-edit-${item.id}`, `program-delete-${item.id}`
- `program-form-title`, `program-form-type`, `program-form-start`, `program-form-end`
- `program-form-submit`
- `confirm-dialog-confirm` (lokale `_confirm`-Hilfsfunktion dieses Screens, gleicher Name wie in anderen
  Screens, aber eigene lokale Funktion — kein geteiltes Widget wie bei Durchsagen)

## 8. Flows

Keine Funktion fällt weg. Mapping gegen Regressionsinventar § Tagesablauf: anzeigen, anlegen, bearbeiten,
löschen, Fehlerzustand, Leerzustand — alle erhalten; Farbfehler (Rot für eine harmlose Aktion) korrigiert,
BF-Tag-Auswahl in den Topbar verschoben, zusätzliche (nicht ersetzende) Start/Ende-Validierung vorgeschlagen.
