import 'package:bftag_mobile/widgets/main_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> _pump(WidgetTester tester, {int currentIndex = 0}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            MainNavBar(currentIndex: currentIndex),
      ),
      GoRoute(
        path: '/einsaetze',
        builder: (context, state) =>
            MainNavBar(currentIndex: currentIndex),
      ),
      GoRoute(
        path: '/durchsagen',
        builder: (context, state) =>
            MainNavBar(currentIndex: currentIndex),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  return router;
}

void main() {
  testWidgets('has exactly three destinations', (tester) async {
    await _pump(tester);

    expect(find.byKey(const Key('nav-my-vehicle')), findsOneWidget);
    expect(find.byKey(const Key('nav-incidents')), findsOneWidget);
    expect(find.byKey(const Key('nav-announcements')), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).destinations,
      hasLength(3),
    );
  });

  testWidgets('tapping "Durchsagen" navigates to /durchsagen',
      (tester) async {
    final router = await _pump(tester, currentIndex: 0);

    await tester.tap(find.byKey(const Key('nav-announcements')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        '/durchsagen');
  });

  testWidgets('tapping "Fahrzeug" navigates to /', (tester) async {
    final router = await _pump(tester, currentIndex: 2);

    await tester.tap(find.byKey(const Key('nav-my-vehicle')));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/');
  });

  testWidgets('tapping "Einsätze" navigates to /einsaetze', (tester) async {
    final router = await _pump(tester, currentIndex: 0);

    await tester.tap(find.byKey(const Key('nav-incidents')));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/einsaetze',
    );
  });
}
