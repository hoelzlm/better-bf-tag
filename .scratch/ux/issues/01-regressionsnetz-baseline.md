# ux-01 — Regressionsnetz und Screenshot-Baseline

**What to build:** Bevor sich die Oberfläche ändert, ist jede Funktion jedes Screens durch einen Verhaltenstest
abgesichert, und es gibt reproduzierbare Screenshots aller Screens. Details: `.scratch/ux/spec.md`
(„Testing Decisions“).

**Blocked by:** –

**Owner:** Tester (Karten mit assignee `tester`; Review durch `reviewer`)

**Status:** done

- [x] `docs/testing/regression-inventory.md`: Tabelle aller Screens (Admin-Web, Monitor, App) × Funktionen
      (anzeigen, anlegen, bearbeiten, löschen, Navigation, Echtzeit-Updates, Fehler-/Leer-/Offline-Zustände)
      mit dem Test, der sie abdeckt
- [x] Jede Lücke im Inventar hat einen Widget- oder E2E-Test; Tests finden Elemente über `Key`/Semantics und
      prüfen Verhalten, nicht Farben/Pixel. Fehlende `Key`s an interaktiven Elementen werden ergänzt
      (nur Keys, keine sichtbare Änderung)
- [x] Screenshot-Harness: `just screenshots` erzeugt PNGs aller Screens mit festen Beispieldaten
      (Web 1440x900, Monitor 1920x1080 inkl. Standby, Einsatzansicht, Alarm, Durchsage-Banner;
      App 390x844 und 360x640 inkl. Alarm-Screen) nach `docs/design/screenshots/<ordner>/`
- [x] Vorher-Stand erzeugt und committet: `docs/design/screenshots/before/`
- [x] Monitor- und andere Scope-Tests verschachteln `ProviderScope` wie in Produktion (siehe PR #31)
- [x] Doku: `docs/testing/README.md` (wie Inventar, Harness und Suites zusammenhängen)
- [x] `just test`, `just analyze`, `just e2e` grün

Spec: `.scratch/ux/spec.md` · Glossar: `CONTEXT.md`
