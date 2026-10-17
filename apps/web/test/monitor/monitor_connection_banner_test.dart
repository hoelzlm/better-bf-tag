import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/monitor_connection_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'connection_banner_helper.dart';

Future<void> _pumpBanner(WidgetTester tester, ConnectionStatus? status) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: bftagMonitorTheme(),
      home: Scaffold(body: MonitorConnectionBanner(status: status)),
    ),
  );
}

void main() {
  testWidgets('null status shows the connecting banner', (tester) async {
    await _pumpBanner(tester, null);

    expect(
      find.byKey(const Key('connection-banner-connecting')),
      findsOneWidget,
    );
    expect(find.text('Verbinde …'), findsOneWidget);
    expect(
      find.byKey(const Key('connection-banner-reconnecting')),
      findsNothing,
    );
  });

  testWidgets('ConnectionStatus.connecting shows the connecting banner', (
    tester,
  ) async {
    await _pumpBanner(tester, ConnectionStatus.connecting);

    expect(
      find.byKey(const Key('connection-banner-connecting')),
      findsOneWidget,
    );
    final rect = tester.getRect(
      find.byKey(const Key('connection-banner-connecting')),
    );
    expect(rect.height, greaterThanOrEqualTo(56));
  });

  testWidgets('ConnectionStatus.live hides the banner entirely', (
    tester,
  ) async {
    await _pumpBanner(tester, ConnectionStatus.live);

    expect(find.byKey(const Key('connection-banner-connecting')), findsNothing);
    expect(
      find.byKey(const Key('connection-banner-reconnecting')),
      findsNothing,
    );
  });

  testWidgets('ConnectionStatus.reconnecting shows the reconnecting banner, '
      'at least 56 px tall, never alarm/red colored', (tester) async {
    await _pumpBanner(tester, ConnectionStatus.reconnecting);
    await expectReconnectingBannerAtTop(tester);
  });

  testWidgets('ConnectionStatus.revoked also shows the reconnecting banner', (
    tester,
  ) async {
    await _pumpBanner(tester, ConnectionStatus.revoked);

    expect(
      find.byKey(const Key('connection-banner-reconnecting')),
      findsOneWidget,
    );
  });

  testWidgets('text style uses the monitor label scale (>= 22 px)', (
    tester,
  ) async {
    await _pumpBanner(tester, ConnectionStatus.reconnecting);

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('connection-banner-reconnecting')),
        matching: find.byType(Text),
      ),
    );
    expect(text.style?.fontSize, greaterThanOrEqualTo(22));
  });
}
