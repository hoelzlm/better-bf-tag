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

Announcement _announcement({
  String id = 'ann1',
  String bfDayId = 'day1',
  String? shiftId,
  String text = 'Essen ist fertig',
  String createdAt = '2026-10-11T10:00:00Z',
}) {
  return Announcement(
    id: id,
    bfDayId: bfDayId,
    shiftId: shiftId,
    text: text,
    createdBy: 'p1',
    createdAt: DateTime.parse(createdAt),
  );
}

Map<String, dynamic> _announcementJson(Announcement announcement) {
  return announcement.toJson();
}

Map<String, dynamic> _announcementCreatedEvent({
  required int seq,
  required Announcement announcement,
}) {
  return {
    'seq': seq,
    'type': 'announcement.created',
    'at': '2026-10-11T10:00:00Z',
    'data': _announcementJson(announcement),
  };
}

Map<String, dynamic> _announcementDeletedEvent({
  required int seq,
  required String id,
}) {
  return {
    'seq': seq,
    'type': 'announcement.deleted',
    'at': '2026-10-11T10:00:00Z',
    'data': {'id': id},
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
    'at': '2026-10-11T10:00:00Z',
    'data': {'id': id, 'bf_day_id': bfDayId},
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
  group('RealtimeClient announcements (ADR 0024)', () {
    test('snapshot without announcements exposes an empty list', () {
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

        expect(states.last.announcements, isEmpty);

        client.dispose();
      });
    });

    test('announcement.created inserts at the front', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final existing = _announcement(id: 'old');

        client.start();
        async.flushMicrotasks();
        completers.single.complete(
          Snapshot(seq: 10, vehicles: const [], announcements: [existing]),
        );
        async.flushMicrotasks();

        final created = _announcement(id: 'new');
        connector.connections.single.emit(
          _announcementCreatedEvent(seq: 11, announcement: created),
        );
        async.flushMicrotasks();

        expect(
          states.last.announcements.map((a) => a.id),
          ['new', 'old'],
        );

        client.dispose();
      });
    });

    test('announcement.created with a repeated id dedupes, keeping it at '
        'the front', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final a1 = _announcement(id: 'a1');
        final a2 = _announcement(id: 'a2');

        client.start();
        async.flushMicrotasks();
        completers.single.complete(
          Snapshot(seq: 10, vehicles: const [], announcements: [a2, a1]),
        );
        async.flushMicrotasks();

        final repeated = _announcement(id: 'a1', text: 'geändert');
        connector.connections.single.emit(
          _announcementCreatedEvent(seq: 11, announcement: repeated),
        );
        async.flushMicrotasks();

        expect(states.last.announcements, hasLength(2));
        expect(states.last.announcements.first.id, 'a1');
        expect(states.last.announcements.first.text, 'geändert');
        expect(states.last.announcements.last.id, 'a2');

        client.dispose();
      });
    });

    test('announcement.created keeps at most the newest 20', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final initial = List.generate(20, (i) => _announcement(id: 'a$i'));

        client.start();
        async.flushMicrotasks();
        completers.single.complete(
          Snapshot(seq: 10, vehicles: const [], announcements: initial),
        );
        async.flushMicrotasks();
        expect(states.last.announcements, hasLength(20));

        connector.connections.single.emit(
          _announcementCreatedEvent(
            seq: 11,
            announcement: _announcement(id: 'newest'),
          ),
        );
        async.flushMicrotasks();

        expect(states.last.announcements, hasLength(20));
        expect(states.last.announcements.first.id, 'newest');
        expect(
          states.last.announcements.map((a) => a.id),
          isNot(contains('a19')),
          reason: 'the oldest entry must fall off',
        );

        client.dispose();
      });
    });

    test('announcement.deleted removes the matching entry', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);
        final announcement = _announcement(id: 'ann1');

        client.start();
        async.flushMicrotasks();
        completers.single.complete(
          Snapshot(
            seq: 10,
            vehicles: const [],
            announcements: [announcement],
          ),
        );
        async.flushMicrotasks();

        connector.connections.single.emit(
          _announcementDeletedEvent(seq: 11, id: 'ann1'),
        );
        async.flushMicrotasks();

        expect(states.last.announcements, isEmpty);

        client.dispose();
      });
    });

    test(
      'shift.deleted defensively drops announcements targeted at that '
      'shift',
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
          final forShift = _announcement(id: 'ann1', shiftId: 'shift1');
          final forEveryone = _announcement(id: 'ann2', shiftId: null);

          client.start();
          async.flushMicrotasks();
          completers.single.complete(
            Snapshot(
              seq: 10,
              vehicles: const [],
              bfDay: _bfDay(),
              announcements: [forEveryone, forShift],
            ),
          );
          async.flushMicrotasks();

          connector.connections.single.emit(
            _shiftDeletedEvent(seq: 11, id: 'shift1', bfDayId: 'day1'),
          );
          async.flushMicrotasks();

          expect(
            states.last.announcements.map((a) => a.id),
            ['ann2'],
          );

          client.dispose();
        });
      },
    );

    test(
      'liveAnnouncementCreated fires for a live event, not for snapshot '
      'content',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final live = <Announcement>[];
          client.liveAnnouncementCreated.listen(live.add);

          client.start();
          async.flushMicrotasks();
          completers.single.complete(
            Snapshot(
              seq: 10,
              vehicles: const [],
              announcements: [_announcement(id: 'from-snapshot')],
            ),
          );
          async.flushMicrotasks();

          expect(live, isEmpty, reason: 'snapshot content never fires');

          final liveAnnouncement = _announcement(id: 'from-live-event');
          connector.connections.single.emit(
            _announcementCreatedEvent(seq: 11, announcement: liveAnnouncement),
          );
          async.flushMicrotasks();

          expect(live, hasLength(1));
          expect(live.single.id, 'from-live-event');

          client.dispose();
        });
      },
    );

    test(
      'a gap-triggered snapshot reload does not re-fire '
      'liveAnnouncementCreated',
      () {
        fakeAsync((async) {
          final completers = <Completer<Snapshot>>[];
          final connector = _FakeConnector();
          final client = _buildClient(
            snapshotCompleters: completers,
            connector: connector,
          );
          final live = <Announcement>[];
          client.liveAnnouncementCreated.listen(live.add);

          client.start();
          async.flushMicrotasks();
          completers[0].complete(Snapshot(seq: 10, vehicles: const []));
          async.flushMicrotasks();

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
              announcements: [_announcement(id: 'reloaded')],
            ),
          );
          async.flushMicrotasks();

          expect(live, isEmpty);

          client.dispose();
        });
      },
    );
  });
}
