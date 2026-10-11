import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_provider.dart';

/// A single Adresssuche result (ADR 0026, `GET /geocode`).
class GeocodeSuggestion {
  const GeocodeSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

/// Access to the backend's Geocoding-Proxy (ADR 0026):
/// `GET /geocode?q=`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [GeocodeApi]/`Dio`.
abstract class GeocodeRepository {
  /// Looks up [q] (Adresse/Ort). Never throws: any failure (validation,
  /// network, disabled upstream) returns an empty list, mirroring the
  /// backend's `{ results: [] }` fallback behaviour.
  Future<List<GeocodeSuggestion>> search(String q);
}

/// [GeocodeRepository] backed by the generated [GeocodeApi].
class ApiGeocodeRepository implements GeocodeRepository {
  const ApiGeocodeRepository(this._api);

  final GeocodeApi _api;

  @override
  Future<List<GeocodeSuggestion>> search(String q) async {
    try {
      final response = await _api.geocode(q: q);
      final results =
          response.data?.results ?? BuiltList<Geocode200ResponseResultsInner>();
      return results
          .map(
            (r) => GeocodeSuggestion(
              label: r.label,
              latitude: r.latitude.toDouble(),
              longitude: r.longitude.toDouble(),
            ),
          )
          .toList();
    } on DioException {
      return const [];
    }
  }
}

final geocodeRepositoryProvider = Provider<GeocodeRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiGeocodeRepository(apiClient.getGeocodeApi());
});
