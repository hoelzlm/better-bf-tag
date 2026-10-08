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

Slide _slide({String id = 's1', int sortOrder = 1}) {
  return Slide(
    id: id,
    title: 'Folie $id',
    body: 'Text',
    durationSeconds: 10,
    sortOrder: sortOrder,
    active: true,
  );
}

Map<String, dynamic> _slideJson(Slide slide) {
  return {
    'id': slide.id,
    'title': slide.title,
    'body': slide.body,
    'duration_seconds': slide.durationSeconds,
    'sort_order': slide.sortOrder,
    'active': slide.active,
  };
}

Map<String, dynamic> _slidesChangedEvent({
  required int seq,
  required List<Slide> slides,
}) {
  return {
    'seq': seq,
    'type': 'slides.changed',
    'at': '2026-10-09T08:00:00Z',
    'data': {'slides': slides.map(_slideJson).toList()},
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
  group('RealtimeClient slides', () {
    test('snapshot without slides exposes an empty list', () {
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

        expect(states.last.slides, isEmpty);

        client.dispose();
      });
    });

    test('snapshot with slides exposes them', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        final slide = _slide();
        completers.single.complete(
          Snapshot(seq: 1, vehicles: const [], slides: [slide]),
        );
        async.flushMicrotasks();

        expect(states.last.slides, [slide]);

        client.dispose();
      });
    });

    test('slides.changed replaces the whole list', () {
      fakeAsync((async) {
        final completers = <Completer<Snapshot>>[];
        final connector = _FakeConnector();
        final client =
            _buildClient(snapshotCompleters: completers, connector: connector);
        final states = <RealtimeState>[];
        client.states.listen(states.add);

        client.start();
        async.flushMicrotasks();
        completers.single.complete(
          Snapshot(seq: 1, vehicles: const [], slides: [_slide(id: 's1')]),
        );
        async.flushMicrotasks();
        expect(states.last.slides, [_slide(id: 's1')]);

        final newSlides = [_slide(id: 's2'), _slide(id: 's3', sortOrder: 2)];
        connector.connections.single.emit(
          _slidesChangedEvent(seq: 2, slides: newSlides),
        );
        async.flushMicrotasks();

        expect(states.last.slides, newSlides);

        client.dispose();
      });
    });
  });
}
