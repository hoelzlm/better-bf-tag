import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/alarm_sound.dart';
import 'package:bftag_web/monitor/announcement_banner.dart';
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

Map<String, dynamic> _announcementJson({
  String id = 'ann1',
  String bfDayId = 'day1',
  String? shiftId,
  String text = 'Essen ist fertig',
  String createdAt = '2026-10-09T08:00:00Z',
}) {
  return {
    'id': id,
    'bf_day_id': bfDayId,
    'shift_id': shiftId,
    'text': text,
    'created_by': 'p1',
    'created_at': createdAt,
  };
}

Map<String, dynamic> _announcementCreatedEvent({
  required int seq,
  required Map<String, dynamic> announcement,
}) {
  return {
    'seq': seq,
    'type': 'announcement.created',
    'at': '2026-10-09T08:00:00Z',
    'data': announcement,
  };
}

Map<String, dynamic> _announcementDeletedEvent({
  required int seq,
  required String id,
}) {
  return {
    'seq': seq,
    'type': 'announcement.deleted',
    'at': '2026-10-09T08:00:00Z',
    'data': {'id': id},
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
    'shows the live banner when announcement.created arrives on standby',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'announcements': <dynamic>[],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.byKey(const Key('announcement-banner')), findsNothing);

      env.connector.connections.single.emit(
        _announcementCreatedEvent(
          seq: 2,
          announcement: _announcementJson(text: 'Essen ist fertig'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('announcement-banner')), findsOneWidget);
      expect(find.text('Essen ist fertig'), findsOneWidget);
    },
  );

  testWidgets(
    'the banner falls back to the Letzte-Durchsage panel after its '
    'duration elapses',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'announcements': <dynamic>[],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _announcementCreatedEvent(
          seq: 2,
          announcement: _announcementJson(text: 'Essen ist fertig'),
        ),
      );
      // The real backend would keep returning the Durchsage in any
      // subsequent snapshot (reconnect/gap resync) for up to 20
      // entries/until a new BF-Tag starts (ADR 0024); mirror that so a
      // resync triggered by the long pump below doesn't wipe it from the
      // fake backend's in-memory state.
      env.adapter.snapshotBody = {
        ...env.adapter.snapshotBody,
        'announcements': [_announcementJson(text: 'Essen ist fertig')],
      };
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('announcement-banner')), findsOneWidget);

      await tester.pump(announcementBannerDuration + const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('announcement-banner')), findsNothing);
      expect(
        find.byKey(const Key('last-announcement-panel')),
        findsOneWidget,
      );
      expect(find.text('Essen ist fertig'), findsOneWidget);
    },
  );

  testWidgets(
    'a live announcement never interrupts the Einsatzansicht',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [_incidentJson()],
        'alarms': [_alarmJson()],
        'announcements': <dynamic>[],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      expect(find.text('EINSATZ 7'), findsOneWidget);

      env.connector.connections.single.emit(
        _announcementCreatedEvent(
          seq: 2,
          announcement: _announcementJson(text: 'Essen ist fertig'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EINSATZ 7'), findsOneWidget);
      expect(find.byKey(const Key('announcement-banner')), findsNothing);
      expect(find.text('Essen ist fertig'), findsNothing);
    },
  );

  testWidgets(
    'a live announcement arriving during an Einsatz does not reappear '
    'once standby returns',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': [_incidentJson()],
        'alarms': [_alarmJson()],
        'announcements': <dynamic>[],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _announcementCreatedEvent(
          seq: 2,
          announcement: _announcementJson(text: 'Essen ist fertig'),
        ),
      );
      await tester.pumpAndSettle();

      env.connector.connections.single.emit({
        'seq': 3,
        'type': 'incident.updated',
        'at': '2026-10-09T08:00:00Z',
        'data': _incidentJson(state: 'closed'),
      });
      env.connector.connections.single.emit({
        'seq': 4,
        'type': 'incident.closed',
        'at': '2026-10-09T08:00:00Z',
        'data': {'id': 'i1'},
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('announcement-banner')), findsNothing);
      // Was never shown for that announcement (it was superseded by the
      // Einsatz), but the "Letzte Durchsage" panel still lists it from
      // the snapshot once reconnected -- not asserted here since no
      // snapshot refetch happens in this test; only the live banner
      // must stay suppressed.
    },
  );

  testWidgets(
    'deleting the currently shown announcement hides the banner '
    'immediately',
    (tester) async {
      final env = _Env();
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'incidents': <dynamic>[],
        'alarms': <dynamic>[],
        'announcements': <dynamic>[],
      };
      await _pumpMonitor(tester, env);
      await _activateAndPair(tester, env);

      env.connector.connections.single.emit(
        _announcementCreatedEvent(
          seq: 2,
          announcement: _announcementJson(id: 'ann1', text: 'Essen fertig'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('announcement-banner')), findsOneWidget);

      env.connector.connections.single.emit(
        _announcementDeletedEvent(seq: 3, id: 'ann1'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('announcement-banner')), findsNothing);
    },
  );
}
