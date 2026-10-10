import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_provider.dart';

/// Result of [TestAlarmRepository.trigger] (ADR 0021): the backend's
/// `outcome` for an immediate send, or [scheduled] when `delay_seconds > 0`
/// deferred the actual send.
enum TestAlarmOutcome { delivered, rejected, invalidToken, scheduled }

/// A non-2xx `POST /me/device/test-alarm` failure (ADR 0021), carrying the
/// backend's `error.code` so callers can show a specific message:
/// `no_push_token` (409, push isn't set up on this device),
/// `test_alarm_cooldown` (429, another Testalarm is pending or was just
/// sent), `forbidden` (403, not a device session) -- or `unknown` for
/// anything else (network error, unexpected shape).
class TestAlarmException implements Exception {
  const TestAlarmException(this.code);

  final String code;

  @override
  String toString() => 'TestAlarmException($code)';
}

/// Triggers a Testalarm (ADR 0021) on the caller's own device: `POST
/// /me/device/test-alarm`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [AuthApi]/`Dio`.
abstract class TestAlarmRepository {
  /// `POST /me/device/test-alarm` with `{delay_seconds}`. `delaySeconds`
  /// of `0` (the default) sends immediately and resolves with the actual
  /// delivery outcome; a positive value schedules a delayed send on the
  /// backend and resolves with [TestAlarmOutcome.scheduled] as soon as the
  /// backend accepted the request (202), without waiting for the delayed
  /// send itself.
  Future<TestAlarmOutcome> trigger({int delaySeconds = 0});
}

TestAlarmOutcome _outcomeFromWire(TriggerTestAlarm200ResponseOutcomeEnum outcome) {
  switch (outcome) {
    case TriggerTestAlarm200ResponseOutcomeEnum.delivered:
      return TestAlarmOutcome.delivered;
    case TriggerTestAlarm200ResponseOutcomeEnum.rejected:
      return TestAlarmOutcome.rejected;
    case TriggerTestAlarm200ResponseOutcomeEnum.invalidToken:
      return TestAlarmOutcome.invalidToken;
  }
  return TestAlarmOutcome.rejected;
}

/// [TestAlarmRepository] backed by the generated [AuthApi].
///
/// The generated `triggerTestAlarm` only knows how to deserialize the 200
/// response body (the OpenAPI spec's 202 response is a distinct, bodyless
/// shape the generator doesn't surface as an alternative return type), so
/// a successful 202 instead reaches here as a [DioException] wrapping the
/// deserialization failure; this unwraps that case via the response's
/// status code before falling back to the generic 200 decode.
class ApiTestAlarmRepository implements TestAlarmRepository {
  const ApiTestAlarmRepository(this._api);

  final AuthApi _api;

  @override
  Future<TestAlarmOutcome> trigger({int delaySeconds = 0}) async {
    try {
      final response = await _api.triggerTestAlarm(
        triggerTestAlarmRequest: TriggerTestAlarmRequest(
          (b) => b..delaySeconds = delaySeconds,
        ),
      );
      if (response.statusCode == 202) {
        return TestAlarmOutcome.scheduled;
      }
      final outcome = response.data?.outcome;
      if (outcome == null) {
        throw const TestAlarmException('unknown');
      }
      return _outcomeFromWire(outcome);
    } on DioException catch (error) {
      if (error.response?.statusCode == 202) {
        return TestAlarmOutcome.scheduled;
      }
      final data = error.response?.data;
      final errorBody = data is Map ? data['error'] : null;
      final code = errorBody is Map ? errorBody['code'] : null;
      throw TestAlarmException(code is String ? code : 'unknown');
    }
  }
}

final testAlarmRepositoryProvider = Provider<TestAlarmRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiTestAlarmRepository(apiClient.getAuthApi());
});
