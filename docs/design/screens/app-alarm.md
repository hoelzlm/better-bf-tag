# App – Alarm-Screen (`screens/alarm_screen.dart`, `alarm/*`)

Status: Entwurf (ux-02e) · verfeinert das Token-Proof-of-Concept aus ux-02a
(`docs/design/mockups/app-alarm-light.html`/`app-alarm-dark.html`) zum vollständigen Screen-Konzept.

## 1. Zweck

Der wichtigste Screen der App: Vollbild-Alarmanzeige, die automatisch erscheint, sobald die Person eine
pendende Alarmierung hat (`myPendingAlarmProvider`, navigiert über `AlarmNavigationListener`). Zeigt
Meldebild + eigenes Fahrzeug/Funktion und hat genau eine primäre Handlung: **Quittieren** (Empfang
bestätigen — keine Zu-/Absage, keine Statusänderung). Muss unter echtem Stress unmissverständlich sein:
startled/rennend, eine Hand, ggf. grelles Sonnenlicht oder Dunkelheit.

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/alarm-screen-390x844.png`: solide, gute Grundidee (vollflächig Rot,
   großer Pillen-Button) — aber „ALARM"/„ERSTALARM" und der Rest des Texts nutzen fast dieselbe Textgröße
   wie das Stichwort, keine klare Lesereihenfolge; „Alarmierte Fahrzeuge"/„Dein Fahrzeug" sind reiner
   Fließtext in derselben Größe wie Fließtext-Lagebeschreibung — schwer, das eigene Fahrzeug im Vorbeilaufen
   zu finden.
2. Der Hintergrund ist `Colors.red.shade800` (Flutter-Standardfarbe), nicht der Designsystem-Token `alarm`
   (`#D32F2F` hell) — muss auf den neuen Token umgestellt werden, exakt wie im ux-02a-Mockup bereits
   vorgedacht.
3. Keine sichtbare Unterscheidung zwischen Erstalarm und Nachalarmierung außer dem reinen Text
   `alarmSequenceLabel` (`Key('alarm-sequence-label')`) — das Mockup aus ux-02a zeigt nur die
   Erstalarm-Variante; Nachalarmierung braucht ein genauso eindeutiges, aber andersartiges (nicht andersfarbenes)
   Signal.
4. Lange Adressen/Lagebeschreibungen laufen im aktuellen Layout einfach weiter nach unten (SingleChildScroll-
   View) — der Quittieren-Button bleibt zwar fix am unteren Rand (`Column` mit `Expanded` + fixem Footer,
   unverändert gut), aber bei sehr langem Text verschwindet „Dein Fahrzeug" ggf. weit nach unten und ist
   erst nach Scrollen sichtbar, obwohl es für die Person die wichtigste Info nach dem Stichwort ist.
5. Kein Fallback/Hinweis dokumentiert für den Fall, dass Push-Benachrichtigungen deaktiviert sind, und die
   Alarmierung die Person z. B. nur bei App-Neustart via Snapshot erreicht (siehe Abschnitt 4).

## 3. Neues Layout

Beide bestehenden Mockups überarbeitet und neu gerendert:
`docs/design/mockups/app-alarm-light.html`/`.png` und `docs/design/mockups/app-alarm-dark.html`/`.png`
(390×844). Änderungen gegenüber ux-02a: Hintergrund exakt `alarm`-Token (`#D32F2F` hell / `#FF5449` dunkel)
statt `Colors.red.shade800`; klare Typo-Hierarchie: `displaySmall` (32/40 SemiBold, Designsystem 3.1) nur
für „ALARM"; für das Sequenz-Label eine eigene, hier dokumentierte Caps-Variante namens `alarmSequenceCaps`
(ausdrücklich NICHT der Token `labelLarge`, da dessen Gewicht Medium statt Bold ist; auch nicht zu verwechseln
mit der Dart-Funktion `alarmSequenceLabel`, die nur den Textinhalt liefert): **14px Schriftgröße /
20px Zeilenhöhe, Inter Bold (700), Buchstabenabstand 2px**; für das Stichwort gilt EINE hier dokumentierte, screen-eigene Override-Variante namens `alarmKeyword` (ausdrücklich
KEIN `headlineSmall` und kein Mischbegriff): **28px Schriftgröße / 34px Zeilenhöhe, Inter Bold (700)** — nicht
Teil der allgemeinen Skala in Designsystem 3.1, weil dort kein Token so groß/fett für Fließtext-Länge gedacht
ist; `titleMedium` für Fahrzeuglisten-Label, `bodyLarge` für Werte. „Dein Fahrzeug"-Block zusätzlich in eine
eigene, abgesetzte Karte (`onAlarm`-bei-12%-Fläche, nicht transparent) direkt UNTER dem Stichwort verschoben
(vor „Alarmierte Fahrzeuge"), damit er auch bei langem Lagebericht nicht wegscrollt.

Icon neben dem Sequenz-Label (Designsystem 5.11: Unterscheidung NIE über Rotton, nur Label+Icon), alle drei
Zustände aus der Mein Fahrzeug Nachalarmierungs-Logik (`alarmSequenceLabel`, siehe Abschnitt 4) bekommen ein
festes, eigenes Material-Icon aus der bereits gebündelten `Material Icons Outlined`-Schrift (keine neue
Icon-Familie, kein Warndreieck — das würde mit der `warning`-Token-Semantik kollidieren):

| `alarmSequenceLabel(...)` liefert | Anzeige (Großschreibung nur visuell) | Icon (Material, outlined) |
|---|---|---|
| `Erstalarm`                | ERSTALARM            | `notifications_active` |
| `<n>. Nachalarmierung`     | `<N>`. NACHALARMIERUNG | `add_alert`            |
| `Alarmierung` (Fallback, geplanter Alarm ohne Sequenzposition) | ALARMIERUNG | `notifications` |

Alle drei Icons sind aus derselben Glocken-Familie (verschiedene Füllungsgrade/Zustände derselben Form),
damit sie als "zusammengehörig, aber unterscheidbar" erkennbar sind — keines davon ist ein Warnsymbol.

ASCII-Wireframe (390×844, Erstalarm, mit Koordinaten):

```
┌──────────────────────────────────────────┐
│  ALARM                                    │  displaySmall, Buchstabenabstand
│  (bell) ERSTALARM                         │  Label-Caps 14/20 Bold + Icon notifications_active
│                                            │
│  #3 B3 Großbrand Lagerhalle               │  alarmKeyword: 28px/34px Bold (Stichwort)
│                                            │
│  ┌──────────────────────────────────────┐ │  Dein-Fahrzeug-Karte: onAlarm-bei-12%-
│  │ DEIN FAHRZEUG                         │ │  Fläche, fett, direkt unter dem Stichwort
│  │ HLF-1 – MA                            │ │  (verschoben nach oben, s. Problem 4)
│  └──────────────────────────────────────┘ │
│                                            │
│  Industriestraße 7                        │  18px
│  Starke Rauchentwicklung aus dem Dach.    │  16px
│                                            │
│  ALARMIERTE FAHRZEUGE                      │  labelLarge
│  HLF-1                                     │  bodyLarge
│                                            │
│  (Karte, falls Koordinaten vorhanden)      │
│                                            │
│  ┌──────────────────────────────────────┐ │  Quittieren-Button: radiusFull, weiß auf
│  │              QUITTIEREN               │ │  Rot, Mindesthöhe 64dp, volle Breite minus
│  └──────────────────────────────────────┘ │  Rand, fixer Footer (nicht Teil des Scrolls)
└──────────────────────────────────────────┘
```

Nachalarmierungs-Variante: identischer Aufbau, „(bell) ERSTALARM" wird zu „(bell+) 2. NACHALARMIERUNG"
(Icon `add_alert` statt `notifications_active`, Ordinalzahl aus `alarmSequenceLabel` übernommen, gleiche
Rot-Fläche). `app-alarm-light.html`/`.png` zeigt die Erstalarm-Variante, `app-alarm-dark.html`/`.png` zeigt
die Nachalarmierungs-Variante (2. Nachalarmierung) im Dunkelmodus — damit sind Icon-Wechsel UND beide
Farbmodi in den zwei Pflicht-Mockups belegt.

360×640 (kritischer Fall laut Karte — „Quittieren-Button muss ohne Scrollen erreichbar bleiben"): Geprüft
mit `/usr/bin/google-chrome --headless --window-size=360,640`: Kopfbereich (ALARM+Label+Stichwort+Dein-
Fahrzeug-Karte) ≈ 260px, Adresse+Lagebericht ≈ 80px (kurzer Text), Alarmierte-Fahrzeuge-Block ≈ 60px, Footer
mit Button ≈ 96px (Button 64px + 2×16px Padding) — Summe ≈ 496px von 640px, passt ohne Scrollen bei kurzen
Texten. Bei langer Adresse/Lagebeschreibung UND vorhandener Karte reicht 360×640 nicht aus, ohne zu scrollen
— das ist hinnehmbar, WEIL der Footer mit dem Quittieren-Button technisch (wie heute) außerhalb des
scrollbaren Bereichs fix am unteren Rand verankert bleibt (`Column` mit `Expanded(SingleChildScrollView)` +
fixem Footer-`Padding`) und damit IMMER sichtbar ist, unabhängig vom Scroll-Zustand des Inhalts darüber —
das ist das entscheidende Akzeptanzkriterium, nicht "alles passt ohne Scroll".

## 4. Alle Zustände

- **Laden** (`alarm == null`, Alarm noch nicht aus `pairedAlarmsProvider` auflösbar): zentrierter
  `CircularProgressIndicator` in `onAlarm`-Farbe auf vollflächigem `alarm`-Hintergrund (bereits heute über
  `Colors.white` auf `Colors.red.shade800`, nur Token-Umstellung).
- **Erstalarm:** `alarmSequenceLabel` liefert `Erstalarm` → Label-Text „ERSTALARM" (Großschreibung rein
  visuell, Inhalt unverändert aus dem Rückgabewert) + Icon `notifications_active`.
- **Nachalarmierung (für mich als Empfänger):** `alarmSequenceLabel` liefert `<n>. Nachalarmierung`
  (z. B. `1. Nachalarmierung`, `2. Nachalarmierung` — die Ordinalzahl MUSS erhalten bleiben, sie ist für die
  Person relevant: "ist das schon die zweite Nachalarmierung?") → Label-Text „`<N>`. NACHALARMIERUNG" + Icon
  `add_alert`, sonst identisches Layout — gleiche `alarm`-Flächenfarbe (Designsystem 5.11:
  Erstalarm/Nachalarmierung werden NIE über unterschiedliche Rottöne unterschieden, nur über Text+Icon).
- **Alarmierung (Fallback, `alarm` ohne Sequenzposition — z. B. noch `planned`, in der Praxis selten auf
  diesem Screen sichtbar, da er nur bei `triggered`/pendenden Alarmen geöffnet wird, aber von
  `alarmSequenceLabel` als dritter möglicher Rückgabewert dokumentiert):** Label-Text „ALARMIERUNG" + Icon
  `notifications`.
- **Nachalarmierung ohne mich als Empfänger:** Dieser Screen wird dann gar nicht erst geöffnet — geprüft über
  `alarm_screen_test.dart`: „Nachalarmierung ohne mich als Empfänger bleibt auf Einsätze". Das ist kein
  UI-Zustand DIESES Screens, sondern ein Navigationsverhalten von `AlarmNavigationListener`
  (`myPendingAlarmProvider` liefert dann `null`/einen anderen Alarm für diese Person) — im Konzept wichtig zu
  dokumentieren, damit niemand fälschlich eine "für andere sichtbare Nachalarmierung"-UI auf diesem Screen
  entwirft.
- **Lange Adresse/Lagebeschreibung:** Textumbruch, kein Abschneiden (`Text` ohne `maxLines`/`overflow`
  aktuell) — bleibt so; Scrollbereich wächst, Footer mit Quittieren-Button bleibt fix sichtbar (s. Abschnitt 3).
- **Quittieren läuft** (`_acknowledging == true`): Button zeigt 32px-Spinner in `alarm`-Farbe statt Text,
  bleibt in Originalgröße, ist während der Anfrage nicht erneut antippbar.
- **Quittieren fehlgeschlagen:** SnackBar „Quittierung fehlgeschlagen. Bitte erneut versuchen." — Button
  kehrt in editierbaren Zustand zurück, Screen bleibt offen (unverändert).
- **Alarm wird anderswo/durch ein anderes Gerät quittiert, während der Screen offen ist:** `ref.listen` auf
  `myPendingAlarmProvider` schließt den Screen automatisch (`_closeSelf()`), kein manuelles Eingreifen nötig
  — unverändertes Verhalten, kein extra UI-Zustand nötig (Screen verschwindet einfach, Person landet auf dem
  vorherigen/Standard-Screen).
- **Push deaktiviert/kein Push-Token:** Dieser Screen selbst setzt keine Push-Berechtigung voraus — er wird
  ausschließlich über `myPendingAlarmProvider` (abgeleitet aus dem Snapshot + Realtime-WebSocket) geöffnet,
  NICHT direkt durch die Push-Zustellung selbst (`AlarmNavigationListener` reagiert auf Provider-Zustand, der
  Push liefert laut Code-Kommentar nur das zugrunde liegende Realtime-Event als Trigger, während die App im
  Vordergrund ist). Heißt: Ist die App im Vordergrund und die WebSocket-Verbindung aktiv, erscheint der Screen
  unabhängig vom Push-Berechtigungsstatus. Ist die App im Hintergrund/geschlossen und Push ist deaktiviert,
  kommt gar keine System-Benachrichtigung — dafür existiert bereits der Onboarding-Schritt
  „Benachrichtigungen erlauben" (`app-onboarding.md`), der genau dieses Risiko vorab adressiert. Dieser Screen
  selbst braucht keinen eigenen "Push war aus"-Fallback-Zustand, da er diesen Fall nicht erkennen kann/muss.
- **Hell/Dunkel:** Beide Modi bleiben vollflächig `alarm`/`onAlarm` (Spec-Vorgabe: unabhängig vom System-
  Theme) — `#D32F2F`/`#FFFFFF` (hell) vs. `#FF5449`/`#1A0000` (dunkel), siehe die beiden Mockup-Dateien.
- **Motion:** Eintritt des Screens: einmaliger 250ms-Fade-in der Fläche (Designsystem 7), kein Blinken des
  gesamten Screens; falls ein Puls-Badge für "neue Nachalarmierung" später ergänzt wird, ≤1Hz und bei
  Reduced-Motion deaktiviert — aktuell kein Puls-Element auf diesem Screen vorgesehen (reiner Fade-in genügt,
  der Alarmton selbst trägt bereits die Dringlichkeit).

## 5. Interaktionen

- „Quittieren" ist die einzige interaktive Handlung auf dem Screen (kein Zurück-Button, `PopScope(canPop:
  false)` verhindert System-Zurück — unverändert: die Person soll den Alarm bewusst quittieren, nicht
  versehentlich wegwischen).
- Tap auf „Navigation starten" (falls Karte vorhanden, `IncidentLocationCard` identisch zu Einsatzdetail)
  öffnet externe Navigation.
- Der Alarmton läuft im Hintergrund weiter (`alarmSoundProvider`), bis quittiert oder der Screen sich
  automatisch schließt — unverändertes Verhalten, kein neues UI-Element dafür nötig (kein Mute-Button auf
  diesem Screen, bewusst: Ton soll nicht versehentlich stummgeschaltet werden können).

## 6. Testbare Akzeptanzkriterien

1. Der Hintergrund ist exakt der `alarm`-Token (`#D32F2F` hell / `#FF5449` dunkel), nicht `Colors.red.shade800`.
2. Das Sequenz-Label zeigt exakt den Text von `alarmSequenceLabel(...)` (großgeschrieben, Inhalt
   unverändert) — „ERSTALARM", „`<N>`. NACHALARMIERUNG" (inkl. Ordinalzahl) oder „ALARMIERUNG" (Fallback) —
   jeweils mit einem eigenen Icon (`notifications_active`/`add_alert`/`notifications`); die drei Zustände
   unterscheiden sich NIEMALS durch unterschiedliche Flächenfarbe, nur durch Text + Icon.
3. Der Quittieren-Button bleibt bei jeder Scrollposition des Inhalts sichtbar (fixer Footer außerhalb des
   scrollbaren Bereichs).
4. Während `_acknowledging == true` ist der Button nicht erneut antippbar und zeigt einen Spinner.
5. „Dein Fahrzeug" erscheint direkt nach dem Stichwort, vor Adresse/Lagebeschreibung (neue Reihenfolge).
6. Der Screen lässt sich nicht per System-Zurück-Geste schließen (`PopScope(canPop: false)` bleibt erhalten).
7. Schließt sich automatisch, sobald `myPendingAlarmProvider` nicht mehr diesen Alarm liefert.
8. Kontrast `onAlarm`-auf-`alarm` erreicht in beiden Modi mindestens WCAG AA (siehe Designsystem Tabelle 2.3:
   4.98:1 hell, 6.34:1 dunkel).
9. Kein Vollbild-Blinken beim Eintritt — nur ein einmaliger Fade-in ≤ 250 ms.

## 7. Zu erhaltende Keys + Semantics labels

Aus `screens/alarm_screen.dart` (keine `Semantics`/`tooltip` im Quellcode):

- `Key('alarm-sequence-label')` — Text „ERSTALARM"/„NACHALARMIERT".
- `Key('acknowledge-button')` — der Quittieren-Button.
- (von `IncidentLocationCard` wiederverwendet, falls Koordinaten vorhanden: `Key('start-navigation')`, siehe
  `app-einsatzdetail.md`.)

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Alarm-Screen: anzeigen — `alarm_screen_test.dart` | Gleicher Inhalt, neue Hierarchie/Tokens, „Dein Fahrzeug" nach oben verschoben | Ja |
| Alarm-Screen: Navigation (push-ausgelöst, `alarm_navigation_listener.dart`) — inkl. „Nachalarmierung ohne mich als Empfänger bleibt auf Einsätze" | Unverändertes Navigationsverhalten, nur UI der Zielscreen betroffen | Ja |

Keine Funktion entfällt. Kein neuer Push-Fallback-Mechanismus eingeführt (s. Abschnitt 4).
