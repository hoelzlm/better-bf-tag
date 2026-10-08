/// A Folie (slide) shown rotating in the monitor's standby (ADR 0014).
///
/// See CONTEXT.md ("Folie") and docs/03-datenmodell.md.
class Slide {
  const Slide({
    required this.id,
    required this.title,
    required this.body,
    required this.durationSeconds,
    required this.sortOrder,
    required this.active,
    this.image,
  });

  final String id;
  final String title;

  /// Markdown text, rendered with `flutter_markdown_plus`.
  final String body;
  final int durationSeconds;
  final int sortOrder;
  final bool active;
  final SlideImage? image;

  /// Parses the wire representation used by the backend API (snapshot and
  /// `slides.changed`), e.g.
  /// `{id,title,body,duration_seconds,sort_order,active,image}`.
  factory Slide.fromJson(Map<String, dynamic> json) {
    final imageJson = json['image'] as Map<String, dynamic>?;
    return Slide(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      durationSeconds: json['duration_seconds'] as int,
      sortOrder: json['sort_order'] as int,
      active: json['active'] as bool,
      image: imageJson == null ? null : SlideImage.fromJson(imageJson),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Slide &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.durationSeconds == durationSeconds &&
      other.sortOrder == sortOrder &&
      other.active == active &&
      other.image == image;

  @override
  int get hashCode => Object.hash(
        id,
        title,
        body,
        durationSeconds,
        sortOrder,
        active,
        image,
      );

  @override
  String toString() => 'Slide($title, duration: ${durationSeconds}s)';
}

/// A Folie's optional image (ADR 0014): metadata only, no bytes -- those are
/// loaded separately via `SlideImageLoader`.
class SlideImage {
  const SlideImage({
    required this.contentType,
    required this.sizeBytes,
    required this.version,
  });

  final String contentType;
  final int sizeBytes;

  /// The first 16 hex characters of the image's sha256; used as a cache key
  /// alongside the slide id and to detect a replaced image.
  final String version;

  factory SlideImage.fromJson(Map<String, dynamic> json) {
    return SlideImage(
      contentType: json['content_type'] as String,
      sizeBytes: json['size_bytes'] as int,
      version: json['version'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SlideImage &&
      other.contentType == contentType &&
      other.sizeBytes == sizeBytes &&
      other.version == version;

  @override
  int get hashCode => Object.hash(contentType, sizeBytes, version);

  @override
  String toString() => 'SlideImage($contentType, $sizeBytes bytes)';
}
