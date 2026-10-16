# App – Einsatzdetail (`screens/incident_detail_screen.dart`, `map/incident_location_card.dart`)

Status: Entwurf (ux-02e) · baut auf `docs/design/design-system.md`

## 1. Zweck

Detailansicht eines Einsatzes (`/einsaetze/:id`): Meldebild (Stichwort, Adresse, Lagebeschreibung), Karte +
Navigation zum Einsatzort (falls Koordinaten vorhanden), und — nur für Betreuer mit Berechtigung
Einsatzvorbereitung/Leitstelle/Administrator — das Drehbuch. Primäre Aufgabe: schnell erfassen, worum es
geht, und ggf. zum Einsatzort navigieren. Wird oft direkt nach einer Alarmierung aufgerufen.

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/einsatzdetail-390x844.png` zeigt den Fehlerzustand „Einsatz konnte
   nicht geladen werden." mittig in viel Leerraum — wie bei Einsätze kein sichtbarer Hinweis auf
   Pull-to-Refresh als Wiederholungsweg.
2. Die Drehbuch-Box (`Container` mit `Colors.amber.withValues(alpha: 0.15)`-Hintergrund,
   `Colors.amber.shade800`-Rahmen, Schloss-Icon) nutzt eine Ad-hoc-Farbe ohne Bezug zum restlichen Token-
   system — wirkt im Kontext des neuen, ruhigen Designsystems wie ein Fremdkörper statt wie ein bewusst
   gestaltetes "nur für dich sichtbar"-Signal.
3. Meldebild (Stichwort/Adresse/Lagebeschreibung) ist reiner, ununterscheidbarer Fließtext ohne Label/
   Hierarchie zwischen Adresse und Lagebeschreibung — auf einen Blick unter Zeitdruck schwer zu erfassen,
   welche Zeile die Adresse ist.
4. Keine erkennbare Rückkehr-/Breadcrumb-Information, aus welcher Liste man kam, falls direkt aus einem Push
   /Alarm-Screen gesprungen (kein Problem des Codes, aber im visuellen Konzept zu berücksichtigen, da go_router
   hier `push` statt `go` nutzt und damit korrekt ein Zurück-Pfeil in der AppBar erscheint — unverändert
   gewünscht).

## 3. Neues Layout

`docs/design/mockups/app-einsatzdetail.html` → gerendert als `docs/design/mockups/app-einsatzdetail.png`
(390×844, hell, Variante „mit Drehbuch + mit Koordinaten" — die Kombination mit den meisten UI-Elementen).

ASCII-Wireframe (390×844, voll bestückt: mit Drehbuch, mit Koordinaten):

```
┌──────────────────────────────────────────┐
│  ←  #3 B3 Großbrand Lagerhalle            │  AppBar mit Zurück-Pfeil, headlineSmall
├──────────────────────────────────────────┤
│  Großbrand Lagerhalle                     │  headlineSmall (Stichwort)
│                                            │
│  📍 Adresse                                │  labelMedium-Label + Icon vor der Adresse
│  Industriestraße 7                        │  bodyLarge
│                                            │
│  Lagebeschreibung                          │  labelMedium-Label
│  Starke Rauchentwicklung aus dem Dach.    │  bodyLarge
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │        (Kartenausschnitt 180px)       │ │  Card, radiusLarge
│  │  [ Navigation starten ]               │ │  Primärbutton darunter
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │  Drehbuch-Card: primaryContainer-Rahmen-
│  │ 🔒 Drehbuch – nur für dich sichtbar   │ │  Variante (NICHT amber/Ad-hoc), Schloss-
│  │ Aufbau: Nebelmaschine, 2 Darsteller…  │ │  Icon in primary, deutlich abgesetzt von
│  └──────────────────────────────────────┘ │  den öffentlichen Meldebild-Feldern oben
└──────────────────────────────────────────┘
```

Alle vier Kombinationen mit/ohne Drehbuch × mit/ohne Koordinaten verschieben nur, ob die Karten-Card bzw. die
Drehbuch-Card gerendert wird — Grundgerüst (AppBar, Meldebild-Block) bleibt identisch.

360×640: Meldebild-Block (Stichwort+Adresse+Lage) + Kartenvorschau passen ohne Scrollen in den sichtbaren
Bereich bei kurzen Texten; bei langer Lagebeschreibung oder vorhandenem Drehbuch scrollt der Screen (bereits
heute `SingleChildScrollView`) — das ist hier unkritisch, da Einsatzdetail kein Ein-Blick-Screen wie Alarm
ist, sondern bewusst zum Lesen/Scrollen gedacht ist.

## 4. Alle Zustände

Vier Kombinationen (laut `incidents_screen_test.dart`, 5 Tests für `IncidentDetailScreen`), alle müssen im
Konzept vorkommen:

1. **Mit Drehbuch, mit Koordinaten** — Kartenvorschau + Drehbuch-Card beide sichtbar (siehe Wireframe oben).
2. **Mit Drehbuch, ohne Koordinaten** — keine Karten-Card (kein `incident.location`), Drehbuch-Card direkt
   nach der Lagebeschreibung.
3. **Ohne Drehbuch, mit Koordinaten** — Karten-Card sichtbar, kein Drehbuch-Block danach (Feld `script` ist
   `null`, kommt vom Server nur bei entsprechender Berechtigung — die App entscheidet nichts selbst, rein
   feldgetrieben, unverändert).
4. **Ohne Drehbuch, ohne Koordinaten** — nur der reine Meldebild-Block, Screen endet nach der
   Lagebeschreibung (ggf. mit mehr Weißraum/Leerzustand-Gefühl, bewusst akzeptiert, kein künstlicher Füller).

Zusätzlich:

- **Laden:** zentrierter `CircularProgressIndicator` (`primary`).
- **Fehler:** Text „Einsatz konnte nicht geladen werden." + `warning`-Icon + Hinweis auf Pull-to-Refresh
  (analog `app-einsaetze.md`).
- **Leerer Lagebericht:** `incident.report.isNotEmpty`-Prüfung bleibt — wenn leer, wird der
  „Lagebeschreibung"-Block komplett ausgeblendet, nicht als leeres Label gerendert (unverändertes Verhalten).
- **Hell/Dunkel:** Drehbuch-Card nutzt `primaryContainer`/`primary` (nicht amber) in beiden Modi — in Dunkel
  entsprechend Tabelle 2.1 (`#0E3A42`/`#4FB8C9`), weiterhin klar von der neutralen Meldebild-Fläche abgesetzt.
- **Offline:** kein eigenes Offline-Banner auf diesem Screen im aktuellen Code; Verbindungsfehler laufen über
  den Fehlerzustand oben.

## 5. Interaktionen

- „Navigation starten" öffnet die externe Navigations-App (`startNavigation`); schlägt das fehl, erscheint
  eine SnackBar „Navigation konnte nicht gestartet werden" (unverändert).
- Zurück-Pfeil (AppBar) navigiert zur vorherigen Route (`push`-Navigation, Standard-Verhalten).
- Pull-to-Refresh lädt den Einsatz neu.

## 6. Testbare Akzeptanzkriterien

1. Die Drehbuch-Card erscheint ausschließlich wenn `incident.script != null`, niemals selbst entschieden.
2. Die Karten-Card (inkl. „Navigation starten"-Button) erscheint ausschließlich wenn `incident.location != null`.
3. Die Drehbuch-Card nutzt `primaryContainer`/`primary`-Token, nicht `Colors.amber`.
4. Alle vier Kombinationen (Abschnitt 4, Punkte 1–4) rendern ohne Layout-Fehler/Überlappung.
5. „Lagebeschreibung" wird nur gerendert, wenn `incident.report` nicht leer ist.
6. Fehlgeschlagene Navigation zeigt die SnackBar mit dem unveränderten Text.
7. Kontrast der Drehbuch-Card-Texte (`onPrimaryContainer`-äquivalent) erreicht WCAG AA in hell und dunkel.

## 7. Zu erhaltende Keys + Semantics labels

Aus `screens/incident_detail_screen.dart`, `map/incident_location_card.dart` (keine `Semantics`/`tooltip`
im Quellcode):

- `Key('script-section')` — Container des Drehbuch-Blocks.
- `Key('start-navigation')` — „Navigation starten"-Button in `IncidentLocationCard`.

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Einsatzdetail: anzeigen (inkl. Karte, Drehbuch, Navigation) — `incidents_screen_test.dart`: 5 Tests für `IncidentDetailScreen` (mit/ohne Drehbuch, mit/ohne Koordinaten/Karte/Navigationsbutton) | Alle 4 Kombinationen weiterhin abgebildet, Drehbuch-Card nur optisch neu (primaryContainer statt amber) | Ja |

Keine Funktion entfällt; Sichtbarkeitslogik für Drehbuch/Karte bleibt rein feldgetrieben (keine neue
Berechtigungsprüfung in der App).
