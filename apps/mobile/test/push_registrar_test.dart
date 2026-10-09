import 'dart:async';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/alarm/pending_alarm.dart';
import 'package:bftag_mobile/main.dart';
import 'package:bftag_mobile/push/push_service.dart';
import 'package:bftag_mobile/screens/alarm_screen.dart';
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

  void emitTokenRefresh(String newToken) =>
      _tokenRefreshController.add(newToken);

  void emitAlarmOpened(String alarmId) => _alarmOpenedController.add(alarmId);
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
}
