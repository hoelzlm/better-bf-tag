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

/// German message for `POST /incidents/{id}/alarms` (ADR 0017): a 409
/// `invalid_state_transition` means a Erstalarm was already triggered for
/// this Einsatz (e.g. a stale dialog, or another dispatcher got there
/// first) -- phrased as a plain notice, not as an error. Falls back to
/// [describeApiError] for anything else.
String describeAlarmTriggerError(Object error) {
  if (_apiErrorCode(error) == 'invalid_state_transition') {
    return 'Einsatz wurde bereits alarmiert.';
  }
  return describeApiError(error, 'Alarmierung konnte nicht ausgelöst werden.');
}

/// German message for `POST /bf-days/{id}/anonymize` and `GET
/// /bf-days/{id}/anonymization-preview` (ADR 0020): a 409
/// `bf_day_not_ended` means the BF-Tag hasn't ended yet, a 409
/// `bf_day_already_anonymized` means it was already anonymized (e.g. a
/// stale dialog, or a double click). Falls back to [describeApiError] for
/// anything else.
String describeAnonymizationError(Object error) {
  switch (_apiErrorCode(error)) {
    case 'bf_day_not_ended':
      return 'BF-Tag ist noch nicht beendet.';
    case 'bf_day_already_anonymized':
      return 'BF-Tag wurde bereits anonymisiert.';
  }
  return describeApiError(error, 'BF-Tag konnte nicht anonymisiert werden.');
}
