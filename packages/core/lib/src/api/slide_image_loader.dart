import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_provider.dart';

/// Loads Folie (slide) image bytes via `GET /api/v1/slides/{id}/image`,
/// using the authenticated [Dio] (ADR 0014: `Image.network` cannot send the
/// bearer header on web). Caches bytes in memory per `(slideId, version)` so
/// repeated rotations of the same slide don't re-fetch the image.
class SlideImageLoader {
  SlideImageLoader(this._dio);

  final Dio _dio;
  final Map<String, Uint8List> _cache = <String, Uint8List>{};

  String _cacheKey(String slideId, String version) => '$slideId@$version';

  /// Returns the cached bytes for `(slideId, version)`, fetching them from
  /// the server on a cache miss.
  Future<Uint8List> load(String slideId, String version) async {
    final key = _cacheKey(slideId, version);
    final cached = _cache[key];
    if (cached != null) {
      return cached;
    }
    final response = await _dio.get<List<int>>(
      '/api/v1/slides/$slideId/image',
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('GET /slides/$slideId/image returned no body');
    }
    final bytes = Uint8List.fromList(data);
    _cache[key] = bytes;
    return bytes;
  }
}

final slideImageLoaderProvider = Provider<SlideImageLoader>((ref) {
  final dio = ref.watch(dioProvider);
  return SlideImageLoader(dio);
});
