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
    if (normalizePairingCode(code) == 'ABCDEFGH') {
      state = const Paired(_person, 'fake-access-token', 'dev1');
      return;
    }
    throw const PairingFailure('Code ungültig oder abgelaufen.');
  }

  @override
  Future<void> logout() async {
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
  _FakeScanner scanner,
) {
  return [
    pairedSessionControllerProvider.overrideWith(
      () => _FakePairedSessionController(session),
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

  testWidgets(
    'manual code entry calls pair with the normalized code and shows '
    'the Hallo screen',
    (tester) async {
      final scanner = _FakeScanner();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _overrides(const PairedUnpaired(), scanner),
          child: const BftagMobileApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pair-code')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('pair-code')),
        'abcd-efgh',
      );
      await tester.tap(find.byKey(const Key('pair-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Mein Fahrzeug'), findsOneWidget);
    },
  );

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

    expect(
      find.text('Code ungültig oder abgelaufen.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'scanning a QR code pairs the same way as manual entry',
    (tester) async {
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
    },
  );

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
    'a revoked session navigates to the pairing screen with a hint',
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
    },
  );
}
