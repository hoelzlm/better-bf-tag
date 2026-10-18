import 'dart:async';

import 'package:bftag_api_client/bftag_api_client.dart'
    show PairRequestPlatformEnum;
import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/main.dart';
import 'package:bftag_mobile/onboarding/onboarding_store.dart';
import 'package:bftag_mobile/pairing_code_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _person = Person(
  id: 'p1',
  displayName: 'Max M.',
  personType: PersonType.youth,
  permission: Permission.crew,
);

/// Fake [PairedSessionController] simulating pair()/logout()/restore()
/// without any network calls, matching the real controller's contract
/// (ADR 0010): `ABCDEFGH` pairs successfully, anything else is rejected
/// with a [PairingFailure].
class _FakePairedSessionController extends PairedSessionController {
  _FakePairedSessionController(this._initial);

  final PairedSessionState _initial;
  int logoutCalls = 0;

  /// When set, `pair()` waits on this future before resolving/throwing,
  /// so tests can observe the in-flight (`_isSubmitting == true`) state.
  Future<void>? pairDelay;

  @override
  PairedSessionState build() => _initial;

  @override
  Future<void> restore() async {
    // No-op: tests set the initial state explicitly via build().
  }

  @override
  Future<void> pair(
    String code, {
    required PairRequestPlatformEnum platform,
    required String appVersion,
    String? deviceName,
  }) async {
    if (pairDelay != null) {
      await pairDelay;
    }
    if (normalizePairingCode(code) == 'ABCDEFGH') {
      state = const Paired(_person, 'fake-access-token', 'dev1');
      return;
    }
    throw const PairingFailure('Code ungültig oder abgelaufen.');
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = const PairedUnpaired();
  }

  @override
  Future<void> onRevoked() async {
    state = const PairedUnpaired(revoked: true);
  }

  @override
  void acknowledgeRevoked() {
    if (state case PairedUnpaired(revoked: true)) {
      state = const PairedUnpaired();
    }
  }
}

/// A no-op QR scanner stand-in so widget tests never touch a camera. Tests
/// that need to simulate a scan grab the [onDetected] callback this
/// records and invoke it directly.
class _FakeScanner {
  void Function(String code)? onDetected;

  Widget build(void Function(String code) onDetected) {
    this.onDetected = onDetected;
    return const SizedBox.shrink();
  }
}

List<Override> _overrides(
  PairedSessionState session,
  _FakeScanner scanner, {
  _FakePairedSessionController? controller,
}) {
  return [
    pairedSessionControllerProvider.overrideWith(
      () => controller ?? _FakePairedSessionController(session),
    ),
    // These tests exercise pairing/logout navigation, not the Onboarding
    // (ADR 0021) flow itself -- mark it as already completed so a
    // freshly paired session lands directly on "Mein Fahrzeug".
    onboardingStoreProvider.overrideWithValue(
      InMemoryOnboardingStore(completed: true),
    ),
    qrScannerBuilderProvider.overrideWithValue(scanner.build),
    // StartScreen watches this to kick off the realtime connection; these
    // tests only exercise pairing/navigation, so stub it out.
    pairedRealtimeClientProvider.overrideWith((ref) => null),
    // MyVehicleScreen watches this; these tests don't exercise "Mein
    // Fahrzeug" assignments, and overriding it avoids starting the real
    // 30s tick timer (which would otherwise outlive the test).
    myCrewAssignmentsProvider.overrideWithValue(const []),
  ];
}

/// WCAG contrast ratio between two colours, via relative luminance
/// (`Color.computeLuminance`), matching `docs/design/tools/contrast.py`.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Resizes the test surface for the duration of the test (restored via
/// `addTearDown`), matching the 390x844/360x640 sizes the concepts test.
void _setSurfaceSize(WidgetTester tester, Size size) {
  final originalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDpr;
  });
}

/// Forces the platform brightness for the duration of the test, so
/// `BftagMobileApp`'s `ThemeMode.system` renders `bftagDarkTheme()`.
void _setBrightness(WidgetTester tester, Brightness brightness) {
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
}

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'bftag_mobile',
      packageName: 'de.bftag.bftag_mobile',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('manual code entry calls pair with the normalized code and shows '
      'the Hallo screen', (tester) async {
    final scanner = _FakeScanner();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(const PairedUnpaired(), scanner),
        child: const BftagMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pair-code')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pair-code')), 'abcd-efgh');
    await tester.tap(find.byKey(const Key('pair-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Mein Fahrzeug'), findsOneWidget);
  });

  testWidgets('invalid code shows the error text', (tester) async {
    final scanner = _FakeScanner();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(const PairedUnpaired(), scanner),
        child: const BftagMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('pair-code')), 'ZZZZ-ZZZZ');
    await tester.tap(find.byKey(const Key('pair-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Code ungültig oder abgelaufen.'), findsOneWidget);
  });

  testWidgets('scanning a QR code pairs the same way as manual entry', (
    tester,
  ) async {
    final scanner = _FakeScanner();
    await tester.pumpWidget(
      ProviderScope(
        overrides: _overrides(const PairedUnpaired(), scanner),
        child: const BftagMobileApp(),
      ),
    );
    await tester.pumpAndSettle();

    scanner.onDetected!('ABCDEFGH');
    await tester.pumpAndSettle();

    expect(find.text('Mein Fahrzeug'), findsOneWidget);
  });

  testWidgets(
    'Einstellungen -> Gerät abmelden navigates back to the pairing screen',
    (tester) async {
      final scanner = _FakeScanner();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(
            const Paired(_person, 'fake-access-token', 'dev1'),
            scanner,
          ),
          child: const BftagMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mein Fahrzeug'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('logout-button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('logout-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pair-code')), findsOneWidget);
    },
  );

  testWidgets(
    'a revoked session navigates to the pairing screen with a hint, shown '
    'exactly once (AC5)',
    (tester) async {
      final scanner = _FakeScanner();
      final container = ProviderContainer(
        overrides: _overrides(
          const Paired(_person, 'fake-access-token', 'dev1'),
          scanner,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BftagMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mein Fahrzeug'), findsOneWidget);

      await container
          .read(pairedSessionControllerProvider.notifier)
          .onRevoked();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pair-code')), findsOneWidget);
      expect(find.text('Dieses Gerät wurde abgemeldet.'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    },
  );

  group('app-kopplung.md ACs', () {
    testWidgets(
      'AC1: camera area and manual code entry are both present and the '
      'code field is usable',
      (tester) async {
        final scanner = _FakeScanner();
        await tester.pumpWidget(
          ProviderScope(
            overrides: _overrides(const PairedUnpaired(), scanner),
            child: const BftagMobileApp(),
          ),
        );
        await tester.pumpAndSettle();

        // The camera area (built from the overridden qrScannerBuilder) is
        // in the tree...
        expect(scanner.onDetected, isNotNull);
        expect(find.byType(AspectRatio), findsOneWidget);
        // ...and the manual code field + submit button are independently
        // usable.
        await tester.enterText(find.byKey(const Key('pair-code')), 'ABCD-EFGH');
        await tester.tap(find.byKey(const Key('pair-submit')));
        await tester.pumpAndSettle();
        expect(find.text('Mein Fahrzeug'), findsOneWidget);
      },
    );

    testWidgets(
      'AC3: submit is disabled and shows a spinner while submitting',
      (tester) async {
        final scanner = _FakeScanner();
        final delay = Completer<void>();
        final controller = _FakePairedSessionController(const PairedUnpaired())
          ..pairDelay = delay.future;
        await tester.pumpWidget(
          ProviderScope(
            overrides: _overrides(
              const PairedUnpaired(),
              scanner,
              controller: controller,
            ),
            child: const BftagMobileApp(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('pair-code')), 'ABCD-EFGH');
        await tester.tap(find.byKey(const Key('pair-submit')));
        await tester.pump();

        final button = tester.widget<FilledButton>(
          find.byKey(const Key('pair-submit')),
        );
        expect(button.onPressed, isNull);
        expect(
          find.descendant(
            of: find.byKey(const Key('pair-submit')),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
        );
        expect(find.text('Koppeln'), findsNothing);

        delay.complete();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC4: pair-error is absent (no space taken) when there is no error',
      (tester) async {
        final scanner = _FakeScanner();
        await tester.pumpWidget(
          ProviderScope(
            overrides: _overrides(const PairedUnpaired(), scanner),
            child: const BftagMobileApp(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('pair-error')), findsNothing);
      },
    );

    testWidgets(
      'AC4: pair-error colour is colorScheme.error, never the alarm colour',
      (tester) async {
        final scanner = _FakeScanner();
        await tester.pumpWidget(
          ProviderScope(
            overrides: _overrides(const PairedUnpaired(), scanner),
            child: const BftagMobileApp(),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('pair-code')), 'ZZZZ-ZZZZ');
        await tester.tap(find.byKey(const Key('pair-submit')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('pair-error')), findsOneWidget);
        final context = tester.element(find.byKey(const Key('pair-error')));
        final theme = Theme.of(context);
        final icon = tester.widget<Icon>(
          find.descendant(
            of: find.byKey(const Key('pair-error')),
            matching: find.byType(Icon),
          ),
        );
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byKey(const Key('pair-error')),
            matching: find.byType(Text),
          ),
        );
        expect(icon.color, theme.colorScheme.error);
        expect(text.style?.color, theme.colorScheme.error);
        final alarm = theme.extension<BftagAlarmColors>()!.alarm;
        expect(theme.colorScheme.error, isNot(equals(alarm)));
      },
    );

    testWidgets(
      'AC6: on 360x640 the camera area is smaller than on 390x844, and '
      'the code field + submit stay visible without scrolling',
      (tester) async {
        final scanner = _FakeScanner();
        _setSurfaceSize(tester, const Size(390, 844));
        await tester.pumpWidget(
          ProviderScope(
            overrides: _overrides(const PairedUnpaired(), scanner),
            child: const BftagMobileApp(),
          ),
        );
        await tester.pumpAndSettle();
        final largeHeight = tester.getSize(find.byType(AspectRatio)).height;

        _setSurfaceSize(tester, const Size(360, 640));
        await tester.pump();
        await tester.pumpAndSettle();
        final smallHeight = tester.getSize(find.byType(AspectRatio)).height;

        expect(smallHeight, lessThan(largeHeight));

        final codeFieldRect = tester.getRect(
          find.byKey(const Key('pair-code')),
        );
        final submitRect = tester.getRect(find.byKey(const Key('pair-submit')));
        expect(codeFieldRect.bottom, lessThanOrEqualTo(640));
        expect(submitRect.bottom, lessThanOrEqualTo(640));
      },
    );

    testWidgets(
      'AC7: pair-error and the code field label reach >= 4.5:1 contrast '
      'in light and dark theme',
      (tester) async {
        for (final theme in [bftagLightTheme(), bftagDarkTheme()]) {
          final scheme = theme.colorScheme;
          expect(
            _contrast(scheme.error, scheme.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(scheme.onSurfaceVariant, scheme.surface),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );

    testWidgets('meets Android tap target and labeled tap target guidelines '
        '(light, 390x844)', (tester) async {
      final scanner = _FakeScanner();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(const PairedUnpaired(), scanner),
          child: const BftagMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('meets Android tap target and labeled tap target guidelines '
        '(dark, 360x640)', (tester) async {
      final scanner = _FakeScanner();
      _setBrightness(tester, Brightness.dark);
      _setSurfaceSize(tester, const Size(360, 640));
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(const PairedUnpaired(), scanner),
          child: const BftagMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });

  group('app-einstellungen.md ACs', () {
    Future<void> pumpSettings(
      WidgetTester tester, {
      _FakePairedSessionController? controller,
    }) async {
      final scanner = _FakeScanner();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(
            const Paired(_person, 'fake-access-token', 'dev1'),
            scanner,
            controller: controller,
          ),
          child: const BftagMobileApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings')));
      await tester.pumpAndSettle();
    }

    testWidgets('AC1: "Gerät abmelden" uses the alarm FilledButton style, not '
        'primary', (tester) async {
      await pumpSettings(tester);

      final context = tester.element(find.byKey(const Key('logout-button')));
      final alarmColors = Theme.of(context).extension<BftagAlarmColors>()!;
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('logout-button')),
      );
      final background = button.style?.backgroundColor?.resolve({});
      expect(background, alarmColors.alarm);
      expect(background, isNot(equals(Theme.of(context).colorScheme.primary)));
    });

    testWidgets(
      'AC2: in the confirmation dialog only "Abmelden" is alarm-coloured, '
      'the title/text stay neutral and "Abbrechen" is a plain TextButton',
      (tester) async {
        await pumpSettings(tester);

        await tester.tap(find.byKey(const Key('logout-button')));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect((dialog.title as Text).data, 'Gerät abmelden');
        expect(
          find.text(
            'Dieses Gerät wird abgemeldet und muss erneut gekoppelt werden.',
          ),
          findsOneWidget,
        );

        final context = tester.element(find.byKey(const Key('logout-confirm')));
        final alarmColors = Theme.of(context).extension<BftagAlarmColors>()!;
        final confirmButton = tester.widget<FilledButton>(
          find.byKey(const Key('logout-confirm')),
        );
        expect(
          confirmButton.style?.backgroundColor?.resolve({}),
          alarmColors.alarm,
        );

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key == const Key('logout-cancel') &&
                widget is TextButton,
          ),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('logout-cancel')));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'AC3: "Einrichtung erneut öffnen" uses the secondary OutlinedButton '
      'style',
      (tester) async {
        await pumpSettings(tester);

        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget.key == const Key('reopen-onboarding') &&
                widget is OutlinedButton,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('AC4: Testalarm buttons use primary, never the alarm colour', (
      tester,
    ) async {
      await pumpSettings(tester);

      final context = tester.element(find.byKey(const Key('test-alarm-now')));
      final alarmColors = Theme.of(context).extension<BftagAlarmColors>()!;
      final nowButton = tester.widget<FilledButton>(
        find.byKey(const Key('test-alarm-now')),
      );
      final resolvedBackground =
          nowButton.style?.backgroundColor?.resolve({}) ??
          Theme.of(context).colorScheme.primary;
      expect(resolvedBackground, isNot(equals(alarmColors.alarm)));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget.key == const Key('test-alarm-delayed') &&
              widget is OutlinedButton,
        ),
        findsOneWidget,
      );
    });

    testWidgets('AC5: "Abbrechen" in the dialog does not call logout()', (
      tester,
    ) async {
      final controller = _FakePairedSessionController(
        const Paired(_person, 'fake-access-token', 'dev1'),
      );
      await pumpSettings(tester, controller: controller);

      await tester.tap(find.byKey(const Key('logout-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logout-cancel')));
      await tester.pumpAndSettle();

      expect(controller.logoutCalls, 0);
      expect(find.text('Einstellungen'), findsOneWidget);
    });

    testWidgets(
      'AC6: alarm and primary button labels reach >= 4.5:1 contrast in '
      'light and dark theme',
      (tester) async {
        for (final theme in [bftagLightTheme(), bftagDarkTheme()]) {
          final alarmColors = theme.extension<BftagAlarmColors>()!;
          expect(
            _contrast(alarmColors.onAlarm, alarmColors.alarm),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _contrast(theme.colorScheme.onPrimary, theme.colorScheme.primary),
            greaterThanOrEqualTo(4.5),
          );
        }
      },
    );

    testWidgets('meets Android tap target and labeled tap target guidelines '
        '(light, 390x844)', (tester) async {
      await pumpSettings(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });

    testWidgets('meets Android tap target and labeled tap target guidelines '
        '(dark, 360x640)', (tester) async {
      _setBrightness(tester, Brightness.dark);
      _setSurfaceSize(tester, const Size(360, 640));
      await pumpSettings(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });
}
