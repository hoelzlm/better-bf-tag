import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration for talking to the backend API.
///
/// [baseUrl] empty means "same origin" (the API is served from the same
/// origin as the web app, e.g. behind Caddy in production).
class ApiConfig {
  const ApiConfig({required this.baseUrl});

  final String baseUrl;
}

/// The API base URL, injected via `--dart-define=API_BASE_URL=...`.
///
/// An empty string means same origin.
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: '',
);

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return const ApiConfig(baseUrl: _apiBaseUrl);
});
