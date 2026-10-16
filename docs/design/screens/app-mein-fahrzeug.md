# App – Mein Fahrzeug (`screens/my_vehicle_screen.dart`, `widgets/fms_panel.dart`)

Status: Entwurf (ux-02e) · verfeinert das Token-Proof-of-Concept aus ux-02a
(`docs/design/mockups/app-mein-fahrzeug.html`) zum vollständigen Screen-Konzept.

## 1. Zweck

Standard-Tab (`/`) und damit der Screen, den eine Person am häufigsten sieht: eigenes Fahrzeug, eigene
Funktion, aktueller Fahrzeugstatus (FMS) und — die primäre Handlung — einen neuen FMS-Status setzen. Diese
Statusänderung muss unter Zeitdruck, ggf. mit Handschuhen, fehlerfrei zu treffen sein (Kartenauftrag:
„big, error-proof").

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/mein-fahrzeug-390x844.png`: FMS-Buttons sind fast schwarz
   (`Color(0xFF111111)`/`Color(0xFF2A2A2A)`), nur der aktive Status ist knallgelb (`Colors.amber`) — passt zu
   keinem Token des neuen Systems und hat keinen erkennbaren Bezug zu den FMS-Statusfarben, die auf Monitor/
   Web bereits andere Status (z. B. 4 „Am Einsatzort") farblich markieren; dieselbe Information sieht auf App
   und Monitor unterschiedlich aus.
2. FMS-Buttons liegen mit nur 8 px Abstand sehr eng beieinander (`GridView.count`, `mainAxisSpacing: 8`) bei
   geringer Höhe (`minHeight: 72`, `childAspectRatio: 1.4`) — unter Stress/mit Handschuhen reicht das knapp
   nicht für fehlerfreies Treffen, besonders bei 6 Buttons in 2 Spalten × 3 Reihen.
3. Nur 6 von 8 FMS-Status sind im Screenshot sichtbar (`offeredStatuses(vehicle.type)` zeigt 7/„Patient
   aufgenommen" und 8/„Am Transportziel" nur für RTW/KTW) — unverändertes, korrektes Verhalten, aber nicht
   dokumentiert/erklärt im UI, falls eine Person zwischen Fahrzeugtypen wechselt (`SegmentedButton`) und sich
   fragt, warum die Buttonzahl wechselt.
4. Kopfbereich (Fahrzeugname, Funktion, Status als Text) ist reiner Fließtext ohne visuelle Hierarchie —
   schwer auf einen Blick zu erfassen, welches Fahrzeug/welche Funktion gerade aktiv ist, besonders bei
   mehreren zugewiesenen Fahrzeugen (`vehicle-switcher`).
5. Keine Rückmeldung während eine Statusänderung läuft außer einem kleinen Spinner im jeweiligen Button
   (unverändert sinnvoll) — aber kein Hinweis, WELCHER Status aktuell *angefragt* vs. *bestätigt* ist, falls
   die Antwort langsam kommt (kein Problem laut Code-Kommentar "no optimistic update", aber visuell nicht klar
   genug vom bloßen Pending-Spinner unterschieden).

## 3. Neues Layout

`docs/design/mockups/app-mein-fahrzeug.html` wurde überarbeitet (vorher: Token-Proof-of-Concept mit
abweichenden Nav-Icons und nur Platzhalter-FMS-Werten) und neu gerendert als
`docs/design/mockups/app-mein-fahrzeug.png` (390×844, hell). Änderungen gegenüber der ux-02a-Fassung:
Nav-Icons auf die verbindliche Zuordnung aus `app-navigation.md` korrigiert (`local_shipping`/`campaign`/
`chat_bubble`/`schedule` statt `local_fire_department`/`campaign`/`event_note`), FMS-Grid auf die
FMS-Statusfarben aus Designsystem 2.4 umgestellt (vorher neutrale `surfaceContainer`-Kacheln mit nur dem
aktiven Status hervorgehoben — jetzt behalten inaktive Kacheln `surfaceContainer`, aktive Kachel bekommt
die feste Token-Farbe des jeweiligen FMS-Status, nicht mehr nur amber/gelb für Status 3), größere
Button-Mindesthöhe (96 statt 72 px) und größerer Spacing (`lg`=16 statt 8 px) zwischen den Kacheln, sowie das
Zahnrad-Icon (`settings`, `Key('settings')`) rechts in der AppBar ergänzt — im Screenshot zuvor fehlend,
obwohl es laut `app-navigation.md` §1 der einzige Weg zu Einstellungen ist.

ASCII-Wireframe (390×844):

```
┌──────────────────────────────────────────┐
│  Mein Fahrzeug                    ⚙      │  AppBar, Zahnrad → /settings
├──────────────────────────────────────────┤
│  Florian 46/1                             │  titleLarge/headlineSmall
│  HLF-1 – HLF                              │  bodyMedium/onSurfaceVariant
│  [ HLF-1 ▸ ]  (nur bei >1 Fahrzeug)       │  SegmentedButton, nur falls mehrere
│  Funktion: GF   ·   Status: 3 – Einsatz   │  bodyLarge, "Status:" fett hervorgehoben
│  übernommen                                │
│                                            │
│  ┌───────────┐ ┌───────────┐              │  FMS-Grid, 2 Spalten, Zeilenabstand lg
│  │ 1         │ │ 2         │              │  inaktiv: surfaceContainer/onSurface
│  │Einsatzbereit│Einsatzbereit│             │  aktiv: fms3-Token-Farbe + onFms3-Text
│  │über Funk   │ auf Wache   │              │  Mindesthöhe 96dp statt 72dp
│  └───────────┘ └───────────┘              │
│  ┌───────────┐ ┌───────────┐              │
│  │ 3 (aktiv) │ │ 4         │              │
│  └───────────┘ └───────────┘              │
│  ┌───────────┐ ┌───────────┐              │
│  │ 5         │ │ 6         │              │
│  └───────────┘ └───────────┘              │
│  (7/8 zusätzlich bei RTW/KTW)              │
│                                            │
│  Besatzung                                 │
│  GF Max M.                                 │
│  MA Erika M.                               │
├──────────────────────────────────────────┤
│  🚒 Fahrzeug  📢 Einsätze  💬 ..  📅 ..   │  Navigationsleiste (app-navigation.md)
└──────────────────────────────────────────┘
```

360×640: Kritischer Fall laut Karte ("nichts Wesentliches unterhalb des Falzes"). Mit 6 FMS-Kacheln
(96dp Höhe + 16px Abstand) + Kopfbereich + AppBar + Navigationsleiste wurde geprüft: Kopfbereich ca. 110px,
FMS-Grid 3 Reihen × (96+16)px ≈ 336px, Summe mit AppBar (56px) und Navbar (72px) ≈ 574px von 640px
verfügbarer Höhe (ohne Systemleisten) — passt ohne Scrollen bei 6 Kacheln. Bei 8 Kacheln (RTW/KTW, 4 Reihen)
reicht die Höhe auf 360×640 NICHT ohne Scrollen (4×112=448px allein fürs Grid) — das Grid bleibt dann
scrollbar wie heute (`Expanded`+Column sind bereits scrollfähig über `_VehicleContent`s
`SingleChildScrollView`), die Besatzungsliste rutscht unter den Falz, was akzeptabel ist (sekundäre Info);
die FMS-Buttons selbst (primäre Handlung) müssen priorisiert oben bleiben — das ist bereits so.

## 4. Alle Zustände

- **Laden:** Es gibt aktuell keinen expliziten Lade-Spinner für `myCrewAssignmentsProvider` selbst im Code
  (Provider liefert synchron/bereits-geladen) — kein neuer Ladezustand eingeführt, Verhalten unverändert.
- **Leer (keinem Fahrzeug zugeteilt):** zentrierter Text „Du bist aktuell keinem Fahrzeug zugeteilt." — wird
  im neuen Design um ein 48px-Icon (`local_shipping_outlined`, `onSurfaceVariant`) ergänzt, gleicher Text,
  Designsystem-Leerzustandsmuster (5.10).
- **Mehrere Fahrzeuge:** `SegmentedButton` sichtbar, Umschalten lädt denselben Screen mit anderem
  `assignment` neu, FMS-Grid/Kopfbereich aktualisiert sich entsprechend.
- **FMS-Statusänderung angefragt (pending):** betroffene Kachel zeigt 24px-Spinner (`onFmsN`-Farbe auf der
  jeweiligen Kachel, nicht nur Weiß) statt Zahl/Label, Kachel bleibt in ihrer Zielgröße, alle anderen Kacheln
  bleiben inaktiv bedienbar (kein globales Sperren des Screens während eine Anfrage läuft, unverändert).
- **FMS-Statusänderung fehlgeschlagen:** SnackBar mit `describeSetStatusError(error)` — Text unverändert aus
  dem Code, Snackbar folgt dem neuen Theme (`surfaceContainer`-Fläche, nicht mehr Flutter-Standard-Dunkelgrau).
- **Offline/Verbindungsverlust:** **n/a** — laut `docs/testing/regression-inventory.md` existiert für diesen
  Screen bewusst kein eigener Verbindungsstatus-Indikator (`ConnectionStatus`-Widget wie im Monitor gibt es
  hier nicht); dieses Konzept führt KEINEN neuen Offline-Banner ein (wäre eine neue Funktion) — der einzige
  Fehlerpfad bleibt die oben beschriebene SnackBar bei fehlgeschlagener Statusänderung.
- **Hell/Dunkel:** Kopfbereich/Karten nach Tabelle 2.1; FMS-Kacheln auf dunklem Grund erhalten den in
  Designsystem 2.4 festgelegten 1px-`onSurface`-bei-24%-Rahmen für ausreichenden Kantenkontrast.

## 5. Interaktionen

- Tap auf eine FMS-Kachel setzt sofort den neuen Status (kein Bestätigungsdialog, wie heute — Code hat keinen
  Dialog, Verhalten bleibt unverändert: die Buttons sind so groß/klar beschriftet, dass ein Bestätigungsschritt
  die primäre Aufgabe nur verlangsamen würde, ohne die Fehlerquote wesentlich zu senken, siehe
  Grundsatz "big, error-proof" durch Größe/Abstand statt zusätzlichem Dialog).
- Tap auf `vehicle-switcher`-Segment wechselt das angezeigte Fahrzeug.
- Tap auf Zahnrad-Icon navigiert zu `/settings`.

## 6. Testbare Akzeptanzkriterien

1. Jede FMS-Kachel hat eine Touch-Fläche ≥ 48×48 dp (Ziel: 96dp hoch × ca. 160dp breit bei 390px/2 Spalten).
2. Der Abstand zwischen zwei benachbarten FMS-Kacheln beträgt mindestens 16 px (Designsystem `lg`).
3. Die aktive Kachel (entspricht `vehicle.status`) ist durch die feste FMS-Token-Farbe (Tabelle 2.4)
   erkennbar, inaktive Kacheln bleiben `surfaceContainer`.
4. Bei RTW/KTW zeigt das Grid 8 Kacheln, bei anderen Fahrzeugtypen 6 (`offeredStatuses`), unverändert.
5. Während eine Statusänderung läuft (`_pendingCode != null` für genau diesen Code), zeigt nur diese eine
   Kachel einen Spinner; andere Kacheln bleiben antippbar.
6. Ein Fehler beim Setzen des Status zeigt eine SnackBar mit dem Text aus `describeSetStatusError`.
7. Auf 360×640 bleiben bei 6 FMS-Kacheln alle Kacheln ohne Scrollen sichtbar; bei 8 Kacheln scrollt nur der
   Inhaltsbereich (Navigationsleiste bleibt fix sichtbar).
8. Kein Offline-Banner wird auf diesem Screen gerendert (bewusstes `n/a`).
9. Kontrast Text/Zahl-auf-Kachel erreicht für jede der 8 FMS-Farben ≥ WCAG AA (Werte: `docs/design/tools/contrast.py`, siehe Designsystem Tabelle 2.4).

## 7. Zu erhaltende Keys + Semantics labels

Aus `screens/my_vehicle_screen.dart`, `widgets/fms_panel.dart` (keine `Semantics`/`tooltip` im Quellcode):

- `Key('settings')` — Zahnrad-IconButton in der AppBar.
- `Key('vehicle-switcher')` — `SegmentedButton` bei mehreren Fahrzeugen.
- `Key('fms-panel')` — Container des gesamten FMS-Grids.
- `Key('fms-${status.code}')` dynamisch, z. B. `fms-1` … `fms-8` — jede einzelne FMS-Kachel.

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Mein Fahrzeug: anzeigen/bearbeiten (FMS-Status) — `my_vehicle_screen_test.dart` | Gleiches Grid, gleiche Keys, größere/farbige Kacheln | Ja |
| Mein Fahrzeug: Offline/Verbindungsverlust — n/a (kein `ConnectionStatus`-Widget, Fehler via SnackBar abgedeckt) | Unverändert n/a, kein neuer Indikator eingeführt | n/a (bewusst) |

Keine Funktion entfällt; `vehicle-switcher`, Besatzungsliste, Zahnrad-Navigation bleiben unverändert.
