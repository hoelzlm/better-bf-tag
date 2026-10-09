import 'package:dio/dio.dart';

/// Extracts the backend's German error message from a [DioException]'s
/// `{ error: { code, message } }` body (see backend/src/errors.ts), falling
/// back to [fallback] for anything else (network errors, unexpected shape).
String describeApiError(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = (data['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
  }
  return fallback;
}

/// Extracts the `{ error: { code } }` from a [DioException]'s body, or
/// `null` for anything else.
String? _apiErrorCode(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final code = (data['error'] as Map)['code'];
      if (code is String) {
        return code;
      }
    }
  }
  return null;
}

/// German message for a Folien-Bild-Upload error (ADR 0014: `POST
/// /slides/{id}/image` maps 413 to `image_too_large` and 415 to
/// `unsupported_image_type`), falling back to [describeApiError] for
/// anything else.
String describeSlideImageError(Object error) {
  switch (_apiErrorCode(error)) {
    case 'image_too_large':
      return 'Bild ist zu groß (max. 5 MB).';
    case 'unsupported_image_type':
      return 'Nur PNG, JPEG oder WebP.';
  }
  return describeApiError(error, 'Bild konnte nicht hochgeladen werden.');
}
