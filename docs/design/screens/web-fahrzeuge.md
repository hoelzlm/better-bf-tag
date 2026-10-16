# Fahrzeuge — Admin-Web

Grundlage: `docs/design/design-system.md`. Navigation/Seitenleiste: `docs/design/screens/web-navigation.md` (ux-02b,
hier vorausgesetzt, nicht neu entworfen). Quelle: `apps/web/lib/screens/vehicles_screen.dart`.

## 1. Zweck

Administrator pflegt die Fahrzeug-Stammdaten (Funkrufname, Kurzname, Typ) vor dem BF-Tag: anlegen, umbenennen,
Reihenfolge festlegen (bestimmt die Anzeige überall sonst, z. B. Lage, Monitor), Fahrzeuge per Schalter aktiv/
inaktiv setzen (Soft-Delete — ein inaktives Fahrzeug kann nicht mehr beplant werden, bleibt aber in der Historie
sichtbar). Selten während eines laufenden BF-Tags benutzt, meist vorher in Ruhe am Schreibtisch.

## 2. Usability-Probleme heute

Screenshot: `docs/design/screenshots/before/web/fahrzeuge-1440x900.png`.

1. Liste ist eine nackte `ListTile`-Spalte ohne Rahmung; die rechten ~1050 px der 1440 px breiten Seite bleiben
   leer. Keine Begrenzung der Lesebreite, kein Kartenrahmen, wirkt unfertig statt wie eine Stammdatentabelle.
2. Die `FloatingActionButton` „Fahrzeug anlegen“ unten rechts ist blass pink (Seed-Rot bei Opazität) und sitzt
   über möglichem Listeninhalt bei vielen Fahrzeugen — kollidiert potenziell mit der letzten Zeile.
3. Reihenfolge wird nur durch einen kleinen Drag-Handle (☰-Icon, 20 px) rechts signalisiert, kein Hinweis-Text,
   leicht zu übersehen, dass die Liste überhaupt sortierbar ist.
4. Aktiv-Schalter und Drag-Handle hängen ohne Abstand nebeneinander — kleine Touch-/Klickfläche, Gefahr von
   Fehlklicks.
5. Kein optischer Unterschied zwischen aktiven und inaktiven Fahrzeugen in der Liste (beide gleich dunkel) —
   der Zustand ist nur am Schalter selbst ablesbar, nicht an der Zeile.
6. Typ-Vorschlag-Chips im Dialog (`HLF`, `LF`, …) sind eng gepackt (4 px Abstand) ohne erkennbare Überschrift,
   wirken wie Zufallstext statt Hilfsmittel.

## 3. Neues Layout

ASCII-Wireframe, Content-Bereich neben der Seitenleiste (Breite ≥ 1280 px):

```
┌───────────────────────────────────────────────────────────────────────────┐
│ Fahrzeuge                                            [+ Fahrzeug anlegen] │ topbar, xl padding
├───────────────────────────────────────────────────────────────────────────┤
│ ┌───────────────────────────────────────────────────────────────────────┐ │
│ │ ≡  Funkrufname        Kurzname   Typ     Aktiv                        │ │ Kopfzeile, surfaceVariant
│ ├───────────────────────────────────────────────────────────────────────┤ │
│ │ ≡  Florian 46/1        HLF-1     HLF      [●  ]                       │ │ Zeile ≥48dp, outline-Trenner
│ │ ≡  Florian 83/1        RTW-1     RTW      [●  ]                       │ │
│ │ ≡  Florian 33/1        DLK-1     DLK      [●  ]      (inaktiv: 60% Deckkraft, "inaktiv"-Label)
│ └───────────────────────────────────────────────────────────────────────┘ │
│  Inhaltsbreite auf max. 900 px begrenzt, Karte surfaceVariant/radiusLarge  │
└───────────────────────────────────────────────────────────────────────────┘
```

Änderungen gegenüber heute:

- `FloatingActionButton` → normaler `FilledButton.icon` rechts im Topbar (Key bleibt `create-vehicle`, nur Widget-
  Typ ändert sich). Begründung: konsistent mit Fahrzeuge/Einsätze/Folien/Monitore, kein Überlappungsrisiko mit der
  Liste, folgt derselben Topbar-Primäraktion wie `lage.html`.
  **Flow-Vereinfachung** (zu begründen laut Auftrag): Alle sechs Listenscreens dieser Karte bekommen dieselbe
  Topbar-Primäraktion statt FAB — eine Positions-Konvention weniger zu lernen, Funktion identisch.
- Liste bekommt eine Kopfzeile (Label „Funkrufname / Kurzname / Typ / Aktiv“) und eine sichtbare Tabellen-Kante
  (`surfaceVariant`-Karte, `radiusLarge`, `outline` 1 px zwischen Zeilen, Abschnitt 5.3/5.4 Designsystem).
- Inaktive Zeilen: Text bei 60 % Deckkraft + kleines Label „inaktiv“ neben dem Namen (`labelMedium`,
  `onSurfaceVariant`) — Zustand ist jetzt auch ohne Blick auf den Schalter erkennbar.
- Drag-Handle (`drag_indicator`-Icon, `onSurfaceVariant`) bekommt 12 px Abstand zum Schalter und einen
  `Semantics`-Hinweis „Ziehen zum Sortieren“ (neu, da bisher kein Label — WCAG 1.3.1/4.1.2 für ein rein
  grafisches Icon).
- Dialog: Typ-Vorschlag-Chips unter einer kleinen Überschrift „Vorschläge“ (`labelMedium`,
  `onSurfaceVariant`), 8 px Abstand zwischen Chips (`BftagSpacing.sm`) statt 4 px.
- Pflichtfeld-Validierung vor dem Absenden (Funkrufname/Kurzname/Typ dürfen nicht leer sein): verhindert eine
  unnötige Server-Rückfrage, Verhalten bei gültiger Eingabe unverändert — siehe Abschnitt 6, Punkt 7.

## 4. Alle Zustände

- **Laden:** zentrierter `CircularProgressIndicator` (`primary`) anstelle der Liste, Topbar bleibt mit Titel
  bestehen.
- **Leer:** zentriertes Icon `local_shipping` 48 px (`onSurfaceVariant`) + „Noch keine Fahrzeuge angelegt.“ +
  Primäraktion „Fahrzeug anlegen“ (Designsystem 5.3). Tritt praktisch nur bei einer frischen Installation auf.
- **Fehler:** Icon `warning` (`warning`-Farbe) + „Fahrzeuge konnten nicht geladen werden.“ + „Erneut versuchen“-
  Button (ruft `_reload()`).
- **Offline/Reconnecting:** kein eigener Zustand auf diesem Screen (einmaliges `GET`, kein Realtime-Abo) —
  unverändert zum heutigen Verhalten.
- **Ohne Berechtigung:** Screen ist nur für Administrator erreichbar (Navigation blendet den Punkt sonst aus,
  siehe `web-navigation.md`); kein Inline-Zustand nötig.
- **Dialog „Fahrzeug anlegen/bearbeiten“:** Titel je nach Modus, drei Textfelder + Vorschlag-Chips,
  Validierungsfehler je Feld unter dem Feld in `warning`-Farbe (Designsystem 5.2) bei leerem Pflichtfeld,
  „Speichern“ erst nach gültiger Eingabe aktiv.
- **Validierungsfehler (Server, z. B. Doppel-Funkrufname):** SnackBar mit der Fehlermeldung, Dialog bleibt
  nicht offen (heutiges Verhalten unverändert: Dialog schließt, Fehler erscheint danach).
- **Destructive Confirmation:** keine vorhanden auf diesem Screen (Soft-Delete per Schalter, kein Lösch-Dialog) —
  Schalter selbst braucht keine Bestätigung (reversibel).

## 5. Interaktionen

- Klick/Tap auf eine Zeile (außer Schalter/Drag-Handle) öffnet den Bearbeiten-Dialog.
- Drag per Maus auf dem Handle-Icon sortiert; Tastatur-Alternative: Zeile fokussieren (Tab), `Shift+↑/↓` verschiebt
  eine Position (neu zu implementieren in ux-03, da `ReorderableListView` dies nicht automatisch anbietet — ohne
  Maus ist die Liste sonst nicht sortierbar, WCAG 2.1.1).
- Tab-Reihenfolge: Primärbutton (Topbar) → Zeilen (je Zeile: Name/Edit-Ziel → Schalter → Drag-Handle) → (Dialog:
  Felder → Chips → Abbrechen → Speichern).
- Fokusring 2 px `primary` auf jedem interaktiven Element (Designsystem 8).
- Enter im letzten Textfeld des Dialogs löst „Speichern“ aus (bestehendes Verhalten erhalten).

## 6. Testbare Akzeptanzkriterien

1. Liste zeigt alle Fahrzeuge inkl. inaktiver, mit Funkrufname, Kurzname, Typ, Aktiv-Schalter.
2. Klick auf eine Zeile öffnet den Bearbeiten-Dialog mit vorausgefüllten Werten.
3. „Fahrzeug anlegen“ (Topbar-Button, Key `create-vehicle`) öffnet den Anlegen-Dialog.
4. Speichern im Anlegen-Dialog ruft `create()` mit den eingegebenen Werten auf; die Liste wird danach neu
   geladen.
5. Speichern im Bearbeiten-Dialog ruft `update()` mit den eingegebenen Werten auf.
6. Umschalten des Aktiv-Schalters ruft `update(active: …)` auf und lädt die Liste neu.
7. Leeres Funkrufname-, Kurzname- oder Typ-Feld zeigt einen Inline-Fehler und verhindert das Absenden
   („Speichern“ bleibt deaktiviert oder zeigt `errorText`), bis alle drei Felder gefüllt sind.
8. Ziehen einer Zeile an eine neue Position ruft `reorder()` mit der neuen Reihenfolge der Fahrzeug-IDs auf.
9. Ladefehler zeigt „Fahrzeuge konnten nicht geladen werden.“ statt der Liste.
10. Leere Fahrzeugliste zeigt den Leerzustand mit Primäraktion statt einer leeren Fläche.
11. Inaktive Fahrzeuge sind in der Liste optisch (Deckkraft + Label) von aktiven unterscheidbar.

## 7. Zu erhaltende Keys + Semantics

Aus `apps/web/lib/screens/vehicles_screen.dart` (grep-geprüft):

- `create-vehicle` (Anlegen-Button, bleibt Key, Widget wechselt FAB→FilledButton)
- `vehicles-list` (Liste)
- `ValueKey(vehicle.id)` je Zeile
- `active-switch-${vehicle.id}` je Zeile
- `vehicle-form-call-sign`, `vehicle-form-short-name`, `vehicle-form-type` (Dialogfelder)
- `type-suggestion-$suggestion` je Vorschlag-Chip (HLF, LF, TLF, DLK, RW, ELW, MTW, RTW, KTW)
- `vehicle-form-submit`

Neue Semantics (ux-03 ergänzt, keine Key-Pflicht): Drag-Handle „Ziehen zum Sortieren: {Funkrufname}“.

## 8. Flows

Keine Funktion fällt weg. Mapping gegen `docs/testing/regression-inventory.md` § Fahrzeuge: anzeigen, anlegen,
bearbeiten, löschen (= Aktiv-Schalter), Fehlerzustand — alle unverändert vorhanden, nur Tabellenrahmen + Topbar-
Button statt FAB + Pflichtfeld-Validierung (zusätzliche, nicht entfernte Prüfung) + sichtbarer Sortier-Hinweis.
