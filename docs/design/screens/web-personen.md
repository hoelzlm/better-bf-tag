# Admin-Web — Personen

Quelle: `apps/web/lib/screens/persons_screen.dart`. Vorher:
`docs/design/screenshots/before/web/personen-1440x900.png`,
`docs/design/screenshots/before/web/personen-dialog-1440x900.png`. Rendertes Mockup:
`docs/design/mockups/web-personen.html`/`.png` (1440×900, inkl. Sidebar).

## 1. Zweck

Administratoren pflegen Personen-Stammdaten (Jugendliche + Betreuer), vergeben Web-Zugänge für Betreuer,
verwalten gekoppelte Geräte und drucken Kopplungscode-Listen für Jugendliche (QR-Code auf Papier, da diese
i. d. R. keinen eigenen Web-Zugang haben). Meist vor einem BF-Tag in einer Sitzung für viele Personen
genutzt — Listendichte und schnelles Wiederfinden einer Person sind wichtiger als große Touch-Ziele (reines
Desktop-Werkzeug).

## 2. Usability-Probleme heute

1. **Personentyp/Berechtigung/Zugang nur als Fließtext mit `·`-Trennern**
   (`docs/design/screenshots/before/web/personen-1440x900.png`: „Jugendlicher · Mannschaft · –“) — bei
   Dutzenden Personen ist das beim Scannen langsamer als farblich unterscheidbare Chips.
2. **Vier verschiedene Bedienelemente in einer Zeile ohne Gruppierung** (🔓/🔒-Icon, Geräte-Icon, Switch) —
   Screenshot zeigt sie eng beieinander ohne erkennbare Zuordnung zu „was gehört zusammen“.
3. **Aktiv-Switch ohne Bestätigungs-Hinweis sichtbar** — der Screenshot zeigt alle Switches eingeschaltet ohne
   erkennbaren Unterschied zwischen „aktiv“ und „kürzlich deaktiviert“; der bestehende Bestätigungsdialog beim
   Deaktivieren ist gut, aber visuell nicht vom Rest der Zeile abgesetzt.
4. **Dialog (`personen-dialog-1440x900.png`): Chip-Gruppen ohne Abstand zur darüberliegenden Beschriftung**,
   „Personentyp“/„Berechtigung“ wirken wie Fließtext-Labels statt Formular-Feldgruppen; Dialogbreite wirkt für
   nur drei Felder unnötig eng gequetscht bei gleichzeitig viel Weißraum um den Dialog herum.
5. **FAB „Person anlegen“** isoliert unten rechts (gleiches Muster wie BF-Tage, Problem 4 dort).
6. **Druck-Icon ohne erkennbares Label**, nur Tooltip „Kopplungscodes drucken“ — bei einer so seltenen, aber
   wichtigen Aktion (Papierlisten für den BF-Tag) sollte sie auffindbarer sein als ein einzelnes Icon neben dem
   Inaktive-Schalter.

## 3. Neues Layout

Rendertes Mockup: `docs/design/mockups/web-personen.html`/`.png`.

```
┌──────────┬────────────────────────────────────────────────────────────┐
│ Sidebar  │ Personen   inaktive anzeigen ⚪ 🖨 Codes drucken [+ Person] │
│ (aktiv:  ├────────────────────────────────────────────────────────────┤
│ Personen)│ Anna Jugend              [Jugendlicher] [Mannschaft]        │
│          │                                          📱 Geräte  ⬤ aktiv │
│          │ ──────────────────────────────────────────────────────────│
│          │ Leitstelle screenshots   [Betreuer] [Leitstelle]            │
│          │                           🔑 Web-Zugang  📱 Geräte  ⬤ aktiv │
│          │ ──────────────────────────────────────────────────────────│
│          │ (leer: „Noch keine Personen angelegt.“ + Primäraktion)      │
└──────────┴────────────────────────────────────────────────────────────┘
```

Zeilen als `ListTile`-Nachfolger im Tabellenstil (design-system 5.3), Name `titleMedium`, darunter zwei kleine
`Chip`s (`labelMedium`, `surfaceVariant`-Fläche, `radiusSmall`) für Personentyp und Berechtigung statt
`·`-getrenntem Fließtext — schneller scanbar, und Berechtigung „Administrator“ bekommt zusätzlich einen
`primaryContainer`-Chip (hebt die mächtigste Rolle optisch ab). Benutzername bleibt als dritter, unauffälliger
Text (`bodyMedium`/`onSurfaceVariant`) hinter den Chips, nicht als weiterer Chip (ist kein Status, sondern ein
Datenfeld). Aktionen rechts gruppiert: Web-Zugang (nur sichtbar wenn `permission != crew`, wie heute, siehe
`persons_screen.dart:258` — eine Person mit Personentyp „Betreuer“ aber Berechtigung „Mannschaft“ sieht also
**kein** „Web-Zugang“) und Geräte als Icon-Buttons mit sichtbarem Label daneben (nicht nur Tooltip, da nur 2
Icons, genug Platz), Aktiv-Switch (`Switch`-Komponente, `active-switch-{id}`, design-system 5.2 Auswahl-
Komponenten) mit Statuswort davor (⬤ aktiv / ⬤ deaktiviert in `onSurfaceVariant`, nicht grün/rot — ist kein
FMS-/Alarmstatus) — der Switch selbst muss sichtbar bleiben, nicht nur der Statuspunkt. Kopfzeile: Titel
links, rechts in einer Zeile „inaktive anzeigen“-Schalter wie heute, „Codes drucken“ als sichtbar
beschrifteter `OutlinedButton.icon` statt alleinstehendem Icon, „Person anlegen“ als `FilledButton.icon` ganz
rechts (gleiches Muster wie BF-Tage, Abschnitt 8 — eine Kopfzeile, keine zweite Zeile nur für den
Anlegen-Button).

Dialog (design-system 5.6): Breite 420 px (statt gefühlt zu schmal im Screenshot bei zu viel Rand drumherum),
`surfaceContainer`-Fläche, `radiusLarge`. Feldgruppen „Personentyp“/„Berechtigung“ mit `titleMedium`-Label und
`sm`-Abstand (8 px) zur Chip-Reihe darunter (statt direkt anliegend), Chips als `ChoiceChip` mit
`primaryContainer`/`primary`-Rahmen im ausgewählten Zustand (design-system 5.1/5.3-Stil übertragen auf Chips).

## 4. Alle Zustände

- **Laden:** Skeleton-Zeilen (3, design-system 5.10) statt Vollbild-Spinner.
- **Leer (keine Personen):** Leerzustand „Noch keine Personen angelegt.“ + „Person anlegen“-Button
  (design-system 5.3/5.10) statt reiner leerer Liste.
- **Fehler beim Laden:** Fehlertext + „Erneut versuchen“ ersetzt die Liste (ruft denselben `_reload()`-Pfad),
  identisch zum bestehenden `_loadError`-Verhalten, nur mit Icon/Retry-Button ergänzt.
- **„inaktive anzeigen“ aus:** Liste zeigt nur `p.active`-Personen (unverändert), Switch-Zustand bleibt erhalten
  bei Reload (unverändert, reiner Client-Filter).
- **Deaktivieren/Reaktivieren:** Bestätigungsdialog unverändert (`_confirm` mit personenspezifischem Text,
  inkl. Hinweis „Alle Web-Sitzungen und Geräte … werden gesperrt“ beim Deaktivieren).
- **Web-Zugang-Dialog:** leeres Passwortfeld + Fehlertext bei < 8 Zeichen (`warning`-Farbe statt generischem
  `colorScheme.error`-Rot — mapped laut design-system 5.2/Abschnitt 10 ohnehin auf `warning`), „Web-Zugang
  entfernen“ nur sichtbar wenn `hasWebAccess` (unverändert).
- **Geräte-Dialog:** Liste der Geräte mit Plattform, Version, Zeiten, „Sperren“ je aktivem Gerät; leer →
  „Keine Geräte gekoppelt.“ (unverändert); „Kopplungscode erzeugen“ wechselt denselben Dialog in die
  QR-Code-Ansicht (`pairing-code-text`), Hinweis „Dieser Code wird nur einmal angezeigt.“ bleibt erhalten,
  visuell als `warning`-unterlegter Hinweistext hervorgehoben (es ist keine Fehlermeldung, aber eine wichtige
  Einmaligkeits-Warnung — leichte `warningContainer`-Fläche um den Hinweis, kein neuer Zustand, nur Betonung).
- **Drucken (`_printPairingCodes`):** öffnet weiterhin den System-Druckdialog (`Printing.layoutPdf`), Fehler
  dabei als SnackBar (unverändert).
- **Sehr lange Namen/viele Chips:** Name mit `TextOverflow.ellipsis` + Tooltip, Chip-Reihe bleibt einzeilig
  (zwei bis drei Chips passen immer), Aktionen rechts brechen bei Bedarf nicht um (feste Mindestbreite der
  rechten Spalte, Name-Spalte ist die flexible).
- **Ohne Berechtigung:** die gesamte Seite ist nur für `Permission.admin` erreichbar (Router-Redirect
  unverändert); kein In-Screen-„ohne Berechtigung“-Zustand nötig.
- **Offline/Verbindung verloren:** Kein eigener Zustand auf dieser Karte — das gemeinsame `connection-banner`
  der `AdminShell` zeigt den Verbindungsverlust einheitlich für alle `/admin/*`-Screens (s. `web-navigation.md`
  Abschnitt 4/6 AK 12). Personen hat kein eigenes Realtime-Abo (einmaliges `GET /persons`, unverändert);
  Aktionen, die während eines Verbindungsverlusts fehlschlagen, zeigen weiterhin SnackBar/Ladefehler wie
  heute.

## 5. Interaktionen

- Zeilen-Klick öffnet weiterhin den Bearbeiten-Dialog (`onTap: () => _openEditDialog(person)`, unverändert).
- Tab-Reihenfolge: Sidebar → „inaktive anzeigen“ → „Codes drucken“ → „Person anlegen“ → Zeilen von oben nach
  unten, je Zeile: Web-Zugang → Geräte → Aktiv-Switch.
- Chip-Auswahl im Dialog (Personentyp/Berechtigung) per Klick oder Tastatur (Space/Enter auf fokussiertem
  Chip), `_setPersonType` setzt bei Wechsel weg von „Betreuer“ automatisch `Permission.crew`, falls vorher
  `admin` gewählt war (unverändert, Admin nur für Betreuer laut `CONTEXT.md`).

## 6. Testbare Akzeptanzkriterien

1. `show-inactive`, `print-pairing-codes`, `create-person`, `persons-list`, `person-{id}`,
   `web-access-{id}`, `devices-{id}`, `active-switch-{id}` funktionieren identisch zu
   `persons_screen_test.dart`.
2. `create-person` ist weiterhin auffindbar und löst denselben Erstellen-Dialog aus, unabhängig von FAB- vs.
   Header-Button-Darstellung.
3. Jede Personenzeile zeigt Personentyp und Berechtigung als getrennt erkennbare Chips (nicht nur
   Fließtext mit `·`).
4. `web-access-{id}` ist nur für Personen mit `permission != Permission.crew` vorhanden (unverändert).
5. Bei leerer Liste erscheint ein Text, der „Noch keine Personen“ (oder gleichwertig) enthält.
6. Bei Ladefehler ersetzt ein Fehlertext + Retry-Button die Liste.
7. `person-form-display-name`, `person-type-{name}`, `permission-{name}`, `person-form-submit` im
   Anlege-/Bearbeiten-Dialog funktionieren identisch zu heute, inkl. der Einschränkung, dass
   `permission-admin` nur wählbar ist, wenn `person-type-supervisor` gewählt ist.
8. `web-access-username`, `web-access-password`, `web-access-remove`, `web-access-submit` funktionieren
   identisch; ein Passwort < 8 Zeichen zeigt weiterhin den Fehlertext und verhindert das Submitten.
9. `create-pairing-code`, `pairing-code-text`, `device-{id}`, `revoke-device-{id}` funktionieren identisch zu
   `monitors_screen_test.dart`-ähnlichen Mustern/`persons_screen_test.dart`.

## 7. Zu erhaltende Keys + Semantics labels

Aus `persons_screen.dart` (`grep -n "Key("`): `confirm-dialog-confirm`, `show-inactive`,
`print-pairing-codes`, `create-person`, `persons-list`, `person-{person.id}`, `web-access-{person.id}`,
`devices-{person.id}`, `active-switch-{person.id}`, `person-form-display-name`, `person-type-{type.name}`,
`permission-{permission.name}`, `person-form-submit`, `web-access-username`, `web-access-password`,
`web-access-remove`, `web-access-submit`, `create-pairing-code`, `pairing-code-text`, `device-{device.id}`,
`revoke-device-{device.id}`. Tooltips: „Web-Zugang“ (`web-access-{id}`), „Geräte“ (`devices-{id}`),
„Kopplungscodes drucken“ (`print-pairing-codes`) — Texte bleiben identisch, Geräte-/Web-Zugang-Icons erhalten
zusätzlich ein sichtbares Label (Zugabe, kein Ersatz des Tooltips).

## 8. Flows

Eine Vereinfachung, analog zu `web-bf-tage.md`: **„Person anlegen“ wandert vom FAB in den Seitenkopf**
(Begründung dort, gilt identisch hier — konsistentes Desktop-Pattern über alle Listen-Admin-Screens). Keine
weitere Flow-Änderung: Anlegen/Bearbeiten/Deaktivieren, Web-Zugang, Geräte, Kopplungscode-Erzeugung und
-Druck bleiben in Anzahl und Reihenfolge der Schritte exakt erhalten.

## 9. Zuordnung zum Regressionsinventar

Tabelle „Personen“ (`docs/testing/regression-inventory.md`, Abschnitt „### Personen (`persons_screen.dart`)“):

| Funktion (Inventar) | Test | Ort im neuen Layout |
|---|---|---|
| anzeigen | `persons_screen_test.dart`: lists persons from the fake response | Zeilenliste mit Chips statt Fließtext (Abschnitt 3), gleicher Key `persons-list`. |
| anlegen | `persons_screen_test.dart`: creating a person calls createPerson with the entered fields | `create-person`-Button im Seitenkopf statt FAB (Abschnitt 8), Dialog unverändert. |
| bearbeiten | `persons_screen_test.dart`: editing a person calls updatePerson with the entered fields; toggling active calls updatePerson | Zeilen-Klick → Dialog; `active-switch-{id}` sichtbar als echter Switch (Abschnitt 3, behebt Problem 3). |
| löschen | n/a (Aktiv-Switch statt Löschen) | n/a |
| Navigation | n/a | n/a |
| Echtzeit-Updates | n/a (einmaliges `GET /persons`, kein Abo) | n/a |
| Fehlerzustand | `persons_screen_test.dart`: load error shows the error message instead of the list | Fehlertext + Retry-Button (Abschnitt 4). |
| Leerzustand/Offline | n/a (keine eigene UI) | Leerzustand jetzt mit Icon (Abschnitt 4); Offline zusätzlich über das gemeinsame `connection-banner` der `AdminShell` (Abschnitt 4), keine neue Personen-spezifische Funktion. |
