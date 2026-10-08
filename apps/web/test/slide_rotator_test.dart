import 'dart:async';
import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/widgets/slide_rotator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Slide _slide({
  String id = 's1',
  String? title,
  String body = 'Text',
  int durationSeconds = 10,
  int sortOrder = 1,
  SlideImage? image,
}) {
  return Slide(
    id: id,
    title: title ?? 'Titel $id',
    body: body,
    durationSeconds: durationSeconds,
    sortOrder: sortOrder,
    active: true,
    image: image,
  );
}

/// A no-op [HttpClientAdapter]: tests that don't exercise the image loader
/// never issue a request, but [dioProvider] still needs a working [Dio].
class _NoopAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw UnimplementedError('Unexpected request: ${options.path}');
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _pump(WidgetTester tester, List<Slide> slides) async {
  final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = _NoopAdapter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dioProvider.overrideWithValue(dio)],
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: SlideRotator(slides: slides),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('SlideRotator', () {
    testWidgets('empty list shows nothing', (tester) async {
      await _pump(tester, const []);
      expect(find.byType(SlideRotator), findsOneWidget);
      expect(find.text('Titel s1'), findsNothing);
    });

    testWidgets('shows the first slide', (tester) async {
      await _pump(tester, [_slide(id: 's1'), _slide(id: 's2', sortOrder: 2)]);
      expect(find.byKey(const Key('slide-s1')), findsOneWidget);
      expect(find.text('Titel s1'), findsOneWidget);
    });

    testWidgets('advances to the next slide after its duration', (tester) async {
      await _pump(tester, [
        _slide(id: 's1', durationSeconds: 5),
        _slide(id: 's2', sortOrder: 2, durationSeconds: 5),
      ]);
      expect(find.byKey(const Key('slide-s1')), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));

      expect(find.byKey(const Key('slide-s2')), findsOneWidget);
      expect(find.byKey(const Key('slide-s1')), findsNothing);
    });

    testWidgets('wraps around to the first slide', (tester) async {
      await _pump(tester, [
        _slide(id: 's1', durationSeconds: 5),
        _slide(id: 's2', sortOrder: 2, durationSeconds: 5),
      ]);

      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(const Key('slide-s2')), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(const Key('slide-s1')), findsOneWidget);
    });

    testWidgets('a single slide never rotates', (tester) async {
      await _pump(tester, [_slide(id: 's1', durationSeconds: 1)]);
      expect(find.byKey(const Key('slide-s1')), findsOneWidget);

      await tester.pump(const Duration(seconds: 30));

      expect(find.byKey(const Key('slide-s1')), findsOneWidget);
    });

    testWidgets(
      'a list update keeps the current slide (by id) and the timer running',
      (tester) async {
        final initial = [
          _slide(id: 's1', durationSeconds: 10),
          _slide(id: 's2', sortOrder: 2, durationSeconds: 10),
        ];
        await _pump(tester, initial);
        await tester.pump(const Duration(seconds: 10));
        expect(find.byKey(const Key('slide-s2')), findsOneWidget);

        // Reordered list: s2 (currently shown) is now first, plus a new
        // s3. The shown slide must not jump back to s1.
        final updated = [
          _slide(id: 's2', sortOrder: 1, durationSeconds: 10),
          _slide(id: 's3', sortOrder: 2, durationSeconds: 10),
          _slide(id: 's1', sortOrder: 3, durationSeconds: 10),
        ];
        await _pump(tester, updated);
        expect(find.byKey(const Key('slide-s2')), findsOneWidget);

        // Timer kept running: after the remaining duration it advances to
        // the next slide in the *new* list (s3), not a restart at index 0.
        await tester.pump(const Duration(seconds: 10));
        expect(find.byKey(const Key('slide-s3')), findsOneWidget);
      },
    );

    testWidgets(
      'a list update resets to index 0 when the current slide is gone',
      (tester) async {
        final initial = [
          _slide(id: 's1', durationSeconds: 10),
          _slide(id: 's2', sortOrder: 2, durationSeconds: 10),
        ];
        await _pump(tester, initial);
        await tester.pump(const Duration(seconds: 10));
        expect(find.byKey(const Key('slide-s2')), findsOneWidget);

        final updated = [
          _slide(id: 's3', durationSeconds: 10),
          _slide(id: 's4', sortOrder: 2, durationSeconds: 10),
        ];
        await _pump(tester, updated);

        expect(find.byKey(const Key('slide-s3')), findsOneWidget);
      },
    );

    testWidgets('markdown body text is visible', (tester) async {
      await _pump(tester, [_slide(id: 's1', body: '**fett**')]);
      expect(find.text('fett'), findsOneWidget);
    });

    testWidgets('shows nothing for the image while loading, then the image',
        (tester) async {
      final completer = Completer<Response<List<int>>>();
      final adapter = _CapturingAdapter(completer);
      final dio = Dio(BaseOptions(baseUrl: ''))..httpClientAdapter = adapter;
      final slide = _slide(
        id: 's1',
        image: const SlideImage(
          contentType: 'image/png',
          sizeBytes: 10,
          version: 'v1',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(dio)],
          child: MaterialApp(
            home: Scaffold(body: SlideRotator(slides: [slide])),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('slide-image')), findsNothing);

      // 1x1 transparent PNG.
      const pngBytes = <int>[
        137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
        1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 10, 73, 68,
        65, 84, 120, 156, 99, 0, 1, 0, 0, 5, 0, 1, 13, 10, 45, 180, 0, 0, 0,
        0, 73, 69, 78, 68, 174, 66, 96, 130,
      ];
      completer.complete(
        Response(
          data: pngBytes,
          requestOptions: RequestOptions(path: '/api/v1/slides/s1/image'),
          statusCode: 200,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slide-image')), findsOneWidget);
    });
  });
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.completer);

  final Completer<Response<List<int>>> completer;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final response = await completer.future;
    return ResponseBody.fromBytes(
      response.data as List<int>,
      response.statusCode ?? 200,
    );
  }

  @override
  void close({bool force = false}) {}
}
