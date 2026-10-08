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
