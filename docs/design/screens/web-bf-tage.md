# Admin-Web — BF-Tage

Quelle: `apps/web/lib/screens/bf_days_screen.dart`. Vorher:
`docs/design/screenshots/before/web/bf-tage-1440x900.png`.

## 1. Zweck

Administratoren legen hier BF-Tage an, starten/beenden sie und verwalten Teilnahmen; nach Ende anonymisiert
die Leitstelle oder der Administrator den Tag (ADR 0020). Seltene, aber folgenreiche Aktionen (Start/Ende
betreffen den ganzen Betrieb) — Übersicht muss auch bei nur einem BF-Tag nicht leer wirken, und bei vielen
historischen BF-Tagen (mehrere Saisons) muss die Liste scanbar bleiben.

## 2. Usability-Probleme heute

1. **Riesige leere Fläche unter dem einzigen Eintrag** — `docs/design/screenshots/before/web/bf-tage-1440x900.png`
   zeigt eine Zeile bei y≈80–115, danach bis y=900 nichts außer dem FAB. Bei mehr BF-Tagen würde die Liste
   trotzdem wie eine lose Textzeile wirken, nicht wie ein gepflegtes Verwaltungsformular.
2. **Zustand-Chip „läuft“ kaum als Status erkennbar** — nur ein dünner Outline-Chip ohne Farbcodierung
   (Screenshot oben rechts: „läuft“ in schwachem Kontrast, keine Fläche).
3. **Aktionen rechts bündig ohne klare Trennung**: Teilnahmen-Icon, „Beenden“-Textbutton direkt nebeneinander,
   kein Abstand zu Zustand-Chip — bei zusätzlichen Zuständen (z. B. „Anonymisieren“-Button für beendete Tage)
   würde die Zeile beliebig weiter wachsen.
4. **FAB „BF-Tag anlegen“** schwebt isoliert unten rechts, ohne Bezug zum Listenkopf — auf einem
   Desktop-Formular wirkt das wie ein mobiles Pattern, nicht wie eine Verwaltungsseite.
5. **Keine Navigation außer dem Titel** (siehe `web-navigation.md` Punkt 1 — betrifft diesen Screen wie alle
   anderen).

## 3. Neues Layout

```
┌──────────┬────────────────────────────────────────────────────────┐
│ Sidebar  │ BF-Tage                              [+ BF-Tag anlegen]│
│ (aktiv:  ├────────────────────────────────────────────────────────┤
│ BF-Tage) │ Name            Zeitraum                 Zustand       │
│          │ ──────────────────────────────────────────────────────│
│          │ Screenshots …   16.10.2026 05:34–16:34   [● läuft]  ⋯  │
│          │   👥 Teilnahmen   Beenden                               │
│          │ ──────────────────────────────────────────────────────│
│          │ Herbstlager 25  12.10.2026 08:00–13.10 08:00 [beendet] │
│          │   Anonymisiert am 14.10.2026 09:00                     │
│          │ ──────────────────────────────────────────────────────│
│          │ (leer: Icon + „Noch keine BF-Tage angelegt.“           │
│          │  + [+ BF-Tag anlegen])                                 │
└──────────┴────────────────────────────────────────────────────────┘
```

Primäraktion „BF-Tag anlegen“ wandert vom FAB in den Seitenkopf rechts neben den Titel (`FilledButton.icon`,
design-system 5.1) — Desktop-Formulare führen die Primäraktion typischerweise im Seitenkopf, FAB ist ein
mobiles Pattern (Begründung Abschnitt 8). Gleicher `Key('create-bf-day')`, gleiches `onPressed`.

Liste als Tabellenzeilen (design-system 5.3): Spalten Name, Zeitraum, Zustand-Chip, Aktionen. Zustand-Chip
farbcodiert, aber **nicht** mit FMS- oder Alarmfarben verwechselbar — eigene neutrale Mapping:
„in Planung“ = `outline`-Rahmen/`onSurfaceVariant`, „läuft“ = `primaryContainer`/`primary` + Punkt-Icon,
„beendet“ = `surfaceContainer`/`onSurfaceVariant`. Aktionen (Teilnahmen/Starten/Beenden/Anonymisieren) als
zweite Zeile unter Name+Zeitraum bei aktiven Zeilen, damit die Tabellenspalten nicht durch wechselnde
Aktionsmengen pro Zustand ihre Breite ändern. „Anonymisieren“ bleibt `alarm`-farbener Button (destruktiv,
design-system 5.1), Bestätigungsdialog unverändert mit Vorschau.

## 4. Alle Zustände

- **Laden:** Skeleton-Zeilen (3 Platzhalter, design-system 5.10) statt Vollbild-Spinner, Seitenkopf mit Titel
  + deaktiviertem „BF-Tag anlegen“-Button bleibt sichtbar.
- **Leer (keine BF-Tage):** zentrierter Leerzustand im Listenbereich (Icon `calendar_month` 48 px + „Noch keine
  BF-Tage angelegt.“ + „BF-Tag anlegen“-Button als Primäraktion dort zusätzlich, design-system 5.3) —
  ersetzt die leere Fläche aus Problem 1.
- **Fehler beim Laden:** Fehlertext + „Erneut versuchen“ ersetzt die Liste (design-system 5.10), identisch zum
  bestehenden `_loadError`-Text, nur mit Icon und Retry-Button ergänzt (Retry ruft `_reload()`, kein neues
  Verhalten, nur ein bisher fehlender Button für einen bereits vorhandenen Fehlerzustand).
- **Fehler bei Aktion (Start/Ende/Speichern):** SnackBar wie heute (`_showError`), unverändert.
- **Viele BF-Tage (lange Liste):** Tabellenbereich scrollt vertikal, Seitenkopf bleibt fix oben (kein Resticky
  nötig — Liste ist nicht so dicht, dass Pagination notwendig wäre).
- **Nicht-Administrator (Leitstelle) bei beendetem, nicht-anonymisiertem Tag:** sieht „Anonymisieren“, aber
  nicht „Starten“/„Beenden“/„Teilnahmen“/den „BF-Tag anlegen“-Button (identisch zur heutigen `isAdmin`/
  `isDispatchOrAdmin`-Logik in `bf_days_screen.dart:233-235`).
- **Dialoge:** Anlegen/Bearbeiten-Dialog (Name, Start, Ende), Teilnahmen-Dialog (Checkbox-Liste + Alle/Keine),
  Anonymisieren-Dialog (Vorschau-Liste + destruktive Bestätigung) — alle nach design-system 5.6
  (`surfaceContainer`, `radiusLarge`, Aktionen rechtsbündig), Anonymisieren-Button `alarm`-farben,
  Beschreibungstext NICHT rot (nur der Button, design-system 5.6).
- **Validierungsfehler im Anlege-/Bearbeiten-Dialog:** aktuell keine serverseitige Client-Validierung vor
  Submit — das bleibt so (keine neue Funktion); falls Backend einen Fehler zurückgibt, erscheint er als
  SnackBar wie heute.
- **Offline/Verbindung verloren:** Kein eigener Zustand auf dieser Karte — das gemeinsame `connection-banner`
  der `AdminShell` zeigt den Verbindungsverlust einheitlich für alle `/admin/*`-Screens (s. `web-navigation.md`
  Abschnitt 4/6 AK 12). BF-Tage hat kein eigenes Realtime-Abo (unverändert); Start/Ende/Anonymisieren
  scheitern bei fehlender Verbindung weiterhin über die bestehende SnackBar-Fehlerbehandlung (`_showError`).

## 5. Interaktionen

- Tab-Reihenfolge: Sidebar → „BF-Tag anlegen“-Button → Tabellenzeilen von oben nach unten → je Zeile ihre
  Aktionen von links nach rechts.
- Zeilen-Klick (nur `isPlanning && isAdmin`) öffnet weiterhin den Bearbeiten-Dialog, identisch zu
  `onTap: isPlanning && isAdmin ? () => _openEditDialog(day) : null`.
- Datum/Zeit-Picker in den Dialogen unverändert (`showDatePicker`/`showTimePicker`).
- Bestätigungsdialoge (Starten/Beenden/Anonymisieren) unverändert: Enter bestätigt nicht automatisch
  (Standard-`AlertDialog`-Verhalten), Fokus startet auf „Abbrechen“.

## 6. Testbare Akzeptanzkriterien

1. `create-bf-day` ist weiterhin auffindbar und löst denselben Erstellen-Dialog aus wie heute — unabhängig
   davon, ob die Implementierung FAB oder Header-Button ist.
2. `bf-days-list`, `bf-day-{id}`, `bf-day-state-{id}`, `bf-day-participants-{id}`, `bf-day-start-{id}`,
   `bf-day-end-{id}`, `bf-day-anonymized-{id}`, `bf-day-anonymize-{id}` existieren unverändert mit identischem
   Verhalten (siehe `bf_days_screen_test.dart`).
3. Bei leerer Liste zeigt der Screen einen Text, der „Noch keine BF-Tage“ (oder gleichwertig) enthält, plus
   einen funktionierenden „BF-Tag anlegen“-Weg.
4. Bei Ladefehler ersetzt ein Fehlertext + Retry-Button die Liste; Retry ruft denselben Reload-Pfad auf wie der
   initiale Load.
5. Die Zustand-Chips zeigen für `planning`/`running`/`ended` unterschiedliche, feste Farben (keine
   `alarm`/FMS-Token-Farben).
6. Nicht-Admin, Berechtigung Leitstelle: `create-bf-day`, `bf-day-start-{id}`, `bf-day-end-{id}`,
   `bf-day-participants-{id}` sind nicht vorhanden; `bf-day-anonymize-{id}` ist vorhanden für beendete,
   nicht-anonymisierte Tage.
7. Der Anonymisieren-Bestätigungsdialog zeigt weiterhin die Vorschau-Zahlen aus
   `AnonymizationSummary` und der bestätigende Button (`anonymize-dialog-confirm`) ist in Alarmfarbe
   (`alarm`), der übrige Dialogtext bleibt neutral.

## 7. Zu erhaltende Keys + Semantics labels

Aus `bf_days_screen.dart` (`grep -n "Key("`): `confirm-dialog-confirm`, `create-bf-day`, `bf-days-list`,
`bf-day-{day.id}` (Zeile 263), `bf-day-state-{day.id}`, `bf-day-participants-{day.id}`,
`bf-day-start-{day.id}`, `bf-day-end-{day.id}`, `bf-day-anonymized-{day.id}`, `bf-day-anonymize-{day.id}`,
`bf-day-form-name`, `bf-day-form-start`, `bf-day-form-end`, `bf-day-form-submit`,
`participants-select-all`, `participants-select-none`, `participants-list`, `participant-{person.id}`,
`participants-submit`, `anonymize-dialog-confirm`. Tooltips: „Teilnahmen“ an `bf-day-participants-{id}`
(`Icons.groups`) bleibt erhalten.

## 8. Flows

Eine Vereinfachung: **Primäraktion „BF-Tag anlegen“ wandert vom FAB in den Seitenkopf.** Begründung: Admin-Web
ist Desktop-first (design-system 4.4); ein schwebender Rundbutton ist ein Mobile-Pattern, das auf einer breiten
Desktop-Seite ungenutzten Raum suggeriert statt Teil eines Formularkopfs zu sein. Die Funktion selbst
(Dialog öffnen, `create()` aufrufen) ist identisch — nur der Auslöser wechselt den Ort. Gleiche Änderung analog
in `web-personen.md` (dort ebenfalls FAB → Header-Button), für konsistente Wahrnehmung über alle Listen-Screens
hinweg.

## 9. Zuordnung zum Regressionsinventar

Tabelle „BF-Tage“ (`docs/testing/regression-inventory.md`, Abschnitt „### BF-Tage (`bf_days_screen.dart`)“):

| Funktion (Inventar) | Test | Ort im neuen Layout |
|---|---|---|
| anzeigen | `bf_days_screen_test.dart`: lists BF-Tage mit Zeitraum und Zustand-Chip | Tabellenzeilen Name/Zeitraum/Zustand-Chip (Abschnitt 3), gleicher Key `bf-days-list`. |
| anlegen | `bf_days_screen_test.dart`: create dialog calls the API with the entered values | `create-bf-day`-Button im Seitenkopf statt FAB (Abschnitt 8), Dialog unverändert. |
| bearbeiten | `bf_days_screen_test.dart`: edit dialog calls update with the new values | Zeilen-Klick (nur `isPlanning && isAdmin`) öffnet Bearbeiten-Dialog, unverändert. |
| löschen | n/a (Anonymisierung ersetzt Löschen, ADR 0020) | n/a |
| Navigation | `bf_days_screen_test.dart`: participants dialog | `bf-day-participants-{id}` in der zweiten Zeile der Tabellenzeile (Abschnitt 3). |
| Echtzeit-Updates | n/a (kein Realtime-Abo, by design) | n/a |
| Fehlerzustand | `bf_days_screen_test.dart`: starting shows the backend error message on failure | SnackBar unverändert (Abschnitt 4). |
| Leerzustand/Offline | n/a (keine eigene UI) | Leerzustand jetzt mit Icon + Primäraktion (Abschnitt 4); Offline zusätzlich über das gemeinsame `connection-banner` der `AdminShell` (Abschnitt 4, neu ergänzt), keine neue BF-Tage-spezifische Funktion. |
