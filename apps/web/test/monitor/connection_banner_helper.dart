import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/monitor/monitor_connection_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared assertions for [MonitorConnectionBanner] embedded in a full
/// monitor screen (standby/incident, cards ux-07 B/C): the reconnecting
/// banner must be found, rendered at the very top of the screen, at
/// least 56 px tall, and must never use the alarm/red colors
/// (Grundprinzip 1 -- a dropped realtime connection is not an Alarm).
Future<void> expectReconnectingBannerAtTop(WidgetTester tester) async {
  final bannerFinder = find.byKey(const Key('connection-banner-reconnecting'));
  expect(bannerFinder, findsOneWidget);

  final bannerRect = tester.getRect(bannerFinder);
  expect(bannerRect.height, greaterThanOrEqualTo(56));
  expect(
    bannerRect.top,
    lessThanOrEqualTo(1),
    reason: 'MonitorConnectionBanner must be the topmost content',
  );

  final container = tester
      .widgetList<Container>(
        find.descendant(of: bannerFinder, matching: find.byType(Container)),
      )
      .first;
  final backgroundColor = container.color;
  expect(backgroundColor, isNotNull);
  expect(backgroundColor, isNot(equals(Colors.red)));

  final theme = Theme.of(tester.element(bannerFinder));
  final alarmColors = theme.extension<BftagAlarmColors>();
  if (alarmColors != null) {
    expect(backgroundColor, isNot(equals(alarmColors.alarm)));
  }
}
