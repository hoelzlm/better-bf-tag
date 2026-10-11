import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/alarm/pending_alarm.dart';
import 'package:bftag_mobile/main.dart';
import 'package:bftag_mobile/onboarding/onboarding_store.dart';
import 'package:bftag_mobile/push/push_service.dart';
import 'package:bftag_mobile/screens/alarm_screen.dart';
import 'package:bftag_mobile/screens/announcements_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = Person(
  id: 'p1',
  displayName: 'Max M.',
  personType: PersonType.youth,
  permission: Permission.crew,
);

/// Fake [PushService] with fully controllable token/alarm streams, so
/// tests can simulate `onTokenRefresh`/`onAlarmOpened` events without any
/// real platform channel or Firebase.
class _FakePushService implements PushService {
  _FakePushService({this.token, this.initialAlarmIdValue});

  String? token;
  String? initialAlarmIdValue;
  int initCalls = 0;

  final _tokenRefreshController = StreamController<String>.broadcast();
  final _alarmOpenedController = StreamController<String>.broadcast();
  final _announcementOpenedController = StreamController<void>.broadcast();

  @override
  Future<void> init() async {
    initCalls++;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<String?> initialAlarmId() async => initialAlarmIdValue;

  @override
  Stream<String> get onAlarmOpened => _alarmOpenedController.stream;

  @override
  Stream<void> get onTestAlarmReceived => const Stream<void>.empty();

  @override
  Stream<void> get onAnnouncementOpened => _announcementOpenedController.stream;

  void emitTokenRefresh(String newToken) =>
      _tokenRefreshController.add(newToken);

  void emitAlarmOpened(String alarmId) => _alarmOpenedController.add(alarmId);

  void emitAnnouncementOpened() => _announcementOpenedController.add(null);
}

class _FakePushTokenRepository implements PushTokenRepository {
  final List<String> calls = [];

  @override
  Future<void> updatePushToken(String token) async {
    calls.add(token);
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

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  required PairedSessionState session,
  required _FakePushService pushService,
  required _FakePushTokenRepository repository,
  StreamController<Announcement>? announcementCreatedController,
}) async {
  final container = ProviderContainer(
    overrides: [
      pairedSessionControllerProvider.overrideWith(
        () => _FakePairedSessionController(session),
      ),
      pairedRealtimeClientProvider.overrideWith((ref) => null),
      pairedAlarmsProvider.overrideWith((ref) => Stream.value(const [])),
      myCrewAssignmentsProvider.overrideWithValue(const []),
      pushServiceProvider.overrideWithValue(pushService),
      pushTokenRepositoryProvider.overrideWithValue(repository),
      if (announcementCreatedController != null)
        pairedAnnouncementCreatedProvider.overrideWith(
          (ref) => announcementCreatedController.stream,
        ),
      // Not under test here; keep a freshly-Paired session off the
      // Onboarding (ADR 0021) redirect.
      onboardingStoreProvider.overrideWithValue(
        InMemoryOnboardingStore(completed: true),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const BftagMobileApp(),
    ),
  );
  // Not `pumpAndSettle`: `AlarmScreen` shows an indefinitely-animating
  // `CircularProgressIndicator` while its alarm hasn't loaded (it never
  // does here, these tests don't care about its content), which
  // `pumpAndSettle` can never settle past. A few pumps are enough to
  // flush the microtasks `PushRegistrar` schedules (init/getToken/
  // register, initialAlarmId) and the resulting go_router navigation.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
  return container;
}

void main() {
  testWidgets(
    'a paired session registers the token once at start, and again on '
    'onTokenRefresh',
    (tester) async {
      final pushService = _FakePushService(token: 'tok1');
      final repository = _FakePushTokenRepository();

      await _pumpApp(
        tester,
        session: const Paired(_me, 'fake-access-token', 'dev1'),
        pushService: pushService,
        repository: repository,
      );

      expect(pushService.initCalls, 1);
      expect(repository.calls, ['tok1']);

      pushService.emitTokenRefresh('tok2');
      await tester.pump();

      expect(repository.calls, ['tok1', 'tok2']);
    },
  );

  testWidgets('an unpaired device never registers a token', (tester) async {
    final pushService = _FakePushService(token: 'tok1');
    final repository = _FakePushTokenRepository();

    await _pumpApp(
      tester,
      session: const PairedUnpaired(),
      pushService: pushService,
      repository: repository,
    );

    expect(pushService.initCalls, 0);
    expect(repository.calls, isEmpty);
  });

  testWidgets(
    'initialAlarmId navigates to /alarm/:alarmId (cold start from a tap)',
    (tester) async {
      final pushService = _FakePushService(
        token: 'tok1',
        initialAlarmIdValue: 'a1',
      );
      final repository = _FakePushTokenRepository();

      await _pumpApp(
        tester,
        session: const Paired(_me, 'fake-access-token', 'dev1'),
        pushService: pushService,
        repository: repository,
      );

      final alarmScreen = tester.widget<AlarmScreen>(
        find.byType(AlarmScreen),
      );
      expect(alarmScreen.alarmId, 'a1');
    },
  );

  testWidgets(
    'onAlarmOpened navigates to /alarm/:alarmId (tap while backgrounded)',
    (tester) async {
      final pushService = _FakePushService(token: 'tok1');
      final repository = _FakePushTokenRepository();

      await _pumpApp(
        tester,
        session: const Paired(_me, 'fake-access-token', 'dev1'),
        pushService: pushService,
        repository: repository,
      );

      pushService.emitAlarmOpened('a2');
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      final alarmScreen = tester.widget<AlarmScreen>(
        find.byType(AlarmScreen),
      );
      expect(alarmScreen.alarmId, 'a2');
    },
  );

  testWidgets(
    'onAnnouncementOpened navigates to /durchsagen (Durchsage push tap)',
    (tester) async {
      final pushService = _FakePushService(token: 'tok1');
      final repository = _FakePushTokenRepository();

      await _pumpApp(
        tester,
        session: const Paired(_me, 'fake-access-token', 'dev1'),
        pushService: pushService,
        repository: repository,
      );

      pushService.emitAnnouncementOpened();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(find.byType(AnnouncementsScreen), findsOneWidget);
      expect(find.byType(AlarmScreen), findsNothing);
    },
  );

  testWidgets(
    'an alarm-open event does not navigate to /durchsagen, and an '
    'announcement-open event does not navigate to /alarm',
    (tester) async {
      final pushService = _FakePushService(token: 'tok1');
      final repository = _FakePushTokenRepository();

      await _pumpApp(
        tester,
        session: const Paired(_me, 'fake-access-token', 'dev1'),
        pushService: pushService,
        repository: repository,
      );

      pushService.emitAlarmOpened('a3');
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(find.byType(AlarmScreen), findsOneWidget);
      expect(find.byType(AnnouncementsScreen), findsNothing);
    },
  );

  testWidgets(
    'a live announcement.created event shows a SnackBar with an '
    '"Anzeigen" action that navigates to /durchsagen',
    (tester) async {
      final pushService = _FakePushService(token: 'tok1');
      final repository = _FakePushTokenRepository();
      final announcementCreatedController =
          StreamController<Announcement>.broadcast();
      addTearDown(announcementCreatedController.close);

      await _pumpApp(
        tester,
        session: const Paired(_me, 'fake-access-token', 'dev1'),
        pushService: pushService,
        repository: repository,
        announcementCreatedController: announcementCreatedController,
      );

      // Grows the test surface so the SnackBarAction stays within the
      // visible/tappable area at the default test window size.
      final originalSize = tester.view.physicalSize;
      final originalDpr = tester.view.devicePixelRatio;
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalDpr;
      });

      announcementCreatedController.add(
        Announcement(
          id: 'ann1',
          bfDayId: 'day1',
          text: 'Essen ist fertig',
          createdBy: 'p1',
          createdAt: DateTime(2026, 6, 1, 10, 30),
        ),
      );
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(find.text('Durchsage: Essen ist fertig'), findsOneWidget);

      await tester.tap(find.text('Anzeigen'));
      await tester.pumpAndSettle();

      expect(find.byType(AnnouncementsScreen), findsOneWidget);
    },
  );
}
