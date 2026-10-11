import 'dart:async';
import 'dart:math';

import 'package:bftag_core/bftag_core.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class _ZeroRandom implements Random {
  @override
  double nextDouble() => 0.0;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

class _FakeSink implements WebSocketConnectionSink {
  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}
}

class _FakeConnection implements WebSocketConnection {
  final StreamController<dynamic> _controller =
      StreamController<dynamic>.broadcast();
  final _FakeSink _sink = _FakeSink();

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketConnectionSink get sink => _sink;

  @override
  int? get closeCode => null;

  void emit(Map<String, dynamic> message) {
    _controller.add(message);
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

BfDay _bfDay({String id = 'day1'}) {
  return BfDay(
    id: id,
    name: 'BF-Tag',
    startsAt: DateTime.parse('2026-06-01T00:00:00Z'),
    endsAt: DateTime.parse('2026-06-02T00:00:00Z'),
    state: BfDayState.running,
  );
}

ProgramItem _programItem({
  String id = 'pi1',
  String bfDayId = 'day1',
  String title = 'Mittagessen',
  ProgramItemType type = ProgramItemType.meal,
  String startsAt = '2026-10-11T11:00:00Z',
  String endsAt = '2026-10-11T12:00:00Z',
}) {
  return ProgramItem(
    id: id,
    bfDayId: bfDayId,
    title: title,
    type: type,
    startsAt: DateTime.parse(startsAt),
    endsAt: DateTime.parse(endsAt),
  );
}

Map<String, dynamic> _programChangedEvent({
  required int seq,
  required String bfDayId,
  required List<ProgramItem> items,
}) {
  return {
    'seq': seq,
    'type': 'program.changed',
    'at': '2026-10-11T10:00:00Z',
    'data': {
      'bf_day_id': bfDayId,
      'items': items.map((i) => i.toJson()).toList(),
    },
  };
}

RealtimeClient _buildClient({
  required List<Completer<Snapshot>> snapshotCompleters,
  required _FakeConnector connector,
}) {
  return RealtimeClient(
    wsEndpoint: Uri.parse('ws://api.test/ws'),
    loadSnapshot: () {
      final completer = Completer<Snapshot>();
      snapshotCompleters.add(completer);
      return completer.future;
    },
    accessToken: () async => 'token-123',
    refreshSession: () async {},
    connector: connector.call,
    heartbeatInterval: const Duration(seconds: 10),
    random: _ZeroRandom(),
  );
}

void main() {
  group('RealtimeClient programItems (ADR 0025)', () {
    test('snapshot without programItems exposes an empty list', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers.single.complete(const Snapshot(seq: 1, vehicles: []));
        async.flushMicrotasks();

        expect(states.last.programItems, isEmpty);

        client.dispose();
      });
    });

    test('program.changed for the running day replaces the list', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final existing = _programItem(id: 'pi1');

        client.start();
        async.flushMicrotasks();
        completers.single.complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(),
            programItems: [existing],
          ),
        );
        async.flushMicrotasks();

        final updated = [
          existing,
          _programItem(id: 'pi2', title: 'Ausbildung'),
        ];
        connector.connections.single.emit(
          _programChangedEvent(seq: 11, bfDayId: 'day1', items: updated),
        );
        async.flushMicrotasks();

        expect(
          states.last.programItems.map((i) => i.id),
          ['pi1', 'pi2'],
        );

        client.dispose();
      });
    });

    test('program.changed for a different BF-Tag is ignored', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final existing = _programItem(id: 'pi1', bfDayId: 'day1');

        client.start();
        async.flushMicrotasks();
        completers.single.complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            bfDay: _bfDay(id: 'day1'),
            programItems: [existing],
          ),
        );
        async.flushMicrotasks();

        connector.connections.single.emit(
          _programChangedEvent(
            seq: 11,
            bfDayId: 'other-day',
            items: [_programItem(id: 'pi-other', bfDayId: 'other-day')],
          ),
        );
        async.flushMicrotasks();

        expect(states.last.programItems.map((i) => i.id), ['pi1']);

        client.dispose();
      });
    });

    test('program.changed while no BF-Tag is running is ignored', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers.single.complete(const Snapshot(seq: 10, vehicles: []));
        async.flushMicrotasks();

        connector.connections.single.emit(
          _programChangedEvent(
            seq: 11,
            bfDayId: 'day1',
            items: [_programItem(id: 'pi1')],
          ),
        );
        async.flushMicrotasks();

        expect(states.last.programItems, isEmpty);

        client.dispose();
      });
    });

    test('a snapshot reload resets programItems to the new snapshot', () {
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
            vehicles: const [],
            bfDay: _bfDay(),
            programItems: [_programItem(id: 'pi1')],
          ),
        );
        async.flushMicrotasks();

        // A gap (seq jump) triggers a snapshot reload.
        connector.connections.single.emit({
          'seq': 20,
          'type': 'vehicle.status_changed',
          'at': '2026-10-11T10:00:00Z',
          'data': {'vehicle_id': 'v1', 'status': 2, 'source': 'app'},
        });
        async.flushMicrotasks();
        expect(completers, hasLength(2));

        completers[1].complete(
          Snapshot(
            seq: 20,
            vehicles: const [],
            bfDay: _bfDay(),
            programItems: [_programItem(id: 'reloaded')],
          ),
        );
        async.flushMicrotasks();

        expect(states.last.programItems.map((i) => i.id), ['reloaded']);

        client.dispose();
      });
    });
  });
}
