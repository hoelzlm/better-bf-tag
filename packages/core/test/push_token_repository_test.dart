import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HttpClientAdapter] that routes by path and returns a canned
/// response, so [ApiPushTokenRepository] can be tested without any real
/// network calls.
class _FakePushTokenAdapter implements HttpClientAdapter {
  int calls = 0;
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  int statusCode = 200;

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
    return ResponseBody.fromString('', statusCode);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiPushTokenRepository', () {
    test('updatePushToken sends PUT /me/device/push-token with {token}',
        () async {
      final adapter = _FakePushTokenAdapter();
      final dio = Dio(BaseOptions(baseUrl: ''));
      dio.httpClientAdapter = adapter;
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);

      final repository = container.read(pushTokenRepositoryProvider);
      await repository.updatePushToken('token-abc');

      expect(adapter.calls, 1);
      expect(adapter.lastMethod, 'PUT');
      expect(adapter.lastPath, contains('/me/device/push-token'));
      expect(adapter.lastBody, {'token': 'token-abc'});
    });
  });
}
