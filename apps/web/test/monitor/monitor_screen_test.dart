import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/monitor_clock.dart';
import 'package:bftag_web/monitor/monitor_platform.dart';
import 'package:bftag_web/monitor/monitor_session.dart';
import 'package:bftag_web/screens/monitor_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records [enableWakeLock]/[requestFullscreen] calls instead of touching
/// real browser APIs (ADR 0012).
class _FakeMonitorPlatform implements MonitorPlatform {
  int wakeLockCalls = 0;
  int fullscreenCalls = 0;

  @override
  Future<void> enableWakeLock() async {
    wakeLockCalls++;
  }

  @override
  Future<void> requestFullscreen() async {
    fullscreenCalls++;
  }
}

/// A fake [WebSocketConnection] that never emits anything; sufficient for
/// widget tests that only exercise the pairing/standby flow, not the
/// realtime vehicle updates (covered by the fake-Dio snapshot instead).
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

/// Fake [HttpClientAdapter] routing by path, so the monitor flow can be
/// tested without any real network calls (mirrors
/// packages/core/test/paired_session_test.dart's `_FakeAuthAdapter`).
class _FakeMonitorAdapter implements HttpClientAdapter {
  int pairCalls = 0;
  int refreshCalls = 0;
  int snapshotCalls = 0;
  final List<String> webAuthRefreshPaths = [];

  int pairStatusCode = 200;
  Map<String, dynamic>? pairBody;

  int refreshStatusCode = 200;
  Map<String, dynamic>? refreshBody;

  int snapshotStatusCode = 200;
  Map<String, dynamic> snapshotBody = {'seq': 0, 'vehicles': <dynamic>[]};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/monitor/pair')) {
      pairCalls++;
      return _json(pairStatusCode, pairBody);
    }
    if (options.path.contains('/auth/monitor/refresh')) {
      refreshCalls++;
      return _json(refreshStatusCode, refreshBody);
    }
    if (options.path.contains('/auth/refresh')) {
      // The web admin session's refresh endpoint (no `/monitor/` segment)
      // -- the monitor flow must never call this.
      webAuthRefreshPaths.add(options.path);
      return _json(401, null);
    }
    if (options.path.contains('/snapshot')) {
      snapshotCalls++;
      return _json(snapshotStatusCode, snapshotBody);
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
  required String monitorId,
  String name = 'Gerätehaus',
}) {
  return {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_in': 900,
    'monitor': {'id': monitorId, 'name': name},
  };
}

/// Bundles a [ProviderContainer] wired to a fresh [_FakeMonitorAdapter],
/// [InMemoryTokenStore], and [_FakeMonitorPlatform] for one test.
class _Env {
  _Env({DateTime? clock})
      : adapter = _FakeMonitorAdapter(),
        tokenStore = InMemoryTokenStore(),
        platform = _FakeMonitorPlatform() {
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    overrides = [
      ...monitorProviderOverrides(tokenStore: tokenStore, dio: dio),
      monitorPlatformProvider.overrideWithValue(platform),
      monitorWebSocketConnectorProvider
          .overrideWithValue((uri) => _FakeWsConnection()),
      if (clock != null)
        monitorClockProvider.overrideWith((ref) => Stream.value(clock)),
    ];
  }

  final _FakeMonitorAdapter adapter;
  final InMemoryTokenStore tokenStore;
  final _FakeMonitorPlatform platform;
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

Future<void> _activate(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('monitor-activation-overlay')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'shows the activation overlay and calls enableWakeLock on tap',
    (tester) async {
      final env = _Env();
      await _pumpMonitor(tester, env);

      expect(
        find.text('Zum Aktivieren tippen'),
        findsOneWidget,
      );
      expect(env.platform.wakeLockCalls, 0);

      await _activate(tester);

      expect(env.platform.wakeLockCalls, 1);
      expect(env.platform.fullscreenCalls, 1);
    },
  );

  testWidgets(
    'unpaired -> pairing screen; entering a code pairs with the '
    'normalized code and shows standby',
    (tester) async {
      final env = _Env(clock: DateTime(2026, 10, 9, 9, 41, 7));
      env.adapter.pairBody = _pairResponseBody(
        accessToken: 'at1',
        refreshToken: 'rt1',
        monitorId: 'mon1',
        name: 'Gerätehaus',
      );
      await _pumpMonitor(tester, env);
      await _activate(tester);

      expect(find.text('Monitor koppeln'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('monitor-pairing-code')),
        'abcd-efgh',
      );
      await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
      await tester.pumpAndSettle();

      expect(env.adapter.pairCalls, 1);
      expect(find.byKey(const Key('monitor-clock-time')), findsOneWidget);
      expect(find.text('09:41'), findsOneWidget);

      final stored = await env.tokenStore.read();
      expect(stored, isNotNull);
      expect(stored!.refreshToken, 'rt1');
      expect(stored.deviceId, 'mon1');
    },
  );

  testWidgets('invalid code shows the error text and stays on pairing',
      (tester) async {
    final env = _Env();
    env.adapter.pairStatusCode = 401;
    await _pumpMonitor(tester, env);
    await _activate(tester);

    await tester.enterText(
      find.byKey(const Key('monitor-pairing-code')),
      'ZZZZ-ZZZZ',
    );
    await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Code ungültig oder abgelaufen.'),
      findsOneWidget,
    );
    expect(find.text('Monitor koppeln'), findsOneWidget);
  });

  testWidgets(
    'a stored token with a successful refresh goes directly to standby',
    (tester) async {
      final env = _Env(clock: DateTime(2026, 10, 9, 9, 41, 7));
      await env.tokenStore.write(
        const StoredDeviceSession(refreshToken: 'rt-old', deviceId: 'mon1'),
      );
      env.adapter.refreshBody = _pairResponseBody(
        accessToken: 'at2',
        refreshToken: 'rt-new',
        monitorId: 'mon1',
      );
      await _pumpMonitor(tester, env);
      await _activate(tester);
      await tester.pumpAndSettle();

      expect(env.adapter.refreshCalls, 1);
      expect(find.byKey(const Key('monitor-clock-time')), findsOneWidget);
      expect(find.text('Monitor koppeln'), findsNothing);
    },
  );

  testWidgets(
    'a stored token with a 401 refresh goes to pairing and clears the store',
    (tester) async {
      final env = _Env();
      await env.tokenStore.write(
        const StoredDeviceSession(refreshToken: 'rt-old', deviceId: 'mon1'),
      );
      env.adapter.refreshStatusCode = 401;
      await _pumpMonitor(tester, env);
      await _activate(tester);
      await tester.pumpAndSettle();

      expect(find.text('Monitor koppeln'), findsOneWidget);
      expect(await env.tokenStore.read(), isNull);
    },
  );

  testWidgets('standby shows the vehicle status bar tiles from a snapshot',
      (tester) async {
    final env = _Env(clock: DateTime(2026, 10, 9, 9, 41, 7));
    env.adapter.pairBody = _pairResponseBody(
      accessToken: 'at1',
      refreshToken: 'rt1',
      monitorId: 'mon1',
    );
    env.adapter.snapshotBody = {
      'seq': 1,
      'vehicles': [
        {
          'id': 'v1',
          'call_sign': 'Florian 1',
          'short_name': 'HLF 1',
          'type': 'HLF',
          'status': 2,
          'status_changed_at': null,
          'sort_order': 1,
          'active': true,
        },
      ],
    };
    await _pumpMonitor(tester, env);
    await _activate(tester);
    await tester.enterText(
      find.byKey(const Key('monitor-pairing-code')),
      'ABCDEFGH',
    );
    await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('vehicle-tile-v1')), findsOneWidget);
    expect(find.text('HLF 1'), findsOneWidget);
  });

  testWidgets(
    'standby shows a slide from a fake snapshot (image loader is faked)',
    (tester) async {
      final env = _Env(clock: DateTime(2026, 10, 9, 9, 41, 7));
      env.adapter.pairBody = _pairResponseBody(
        accessToken: 'at1',
        refreshToken: 'rt1',
        monitorId: 'mon1',
      );
      env.adapter.snapshotBody = {
        'seq': 1,
        'vehicles': <dynamic>[],
        'slides': [
          {
            'id': 'sl1',
            'title': 'Hinweis',
            'body': 'Willkommen beim **BF-Tag**',
            'duration_seconds': 10,
            'sort_order': 1,
            'active': true,
            'created_at': '2026-10-01T00:00:00Z',
            'updated_at': '2026-10-01T00:00:00Z',
          },
        ],
      };
      await _pumpMonitor(tester, env);
      await _activate(tester);
      await tester.enterText(
        find.byKey(const Key('monitor-pairing-code')),
        'abcd-efgh',
      );
      await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slide-sl1')), findsOneWidget);
      expect(find.text('Hinweis'), findsOneWidget);
      expect(find.textContaining('Willkommen beim'), findsOneWidget);
    },
  );

  testWidgets('revoked signal shows the pairing screen with the gesperrt '
      'text and clears the store', (tester) async {
    final env = _Env(clock: DateTime(2026, 10, 9, 9, 41, 7));
    env.adapter.pairBody = _pairResponseBody(
      accessToken: 'at1',
      refreshToken: 'rt1',
      monitorId: 'mon1',
    );
    final container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MonitorScreen()),
      ),
    );
    await tester.pump();
    await _activate(tester);
    await tester.enterText(
      find.byKey(const Key('monitor-pairing-code')),
      'ABCDEFGH',
    );
    await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('monitor-clock-time')), findsOneWidget);

    await container
        .read(monitorSessionControllerProvider.notifier)
        .onRevoked();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('monitor-revoked-hint')),
      findsOneWidget,
    );
    expect(find.text('Monitor koppeln'), findsOneWidget);
    expect(await env.tokenStore.read(), isNull);
  });

  testWidgets(
    'connection reconnecting shows the red banner; live hides it',
    (tester) async {
      final env = _Env(clock: DateTime(2026, 10, 9, 9, 41, 7));
      env.adapter.pairBody = _pairResponseBody(
        accessToken: 'at1',
        refreshToken: 'rt1',
        monitorId: 'mon1',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...env.overrides,
            // Stub the vehicle list so no real RealtimeClient is built for
            // this banner-only assertion (avoids a pending watchdog timer).
            vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
            realtimeConnectionProvider.overrideWith(
              (ref) => Stream.value(ConnectionStatus.reconnecting),
            ),
          ],
          child: const MaterialApp(home: MonitorScreen()),
        ),
      );
      await tester.pump();
      await _activate(tester);
      await tester.enterText(
        find.byKey(const Key('monitor-pairing-code')),
        'ABCDEFGH',
      );
      await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('connection-banner-reconnecting')),
        findsOneWidget,
      );
    },
  );

  testWidgets('live connection hides the banner', (tester) async {
    final env = _Env(clock: DateTime(2026, 10, 9, 9, 41, 7));
    env.adapter.pairBody = _pairResponseBody(
      accessToken: 'at1',
      refreshToken: 'rt1',
      monitorId: 'mon1',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...env.overrides,
          vehiclesProvider.overrideWith((ref) => Stream.value(const [])),
          realtimeConnectionProvider.overrideWith(
            (ref) => Stream.value(ConnectionStatus.live),
          ),
        ],
        child: const MaterialApp(home: MonitorScreen()),
      ),
    );
    await tester.pump();
    await _activate(tester);
    await tester.enterText(
      find.byKey(const Key('monitor-pairing-code')),
      'ABCDEFGH',
    );
    await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('connection-banner-reconnecting')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('connection-banner-connecting')),
      findsNothing,
    );
  });

  testWidgets(
    'the monitor flow never calls the web admin /auth/refresh endpoint',
    (tester) async {
      final env = _Env(clock: DateTime(2026, 10, 9, 9, 41, 7));
      await env.tokenStore.write(
        const StoredDeviceSession(refreshToken: 'rt-old', deviceId: 'mon1'),
      );
      env.adapter.refreshBody = _pairResponseBody(
        accessToken: 'at2',
        refreshToken: 'rt-new',
        monitorId: 'mon1',
      );
      await _pumpMonitor(tester, env);
      await _activate(tester);
      await tester.pumpAndSettle();

      expect(env.adapter.webAuthRefreshPaths, isEmpty);
    },
  );
}
