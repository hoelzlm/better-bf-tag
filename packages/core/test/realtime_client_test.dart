import 'dart:async';
import 'dart:math';

import 'package:bftag_core/bftag_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

/// A [Random] that always returns 0, so backoff delays in tests are exact
/// (no jitter) and therefore trivially assertable.
class _ZeroRandom implements Random {
  @override
  double nextDouble() => 0.0;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

class _FakeSink implements WebSocketConnectionSink {
  bool closed = false;
  int? closeCodeUsed;

  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
    closeCodeUsed = closeCode;
  }
}

class _FakeConnection implements WebSocketConnection {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  final _FakeSink _sink = _FakeSink();
  int? _closeCode;

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketConnectionSink get sink => _sink;

  @override
  int? get closeCode => _closeCode;

  void emit(Map<String, dynamic> message) {
    _controller.add(message);
  }

  /// Simulates the server closing the connection with [code].
  void closeWithCode(int code) {
    _closeCode = code;
    unawaited(_controller.close());
  }
}

class _FakeConnector {
  final List<_FakeConnection> connections = <_FakeConnection>[];

  WebSocketConnection call(Uri uri) {
    final connection = _FakeConnection();
    connections.add(connection);
    return connection;
  }
}

Vehicle _vehicle({
  String id = 'v1',
  String callSign = 'Florian 1',
  String shortName = 'HLF 1',
  int status = 2,
  int sortOrder = 1,
  bool active = true,
}) {
  return Vehicle(
    id: id,
    callSign: callSign,
    shortName: shortName,
    type: 'HLF',
    status: FmsStatus.fromCode(status),
    statusChangedAt: null,
    sortOrder: sortOrder,
    active: active,
  );
}

Map<String, dynamic> _statusChangedEvent({
  required int seq,
  required String vehicleId,
  required int status,
}) {
  return {
    'seq': seq,
    'type': 'vehicle.status_changed',
    'at': '2026-10-08T18:00:00Z',
    'data': {'vehicle_id': vehicleId, 'status': status, 'source': 'app'},
  };
}

Map<String, dynamic> _vehicleUpdatedEvent({
  required int seq,
  required Vehicle vehicle,
}) {
  return {
    'seq': seq,
    'type': 'vehicle.updated',
    'at': '2026-10-08T18:00:00Z',
    'data': {
      'id': vehicle.id,
      'call_sign': vehicle.callSign,
      'short_name': vehicle.shortName,
      'type': vehicle.type,
      'status': vehicle.status.code,
      'status_changed_at': null,
      'sort_order': vehicle.sortOrder,
      'active': vehicle.active,
    },
  };
}

BfDay _bfDay({
  String id = 'day1',
  String name = 'BF-Tag',
  BfDayState state = BfDayState.running,
}) {
  return BfDay(
    id: id,
    name: name,
    startsAt: DateTime.parse('2026-06-01T00:00:00Z'),
    endsAt: DateTime.parse('2026-06-02T00:00:00Z'),
    state: state,
  );
}

Shift _shift({
  String id = 'shift1',
  String bfDayId = 'day1',
  String name = 'Tagschicht',
  List<CrewAssignment> crew = const [],
}) {
  return Shift(
    id: id,
    bfDayId: bfDayId,
    name: name,
    startsAt: DateTime.parse('2026-06-01T08:00:00Z'),
    endsAt: DateTime.parse('2026-06-01T20:00:00Z'),
    crew: crew,
  );
}

Map<String, dynamic> _shiftJson(Shift shift) {
  return {
    'id': shift.id,
    'bf_day_id': shift.bfDayId,
    'name': shift.name,
    'starts_at': shift.startsAt.toIso8601String(),
    'ends_at': shift.endsAt.toIso8601String(),
    'crew': shift.crew
        .map(
          (c) => {
            'vehicle_id': c.vehicleId,
            'person_id': c.personId,
            'display_name': c.displayName,
            'function': c.function,
          },
        )
        .toList(),
  };
}

Map<String, dynamic> _shiftCrewChangedEvent({
  required int seq,
  required Shift shift,
}) {
  return {
    'seq': seq,
    'type': 'shift.crew_changed',
    'at': '2026-10-08T18:00:00Z',
    'data': _shiftJson(shift),
  };
}

Map<String, dynamic> _shiftDeletedEvent({
  required int seq,
  required String id,
  required String bfDayId,
}) {
  return {
    'seq': seq,
    'type': 'shift.deleted',
    'at': '2026-10-08T18:00:00Z',
    'data': {'id': id, 'bf_day_id': bfDayId},
  };
}

Map<String, dynamic> _bfDayUpdatedEvent({
  required int seq,
  required BfDay bfDay,
}) {
  return {
    'seq': seq,
    'type': 'bf_day.updated',
    'at': '2026-10-08T18:00:00Z',
    'data': {
      'id': bfDay.id,
      'name': bfDay.name,
      'starts_at': bfDay.startsAt.toIso8601String(),
      'ends_at': bfDay.endsAt.toIso8601String(),
      'state': bfDay.state.name,
    },
  };
}

Incident _incident({
  String id = 'i1',
  String bfDayId = 'day1',
  int number = 1,
  IncidentState state = IncidentState.draft,
  String? script,
}) {
  return Incident(
    id: id,
    bfDayId: bfDayId,
    number: number,
    keyword: 'Verkehrsunfall',
    address: 'Hauptstraße 1',
    report: 'PKW gegen Baum',
    script: script,
    state: state,
    createdAt: DateTime.parse('2026-10-08T18:00:00Z'),
    updatedAt: DateTime.parse('2026-10-08T18:00:00Z'),
  );
}

Map<String, dynamic> _incidentJson(Incident incident) {
  return incident.toJson();
}

Map<String, dynamic> _incidentCreatedEvent({
  required int seq,
  required Incident incident,
}) {
  return {
    'seq': seq,
    'type': 'incident.created',
    'at': '2026-10-08T18:00:00Z',
    'data': _incidentJson(incident),
  };
}

Map<String, dynamic> _incidentUpdatedEvent({
  required int seq,
  required Incident incident,
}) {
  return {
    'seq': seq,
    'type': 'incident.updated',
    'at': '2026-10-08T18:00:00Z',
    'data': _incidentJson(incident),
  };
}

/// Builds a [RealtimeClient] wired to a fresh [_FakeConnector] and a
/// snapshot loader whose completers are collected in [snapshotCompleters]
/// (one appended per call, in order) so tests can control exactly when
/// each snapshot load resolves.
RealtimeClient _buildClient({
  required List<Completer<Snapshot>> snapshotCompleters,
  required _FakeConnector connector,
  Future<void> Function()? refreshSession,
  Duration heartbeatInterval = const Duration(seconds: 10),
  Duration Function(int, Random)? backoff,
}) {
  return RealtimeClient(
    wsEndpoint: Uri.parse('ws://api.test/ws'),
    loadSnapshot: () {
      final completer = Completer<Snapshot>();
      snapshotCompleters.add(completer);
      return completer.future;
    },
    accessToken: () async => 'token-123',
    refreshSession: refreshSession ?? () async {},
    connector: connector.call,
    heartbeatInterval: heartbeatInterval,
    random: _ZeroRandom(),
    backoff: backoff,
  );
}

void main() {
  group('RealtimeClient', () {
    test(
      'buffers pre-snapshot events, dedups by seq, applies status change',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client =
              _buildClient(snapshotCompleters: completers, connector: connector);
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();

          expect(connector.connections, hasLength(1));
          final conn = connector.connections.single;

          // Arrive before the snapshot resolves: must be buffered, not
          // applied yet.
          conn.emit({'type': 'hello', 'seq': 10});
          conn.emit(
            _statusChangedEvent(seq: 11, vehicleId: 'v1', status: 3),
          );
          // A duplicate of seq 11: once replayed after the snapshot, it
          // must be dropped (already applied) rather than applied twice.
          conn.emit(
            _statusChangedEvent(seq: 11, vehicleId: 'v1', status: 5),
          );
          async.flushMicrotasks();

          expect(states, isEmpty, reason: 'nothing applied before snapshot');

          completers.single.complete(
            Snapshot(seq: 10, vehicles: [_vehicle(status: 2)]),
          );
          async.flushMicrotasks();

          expect(completers, hasLength(1));
          final latest = states.last;
          expect(latest.seq, 11);
          expect(latest.status, ConnectionStatus.live);
          expect(latest.vehicles.single.status, FmsStatus.s3);

          client.dispose();
        });
      },
    );

    test('gap reloads the snapshot exactly once', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0]
            .complete(Snapshot(seq: 10, vehicles: [_vehicle(status: 2)]));
        async.flushMicrotasks();
        expect(completers, hasLength(1));

        final conn = connector.connections.single;
        // Gap: expected seq 11, this is 15. Multiple gap messages in a row
        // must still only trigger a single reload.
        conn.emit(_statusChangedEvent(seq: 15, vehicleId: 'v1', status: 3));
        conn.emit(_statusChangedEvent(seq: 16, vehicleId: 'v1', status: 4));
        async.flushMicrotasks();

        expect(completers, hasLength(2), reason: 'exactly one reload');

        completers[1]
            .complete(Snapshot(seq: 15, vehicles: [_vehicle(status: 3)]));
        async.flushMicrotasks();

        // The second buffered message (seq 16) is a valid continuation of
        // the reloaded snapshot (15+1) and is replayed after the reload.
        expect(states.last.seq, 16);
        expect(states.last.vehicles.single.status, FmsStatus.s4);

        client.dispose();
      });
    });

    test('skip advances seq without changing vehicles', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0]
            .complete(Snapshot(seq: 10, vehicles: [_vehicle(status: 2)]));
        async.flushMicrotasks();

        connector.connections.single.emit({'seq': 11, 'type': 'skip'});
        async.flushMicrotasks();

        expect(completers, hasLength(1), reason: 'skip must not reload');
        expect(states.last.seq, 11);
        expect(states.last.vehicles.single.status, FmsStatus.s2);

        client.dispose();
      });
    });

    test('unknown event type advances seq without breaking it', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0]
            .complete(Snapshot(seq: 10, vehicles: [_vehicle(status: 2)]));
        async.flushMicrotasks();

        connector.connections.single.emit({
          'seq': 11,
          'type': 'incident.closed',
          'at': '2026-10-08T18:00:00Z',
          'data': {'id': 'i1'},
        });
        async.flushMicrotasks();

        expect(completers, hasLength(1), reason: 'unknown type must not reload');
        expect(states.last.seq, 11);

        client.dispose();
      });
    });

    test('heartbeat seq mismatch reloads the snapshot', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);

        client.start();
        async.flushMicrotasks();
        completers[0]
            .complete(Snapshot(seq: 10, vehicles: [_vehicle(status: 2)]));
        async.flushMicrotasks();

        connector.connections.single.emit({'type': 'heartbeat', 'seq': 12});
        async.flushMicrotasks();

        expect(completers, hasLength(2));
        completers[1].complete(Snapshot(seq: 12, vehicles: []));
        async.flushMicrotasks();

        client.dispose();
      });
    });

    test('inactive vehicle.updated removes the vehicle', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: [
              _vehicle(id: 'v1', sortOrder: 1),
              _vehicle(id: 'v2', sortOrder: 2),
            ],
          ),
        );
        async.flushMicrotasks();
        expect(states.last.vehicles, hasLength(2));

        connector.connections.single.emit(
          _vehicleUpdatedEvent(
            seq: 11,
            vehicle: _vehicle(id: 'v1', sortOrder: 1, active: false),
          ),
        );
        async.flushMicrotasks();

        expect(states.last.vehicles, hasLength(1));
        expect(states.last.vehicles.single.id, 'v2');

        client.dispose();
      });
    });

    test(
      'silence for 2x heartbeatInterval triggers reconnect with growing, '
      'capped backoff',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final delays = <int>[];
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
            heartbeatInterval: const Duration(seconds: 1),
            backoff: (attempt, random) {
              final seconds = attempt == 0
                  ? 1
                  : attempt == 1
                      ? 2
                      : attempt == 2
                          ? 4
                          : 30;
              delays.add(seconds);
              return Duration(seconds: seconds);
            },
          );

          client.start();
          async.flushMicrotasks();
          completers[0].complete(Snapshot(seq: 10, vehicles: []));
          async.flushMicrotasks();
          expect(connector.connections, hasLength(1));

          // Silence for > 2x the 1s heartbeat interval: watchdog fires.
          async.elapse(const Duration(seconds: 3));
          expect(connector.connections, hasLength(2));
          completers[1].complete(Snapshot(seq: 10, vehicles: []));
          async.flushMicrotasks();

          // Silence again: backoff attempt #2 (2s).
          async.elapse(const Duration(seconds: 3));
          expect(connector.connections, hasLength(3));
          completers[2].complete(Snapshot(seq: 10, vehicles: []));
          async.flushMicrotasks();

          // A successful snapshot resets the backoff counter, so the next
          // silence reconnect is attempt #0 (1s) again, not #2 (4s).
          expect(delays, [1, 1]);

          client.dispose();
        });
      },
    );

    test('close code 4401 refreshes the session before reconnecting', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        var refreshCalls = 0;
        final refreshCompleter = Completer<void>();
        final client = _buildClient(
          snapshotCompleters: completers,
          connector: connector,
          refreshSession: () {
            refreshCalls++;
            return refreshCompleter.future;
          },
        );

        client.start();
        async.flushMicrotasks();
        completers[0].complete(Snapshot(seq: 10, vehicles: []));
        async.flushMicrotasks();

        connector.connections.single.closeWithCode(4401);
        async.flushMicrotasks();

        expect(refreshCalls, 1);
        expect(
          connector.connections,
          hasLength(1),
          reason: 'must not reconnect before refreshSession resolves',
        );

        refreshCompleter.complete();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));

        expect(connector.connections, hasLength(2));
        completers[1].complete(Snapshot(seq: 10, vehicles: []));
        async.flushMicrotasks();

        client.dispose();
      });
    });

    test(
      'session.revoked message stops the client without reconnecting',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          var revokedCalls = 0;
          final client = RealtimeClient(
            wsEndpoint: Uri.parse('ws://api.test/ws'),
            loadSnapshot: () {
              final completer = Completer<Snapshot>();
              completers.add(completer);
              return completer.future;
            },
            accessToken: () async => 'token-123',
            refreshSession: () async {},
            onRevoked: () => revokedCalls++,
            connector: connector.call,
            heartbeatInterval: const Duration(seconds: 10),
            random: _ZeroRandom(),
          );
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();
          completers[0].complete(Snapshot(seq: 10, vehicles: [_vehicle()]));
          async.flushMicrotasks();

          connector.connections.single.emit({'type': 'session.revoked'});
          async.flushMicrotasks();

          expect(revokedCalls, 1);
          expect(states.last.status, ConnectionStatus.revoked);
          expect((connector.connections.single.sink as _FakeSink).closed, isTrue);

          // The server also closes with 4403; must stay revoked, no
          // reconnect, and the callback must not fire a second time.
          connector.connections.single.closeWithCode(4403);
          async.flushMicrotasks();
          async.elapse(const Duration(seconds: 60));

          expect(revokedCalls, 1);
          expect(connector.connections, hasLength(1));

          client.dispose();
        });
      },
    );

    test('close code 4403 (without a prior message) stops without reconnecting', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        var revokedCalls = 0;
        final client = RealtimeClient(
          wsEndpoint: Uri.parse('ws://api.test/ws'),
          loadSnapshot: () {
            final completer = Completer<Snapshot>();
            completers.add(completer);
            return completer.future;
          },
          accessToken: () async => 'token-123',
          refreshSession: () async {},
          onRevoked: () => revokedCalls++,
          connector: connector.call,
          heartbeatInterval: const Duration(seconds: 10),
          random: _ZeroRandom(),
        );
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0].complete(Snapshot(seq: 10, vehicles: []));
        async.flushMicrotasks();

        connector.connections.single.closeWithCode(4403);
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 60));

        expect(revokedCalls, 1);
        expect(states.last.status, ConnectionStatus.revoked);
        expect(connector.connections, hasLength(1), reason: 'no reconnect');

        client.dispose();
      });
    });

    test(
      'shift.crew_changed upserts a shift belonging to the running BF-Tag',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();
          completers[0].complete(
            Snapshot(seq: 10, vehicles: const [], bfDay: _bfDay()),
          );
          async.flushMicrotasks();

          final updatedShift = _shift(
            crew: [
              const CrewAssignment(
                vehicleId: 'v1',
                personId: 'p1',
                displayName: 'Max Muster',
                function: 'GF',
              ),
            ],
          );
          connector.connections.single.emit(
            _shiftCrewChangedEvent(seq: 11, shift: updatedShift),
          );
          async.flushMicrotasks();

          expect(states.last.shifts, hasLength(1));
          expect(states.last.shifts.single.crew, hasLength(1));

          client.dispose();
        });
      },
    );

    test(
      'shift.crew_changed for a different BF-Tag is ignored',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();
          completers[0].complete(
            Snapshot(seq: 10, vehicles: const [], bfDay: _bfDay(id: 'day1')),
          );
          async.flushMicrotasks();

          connector.connections.single.emit(
            _shiftCrewChangedEvent(
              seq: 11,
              shift: _shift(bfDayId: 'other-day'),
            ),
          );
          async.flushMicrotasks();

          expect(states.last.shifts, isEmpty);
          expect(states.last.seq, 11, reason: 'seq still advances');

          client.dispose();
        });
      },
    );

    test('shift.deleted removes the shift', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client = _buildClient(
          snapshotCompleters: completers,
          connector: connector,
        );
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final shift = _shift();

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            shifts: [shift],
          ),
        );
        async.flushMicrotasks();
        expect(states.last.shifts, hasLength(1));

        connector.connections.single.emit(
          _shiftDeletedEvent(seq: 11, id: shift.id, bfDayId: shift.bfDayId),
        );
        async.flushMicrotasks();

        expect(states.last.shifts, isEmpty);

        client.dispose();
      });
    });

    test('bf_day.updated triggers a full snapshot reload', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client = _buildClient(
          snapshotCompleters: completers,
          connector: connector,
        );
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(seq: 10, vehicles: const [], bfDay: _bfDay(id: 'day1')),
        );
        async.flushMicrotasks();

        connector.connections.single.emit(
          _bfDayUpdatedEvent(seq: 11, bfDay: _bfDay(id: 'day2')),
        );
        async.flushMicrotasks();

        expect(completers, hasLength(2), reason: 'reloads the snapshot');
        completers[1].complete(
          Snapshot(
            seq: 11,
            vehicles: const [],
            bfDay: _bfDay(id: 'day2'),
          ),
        );
        async.flushMicrotasks();

        expect(states.last.bfDay?.id, 'day2');

        client.dispose();
      });
    });

    test(
      'incident.created with state running upserts into the running BF-Tag',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();
          completers[0].complete(
            Snapshot(seq: 10, vehicles: const [], bfDay: _bfDay()),
          );
          async.flushMicrotasks();

          connector.connections.single.emit(
            _incidentCreatedEvent(
              seq: 11,
              incident: _incident(state: IncidentState.running),
            ),
          );
          async.flushMicrotasks();

          expect(states.last.incidents, hasLength(1));
          expect(states.last.incidents.single.id, 'i1');

          client.dispose();
        });
      },
    );

    test('incident.created with state draft is ignored', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client = _buildClient(
          snapshotCompleters: completers,
          connector: connector,
        );
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers[0].complete(
          Snapshot(seq: 10, vehicles: const [], bfDay: _bfDay()),
        );
        async.flushMicrotasks();

        connector.connections.single.emit(
          _incidentCreatedEvent(
            seq: 11,
            incident: _incident(state: IncidentState.draft),
          ),
        );
        async.flushMicrotasks();

        expect(states.last.incidents, isEmpty);

        client.dispose();
      });
    });

    test(
      'incident.updated transitioning to closed removes the incident',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();
          completers[0].complete(
            Snapshot(
              seq: 10,
              vehicles: const [],
              bfDay: _bfDay(),
              incidents: [_incident(state: IncidentState.running)],
            ),
          );
          async.flushMicrotasks();
          expect(states.last.incidents, hasLength(1));

          connector.connections.single.emit(
            _incidentUpdatedEvent(
              seq: 11,
              incident: _incident(state: IncidentState.closed),
            ),
          );
          async.flushMicrotasks();

          expect(states.last.incidents, isEmpty);

          client.dispose();
        });
      },
    );

    test(
      'incident.updated transitioning to discarded removes the incident',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();
          completers[0].complete(
            Snapshot(
              seq: 10,
              vehicles: const [],
              bfDay: _bfDay(),
              incidents: [_incident(state: IncidentState.running)],
            ),
          );
          async.flushMicrotasks();
          expect(states.last.incidents, hasLength(1));

          connector.connections.single.emit(
            _incidentUpdatedEvent(
              seq: 11,
              incident: _incident(state: IncidentState.discarded),
            ),
          );
          async.flushMicrotasks();

          expect(states.last.incidents, isEmpty);

          client.dispose();
        });
      },
    );

    test(
      'incident.updated for a different BF-Tag is ignored',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final states = <RealtimeState>[];
          client.states.listen(states.add);

          client.start();
          async.flushMicrotasks();
          completers[0].complete(
            Snapshot(seq: 10, vehicles: const [], bfDay: _bfDay(id: 'day1')),
          );
          async.flushMicrotasks();

          connector.connections.single.emit(
            _incidentUpdatedEvent(
              seq: 11,
              incident: _incident(
                bfDayId: 'other-day',
                state: IncidentState.running,
              ),
            ),
          );
          async.flushMicrotasks();

          expect(states.last.incidents, isEmpty);
          expect(states.last.seq, 11, reason: 'seq still advances');

          client.dispose();
        });
      },
    );
  });

  group('defaultReconnectBackoff', () {
    test('grows exponentially and caps at 30s (no jitter)', () {
      final random = _ZeroRandom();
      expect(defaultReconnectBackoff(0, random), const Duration(seconds: 1));
      expect(defaultReconnectBackoff(1, random), const Duration(seconds: 2));
      expect(defaultReconnectBackoff(2, random), const Duration(seconds: 4));
      expect(defaultReconnectBackoff(3, random), const Duration(seconds: 8));
      expect(defaultReconnectBackoff(4, random), const Duration(seconds: 16));
      expect(defaultReconnectBackoff(5, random), const Duration(seconds: 30));
      expect(defaultReconnectBackoff(10, random), const Duration(seconds: 30));
    });
  });
}
