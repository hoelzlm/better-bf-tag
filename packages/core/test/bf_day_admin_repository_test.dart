import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HttpClientAdapter] that records the request body and returns a
/// canned JSON response (same pattern as alarm_repository_test.dart).
class _FakeBfDayAdapter implements HttpClientAdapter {
  int calls = 0;
  Map<String, dynamic>? lastBody;
  Map<String, dynamic> response = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      if (bytes.isNotEmpty) {
        lastBody = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      }
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _bfDayJson = {
  'id': 'd1',
  'name': 'BF-Tag 2026',
  'starts_at': '2026-10-12T08:00:00.000Z',
  'ends_at': '2026-10-13T08:00:00.000Z',
  'state': 'planning',
  'anonymized_at': null,
  'created_at': '2026-10-11T08:00:00.000Z',
};

void main() {
  late _FakeBfDayAdapter adapter;
  late ApiBfDayAdminRepository repository;

  setUp(() {
    adapter = _FakeBfDayAdapter()..response = _bfDayJson;
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    repository = ApiBfDayAdminRepository(
      BftagApiClient(dio: dio).getBfDaysApi(),
    );
  });

  // The admin UI hands local DateTimes from the date/time picker; the
  // generated client's Iso8601DateTimeSerializer throws on non-UTC values
  // before any request is sent.
  test('create sends local DateTimes as UTC', () async {
    final startsAt = DateTime(2026, 10, 12, 10);
    final endsAt = DateTime(2026, 10, 13, 10);

    await repository.create(
      name: 'BF-Tag 2026',
      startsAt: startsAt,
      endsAt: endsAt,
    );

    expect(adapter.calls, 1);
    expect(
      DateTime.parse(adapter.lastBody!['starts_at'] as String),
      startsAt.toUtc(),
    );
    expect(
      DateTime.parse(adapter.lastBody!['ends_at'] as String),
      endsAt.toUtc(),
    );
  });

  test('update sends local DateTimes as UTC', () async {
    final startsAt = DateTime(2026, 10, 12, 10);

    await repository.update('d1', startsAt: startsAt);

    expect(adapter.calls, 1);
    expect(
      DateTime.parse(adapter.lastBody!['starts_at'] as String),
      startsAt.toUtc(),
    );
  });
}
