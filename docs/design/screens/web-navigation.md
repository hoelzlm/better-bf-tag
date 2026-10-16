# Admin-Web — Navigation / Seitenleiste

Quelle heute: `apps/web/lib/router.dart` (Routing/Redirects) + `apps/web/lib/screens/lage_screen.dart`
(AppBar-`actions` — die Navigation existiert heute **nur als Icon-Leiste auf dem Lage-Screen**, siehe unten).
Baut auf `docs/design/design-system.md` (Abschnitt 5.8 Seitenleiste, 4.4 Breakpoints) und dem gemeinsamen
Lage-Mockup (`docs/design/mockups/lage.html`) auf.

## 1. Zweck

Die Betreuer der Leitstelle (Berechtigung Leitstelle oder Administrator) wechseln während der Vorbereitung und
im laufenden BF-Tag ständig zwischen BF-Tage, Schichten, Personen, Fahrzeuge, Einsätze, Durchsagen,
Tagesablauf, Folien, Monitore und zurück zur Lage. Das passiert unter Zeitdruck (Alarmierung läuft, Schicht
wird kurzfristig umgebaut). Navigation muss von **jedem** Admin-Screen aus sofort sichtbar und erreichbar sein,
nicht nur von der Startseite.

## 2. Usability-Probleme heute

1. **Navigation existiert nur auf dem Lage-Screen.** `lage_screen.dart:38-127` hängt alle Nav-Icons als
   `AppBar.actions` an — jeder andere Screen (`bf_days_screen.dart:238`, `shifts_screen.dart:424`,
   `persons_screen.dart:207` usw.) hat nur `AppBar(title: Text(...))`, **keinen** Weg zu einem anderen
   Admin-Bereich außer dem Browser-Zurück-Button. Wer auf Personen ist und zu Schichten will, muss über die
   Lage. Beleg: `docs/design/screenshots/before/web/bf-tage-1440x900.png`,
   `docs/design/screenshots/before/web/schichten-1440x900.png`,
   `docs/design/screenshots/before/web/personen-1440x900.png` — alle drei zeigen nur einen Titel ohne
   jegliche Navigation.
2. **Icon-only, keine Labels, Overflow-Risiko.** `docs/design/screenshots/before/web/lage-1440x900.png`
   zeigt 9 Icon-Buttons + Name + Logout dicht an dicht rechts in der AppBar, ohne sichtbares Label — ob
   „Fahrzeuge“ oder „Folien“ gemeint ist, erschließt sich nur aus dem Icon oder einem Hover-Tooltip. Der
   Code-Kommentar in `lage_screen.dart:28-29` bestätigt das Problem selbst („the growing number of
   `/admin/*` nav entries keeps fitting the AppBar's trailing area (which doesn't scroll/wrap on overflow)“)
   — die Lösung dort ist `VisualDensity.compact`, kein strukturelles Fix. Jeder weitere Menüpunkt bringt die
   Leiste näher an den Overflow.
3. **Kein aktiver Zustand.** Keines der Icons zeigt an, wo man sich gerade befindet (kein Icon ist auf der
   Lage selbst „aktiv“ markiert, weil die Lage keinen eigenen Nav-Eintrag hat).
4. **Angemeldete Person kaum lesbar.** `Administrator (Administrator)` steht klein, ohne visuelle Trennung,
   zwischen den Icons und dem Logout-Icon (`lage-1440x900.png`, oben rechts).
5. **Berechtigungs-Ausblendung ist unsichtbar als Konzept.** Dass z. B. Mannschaft fast keine Einträge sieht,
   Einsatzvorbereitung nur Einsätze, Leitstelle mehr, nur Administrator alles — ist heute reine
   `if`-Logik ohne erkennbare Gruppierung (kein Abschnitt „Verwaltung“ vs. „Betrieb“).

## 3. Neues Layout

**Flow-Änderung (begründet, siehe Abschnitt 8):** Die Navigation wird aus `LageScreen` herausgelöst und zu
einer permanenten Seitenleiste, die **alle** `/admin/*`-Screens umschließt (neue `AdminShell`-Route-Wrapper in
`router.dart`, ersetzt `_SessionGate` + eigenes `Scaffold.appBar` pro Screen für die Navigationsteile).

Rendertes Mockup (mit Schichten als Inhalt, siehe `web-schichten.md`):
`docs/design/mockups/web-schichten.html` / `.png` (1440×900).

```
┌──────────────┬──────────────────────────────────────────────────────────────┐
│ ■ BF-Tag     │  <Screentitel>                                    [live ●]   │
│              ├──────────────────────────────────────────────────────────────┤
│ ● Lage       │ (Offline-Banner, nur sichtbar bei Verbindungsverlust, s. u.)  │
│   Einsätze   │                                                              │
│   Durchsagen │                     <Screeninhalt>                          │
│   Tagesablauf│                                                              │
│   Schichten  │                                                              │
│   BF-Tage    │                                                              │
│              │                                                              │
│ Verwaltung   │                                                              │
│   Personen   │                                                              │
│   Fahrzeuge  │                                                              │
│   Monitore   │                                                              │
│   Folien     │                                                              │
│              │                                                              │
│ ──────────   │                                                              │
│ Vorname Name │                                                              │
│ Administrator│                                                              │
│ Abmelden  ⎋  │                                                              │
└──────────────┴──────────────────────────────────────────────────────────────┘
  240px (72px kollabiert, 1024–1279px)
```

Full-Breite (≥1280 px): Sidebar `surfaceVariant`, 240 px fest, `BftagSpacing.lg` (16) Innenabstand an den
Rändern, Nav-Items `radiusMedium`, 44 px hoch, Icon (24 dp) + Label (`labelLarge`). Aktiver Eintrag:
`primaryContainer`-Fläche, `primary`-Text, linker 3 px `primary`-Indikator (design-system 5.8).

Tablet (1024–1279 px): Sidebar kollabiert automatisch auf 72 px, nur Icons zentriert, Label verschwindet,
Tooltip bei Hover/Fokus zeigt das Label (identischer Text wie das `tooltip`/`semanticLabel` im Code). Ein
Toggle-Icon (`menu`/`menu_open`) oben in der Sidebar erlaubt manuelles Auf-/Zuklappen auch bei ≥1280 px, Zustand
nicht persistiert (pro Sitzung reicht, kein neues Feature nötig). Unter 1024 px: kein eigenes Layout nötig
(laut Spec kein Phone-Ziel für Admin-Web); Sidebar bleibt kollabiert, Inhalt darf horizontal scrollen.

Reihenfolge und Sichtbarkeit der Einträge (Sichtbarkeits-Logik identisch zur heutigen `if`-Kette, nur visuell
gruppiert und neu sortiert — **Entscheidung Architekt-Review Runde 1**: Betriebsablauf zuerst in der
Reihenfolge, in der die Screens während eines BF-Tags typischerweise gebraucht werden, dann eine eigene
„Verwaltung“-Gruppe für die seltener benötigten Stammdaten-Screens):

| Eintrag | Icon | sichtbar ab Berechtigung | bisheriger Key |
|---|---|---|---|
| Lage | `home` | immer (alle) | *(neu, s. Abschnitt 7)* |
| Einsätze | `local_fire_department` | Einsatzvorbereitung, Leitstelle, Administrator | `nav-einsaetze` |
| Durchsagen | `campaign` | Leitstelle, Administrator | `nav-durchsagen` |
| Tagesablauf | `event_note` *(war `calendar_today`)* | Leitstelle, Administrator | `nav-tagesablauf` |
| Schichten | `schedule` | Leitstelle, Administrator | `nav-schichten` |
| BF-Tage | `calendar_month` *(war `event`)* | Leitstelle, Administrator | `nav-bf-tage` |
| — Abschnittsüberschrift „Verwaltung“ (`labelMedium`, `onSurfaceVariant`) — nur sichtbar, wenn mindestens ein Eintrag darunter sichtbar ist (für `Permission.admin`; für alle anderen Berechtigungen ganz ausgeblendet, da kein Eintrag darunter sichtbar wäre) — | | | |
| Personen | `group` *(war `people`)* | Administrator | `nav-persons` |
| Fahrzeuge | `local_shipping` *(war `fire_truck`)* | Administrator | `nav-fahrzeuge` |
| Monitore | `desktop_windows` *(war `tv`)* | Administrator | `nav-monitors` |
| Folien | `image` *(war `slideshow`)* | Administrator | `nav-slides` |

Sechs Icons ändern sich gegenüber dem heutigen Code (bewusste Änderung, nicht Teil der Sichtbarkeits-/
Reihenfolgenlogik): `event`→`calendar_month` (BF-Tage), `calendar_today`→`event_note` (Tagesablauf),
`fire_truck`→`local_shipping` (Fahrzeuge), `people`→`group` (Personen), `tv`→`desktop_windows` (Monitore),
`slideshow`→`image` (Folien). Grund: in der neuen Sidebar stehen BF-Tage/Tagesablauf (beide mit
Kalenderbezug) und Fahrzeuge (vorher mit `fire_truck`, das auf dem Monitor/in der App bereits für „eigenes
Fahrzeug“ reserviert ist, design-system 8) nebeneinander — die neuen Icons unterscheiden sie klarer und
vermeiden Doppel-Icon-Verwendung. **Testsicherheit geprüft:** `apps/web/test` enthält `find.byIcon` nur in
`shifts_screen_test.dart` (prüft `Icons.warning`, Schichten-Doppelbelegung, unberührt von dieser Karte) und
`running_incidents_section_test.dart` (prüft `Icons.check_circle`/`Icons.more_horiz`/
`Icons.remove_circle_outline`, Quittierungsstatus auf der Lage, ebenfalls unberührt) — keiner der sechs
getauschten Nav-Icons wird von einem Test referenziert, der Austausch bricht also keinen bestehenden Test.

Footer der Sidebar (immer sichtbar, auch kollabiert): angemeldete Person — `titleMedium` Name,
`bodyMedium`/`onSurfaceVariant` Berechtigungslabel darunter, darunter „Abmelden“ als Textzeile mit Icon
(`logout`). Kollabiert: nur Avatar-Initialen-Kreis + Logout-Icon, Tooltip zeigt Name + Berechtigung.

## 4. Alle Zustände

- **Laden (Session unbekannt):** identisch zu heute — `_SessionGate` zeigt zentrierten
  `CircularProgressIndicator` auf leerem `Scaffold`, keine Sidebar (verhindert Flackern vor Rückfrage, ob
  angemeldet). Unverändert aus `router.dart:40-47`.
- **Abgemeldet:** kein Sidebar-Rendering, nur `LoginScreen` ohne Chrome (Login hat keine Navigation, siehe
  `web-login.md`).
- **Angemeldet, wenig Berechtigung (Mannschaft):** Sidebar zeigt nur „Lage“ (keine weiteren Einträge sichtbar
  — wie heute 0 Icons für `Permission.crew`), Fußzeile mit Person + Abmelden bleibt immer da. Die
  „Verwaltung“-Überschrift ist ebenfalls ausgeblendet (kein sichtbarer Eintrag darunter).
- **Angemeldet, Berechtigung Leitstelle/Einsatzvorbereitung:** „Verwaltung“-Überschrift und alle vier
  Einträge darunter (Personen/Fahrzeuge/Monitore/Folien) sind ausgeblendet, da keiner davon für diese
  Berechtigungen sichtbar ist (identisch zur heutigen `if (permission == Permission.admin)`-Kette).
- **Aktiver Screen:** Eintrag hervorgehoben (s. o.); bei Routen ohne eigenen Sidebar-Eintrag (es gibt keine in
  diesem Kartenumfang) wäre kein Eintrag aktiv — kommt hier nicht vor.
- **Kollabiert (Tablet-Breite 1024–1279 px):** s. Abschnitt 3; Zustand wechselt live beim Resize
  (`LayoutBuilder`/`MediaQuery`, keine Sprung-Reloads). Die „Verwaltung“-Überschrift verschwindet im
  kollabierten Zustand wie jedes Label (nur Icons sichtbar), bleibt aber als zusätzlicher optischer
  Abstand (Spacer) zwischen den beiden Icon-Gruppen erhalten.
- **Fokus/Tastatur:** jedes Nav-Item fokussierbar (Tab-Reihenfolge von oben nach unten, dann Fußzeile),
  sichtbarer 2 px `primary`-Fokusring (design-system 8). Die „Verwaltung“-Überschrift selbst ist kein
  fokussierbares Element (reiner Text/Trenner, kein `Key` nötig).
- **Viele Einträge / lange Namen in der Fußzeile:** Personenname mit `TextOverflow.ellipsis` nach einer Zeile,
  voller Name im Tooltip.
- **Offline/Verbindung verloren (gemeinsames Banner für alle `/admin/*`-Screens):** Die `AdminShell`
  rendert — oberhalb des jeweiligen Screen-Inhalts, unterhalb des Screentitels, über die volle Breite der
  Content-Spalte (nicht über die Sidebar) — ein Banner, sobald `realtimeConnectionProvider`
  (`packages/core/lib/src/realtime/providers.dart:267`, derselbe `StreamProvider<ConnectionStatus>` aus
  `packages/core/lib/src/realtime/realtime_client.dart:23`, den `VehicleStatusBar` heute schon für ihren
  eigenen kleinen Verbindungstext `connection-indicator` beobachtet) einen Wert ungleich
  `ConnectionStatus.live` liefert — also bei `connecting`, `reconnecting` und `revoked` gleichermaßen,
  identisch zu der Bedingung, die `VehicleStatusBar` bereits heute für „verbinde neu…“ verwendet. Kein neuer
  Verbindungsmechanismus, nur eine zusätzliche, immer vorhandene Anzeige auf Shell-Ebene statt (wie heute)
  nur innerhalb der Lage. Darstellung nach design-system 5.10: `surfaceVariant`-Fläche volle Breite, Icon
  `cloud_off`, Text „Verbindung verloren — verbinde erneut …“, kein Rot. Banner verschwindet automatisch,
  sobald der Provider wieder `live` liefert. Während das Banner sichtbar ist, bleiben alle Screens bedienbar;
  Aktionen, die währenddessen fehlschlagen, zeigen weiterhin ihre bestehende Fehlerbehandlung (SnackBar bzw.
  Ladefehler je Screen, unverändert — s. jeweilige Screen-Konzepte). Neuer Test-Hook (kein bestehender Test
  referenziert ihn): `Key('connection-banner')` auf dem Banner-Container.

## 5. Interaktionen

- Klick/Tap auf Eintrag → `context.go('/admin/...')`, identische Zielpfade wie heute.
- Tastatur: Tab durchläuft Einträge in Listreihenfolge, Enter/Space aktiviert, Escape hat keine Funktion hier
  (keine Overlay). Pfeiltasten optional (nicht erforderlich, Standard-Tab-Fokus reicht für WCAG 2.1.1).
  Sichtbarer Fokusring auch im kollabierten Zustand.
  Browser-Zurück/Vorwärts funktioniert weiterhin über go_router-Historie, unabhängig von der Sidebar.
- Sidebar-Collapse-Toggle: Klick wechselt zwischen 240 px/72 px, 300 ms `Curves.easeInOutCubic`
  (design-system 7), kein Layout-Sprung im Content (nur Breite der Sidebar ändert sich, Content füllt Rest).
- Abmelden: Klick löst denselben `sessionControllerProvider.notifier.logout()`-Aufruf wie heute aus
  (`lage_screen.dart:124`), danach Redirect zu `/admin/login` via bestehende `redirect`-Logik in `router.dart`.

## 6. Testbare Akzeptanzkriterien

Zählung (eindeutig, um Runde-1-Punkt 5 nicht erneut mehrdeutig zu lassen): Es gibt **neun bestehende**
`nav-*`-Keys aus dem heutigen Code (`nav-einsaetze`, `nav-schichten`, `nav-durchsagen`, `nav-tagesablauf`,
`nav-bf-tage`, `nav-fahrzeuge`, `nav-persons`, `nav-monitors`, `nav-slides`) **plus** den einen neuen
`nav-lage` aus Abschnitt 7 — **zehn `nav-*`-Keys insgesamt**. Jede Zahl unten bezieht sich ausdrücklich auf
eine der beiden Mengen.

1. Jeder `/admin/*`-Screen (Lage, BF-Tage, Schichten, Personen, Fahrzeuge, Einsätze, Durchsagen, Tagesablauf,
   Folien, Monitore) rendert dieselbe Sidebar-Instanz mit denselben sichtbaren Einträgen für dieselbe
   Berechtigung — nicht nur Lage.
2. Für `Permission.crew` ist in der Sidebar nur `nav-lage` sichtbar (plus Fußzeile); keiner der neun
   bestehenden `nav-*`-Keys ist vorhanden, und die „Verwaltung“-Überschrift ist nicht vorhanden.
3. Für `Permission.preparation` ist zusätzlich `nav-einsaetze` sichtbar, die übrigen acht bestehenden
   `nav-*`-Keys nicht; „Verwaltung“-Überschrift weiterhin nicht vorhanden.
4. Für `Permission.dispatch` sind `nav-einsaetze`, `nav-durchsagen`, `nav-tagesablauf`, `nav-schichten`,
   `nav-bf-tage` sichtbar, `nav-fahrzeuge`/`nav-persons`/`nav-monitors`/`nav-slides` nicht; „Verwaltung“-
   Überschrift nicht vorhanden (kein Eintrag darunter sichtbar).
5. Für `Permission.admin` sind alle zehn `nav-*`-Keys (neun bestehende + `nav-lage`) sichtbar, inklusive der
   „Verwaltung“-Überschrift über Personen/Fahrzeuge/Monitore/Folien.
6. Klick auf jeden sichtbaren Nav-Eintrag navigiert zur erwarteten Route (`/admin/...`), identisch zu den
   bestehenden 19 `router_test.dart`-Fällen.
7. Der aktive Eintrag (entsprechend der aktuellen Route) hat `primaryContainer`-Hintergrund und den 3 px
   Indikator; genau ein Eintrag ist je Route aktiv.
8. Bei Fensterbreite zwischen 1024 und 1279 px zeigt die Sidebar nur Icons (Breite 72 px); ab 1280 px Icons +
   Label (Breite 240 px). Der Layout-Wechsel verändert nicht die sichtbaren `nav-*`-Keys, nur ihre Darstellung.
9. `logout`-Key löst `logout()` aus und führt zu `/admin/login`, identisch zum bisherigen Verhalten.
10. Der Name der angemeldeten Person und ihr Berechtigungslabel sind in der Fußzeile sichtbar (Text enthält
    `displayName` und `permission.label`), wie bisher im AppBar-Text.
11. Jedes Icon-only-Nav-Item (kollabierter Zustand) hat ein `Semantics`/`tooltip`-Label identisch zum
    sichtbaren Label im ausgeklappten Zustand (z. B. „Personen“, nicht „Icon“).
12. `connection-banner` ist genau dann sichtbar, wenn `realtimeConnectionProvider` einen Wert ungleich
    `ConnectionStatus.live` liefert, auf jedem `/admin/*`-Screen identisch (nicht nur auf Lage); sobald der
    Provider `live` liefert, verschwindet es wieder.
13. Icon-Zuordnung je `nav-*`-Key entspricht der Tabelle in Abschnitt 3 (inkl. der sechs geänderten Icons);
    kein bestehender Test in `apps/web/test` verwendet `find.byIcon` auf einem dieser Icons (geprüft gegen
    `shifts_screen_test.dart`/`running_incidents_section_test.dart`, den einzigen beiden Dateien mit
    `byIcon`-Verwendung).

## 7. Zu erhaltende Keys + Semantics labels

Aus `lage_screen.dart` (per `grep -n "Key("`), wandern unverändert von AppBar-`IconButton`s in Sidebar-Items
(gleicher `Key`-Wert, gleiches `tooltip`):

`nav-einsaetze`, `nav-schichten`, `nav-durchsagen`, `nav-tagesablauf`, `nav-bf-tage`, `nav-fahrzeuge`,
`nav-persons`, `nav-monitors`, `nav-slides`, `logout`.

Tooltips (bleiben als `Semantics`/`tooltip`-Text erhalten): „Einsätze“, „Schichten“, „Durchsagen“,
„Tagesablauf“, „BF-Tage“, „Fahrzeuge“, „Personen“, „Monitore“, „Folien“, „Abmelden“.

**Neu (kein bestehender Test referenziert ihn, aber für Testbarkeit laut Akzeptanzkriterium 7 nötig):**
`Key('nav-lage')` für den Lage-Eintrag selbst (existierte bisher nicht, weil Lage keinen Eintrag für sich
selbst brauchte). Der Coder/Tester kann diesen Key frei vergeben; er ist in keinem bestehenden Test
referenziert.

**Neu (ebenfalls kein bestehender Test, für Akzeptanzkriterium 12 nötig):** `Key('connection-banner')` für
das gemeinsame Offline-Banner der `AdminShell` (Abschnitt 4).

## 8. Flows

Dies ist die einzige Karte mit einer strukturellen Flow-Änderung im Umfang von ux-02b:

**Vorher:** Navigation = AppBar-Actions, nur auf `LageScreen`. Jeder andere Screen hat keinen Weg zu einem
anderen Admin-Bereich außer „zurück zur Lage, dann von dort weiter“.

**Nachher:** Navigation = persistente Seitenleiste um alle `/admin/*`-Routen (`AdminShell` in `router.dart`).

**Begründung:** Das ist keine neue Funktion (jede Zielroute existierte bereits und war über die Lage
erreichbar) und keine fehlende Funktion (jeder Pfad, jede Berechtigungsprüfung bleibt identisch) — es ist eine
Vereinfachung des Zugriffspfads: von „Lage → Zielscreen → zurück zur Lage → nächster Zielscreen“ zu „Zielscreen
→ nächster Zielscreen direkt“. Das ist der höchste Benutzbarkeitsgewinn in dieser Karte für eine Leitstelle,
die unter Zeitdruck zwischen vielen Screens wechselt (Kartenbeschreibung „Leitstelle unter Zeitdruck“). Jede
einzelne Zielfunktion bleibt exakt erhalten, nur ihr Einstiegspunkt wird überall verfügbar statt nur von einem
Screen aus.

Implementierungshinweis für den Coder (kein Designentscheid, nur Hinweis): `router.dart` braucht einen
`ShellRoute`/`StatefulShellRoute` um die bestehenden `/admin/*`-`GoRoute`s, der die Sidebar einmal rendert und
die Screens als `child` einsetzt; jeder einzelne Screen (`BfDaysScreen`, `ShiftsScreen`, `PersonsScreen`, …)
behält seinen eigenen `AppBar`/Inhalt für Screen-spezifische Titel/Actions (s. jeweilige Screen-Konzepte),
verliert aber keine bestehende Funktion.

## 9. Zuordnung zum Regressionsinventar

Tabelle „Navigation / Seitenleiste“ (`docs/testing/regression-inventory.md`, Abschnitt
„### Navigation / Seitenleiste (`router.dart`)“):

| Funktion (Inventar) | Test | Ort im neuen Layout |
|---|---|---|
| Navigation | `router_test.dart` (19 Tests): SignedOut→Login, SignedIn→Lage, `/monitor`-Aktivierungsoverlay, Berechtigungs-basiertes Ein-/Ausblenden der Sidebar-Einträge, Navigation zu jedem Admin-Screen | Alle 19 Fälle bleiben gültig: dieselben Zielrouten, dieselbe Berechtigungs-Sichtbarkeit — nur aus AppBar-Icons (Lage) werden Sidebar-Items (`AdminShell`, Abschnitt 3/8); Signed-Out/Signed-In-Redirects unverändert in `router.dart`. |
| anzeigen/anlegen/bearbeiten/löschen/Echtzeit-Updates/Fehler/Leer/Offline | n/a (reine Navigationsschicht) | n/a — **außer** Offline: diese Karte führt das gemeinsame `connection-banner` neu als Shell-Konzept ein (Abschnitt 4/6 AK 12), das Inventar wird dadurch nicht invalidiert (keine neue Funktion, nur eine neue Anzeige des bereits bestehenden `realtimeConnectionProvider`-Zustands). |
