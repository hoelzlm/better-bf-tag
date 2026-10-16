# App – Navigationsleiste (`main_nav_bar.dart`, `router.dart`)

Status: Entwurf (ux-02e) · baut auf `docs/design/design-system.md` (Abschnitt 5.9, 10)

## 1. Zweck

Dauerhaft sichtbare untere Navigation zwischen den vier gleichrangigen Hauptbereichen der App: **Mein
Fahrzeug** (`/`, Standard-Tab), **Einsätze** (`/einsaetze`), **Durchsagen** (`/durchsagen`), **Ablauf**
(`/tagesablauf`). Einstellungen sind bewusst kein fünfter Tab, sondern über das Zahnrad-Icon in der AppBar
jedes Tab-Screens erreichbar (unverändert, siehe `app-mein-fahrzeug.md`/`app-einsaetze.md`).

Die Leiste wird NICHT angezeigt auf: Onboarding, Kopplung, Einsatzdetail, Alarm-Screen, Einstellungen
(bestätigt durch Grep über `apps/mobile/lib/screens/*.dart` nach `bottomNavigationBar: const MainNavBar` —
nur in `my_vehicle_screen.dart`, `incidents_screen.dart`, `program_screen.dart`, `announcements_screen.dart`).
Das bleibt unverändert; Einsatzdetail und Alarm sind bewusst "Vollbild ohne Tab-Rahmen", damit nichts vom
Alarm/Einsatzinhalt ablenkt.

## 2. Usability-Probleme heute

1. Die Leiste erbt den rötlichen `ColorScheme.fromSeed(Colors.red)`-Ton (zu sehen z. B. in
   `docs/design/screenshots/before/app/mein-fahrzeug-390x844.png`): aktiver Tab "Fahrzeug" bekommt eine
   blassrosa Pille — dieselbe Farbfamilie wie der Alarm-Screen, wodurch der Alarm seine Signalwirkung
   verliert (Grundprinzip 1 des Designsystems).
2. Inaktive Icons sind reine Umrisse ohne klaren Kontrast zum Pink-Hintergrund, Labels sehr klein — auf dem
   Screenshot kaum zu unterscheiden, welcher Tab aktiv ist, außer an der Pillenfarbe.
3. Icon/Label-Wahl zwischen Code (`main_nav_bar.dart`: `campaign_outlined` für Einsätze,
   `chat_bubble_outline` für Durchsagen, `schedule_outlined` für Ablauf) und dem früheren Token-Mockup
   `docs/design/mockups/app-mein-fahrzeug.html` (nutzte `local_fire_department`/`campaign`/`event_note`)
   widersprachen sich — das Mockup war nur ein Farb-Proof-of-Concept der ux-02a-Karte, keine endgültige
   Navigationsentscheidung. Dieses Konzept legt die Icons verbindlich fest (Abschnitt 3) und das Mockup
   wurde entsprechend korrigiert.

## 3. Neues Layout

Kein neues HTML-Mockup nötig (keine App-Vollbild-Karte für sich) — die korrigierte Referenz ist die
Navigationsleiste am unteren Rand von `docs/design/mockups/app-mein-fahrzeug.png` (390×844, siehe
`app-mein-fahrzeug.md` Abschnitt 3).

ASCII (Querschnitt, 390 px breit, Höhe 72 dp inkl. Safe-Area-Bottom):

```
┌──────────────────────────────────────────────┐
│  🚒          📢          💬          📅       │  <- Icon 24dp, aktiv: primary + gefüllte
│ Fahrzeug   Einsätze   Durchsagen   Ablauf      │     Variante, inaktiv: onSurfaceVariant, outline-Icon
└──────────────────────────────────────────────┘
   surfaceVariant-Fläche, 1px outline-Trenner oben, keine Schatten
```

Verbindliche Icon-Zuordnung (Material Symbols Outlined/Filled-Paar, entspricht den heutigen
`main_nav_bar.dart`-Icons — bewusst beibehalten, nicht das abweichende Mockup-Set):

| Tab | Route | Icon (inaktiv/aktiv) | Label |
|---|---|---|---|
| Fahrzeug | `/` | `local_shipping_outlined` / `local_shipping` | „Fahrzeug" |
| Einsätze | `/einsaetze` | `campaign_outlined` / `campaign` | „Einsätze" |
| Durchsagen | `/durchsagen` | `chat_bubble_outline` / `chat_bubble` | „Durchsagen" |
| Ablauf | `/tagesablauf` | `schedule_outlined` / `schedule` | „Ablauf" |

Token-Anwendung: `surfaceVariant`-Fläche, 1 px `outline`-Trenner oben, aktiver Tab Icon+Label in `primary`,
inaktiv `onSurfaceVariant`, Touch-Ziel ≥ 56 dp Höhe je Tab (volle Leistenhöhe), kein Label-Ausblenden bei
Inaktivität (immer sichtbar, Material-3-`NavigationBar`-Standard `labelBehavior: alwaysShow`).

360×640: Leiste bleibt exakt gleich hoch (56–72 dp), nimmt proportional mehr vom Screen ein, aber nichts
wird abgeschnitten — vier Tabs mit kurzen Labels passen komfortabel in 360 px Breite (90 px/Tab).

## 4. Alle Zustände

- **Normal:** vier Tabs, genau einer aktiv (bestimmt durch `currentIndex`-Parameter, von der jeweiligen
  Screen-Route gesetzt).
- **Badge/Ungelesen-Indikator:** Design-System 5.9 beschreibt optional einen `alarm`-farbenen Punkt auf
  einem Tab für ungelesene Durchsagen/aktive Alarme. **Heute nicht umsetzbar ohne neue Funktion:** Es gibt
  weder einen Ungelesen-Zähler für Durchsagen (`pairedAnnouncementsProvider` liefert nur die Liste, keinen
  Lese-Status) noch eine Zuordnung "aktiver Alarm → Tab" in den vorhandenen Daten. Dieses Konzept **führt
  keinen Badge ein** (Spec: keine neuen Funktionen) — die Leiste sieht optisch so aus, dass ein Badge später
  ergänzt werden könnte (Platz oben rechts am Icon), ist aber im ux-03-Umsetzungsticket NICHT enthalten,
  außer der Architekt entscheidet sich explizit dafür und begründet ein eigenes Ticket.
- **Offline:** Die Leiste selbst zeigt keinen eigenen Status; Offline-Banner (falls auf dem jeweiligen
  Screen vorhanden) erscheinen oberhalb des Contents, die Navigationsleiste bleibt unverändert bedienbar.
- **Hell/Dunkel:** Flächen-/Textfarben tauschen 1:1 nach Tabelle 2.1 des Designsystems; auf Dunkel erhält
  die Leiste keinen zusätzlichen Schatten (Designsystem 4.3), nur die `outline`-Trennlinie.

## 5. Interaktionen

- Tap auf einen Tab navigiert sofort per `context.go(route)` (kein Doppel-Tap-Schutz nötig, Verhalten
  unverändert — `onDestinationSelected` ignoriert bereits einen Tap auf den aktuell aktiven Tab).
- Kein Swipe zwischen Tabs (Material-3-`NavigationBar`-Standard, kein `TabBarView`) — bleibt wie heute.
- Fokus/Tastatur (falls Bluetooth-Tastatur am Handy): sichtbarer Fokusring in `primary`, Tab-Reihenfolge
  links nach rechts.

## 6. Testbare Akzeptanzkriterien

1. Die Leiste zeigt genau 4 Tabs in der Reihenfolge Fahrzeug/Einsätze/Durchsagen/Ablauf mit den in
   Abschnitt 3 festgelegten Icons/Labels.
2. Der aktive Tab ist durch `primary`-Farbe (Text+Icon) UND gefülltes Icon erkennbar, nie durch Farbe allein
   fehlerfrei trennbar von anderen Tabs.
3. Jeder Tab hat eine Touch-Fläche ≥ 48×48 dp (gemessen: volle Leistenhöhe × 390/4 px Breite).
4. Die Leiste erscheint NICHT auf `/onboarding`, `/pair`, `/einsaetze/:id`, `/alarm/:alarmId`, `/settings`.
5. Tap auf einen inaktiven Tab navigiert zur entsprechenden Route; Tap auf den aktiven Tab navigiert nicht
   erneut (kein Rebuild-Loop).
6. In beiden Theme-Modi (hell/dunkel) bleibt der Kontrast Text/Icon zu Fläche ≥ WCAG AA (siehe
   `docs/design/tools/contrast.py`, `primary`-auf-`surfaceVariant` und `onSurfaceVariant`-auf-`surfaceVariant`).
7. Kein Badge/Ungelesen-Punkt wird gerendert (da keine Datenquelle existiert) — dies ist eine bewusste
   Nicht-Funktion, kein Fehler.

## 7. Zu erhaltende Keys + Semantics labels

Aus `apps/mobile/lib/widgets/main_nav_bar.dart` (keine `Semantics`/`tooltip` vorhanden, nur Keys):

- `Key('main-nav-bar')` — die `NavigationBar` selbst.
- `Key('nav-my-vehicle')` — Tab „Fahrzeug".
- `Key('nav-incidents')` — Tab „Einsätze".
- `Key('nav-announcements')` — Tab „Durchsagen".
- `Key('nav-program')` — Tab „Ablauf".

Diese fünf Keys bleiben exakt so benannt (geprüft durch `main_nav_bar_test.dart`, `navigation_test.dart`).

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Navigationsleiste (`main_nav_bar.dart`, `router.dart`): Navigation — `main_nav_bar_test.dart`, `navigation_test.dart` | Gleiche 4 Tabs, gleiche Routen, gleiche Keys, nur neue Token/Farben/Icons-Feinschliff | Ja |

Keine Funktion entfällt. Kein neues Verhalten (Badge explizit NICHT umgesetzt, s. o.).
