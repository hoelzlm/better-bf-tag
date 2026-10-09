import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/alarm_sound.dart';
import 'package:bftag_web/monitor/monitor_platform.dart';
import 'package:bftag_web/monitor/monitor_session.dart';
import 'package:bftag_web/screens/monitor_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records [enableWakeLock]/[requestFullscreen] calls instead of touching
/// real browser APIs (ADR 0012); mirrors monitor_screen_test.dart.
class _FakeMonitorPlatform implements MonitorPlatform {
  @override
  Future<void> enableWakeLock() async {}

  @override
  Future<void> requestFullscreen() async {}
}

/// Records [play] calls instead of touching real audio (ADR 0017).
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

/// A controllable fake [WebSocketConnection] so tests can emit raw
/// `alarm.triggered`/`alarm.acknowledged` protocol messages after the
/// snapshot has loaded (mirrors
/// packages/core/test/realtime_client_alarm_test.dart's `_FakeConnection`).
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

/// Fake [HttpClientAdapter] routing by path (mirrors
/// monitor_screen_test.dart's `_FakeMonitorAdapter`).
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

Map<String, dynamic> _recipientJson({
  required String personId,
  required String displayName,
  String vehicleId = 'v1',
  String function = 'GF',
  bool hasDevice = true,
  String? acknowledgedAt,
}) {
  return {
    'person_id': personId,
    'display_name': displayName,
    'vehicle_id': vehicleId,
    'function': function,
    'has_device': hasDevice,
    'acknowledged_at': acknowledgedAt,
  };
}

Map<String, dynamic> _alarmJson({
  String id = 'a1',
  String incidentId = 'i1',
  String triggeredAt = '2026-10-09T08:00:00Z',
  List<String> vehicleIds = const ['v1'],
  List<Map<String, dynamic>> recipients = const [],
  int pushDelivered = 0,
  int pushRejected = 0,
}) {
  return {
    'id': id,
    'incident_id': incidentId,
    'state': 'triggered',
    'scheduled_at': null,
    'triggered_at': triggeredAt,
    'vehicle_ids': vehicleIds,
    'recipients': recipients,
    'push_delivered': pushDelivered,
    'push_rejected': pushRejected,
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

/// The real backend emits `incident.updated` (state `closed`) before the
/// bare `incident.closed` signal (ADR 0019); the Einsatz/its Alarmierungen
/// are removed on the former, `incident.closed` only drops a leftover
/// Abschlussvorschlag.
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

Future<void> _pumpMonitor(WidgetTester tester, _Env env) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: env.overrides,
      child: const MaterialApp(home: MonitorScreen()),
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
}

void main() {
  testWidgets(
    'standby is shown when no running incident has an alarm',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [_incidentJson()],
        'alarms': <dynamic>[],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.byKey(const Key('monitor-clock-time')), findsOneWidget);
      expect(find.byKey(const Key('monitor-incident-number')), findsNothing);
    },
  );

  testWidgets(
    'shows the Einsatzansicht from the snapshot with number/keyword/'
    'address/Meldebild/recipients/vehicles, without playing the gong',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': [
          _vehicleJson(id: 'v1', shortName: 'HLF 1', status: 3),
        ],
        'incidents': [_incidentJson()],
        'alarms': [
          _alarmJson(
            vehicleIds: ['v1'],
            recipients: [
              _recipientJson(
                personId: 'p1',
                displayName: 'Max M.',
                acknowledgedAt: '2026-10-09T08:01:00Z',
              ),
              _recipientJson(personId: 'p2', displayName: 'Lea K.'),
              _recipientJson(
                personId: 'p3',
                displayName: 'Ben R.',
                hasDevice: false,
              ),
            ],
          ),
        ],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.text('EINSATZ 7'), findsOneWidget);
      expect(find.text('B2 – WOHNUNGSBRAND'), findsOneWidget);
      expect(find.text('Musterstraße 1, Musterstadt'), findsOneWidget);
      expect(
        find.text('Rauchentwicklung aus Fenster, 2. OG, Person vermisst'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('incident-recipient-p1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('incident-recipient-p2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('incident-recipient-p3')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('incident-vehicle-v1')), findsOneWidget);
      expect(find.text('HLF 1'), findsOneWidget);

      // Alarms arriving via the initial snapshot never ring the gong.
      expect(env.alarmSound.playCalls, 0);
    },
  );

  testWidgets(
    'switches from standby to Einsatzansicht and rings the gong exactly '
    'once when a live alarm.triggered arrives',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'bf_day': {
          'id': 'day1',
          'name': 'BF-Tag 2026',
          'starts_at': '2026-10-09T00:00:00Z',
          'ends_at': '2026-10-10T00:00:00Z',
          'state': 'running',
          'created_at': '2026-10-01T00:00:00Z',
        },
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.byKey(const Key('monitor-clock-time')), findsOneWidget);
      expect(env.alarmSound.unlockCalls, 1);

      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 2,
          incident: _incidentJson(bfDayId: 'day1', state: 'running'),
          alarm: _alarmJson(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EINSATZ 7'), findsOneWidget);
      expect(find.byKey(const Key('monitor-clock-time')), findsNothing);
      expect(env.alarmSound.playCalls, 1);

      // A second, unrelated alarm.triggered must not re-ring beyond once
      // per live event.
      env.connector.connections.single.emit(
        _alarmTriggeredEvent(
          seq: 3,
          incident: _incidentJson(
            id: 'i2',
            bfDayId: 'day1',
            number: 8,
            state: 'running',
          ),
          alarm: _alarmJson(id: 'a2', incidentId: 'i2'),
        ),
      );
      await tester.pumpAndSettle();

      expect(env.alarmSound.playCalls, 2);
    },
  );

  testWidgets(
    'no script text appears on the Einsatzansicht',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [_incidentJson()],
        'alarms': [_alarmJson()],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.text('EINSATZ 7'), findsOneWidget);
      expect(find.textContaining('Drehbuch'), findsNothing);
      expect(find.byKey(const Key('monitor-incident-script')), findsNothing);
    },
  );

  testWidgets(
    'returns to standby after incident.closed for the only running Einsatz',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [_incidentJson()],
        'alarms': [_alarmJson()],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.text('EINSATZ 7'), findsOneWidget);
      expect(find.byKey(const Key('monitor-clock-time')), findsNothing);

      env.connector.connections.single.emit(
        _incidentUpdatedClosedEvent(seq: 2, id: 'i1'),
      );
      env.connector.connections.single.emit(
        _incidentClosedEvent(seq: 3, id: 'i1'),
      );
      await tester.pumpAndSettle();

      expect(find.text('EINSATZ 7'), findsNothing);
      expect(find.byKey(const Key('monitor-clock-time')), findsOneWidget);
    },
  );

  testWidgets(
    'with two running Eins\u00e4tze, closing one keeps showing the other',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [
          _incidentJson(id: 'i1', number: 7),
          _incidentJson(id: 'i2', number: 8),
        ],
        'alarms': [
          _alarmJson(id: 'a1', incidentId: 'i1'),
          _alarmJson(id: 'a2', incidentId: 'i2'),
        ],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      // Candidates are sorted by Einsatznummer, so the lower number (7)
      // is shown first, deterministically.
      expect(find.text('EINSATZ 7'), findsOneWidget);

      env.connector.connections.single.emit(
        _incidentUpdatedClosedEvent(seq: 2, id: 'i1', number: 7),
      );
      env.connector.connections.single.emit(
        _incidentClosedEvent(seq: 3, id: 'i1'),
      );
      await tester.pumpAndSettle();

      expect(find.text('EINSATZ 7'), findsNothing);
      expect(find.text('EINSATZ 8'), findsOneWidget);
      expect(find.byKey(const Key('monitor-clock-time')), findsNothing);
    },
  );
}
