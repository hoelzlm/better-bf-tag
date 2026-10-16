# App – Kopplung (`screens/pairing_screen.dart`, `pairing_code_scanner.dart`)

Status: Entwurf (ux-02e) · baut auf `docs/design/design-system.md`

## 1. Zweck

Erster Screen nach Installation (oder nach Abmeldung/Session-Widerruf): das Gerät mit einer Person über
einen 8-stelligen Kopplungscode verbinden, per QR-Scan oder manueller Eingabe (ADR 0010). Primäre Aufgabe:
Code erfassen (scannen oder tippen), Koppeln bestätigen.

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/kopplung-390x844.png` zeigt enormen Leerraum zwischen Titel und
   Kamera-/Eingabebereich — der Kamera-Scanner (`SizedBox(height: 240)`) scheint im Screenshot (Widget-Test
   ohne echte Kamera) leer zu bleiben, wodurch fast der ganze obere Bildschirmbereich ungenutzt wirkt.
2. Keine visuelle Trennung zwischen "Scannen" und "Code eingeben" — wirkt wie zwei zufällig untereinander
   platzierte Elemente statt zwei gleichwertige Wege zum selben Ziel.
3. Der Fehlertext (`Key('pair-error')`) nutzt `Theme.of(context).colorScheme.error`, was nach Designsystem-
   Entscheidung (Abschnitt 10) auf die `warning`-Farbe gemappt wird — richtig für einen ungültigen Code
   (Formularfehler, kein Alarm), aber heute im unbearbeiteten Theme zufällig rot und optisch identisch mit
   dem allgemeinen App-Rot, keine klare Trennung von "Alarm-Rot" erkennbar.
4. Kein Platzhalter/Hinweis in der Kamera-Fläche, wenn die Kamera-Berechtigung fehlt oder die Kamera noch
   lädt — auf dem Screenshot nicht zu unterscheiden, ob die Fläche "lädt", "keine Berechtigung" oder "Fehler"
   bedeutet.

## 3. Neues Layout

ASCII-Wireframe (390×844):

```
┌──────────────────────────────────────────┐
│  Gerät koppeln                            │  AppBar
├──────────────────────────────────────────┤
│  QR-Code scannen                          │  titleMedium Label über der Kamera
│ ┌────────────────────────────────────────┐│
│ │                                        ││  Kamera-Vorschau, radiusLarge,
│ │         (Live-Kamerabild)              ││  surfaceContainer-Rahmen als Platzhalter
│ │                                        ││  wenn kein Bild/keine Berechtigung
│ └────────────────────────────────────────┘│
│                                            │
│  ──────────── oder Code eingeben ──────── │  outline-Trenner mit Label (klar: Alternative)
│                                            │
│  ┌────────────────────────────────────────┐│
│  │ Code eingeben          ABCD-EFGH       ││  TextField, radiusMedium, floating Label
│  └────────────────────────────────────────┘│
│                                            │
│              [ Koppeln ]                   │  Primärbutton, volle Breite, ≥48dp
│                                            │
│  ⚠ Ungültiger Code. Bitte erneut prüfen.  │  warning-Text, nur sichtbar bei Fehler
└──────────────────────────────────────────┘
```

Kein eigenes HTML-Mockup für diesen Screen Pflicht (nicht in der "mindestens"-Liste der Karte) — die
Token-Anwendung ist 1:1 aus `app-mein-fahrzeug.md`/Designsystem ableitbar (Card-Radius, Primärbutton,
warning-Fehlertext). 360×640: Kamera-Fläche schrumpft proportional (z. B. 180 statt 240 px Höhe, über
`LayoutBuilder`/`AspectRatio` statt fixer `SizedBox`-Höhe — siehe Akzeptanzkriterium 6), Eingabe+Button
bleiben ohne Scrollen erreichbar.

## 4. Alle Zustände

- **Initial/leer:** Kamera-Vorschau lädt (Platzhalter: zentriertes Kamera-Icon in `onSurfaceVariant` auf
  `surfaceContainer`, kein Spinner nötig solange die Plattform-Kamera selbst noch initialisiert — reine
  Optik, kein neues State-Handling im Code).
- **Kamera-Berechtigung verweigert:** `mobile_scanner` liefert plattformseitig i. d. R. einen eigenen
  Hinweis/Fehlerzustand in der Kamerafläche; dieses Konzept verlangt keine neue App-Logik dafür (kein API im
  aktuellen Code, das den Berechtigungsstatus separat exponiert) — die manuelle Codeeingabe bleibt in jedem
  Fall vollständig nutzbar als Fallback, das ist der entscheidende Punkt: der Screen funktioniert auch ganz
  ohne Kamera.
- **Eingabe, kein Fehler:** leeres `pair-error`-Textfeld (Code: `_errorText ?? ''`) — im neuen Design wird
  die Fehlerzeile nur gerendert (Platz eingenommen), wenn `_errorText != null`, statt eines leeren `Text('')`,
  damit kein unsichtbarer Leerraum unterhalb des Buttons entsteht, wenn kein Fehler vorliegt.
- **Senden (`_isSubmitting == true`):** „Koppeln"-Button zeigt 16px-Spinner (`onPrimary`) statt Text, Button
  bleibt in Originalgröße, Eingabefeld bleibt editierbar aber Button ist inaktiv (Doppel-Submit verhindert).
- **Fehler (ungültiger Code):** `warning`-Text unterhalb des Buttons mit Warn-Icon, Server-Fehlertext
  (`failure.message`) unverändert übernommen.
- **Gerät abgemeldet (Session widerrufen):** einmaliger SnackBar „Dieses Gerät wurde abgemeldet." beim
  Betreten des Screens (`PairedUnpaired(revoked: true)`), unverändertes Verhalten, nur SnackBar folgt dem
  neuen Theme (surfaceContainer-Fläche statt Flutter-Default).
- **Hell/Dunkel:** Karten-/Feld-Token nach Tabelle 2.1; Kamera-Platzhalter-Icon-Kontrast in beiden Modi ≥ AA.
- **Offline:** kein spezifisches Offline-Banner auf diesem Screen (kein `ConnectionStatus`-Widget hier
  vorhanden, analog Mein Fahrzeug) — ein Netzwerkfehler beim Koppeln landet im normalen Fehlertext-Zustand
  oben (`PairingFailure`-Mapping ist bereits generisch).

## 5. Interaktionen

- QR-Scan: automatischer Trigger bei erkanntem Code (`onDetected` → `_onScanned` → `_pair`), kein Tap nötig.
- Manuelle Eingabe: Tippen + „Koppeln" oder Enter/Submit im Textfeld (`onSubmitted`) — beide Wege unverändert
  gleichwertig.
- `_scannerConsumed`-Schutz verhindert Doppel-Pairing durch zwei schnelle Scans — unverändert.

## 6. Testbare Akzeptanzkriterien

1. Kamera-Vorschau und manuelle Codeeingabe sind beide sichtbar und bedienbar, ohne dass eines das andere
   blockiert.
2. Ein erfolgreicher Scan löst denselben `_pair()`-Aufruf aus wie ein manuell eingegebener + bestätigter Code.
3. Während `_isSubmitting == true` ist der „Koppeln"-Button deaktiviert und zeigt einen Spinner statt Text.
4. Die Fehlerzeile (`Key('pair-error')`) ist nur sichtbar/belegt Platz, wenn ein Fehlertext vorliegt; ihre
   Farbe ist `warning`, nie `alarm`.
5. Bei `PairedUnpaired(revoked: true)` erscheint die SnackBar „Dieses Gerät wurde abgemeldet." genau einmal
   beim Betreten des Screens.
6. Auf 360×640 ist die Kamera-Fläche kleiner, aber Eingabefeld + Button bleiben ohne Scrollen sichtbar.
7. Kontrast der Fehlerzeile und des Eingabefeld-Labels erreicht WCAG AA in hell und dunkel.

## 7. Zu erhaltende Keys + Semantics labels

Aus `screens/pairing_screen.dart` (keine `Semantics`/`tooltip` im Quellcode):

- `Key('pair-code')` — Textfeld für die manuelle Codeeingabe.
- `Key('pair-submit')` — „Koppeln"-Button.
- `Key('pair-error')` — Fehlertext-Widget.

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Kopplung: anzeigen/anlegen (Code-Eingabe) — `pairing_and_settings_test.dart` | Gleiches Textfeld + Button, neue Card-/Trenner-Optik, Scan+manuell weiterhin gleichwertig | Ja |
| Kopplung: Fehlerzustand (ungültiger Code) — `pairing_and_settings_test.dart`: „invalid code shows the error text" | Gleicher Fehlertext, jetzt in `warning`-Farbe statt generischem `colorScheme.error` | Ja |

Keine Funktion entfällt. Keine neue API/kein neuer Berechtigungsstatus eingeführt — der Kamera-Platzhalter
ist rein optisch (Zustand ohnehin durch `mobile_scanner` selbst gerendert).
