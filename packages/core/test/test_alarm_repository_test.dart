import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HttpClientAdapter] that routes `POST /me/device/test-alarm` to a
/// canned response, so [ApiTestAlarmRepository] can be tested without any
/// real network calls.
class _FakeTestAlarmAdapter implements HttpClientAdapter {
  int calls = 0;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  int statusCode = 200;
  Object? body;

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

void main() {
  group('ApiTestAlarmRepository', () {
    late _FakeTestAlarmAdapter adapter;
    late Dio dio;
    late ProviderContainer container;

    setUp(() {
      adapter = _FakeTestAlarmAdapter();
      dio = Dio(BaseOptions(baseUrl: ''));
      dio.httpClientAdapter = adapter;
      container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
    });

    tearDown(() => container.dispose());

    TestAlarmRepository repo() => container.read(testAlarmRepositoryProvider);

    test('200 delivered -> TestAlarmOutcome.delivered, sends delay_seconds',
        () async {
      adapter.statusCode = 200;
      adapter.body = {'outcome': 'delivered'};

      final outcome = await repo().trigger();

      expect(outcome, TestAlarmOutcome.delivered);
      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, contains('/me/device/test-alarm'));
      expect(adapter.lastBody, {'delay_seconds': 0});
    });

    test('200 rejected -> TestAlarmOutcome.rejected', () async {
      adapter.statusCode = 200;
      adapter.body = {'outcome': 'rejected'};

      final outcome = await repo().trigger();

      expect(outcome, TestAlarmOutcome.rejected);
    });

    test('200 invalid_token -> TestAlarmOutcome.invalidToken', () async {
      adapter.statusCode = 200;
      adapter.body = {'outcome': 'invalid_token'};

      final outcome = await repo().trigger();

      expect(outcome, TestAlarmOutcome.invalidToken);
    });

    test('202 scheduled=true -> TestAlarmOutcome.scheduled', () async {
      adapter.statusCode = 202;
      adapter.body = {'scheduled': true};

      final outcome = await repo().trigger(delaySeconds: 5);

      expect(outcome, TestAlarmOutcome.scheduled);
      expect(adapter.lastBody, {'delay_seconds': 5});
    });

    test('409 no_push_token -> TestAlarmException("no_push_token")',
        () async {
      adapter.statusCode = 409;
      adapter.body = {
        'error': {'code': 'no_push_token', 'message': 'Kein Push-Token.'},
      };

      await expectLater(
        repo().trigger(),
        throwsA(
          isA<TestAlarmException>().having(
            (e) => e.code,
            'code',
            'no_push_token',
          ),
        ),
      );
    });

    test(
        '429 test_alarm_cooldown -> TestAlarmException("test_alarm_cooldown")',
        () async {
      adapter.statusCode = 429;
      adapter.body = {
        'error': {
          'code': 'test_alarm_cooldown',
          'message': 'Bitte warten.',
        },
      };

      await expectLater(
        repo().trigger(),
        throwsA(
          isA<TestAlarmException>().having(
            (e) => e.code,
            'code',
            'test_alarm_cooldown',
          ),
        ),
      );
    });

    test('403 forbidden -> TestAlarmException("forbidden")', () async {
      adapter.statusCode = 403;
      adapter.body = {
        'error': {'code': 'forbidden', 'message': 'Keine Berechtigung.'},
      };

      await expectLater(
        repo().trigger(),
        throwsA(
          isA<TestAlarmException>().having(
            (e) => e.code,
            'code',
            'forbidden',
          ),
        ),
      );
    });

    test('unexpected error shape -> TestAlarmException("unknown")', () async {
      adapter.statusCode = 500;
      adapter.body = {'oops': true};

      await expectLater(
        repo().trigger(),
        throwsA(
          isA<TestAlarmException>().having((e) => e.code, 'code', 'unknown'),
        ),
      );
    });
  });
}
