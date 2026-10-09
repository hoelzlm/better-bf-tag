import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _slideJson({
  String id = 's1',
  String title = 'Willkommen',
  String body = '**fett**',
  int durationSeconds = 10,
  int sortOrder = 1,
  bool active = true,
  Map<String, dynamic>? image,
}) {
  return {
    'id': id,
    'title': title,
    'body': body,
    'duration_seconds': durationSeconds,
    'sort_order': sortOrder,
    'active': active,
    if (image != null) 'image': image,
  };
}

void main() {
  group('Slide.fromJson', () {
    test('parses a slide without an image', () {
      final slide = Slide.fromJson(_slideJson());

      expect(slide.id, 's1');
      expect(slide.title, 'Willkommen');
      expect(slide.body, '**fett**');
      expect(slide.durationSeconds, 10);
      expect(slide.sortOrder, 1);
      expect(slide.active, isTrue);
      expect(slide.image, isNull);
    });

    test('parses a slide with an image', () {
      final slide = Slide.fromJson(
        _slideJson(
          image: {
            'content_type': 'image/png',
            'size_bytes': 1234,
            'version': 'abcdef0123456789',
          },
        ),
      );

      expect(slide.image, isNotNull);
      expect(slide.image!.contentType, 'image/png');
      expect(slide.image!.sizeBytes, 1234);
      expect(slide.image!.version, 'abcdef0123456789');
    });

    test('tolerates a missing body (defaults to empty string)', () {
      final json = _slideJson()..remove('body');
      final slide = Slide.fromJson(json);

      expect(slide.body, '');
    });
  });

  group('SlideImage equality', () {
    test('two SlideImage with the same fields are equal', () {
      const a = SlideImage(contentType: 'image/png', sizeBytes: 1, version: 'v1');
      const b = SlideImage(contentType: 'image/png', sizeBytes: 1, version: 'v1');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('Slide equality', () {
    test('two Slide with the same fields are equal', () {
      final a = Slide.fromJson(_slideJson());
      final b = Slide.fromJson(_slideJson());
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different id makes them unequal', () {
      final a = Slide.fromJson(_slideJson(id: 's1'));
      final b = Slide.fromJson(_slideJson(id: 's2'));
      expect(a, isNot(b));
    });
  });

  group('Snapshot', () {
    test('defaults slides to an empty list when omitted', () {
      const snapshot = Snapshot(seq: 1, vehicles: []);
      expect(snapshot.slides, isEmpty);
    });

    test('carries the given slides', () {
      final slide = Slide.fromJson(_slideJson());
      final snapshot = Snapshot(seq: 1, vehicles: const [], slides: [slide]);
      expect(snapshot.slides, [slide]);
    });
  });
}
