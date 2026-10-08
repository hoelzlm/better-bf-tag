import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/screens/monitors_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Monitor _monitor({
  String id = 'm1',
  String name = 'Monitor 1',
  bool paired = false,
  DateTime? pairedAt,
  DateTime? lastSeenAt,
  DateTime? revokedAt,
}) {
  return Monitor(
    id: id,
    name: name,
    paired: paired,
    pairedAt: pairedAt,
    lastSeenAt: lastSeenAt,
    revokedAt: revokedAt,
    createdAt: DateTime(2026, 1, 1),
  );
}

class _FakeMonitorAdminRepository implements MonitorAdminRepository {
  _FakeMonitorAdminRepository(this.monitors);

  List<Monitor> monitors;
  final List<String> createCalls = [];
  final List<(String, String)> updateCalls = [];
  final List<String> revokeCalls = [];
  final List<String> pairingCodeCalls = [];

  @override
  Future<List<Monitor>> listMonitors() async => List.of(monitors);

  @override
  Future<Monitor> createMonitor({required String name}) async {
    createCalls.add(name);
    final created = _monitor(id: 'new-${monitors.length}', name: name);
    monitors = [...monitors, created];
    return created;
  }

  @override
  Future<Monitor> updateMonitor(String id, {required String name}) async {
    updateCalls.add((id, name));
    final index = monitors.indexWhere((m) => m.id == id);
    final updated = monitors[index].copyWith(name: name);
    monitors = List.of(monitors)..[index] = updated;
    return updated;
  }

  @override
  Future<void> revokeMonitor(String id) async {
    revokeCalls.add(id);
    final index = monitors.indexWhere((m) => m.id == id);
    monitors = List.of(monitors)
      ..[index] = monitors[index].copyWith(revokedAt: DateTime(2026, 1, 2));
  }

  @override
  Future<MonitorPairingCode> createPairingCode(String id) async {
    pairingCodeCalls.add(id);
    final monitor = monitors.firstWhere((m) => m.id == id);
    return MonitorPairingCode(
      monitorId: id,
      name: monitor.name,
      code: 'ABCD-EFGH',
      expiresAt: DateTime(2026, 1, 1, 15, 30),
    );
  }
}

Future<_FakeMonitorAdminRepository> _pump(
  WidgetTester tester, {
  required List<Monitor> monitors,
}) async {
  final repository = _FakeMonitorAdminRepository(monitors);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        monitorAdminRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: MonitorsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('lists monitors with the three different statuses',
      (tester) async {
    await _pump(
      tester,
      monitors: [
        _monitor(id: 'm1', name: 'TV Eingang', paired: false),
        _monitor(
          id: 'm2',
          name: 'TV Zelt',
          paired: true,
          pairedAt: DateTime(2026, 1, 1),
        ),
        _monitor(
          id: 'm3',
          name: 'TV Lager',
          paired: true,
          pairedAt: DateTime(2026, 1, 1),
          revokedAt: DateTime(2026, 1, 2),
        ),
      ],
    );

    expect(find.text('TV Eingang'), findsOneWidget);
    expect(find.text('nicht gekoppelt · zuletzt gesehen –'), findsOneWidget);
    expect(find.text('TV Zelt'), findsOneWidget);
    expect(find.text('gekoppelt · zuletzt gesehen –'), findsOneWidget);
    expect(find.text('TV Lager'), findsOneWidget);
    expect(find.text('gesperrt · zuletzt gesehen –'), findsOneWidget);
  });

  testWidgets('create dialog calls the API with the entered name',
      (tester) async {
    final repository = await _pump(tester, monitors: []);

    await tester.tap(find.byKey(const Key('create-monitor')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('monitor-form-name')),
      'Zelt-TV',
    );
    await tester.tap(find.byKey(const Key('monitor-form-submit')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, ['Zelt-TV']);
    expect(find.textContaining('Zelt-TV'), findsOneWidget);
  });

  testWidgets(
    'pairing code dialog shows the formatted code and the /monitor hint',
    (tester) async {
      await _pump(tester, monitors: [_monitor(id: 'm1', name: 'Monitor 1')]);

      await tester.tap(find.byKey(const Key('pairing-code-m1')));
      await tester.pumpAndSettle();

      expect(find.text('ABCD-EFGH'), findsOneWidget);
      expect(find.textContaining('gültig bis'), findsOneWidget);
      expect(find.textContaining('/monitor öffnen'), findsOneWidget);
      expect(find.textContaining('nur einmal angezeigt'), findsOneWidget);
    },
  );

  testWidgets('sperren calls revokeMonitor only after confirm',
      (tester) async {
    final repository = await _pump(
      tester,
      monitors: [_monitor(id: 'm1', name: 'Monitor 1')],
    );

    await tester.tap(find.byKey(const Key('revoke-monitor-m1')));
    await tester.pumpAndSettle();

    expect(repository.revokeCalls, isEmpty);

    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();
    expect(repository.revokeCalls, isEmpty);

    await tester.tap(find.byKey(const Key('revoke-monitor-m1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.revokeCalls, ['m1']);
    expect(find.byKey(const Key('revoke-monitor-m1')), findsNothing);
  });
}
