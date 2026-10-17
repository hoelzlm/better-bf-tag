import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/monitor_session.dart';
import 'package:bftag_web/screens/monitor_pairing_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Standalone widget tests for [MonitorPairingScreen] (no activation
/// overlay / `MonitorScreen` involved -- see `monitor_screen_test.dart`
/// for the full-flow coverage), covering
/// `docs/design/screens/monitor-kopplung.md` §6 AC 4-9.

/// Fake [HttpClientAdapter] for `POST /auth/monitor/pair`, with an
/// optional [pairGate] so a test can hold the request open to assert the
/// "Senden" (submitting) UI deterministically, instead of a fixed delay.
class _FakeMonitorAdapter implements HttpClientAdapter {
  int pairCalls = 0;
  int pairStatusCode = 200;
  Map<String, dynamic>? pairBody;
  Object? pairError;
  Completer<void>? pairGate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains('/auth/monitor/pair')) {
      pairCalls++;
      final gate = pairGate;
      if (gate != null) await gate.future;
      final error = pairError;
      if (error != null) throw error;
      return _json(pairStatusCode, pairBody);
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

List<Override> _overrides(_FakeMonitorAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: ''));
  dio.httpClientAdapter = adapter;
  return monitorProviderOverrides(tokenStore: InMemoryTokenStore(), dio: dio);
}

Future<void> _pumpPairing(
  WidgetTester tester,
  List<Override> overrides, {
  bool revokedHint = false,
}) async {
  // The pairing screen targets the 1920x1080 TV layout (concept
  // `docs/design/screens/monitor-kopplung.md` §3) -- the default
  // 800x600 test viewport is too small to fit it.
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      child: ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: bftagMonitorTheme(),
          home: MonitorPairingScreen(revokedHint: revokedHint),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('AC4: code field has the standing label, placeholder, autofocus, '
      'and accepts the existing character mask', (tester) async {
    final adapter = _FakeMonitorAdapter();
    await _pumpPairing(tester, _overrides(adapter));

    final field = tester.widget<TextField>(
      find.byKey(const Key('monitor-pairing-code')),
    );
    expect(field.decoration?.labelText, 'Kopplungscode');
    expect(field.decoration?.hintText, 'ABCD-EFGH');
    expect(field.autofocus, isTrue);

    await tester.enterText(
      find.byKey(const Key('monitor-pairing-code')),
      'abCD-12!@#',
    );
    await tester.pump();
    expect(find.text('abCD-12'), findsOneWidget);
  });

  testWidgets(
    'AC5: submit is disabled when empty and while submitting, shows a '
    'same-size spinner instead of the label while sending',
    (tester) async {
      final adapter = _FakeMonitorAdapter()..pairBody = _pairResponseBody();
      await _pumpPairing(tester, _overrides(adapter));

      var button = tester.widget<FilledButton>(
        find.byKey(const Key('monitor-pairing-submit')),
      );
      expect(button.onPressed, isNull);
      final sizeEmpty = tester.getSize(
        find.byKey(const Key('monitor-pairing-submit')),
      );

      await tester.enterText(
        find.byKey(const Key('monitor-pairing-code')),
        'ABCD-EFGH',
      );
      await tester.pump();
      button = tester.widget<FilledButton>(
        find.byKey(const Key('monitor-pairing-submit')),
      );
      expect(button.onPressed, isNotNull);

      final gate = Completer<void>();
      adapter.pairGate = gate;
      await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      button = tester.widget<FilledButton>(
        find.byKey(const Key('monitor-pairing-submit')),
      );
      expect(button.onPressed, isNull);
      final sizeSubmitting = tester.getSize(
        find.byKey(const Key('monitor-pairing-submit')),
      );
      expect(sizeSubmitting, sizeEmpty);

      gate.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'AC6: error text uses the warning/error token (ColorScheme.error), '
    'never the alarm color',
    (tester) async {
      final adapter = _FakeMonitorAdapter()..pairStatusCode = 401;
      await _pumpPairing(tester, _overrides(adapter));

      await tester.enterText(
        find.byKey(const Key('monitor-pairing-code')),
        'ZZZZ-ZZZZ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('monitor-pairing-submit')));
      await tester.pumpAndSettle();

      final errorFinder = find.byKey(const Key('monitor-pairing-error'));
      expect(errorFinder, findsOneWidget);
      final errorText = tester.widget<Text>(errorFinder);
      final theme = Theme.of(tester.element(errorFinder));
      final alarmColors = theme.extension<BftagAlarmColors>();

      expect(errorText.style?.color, theme.colorScheme.error);
      expect(errorText.style?.color, isNot(equals(alarmColors?.alarm)));
      expect(errorText.style?.color, isNot(equals(Colors.red)));
    },
  );

  test('AC7: source uses no hardcoded Colors.red/orange', () {
    final source = File('lib/screens/monitor_pairing_screen.dart')
        .readAsStringSync();
    expect(RegExp(r'Colors\.red|Colors\.orange').hasMatch(source), isFalse);
  });

  testWidgets('AC8: revoked hint only appears when revokedHint is true, in '
      'onSurfaceVariant, with the unchanged text', (tester) async {
    final adapter = _FakeMonitorAdapter();
    await _pumpPairing(tester, _overrides(adapter));
    expect(find.byKey(const Key('monitor-revoked-hint')), findsNothing);

    await _pumpPairing(tester, _overrides(adapter), revokedHint: true);
    final hintFinder = find.byKey(const Key('monitor-revoked-hint'));
    expect(hintFinder, findsOneWidget);
    expect(
      find.text('Dieser Monitor wurde gesperrt oder neu gekoppelt.'),
      findsOneWidget,
    );
    final hintText = tester.widget<Text>(hintFinder);
    final theme = Theme.of(tester.element(hintFinder));
    expect(hintText.style?.color, theme.colorScheme.onSurfaceVariant);
  });

  testWidgets(
    'AC9: the code field uses the monitor display scale (>= 64 px), the '
    'footer uses the monitor label scale (>= 22 px)',
    (tester) async {
      final adapter = _FakeMonitorAdapter();
      await _pumpPairing(tester, _overrides(adapter));

      final field = tester.widget<TextField>(
        find.byKey(const Key('monitor-pairing-code')),
      );
      expect(field.style?.fontSize, greaterThanOrEqualTo(64));

      final footer = tester.widget<Text>(
        find.text('Gerätename wird nach der Kopplung hier angezeigt.'),
      );
      expect(footer.style?.fontSize, greaterThanOrEqualTo(22));
    },
  );
}
