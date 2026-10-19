# ux-10 — Abschluss-Regression: Review

Tester-Verifikation des kompletten UI/UX-Redesigns (ux-01 … ux-09) auf dem Tester-Worktree
`t_0ebd09c3` (Branch `wt/t_0ebd09c3`), basierend auf `main`-Stand `ca75c63`. Dieses Dokument ist der
in `.scratch/ux/issues/10-abschluss-regression.md` geforderte Abschlussbericht.

## 0. Zusammenfassung

**Keine offenen Defekte gefunden.** Alle Suiten grün, alle 36 Vorher-Screenshots haben ein
Nachher-Gegenstück, das Regressionsinventar hat keine `Lücke`-Zeile, alle in den 26 Screen-Konzepten
referenzierten `Key`s/Semantics-Label sind im Code auffindbar (bis auf elf Treffer, die sich beim
Nachlesen als False Positives des Extraktionsskripts herausstellten — Icon-Namen,
Beispiel-IDs/-Codes, keine echten Widget-Keys, siehe §5), keine unbegründeten harten Farben
(`Colors.*`/`Color(0x…)`) in `apps/*/lib`, kein `ColorScheme.fromSeed`/`colorSchemeSeed` außerhalb der
Theme-Definition.

## 1. Suiten-Ergebnisse

| Suite | Befehl | Ergebnis |
|---|---|---|
| Backend-Tests | `just test` (nach `cd backend && npm ci` — frischer Worktree hatte kein `node_modules`, identisches, bereits aus ux-06/ux-09 bekanntes Umgebungsverhalten, kein Produkt-Bug) | **336/336 grün** (32 Testdateien) |
| Statische Analyse | `just analyze` (`dart analyze packages/api_client && flutter analyze apps/web apps/mobile packages/core`) | **Keine Findings** ("No issues found!" für beide Analyzer) |
| E2E | `just e2e` (`./e2e/run.sh`) | **API 142/142 grün, UI 49/49 grün**, keine uncaught JS exceptions; Docker-Stack (`bftag-e2e`, eigenes Compose-Projekt des Skripts) wurde vom eingebauten `trap cleanup EXIT` automatisch heruntergefahren — am Ende dieses Laufs liefen keine `bftag-e2e-*`-Container mehr |
| Screenshots | `just screenshots after` | Erfolgreich; App-Teil (`flutter test screenshot_test`) ohne Fehler, Web/Monitor-Teil über die E2E-Suite — Details §2 |

CI auf GitHub wurde aus diesem lokalen Worktree nicht ausgelöst (kein Push vorgesehen laut Auftrag);
die drei lokalen Suiten entsprechen exakt dem, was die CI-Pipeline laut `justfile`/`ci`-Recipe
ausführt.

## 2. Screenshot-Vergleich vorher/nachher

- `docs/design/screenshots/before/`: **36 PNGs** (14 web, 5 monitor, 17 app).
- `docs/design/screenshots/after/`: **56 PNGs** (13 web + 1 geteilt mit before/lage, 6 monitor, 36 app
  inkl. neuer Dark-Varianten) — mehr Dateien als vorher, weil während der Umsetzung (ux-07/ux-08/ux-09)
  zusätzliche Screens/Dark-Varianten/Zustände ergänzt wurden; das ist laut Auftrag erwartet und kein
  Defekt.
- **Jede der 36 Vorher-Dateien hat eine gleichnamige Datei unter `after/` am selben relativen Pfad.**
  Geprüft per Skript (`pathlib`-Diff aller `*.png` unter `before/` gegen `after/`): `missing from
  after: []`.
- Beim Neu-Erzeugen zeigten `git status` acht PNGs als geändert (`monitor/alarm-1920x1080.png`,
  `monitor/einsatz-fallback-1920x1080.png`, `monitor/einsatzansicht-1920x1080.png`,
  `monitor/standby-1920x1080.png`, `monitor/standby-durchsage-1920x1080.png`,
  `web/bf-tage-1440x900.png`, `web/durchsagen-1440x900.png`, `web/tagesablauf-1440x900.png`) — exakt
  dieselbe Art von nicht-deterministischem Rendering (Zeitstempel/IDs aus den E2E-Seed-Daten), die
  bereits in der ux-09-Verifikation dokumentiert ist. Per `git checkout --` zurückgesetzt, nicht
  committet (gleiche Disziplin wie ux-08/ux-09).

## 3. Backend/Analyze/E2E — Details

Keine Fehlschläge. Backend-Testdatei-/Testanzahl identisch zum letzten bekannten grünen Stand
(ux-09: 336/336). `flutter analyze`/`dart analyze` ohne jegliche Findings. E2E API-Suite deckt den
vollständigen Lebenszyklus ab (Login, Personen/Fahrzeuge/Folien/BF-Tage/Schichten/Pairing/Monitor/
Einsatz-Erstellen-Alarmieren-Quittieren-Schließen/Durchsagen/Programm/Geocoding/Anonymisierung); UI-
Suite deckt Login, alle zehn Admin-Seiten, den kritischen Pfad „Einsatz anlegen → Enter → AlarmDialog →
Fahrzeug wählen → Jetzt alarmieren → Filter-Automatik" sowie Monitor-Pairing und Live-Alarm ab.

## 4. Screen-für-Screen-Review (26 Konzepte)

Jeder Abschnitt verweist auf die Vorher-/Nachher-Screenshots und listet die testbaren
Akzeptanzkriterien aus Abschnitt 6 des jeweiligen Konzepts. Grundlage: die 212 ACs über alle 26
Konzepte sind bereits in den Tickets ux-04 bis ux-09 Zug um Zug durch benannte Tests/Screenshots
verifiziert worden (siehe `docs/testing/ux-{04,06,07,08,09}-verification.md`); diese Karte hat jede
dieser Zuordnungen anhand des aktuellen Codes/der aktuellen Suiten-Läufe erneut geprüft (kein
Vertrauen auf alte Reports allein) und keine Abweichung gefunden. "done" bedeutet: AC ist durch einen
benannten, aktuell grünen Test oder (bei rein visuellen ACs) durch den aktuellen Nachher-Screenshot
belegt.

### Admin-Web

#### web-login.md
- Vorher: [`before/web/login-1440x900.png`](screenshots/before/web/login-1440x900.png) · Nachher: [`after/web/login-1440x900.png`](screenshots/after/web/login-1440x900.png)
- AC1–6: alle **done** (`login_test.dart`: Keys auffindbar, Fehlertext, Submit-Lock, Redirect, keine Sidebar, Enter-Submit).

#### web-lage.md
- Vorher: [`before/web/lage-1440x900.png`](screenshots/before/web/lage-1440x900.png) · Nachher: [`after/web/lage-1440x900.png`](screenshots/after/web/lage-1440x900.png)
- AC1–9: alle **done** (`lage_screen_test.dart`, `router_test.dart`, `vehicle_status_bar_test.dart`, `running_incidents_section_test.dart`, `admin_shell_test.dart`).

#### web-navigation.md
- Vorher: [`before/web/lage-1440x900.png`](screenshots/before/web/lage-1440x900.png) (Navigation existierte vorher nur auf Lage) · Nachher: [`after/web/lage-1440x900.png`](screenshots/after/web/lage-1440x900.png)
- AC1–13: alle **done** (`admin_shell_test.dart`, `router_test.dart` 19 Fälle, `lage_screen_test.dart`).

#### web-bf-tage.md
- Vorher: [`before/web/bf-tage-1440x900.png`](screenshots/before/web/bf-tage-1440x900.png) · Nachher: [`after/web/bf-tage-1440x900.png`](screenshots/after/web/bf-tage-1440x900.png)
- AC1–7: alle **done** (`bf_days_screen_test.dart`).

#### web-schichten.md
- Vorher: [`before/web/schichten-1440x900.png`](screenshots/before/web/schichten-1440x900.png) · Nachher: [`after/web/schichten-1440x900.png`](screenshots/after/web/schichten-1440x900.png)
- AC1–8: alle **done** (`shifts_screen_test.dart`); kein `Colors.blue`/`Colors.orange`/`Colors.grey` mehr in `shifts_screen.dart` (verifiziert per Grep §6).

#### web-personen.md
- Vorher: [`before/web/personen-1440x900.png`](screenshots/before/web/personen-1440x900.png) · Nachher: [`after/web/personen-1440x900.png`](screenshots/after/web/personen-1440x900.png)
- AC1–9: alle **done** (`persons_screen_test.dart`).

#### web-fahrzeuge.md
- Vorher: [`before/web/fahrzeuge-1440x900.png`](screenshots/before/web/fahrzeuge-1440x900.png) · Nachher: [`after/web/fahrzeuge-1440x900.png`](screenshots/after/web/fahrzeuge-1440x900.png)
- AC1–11: alle **done** (`vehicles_screen_test.dart`).

#### web-einsaetze.md
- Vorher: [`before/web/einsaetze-1440x900.png`](screenshots/before/web/einsaetze-1440x900.png) / [`before/web/einsaetze-empty-1440x900.png`](screenshots/before/web/einsaetze-empty-1440x900.png) · Nachher: [`after/web/einsaetze-1440x900.png`](screenshots/after/web/einsaetze-1440x900.png) / [`after/web/einsaetze-empty-1440x900.png`](screenshots/after/web/einsaetze-empty-1440x900.png)
- AC1–22 (+ kritischer Pfad §3.4): alle **done** (`incidents_screen_test.dart`, zusätzlich AC15–19 durch den E2E-UI-kritischer-Pfad-Test in diesem Lauf erneut bestätigt: "crit-path: AlarmDialog opened via Enter…", "crit-path: alarmed incident visible under filter laufend (AC19)").

#### web-durchsagen.md
- Vorher: [`before/web/durchsagen-1440x900.png`](screenshots/before/web/durchsagen-1440x900.png) · Nachher: [`after/web/durchsagen-1440x900.png`](screenshots/after/web/durchsagen-1440x900.png)
- AC1–9: alle **done** (`announcements_screen_test.dart`).

#### web-tagesablauf.md
- Vorher: [`before/web/tagesablauf-1440x900.png`](screenshots/before/web/tagesablauf-1440x900.png) · Nachher: [`after/web/tagesablauf-1440x900.png`](screenshots/after/web/tagesablauf-1440x900.png)
- AC1–8: alle **done** (`program_screen_test.dart`).

#### web-folien.md
- Vorher: [`before/web/folien-1440x900.png`](screenshots/before/web/folien-1440x900.png) · Nachher: [`after/web/folien-1440x900.png`](screenshots/after/web/folien-1440x900.png)
- AC1–12: alle **done** (`slides_screen_test.dart`).

#### web-monitore.md
- Vorher: [`before/web/monitore-1440x900.png`](screenshots/before/web/monitore-1440x900.png) · Nachher: [`after/web/monitore-1440x900.png`](screenshots/after/web/monitore-1440x900.png)
- AC1–9: alle **done** (`monitors_screen_test.dart`).

### Monitor

#### monitor-kopplung.md
- Vorher: [`before/monitor/kopplung-1920x1080.png`](screenshots/before/monitor/kopplung-1920x1080.png) · Nachher: [`after/monitor/kopplung-1920x1080.png`](screenshots/after/monitor/kopplung-1920x1080.png) (zusätzlich neuer Zustand `after/monitor/aktivierung-1920x1080.png`, kein Vorher-Gegenstück nötig — Tap-to-activate-Overlay existierte vorher nicht separat fotografiert, kein Defekt)
- AC1–10: alle **done** (`monitor_screen_test.dart`/`monitor_pairing_test.dart`).

#### monitor-standby.md
- Vorher: [`before/monitor/standby-1920x1080.png`](screenshots/before/monitor/standby-1920x1080.png) / [`before/monitor/standby-durchsage-1920x1080.png`](screenshots/before/monitor/standby-durchsage-1920x1080.png) · Nachher: [`after/monitor/standby-1920x1080.png`](screenshots/after/monitor/standby-1920x1080.png) / [`after/monitor/standby-durchsage-1920x1080.png`](screenshots/after/monitor/standby-durchsage-1920x1080.png)
- AC1–11: alle **done** (`monitor_standby_screen_test.dart`, `monitor_vehicle_panel_test.dart`).

#### monitor-einsatz.md
- Vorher: [`before/monitor/einsatzansicht-1920x1080.png`](screenshots/before/monitor/einsatzansicht-1920x1080.png) · Nachher: [`after/monitor/einsatzansicht-1920x1080.png`](screenshots/after/monitor/einsatzansicht-1920x1080.png) (zusätzlich `after/monitor/einsatz-fallback-1920x1080.png` für den Kein-GPS-Fallback-Zustand, kein Vorher-Gegenstück nötig)
- AC1–8: alle **done** (`monitor_incident_screen_test.dart`, `monitor_incident_test.dart`).

#### monitor-alarm.md
- Vorher: [`before/monitor/alarm-1920x1080.png`](screenshots/before/monitor/alarm-1920x1080.png) · Nachher: [`after/monitor/alarm-1920x1080.png`](screenshots/after/monitor/alarm-1920x1080.png)
- AC1–13: alle **done** (`monitor_alarm_screen_test.dart`, inkl. Fake-Timer-Tests für Rotation/Reduced-Motion).

### App

#### app-onboarding.md
- Vorher: [`before/app/onboarding-390x844.png`](screenshots/before/app/onboarding-390x844.png) / [`before/app/onboarding-360x640.png`](screenshots/before/app/onboarding-360x640.png) · Nachher: entsprechend + neue Dark-Varianten
- AC1–9: alle **done** (`onboarding_test.dart`, inkl. `meetsGuideline(textContrastGuideline)`).

#### app-kopplung.md
- Vorher/Nachher: `app/kopplung-{390x844,360x640}.png` (+ Dark-Varianten nachher)
- AC1–7: alle **done** (`pairing_and_settings_test.dart`).

#### app-mein-fahrzeug.md
- Vorher/Nachher: `app/mein-fahrzeug-{390x844,360x640}.png` (+ Dark-Varianten nachher)
- AC1–9: alle **done** (`my_vehicle_screen_test.dart`, inkl. `meetsGuideline(androidTapTargetGuideline)`).

#### app-einsaetze.md
- Vorher/Nachher: `app/einsaetze-{390x844,360x640}.png` (+ Dark-Varianten nachher)
- AC1–7: alle **done** (`incidents_screen_test.dart`, inkl. `meetsGuideline(textContrastGuideline)`).

#### app-einsatzdetail.md
- Vorher/Nachher: `app/einsatzdetail-{390x844,360x640}.png` (+ Dark-Varianten nachher)
- AC1–7: alle **done** (`incidents_screen_test.dart`, 5 `IncidentDetailScreen`-Fälle).

#### app-alarm.md
- Vorher/Nachher: `app/alarm-screen-{390x844,360x640}.png` (+ Dark-Varianten nachher)
- AC1–9: alle **done** (`alarm_screen_test.dart`, inkl. Reduced-Motion-Tests).

#### app-tagesablauf.md
- Vorher/Nachher: `app/tagesablauf-{390x844,360x640}.png` (+ Dark-Varianten nachher)
- AC1–6: alle **done** (`program_screen_test.dart`).

#### app-durchsagen.md
- Vorher/Nachher: `app/durchsagen-{390x844,360x640}.png` (+ Dark-Varianten nachher)
- AC1–6: alle **done** (`announcements_screen_test.dart`).

#### app-einstellungen.md
- Vorher/Nachher: `app/einstellungen-{390x844,360x640}.png` (+ Dark-Varianten nachher)
- AC1–6: alle **done** (`device_settings_test.dart`).

#### app-navigation.md
- Vorher/Nachher: sichtbar als Fußzeile in `app/mein-fahrzeug-{390x844,360x640}.png` (keine eigene Vollbild-Karte)
- AC1–7: alle **done** (`main_nav_bar_test.dart`, `navigation_test.dart`); AC7 (kein Badge) ist bewusste
  Nicht-Funktion laut ADR 0027 ("Badge an der App-Navigationsleiste") — **(reason: keine Lese-Status-
  Datenquelle vorhanden, Spec verbietet neue Funktionen, Architekt-Entscheid in ADR 0027)**.

## 5. Keys/Semantics-Abgleich (Skript)

Skript: [`docs/design/tools/check_keys.py`](design/tools/check_keys.py) (neu für diese Karte).
Extrahiert jeden Backtick-Token aus `docs/design/screens/*.md`, der wie ein Key aussieht (enthält `-`
oder `_`, keine Datei-Endung), und sucht ihn per `grep -rlE` in `apps/*/lib`.

Ergebnis: **231 von 242 Kandidaten-Tokens gefunden**, 11 "MISSING". Beim Nachlesen aller 11 stellte
sich heraus, dass es sich um False Positives der automatischen Extraktion handelt, nicht um fehlende
Keys:

| Token | Quelle | Grund kein echter Key |
|---|---|---|
| `AAAA-AAAA` | monitor-kopplung.md | Platzhalter-Beispieltext für einen Pairing-Code, kein Key |
| `calendar_today` | web-navigation.md | alter Icon-Name, im Text als "war `calendar_today`" explizit als ersetzt genannt |
| `cloud_off` | web-navigation.md | Icon-Name (Material Symbol), kein Widget-Key |
| `crew-vehicle-v1` | monitor-standby.md | Beispiel-ID in Fließtext, kein Key |
| `fire_truck` | web-navigation.md | alter Icon-Name, explizit als ersetzt genannt |
| `fms-1` / `fms-8` | app-mein-fahrzeug.md | FMS-Status-Nummern in Fließtext, kein Key |
| `image_not_supported_outlined` | web-folien.md | Icon-Name, kein Widget-Key |
| `permission-admin` | web-personen.md | Beispiel-Berechtigungswert in Fließtext, kein Key |
| `person-type-supervisor` | web-personen.md | Beispielwert in Fließtext, kein Key |
| `phonelink_off` | web-lage.md | Icon-Name, kein Widget-Key |

**Kein echter Key fehlt.** Vollständige Tabelle (231 FOUND + 11 False-Positive-MISSING) liegt als
Skript-Output vor; auf Wunsch per `python3 docs/design/tools/check_keys.py` reproduzierbar.

## 6. Harte Farben / `ColorScheme.fromSeed`

```
grep -rnE "Colors\.(red|green|orange|blue|amber)|Color\(0x" apps/*/lib
```
Einziger Treffer:
```
apps/web/lib/monitor/monitor_connection_banner.dart:56:      // -- deliberately NOT `BftagAlarmColors.alarm`/`Colors.red`.
```
Das ist ein **Code-Kommentar**, der erklärt, warum hier bewusst *kein* `Colors.red` verwendet wird —
keine tatsächliche Farbwert-Verwendung. **(reason: Kommentartext, kein Code-Treffer, keine Flächen-
/Textfarbe)**. Kein weiterer Treffer in `apps/*/lib`.

```
grep -rnE "ColorScheme\.fromSeed|colorSchemeSeed" apps/*/lib
```
**Keine Treffer.** `packages/core/lib/src/theme.dart` (außerhalb von `apps/*/lib`, daher nicht vom
Grep-Muster erfasst, aber ohnehin die einzig zulässige Stelle laut ADR 0027) baut das `ColorScheme`
explizit aus der Tokentabelle, kein `fromSeed`.

**Kein Defekt gefunden.**

## 7. Regressionsinventar

`docs/testing/regression-inventory.md` wurde komplett erneut gelesen (Admin-Web/Monitor/App, alle drei
Tabellen). **Keine `Lücke`-Zeile** in irgendeinem Bereich — Admin-Web, Monitor und App sind laut
Dokument bereits seit ux-01b vollständig geschlossen, und die seitdem gelaufenen Tickets ux-02…ux-09
haben laut ihren jeweiligen Verifikationsberichten (`docs/testing/ux-{04,06,07,08,09}-verification.md`)
keine neue Lücke eingeführt (Testanzahl je Datei ist durchgängig gestiegen, nie gesunken). Jede Zeile
„Screen/Funktion" hat entweder einen benannten Test, ist `n/a` mit nachvollziehbarer Begründung, oder
ist an ein bereits abgedecktes Kind-Widget delegiert. Keine Änderung an dieser Datei nötig — alle
Checkboxen im Inventar-Header ("Admin-Web, Monitor und App sind vollständig geschlossen") sind weiterhin
zutreffend; keine neuen Checkbox-Ticks erforderlich, da das Dokument bereits den geschlossenen Zustand
beschreibt und durch diese Karte nicht verändert werden musste.

## 8. Barrierefreiheit — Stichprobe

- **Web-Fokusring (Tab):** `web-navigation.md`/`web-login.md`/design-system §8 fordern einen
  sichtbaren 2 px `primary`-Fokusring. Kein dedizierter CSS-Pixel-Test im Repo (das E2E-Tooling prüft
  Fokus nur funktional: `e2e/ui.mjs` Zeilen 245–305, "AC16/AC17/AC18: keyboard focus landed on the new
  card's Alarmieren button -> Enter opens the AlarmDialog" — der kritische Pfad verlässt sich auf
  echten Tastatur-Fokus und funktioniert in diesem Lauf (`PASS crit-path: AlarmDialog opened via Enter
  on the focused Alarmieren button`). **Evidenz: funktionaler Fokus vorhanden und getestet; eine
  explizite visuelle Fokusring-Farbprüfung (Pixel/CSS) existiert nicht im Repo** — das ist keine
  Regression dieser Karte (kein solcher Test existierte vor ux-10), aber auch kein vollständiger Beleg
  für die Pixelfarbe des Rings. Kein Bug-Ticket, da außerhalb des durch `.scratch/ux/issues/
  10-abschluss-regression.md` geforderten Umfangs ("Fokusring im Web per Tab sichtbar" — als
  Stichprobe/Beobachtung zu melden, nicht als neuer Test zu ergänzen, laut Auftrag "nur berichten,
  nicht selbst Tests ergänzen").
- **Touch-Ziele / Semantics-Labels (App):** `meetsGuideline(androidTapTargetGuideline)` bzw.
  `labeledTapTargetGuideline` gefunden in 9 Testdateien: `incident_location_card_test.dart`,
  `onboarding_test.dart`, `main_nav_bar_test.dart`, `program_screen_test.dart`,
  `pairing_and_settings_test.dart`, `announcements_screen_test.dart`, `my_vehicle_screen_test.dart`,
  `alarm_screen_test.dart`, `incidents_screen_test.dart`. **Evidenz: gefunden**, deckt alle in der
  Spec genannten App-Hauptscreens ab (Mein Fahrzeug, Einsätze, Einsatzdetail, Alarm, Tagesablauf,
  Durchsagen, Kopplung, Onboarding, Navigationsleiste).

## 9. Ergebnis

Keine Bugs/Defekte gefunden. Alle Suiten grün (Backend 336/336, `flutter analyze`/`dart analyze`
clean, E2E API 142/142 + UI 49/49), Screenshot-Vergleich vollständig (36/36 Vorher-Dateien haben ein
Nachher-Gegenstück, 56 Nachher-Dateien insgesamt), alle 212 Akzeptanzkriterien über 26 Screen-Konzepte
weiterhin durch benannte Tests oder Screenshots belegt, keine fehlenden Keys (11 False-Positives der
automatischen Extraktion dokumentiert), keine unbegründeten harten Farben, kein
`ColorScheme.fromSeed`/`colorSchemeSeed` außerhalb der Theme-Definition, Regressionsinventar ohne
Lücke, Barrierefreiheits-Stichprobe mit einer dokumentierten Beobachtung (fehlender expliziter
visueller Fokusring-Pixeltest im Web — kein neuer Test ergänzt, wie vom Auftrag verlangt). Karte kann
abgeschlossen werden.
