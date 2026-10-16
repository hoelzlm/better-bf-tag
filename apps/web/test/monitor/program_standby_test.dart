import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/alarm_sound.dart';
import 'package:bftag_web/monitor/monitor_clock.dart';
import 'package:bftag_web/monitor/monitor_platform.dart';
import 'package:bftag_web/monitor/monitor_session.dart';
import 'package:bftag_web/screens/monitor_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors monitor_incident_test.dart's fakes -- see that file for
/// rationale.
class _FakeMonitorPlatform implements MonitorPlatform {
  @override
  Future<void> enableWakeLock() async {}

  @override
  Future<void> requestFullscreen() async {}
}

class _FakeAlarmSound implements AlarmSound {
  @override
  Future<void> unlock() async {}

  @override
  Future<void> play({bool loop = false}) async {}

  @override
  Future<void> stop() async {}
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
}

class _FakeWsSink implements WebSocketConnectionSink {
  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
}

class _FakeConnector {
  WebSocketConnection call(Uri uri) => _FakeWsConnection();
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

Map<String, dynamic> _pairResponseBody() {
  return {
    'access_token': 'at1',
    'refresh_token': 'rt1',
    'expires_in': 900,
    'monitor': {'id': 'mon1', 'name': 'Gerätehaus'},
  };
}

Map<String, dynamic> _programItemJson({
  required String id,
  String bfDayId = 'day1',
  required String title,
  String type = 'other',
  required String startsAt,
  required String endsAt,
}) {
  return {
    'id': id,
    'bf_day_id': bfDayId,
    'title': title,
    'type': type,
    'starts_at': startsAt,
    'ends_at': endsAt,
  };
}

Map<String, dynamic> _incidentJson({
  String id = 'i1',
  String bfDayId = 'day1',
  int number = 7,
  String state = 'running',
}) {
  return {
    'id': id,
    'bf_day_id': bfDayId,
    'number': number,
    'keyword': 'B2 – Wohnungsbrand',
    'address': 'Musterstraße 1, Musterstadt',
    'report': 'Rauchentwicklung',
    'state': state,
    'created_at': '2026-10-09T08:00:00Z',
    'updated_at': '2026-10-09T08:00:00Z',
  };
}

Map<String, dynamic> _alarmJson({String id = 'a1', String incidentId = 'i1'}) {
  return {
    'id': id,
    'incident_id': incidentId,
    'state': 'triggered',
    'scheduled_at': null,
    'triggered_at': '2026-10-09T08:00:00Z',
    'vehicle_ids': <String>[],
    'recipients': <dynamic>[],
    'push_delivered': 0,
    'push_rejected': 0,
  };
}

class _Env {
  _Env()
      : adapter = _FakeMonitorAdapter(),
        tokenStore = InMemoryTokenStore(),
        platform = _FakeMonitorPlatform(),
        alarmSound = _FakeAlarmSound(),
        connector = _FakeConnector(),
        clockController = StreamController<DateTime>.broadcast() {
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    overrides = [
      ...monitorProviderOverrides(tokenStore: tokenStore, dio: dio),
      monitorPlatformProvider.overrideWithValue(platform),
      monitorWebSocketConnectorProvider.overrideWithValue(connector.call),
      alarmSoundProvider.overrideWithValue(alarmSound),
      monitorClockProvider.overrideWith((ref) => clockController.stream),
    ];
  }

  final _FakeMonitorAdapter adapter;
  final InMemoryTokenStore tokenStore;
  final _FakeMonitorPlatform platform;
  final _FakeAlarmSound alarmSound;
  final _FakeConnector connector;
  final StreamController<DateTime> clockController;
  late final List<Override> overrides;
}

Future<void> _pumpMonitor(WidgetTester tester, _Env env) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  // Mirrors production nesting (router.dart; PR #31 / commit 7764c01):
  // a root ProviderScope with the `/monitor` scope nested inside.
  await tester.pumpWidget(
    ProviderScope(
      child: ProviderScope(
        overrides: env.overrides,
        child: const MaterialApp(home: MonitorScreen()),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _activateAndPair(WidgetTester tester, _Env env) async {
  env.adapter.pairBody = _pairResponseBody();
  await tester.tap(find.byKey(const Key('monitor-activation-overlay')));
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byKey(const Key('monitor-pairing-code')),
    'ABCDEFGH',
  );
  await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
  await tester.pumpAndSettle();
  // The standby screen only subscribes to monitorClockProvider once
  // mounted; re-emit now that there's a listener.
  env.clockController.add(DateTime.utc(2026, 10, 11, 10, 0, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows the current and next Programmpunkt from the snapshot',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'program_items': [
          _programItemJson(
            id: 'p1',
            title: 'Mittagessen',
            startsAt: '2026-10-11T09:00:00Z',
            endsAt: '2026-10-11T11:00:00Z',
          ),
          _programItemJson(
            id: 'p2',
            title: 'Ausbildung',
            startsAt: '2026-10-11T12:00:00Z',
            endsAt: '2026-10-11T13:00:00Z',
          ),
        ],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.byKey(const Key('monitor-program-current')), findsOneWidget);
      expect(find.textContaining('Mittagessen'), findsOneWidget);
      expect(find.byKey(const Key('monitor-program-next')), findsOneWidget);
      expect(find.textContaining('Ausbildung'), findsOneWidget);
    },
  );

  testWidgets(
    'switches which Programmpunkt is current/next purely from the clock',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'program_items': [
          _programItemJson(
            id: 'p1',
            title: 'Mittagessen',
            startsAt: '2026-10-11T09:00:00Z',
            endsAt: '2026-10-11T11:00:00Z',
          ),
          _programItemJson(
            id: 'p2',
            title: 'Ausbildung',
            startsAt: '2026-10-11T11:00:00Z',
            endsAt: '2026-10-11T13:00:00Z',
          ),
        ],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.textContaining('Mittagessen'), findsOneWidget);
      expect(find.textContaining('Ausbildung'), findsOneWidget);

      // Crosses the boundary (ends_at of p1 == starts_at of p2) without
      // any event -- purely the clock advancing.
      env.clockController.add(DateTime.utc(2026, 10, 11, 12, 0, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('monitor-program-current')), findsOneWidget);
      expect(find.textContaining('Ausbildung'), findsOneWidget);
      expect(find.byKey(const Key('monitor-program-next')), findsNothing);
      expect(find.textContaining('Mittagessen'), findsNothing);
    },
  );

  testWidgets(
    'an overlap picks the Programmpunkt with the latest starts_at as current',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'program_items': [
          _programItemJson(
            id: 'p1',
            title: 'Frühe Ruhe',
            startsAt: '2026-10-11T09:00:00Z',
            endsAt: '2026-10-11T12:00:00Z',
          ),
          _programItemJson(
            id: 'p2',
            title: 'Später begonnene Ausbildung',
            startsAt: '2026-10-11T10:00:00Z',
            endsAt: '2026-10-11T12:00:00Z',
          ),
        ],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.clockController.add(DateTime.utc(2026, 10, 11, 10, 30, 0));
      await tester.pumpAndSettle();

      final currentText = tester
          .widget<Text>(find.byKey(const Key('monitor-program-current')))
          .data;
      expect(currentText, contains('Später begonnene Ausbildung'));
      expect(find.textContaining('Frühe Ruhe'), findsNothing);
    },
  );

  testWidgets(
    'the block is absent when there are no Programmpunkte',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'program_items': <dynamic>[],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.byKey(const Key('program-standby-panel')), findsNothing);
      expect(find.byKey(const Key('monitor-program-current')), findsNothing);
      expect(find.byKey(const Key('monitor-program-next')), findsNothing);
    },
  );

  testWidgets(
    'a running Einsatzansicht still has precedence over the Programmpunkt block',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [_incidentJson()],
        'alarms': [_alarmJson()],
        'program_items': [
          _programItemJson(
            id: 'p1',
            title: 'Mittagessen',
            startsAt: '2026-10-11T09:00:00Z',
            endsAt: '2026-10-11T11:00:00Z',
          ),
        ],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.text('EINSATZ 7'), findsOneWidget);
      expect(find.byKey(const Key('program-standby-panel')), findsNothing);
      expect(find.textContaining('Mittagessen'), findsNothing);
    },
  );
}
