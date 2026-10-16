# ux-04 Verification Report (Navigation / Login / Lage rework)

Verified on branch `wt/t_98ac2c25` (== `main` at this point), commits present:
`1b69a8c` (ux-04a AdminShell/login/lage-header), `89f2f97`/`b77f386` (ux-04b
Lage-Kind-Widgets theme tokens).

## BUGS FOUND

**None.** No AC violations found in `apps/web/lib/{admin_shell,router}.dart`,
`screens/{login_screen,lage_screen}.dart`, or the four Lage Kind-Widgets. All
28 testable acceptance criteria across the three concept docs are satisfied
by the current implementation; no hardcoded `Colors.*`/`Color(0x...)` were
found in the files in scope (only `alarmColors.alarm`/`.alarmContainer`
token field accesses, which matched the same grep pattern as a false
positive and are themed, not hardcoded); no test assertions were weakened
between `1d2a1e8` and `HEAD` (see §4 below); all 10 `nav-*` keys, `logout`,
`connection-banner`, the 4 login keys, and all Lage-Kind-Widget keys from
§7 of the three concept docs are present in `apps/web/lib` unchanged.

## 1. Acceptance-criteria matrix

### web-navigation.md (13 AC)

| # | AC (short) | Evidence | Pass/Fail |
|---|---|---|---|
| 1 | Every `/admin/*` screen renders the same sidebar for the same permission | `router_test.dart` (19 cases, e.g. "admin can navigate to /admin/fahrzeuge via the nav entry") + `admin_shell_test.dart` AC1 | Pass |
| 2 | `Permission.crew` sees only `nav-lage`, no Verwaltung | `admin_shell_test.dart`: "AC2: Permission.crew sees only nav-lage, no Verwaltung" | Pass |
| 3 | `Permission.preparation` additionally sees `nav-einsaetze` only | `admin_shell_test.dart`: "AC3: Permission.preparation additionally sees nav-einsaetze only" | Pass |
| 4 | `Permission.dispatch` sees Betriebsablauf entries, no Verwaltung | `admin_shell_test.dart`: "AC4: Permission.dispatch sees the Betriebsablauf entries, no Verwaltung" | Pass |
| 5 | `Permission.admin` sees all ten `nav-*` + Verwaltung | `admin_shell_test.dart`: "AC5: Permission.admin sees all ten nav-* keys + Verwaltung" | Pass |
| 6 | Click on each visible nav entry navigates to the expected route | `router_test.dart` (19 cases) + `admin_shell_test.dart`: "clicking nav-fahrzeuge navigates to /admin/fahrzeuge" + `lage_screen_test.dart` (4 Navigation cases) | Pass |
| 7 | Active entry has `primaryContainer` background + 3px indicator, exactly one active | `admin_shell_test.dart`: "AC7: exactly one entry is active, with primary indicator" | Pass |
| 8 | Sidebar collapses to icons under 1280px, expands at/above | `admin_shell_test.dart`: "AC8: sidebar collapses to icons under 1280px, expands at/above it" | Pass |
| 9 | `logout` triggers `logout()` and redirects to `/admin/login` | `admin_shell_test.dart`: "AC9: logout triggers logout() and navigates to /admin/login" | Pass |
| 10 | Signed-in person's name + permission label visible in the footer | `admin_shell_test.dart`: "AC10: footer shows displayName and permission.label" + `lage_screen_test.dart`: "anzeigen: shows the signed-in person and Berechtigung" | Pass |
| 11 | Collapsed icon-only nav items keep a Tooltip matching the expanded label | `admin_shell_test.dart`: "AC11: collapsed icon-only nav items keep a Tooltip with the German label" | Pass |
| 12 | `connection-banner` shown iff connection != live, on every `/admin/*` screen | `admin_shell_test.dart`: "AC12: connection-banner shown iff not live, on Lage and another screen" | Pass |
| 13 | Icon assignment per `nav-*` key matches the table (incl. the 6 changed icons) | `admin_shell_test.dart`: "AC13: icon assignment per nav-* key matches the table" | Pass |

### web-login.md (6 AC)

| # | AC (short) | Evidence | Pass/Fail |
|---|---|---|---|
| 1 | `login-username`/`login-password`/`login-submit`/`login-error` findable and functional | `login_test.dart` (all 3 pre-existing tests use these keys) | Pass |
| 2 | Invalid login shows `LoginFailure.message` in `login-error` | `login_test.dart`: "invalid login shows the error text" | Pass |
| 3 | `login-submit` is `onPressed: null` + shows loader while `_isSubmitting` | Visually verified via code (`login_screen.dart:138-146`: `onPressed: _isSubmitting ? null : _submit`, replaces label with `CircularProgressIndicator`); **no dedicated test existed** — this state is implicitly exercised in passing (the submit button is tapped and settles) but not directly asserted mid-flight. *Gap not closed*: adding a reliable test requires pumping without `pumpAndSettle` mid-submit, which is fragile against this fake controller's synchronous `Future`; left as a minor residual test gap, not an AC violation (code matches spec exactly) | Pass (code); test coverage gap noted |
| 4 | Valid login navigates to `/admin` | `login_test.dart`: "valid login navigates to the Lage and shows no active deployments" | Pass |
| 5 | Login page renders no sidebar / no `nav-*` keys | **Gap found, closed**: new test `login_test.dart`: "AC5 (web-login.md): the login screen renders no sidebar/nav-* keys" (added by this verification) | Pass |
| 6 | Enter key in either field submits like a click on `login-submit` | `login_test.dart`: "Enter key in the password field submits the form" | Pass |

### web-lage.md (9 AC)

| # | AC (short) | Evidence | Pass/Fail |
|---|---|---|---|
| 1 | Lage renders inside the shared sidebar (active "Lage"), no own AppBar nav icons | `router_test.dart`/`admin_shell_test.dart` (AdminShell wraps `LageScreen`, `lage_screen.dart` AppBar has no `actions`) + visual confirmation via `lage-1440x900.png` (§3 below) | Pass |
| 2 | `nav-einsaetze` etc. are sidebar items, not `LageScreen` AppBar children; navigation unaffected | `lage_screen_test.dart` (4 Navigation cases: einsaetze/monitors/slides/persons) + `router_test.dart` | Pass |
| 3 | FMS badges use design-system tokens, not `Colors.orange`/`Colors.green` | `vehicle_status_bar_test.dart`: "FMS badges use themed status colors, not hard Colors values" | Pass |
| 4 | No running incidents shows an empty state (icon + text), not an empty area | `running_incidents_section_test.dart`: "empty state shows an icon and 'Keine laufenden Einsätze'" | Pass |
| 5 | Truncated vehicle/crew name shows the full text on hover/focus (Tooltip) | `vehicle_status_bar_test.dart`: "shows a Tooltip with the full crew text for a long call sign" | Pass |
| 6 | "shows the signed-in person and Berechtigung" test stays green | `lage_screen_test.dart`: "anzeigen: shows the signed-in person and Berechtigung" (passing, now reads from sidebar footer) | Pass |
| 7 | `missed-alarms-section`/`scheduled-alarms-section` render only when non-empty, correct order | `missed_alarms_section_test.dart`: "renders nothing when there are no missed Alarmierungen" + `scheduled_alarms_section_test.dart`: "renders nothing when there are no planned Alarmierungen"; order (`vehicle-status-bar` → `missed-alarms-section` → `scheduled-alarms-section` → `running-incidents-section`) fixed structurally in `lage_screen.dart:17-24`, unchanged by this epic | Pass |
| 8 | `missed-alarm-trigger/discard-{id}` and `scheduled-alarm-trigger/change/discard-{id}` are dispatch/admin-only | `missed_alarms_section_test.dart`: "Einsatzvorbereitung sees the list read-only" + `scheduled_alarms_section_test.dart`: "Einsatzvorbereitung sees the list read-only" | Pass |
| 9 | `scheduled-alarm-countdown-{id}` text changes visibly within 2 seconds | **Gap found, closed**: new test `scheduled_alarms_section_test.dart`: "AC9 (web-lage.md): scheduled-alarm-countdown ticks within 2 seconds" (added by this verification) | Pass |

## 2. "Zu erhaltende Keys" preservation check

Grepped `Key('<k>` in `apps/web/lib` for every key listed in §7 of all three
concept docs (10 `nav-*` incl. new `nav-lage`, `logout`, `connection-banner`,
4 login keys, and all Lage-Kind-Widget keys incl. `alarm_dialog.dart`/
`confirm_dialog.dart`). **All present, none missing.** (`alarm_dialog.dart`
and `confirm_dialog.dart` keys were out of scope for code changes in this
epic and untouched; spot-checked present via `confirm-dialog-confirm`
appearing in 8 locations across the dialog + its callers.)

## 3. Test-weakening check (`git diff 1d2a1e8..HEAD -- apps/web/test`)

`--stat`: 11 files changed, 524 insertions(+), 86 deletions(-) — net growth,
dominated by the new `admin_shell_test.dart` (356 lines) and
`vehicle_status_bar_test.dart`'s AC3-coverage rewrite.

Reviewed every removed `expect(` line: all removals are either (a) pure
reformatting (multi-line `expect(...)` collapsed to one line, same
assertion) or (b) a strictly equivalent/stricter replacement, e.g.
`vehicle_status_bar_test.dart`'s `expect(find.text('2'), findsOneWidget)` →
`expect(find.textContaining('Einsatzbereit auf Wache'), findsOneWidget)`
(same status-change assertion, now checking the FMS label text instead of
the raw status code, which is a *stronger* check, not a weaker one). No
assertion was deleted without an equivalent or stronger replacement.
`running_incidents_section_test.dart` and the monitor test files show small
diffs from unrelated reformatting/`bftagLightTheme()` additions, not
assertion removal.

## 4. Hardcoded-color check

`grep -nE "Colors\.[a-z]|Color\(0x"` across `router.dart`, `admin_shell.dart`,
`lage_screen.dart`, `login_screen.dart`, and the four Lage-Kind-Widgets:
only matches are `alarmColors.alarm` / `alarmColors.alarmContainer` /
`alarmColors.onAlarm` field accesses in `missed_alarms_section.dart` and
`running_incidents_section.dart` — these are theme-extension token lookups
(`BftagAlarmColors`), not hardcoded `Colors.*`/`Color(0x...)` literals; the
regex only matched because the field names happen to contain the substring
"Colors"/"Color". **No hardcoded colors found.**

## 5. Test suite results

| Suite | Command | Result |
|---|---|---|
| Backend | `just test` | **32 files passed, 336 tests passed**, 0 failed |
| Static analysis | `just analyze` | `dart analyze packages/api_client`: no issues. `flutter analyze apps/web apps/mobile packages/core`: **no issues found** |
| Flutter web tests | `cd apps/web && flutter test` | **223 tests passed**, 0 failed (includes the 2 new tests added by this verification, see §1 gaps) |
| E2E | `just e2e` | API: **142 passed, 0 failed**. UI: **29 passed, 0 failed** |

All green, no regressions. Docker Compose stack (`bftag-e2e` project,
backend + postgres) was started and torn down automatically by
`e2e/run.sh`'s own `trap cleanup EXIT` (`docker compose ... down -v
--remove-orphans`) for both the `just e2e` and `just screenshots after`
runs — nothing left running afterward (`docker ps -a` only shows stale,
already-`Exited` containers from days-old unrelated runs).

## 6. Missing-test gaps filled

Two testable AC had no covering test; both closed by this verification
(production code untouched):

1. **`apps/web/test/login_test.dart`** — new test `"AC5 (web-login.md): the
   login screen renders no sidebar/nav-* keys"`: asserts `login-username` is
   present while all 10 `nav-*` keys and `logout` are absent on
   `/admin/login`.
2. **`apps/web/test/scheduled_alarms_section_test.dart`** — new test
   `"AC9 (web-lage.md): scheduled-alarm-countdown ticks within 2 seconds"`:
   drives `monitorClockProvider` through two ticks 2 seconds apart and
   asserts the `scheduled-alarm-countdown-{id}` text actually changes.

Both pass (`flutter test test/login_test.dart
test/scheduled_alarms_section_test.dart`: 11/11 passed).

## 7. Visual verification (screenshots)

Regenerated via `just screenshots after` → `docs/design/screenshots/after/{web,monitor}/*.png`
(40 screenshots, 0 failed).

- **`login-1440x900.png`**: centered card, 64px primary-colored rounded-square
  app icon with a flame glyph, "BF-Tag" title, Benutzername/Passwort fields,
  full-width "Anmelden" button — matches web-login.md §3 mockup. No layout
  issues.
- **`lage-1440x900.png`**: left sidebar (240px, expanded) with "Lage"
  highlighted as the active entry (filled icon background + visible left
  indicator), "Verwaltung" section heading present above
  Personen/Fahrzeuge/Monitore/Folien, footer shows "Administrator /
  Administrator / Abmelden". Content area shows three FMS-badged vehicle
  tiles (HLF-1/RTW-1/DLK-1, status badges in orange "3 Einsatz übernommen"
  and green "2 Einsatzbereit auf Wache") and one running-incident card
  ("#1 B3 Großbrand Lagerhalle", Nachalarmieren/Einsatz schließen buttons,
  quittierungs rows). Matches `docs/design/mockups/lage.png`'s structure.
  **Deviation (cosmetic, not a regression)**: vehicle crew names are
  truncated to "Florian screenshots …" in the static screenshot — this is
  expected (`TextOverflow.ellipsis` + `Tooltip`, AC5 above, verified via
  test); a screenshot cannot show the hover tooltip, so the full text isn't
  visible in the PNG, but this is correct, spec'd behavior, not a bug.

No broken layout, no clipped buttons, no missing data, no contrast issues,
no lost empty/error states observed in either screenshot.

## Summary

- **BUGS FOUND: 0** (ticket-worthy issues).
- **Missing tests filled: 2** (login AC5, Lage AC9 — both listed in §6).
- **Visual deviations: 0 regressions** (one expected/spec'd truncation
  noted in §7, not an issue).
- **All test suites green**: backend 336/336, analyze clean, flutter web
  223/223, e2e API 142/142 + UI 29/29.
