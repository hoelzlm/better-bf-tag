# Monitor — Kopplung

Grundlage: `docs/design/design-system.md` (Tokens, Monitor-Typskala 3.2, Komponenten). Baut auf
`docs/design/mockups/monitor-standby.html`/`monitor-alarm.html` (gleiche Tokens, gleiche Schrift) auf.
Quelle: `apps/web/lib/screens/monitor_pairing_screen.dart`.

## 1. Zweck

Erster Bildschirm nach dem Öffnen von `/monitor` auf einem neuen/entkoppelten Gerät. Ein Betreuer steht
vor dem TV (oder bedient es per Fernbedienung/Tastatur) und trägt einen 8-stelligen Kopplungscode ein, den
er zuvor in der Admin-Web unter „Monitore“ erzeugt hat. Danach läuft der Monitor unbeaufsichtigt weiter
(Standby/Einsatzansicht/Alarm).

**Korrektur Review-Runde 1:** „Kopplung ist die einzige Interaktion“ war falsch — vor der Kopplung (und bei
jedem Neustart/Browser-Reload des Geräts) zeigt `monitor_screen.dart:117/204–231` zunächst ein
**Aktivierungs-Overlay** (`_ActivationOverlay`, Key `monitor-activation-overlay`): ein Tap irgendwo auf die
Fläche aktiviert WakeLock + Vollbild und schaltet die Audiowiedergabe des Browsers für den Rest der Sitzung
frei (ADR 0017 — ohne diesen einen Tap als „genuine user gesture“ bleibt der Alarm-Gong stumm, Browser-
Autoplay-Policy). Das ist die **einzige** Interaktion, die auf jedem Monitor-Gerät garantiert stattfinden
muss, Kopplung ist die zweite. Dieses Dokument behandelt daher beide Schritte: Aktivierung (§3/§4 erster
Zustand) und Kopplung (§3/§4 übrige Zustände).

## 2. Usability-Probleme heute (Screenshot `docs/design/screenshots/before/monitor/kopplung-1920x1080.png`)

1. Ein kleiner, grau-auf-schwarz zentrierter Block auf sonst komplett leerer 1920×1080-Fläche — auf einem
   großen TV aus mehreren Metern wirkt das wie ein halb geladener Bildschirm, nicht wie eine bewusste
   Eingabemaske. Keine Markenidentität (kein Logo/Icon), kein Hinweis, *wo* der Code herkommt.
2. Titel „Monitor koppeln“ 24 px (Default-`headlineMedium`) — auf Monitor-Maßstab (Soll ≥ 28 px, siehe
   Designsystem 3.2) zwar knapp über dem Minimum, aber verschwindend klein im Verhältnis zur Fläche und ohne
   erkennbare Hierarchie zum Rest.
3. Eingabefeld nutzt Default-`OutlineInputBorder` in der (zufälligen) Seed-Rot-Linie des alten Themes — Rot
   taucht hier auf, obwohl nichts Alarmierendes passiert (Grundprinzip 1 verletzt).
4. Fehlertext „ungültiger Code“ nutzt `Colors.redAccent` — selbes Problem: ein Formularfehler ist kein Alarm
   (Designsystem 5.2/5.10), Rot muss dem Alarmzustand vorbehalten bleiben.
5. „Gesperrt/neu gekoppelt“-Hinweis (`monitor-revoked-hint`) nutzt `Colors.orangeAccent` — kollidiert farblich
   mit FMS 3 (`#F2A900`) und wirkt wie ein Status statt wie ein Systemhinweis.
6. Keine sichtbare Anleitung, dass der Code über die Fernbedienung/Tastatur eingegeben wird, keine Angabe
   zum Format außer dem Platzhalter `ABCD-EFGH` (verschwindet beim Tippen, kein Label bleibt stehen).
7. Lade-/Offline-Zustand während der Kopplung (bei Verbindungsverlust, laut Regressionsnetz bereits getestet)
   hat aktuell keine sichtbar eigene Gestaltung — nur der generische Fehlertext.
8. **Aktivierungs-Overlay ohne jede Erklärung** (`_ActivationOverlay`, `monitor_screen.dart:204–231`): reiner
   Fließtext „Zum Aktivieren tippen“, 48 px Weiß auf Schwarz, kein Icon, keine Markenidentität, kein Hinweis
   *warum* ein Tap nötig ist. Ein Betreuer, der das Gerät zum ersten Mal einrichtet, versteht nicht, dass genau
   dieser Tap später den Alarm-Gong freischaltet — tippt er stattdessen direkt den Kopplungscode über eine
   angeschlossene Tastatur ein (ohne vorher irgendwo zu *klicken*), bleibt der Gong im Ernstfall stumm, ohne
   dass irgendeine UI das je sichtbar gemacht hätte. Zweiter, eigenständiger Zustand desselben Grundproblems
   wie 1–6: Information fehlt bzw. ist zu klein/unauffällig für die Tragweite.

## 3. Neues Layout

### 3.1 Aktivierung (vorgelagerter Zustand, eigene PNG `monitor-aktivierung.png`)

Pixelraster 1920×1080, Grund bleibt bewusst reines Schwarz (nicht `surface` #14181C) — das ist die einzige
Fläche der gesamten App, die absichtlich *vor* dem Theme liegt: Sie muss funktionieren, noch bevor irgendein
Font/Theme geladen hat, und signalisiert „hier passiert noch nichts, bis du tippst“, nicht „das ist schon der
Monitor“. Ganze Fläche ist die Tap-Zone (`Key('monitor-activation-overlay')`), kein kleiner Button.

```
┌──────────────────────────────── 1920×1080 ────────────────────────────────┐
│                                   (Schwarz)                                │
│                              [Icon-Marke 96×96]            y≈420          │
│                                                                            │
│                         Zum Aktivieren tippen              monitorAlarmTitle-Stufe 48, Bold, Weiß │
│                                                                            │
│              Aktiviert Vollbild und Ton für Alarmdurchsagen.               monitorBody 28, Weiß 70 %│
└────────────────────────────────────────────────────────────────────────────┘
```

Icon-Marke (dasselbe `app-icon-mono.svg`, Weiß statt `primary` — auf Schwarz vor Theme-Laden gibt es noch
keine Tokens) stiftet Wiedererkennung mit dem Kopplungsbildschirm direkt danach. Zweite Zeile „Aktiviert
Vollbild und Ton für Alarmdurchsagen.“ ist **neu** (behebt Problem 8): macht genau das sichtbar, was der Tap
bewirkt, ohne technisches Vokabular („WakeLock“/„Autoplay-Policy“) zu verwenden.

### 3.2 Kopplung

Pixelraster 1920×1080, dunkler Grund (`surface` #14181C, identisch zu Standby/Einsatz — ein Monitor hat
genau eine visuelle Basis in allen Zuständen). Zentrierte Karte, kein Vollbild-Formular ohne Kontext.

```
┌──────────────────────────────── 1920×1080 ────────────────────────────────┐
│                                                                            │
│                              [Icon-Marke 96×96]            y≈300          │
│                              Monitor koppeln                 monitorHeadline 40, SemiBold
│                 Kopplungscode aus „Monitore“ in der Admin-Web eingeben     bodyLarge-äquivalent 28, onSurfaceVariant
│                                                                            │
│                    ┌──────────────────────────────────┐                   │
│                    │   A B C D  –  E F G H             │  monitorDisplay 64, Einzelzeichen-Tracking
│                    └──────────────────────────────────┘   720×140, radiusLarge 16, outline 2px, Fokus: primary 3px
│                              (Fehlertext, wenn vorhanden)  monitorBody 28, warning
│                                                                            │
│                         [  Koppeln  ]                      56 px hoch, FilledButton-Stil, min. 320 px breit
│                                                                            │
│                                                                            │
│  Fußzeile (immer sichtbar, monitorLabel 22, onSurfaceVariant):            │
│  „Gerätename wird nach der Kopplung hier angezeigt.“                      │
└────────────────────────────────────────────────────────────────────────────┘
```

Karte ist horizontal/vertikal zentriert, max. Breite 900 px, Innenabstand `huge` (64). Alle Texte zentriert.
Das Eingabefeld behält Key `monitor-pairing-code`, bekommt aber ein **stehendes Label** „Kopplungscode“
oberhalb des Felds (nicht nur Platzhalter) + die Formatmaske `AAAA-AAAA` bleibt als Platzhalter erhalten.
Feld-Styling folgt Designsystem 5.2 (Fokus: 3 px `primary`-Rahmen statt Default-2px, da Monitor-Maßstab),
Fehlerzustand: 2 px `warning`-Rahmen + Fehlertext in `warning`, **nicht** `alarm`-Rot.

Icon-Marke: `app-icon-mono.svg` aus `docs/design/icon/`, 96×96, Farbe `primary` auf transparentem Grund
(Monitor ist dunkel) — stellt die Markenidentität her, ohne wie ein Alarmsymbol zu wirken.

## 4. Alle Zustände

- **Aktivierung (vor allem anderen, bei jedem Start/Reload):** siehe Abschnitt 3.1 — ganze Fläche tappbar,
  kein Timeout, kein automatisches Weiterschalten (muss ein echter Nutzer-Tap sein, sonst bleibt die
  Audiofreigabe des Browsers aus). Verschwindet sofort nach dem Tap, kein Bestätigungs-Zwischenschritt.
- **Leer (Erstbesuch):** wie oben, Feld leer, Fokus automatisch im Feld (`autofocus`, bleibt erhalten),
  kein Fehlertext, kein Revoked-Hinweis.
- **Eingabe:** Zeichen erscheinen in `monitorDisplay` 64 px mit Tracking 4 px (wie heute), Groß-Umwandlung
  bleibt (`textCapitalization: characters`).
- **Senden (Submitting):** Button zeigt `CircularProgressIndicator` (24 px, `onPrimary`) anstelle des Texts,
  Button bleibt in Originalgröße, Feld wird read-only (nicht nur `enabled: false`-Opazität, da sonst der
  Text unlesbar klein wirkt) — entspricht Designsystem 5.1 Loading-Zustand.
- **Fehler (ungültiger Code):** Feldrahmen `warning` 2 px, Fehlertext unter dem Feld in `warning`-Farbe,
  Icon „error“ (`warning`-Farbe) links vom Text, Fokus springt zurück ins Feld, Feldinhalt bleibt stehen
  (nicht gelöscht) — Key `monitor-pairing-error` bleibt.
- **Verbindungsverlust beim Senden:** derselbe Fehlerzustand, Text „Server nicht erreichbar.“ (bestehender
  Text/Verhalten, `MonitorPairingFailure`-Pfad) — keine eigene Extra-UI nötig, da es sich visuell wie jeder
  andere Formularfehler verhält (kein separates Offline-Banner auf diesem Screen: Betreuer steht davor und
  tippt gerade, ein Banner über dem Titel würde nur ablenken).
- **Gesperrt/neu gekoppelt (`revokedHint`):** eigene Zeile zwischen Untertitel und Eingabefeld, Icon „info“
  + Text in `onSurfaceVariant` (neutral, kein Status-Ton) — Key `monitor-revoked-hint` bleibt, Text bleibt
  „Dieser Monitor wurde gesperrt oder neu gekoppelt.“
- **Viele/lange Fehlermeldungen:** Fehlertext max. 2 Zeilen, zentriert, `monitorBody` 28 px — Texte aus dem
  Code sind kurze Sätze, das reicht immer aus (keine Kürzung nötig).
- **`MonitorUnknown` (Sitzung wird wiederherstellt, `MonitorSessionController.restore()` noch nicht
  abgeschlossen):** eigener Zwischenzustand (`_MonitorConnectingScreen`, kein Teil der Kopplung selbst),
  Text „Verbinde …“ wächst auf `monitorHeadline` 40 px (Key `monitor-connecting` bleibt), zentriert, mit
  derselben Icon-Marke darüber für Konsistenz.
- **`MonitorOffline` (Netzwerkfehler beim Restore/Reconnect, gespeichertes Pairing-Token bleibt erhalten):**
  **Review-Runde 1 — Entscheidung:** zeigt denselben Screen/Text wie `MonitorUnknown` (identischer
  `_MonitorConnectingScreen`, derselbe Key `monitor-connecting`). Begründung: Beide Zustände verlangen von
  einem unbeaufsichtigten Gerät exakt dieselbe Handlung — nichts tun, automatisch weiter versuchen — ein
  unterschiedlicher Text („Verbindung verloren“ vs. „Verbinde …“) würde einem zufällig vorbeigehenden
  Betreuer eine Fehlersituation suggerieren, die keine Handlung von ihm erfordert und sich selbst behebt,
  sobald das Netz zurückkommt (anders als bei Standby/Einsatz/Alarm, wo die einheitliche
  Verbindungsbanner-Komponente aus Abschnitt 5/7 der anderen Dokumente läuft, *während* bereits Inhalte
  sichtbar sind — hier gibt es noch keinen Inhalt, den ein Banner ergänzen könnte, der ganze Screen *ist*
  der Wartezustand). Das gespeicherte Token bleibt erhalten, kein Rückfall auf `MonitorPairingScreen`
  (ein gültiges Pairing darf durch einen vorübergehenden Netzwerkfehler nicht verloren gehen).

## 5. Interaktionen/Übergänge

- **Aktivierung:** ganze Fläche ist Tap-Ziel, kein `onSubmitted`/Tastatur-Pfad nötig (Fernbedienung „OK“
  zählt als Tap). Nach dem Tap sofortiger, ungedämpfter Wechsel (kein Fade, Designsystem 7: Statuswechsel
  ohne inhaltliche Dringlichkeit dürfen schnell/ohne Animation sein) zu Kopplung oder Standby, je nach
  `MonitorSessionState`.
- Vollständig tastatur-/fernbedienungsbedienbar: Autofocus im Feld, Enter/OK sendet (`onSubmitted`, bleibt),
  Tab/Pfeiltasten wechseln zum Button.
- Erfolgreiche Kopplung: kein Zwischenbildschirm/Bestätigungstoast — direkter, 200 ms Fade-in-Übergang
  (Designsystem 7) zur Standby-Ansicht, die danach den Gerätenamen oben rechts zeigt (`monitor-name`).
- Kein Abbrechen/Zurück nötig (es gibt nichts, wohin man zurückkehren würde) — bleibt unverändert.

## 6. Testbare Akzeptanzkriterien

1. `Key('monitor-activation-overlay')` deckt die volle Fläche ab, ist tappbar, und wechselt nach einem Tap
   zu Kopplung/Standby (bestehender Test „unpaired -> pairing screen“ ergänzt um den vorausgehenden Tap);
   `enableWakeLock()`, `requestFullscreen()` und `alarmSoundProvider.unlock()` werden genau einmal pro Tap
   aufgerufen (bestehendes Verhalten, nur jetzt dokumentiert/getestet).
2. Vor dem ersten Tap ist weder das Kopplungsfeld noch die Standby-Ansicht im Widget-Baum vorhanden (Fake-
   Verify, dass `_activated == false` den gesamten übrigen Baum ersetzt, nicht nur überlagert).
3. `MonitorOffline` und `MonitorUnknown` rendern beide `Key('monitor-connecting')` mit identischem Text
   „Verbinde …“ — Widget-Test mit beiden States prüft denselben Finder/Text für beide.
4. `Key('monitor-pairing-code')` ist ein Textfeld mit Label „Kopplungscode“, Platzhalter `ABCD-EFGH`,
   `autofocus: true`, akzeptiert weiterhin `[A-Za-z0-9\-\s]`.
5. `Key('monitor-pairing-submit')` ist bei leerem Feld und während des Sendens deaktiviert; zeigt während
   des Sendens einen `CircularProgressIndicator` statt des Texts „Koppeln“, bleibt in derselben Größe.
6. Bei einem Fehler zeigt `Key('monitor-pairing-error')` den Fehlertext in `BftagAlarmColors`-unabhängiger,
   `warning`-Farbe (Kontraststprüfung: nicht `alarm`/`onAlarm`-Token) — Snapshot-/Pixelvergleich oder
   Farbwert-Assertion im Widget-Test.
7. Kein Widget auf diesem Screen verwendet `Colors.red*`/`Colors.orange*` direkt — nur Theme-Tokens
   (`ColorScheme`, `BftagAlarmColors`, `BftagStatusColors`). Grep-Test: keine `Colors.red`/`Colors.orange`
   in `monitor_pairing_screen.dart` nach Umsetzung.
8. `Key('monitor-revoked-hint')` erscheint nur, wenn `revokedHint == true`, Text unverändert
   „Dieser Monitor wurde gesperrt oder neu gekoppelt.“, Farbe `onSurfaceVariant` statt `orangeAccent`.
9. Größter Text auf dem Screen (`monitorDisplay`, Codefeld) ≥ 64 px, kleinster Fließtext (Fußzeile) ≥ 22 px
   (Designsystem 3.2 Mindestgröße 22 px) — Layout-Test oder manuelle Prüfung am gerenderten Mockup.
10. Bei erfolgreicher Kopplung navigiert der Screen weiterhin zu `MonitorStandbyScreen` (bestehendes
    Verhalten aus `monitor_screen_test.dart`: „unpaired -> pairing screen; entering a code pairs ... and
    shows standby“ bleibt grün, ggf. mit angepassten Finder-Strings für neue Labels).

## 7. Zu erhaltende Keys + Semantics

Aus `apps/web/lib/screens/monitor_pairing_screen.dart` und `monitor_screen.dart` (grep-geprüft, keine
`Semantics(...)` auf diesen Screens vorhanden — reine Text-/Eingabe-Keys):

- `Key('monitor-activation-overlay')` (in `monitor_screen.dart`, `_ActivationOverlay` — neu in diesem
  Dokument aufgenommen, Review-Runde 1 Punkt 1)
- `Key('monitor-revoked-hint')`
- `Key('monitor-pairing-code')`
- `Key('monitor-pairing-error')`
- `Key('monitor-pairing-submit')`
- `Key('monitor-connecting')` (in `monitor_screen.dart`, `_MonitorConnectingScreen` — deckt sowohl
  `MonitorUnknown` als auch `MonitorOffline` ab, siehe Abschnitt 4)

Neu empfohlen (nicht zwingend, erleichtert Tests für das neue Label/den Fehler-Icon-Zustand):
`Key('monitor-pairing-code-label')` für das stehende Feld-Label, falls der Coder es als eigenes Text-Widget
umsetzt statt als `InputDecoration.labelText` (dann reicht der bestehende Key am Feld selbst).

## 8. Funktionsabgleich vs. `docs/testing/regression-inventory.md`

| Funktion (Inventar) | Bleibt erhalten als |
|---|---|
| anzeigen (Code-Eingabe-UI) | Abschnitt 3.2, Zustand „Leer“ — gleiches Feld, gleicher Key, zusätzlich Label |
| Navigation (Erfolg → Standby) | Abschnitt 5 — unverändertes Verhalten, nur neuer Übergangs-Fade |
| Fehlerzustand (ungültiger Code) | Abschnitt 4 „Fehler“ — Text/Key unverändert, nur Farbe `warning` statt Rot |
| Offline/Verbindungsverlust | Abschnitt 4 „`MonitorOffline`“ + „Verbindungsverlust beim Senden“ — Text/Keys unverändert |
| Aktivierung (WakeLock/Vollbild/Audiofreigabe) | Abschnitt 3.1/4/6 — bisher nicht dokumentiert, Verhalten unverändert, nur jetzt mit Begründungstext und ACs versehen |
| anlegen/bearbeiten/löschen/Echtzeit-Updates | n/a (gilt hier wie im Inventar, keine Änderung) |

Keine Funktion entfällt. Abweichungen vom bisherigen Verhalten: Farben folgen jetzt den Tokens (kein
Rot/Orange mehr außerhalb von Alarm/FMS), das Feld bekommt ein stehendes Label statt reinem Platzhalter,
das Aktivierungs-Overlay bekommt eine erklärende zweite Zeile — alle drei ausdrücklich als
Usability-Verbesserung begründet (Abschnitt 2, Punkte 3–6, 8).
