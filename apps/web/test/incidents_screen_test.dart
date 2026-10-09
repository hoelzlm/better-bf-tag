import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/incidents_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

BfDay _bfDay({
  String id = 'd1',
  String name = 'BF-Tag 2026',
  BfDayState state = BfDayState.running,
}) {
  return BfDay(
    id: id,
    name: name,
    startsAt: DateTime.now().subtract(const Duration(hours: 1)),
    endsAt: DateTime.now().add(const Duration(hours: 23)),
    state: state,
  );
}

Incident _incident({
  String id = 'i1',
  String bfDayId = 'd1',
  int number = 1,
  String keyword = 'Verkehrsunfall',
  String address = 'Hauptstraße 1',
  String report = 'PKW gegen Baum',
  String? script,
  IncidentState state = IncidentState.draft,
}) {
  return Incident(
    id: id,
    bfDayId: bfDayId,
    number: number,
    keyword: keyword,
    address: address,
    report: report,
    script: script,
    state: state,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

class _FakeBfDayAdminRepository implements BfDayAdminRepository {
  _FakeBfDayAdminRepository({List<BfDay>? days}) : days = days ?? [];

  List<BfDay> days;

  @override
  Future<List<BfDay>> list() async => List.of(days);

  @override
  Future<BfDay> create({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<BfDay> update(
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) =>
      throw UnimplementedError();

  @override
  Future<BfDay> start(String id) => throw UnimplementedError();

  @override
  Future<BfDay> end(String id) => throw UnimplementedError();

  @override
  Future<List<Participant>> listParticipants(String day) async => const [];

  @override
  Future<void> setParticipants(String day, List<String> personIds) =>
      throw UnimplementedError();
}

class _FakeIncidentRepository implements IncidentRepository {
  _FakeIncidentRepository({Map<String, List<Incident>>? incidentsByDay})
      : incidentsByDay = incidentsByDay ?? {};

  Map<String, List<Incident>> incidentsByDay;
  final List<
      ({
        String day,
        String keyword,
        String address,
        String report,
        String? script,
      })> createCalls = [];
  final List<String> discardCalls = [];
  Object? createError;

  @override
  Future<List<Incident>> list(String day, {IncidentState? state}) async {
    final all = List.of(incidentsByDay[day] ?? const <Incident>[]);
    if (state == null) return all;
    return all.where((i) => i.state == state).toList();
  }

  @override
  Future<Incident> get(String id) async {
    for (final list in incidentsByDay.values) {
      for (final i in list) {
        if (i.id == id) return i;
      }
    }
    throw StateError('incident not found: $id');
  }

  @override
  Future<Incident> create(
    String day, {
    required String keyword,
    required String address,
    String? report,
    String? script,
  }) async {
    createCalls.add((
      day: day,
      keyword: keyword,
      address: address,
      report: report ?? '',
      script: script,
    ));
    final error = createError;
    if (error != null) throw error;
    final created = _incident(
      id: 'new-incident',
      bfDayId: day,
      number: (incidentsByDay[day]?.length ?? 0) + 1,
      keyword: keyword,
      address: address,
      report: report ?? '',
      script: script,
      state: IncidentState.draft,
    );
    incidentsByDay[day] = [...(incidentsByDay[day] ?? []), created];
    return created;
  }

  @override
  Future<Incident> update(
    String id, {
    String? keyword,
    String? address,
    String? report,
    String? script,
  }) async {
    for (final entry in incidentsByDay.entries) {
      final idx = entry.value.indexWhere((i) => i.id == id);
      if (idx != -1) {
        final updated = entry.value[idx].copyWith(
          keyword: keyword,
          address: address,
          report: report,
          script: script,
        );
        incidentsByDay[entry.key] = [
          for (final i in entry.value) if (i.id == id) updated else i,
        ];
        return updated;
      }
    }
    throw StateError('incident not found: $id');
  }

  @override
  Future<Incident> discard(String id) async {
    discardCalls.add(id);
    for (final entry in incidentsByDay.entries) {
      final idx = entry.value.indexWhere((i) => i.id == id);
      if (idx != -1) {
        final updated =
            entry.value[idx].copyWith(state: IncidentState.discarded);
        incidentsByDay[entry.key] = [
          for (final i in entry.value) if (i.id == id) updated else i,
        ];
        return updated;
      }
    }
    throw StateError('incident not found: $id');
  }
}

Future<_FakeIncidentRepository> _pump(
  WidgetTester tester, {
  required List<BfDay> days,
  Map<String, List<Incident>>? incidents,
}) async {
  final bfDayRepository = _FakeBfDayAdminRepository(days: days);
  final incidentRepository =
      _FakeIncidentRepository(incidentsByDay: incidents ?? {});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bfDayAdminRepositoryProvider.overrideWithValue(bfDayRepository),
        incidentRepositoryProvider.overrideWithValue(incidentRepository),
      ],
      child: const MaterialApp(home: IncidentsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return incidentRepository;
}

void main() {
  testWidgets('filter switches between shown states', (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [
          _incident(id: 'i1', number: 1, state: IncidentState.draft),
          _incident(id: 'i2', number: 2, state: IncidentState.running),
        ],
      },
    );

    expect(find.text('#1 Verkehrsunfall – Hauptstraße 1'), findsOneWidget);
    expect(find.text('#2 Verkehrsunfall – Hauptstraße 1'), findsNothing);

    await tester.tap(find.text('laufend'));
    await tester.pumpAndSettle();

    expect(find.text('#1 Verkehrsunfall – Hauptstraße 1'), findsNothing);
    expect(find.text('#2 Verkehrsunfall – Hauptstraße 1'), findsOneWidget);
  });

  testWidgets('editor shows script-section with the GEHEIM header',
      (tester) async {
    await _pump(tester, days: [_bfDay()]);

    await tester.tap(find.byKey(const Key('create-incident')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('script-section')), findsOneWidget);
    expect(
      find.text('Drehbuch – GEHEIM, nie für die Mannschaft sichtbar'),
      findsOneWidget,
    );
  });

  testWidgets('discard button only shown for draft incidents',
      (tester) async {
    await _pump(
      tester,
      days: [_bfDay()],
      incidents: {
        'd1': [
          _incident(id: 'i1', number: 1, state: IncidentState.draft),
        ],
      },
    );

    expect(find.byKey(const Key('discard-incident-i1')), findsOneWidget);

    await tester.tap(find.text('laufend'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('discard-incident-i1')), findsNothing);
  });

  testWidgets('create calls repository with entered values', (tester) async {
    final incidentRepository = await _pump(tester, days: [_bfDay()]);

    await tester.tap(find.byKey(const Key('create-incident')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('incident-form-keyword')),
      'Zimmerbrand',
    );
    await tester.enterText(
      find.byKey(const Key('incident-form-address')),
      'Musterweg 5',
    );
    await tester.enterText(
      find.byKey(const Key('incident-form-report')),
      'Rauchentwicklung im 2. OG',
    );
    await tester.enterText(
      find.byKey(const Key('incident-form-script')),
      'Darsteller: 1 Person, leicht verletzt',
    );
    await tester.tap(find.byKey(const Key('incident-form-submit')));
    await tester.pumpAndSettle();

    expect(incidentRepository.createCalls, hasLength(1));
    final call = incidentRepository.createCalls.single;
    expect(call.day, 'd1');
    expect(call.keyword, 'Zimmerbrand');
    expect(call.address, 'Musterweg 5');
    expect(call.report, 'Rauchentwicklung im 2. OG');
    expect(call.script, 'Darsteller: 1 Person, leicht verletzt');
  });
}
