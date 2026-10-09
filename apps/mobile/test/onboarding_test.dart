import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/alarm/alarm_sound.dart';
import 'package:bftag_mobile/alarm/pending_alarm.dart';
import 'package:bftag_mobile/main.dart';
import 'package:bftag_mobile/onboarding/device_settings.dart';
import 'package:bftag_mobile/onboarding/onboarding_screen.dart';
import 'package:bftag_mobile/onboarding/onboarding_store.dart';
import 'package:bftag_mobile/push/push_service.dart';
import 'package:bftag_mobile/router.dart';
import 'package:bftag_mobile/screens/alarm_screen.dart';
import 'package:bftag_mobile/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = Person(
  id: 'p1',
  displayName: 'Max M.',
  personType: PersonType.youth,
  permission: Permission.crew,
);

/// Fake [DeviceSettings] with directly settable status fields and call
/// counters, so tests can control what the Onboarding shows/does without
/// any real platform channel.
class _FakeDeviceSettings implements DeviceSettings {
  bool notifications = false;
  bool dnd = false;
  bool battery = false;
  String manufacturerValue = 'samsung';
  int openNotificationSettingsCalls = 0;
  int openDndSettingsCalls = 0;
  int requestIgnoreBatteryOptimizationCalls = 0;

  @override
  Future<bool> notificationsEnabled() async => notifications;

  @override
  Future<bool> bypassesDnd() async => dnd;

  @override
  Future<bool> batteryOptimizationIgnored() async => battery;

  @override
  Future<String> manufacturer() async => manufacturerValue;

  @override
  Future<void> openNotificationSettings() async {
    openNotificationSettingsCalls++;
  }

  @override
  Future<void> openDndSettings() async {
    openDndSettingsCalls++;
  }

  @override
  Future<void> requestIgnoreBatteryOptimization() async {
    requestIgnoreBatteryOptimizationCalls++;
  }
}

/// Fake [TestAlarmRepository] recording every `trigger` call, with a
/// configurable [outcome] or [exception] to return/throw instead.
class _FakeTestAlarmRepository implements TestAlarmRepository {
  final List<int> calls = [];
  TestAlarmOutcome outcome = TestAlarmOutcome.delivered;
  Object? exception;

  @override
  Future<TestAlarmOutcome> trigger({int delaySeconds = 0}) async {
    calls.add(delaySeconds);
    final error = exception;
    if (error != null) {
      throw error;
    }
    return outcome;
  }
}

/// Fake [PushService] with a controllable [onTestAlarmReceived] stream and
/// an [init] call counter.
class _FakePushService implements PushService {
  int initCalls = 0;
  final _testAlarmReceivedController = StreamController<void>.broadcast();

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<String?> initialAlarmId() async => null;

  @override
  Stream<String> get onAlarmOpened => const Stream<String>.empty();

  @override
  Stream<void> get onTestAlarmReceived => _testAlarmReceivedController.stream;

  void emitTestAlarmReceived() => _testAlarmReceivedController.add(null);
}

class _FakeAlarmSound implements AlarmSound {
  int playCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> play({bool loop = false}) async {
    playCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

class _FakePairedSessionController extends PairedSessionController {
  _FakePairedSessionController(this._initial);

  final PairedSessionState _initial;

  @override
  PairedSessionState build() => _initial;

  @override
  Future<void> restore() async {}

  @override
  Future<void> logout() async {
    state = const PairedUnpaired();
  }

  @override
  Future<void> onRevoked() async {
    state = const PairedUnpaired(revoked: true);
  }

  @override
  void acknowledgeRevoked() {}
}

List<Override> _overrides({
  required PairedSessionState session,
  required InMemoryOnboardingStore onboardingStore,
  required _FakeDeviceSettings deviceSettings,
  required _FakeTestAlarmRepository testAlarmRepository,
  required _FakePushService pushService,
  required bool isIos,
  _FakeAlarmSound? alarmSound,
}) {
  return [
    pairedSessionControllerProvider.overrideWith(
      () => _FakePairedSessionController(session),
    ),
    onboardingStoreProvider.overrideWithValue(onboardingStore),
    deviceSettingsProvider.overrideWithValue(deviceSettings),
    testAlarmRepositoryProvider.overrideWithValue(testAlarmRepository),
    pushServiceProvider.overrideWithValue(pushService),
    onboardingPlatformProvider.overrideWithValue(isIos),
    alarmSoundProvider.overrideWithValue(alarmSound ?? _FakeAlarmSound()),
    pairedRealtimeClientProvider.overrideWith((ref) => null),
    myCrewAssignmentsProvider.overrideWithValue(const []),
    pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
    pairedIncidentsProvider.overrideWith((ref) => Stream.value(const [])),
    pairedVehiclesProvider.overrideWith((ref) => Stream.value(const [])),
  ];
}

const _paired = Paired(_me, 'fake-access-token', 'dev1');

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required PairedSessionState session,
  required InMemoryOnboardingStore onboardingStore,
  required _FakeDeviceSettings deviceSettings,
  required _FakeTestAlarmRepository testAlarmRepository,
  required _FakePushService pushService,
  bool isIos = false,
}) async {
  final container = ProviderContainer(
    overrides: _overrides(
      session: session,
      onboardingStore: onboardingStore,
      deviceSettings: deviceSettings,
      testAlarmRepository: testAlarmRepository,
      pushService: pushService,
      isIos: isIos,
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
  return container;
}

void main() {
  testWidgets(
    'a freshly paired, not-yet-onboarded session lands on /onboarding',
    (tester) async {
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
      );

      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets(
    'a paired session with a completed onboarding lands on Mein Fahrzeug',
    (tester) async {
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: true),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
      );

      expect(find.text('Mein Fahrzeug'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  testWidgets(
    'deep link /alarm/:id is never redirected to /onboarding',
    (tester) async {
      final container = await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
      );
      // Reached /onboarding first (completed=false), matching the test
      // above -- now simulate a deep link tap while still not onboarded.
      expect(find.byType(OnboardingScreen), findsOneWidget);

      container.read(mobileGoRouterProvider).go('/alarm/a1');
      // Not `pumpAndSettle`: `AlarmScreen` shows an indefinitely-animating
      // `CircularProgressIndicator` while its alarm hasn't loaded (it
      // never does here), which `pumpAndSettle` can never settle past.
      // Enough pumps to get past the page transition animation (so the
      // old /onboarding page is actually disposed), not just one frame.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(OnboardingScreen), findsNothing);
      final alarmScreen = tester.widget<AlarmScreen>(
        find.byType(AlarmScreen),
      );
      expect(alarmScreen.alarmId, 'a1');
    },
  );

  testWidgets(
    'Android shows the Akku-Optimierung step with the manufacturer hint, '
    'no mute hint',
    (tester) async {
      final deviceSettings = _FakeDeviceSettings()
        ..manufacturerValue = 'samsung';
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: deviceSettings,
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
        isIos: false,
      );

      // Notifications -> Weiter
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      // Nicht stören -> Weiter
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding-status-battery')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-battery-hint')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-mute-hint')), findsNothing);
    },
  );

  testWidgets(
    'iOS shows the mute hint, no Akku-Optimierung step',
    (tester) async {
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
        isIos: true,
      );

      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('onboarding-mute-hint')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-status-battery')), findsNothing);
      expect(find.byKey(const Key('onboarding-battery-hint')), findsNothing);
    },
  );

  testWidgets(
    'statuses render from the fake and refresh after a simulated resume',
    (tester) async {
      final deviceSettings = _FakeDeviceSettings()..notifications = false;
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: deviceSettings,
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('onboarding-status-notifications')),
            )
            .data,
        '✗',
      );

      deviceSettings.notifications = true;
      final observer = tester.state<State<OnboardingScreen>>(
        find.byType(OnboardingScreen),
      ) as WidgetsBindingObserver;
      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Text>(
              find.byKey(const Key('onboarding-status-notifications')),
            )
            .data,
        '✓',
      );
    },
  );

  Future<void> goToTestAlarmStep(WidgetTester tester, bool isIos) async {
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    // Battery (Android) / mute (iOS) step.
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    '"Testalarm jetzt" triggers delaySeconds 0 and shows the delivered text',
    (tester) async {
      final testAlarmRepository = _FakeTestAlarmRepository()
        ..outcome = TestAlarmOutcome.delivered;
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: testAlarmRepository,
        pushService: _FakePushService(),
      );
      await goToTestAlarmStep(tester, false);

      await tester.tap(find.byKey(const Key('test-alarm-now')));
      await tester.pumpAndSettle();

      expect(testAlarmRepository.calls, [0]);
      expect(
        find.text('Push zugestellt – hast du den Alarmton gehört?'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '"Testalarm in 10 Sekunden" triggers delaySeconds 10 and shows the '
    'lock-screen hint',
    (tester) async {
      final testAlarmRepository = _FakeTestAlarmRepository()
        ..outcome = TestAlarmOutcome.scheduled;
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: testAlarmRepository,
        pushService: _FakePushService(),
      );
      await goToTestAlarmStep(tester, false);

      await tester.tap(find.byKey(const Key('test-alarm-delayed')));
      await tester.pumpAndSettle();

      expect(testAlarmRepository.calls, [10]);
      expect(find.text('Sperre jetzt den Bildschirm.'), findsOneWidget);
    },
  );

  testWidgets(
    'no_push_token shows the "nicht eingerichtet" text',
    (tester) async {
      final testAlarmRepository = _FakeTestAlarmRepository()
        ..exception = const TestAlarmException('no_push_token');
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: testAlarmRepository,
        pushService: _FakePushService(),
      );
      await goToTestAlarmStep(tester, false);

      await tester.tap(find.byKey(const Key('test-alarm-now')));
      await tester.pumpAndSettle();

      expect(
        find.text('Push ist auf diesem Gerät nicht eingerichtet.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'test_alarm_cooldown shows the "kurz warten" text',
    (tester) async {
      final testAlarmRepository = _FakeTestAlarmRepository()
        ..exception = const TestAlarmException('test_alarm_cooldown');
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: testAlarmRepository,
        pushService: _FakePushService(),
      );
      await goToTestAlarmStep(tester, false);

      await tester.tap(find.byKey(const Key('test-alarm-now')));
      await tester.pumpAndSettle();

      expect(
        find.text('Bitte kurz warten und erneut versuchen.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'onTestAlarmReceived shows "Testalarm empfangen"',
    (tester) async {
      final pushService = _FakePushService();
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: false),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: pushService,
      );
      await goToTestAlarmStep(tester, false);

      pushService.emitTestAlarmReceived();
      await tester.pumpAndSettle();

      expect(find.text('Testalarm empfangen'), findsOneWidget);
    },
  );

  testWidgets(
    'Fertig completes onboarding and navigates to Mein Fahrzeug',
    (tester) async {
      final onboardingStore = InMemoryOnboardingStore(completed: false);
      await _pump(
        tester,
        session: _paired,
        onboardingStore: onboardingStore,
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
      );
      await goToTestAlarmStep(tester, false);
      // Testalarm -> Weiter
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding-finish')));
      await tester.pumpAndSettle();

      expect(find.text('Mein Fahrzeug'), findsOneWidget);
      expect(await onboardingStore.isCompleted(), isTrue);
    },
  );

  testWidgets(
    'Settings "Einrichtung erneut öffnen" opens the onboarding',
    (tester) async {
      await _pump(
        tester,
        session: _paired,
        onboardingStore: InMemoryOnboardingStore(completed: true),
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
      );
      expect(find.text('Mein Fahrzeug'), findsOneWidget);

      await tester.tap(find.byKey(const Key('settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('reopen-onboarding')));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen), findsOneWidget);
    },
  );

  testWidgets(
    'logout resets the onboarding flag',
    (tester) async {
      final onboardingStore = InMemoryOnboardingStore(completed: true);
      await _pump(
        tester,
        session: _paired,
        onboardingStore: onboardingStore,
        deviceSettings: _FakeDeviceSettings(),
        testAlarmRepository: _FakeTestAlarmRepository(),
        pushService: _FakePushService(),
      );

      await tester.tap(find.byKey(const Key('settings')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logout-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logout-confirm')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pair-code')), findsOneWidget);
      expect(await onboardingStore.isCompleted(), isFalse);
    },
  );
}
