import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/admin/api_errors.dart';
import 'package:bftag_web/screens/slides_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Slide _slide({
  String id = 's1',
  String title = 'Willkommen',
  String body = '**fett**',
  int durationSeconds = 10,
  int sortOrder = 1,
  bool active = true,
  SlideImage? image,
}) {
  return Slide(
    id: id,
    title: title,
    body: body,
    durationSeconds: durationSeconds,
    sortOrder: sortOrder,
    active: active,
    image: image,
  );
}

class _FakeSlideAdminRepository implements SlideAdminRepository {
  _FakeSlideAdminRepository(this.slides);

  List<Slide> slides;
  final List<(String, String?, int?, bool?)> createCalls = [];
  final List<(String, bool?)> activeToggleCalls = [];
  final List<String> deleteCalls = [];
  final List<List<String>> reorderCalls = [];

  @override
  Future<List<Slide>> list() async => List.of(slides);

  @override
  Future<Slide> create({
    required String title,
    String? body,
    int? durationSeconds,
    bool? active,
  }) async {
    createCalls.add((title, body, durationSeconds, active));
    final created = _slide(
      id: 'new-${slides.length}',
      title: title,
      body: body ?? '',
      durationSeconds: durationSeconds ?? 10,
      sortOrder: slides.length,
      active: active ?? true,
    );
    slides = [...slides, created];
    return created;
  }

  @override
  Future<Slide> update(
    String id, {
    String? title,
    String? body,
    int? durationSeconds,
    bool? active,
  }) async {
    if (active != null) {
      activeToggleCalls.add((id, active));
    }
    final index = slides.indexWhere((s) => s.id == id);
    final current = slides[index];
    final updated = _slide(
      id: current.id,
      title: title ?? current.title,
      body: body ?? current.body,
      durationSeconds: durationSeconds ?? current.durationSeconds,
      sortOrder: current.sortOrder,
      active: active ?? current.active,
      image: current.image,
    );
    slides = List.of(slides)..[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    deleteCalls.add(id);
    slides = slides.where((s) => s.id != id).toList();
  }

  @override
  Future<void> reorder(List<String> slideIds) async {
    reorderCalls.add(slideIds);
    final byId = {for (final s in slides) s.id: s};
    slides = [
      for (var i = 0; i < slideIds.length; i++)
        _slide(
          id: byId[slideIds[i]]!.id,
          title: byId[slideIds[i]]!.title,
          body: byId[slideIds[i]]!.body,
          durationSeconds: byId[slideIds[i]]!.durationSeconds,
          sortOrder: i,
          active: byId[slideIds[i]]!.active,
          image: byId[slideIds[i]]!.image,
        ),
    ];
  }

  @override
  Future<Slide> uploadImage(
    String id,
    Uint8List bytes,
    String contentType,
  ) =>
      throw UnimplementedError();

  @override
  Future<void> deleteImage(String id) => throw UnimplementedError();
}

Future<_FakeSlideAdminRepository> _pump(
  WidgetTester tester, {
  required List<Slide> slides,
}) async {
  final repository = _FakeSlideAdminRepository(slides);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        slideAdminRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: SlidesScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('lists slides with title and duration', (tester) async {
    await _pump(
      tester,
      slides: [
        _slide(id: 's1', title: 'Willkommen', durationSeconds: 12),
        _slide(id: 's2', title: 'Sicherheit', durationSeconds: 20, active: false),
      ],
    );

    expect(find.text('Willkommen'), findsOneWidget);
    expect(find.text('12 s'), findsOneWidget);
    expect(find.text('Sicherheit'), findsOneWidget);
    expect(find.text('20 s'), findsOneWidget);
  });

  testWidgets('create dialog rejects an empty title', (tester) async {
    await _pump(tester, slides: []);

    await tester.tap(find.byKey(const Key('create-slide')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('slide-form-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Titel ist erforderlich.'), findsOneWidget);
    // Dialog is still open.
    expect(find.byKey(const Key('slide-form-title')), findsOneWidget);
  });

  testWidgets('create dialog rejects a duration out of range', (tester) async {
    await _pump(tester, slides: []);

    await tester.tap(find.byKey(const Key('create-slide')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('slide-form-title')),
      'Neue Folie',
    );
    await tester.enterText(
      find.byKey(const Key('slide-form-duration')),
      '1',
    );
    await tester.tap(find.byKey(const Key('slide-form-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('Anzeigedauer muss zwischen 3 und 300 Sekunden liegen.'),
      findsOneWidget,
    );
  });

  testWidgets('create dialog with valid input calls the repository',
      (tester) async {
    final repository = await _pump(tester, slides: []);

    await tester.tap(find.byKey(const Key('create-slide')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('slide-form-title')),
      'Neue Folie',
    );
    await tester.enterText(
      find.byKey(const Key('slide-form-body')),
      'Hallo Welt',
    );
    await tester.enterText(
      find.byKey(const Key('slide-form-duration')),
      '15',
    );
    await tester.tap(find.byKey(const Key('slide-form-submit')));
    await tester.pumpAndSettle();

    expect(repository.createCalls, [('Neue Folie', 'Hallo Welt', 15, true)]);
    expect(find.text('Neue Folie'), findsOneWidget);
  });

  testWidgets('preview toggle shows the markdown body', (tester) async {
    await _pump(tester, slides: []);

    await tester.tap(find.byKey(const Key('create-slide')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('slide-form-body')),
      '**fett**',
    );
    await tester.tap(find.byKey(const Key('slide-form-preview-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('slide-form-preview')), findsOneWidget);
    expect(find.byKey(const Key('slide-form-body')), findsNothing);
  });

  testWidgets('toggling active calls update with active', (tester) async {
    final repository = await _pump(tester, slides: [_slide(id: 's1')]);

    await tester.tap(find.byKey(const Key('active-switch-s1')));
    await tester.pumpAndSettle();

    expect(repository.activeToggleCalls, [('s1', false)]);
  });

  testWidgets('delete asks for confirmation before calling the repository',
      (tester) async {
    final repository = await _pump(tester, slides: [_slide(id: 's1')]);

    await tester.tap(find.byKey(const Key('delete-slide-s1')));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, isEmpty);

    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();
    expect(repository.deleteCalls, isEmpty);

    await tester.tap(find.byKey(const Key('delete-slide-s1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(repository.deleteCalls, ['s1']);
  });

  testWidgets('reorder calls the order API', (tester) async {
    final repository = await _pump(
      tester,
      slides: [
        _slide(id: 's1', title: 'Erste', sortOrder: 0),
        _slide(id: 's2', title: 'Zweite', sortOrder: 1),
      ],
    );

    final reorderable = tester.widget<ReorderableListView>(
      find.byKey(const Key('slides-list')),
    );
    reorderable.onReorderItem!(0, 1);
    await tester.pumpAndSettle();

    expect(repository.reorderCalls, [
      ['s2', 's1'],
    ]);
  });

  group('describeSlideImageError', () {
    test('maps image_too_large to the German message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/slides/s1/image'),
        response: Response(
          requestOptions: RequestOptions(path: '/slides/s1/image'),
          statusCode: 413,
          data: {
            'error': {
              'code': 'image_too_large',
              'message': 'Bild ist zu groß.',
            },
          },
        ),
      );

      expect(
        describeSlideImageError(error),
        'Bild ist zu groß (max. 5 MB).',
      );
    });

    test('maps unsupported_image_type to the German message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/slides/s1/image'),
        response: Response(
          requestOptions: RequestOptions(path: '/slides/s1/image'),
          statusCode: 415,
          data: {
            'error': {
              'code': 'unsupported_image_type',
              'message': 'Nicht unterstützter Bildtyp.',
            },
          },
        ),
      );

      expect(describeSlideImageError(error), 'Nur PNG, JPEG oder WebP.');
    });

    test('falls back to the backend message for other errors', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/slides/s1/image'),
        response: Response(
          requestOptions: RequestOptions(path: '/slides/s1/image'),
          statusCode: 500,
          data: {
            'error': {'code': 'internal_error', 'message': 'Serverfehler.'},
          },
        ),
      );

      expect(describeSlideImageError(error), 'Serverfehler.');
    });
  });
}
