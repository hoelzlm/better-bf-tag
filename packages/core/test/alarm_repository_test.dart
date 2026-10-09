import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HttpClientAdapter] that routes by path and returns a canned JSON
/// response, so [ApiAlarmRepository] can be tested without any real
/// network calls (same pattern as push_token_repository_test.dart).
class _FakeAlarmAdapter implements HttpClientAdapter {
  int calls = 0;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  int statusCode = 200;
  Map<String, dynamic> response = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    lastMethod = options.method;
    lastPath = options.path;
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      if (bytes.isNotEmpty) {
        lastBody = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      }
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _alarmJson({
  String id = 'a1',
  String incidentId = 'i1',
  String state = 'planned',
  String? scheduledAt,
  String? triggeredAt,
  List<String> vehicleIds = const ['v1'],
}) {
  return {
    'id': id,
    'incident_id': incidentId,
    'state': state,
    'scheduled_at': scheduledAt,
    'triggered_at': triggeredAt,
    'vehicle_ids': vehicleIds,
    'recipients': const <Map<String, dynamic>>[],
    'push_delivered': 0,
    'push_rejected': 0,
  };
}

void main() {
  late _FakeAlarmAdapter adapter;
  late ApiAlarmRepository repository;

  setUp(() {
    adapter = _FakeAlarmAdapter();
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    final apiClient = BftagApiClient(dio: dio);
    repository = ApiAlarmRepository(apiClient.getAlarmsApi());
  });

  group('ApiAlarmRepository.plan (ADR 0022)', () {
    test('POST /incidents/{id}/alarms with scheduled_at', () async {
      adapter.response = {
        'alarm': _alarmJson(
          state: 'planned',
          scheduledAt: '2026-10-09T10:08:00.000Z',
        ),
        'double_crewed': const <Map<String, dynamic>>[],
      };

      final alarm = await repository.plan(
        'i1',
        ['v1'],
        id: 'idem-1',
        scheduledAt: DateTime.parse('2026-10-09T10:08:00Z'),
      );

      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, contains('/incidents/i1/alarms'));
      expect(adapter.lastBody?['id'], 'idem-1');
      expect(adapter.lastBody?['vehicle_ids'], ['v1']);
      expect(adapter.lastBody?['scheduled_at'], isNotNull);
      expect(alarm.id, 'a1');
      expect(alarm.state, AlarmState.planned);
      expect(alarm.scheduledAt, DateTime.parse('2026-10-09T10:08:00.000Z'));
    });

    test('POST /incidents/{id}/alarms with offset_minutes', () async {
      adapter.response = {
        'alarm': _alarmJson(
          state: 'planned',
          scheduledAt: '2026-10-09T10:08:00.000Z',
        ),
        'double_crewed': const <Map<String, dynamic>>[],
      };

      await repository.plan('i1', ['v1'], offsetMinutes: 8);

      expect(adapter.lastBody?['offset_minutes'], 8);
      expect(adapter.lastBody?.containsKey('scheduled_at'), isFalse);
      expect(adapter.lastBody?.containsKey('id'), isFalse);
    });
  });

  group('ApiAlarmRepository.update (ADR 0022)', () {
    test('PATCH /alarms/{id} with scheduled_at', () async {
      adapter.response = {
        'alarm': _alarmJson(
          state: 'planned',
          scheduledAt: '2026-10-09T10:20:00.000Z',
        ),
      };

      final alarm = await repository.update(
        'a1',
        scheduledAt: DateTime.parse('2026-10-09T10:20:00Z'),
      );

      expect(adapter.lastMethod, 'PATCH');
      expect(adapter.lastPath, contains('/alarms/a1'));
      expect(adapter.lastBody?['scheduled_at'], isNotNull);
      expect(alarm.scheduledAt, DateTime.parse('2026-10-09T10:20:00.000Z'));
    });

    test('PATCH /alarms/{id} with vehicle_ids', () async {
      adapter.response = {
        'alarm': _alarmJson(state: 'planned', vehicleIds: const ['v2']),
      };

      await repository.update('a1', vehicleIds: ['v2']);

      expect(adapter.lastBody?['vehicle_ids'], ['v2']);
    });
  });

  group('ApiAlarmRepository.discard (ADR 0022)', () {
    test('POST /alarms/{id}/discard', () async {
      adapter.response = {'alarm': _alarmJson(state: 'discarded')};

      final alarm = await repository.discard('a1');

      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, contains('/alarms/a1/discard'));
      expect(alarm.state, AlarmState.discarded);
    });
  });

  group('ApiAlarmRepository.triggerNow (ADR 0022)', () {
    test('POST /alarms/{id}/trigger', () async {
      adapter.response = {
        'alarm': _alarmJson(
          state: 'triggered',
          triggeredAt: '2026-10-09T10:00:00.000Z',
        ),
        'double_crewed': const <Map<String, dynamic>>[],
      };

      final result = await repository.triggerNow('a1');

      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, contains('/alarms/a1/trigger'));
      expect(result.alarm.state, AlarmState.triggered);
      expect(result.doubleCrewed, isEmpty);
    });
  });
}
