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
  testWidgets(
    'Monitore AC1: lists all monitors with name, status label and '
    '"zuletzt gesehen"',
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
            lastSeenAt: DateTime(2026, 1, 3, 9, 12),
          ),
        ],
      );

      expect(find.text('TV Eingang'), findsOneWidget);
      expect(find.text('nicht gekoppelt · noch nie gesehen'), findsOneWidget);
      expect(find.text('TV Zelt'), findsOneWidget);
      expect(
        find.text('gekoppelt · zuletzt gesehen 03.01.2026 09:12'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Monitore AC2: "Monitor anlegen" calls createMonitor(name:)',
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
    'Monitore AC3: tapping a row opens rename prefilled and calls '
    'updateMonitor(id, name:)',
    (tester) async {
      final repository = await _pump(
        tester,
        monitors: [_monitor(id: 'm1', name: 'Monitor 1')],
      );

      await tester.tap(find.byKey(const Key('monitor-m1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('monitor-form-name')))
            .controller!
            .text,
        'Monitor 1',
      );
      await tester.enterText(
        find.byKey(const Key('monitor-form-name')),
        'Monitor Zelt',
      );
      await tester.tap(find.byKey(const Key('monitor-form-submit')));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, [('m1', 'Monitor Zelt')]);
      expect(find.text('Monitor Zelt'), findsOneWidget);
    },
  );

  testWidgets(
    'Monitore AC4: pairing code button calls createPairingCode(id) and '
    'shows the code dialog with code + Ablaufdatum',
    (tester) async {
      final repository = await _pump(
        tester,
        monitors: [_monitor(id: 'm1', name: 'Monitor 1')],
      );

      await tester.tap(find.byKey(const Key('pairing-code-m1')));
      await tester.pumpAndSettle();

      expect(repository.pairingCodeCalls, ['m1']);
      expect(find.text('ABCD-EFGH'), findsOneWidget);
      expect(find.textContaining('gültig bis'), findsOneWidget);
      expect(find.textContaining('/monitor öffnen'), findsOneWidget);
      expect(find.textContaining('nur einmal angezeigt'), findsOneWidget);
    },
  );

  testWidgets(
    'Monitore AC5: "Sperren" is only visible when isRevoked == false',
    (tester) async {
      await _pump(
        tester,
        monitors: [
          _monitor(id: 'm1', name: 'Aktiv'),
          _monitor(
            id: 'm2',
            name: 'Gesperrt',
            paired: true,
            pairedAt: DateTime(2026, 1, 1),
            revokedAt: DateTime(2026, 1, 2),
          ),
        ],
      );

      expect(find.byKey(const Key('revoke-monitor-m1')), findsOneWidget);
      expect(find.byKey(const Key('revoke-monitor-m2')), findsNothing);
    },
  );

  testWidgets(
    'Monitore AC6: "Sperren" calls revokeMonitor only after confirm',
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
    },
  );

  testWidgets(
    'Monitore AC7: load error shows "Monitore konnten nicht geladen '
    'werden." instead of the list',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monitorAdminRepositoryProvider.overrideWith(
              (ref) => _ThrowingMonitorAdminRepository(),
            ),
          ],
          child: const MaterialApp(home: MonitorsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Monitore konnten nicht geladen werden.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('monitors-list')), findsNothing);
    },
  );

  testWidgets(
    'Monitore AC8: monitors are sorted gekoppelt, nicht gekoppelt, gesperrt',
    (tester) async {
      await _pump(
        tester,
        monitors: [
          _monitor(
            id: 'm-revoked',
            name: 'Gesperrt',
            paired: true,
            pairedAt: DateTime(2026, 1, 1),
            revokedAt: DateTime(2026, 1, 2),
          ),
          _monitor(id: 'm-not-paired', name: 'Nicht gekoppelt'),
          _monitor(
            id: 'm-paired',
            name: 'Gekoppelt',
            paired: true,
            pairedAt: DateTime(2026, 1, 1),
          ),
        ],
      );

      final names = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const Key('monitors-list')),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Text &&
                    ['Gesperrt', 'Nicht gekoppelt', 'Gekoppelt']
                        .contains(w.data),
              ),
            ),
          )
          .map((t) => t.data)
          .toList();

      expect(names, ['Gekoppelt', 'Nicht gekoppelt', 'Gesperrt']);
    },
  );

  testWidgets(
    'Monitore AC9: an empty name field shows an inline error instead of a '
    'silent failure',
    (tester) async {
      final repository = await _pump(tester, monitors: []);

      await tester.tap(find.byKey(const Key('create-monitor')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('monitor-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Name ist erforderlich.'), findsOneWidget);
      expect(repository.createCalls, isEmpty);
      expect(find.byKey(const Key('monitor-form-name')), findsOneWidget);
    },
  );

  testWidgets('Fehlerzustand: empty monitor list shows the empty state',
      (tester) async {
    await _pump(tester, monitors: []);

    expect(find.text('Noch keine Monitore angelegt.'), findsOneWidget);
    expect(find.byKey(const Key('monitors-empty-create')), findsOneWidget);
  });
}

class _ThrowingMonitorAdminRepository implements MonitorAdminRepository {
  @override
  Future<List<Monitor>> listMonitors() async => throw Exception('boom');

  @override
  Future<Monitor> createMonitor({required String name}) =>
      throw UnimplementedError();

  @override
  Future<Monitor> updateMonitor(String id, {required String name}) =>
      throw UnimplementedError();

  @override
  Future<void> revokeMonitor(String id) => throw UnimplementedError();

  @override
  Future<MonitorPairingCode> createPairingCode(String id) =>
      throw UnimplementedError();
}
