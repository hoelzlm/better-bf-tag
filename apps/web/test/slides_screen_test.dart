import 'dart:typed_data';

import 'package:bftag_core/bftag_core.dart';
import 'package:bftag_web/admin/api_errors.dart';
import 'package:bftag_web/screens/slides_screen.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal, decodable 1x1 transparent PNG -- `_detectImageContentType`
/// only checks the magic bytes, but `Image.memory` in `_SlideThumbnail`
/// actually decodes this, so it has to be a real (tiny) PNG.
final _pngBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x04, 0x00, 0x00, 0x00, 0xB5, 0x1C, 0x0C, 0x02, 0x00, 0x00, 0x00,
  0x0B, 0x49, 0x44, 0x41, 0x54, 0x78, 0xDA, 0x63, 0x64, 0xF8, 0x0F, 0x00,
  0x01, 0x05, 0x01, 0x01, 0x27, 0x18, 0xE3, 0x66, 0x00, 0x00, 0x00, 0x00,
  0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

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
  final List<(String, Uint8List, String)> uploadImageCalls = [];
  final List<String> deleteImageCalls = [];
  Object? uploadImageError;

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
  ) async {
    uploadImageCalls.add((id, bytes, contentType));
    final error = uploadImageError;
    if (error != null) throw error;
    final index = slides.indexWhere((s) => s.id == id);
    final current = slides[index];
    final updated = _slide(
      id: current.id,
      title: current.title,
      body: current.body,
      durationSeconds: current.durationSeconds,
      sortOrder: current.sortOrder,
      active: current.active,
      image: SlideImage(
        contentType: contentType,
        sizeBytes: bytes.length,
        version: 'v2',
      ),
    );
    slides = List.of(slides)..[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteImage(String id) async {
    deleteImageCalls.add(id);
    final index = slides.indexWhere((s) => s.id == id);
    final current = slides[index];
    slides = List.of(slides)
      ..[index] = _slide(
        id: current.id,
        title: current.title,
        body: current.body,
        durationSeconds: current.durationSeconds,
        sortOrder: current.sortOrder,
        active: current.active,
      );
  }
}

/// Fake `FilePicker.platform` (ADR 0014: client-side file selection) that
/// returns a single fixed file instead of opening a native dialog --
/// `FilePicker.platform` is a public, overridable `PlatformInterface`
/// setter, same mechanism the real desktop/web implementations use.
class _FakeFilePicker extends FilePicker {
  _FakeFilePicker(this.result);

  final FilePickerResult? result;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      result;
}

/// Fake [SlideImageLoader] that never touches the network -- real thumbnail
/// bytes don't matter for these tests, only that `_SlideThumbnail` doesn't
/// hang on an unreachable `Dio` call.
class _FakeSlideImageLoader implements SlideImageLoader {
  @override
  Future<Uint8List> load(String slideId, String version) async => _pngBytes;
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
        slideImageLoaderProvider.overrideWithValue(_FakeSlideImageLoader()),
      ],
      child: const MaterialApp(home: SlidesScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets(
    'Folien AC1: lists slides incl. inactive with title, preview, duration '
    'chip and placeholder',
    (tester) async {
      await _pump(
        tester,
        slides: [
          _slide(id: 's1', title: 'Willkommen', body: '**Hallo Welt**', durationSeconds: 12),
          _slide(id: 's2', title: 'Sicherheit', durationSeconds: 20, active: false),
        ],
      );

      expect(find.text('Willkommen'), findsOneWidget);
      expect(find.text('12 s'), findsOneWidget);
      expect(find.text('Hallo Welt'), findsOneWidget);
      expect(find.text('Sicherheit'), findsOneWidget);
      expect(find.text('20 s'), findsOneWidget);
      expect(find.text('(inaktiv)'), findsOneWidget);
      // s2 has no image -> neutral placeholder icon, not the error-looking
      // "image_not_supported" icon (Problem 1 of the concept).
      expect(find.byIcon(Icons.image_outlined), findsWidgets);
      expect(find.byIcon(Icons.image_not_supported_outlined), findsNothing);
    },
  );

  testWidgets('Folien AC2: "Folie anlegen" opens the create dialog',
      (tester) async {
    await _pump(tester, slides: []);

    await tester.tap(find.byKey(const Key('create-slide')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('slide-form-title')), findsOneWidget);
  });

  testWidgets(
    'Folien AC3: empty title shows an inline error and blocks submit',
    (tester) async {
      await _pump(tester, slides: []);

      await tester.tap(find.byKey(const Key('create-slide')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('slide-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Titel ist erforderlich.'), findsOneWidget);
      expect(find.byKey(const Key('slide-form-title')), findsOneWidget);
    },
  );

  testWidgets(
    'Folien AC3: title over 200 characters shows an inline error',
    (tester) async {
      await _pump(tester, slides: []);

      await tester.tap(find.byKey(const Key('create-slide')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('slide-form-title')),
        'x' * 201,
      );
      await tester.tap(find.byKey(const Key('slide-form-submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('Titel darf höchstens 200 Zeichen haben.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Folien AC3: body over 5000 characters shows an inline error',
    (tester) async {
      await _pump(tester, slides: []);

      await tester.tap(find.byKey(const Key('create-slide')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('slide-form-title')),
        'Titel',
      );
      await tester.enterText(
        find.byKey(const Key('slide-form-body')),
        'x' * 5001,
      );
      await tester.tap(find.byKey(const Key('slide-form-submit')));
      await tester.pumpAndSettle();

      expect(
        find.text('Text darf höchstens 5000 Zeichen haben.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Folien AC3: duration out of 3-300 range shows an inline error',
    (tester) async {
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
    },
  );

  testWidgets(
    'Folien AC2+AC3: valid input in the create dialog calls create()',
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
    },
  );

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

  testWidgets(
    'Folien AC4: tapping a row opens edit prefilled and save calls update()',
    (tester) async {
      await _pump(
        tester,
        slides: [_slide(id: 's1', title: 'Willkommen')],
      );

      await tester.tap(find.text('Willkommen'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('slide-form-title')))
            .controller!
            .text,
        'Willkommen',
      );
      await tester.enterText(
        find.byKey(const Key('slide-form-title')),
        'Willkommen neu',
      );
      await tester.tap(find.byKey(const Key('slide-form-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Willkommen neu'), findsOneWidget);
    },
  );

  testWidgets(
    'Folien AC5: toggling active calls update(active:) and dims the row',
    (tester) async {
      final repository = await _pump(tester, slides: [_slide(id: 's1')]);

      await tester.tap(find.byKey(const Key('active-switch-s1')));
      await tester.pumpAndSettle();

      expect(repository.activeToggleCalls, [('s1', false)]);
      expect(find.text('(inaktiv)'), findsOneWidget);
    },
  );

  testWidgets(
    'Folien AC6: valid image upload in the edit dialog calls uploadImage() '
    'and shows the new image',
    (tester) async {
      FilePicker.platform = _FakeFilePicker(
        FilePickerResult([
          PlatformFile(name: 'logo.png', size: _pngBytes.length, bytes: _pngBytes),
        ]),
      );
      addTearDown(() => FilePicker.platform = _FakeFilePicker(null));

      final repository = await _pump(
        tester,
        slides: [_slide(id: 's1', title: 'Willkommen')],
      );

      await tester.tap(find.text('Willkommen'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('slide-form-upload-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('slide-form-upload-image')));
      await tester.pumpAndSettle();

      expect(repository.uploadImageCalls, hasLength(1));
      expect(repository.uploadImageCalls.single.$1, 's1');
      expect(repository.uploadImageCalls.single.$3, 'image/png');
      expect(find.byKey(const Key('slide-form-remove-image')), findsOneWidget);
    },
  );

  testWidgets(
    'Folien AC7: an oversized image shows an error without calling '
    'uploadImage()',
    (tester) async {
      final bigBytes = Uint8List(6 * 1024 * 1024);
      FilePicker.platform = _FakeFilePicker(
        FilePickerResult([
          PlatformFile(name: 'big.png', size: bigBytes.length, bytes: bigBytes),
        ]),
      );
      addTearDown(() => FilePicker.platform = _FakeFilePicker(null));

      final repository = await _pump(
        tester,
        slides: [_slide(id: 's1', title: 'Willkommen')],
      );

      await tester.tap(find.text('Willkommen'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('slide-form-upload-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('slide-form-upload-image')));
      await tester.pumpAndSettle();

      expect(find.text('Bild ist zu groß (max. 5 MB).'), findsOneWidget);
      expect(repository.uploadImageCalls, isEmpty);
    },
  );

  testWidgets(
    'Folien AC7: a non-image file shows an error without calling '
    'uploadImage()',
    (tester) async {
      final badBytes = Uint8List.fromList([1, 2, 3, 4]);
      FilePicker.platform = _FakeFilePicker(
        FilePickerResult([
          PlatformFile(name: 'doc.txt', size: badBytes.length, bytes: badBytes),
        ]),
      );
      addTearDown(() => FilePicker.platform = _FakeFilePicker(null));

      final repository = await _pump(
        tester,
        slides: [_slide(id: 's1', title: 'Willkommen')],
      );

      await tester.tap(find.text('Willkommen'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('slide-form-upload-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('slide-form-upload-image')));
      await tester.pumpAndSettle();

      expect(find.text('Nur PNG, JPEG oder WebP.'), findsOneWidget);
      expect(repository.uploadImageCalls, isEmpty);
    },
  );

  testWidgets(
    'Folien AC8: "Bild entfernen" calls deleteImage() and shows the '
    'placeholder again',
    (tester) async {
      final repository = await _pump(
        tester,
        slides: [
          _slide(
            id: 's1',
            title: 'Willkommen',
            image: const SlideImage(
              contentType: 'image/png',
              sizeBytes: 1024,
              version: 'v1',
            ),
          ),
        ],
      );

      await tester.tap(find.text('Willkommen'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('slide-form-remove-image')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('slide-form-remove-image')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('slide-form-remove-image')));
      await tester.pumpAndSettle();

      expect(repository.deleteImageCalls, ['s1']);
      expect(find.byKey(const Key('slide-form-remove-image')), findsNothing);
    },
  );

  testWidgets(
    'Folien AC9: delete asks for confirmation before calling delete()',
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
    },
  );

  testWidgets(
    'Folien AC10: dragging a row calls reorder() with the new slide order',
    (tester) async {
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
    },
  );

  testWidgets(
    'Folien AC11: load error shows "Folien konnten nicht geladen werden." '
    'instead of the list',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            slideAdminRepositoryProvider.overrideWith(
              (ref) => _ThrowingSlideAdminRepository(),
            ),
          ],
          child: const MaterialApp(home: SlidesScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Folien konnten nicht geladen werden.'), findsOneWidget);
      expect(find.byKey(const Key('slides-list')), findsNothing);
    },
  );

  testWidgets(
    'Folien AC12: an empty slide list shows the empty state with a '
    'primary action',
    (tester) async {
      await _pump(tester, slides: []);

      expect(find.text('Noch keine Folien angelegt.'), findsOneWidget);
      expect(find.byKey(const Key('slides-empty-create')), findsOneWidget);
    },
  );

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

class _ThrowingSlideAdminRepository implements SlideAdminRepository {
  @override
  Future<List<Slide>> list() async => throw Exception('boom');

  @override
  Future<Slide> create({
    required String title,
    String? body,
    int? durationSeconds,
    bool? active,
  }) =>
      throw UnimplementedError();

  @override
  Future<Slide> update(
    String id, {
    String? title,
    String? body,
    int? durationSeconds,
    bool? active,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> delete(String id) => throw UnimplementedError();

  @override
  Future<void> reorder(List<String> slideIds) => throw UnimplementedError();

  @override
  Future<Slide> uploadImage(String id, Uint8List bytes, String contentType) =>
      throw UnimplementedError();

  @override
  Future<void> deleteImage(String id) => throw UnimplementedError();
}
