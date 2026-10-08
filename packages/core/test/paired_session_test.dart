import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_api_client/bftag_api_client.dart' show PairRequestPlatformEnum;
import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HttpClientAdapter] that routes by path and returns a canned
/// response, so [PairedSessionController] can be tested without any real
/// network calls.
class _FakeAuthAdapter implements HttpClientAdapter {
  int pairCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;
  final List<String?> logoutAuthHeaders = [];

  int pairStatusCode = 200;
  Map<String, dynamic>? pairBody;

  int refreshStatusCode = 200;
  Map<String, dynamic>? refreshBody;

  int logoutStatusCode = 204;
  bool logoutThrowsNetworkError = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/pair')) {
      pairCalls++;
      return _json(pairStatusCode, pairBody);
    }
    if (options.path.contains('/auth/device/refresh')) {
      refreshCalls++;
      return _json(refreshStatusCode, refreshBody);
    }
    if (options.path.contains('/auth/device/logout')) {
      logoutCalls++;
      logoutAuthHeaders.add(options.headers['Authorization'] as String?);
      if (logoutThrowsNetworkError) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return ResponseBody.fromString('', logoutStatusCode);
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
  required String accessToken,
  required String refreshToken,
  required String deviceId,
  String displayName = 'Max M.',
}) {
  return {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': 900,
    'device_id': deviceId,
    'person': {
      'id': 'p1',
      'display_name': displayName,
      'person_type': 'youth',
      'permission': 'crew',
    },
  };
}

/// Bundles a [ProviderContainer] wired to a fresh [_FakeAuthAdapter] and
/// [InMemoryTokenStore] for one test.
class _Env {
  _Env()
      : adapter = _FakeAuthAdapter(),
        tokenStore = InMemoryTokenStore() {
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        tokenStoreProvider.overrideWithValue(tokenStore),
      ],
    );
  }

  final _FakeAuthAdapter adapter;
  final InMemoryTokenStore tokenStore;
  late final ProviderContainer container;

  PairedSessionController get controller =>
      container.read(pairedSessionControllerProvider.notifier);

  PairedSessionState get state => container.read(pairedSessionControllerProvider);

  void dispose() => container.dispose();
}

void main() {
  group('normalizePairingCode', () {
    test('uppercases and strips spaces/hyphens', () {
      expect(normalizePairingCode('abcd-efgh'), 'ABCDEFGH');
      expect(normalizePairingCode('ab cd ef gh'), 'ABCDEFGH');
      expect(normalizePairingCode('ABCD-EFGH'), 'ABCDEFGH');
    });
  });

  group('PairedSessionController', () {
    test('pair success persists the token and transitions to Paired',
        () async {
      final env = _Env();
      addTearDown(env.dispose);
      env.adapter.pairBody = _pairResponseBody(
        accessToken: 'at1',
        refreshToken: 'rt1',
        deviceId: 'dev1',
      );

      await env.controller.pair(
        'abcd-efgh',
        platform: PairRequestPlatformEnum.android,
        appVersion: '1.0.0',
      );

      expect(env.adapter.pairCalls, 1);
      final state = env.state;
      expect(state, isA<Paired>());
      expect((state as Paired).accessToken, 'at1');
      expect(state.deviceId, 'dev1');
      expect(state.person.displayName, 'Max M.');

      final stored = await env.tokenStore.read();
      expect(stored, isNotNull);
      expect(stored!.refreshToken, 'rt1');
      expect(stored.deviceId, 'dev1');
    });

    test('invalid code throws PairingFailure and does not persist anything',
        () async {
      final env = _Env();
      addTearDown(env.dispose);
      env.adapter.pairStatusCode = 401;

      await expectLater(
        env.controller.pair(
          'ABCD-EFGH',
          platform: PairRequestPlatformEnum.android,
          appVersion: '1.0.0',
        ),
        throwsA(
          isA<PairingFailure>().having(
            (f) => f.message,
            'message',
            'Code ungültig oder abgelaufen.',
          ),
        ),
      );
      expect(await env.tokenStore.read(), isNull);
    });

    test('restore with a stored token refreshes and transitions to Paired',
        () async {
      final env = _Env();
      addTearDown(env.dispose);
      await env.tokenStore.write(
        const StoredDeviceSession(refreshToken: 'rt-old', deviceId: 'dev1'),
      );
      env.adapter.refreshBody = _pairResponseBody(
        accessToken: 'at2',
        refreshToken: 'rt-new',
        deviceId: 'dev1',
      );

      await env.controller.restore();

      expect(env.adapter.refreshCalls, 1);
      expect(env.state, isA<Paired>());
      final stored = await env.tokenStore.read();
      expect(stored!.refreshToken, 'rt-new');
    });

    test('restore with an invalid refresh token clears the store', () async {
      final env = _Env();
      addTearDown(env.dispose);
      await env.tokenStore.write(
        const StoredDeviceSession(refreshToken: 'rt-old', deviceId: 'dev1'),
      );
      env.adapter.refreshStatusCode = 401;

      await env.controller.restore();

      expect(env.state, isA<PairedUnpaired>());
      expect(await env.tokenStore.read(), isNull);
    });

    test('restore on a network error keeps the stored token (PairedOffline)',
        () async {
      final env = _Env();
      addTearDown(env.dispose);
      await env.tokenStore.write(
        const StoredDeviceSession(refreshToken: 'rt-old', deviceId: 'dev1'),
      );
      env.adapter.refreshStatusCode = 503;

      await env.controller.restore();

      expect(env.state, isA<PairedOffline>());
      final stored = await env.tokenStore.read();
      expect(stored!.refreshToken, 'rt-old', reason: 'must not be cleared');
    });

    test('refresh rotates and persists the refresh token', () async {
      final env = _Env();
      addTearDown(env.dispose);
      env.adapter.pairBody = _pairResponseBody(
        accessToken: 'at1',
        refreshToken: 'rt1',
        deviceId: 'dev1',
      );
      await env.controller.pair(
        'ABCDEFGH',
        platform: PairRequestPlatformEnum.android,
        appVersion: '1.0.0',
      );

      env.adapter.refreshBody = _pairResponseBody(
        accessToken: 'at2',
        refreshToken: 'rt2',
        deviceId: 'dev1',
      );
      final newToken = await env.controller.refresh();

      expect(newToken, 'at2');
      expect(env.adapter.refreshCalls, 1);
      final stored = await env.tokenStore.read();
      expect(stored!.refreshToken, 'rt2');
    });

    test('logout clears the store even when the request fails', () async {
      final env = _Env();
      addTearDown(env.dispose);
      env.adapter.pairBody = _pairResponseBody(
        accessToken: 'at1',
        refreshToken: 'rt1',
        deviceId: 'dev1',
      );
      await env.controller.pair(
        'ABCDEFGH',
        platform: PairRequestPlatformEnum.android,
        appVersion: '1.0.0',
      );
      env.adapter.logoutThrowsNetworkError = true;

      await env.controller.logout();

      expect(env.adapter.logoutCalls, 1);
      expect(env.adapter.logoutAuthHeaders.single, 'Bearer at1');
      expect(env.state, isA<PairedUnpaired>());
      expect(await env.tokenStore.read(), isNull);
    });

    test('onRevoked clears the store and transitions to Unpaired', () async {
      final env = _Env();
      addTearDown(env.dispose);
      env.adapter.pairBody = _pairResponseBody(
        accessToken: 'at1',
        refreshToken: 'rt1',
        deviceId: 'dev1',
      );
      await env.controller.pair(
        'ABCDEFGH',
        platform: PairRequestPlatformEnum.android,
        appVersion: '1.0.0',
      );

      await env.controller.onRevoked();

      expect(env.state, isA<PairedUnpaired>());
      expect((env.state as PairedUnpaired).revoked, isTrue);
      expect(await env.tokenStore.read(), isNull);
    });
  });
}
