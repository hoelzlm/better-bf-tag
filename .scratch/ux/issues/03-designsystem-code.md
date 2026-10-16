# ux-03 — Designsystem im Code (Theme, Schrift, Icon, gemeinsame Widgets)

**What to build:** Das Designsystem aus `docs/design/design-system.md` wird in `packages/core` umgesetzt und in
Web, Monitor und App eingehängt. Danach sehen alle Oberflächen mit Standard-Material-Widgets schon nach dem
neuen System aus (Farben, Schrift); die Screens selbst werden erst ab ux-04 umgebaut. Entscheidungen: ADR 0027.

**Blocked by:** ux-02

**Owner:** Architekt (zerlegt in Coder-Karten), Coder, Reviewer, Tester

**Status:** ready-for-agent

- [ ] `packages/core`: `bftagTheme(BftagThemeMode)`, `bftagLightTheme()`, `bftagDarkTheme()`,
      `bftagMonitorTheme()` und die Extensions `BftagStatusColors`, `BftagAlarmColors`, `BftagSpacing`,
      `BftagRadii`, `BftagMonitorTextStyles` exakt nach Designsystem §2–§5 und §10 (explizites `ColorScheme`
      aus Tabelle 2.1, `error` = `warning`, Alarmrot nur in `BftagAlarmColors`, Komponenten-`*ThemeData`
      nach §5, Fokusring nach §8); exportiert über `bftag_core.dart`
- [ ] Inter (400/500/600/700) + `OFL.txt` als Font-Asset in `packages/core`, im Theme gesetzt; kein
      Laufzeit-Laden von Schriften (kein `google_fonts`)
- [ ] Web: `MaterialApp` nutzt `bftagLightTheme()`; Monitor-Routen in `Theme(data: bftagMonitorTheme())`
- [ ] App: `theme: bftagLightTheme(), darkTheme: bftagDarkTheme(), themeMode: ThemeMode.system`; das eigene
      `ThemeData` in `apps/mobile/lib/main.dart` ist entfernt
- [ ] Gemeinsame Widgets in `packages/core/lib/src/widgets/`: `FmsBadge`, `BftagStateView`
      (`.loading/.empty/.error`), `ConnectionBanner` (Designsystem 5.5, 5.10) mit Widget-Tests
- [ ] Theme-Tests: alle drei Modi liefern alle Extensions; `colorScheme.error != BftagAlarmColors.alarm`;
      Stichproben-Kontraste aus Tabelle 2.3 per Berechnung (≥ 4,5 : 1)
- [ ] App-Icon/Favicon aus `docs/design/icon/`: Web (`favicon.png`, `favicon.svg`, `icons/Icon-*.png`,
      `manifest.json`-Farben), Android (Launcher inkl. adaptive + monochrom), iOS (AppIcon-Set)
- [ ] Screenshot-Harness der App lädt Inter (keine Ahem-Blöcke); `just screenshots after` läuft durch
- [ ] Bestehende Widget-`Key`s und Semantics-Labels bleiben erhalten; kein Verhaltenstest gelöscht oder
      abgeschwächt
- [ ] `just test`, `just analyze`, `just e2e` grün; CI auf GitHub grün
- [ ] Tester-Verifikation abgeschlossen

Spec: `.scratch/ux/spec.md` · Designsystem: `docs/design/design-system.md` · ADR: `docs/adr/0027-designsystem-umsetzung.md` · Glossar: `CONTEXT.md`
