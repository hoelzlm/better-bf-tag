// Fake-Timer-Tests für den Alarmzustand (`docs/design/screens/
// monitor-alarm.md`, ux-07 D) -- AC 1,2,3,6,7,8,9,10,11,12,13. Mirrors
// monitor_incident_test.dart's fixtures/fakes; see that file for the
// rationale behind `_FakeWsConnection`/`_FakeMonitorAdapter`.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/alarm_sound.dart';
import 'package:bftag_web/monitor/monitor_platform.dart';
import 'package:bftag_web/monitor/monitor_session.dart';
import 'package:bftag_web/screens/monitor_alarm_screen.dart';
import 'package:bftag_web/screens/monitor_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'connection_banner_helper.dart';

class _FakeMonitorPlatform implements MonitorPlatform {
  @override
  Future<void> enableWakeLock() async {}

  @override
  Future<void> requestFullscreen() async {}
}

class _FakeAlarmSound implements AlarmSound {
  int unlockCalls = 0;
  int playCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> unlock() async {
    unlockCalls++;
  }

  @override
  Future<void> play({bool loop = false}) async {
    playCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

class _FakeWsConnection implements WebSocketConnection {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  final _FakeWsSink _sink = _FakeWsSink();

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketConnectionSink get sink => _sink;

  @override
  int? get closeCode => null;

  void emit(Map<String, dynamic> message) {
    _controller.add(message);
  }

  /// Simulates the socket dropping (mirrors monitor_incident_test.dart).
  void disconnect() {
    _controller.close();
  }
}

class _FakeWsSink implements WebSocketConnectionSink {
  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
}

class _FakeConnector {
  final List<_FakeWsConnection> connections = <_FakeWsConnection>[];

  WebSocketConnection call(Uri uri) {
    final connection = _FakeWsConnection();
    connections.add(connection);
    return connection;
  }
}

class _FakeMonitorAdapter implements HttpClientAdapter {
  Map<String, dynamic>? pairBody;
  Map<String, dynamic> snapshotBody = {'seq': 0, 'vehicles': <dynamic>[]};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/monitor/pair')) {
      return _json(200, pairBody);
    }
    if (options.path.contains('/auth/monitor/refresh')) {
      return _json(401, null);
    }
    if (options.path.contains('/snapshot')) {
      return _json(200, snapshotBody);
    }
    throw UnimplementedError('Unhandled path in test: ${options.path}');
  }

  ResponseBody _json(int statusCode, Map<String, dynamic>? body) {
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _pairResponseBody({
  String accessToken = 'at1',
  String refreshToken = 'rt1',
  String monitorId = 'mon1',
  String name = 'Gerätehaus',
}) {
  return {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': 900,
    'monitor': {'id': monitorId, 'name': name},
  };
}

Map<String, dynamic> _incidentJson({
  String id = 'i1',
  String bfDayId = 'day1',
  int number = 7,
  String keyword = 'B2 – Wohnungsbrand',
  String address = 'Musterstraße 1, Musterstadt',
  String report = 'Rauchentwicklung aus Fenster, 2. OG, Person vermisst',
  String state = 'running',
}) {
  return {
    'id': id,
    'bf_day_id': bfDayId,
    'number': number,
    'keyword': keyword,
    'address': address,
    'report': report,
    'state': state,
    'created_at': '2026-10-09T08:00:00Z',
    'updated_at': '2026-10-09T08:00:00Z',
  };
}

Map<String, dynamic> _alarmJson({
  String id = 'a1',
  String incidentId = 'i1',
  String triggeredAt = '2026-10-09T08:00:00Z',
  List<String> vehicleIds = const ['v1'],
  List<Map<String, dynamic>> recipients = const [],
}) {
  return {
    'id': id,
    'incident_id': incidentId,
    'state': 'triggered',
    'scheduled_at': null,
    'triggered_at': triggeredAt,
    'vehicle_ids': vehicleIds,
    'recipients': recipients,
    'push_delivered': 0,
    'push_rejected': 0,
  };
}

Map<String, dynamic> _vehicleJson({
  required String id,
  required String shortName,
  int status = 2,
  int sortOrder = 1,
}) {
  return {
    'id': id,
    'call_sign': shortName,
    'short_name': shortName,
    'type': 'HLF',
    'status': status,
    'status_changed_at': null,
    'sort_order': sortOrder,
    'active': true,
  };
}

const _bfDayJson = {
  'id': 'day1',
  'name': 'BF-Tag 2026',
  'starts_at': '2026-10-09T00:00:00Z',
  'ends_at': '2026-10-10T00:00:00Z',
  'state': 'running',
  'created_at': '2026-10-01T00:00:00Z',
};

Map<String, dynamic> _alarmTriggeredEvent({
  required int seq,
  required Map<String, dynamic> incident,
  required Map<String, dynamic> alarm,
}) {
  return {
    'seq': seq,
    'type': 'alarm.triggered',
    'at': '2026-10-09T08:00:00Z',
    'data': {'incident': incident, 'alarm': alarm},
  };
}

Map<String, dynamic> _incidentClosedEvent({
  required int seq,
  required String id,
}) {
  return {
    'seq': seq,
    'type': 'incident.closed',
    'at': '2026-10-09T08:00:00Z',
    'data': {'id': id},
  };
}

Map<String, dynamic> _incidentUpdatedClosedEvent({
  required int seq,
  required String id,
  int number = 7,
}) {
  return {
    'seq': seq,
    'type': 'incident.updated',
    'at': '2026-10-09T08:00:00Z',
    'data': _incidentJson(id: id, number: number, state: 'closed'),
  };
}

class _Env {
  _Env()
    : adapter = _FakeMonitorAdapter(),
      tokenStore = InMemoryTokenStore(),
      platform = _FakeMonitorPlatform(),
      alarmSound = _FakeAlarmSound(),
      connector = _FakeConnector() {
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    overrides = [
      ...monitorProviderOverrides(tokenStore: tokenStore, dio: dio),
      monitorPlatformProvider.overrideWithValue(platform),
      monitorWebSocketConnectorProvider.overrideWithValue(connector.call),
      alarmSoundProvider.overrideWithValue(alarmSound),
    ];
  }

  final _FakeMonitorAdapter adapter;
  final InMemoryTokenStore tokenStore;
  final _FakeMonitorPlatform platform;
  final _FakeAlarmSound alarmSound;
  final _FakeConnector connector;
  late final List<Override> overrides;
}

Future<void> _pumpMonitor(
  WidgetTester tester,
  _Env env, {
  MediaQueryData? mediaQuery,
}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  Widget app = MaterialApp(
    theme: bftagLightTheme(),
    home: const MonitorScreen(),
  );
  if (mediaQuery != null) {
    app = MediaQuery(data: mediaQuery, child: app);
  }
  await tester.pumpWidget(
    ProviderScope(
      child: ProviderScope(overrides: env.overrides, child: app),
    ),
  );
  await tester.pump();
}

/// Flushes the async WS-message -> RealtimeClient -> provider pipeline
/// without `pumpAndSettle` (which would hang forever against the
/// Alarmzustand badge's intentionally infinite pulse animation).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump();
  }
}

Future<void> _activateAndPair(WidgetTester tester, _Env env) async {
  env.adapter.pairBody = _pairResponseBody();
  await tester.tap(find.byKey(const Key('monitor-activation-overlay')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('monitor-pairing-code')),
    'ABCDEFGH',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a live alarm.triggered shows the Alarmzustand for exactly 20 s, then '
    'automatically switches to MonitorIncidentScreen for the same Einsatz '
    '(AC1)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(),
        ),
      );
      await _settle(tester);

      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);
      expect(find.byKey(const Key('monitor-incident-number')), findsNothing);

      await tester.pump(const Duration(seconds: 19));
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('monitor-alarm-badge')), findsNothing);
      expect(find.byKey(const Key('monitor-incident-number')), findsOneWidget);
      expect(find.text('EINSATZ 7'), findsOneWidget);
    },
  );

  testWidgets(
    'alarms arriving via the initial snapshot never show the Alarmzustand '
    '(AC2)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [_incidentJson()],
        'alarms': [_alarmJson()],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.byKey(const Key('monitor-alarm-badge')), findsNothing);
      expect(find.byKey(const Key('monitor-incident-number')), findsOneWidget);
      expect(env.alarmSound.playCalls, 0);
    },
  );

  testWidgets(
    'badge shows ERSTALARM for the first alarm, N. NACHALARMIERUNG for a '
    'later one on the same Einsatz (AC3)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(id: 'a1', triggeredAt: '2026-10-09T08:00:00Z'),
        ),
      );
      await _settle(tester);

      expect(find.text('ERSTALARM'), findsOneWidget);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 3,
          incident: _incidentJson(),
          alarm: _alarmJson(
            id: 'a2',
            triggeredAt: '2026-10-09T08:05:00Z',
            vehicleIds: ['v2'],
          ),
        ),
      );
      await _settle(tester);

      expect(find.text('1. NACHALARMIERUNG'), findsOneWidget);
    },
  );

  testWidgets(
    'the Alarmzustand background is exactly BftagAlarmColors.alarm (AC4)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(),
        ),
      );
      await _settle(tester);

      final scaffold = tester.widget<Scaffold>(
        find.descendant(
          of: find.byType(MonitorAlarmScreen),
          matching: find.byType(Scaffold),
        ),
      );
      final theme = Theme.of(tester.element(find.byType(MonitorAlarmScreen)));
      final alarmColors = theme.extension<BftagAlarmColors>();
      expect(scaffold.backgroundColor, equals(alarmColors?.alarm));
      expect(scaffold.backgroundColor, isNot(equals(Colors.red)));
    },
  );

  testWidgets('the Stichwort is never smaller than 64 px, even for a very long '
      'keyword (AC5)', (tester) async {
    final env = _Env();
    env.adapter.snapshotBody = {
      'seq': 1,
      'vehicles': <dynamic>[],
      'incidents': <dynamic>[],
      'alarms': <dynamic>[],
      'bf_day': _bfDayJson,
    };
    await _pumpMonitor(tester, env);
    await _activateAndPair(tester, env);

    env.connector.connections.single.emit(
      _alarmTriggeredEvent(
        seq: 2,
        incident: _incidentJson(
          keyword: 'B3 Großbrand mit Menschenrettung im mehrstöckigen Lagerhallenkomplex',
        ),
        alarm: _alarmJson(),
      ),
    );
    await _settle(tester);

    final text = tester.widget<Text>(
      find.byKey(const Key('monitor-alarm-keyword')),
    );
    expect(text.style?.fontSize, greaterThanOrEqualTo(64));
  });

  testWidgets(
    'reduced motion disables the badge icon pulse and the Alarmzustand '
    'appears immediately (AC6)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(
        tester,
        env,
        mediaQuery: const MediaQueryData(disableAnimations: true),
      );
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(),
        ),
      );
      // No fade-in / delay: flushing the WS message (2 frames, same as
      // every other alarm.triggered in this file) must already show the
      // full Alarmzustand -- `pumpAndSettle` is deliberately avoided here
      // since a disabled AnimationController never "settles" by
      // definition once it starts repeating.
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

      final opacityBefore = tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const Key('monitor-alarm-badge')),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      expect(opacityBefore, 1.0);

      await tester.pump(const Duration(milliseconds: 500));
      final opacityAfter = tester
          .widget<Opacity>(
            find.descendant(
              of: find.byKey(const Key('monitor-alarm-badge')),
              matching: find.byType(Opacity),
            ),
          )
          .opacity;
      expect(opacityAfter, 1.0);
    },
  );

  testWidgets(
    'a Nachalarmierung shows only its own newly alarmed vehicles, not the '
    'ones from the previous alarm (AC7)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': [
          _vehicleJson(id: 'v1', shortName: 'HLF 1'),
          _vehicleJson(id: 'v2', shortName: 'RTW 1'),
        ],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(id: 'a1', vehicleIds: ['v1']),
        ),
      );
      await _settle(tester);

      expect(find.byKey(const Key('monitor-alarm-vehicle-v1')), findsOneWidget);
      expect(find.byKey(const Key('monitor-alarm-vehicle-v2')), findsNothing);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 3,
          incident: _incidentJson(),
          alarm: _alarmJson(id: 'a2', vehicleIds: ['v2']),
        ),
      );
      await _settle(tester);

      expect(find.byKey(const Key('monitor-alarm-vehicle-v1')), findsNothing);
      expect(find.byKey(const Key('monitor-alarm-vehicle-v2')), findsOneWidget);
    },
  );

  testWidgets(
    'the gong plays exactly once per alarm.triggered, independent of the '
    'new visual Alarmzustand (AC8)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(),
        ),
      );
      await _settle(tester);
      expect(env.alarmSound.playCalls, 1);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 3,
          incident: _incidentJson(id: 'i2', number: 8),
          alarm: _alarmJson(id: 'a2', incidentId: 'i2'),
        ),
      );
      await _settle(tester);
      expect(env.alarmSound.playCalls, 2);
    },
  );

  testWidgets(
    'a second alarm.triggered for the same Einsatz restarts the 20-s timer '
    '(switch happens at 35 s total, not 20 s) (AC9)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(id: 'a1'),
        ),
      );
      await _settle(tester);
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 3,
          incident: _incidentJson(),
          alarm: _alarmJson(id: 'a2'),
        ),
      );
      await _settle(tester);
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

      // Without the restart this would already have switched at 20 s
      // total; it must still be the loud Alarmzustand at 20 s (=5 s after
      // the second event).
      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

      // At 35 s total (20 s after the restart) it must have switched.
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('monitor-alarm-badge')), findsNothing);
      expect(find.byKey(const Key('monitor-incident-number')), findsOneWidget);
    },
  );

  testWidgets(
    'Meldebild is >= 40 px and vehicle chip names are >= 56 px on the '
    'Alarmzustand (AC10)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': [_vehicleJson(id: 'v1', shortName: 'HLF 1')],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(vehicleIds: ['v1']),
        ),
      );
      await _settle(tester);

      final report = tester.widget<Text>(
        find.byKey(const Key('monitor-alarm-report')),
      );
      expect(report.style?.fontSize, greaterThanOrEqualTo(40));

      final vehicleName = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('monitor-alarm-vehicle-v1')),
              matching: find.byType(Text),
            ),
          )
          .first;
      expect(vehicleName.style?.fontSize, greaterThanOrEqualTo(56));
    },
  );

  testWidgets(
    'closing the Einsatz during the 20-s Alarmzustand aborts the timer '
    'immediately and shows standby when no other alarmed Einsatz remains '
    '(AC11, branch 1)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(),
        ),
      );
      await _settle(tester);
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      env.connector.connections.single.emit(
        _incidentUpdatedClosedEvent(seq: 3, id: 'i1'),
      );
      env.connector.connections.single.emit(
        _incidentClosedEvent(seq: 4, id: 'i1'),
      );
      await _settle(tester);

      expect(find.byKey(const Key('monitor-alarm-badge')), findsNothing);
      expect(find.byKey(const Key('monitor-clock-time')), findsOneWidget);
    },
  );

  testWidgets(
    'closing the Einsatz during the 20-s Alarmzustand jumps straight to '
    'the remaining open alarmed Einsatz\'s MonitorIncidentScreen, not back '
    'into the loud Alarmzustand (AC11, branch 2)',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [_incidentJson(id: 'i2', number: 8)],
        'alarms': [_alarmJson(id: 'a2', incidentId: 'i2')],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(id: 'i1', number: 7),
          alarm: _alarmJson(id: 'a1', incidentId: 'i1'),
        ),
      );
      await _settle(tester);
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);
      expect(find.text('EINSATZ 7'), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      env.connector.connections.single.emit(
        _incidentUpdatedClosedEvent(seq: 3, id: 'i1', number: 7),
      );
      env.connector.connections.single.emit(
        _incidentClosedEvent(seq: 4, id: 'i1'),
      );
      await _settle(tester);

      expect(find.byKey(const Key('monitor-alarm-badge')), findsNothing);
      expect(find.text('EINSATZ 8'), findsOneWidget);
    },
  );

  testWidgets('the 15-s Einsatzansicht rotation does not fire while the 20-s '
      'Alarmzustand is active, and resumes with a full 15 s afterwards '
      '(AC12)', (tester) async {
    final env = _Env();
    env.adapter.snapshotBody = {
      'seq': 1,
      'vehicles': <dynamic>[],
      'incidents': [_incidentJson(id: 'i2', number: 8)],
      'alarms': [_alarmJson(id: 'a2', incidentId: 'i2')],
      'bf_day': _bfDayJson,
    };
    await _pumpMonitor(tester, env);
    await _activateAndPair(tester, env);

    env.connector.connections.single.emit(
      _alarmTriggeredEvent(
        seq: 2,
        incident: _incidentJson(id: 'i1', number: 7),
        alarm: _alarmJson(id: 'a1', incidentId: 'i1'),
      ),
    );
    await _settle(tester);
    expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

    // 15 s pass while the loud Alarmzustand (20 s) is still running --
    // the rotation must not have fired.
    await tester.pump(const Duration(seconds: 15));
    expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

    // The remaining 5 s elapse -> automatic switch to Einsatz 7's
    // MonitorIncidentScreen (not a rotation to Einsatz 8).
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    expect(find.byKey(const Key('monitor-alarm-badge')), findsNothing);
    expect(find.text('EINSATZ 7'), findsOneWidget);

    // The rotation restarts fresh with a full 15 s from here.
    await tester.pump(const Duration(seconds: 14));
    expect(find.text('EINSATZ 7'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('EINSATZ 8'), findsOneWidget);
  });

  testWidgets('the vehicle list on the Alarmzustand comes exactly from the '
      'triggering Alarm.vehicleIds (AC13)', (tester) async {
    final env = _Env();
    env.adapter.snapshotBody = {
      'seq': 1,
      'vehicles': [
        _vehicleJson(id: 'v1', shortName: 'HLF 1'),
        _vehicleJson(id: 'v2', shortName: 'RTW 1'),
        _vehicleJson(id: 'v3', shortName: 'DLK 1'),
      ],
      'incidents': <dynamic>[],
      'alarms': <dynamic>[],
      'bf_day': _bfDayJson,
    };
    await _pumpMonitor(tester, env);
    await _activateAndPair(tester, env);

    env.connector.connections.single.emit(
      _alarmTriggeredEvent(
        seq: 2,
        incident: _incidentJson(),
        alarm: _alarmJson(vehicleIds: ['v1', 'v3']),
      ),
    );
    await _settle(tester);

    expect(find.byKey(const Key('monitor-alarm-vehicle-v1')), findsOneWidget);
    expect(find.byKey(const Key('monitor-alarm-vehicle-v2')), findsNothing);
    expect(find.byKey(const Key('monitor-alarm-vehicle-v3')), findsOneWidget);
  });

  testWidgets(
    'the shared MonitorConnectionBanner appears above the Alarmzustand on '
    'connection loss, without hiding the alarm content',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': _bfDayJson,
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(),
          alarm: _alarmJson(),
        ),
      );
      await _settle(tester);
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);

      env.connector.connections.single.disconnect();
      await _settle(tester);

      await expectReconnectingBannerAtTop(tester);
      expect(find.byKey(const Key('monitor-alarm-badge')), findsOneWidget);
    },
  );
}
