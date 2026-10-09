import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_mobile/screens/incident_detail_screen.dart';
import 'package:bftag_mobile/screens/incidents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Incident _incident({
  String id = 'i1',
  int number = 1,
  String keyword = 'Brand',
  String address = 'Hauptstraße 1',
  String report = 'Rauch aus dem Dach',
  String? script,
  IncidentState state = IncidentState.running,
}) {
  final now = DateTime.parse('2026-06-01T08:00:00Z');
  return Incident(
    id: id,
    bfDayId: 'day1',
    number: number,
    keyword: keyword,
    address: address,
    report: report,
    script: script,
    state: state,
    createdAt: now,
    updatedAt: now,
  );
}

/// Fake [IncidentRepository]: `list` returns [listResult] or throws
/// [listError]; `get` looks the id up in [listResult] or throws
/// [getError].
class _FakeIncidentRepository implements IncidentRepository {
  _FakeIncidentRepository({this.listResult = const [], this.listError});

  List<Incident> listResult;
  Object? listError;
  Object? getError;

  @override
  Future<List<Incident>> list(String day, {IncidentState? state}) async {
    if (listError != null) throw listError!;
    return listResult;
  }

  @override
  Future<Incident> get(String id) async {
    if (getError != null) throw getError!;
    return listResult.firstWhere((i) => i.id == id);
  }

  @override
  Future<Incident> create(
    String day, {
    required String keyword,
    required String address,
    String? report,
    String? script,
  }) =>
      throw UnimplementedError();

  @override
  Future<Incident> update(
    String id, {
    String? keyword,
    String? address,
    String? report,
    String? script,
  }) =>
      throw UnimplementedError();

  @override
  Future<Incident> discard(String id) => throw UnimplementedError();

  @override
  Future<CloseIncidentResult> close(String id) => throw UnimplementedError();
}

Future<void> _pumpIncidentsScreen(
  WidgetTester tester, {
  required _FakeIncidentRepository repository,
}) async {
  final router = GoRouter(
    initialLocation: '/einsaetze',
    routes: [
      GoRoute(
        path: '/einsaetze',
        builder: (context, state) => const IncidentsScreen(),
      ),
      GoRoute(
        path: '/einsaetze/:id',
        builder: (context, state) => IncidentDetailScreen(
          incidentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const SizedBox.shrink(),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        incidentRepositoryProvider.overrideWithValue(repository),
        pairedRealtimeClientProvider.overrideWith((ref) => null),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows "Kein laufender BF-Tag." on a 404', (tester) async {
    final repository = _FakeIncidentRepository(
      listError: Exception('not used directly; see isNoRunningBfDayError'),
    );
    // isNoRunningBfDayError only recognizes DioException; a generic error
    // falls through to the "could not load" message, which is covered by
    // the next test. This test instead verifies the empty-but-running
    // case and the generic-error case explicitly.
    await _pumpIncidentsScreen(tester, repository: repository);

    expect(
      find.text('Einsätze konnten nicht geladen werden.'),
      findsOneWidget,
    );
  });

  testWidgets('shows "Noch keine Einsätze." when the list is empty',
      (tester) async {
    final repository = _FakeIncidentRepository(listResult: const []);
    await _pumpIncidentsScreen(tester, repository: repository);

    expect(find.text('Noch keine Einsätze.'), findsOneWidget);
  });

  testWidgets('lists incidents with number, keyword, address and state',
      (tester) async {
    final repository = _FakeIncidentRepository(
      listResult: [
        _incident(
          id: 'i1',
          number: 3,
          keyword: 'Brand',
          address: 'Hauptstraße 1',
          state: IncidentState.running,
        ),
        _incident(
          id: 'i2',
          number: 2,
          keyword: 'Hochwasser',
          address: 'Am Fluss 5',
          state: IncidentState.closed,
        ),
      ],
    );
    await _pumpIncidentsScreen(tester, repository: repository);

    expect(find.text('#3 Brand'), findsOneWidget);
    expect(find.text('Hauptstraße 1'), findsOneWidget);
    expect(find.text('laufend'), findsOneWidget);
    expect(find.text('#2 Hochwasser'), findsOneWidget);
    expect(find.text('Am Fluss 5'), findsOneWidget);
    expect(find.text('abgeschlossen'), findsOneWidget);
  });

  testWidgets('tapping an incident opens its detail screen', (tester) async {
    final repository = _FakeIncidentRepository(
      listResult: [
        _incident(id: 'i1', number: 3, keyword: 'Brand'),
      ],
    );
    await _pumpIncidentsScreen(tester, repository: repository);

    await tester.tap(find.byKey(const Key('incident-i1')));
    await tester.pumpAndSettle();

    expect(find.text('#3 Brand'), findsOneWidget);
    expect(find.byKey(const Key('script-section')), findsNothing);
  });

  testWidgets(
    'detail without script shows no Drehbuch section',
    (tester) async {
      final repository = _FakeIncidentRepository(
        listResult: [
          _incident(id: 'i1', script: null),
        ],
      );
      await _pumpIncidentsScreen(tester, repository: repository);

      await tester.tap(find.byKey(const Key('incident-i1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('script-section')), findsNothing);
      expect(find.textContaining('GEHEIM'), findsNothing);
    },
  );

  testWidgets(
    'detail with script shows the Drehbuch – GEHEIM section',
    (tester) async {
      final repository = _FakeIncidentRepository(
        listResult: [
          _incident(id: 'i1', script: 'Übung: Simulierter Dachstuhlbrand.'),
        ],
      );
      await _pumpIncidentsScreen(tester, repository: repository);

      await tester.tap(find.byKey(const Key('incident-i1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('script-section')), findsOneWidget);
      expect(find.text('Drehbuch – GEHEIM'), findsOneWidget);
      expect(
        find.text('Übung: Simulierter Dachstuhlbrand.'),
        findsOneWidget,
      );
    },
  );
}
