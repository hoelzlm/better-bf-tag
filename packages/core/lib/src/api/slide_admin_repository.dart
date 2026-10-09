import 'dart:typed_data';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/slide.dart';
import 'dio_provider.dart';

Slide _slideFromApi(GetSnapshot200ResponseSlidesInner s) {
  final image = s.image;
  return Slide.fromJson({
    'id': s.id,
    'title': s.title,
    'body': s.body,
    'duration_seconds': s.durationSeconds,
    'sort_order': s.sortOrder,
    'active': s.active,
    'image': image == null
        ? null
        : {
            'content_type': image.contentType,
            'size_bytes': image.sizeBytes,
            'version': image.version,
          },
  });
}

/// Admin access to Folien (`GET/POST/PATCH/DELETE /slides`, `PUT
/// /slides/order`, `POST/DELETE /slides/{id}/image`), siehe ADR 0014.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [SlidesApi]/`Dio`.
abstract class SlideAdminRepository {
  /// `GET /slides`: all slides, in `sort_order`.
  Future<List<Slide>> list();

  /// `POST /slides`.
  Future<Slide> create({
    required String title,
    String? body,
    int? durationSeconds,
    bool? active,
  });

  /// `PATCH /slides/{id}`: only the given fields are sent.
  Future<Slide> update(
    String id, {
    String? title,
    String? body,
    int? durationSeconds,
    bool? active,
  });

  /// `DELETE /slides/{id}`: echtes Löschen (Bild wird mitgelöscht).
  Future<void> delete(String id);

  /// `PUT /slides/order`: vollständige, geordnete Liste aller Folien-IDs.
  Future<void> reorder(List<String> slideIds);

  /// `POST /slides/{id}/image`: Rohdaten im Body mit passendem
  /// `Content-Type` (ADR 0014: über den generierten Client nicht
  /// abbildbar, daher direkt über `Dio`).
  Future<Slide> uploadImage(String id, Uint8List bytes, String contentType);

  /// `DELETE /slides/{id}/image` (idempotent).
  Future<void> deleteImage(String id);
}

/// [SlideAdminRepository] backed by the generated [SlidesApi] for
/// everything except image upload/delete, which go directly over [Dio]
/// since the generated client cannot send a raw-bytes body (ADR 0014).
class ApiSlideAdminRepository implements SlideAdminRepository {
  const ApiSlideAdminRepository(this._api, this._dio);

  final SlidesApi _api;
  final Dio _dio;

  @override
  Future<List<Slide>> list() async {
    final response = await _api.listSlides();
    final data =
        response.data ?? BuiltList<GetSnapshot200ResponseSlidesInner>();
    final slides = data.map(_slideFromApi).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return slides;
  }

  @override
  Future<Slide> create({
    required String title,
    String? body,
    int? durationSeconds,
    bool? active,
  }) async {
    final response = await _api.createSlide(
      createSlideRequest: CreateSlideRequest(
        (b) => b
          ..title = title
          ..body = body
          ..durationSeconds = durationSeconds
          ..active = active,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /slides returned no body');
    }
    return _slideFromApi(data);
  }

  @override
  Future<Slide> update(
    String id, {
    String? title,
    String? body,
    int? durationSeconds,
    bool? active,
  }) async {
    final response = await _api.updateSlide(
      id: id,
      updateSlideRequest: UpdateSlideRequest(
        (b) => b
          ..title = title
          ..body = body
          ..durationSeconds = durationSeconds
          ..active = active,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH /slides/{id} returned no body');
    }
    return _slideFromApi(data);
  }

  @override
  Future<void> delete(String id) async {
    await _api.deleteSlide(id: id);
  }

  @override
  Future<void> reorder(List<String> slideIds) async {
    await _api.reorderSlides(
      reorderSlidesRequest: ReorderSlidesRequest(
        (b) => b..slideIds.addAll(slideIds),
      ),
    );
  }

  @override
  Future<Slide> uploadImage(
    String id,
    Uint8List bytes,
    String contentType,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/slides/$id/image',
      data: bytes,
      options: Options(contentType: contentType),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /slides/{id}/image returned no body');
    }
    return Slide.fromJson(data);
  }

  @override
  Future<void> deleteImage(String id) async {
    await _dio.delete<void>('/api/v1/slides/$id/image');
  }
}

final slideAdminRepositoryProvider = Provider<SlideAdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final dio = ref.watch(dioProvider);
  return ApiSlideAdminRepository(apiClient.getSlidesApi(), dio);
});
