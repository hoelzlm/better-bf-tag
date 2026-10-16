# Teststrategie

Wie das Regressionsinventar, die Unit-/Widget-Tests, die E2E-Suite (ADR 0023)
und der Screenshot-Harness zusammen das Testkonzept des Projekts bilden.

## Die vier Ebenen

1. **Unit-/Widget-Tests** (`flutter test` pro Paket: `apps/web`, `apps/mobile`,
   `packages/core`; `just test` für das Backend; `just analyze` für die
   statische Analyse). Schnell, laufen ohne Backend/Docker. Prüfen Verhalten
   einzelner Screens/Widgets/Funktionen gegen Fakes — siehe Regel unten.
2. **Regressionsinventar** (`docs/testing/regression-inventory.md`). Kein
   eigenes Werkzeug, sondern die Buchhaltung über die Widget-Tests: pro
   Screen und Funktion (anzeigen/anlegen/bearbeiten/löschen/Echtzeit/Fehler/
   Leerzustand/Offline) steht, welcher Test sie abdeckt. Admin-Web, Monitor
   und App sind vollständig geschlossen (keine `Lücke`-Zeile).
3. **E2E-Suite** (`just e2e`, ADR 0023, `e2e/`). Baut die echten
   Produktions-Images, startet den vollen Compose-Stack (`infra/`) und prüft
   API + Web-UI per Chrome DevTools Protocol gegen die echten Container
   (Caddy, HTTPS, WebSocket, Postgres). Prüft Zusammenspiel, nicht
   Screen-für-Screen-Verhalten im Detail — das macht Ebene 1.
4. **Screenshot-Harness** (`just screenshots dir=...`, dieses Dokument). Baut
   auf der E2E-Suite auf (gleicher Stack, gleiche Helfer aus `e2e/lib.mjs`),
   erzeugt aber **keine** Pass/Fail-Checks, sondern PNGs für die visuelle
   Layout-Durchsicht durch Menschen/Designer. Siehe Abschnitt "Wichtig: keine
   Pixel-Tests" unten — das ist eine fundamental andere Aktivität als die
   Tests der Ebenen 1–3.

Alle vier Ebenen zusammen: Ebene 1–3 stellen automatisiert sicher, dass sich
niemand etwas kaputt macht (CI-fähig, Pass/Fail). Ebene 4 ist ein Werkzeug für
die UI/UX-Überarbeitung (`.scratch/ux/spec.md`) — ein Mensch vergleicht
`docs/design/screenshots/before/` mit `docs/design/screenshots/after/` Datei
für Datei und beurteilt das Layout. Sie läuft nicht in CI und hat keinen
Exit-Code, der über richtig/falsch entscheidet.

## Wichtig: keine Pixel-Tests

Die harte Regel aus dem Regressionsinventar gilt unverändert und ausdrücklich
auch für den Screenshot-Harness:

> Tests finden Elemente über `Key`/Semantics-Label/sichtbaren funktionalen
> Text und prüfen Verhalten — nie Farben, Pixel oder Layout.

Der Screenshot-Harness **bricht diese Regel nicht**, weil er kein Test ist:
Er hat keine Assertions, keinen Soll/Ist-Vergleich, keinen Exit-Code ≠ 0 bei
"falschem" Pixel. Die PNGs sind ausschließlich für die **visuelle Durchsicht
durch einen Menschen** (Designer/Entwickler vergleicht vorher/nachher). Ein
automatischer Pixel-Diff zwischen `before/` und `after/` ist bewusst **nicht**
Teil dieses Harnesses — das wäre genau die Art von Pixel-Test, die die Regel
verbietet, weil er bei jeder harmlosen Layout-Änderung (neue Breite durch
mehr Text, Font-Rendering-Unterschiede, Kartenkacheln offline/online) falsch
rot würde. Verhalten bleibt ausschließlich über die Key/Semantics-basierten
Widget-Tests (Ebene 1) abgesichert.

## Screenshot-Harness im Detail

`just screenshots dir="before"` (Default `before`) erzeugt:

```
docs/design/screenshots/<dir>/
  web/      <screen>[-<state>]-1440x900.png   (Admin-Web, über e2e/screenshots.mjs)
  monitor/  <screen>[-<state>]-1920x1080.png  (Monitor, über e2e/screenshots.mjs)
  app/      <screen>[-<state>]-{390x844,360x640}.png (Mobile, über screenshot_test/)
```

Dateinamen: `<screen>[-<state>]-<Breite>x<Höhe>.png`, klein geschrieben,
kebab-case, z. B. `web/personen-1440x900.png`, `monitor/alarm-1920x1080.png`,
`app/alarm-screen-dark-390x844.png`. **Dieselben Dateinamen in jedem `<dir>`**
— so lässt sich `before/` und `after/` 1:1 Datei-für-Datei vergleichen.

### Web + Monitor (`e2e/screenshots.mjs`)

Läuft über denselben Produktions-Stack wie `just e2e` (ADR 0023): `e2e/run.sh`
mit `E2E_MODE=screenshots` baut/startet die Images wie gewohnt, ruft dann
`e2e/screenshots.mjs` statt `api.mjs`+`ui.mjs` auf. `screenshots.mjs`:

- seedet deterministische Beispieldaten selbst über die API (`e2e/lib.mjs`s
  `call()`/`must()`): ein BF-Tag, 3+ Fahrzeuge mit unterschiedlichem
  FMS-Status, Personen mit mehreren Personentypen, Schichten, Einsätze
  (inkl. eines laufenden mit Position), Tagesablauf, Folien, eine Durchsage;
- steuert headless Chrome über CDP (dieselben Helfer wie `ui.mjs`, jetzt in
  `e2e/lib.mjs`: `createCdpSession()` mit `send`/`evalJs`/`nav`/`waitFor`/
  `enableSemantics`/`freePort`); setzt den Viewport über
  `Emulation.setDeviceMetricsOverride` (Web 1440×900, Monitor 1920×1080);
- wartet kurz, bis die Seite gerendert hat (feste Pause reicht hier — Uhrzeit-
  Text unterscheidet sich ohnehin zwischen Läufen, das ist kein Bug), und
  nimmt den Screenshot über `Page.captureScreenshot`.

**Eine neue Seite hinzufügen:** in `e2e/screenshots.mjs` die Seite zur
`ADMIN_PAGES`-Liste (Web) bzw. als zusätzlichen `nav()`+`shot()`-Schritt
(Monitor) hinzufügen; Dateiname nach dem Schema oben wählen.

### Mobile (`apps/mobile/screenshot_test/`)

Bewusst **außerhalb** von `apps/mobile/test/`, damit `flutter test` (ohne
Argument) sie nicht mitläuft — geprüft durch Weglassen des Pfads. Aufruf nur
explizit:

```
cd apps/mobile && flutter test screenshot_test --dart-define=SCREENSHOT_DIR=<abs-path>
```

Jeder Screen wird als Widget-Test (mit den gleichen Fakes/Mustern wie
`apps/mobile/test/*.dart`) bei zwei Größen (390×844, 360×640) gepumpt, in
einem `RepaintBoundary` gefangen und über `RenderRepaintBoundary.toImage()`
als PNG geschrieben. Lädt vorher echte Roboto-/MaterialIcons-Fonts aus
`$FLUTTER_ROOT/bin/cache/artifacts/material_fonts/` (sonst zeigt der
Screenshot Ahem-Kästchen statt Text).

**Eine neue Seite hinzufügen:** in `apps/mobile/screenshot_test/screenshots_test.dart`
einen neuen `testWidgets(...)`-Block nach dem bestehenden Muster ergänzen
(Overrides pumpen, ggf. per Router navigieren, `_capture(tester, name, size)`
aufrufen).

### Dark Mode

Die Mobile-App hat aktuell **kein** Dark Mode (kein `ThemeMode`, kein
`Brightness`-Zweig in `apps/mobile/lib/`, siehe `main.dart`: ein fester
`ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true)`). Der
Screenshot-Harness erzeugt deshalb aktuell **keine** `app/*-dark-*.png` —
sobald Dark Mode implementiert ist, ergänzt `screenshots_test.dart` die
entsprechenden Varianten für Alarm-Screen und Mein Fahrzeug.

## Neue Screens zum Regressionsinventar hinzufügen

Für Verhalten (nicht Layout): neuen Test in `apps/<app>/test/*_test.dart`
oder `packages/core/test/*_test.dart` ergänzen (Key/Semantics-basiert), dann
die passende Zeile in `docs/testing/regression-inventory.md` aktualisieren.
Für Layout-Durchsicht: siehe Abschnitte oben.
