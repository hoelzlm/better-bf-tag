# App – Onboarding (`onboarding/onboarding_screen.dart`)

Status: Entwurf (ux-02e) · baut auf `docs/design/design-system.md`

## 1. Zweck

Führt eine Person direkt nach der Kopplung (oder erneut über Einstellungen → „Einrichtung erneut öffnen")
Schritt für Schritt durch die Systemeinstellungen, von denen ein zuverlässiger Alarm abhängt
(Benachrichtigungen, Nicht-stören-Umgehung, Akku-Optimierung bzw. Stummschalter auf iOS), und lässt am Ende
einen echten Testalarm auslösen. Primäre Aufgabe: jeden Schritt sehen, den nötigen Systemdialog öffnen, den
erreichten Zustand bestätigt sehen, weiter.

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/onboarding-390x844.png`: riesige leere Fläche unter dem Inhalt — kein
   Fortschrittsanzeiger, nirgends sichtbar, wie viele Schritte insgesamt kommen oder welcher gerade läuft.
2. Der Status-Haken (✓/✗ als reiner Unicode-Text, `_StatusStep`) ist winzig, grau auf cremefarbenem
   Hintergrund kaum lesbar; das zusätzliche Icon (`check_circle`/`cancel`) nutzt Standard-Grün/Rot — Rot für
   einen bloß "noch nicht erledigt"-Zustand kollidiert mit der Grundregel "Rot = Alarm" (Designsystem
   Grundprinzip 1), ein unerledigter Einrichtungsschritt ist kein Alarm.
3. Reiner Fließtext ohne visuelle Gruppierung (Titel, Status, Beschreibung, Hersteller-Hinweis, Aktionen,
   „Weiter"-Button sehen alle gleich aus) — auf einen Blick ist nicht erkennbar, was die eine wichtige
   Handlung dieses Schritts ist.
4. Die rötliche Markendekoration oben rechts (Flutter-Demo-Eckband aus `ColorScheme.fromSeed(Colors.red)`)
   lenkt ab und suggeriert optisch "Achtung", obwohl Onboarding ein ruhiger Schritt ist.
5. Keine erkennbare Möglichkeit, vor-/zurückzuspringen oder den Fortschritt zu überspringen — wirkt wie eine
   Sackgasse, falls eine Berechtigung aus gutem Grund abgelehnt wird (z. B. Gerät eines Erziehungsberechtigten).

## 3. Neues Layout

Kartenbasiertes Layout mit festem Fortschrittsbalken oben (5–6 Schritte je nach Plattform), großer,
eindeutiger Status-Pille statt Mini-Unicode-Zeichen, klar getrennte Aktionszone. Mockup:
`docs/design/mockups/app-onboarding.html` → gerendert als `docs/design/mockups/app-onboarding.png` (390×844,
Schritt "Benachrichtigungen erlauben", hell).

ASCII-Wireframe (390×844, ein Schritt exemplarisch):

```
┌──────────────────────────────────────────┐
│  Einrichtung                              │  AppBar, headlineSmall
│  ●──●──○──○──○   Schritt 2 von 5          │  Fortschrittsbalken (primary gefüllt
├──────────────────────────────────────────┤  bis aktueller Schritt, outline Rest)
│                                            │
│  Benachrichtigungen erlauben               │  titleLarge
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │ ⚠ Noch nicht eingerichtet            │ │  Status-Chip: warningContainer/warning
│  └──────────────────────────────────────┘ │  solange ok==false, primaryContainer/primary
│                                            │  sobald ok==true ("✓ Eingerichtet")
│  Ohne Benachrichtigungen kann dich die    │  bodyLarge
│  App nicht alarmieren.                     │
│                                            │
│  [ Erlauben ]  [ Einstellungen öffnen ]   │  Primär-/Sekundärbutton, ≥48dp
│                                            │
│                         [ Weiter → ]       │  unten rechts, Primärbutton
└──────────────────────────────────────────┘
```

360×640: Fortschrittsbalken + Titel + Status-Chip + Beschreibung + Aktionen passen ohne Scrollen in die
Kopfhälfte; der „Weiter"-Button bleibt per `SingleChildScrollView` erreichbar (wie heute), auf 360×640 ggf.
mit kurzem Scroll bei langen Hersteller-Hinweistexten — das ist unkritisch, da Onboarding kein Zeitdruck-Screen
ist (anders als Alarm/Mein Fahrzeug).

## 4. Alle Zustände

- **Laden** (`_loaded == false`): zentrierter `CircularProgressIndicator` (`primary`), kein Fortschrittsbalken
  sichtbar bis Status geladen ist (verhindert Flackern von falsch/richtig).
- **Schritt „Benachrichtigungen"**, `ok == false`: warning-Status-Chip „Noch nicht eingerichtet" + Button
  „Erlauben"; nach erstem Versuch (`_notificationsAllowTried == true`) zusätzlich „Einstellungen öffnen".
- **Schritt „Benachrichtigungen"**, `ok == true`: primaryContainer-Status-Chip „Eingerichtet" (grünlich wäre
  denkbar, aber Designsystem kennt keinen separaten Erfolg-Grün-Token für die App — `primary` steht hier für
  "erledigt", konsistent mit anderen "aktiv/erledigt"-Zuständen im System; kein neuer Token nötig).
- **Schritt „Nicht stören umgehen"**: plattformabhängiger Text (iOS: „Dringliche Mitteilungen"; Android:
  Kanal „Alarm"), ein Button „Einstellungen öffnen", kein eigener "erlauben"-Button (Verhalten unverändert).
- **Schritt „Akku-Optimierung"** (nur Android, `!isIos`): zusätzlich Hersteller-Hinweis-Box
  (`batteryHintFor()` — Samsung/Xiaomi/Huawei/OnePlus/Vivo/Generisch) als eigener, deutlich abgesetzter Kasten
  (surfaceContainer, Icon „info", Linktext „dontkillmyapp.com/…" als Fließtext, nicht klickbar — Verhalten
  unverändert, nur optisch gruppiert statt Fließtext).
- **Schritt „Nicht stumm schalten"** (nur iOS, `isIos`): reiner Hinweistext ohne Statusprüfung (kein API dafür
  verfügbar) — bleibt als ruhiger Hinweis-Block ohne Chip (kein "ok/nicht ok", da nicht prüfbar).
- **Schritt „Testalarm"**: eingebettetes `TestAlarmPanel` (siehe unten) + „Weiter".
- **Schritt „Fertig"**: Abschluss-Bildschirm mit „Fertig"-Button → schließt Onboarding (`context.pop()`/`go('/')`).
- **TestAlarmPanel-Zustände:** Default (zwei Buttons „Testalarm jetzt"/„Testalarm in 10 Sekunden"); busy
  (Buttons disabled während Anfrage läuft, kein Spinner-Text vorgesehen im Code — Button bleibt an Ort und
  Stelle, nur `onPressed: null`); Ergebnis-Text (`_resultText`) in vier Varianten: „Push zugestellt — hast du
  den Alarmton gehört?" (primaryContainer-Hinweiskarte), „wird in 10 Sekunden gesendet" (primaryContainer),
  „nicht eingerichtet"/„kurz warten"/„konnte nicht zugestellt werden" (warningContainer/warning — ein
  Fehlerzustand der Testalarm-Zustellung ist ein technischer Fehler, kein echter Alarm, bleibt also warning,
  nicht alarm-rot); bei `delaySeconds > 0` zusätzlich Hinweis „Sperre jetzt den Bildschirm." (surfaceVariant-
  Kasten mit Icon „lock").
- **Berechtigungen/Push verweigert:** genau der Fall `ok == false` nach einem Erlauben-Versuch — die App kann
  Ablehnung nicht erzwingen rückgängig machen, nur zu den System-Einstellungen verlinken (Button „Einstellungen
  öffnen", erscheint erst nach einem Versuch). Kein Blockieren des weiteren Ablaufs — „Weiter" bleibt immer
  aktiv, die Person darf mit unvollständiger Einrichtung fortfahren (Verhalten unverändert, nur jetzt klarer
  als "du kannst trotzdem weiter, aber der Alarm funktioniert dann evtl. nicht" kommuniziert über die
  warning-Chip-Farbe statt stummes Rot/Grün-Icon).
- **Hell/Dunkel:** alle Flächen/Texte nach Tabelle 2.1; Status-Chips `warningContainer`/`warning` (offen) bzw.
  `primaryContainer`/`primary` (erledigt) in beiden Modi, Kontrast ≥ AA geprüft.
- **Offline:** Onboarding braucht kein Netz außer für den Testalarm-Request; ein fehlgeschlagener
  Testalarm-Request landet im oben beschriebenen Fehlertext, kein eigenes Offline-Banner nötig (kein
  Dauerverbindungs-Request auf diesem Screen).

## 5. Interaktionen

- Jeder Schritt hat genau eine "Weiter"-Handlung (`FilledButton`, unten rechts, ≥48dp) — Reihenfolge linear,
  kein Zurück-Button im Code vorhanden, bleibt unverändert (kein neues Feature).
  Der Fortschrittsbalken ist rein informativ, nicht antippbar (kein Rücksprung-Feature neu einführen).
- „Erlauben"/„Einstellungen öffnen"/„Ausnahme aktivieren" lösen System-Dialoge/-Einstellungen aus
  (`DeviceSettings`-Methodenkanal); bei Rückkehr in den Vordergrund (`AppLifecycleState.resumed`) wird der
  Status automatisch neu geprüft (`_refreshStatuses()`, unverändert).
- Testalarm-Buttons lösen `POST /me/device/test-alarm` aus; Ergebnis erscheint unterhalb als Hinweiskarte.

## 6. Testbare Akzeptanzkriterien

1. Der Fortschrittsbalken zeigt die korrekte Schrittzahl für die Plattform (Android: 5 Schritte
   notifications/dnd/battery/testAlarm/done; iOS: 5 Schritte notifications/dnd/mute/testAlarm/done — `battery`
   nur Android, `mute` nur iOS, siehe `_steps()`).
2. Solange `_loaded == false` ist kein Fortschrittsbalken/Schritt sichtbar, nur ein zentrierter Spinner.
3. Der Status-Chip zeigt `warningContainer`/`warning`-Farbe wenn `ok == false` und `primaryContainer`/`primary`
   wenn `ok == true` — nie `alarm`-Rot.
4. „Einstellungen öffnen" für Benachrichtigungen erscheint erst nachdem „Erlauben" mindestens einmal gedrückt
   wurde (`_notificationsAllowTried`).
5. Der Hersteller-Hinweis-Kasten erscheint nur im Akku-Schritt und nur auf Android, mit dem für den erkannten
   Hersteller passenden Text aus `batteryHintFor()`.
6. Im Testalarm-Schritt sind beide Buttons während einer laufenden Anfrage (`_busy == true`) deaktiviert.
7. Der „Sperre jetzt den Bildschirm."-Hinweis erscheint nur nach „Testalarm in 10 Sekunden", nicht nach
   „Testalarm jetzt".
8. „Fertig" markiert `onboardingCompletedProvider` als abgeschlossen und verlässt den Screen (`pop`/`go('/')`).
9. Alle Text-auf-Fläche-Kombinationen (Status-Chip, Hersteller-Hinweis-Box) erreichen WCAG AA in hell und
   dunkel.

## 7. Zu erhaltende Keys + Semantics labels

Aus `onboarding_screen.dart`, `test_alarm_panel.dart` (keine `Semantics`/`tooltip` im Quellcode vorhanden):

- `Key('onboarding-action-notifications-allow')`, `Key('onboarding-action-notifications-settings')`
- `Key('onboarding-action-dnd-settings')`
- `Key('onboarding-battery-hint')`, `Key('onboarding-action-battery-request')`
- `Key('onboarding-mute-hint')`
- `Key('onboarding-next')` (wiederverwendet auf mehreren Schritten — bleibt so, mehrere Instanzen mit
  gleichem Key existieren nie gleichzeitig im Baum)
- `Key('onboarding-finish')`
- `Key(statusKey)` dynamisch: `'onboarding-status-notifications'`, `'onboarding-status-dnd'`,
  `'onboarding-status-battery'` — der Text, der ✓/✗ trägt, wird im neuen Design zum Chip-Label, Key bleibt
  am selben logischen Text-Widget.
- `Key('test-alarm-now')`, `Key('test-alarm-delayed')`, `Key('test-alarm-lock-hint')`, `Key('test-alarm-result')`

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Onboarding: anzeigen/Navigation — `onboarding_test.dart` | Gleicher Schrittablauf, neue Chip-/Fortschritts-Optik | Ja |
| Onboarding: Fehlerzustand „no_push_token"/„test_alarm_cooldown" — `onboarding_test.dart` | `_resultText`-Hinweiskarte, jetzt in `warningContainer` statt reinem Fließtext, exakt gleicher Text | Ja |

Keine Funktion entfällt; Reihenfolge/Bedingungen der Schritte unverändert.
