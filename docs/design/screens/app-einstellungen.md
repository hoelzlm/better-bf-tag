# App – Einstellungen (`screens/settings_screen.dart`)

Status: Entwurf (ux-02e) · baut auf `docs/design/design-system.md`

## 1. Zweck

Erreichbar über das Zahnrad-Icon auf Mein Fahrzeug/Einsätze: Einrichtung erneut öffnen, Testalarm auslösen,
Gerät abmelden (mit Bestätigungsdialog). Kein Tab in der Navigationsleiste (bewusst, siehe `app-navigation.md`).

## 2. Usability-Probleme heute

1. `docs/design/screenshots/before/app/einstellungen-390x844.png`: „Gerät abmelden" ist ein voller,
   dunkelroter `FilledButton` über die ganze Breite — visuell fast identisch zur generellen Akzentfarbe des
   restlichen Screens (auch die anderen Buttons sind bräunlich-rot), keine klare Signalwirkung "Achtung,
   das ist eine folgenreiche/abmeldende Handlung", UND keine Unterscheidung zur künftigen `alarm`-Farbe —
   nach der Neufarbung muss klar werden: „Gerät abmelden" ist eine destruktive aber keine Alarm-Handlung,
   bekommt nach Designsystem 5.1 trotzdem den `alarm`-Button-Stil (Grundprinzip 1: Rot = Alarm UND
   destruktive Aktionen), nicht die neutrale Primärfarbe.
2. Drei Buttons unterschiedlicher Wichtigkeit („Einrichtung erneut öffnen" sekundär, Testalarm-Buttons
   primär/sekundär, „Gerät abmelden" destruktiv) sehen im Screenshot alle ähnlich „gefüllt bräunlich" aus —
   keine erkennbare Hierarchie zwischen "informativ", "aktiv nützlich" und "folgenreich".

## 3. Neues Layout

Kein eigenes HTML-Mockup Pflicht. ASCII-Wireframe (390×844):

```
┌──────────────────────────────────────────┐
│  Einstellungen                            │  AppBar
├──────────────────────────────────────────┤
│  [ Einrichtung erneut öffnen ]            │  OutlinedButton (sekundär)
│                                            │
│  Testalarm                                 │  titleMedium
│  Löst einen echten Push mit Alarmton nur   │  bodyMedium
│  an dieses Gerät aus, ohne Einsatz.        │
│  [ Testalarm jetzt ]                       │  FilledButton (primary, informativ-
│  [ Testalarm in 10 Sekunden ]              │  nützliche Aktion — kein echter Alarm,
│                                            │  bleibt primary, NICHT alarm-rot)
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │          Gerät abmelden               │ │  FilledButton mit alarm-Token
│  └──────────────────────────────────────┘ │  (destruktive Aktion, Designsystem 5.1)
└──────────────────────────────────────────┘
```

360×640: Alle Elemente passen ohne Scrollen (kurzer Screen, kein primärer Scroll-Fall).

## 4. Alle Zustände

- **Logout-Bestätigungsdialog:** `AlertDialog` mit „Abbrechen" (`TextButton`) und „Abmelden" (`FilledButton`,
  `alarm`-Token) — Titel/Beschreibungstext bleiben neutral/schwarz-weiß (Designsystem 5.6: nur der
  bestätigende Button ist alarmfarben, nicht der ganze Dialog).
- **Testalarm-Zustände:** identisch zu `app-onboarding.md` Abschnitt 4 (gleiches `TestAlarmPanel`-Widget,
  wiederverwendet).
- **Hell/Dunkel:** Button-/Dialog-Token nach Tabelle 2.1.
- **Offline:** kein eigenes Banner; ein fehlgeschlagener Logout-Request ist im aktuellen Code nicht
  gesondert behandelt (kein try/catch um `logout()`) — unverändert, kein neuer Fehlerzustand eingeführt.

## 5. Interaktionen

- „Einrichtung erneut öffnen" navigiert zu `/onboarding` (push, zurück möglich — anders als der initiale
  Onboarding-Aufruf nach Kopplung).
- „Gerät abmelden" öffnet Bestätigungsdialog; nur bei „Abmelden" wird tatsächlich ausgeloggt + Onboarding-
  Flag zurückgesetzt (unverändert).

## 6. Testbare Akzeptanzkriterien

1. „Gerät abmelden" nutzt den `alarm`-Button-Stil (Designsystem 5.1), nicht `primary`.
2. Der Bestätigungsdialog zeigt Titel/Text neutral, nur der „Abmelden"-Button ist `alarm`-farben.
3. „Einrichtung erneut öffnen" nutzt den sekundären (`OutlinedButton`)-Stil.
4. Testalarm-Buttons nutzen `primary` (keine Alarm-Farbe — ein Testalarm-Request ist keine echte Alarmierung).
5. „Abbrechen" im Dialog schließt ohne jede Aktion (`logout()` wird nicht aufgerufen).
6. Kontrast aller Button-Beschriftungen erreicht WCAG AA in hell und dunkel.

## 7. Zu erhaltende Keys + Semantics labels

Aus `screens/settings_screen.dart` (keine `Semantics`/`tooltip` im Quellcode; `TestAlarmPanel`-Keys siehe
`app-onboarding.md` Abschnitt 7):

- `Key('logout-cancel')` — „Abbrechen"-Button im Dialog.
- `Key('logout-confirm')` — „Abmelden"-Button im Dialog.
- `Key('reopen-onboarding')` — „Einrichtung erneut öffnen"-Button.
- `Key('logout-button')` — „Gerät abmelden"-Button (öffnet den Dialog).

## 8. Function-Mapping vs. regression-inventory.md

| Alte Funktion | Neuer Ort | Noch vorhanden? |
|---|---|---|
| Einstellungen: anzeigen/bearbeiten — `device_settings_test.dart` | Gleiche drei Aktionen/Keys, neue Button-Hierarchie (sekundär/primär/alarm) | Ja |

Keine Funktion entfällt.
