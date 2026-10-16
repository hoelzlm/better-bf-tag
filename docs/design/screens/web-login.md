# Admin-Web — Login

Quelle: `apps/web/lib/screens/login_screen.dart`. Vorher: `docs/design/screenshots/before/web/login-1440x900.png`.

## 1. Zweck

Erster Kontakt eines Betreuers mit Admin-Web (Benutzername + Passwort, vergeben über `Personen` →
„Web-Zugang“). Oft einmalig pro Gerät/Sitzung und unter Zeitdruck kurz vor oder während eines BF-Tags. Kein
Navigationsziel dahinter außer „rein“ — die Seite hat bewusst keine Sidebar.

## 2. Usability-Probleme heute

1. **Kein Bezug zur Marke/App.** `login-1440x900.png`: zwei Textfelder und ein Button schweben ohne Rahmen,
   Logo oder Titel im Fensterzentrum — auf den ersten Blick nicht erkennbar, welche Anwendung das ist (relevant
   für Jugendliche/Betreuer, die das Admin-Web selten öffnen).
2. **Riesige ungenutzte Fläche.** Von 1440×900 px nutzt der Inhalt nur einen ca. 310×160 px großen Bereich
   mittig — auf einem Leitstellen-Laptop/Monitor wirkt das leer und unfertig, nicht wie eine fertige
   Einsatzsoftware.
3. **Rotes Theme als einzige Farbakzentuierung** (`login-1440x900.png`: Button in Rosé/Rot-Braun) — kollidiert
   mit Grundprinzip 1 des Designsystems (Rot = Alarm); hier ist nichts alarmbezogen.
4. **Fehlertext ohne Icon/Kontext**, reiner roter Text unter dem Button (`login_screen.dart:94-98`) — bei
   falschem Login nicht sofort als Fehler erkennbar, eher wie ein Hinweistext.
5. **Keine sichtbare Fokusführung** dokumentiert/geprüft — Standard-Flutter-Fokusring ist auf hellem Grund
   schwer sichtbar (Designsystem fordert 2 px `primary`-Ring, Abschnitt 8).

## 3. Neues Layout

Kein Chrome-Element der Sidebar (Login ist vor der Session, s. `web-navigation.md` Abschnitt 4). Zentrierte
Card auf `surface`-Hintergrund, damit die Fläche nicht leer wirkt, aber auch nicht überladen:

```
┌──────────────────────────── 1440×900 ─────────────────────────────┐
│                                                                     │
│                                                                     │
│                         ┌───────────────────┐                     │
│                         │        🛡          │  App-Icon (64px)   │
│                         │      BF-Tag        │  titleLarge        │
│                         │                     │                     │
│                         │  Benutzername       │  TextFormField      │
│                         │  [______________]   │                     │
│                         │                     │                     │
│                         │  Passwort           │  TextFormField      │
│                         │  [______________]   │  (obscured)         │
│                         │                     │                     │
│                         │  (Fehlertext hier)  │  warning, mit Icon  │
│                         │                     │                     │
│                         │  [   Anmelden   ]   │  FilledButton, full │
│                         │                     │  width der Card     │
│                         └───────────────────┘                     │
│                                                                     │
└─────────────────────────────────────────────────────────────────┘
```

Card: `surfaceVariant`-Fläche, `radiusLarge` (16), `elevation 1` (Web-Theme, design-system 4.3), Breite 360 px,
Innenabstand `xxl` (32). App-Icon oben zentriert (`docs/design/icon/app-icon.svg`, 64×64, `primary`-Grund,
abgerundetes Quadrat), darunter `titleLarge` „BF-Tag“. Textfelder volle Card-Breite, `BftagSpacing.lg` (16)
Abstand untereinander. Button volle Card-Breite, `FilledButton` (design-system 5.1).

## 4. Alle Zustände

- **Initial/Leer:** beide Felder leer, kein Fehlertext (Platz dafür ist reserviert, kein Sprung beim
  Erscheinen eines Fehlers — wie heute schon durch immer gerenderten `Text(_errorText ?? '')`).
- **Eingabe:** Standard-`TextFormField`-Fokuszustand (2 px `primary`-Rahmen, design-system 5.2).
- **Absenden/Laden:** Button zeigt 16 px `CircularProgressIndicator` (`onPrimary`) anstelle des Texts, Button
  bleibt in Originalgröße, nicht klickbar (`login_screen.dart:84-91`, unverändert); Felder bleiben editierbar
  (kein Doppel-Submit durch `_isSubmitting`-Guard in `_submit()`, Zeile 27-29, unverändert).
- **Fehler (ungültiger Login):** Fehlertext mit `warning`-Icon (`error_outline` oder `warning`, 16 px) +
  `warning`-Farbe (nicht `alarm`-Rot — ein falsches Passwort ist kein Alarm, Grundprinzip 1), Text aus
  `LoginFailure.message` unverändert (`login_screen.dart:39-45`).
- **Offline/Server nicht erreichbar:** gleicher Fehlertext-Slot, Nachricht kommt weiterhin aus der
  `LoginFailure`, kein separater UI-Zustand nötig (kein neues Verhalten, nur visuelle Behandlung wie „Fehler“).
- **Lange Fehlermeldungen:** Fehlertext bricht in der Card um (max. 2 Zeilen vorgesehen, `softWrap: true`),
  Card wächst nach unten, bleibt vertikal zentriert.

## 5. Interaktionen

- Tab-Reihenfolge: Benutzername → Passwort → Anmelden-Button, danach (falls Fehlertext erscheint) kein
  Fokus-Trap.
- Enter in beiden Feldern löst `_submit()` aus (`login_screen.dart:70,78`, unverändert).
- Sichtbarer Fokusring (2 px `primary`) auf allen drei interaktiven Elementen.
- Passwortfeld bleibt `obscureText: true`, kein „anzeigen“-Toggle (kein bestehendes Feature, nicht neu
  eingeführt).

## 6. Testbare Akzeptanzkriterien

1. `login-username`, `login-password`, `login-submit`, `login-error` sind weiterhin über ihre `Key`s auffindbar
   und funktional identisch (Eingabe, Submit-Button, Fehlertext-Widget).
2. Ein ungültiger Login zeigt den Text aus `LoginFailure.message` im `login-error`-Widget, identisch zu heute.
3. Während `_isSubmitting == true` ist `login-submit` nicht klickbar (`onPressed: null`) und zeigt den
   Lade-Indikator statt „Anmelden“.
4. Ein gültiger Login navigiert weiterhin zu `/admin` (unverändert, via `router.dart`-Redirect).
5. Die Login-Seite rendert keine Sidebar/Navigation (keiner der `nav-*`-Keys aus `web-navigation.md` ist auf
   dieser Route vorhanden).
6. Enter-Taste in `login-username` oder `login-password` löst denselben Submit aus wie Klick auf
   `login-submit`.

## 7. Zu erhaltende Keys + Semantics labels

Aus `login_screen.dart` (`grep -n "Key("`): `login-username`, `login-password`, `login-submit`,
`login-error`. Keine `Semantics(...)`/`semanticsLabel` im aktuellen Code; `InputDecoration.labelText`
(„Benutzername“, „Passwort“) dient Screenreadern bereits als zugängliches Label über `TextFormField` und
bleibt unverändert.

## 8. Flows

Keine Flow-Änderung. Gleiche Felder, gleicher Submit-Pfad, gleiche Fehlerbehandlung — nur visuell neu gerahmt
(Card statt frei schwebender Felder) und mit App-Icon versehen.

## 9. Zuordnung zum Regressionsinventar

Tabelle „Login“ (`docs/testing/regression-inventory.md`, Abschnitt „### Login (`login_screen.dart`)“):

| Funktion (Inventar) | Test | Ort im neuen Layout |
|---|---|---|
| anzeigen | n/a | n/a |
| anlegen/bearbeiten/löschen | n/a | n/a |
| Navigation | `login_test.dart`: valid/invalid login, logout | Gleicher Submit-Pfad/Redirect zu `/admin` (Abschnitt 6 AK 4), Logout bleibt in der Sidebar (`web-navigation.md`). |
| Echtzeit-Updates | n/a | n/a |
| Fehlerzustand | `login_test.dart`: invalid login shows the error text | `login-error` mit `warning`-Icon statt reinem Text (Abschnitt 3/4). |
| Leerzustand/Offline | n/a | Offline-Fall nutzt weiterhin denselben `login-error`-Slot (Abschnitt 4 „Offline/Server nicht erreichbar“), kein separates Banner nötig, da die Login-Seite keine `AdminShell` lädt (vor der Session, s. `web-navigation.md` Abschnitt 4). |
