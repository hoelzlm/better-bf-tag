import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HttpClientAdapter], same pattern as announcement_repository_test.dart.
class _FakeGeocodeAdapter implements HttpClientAdapter {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastQueryParameters;
  int statusCode = 200;
  dynamic response = const <String, dynamic>{'results': <dynamic>[]};
  Object? throwOnFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (throwOnFetch != null) {
      throw throwOnFetch!;
    }
    lastMethod = options.method;
    lastPath = options.path;
    lastQueryParameters = options.queryParameters;
    return ResponseBody.fromString(
      jsonEncode(response),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeGeocodeAdapter adapter;
  late ApiGeocodeRepository repository;

  setUp(() {
    adapter = _FakeGeocodeAdapter();
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    final apiClient = BftagApiClient(dio: dio);
    repository = ApiGeocodeRepository(apiClient.getGeocodeApi());
  });

  group('ApiGeocodeRepository.search (ADR 0026)', () {
    test('GET /geocode?q= maps results to GeocodeSuggestion', () async {
      adapter.response = {
        'results': [
          {'label': 'Hauptstraße 1, Musterstadt', 'latitude': 52.5, 'longitude': 13.4},
          {'label': 'Hauptstraße 2, Musterstadt', 'latitude': 52.6, 'longitude': 13.5},
        ],
      };

      final results = await repository.search('Hauptstraße');

      expect(adapter.lastMethod, 'GET');
      expect(adapter.lastPath, contains('/geocode'));
      expect(adapter.lastQueryParameters?['q'], 'Hauptstraße');
      expect(results, hasLength(2));
      expect(results[0].label, 'Hauptstraße 1, Musterstadt');
      expect(results[0].latitude, 52.5);
      expect(results[0].longitude, 13.4);
      expect(results[1].longitude, 13.5);
    });

    test('empty results -> empty list', () async {
      adapter.response = {'results': <dynamic>[]};

      final results = await repository.search('xyz');

      expect(results, isEmpty);
    });

    test('DioException (network/5xx/validation) -> empty list, never throws', () async {
      adapter.throwOnFetch = DioException(
        requestOptions: RequestOptions(path: '/geocode'),
        type: DioExceptionType.connectionError,
      );

      final results = await repository.search('Hauptstraße');

      expect(results, isEmpty);
    });
  });
}
