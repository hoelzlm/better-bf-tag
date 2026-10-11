import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HttpClientAdapter] that routes by path and returns a canned JSON
/// response, so [ApiProgramItemRepository] can be tested without any real
/// network calls (same pattern as announcement_repository_test.dart).
class _FakeProgramItemAdapter implements HttpClientAdapter {
  String? lastMethod;
  String? lastPath;
  Map<String, dynamic>? lastBody;
  int statusCode = 200;
  dynamic response = const <String, dynamic>{};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastMethod = options.method;
    lastPath = options.path;
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
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _programItemJson({
  String id = 'pi1',
  String bfDayId = 'day1',
  String title = 'Mittagessen',
  String type = 'meal',
  String startsAt = '2026-10-11T11:00:00.000Z',
  String endsAt = '2026-10-11T12:00:00.000Z',
}) {
  return {
    'id': id,
    'bf_day_id': bfDayId,
    'title': title,
    'type': type,
    'starts_at': startsAt,
    'ends_at': endsAt,
  };
}

void main() {
  late _FakeProgramItemAdapter adapter;
  late ApiProgramItemRepository repository;

  setUp(() {
    adapter = _FakeProgramItemAdapter();
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    final apiClient = BftagApiClient(dio: dio);
    repository = ApiProgramItemRepository(apiClient.getProgramItemsApi());
  });

  group('ApiProgramItemRepository.list (ADR 0025)', () {
    test('GET /bf-days/{day}/program-items', () async {
      adapter.response = [
        _programItemJson(id: 'pi1'),
        _programItemJson(id: 'pi2', type: 'training'),
      ];

      final items = await repository.list('day1');

      expect(adapter.lastMethod, 'GET');
      expect(adapter.lastPath, contains('/bf-days/day1/program-items'));
      expect(items, hasLength(2));
      expect(items[0].id, 'pi1');
      expect(items[0].type, ProgramItemType.meal);
      expect(items[1].type, ProgramItemType.training);
    });
  });

  group('ApiProgramItemRepository.create (ADR 0025)', () {
    // The admin UI hands local DateTimes from the date/time picker; the
    // generated client's Iso8601DateTimeSerializer throws on non-UTC
    // values before any request is sent.
    test('POST /bf-days/{day}/program-items sends local DateTimes as UTC', () async {
      adapter.response = _programItemJson();
      final startsAt = DateTime(2026, 10, 11, 13);
      final endsAt = DateTime(2026, 10, 11, 14);

      final item = await repository.create(
        'day1',
        title: 'Mittagessen',
        type: ProgramItemType.meal,
        startsAt: startsAt,
        endsAt: endsAt,
      );

      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, contains('/bf-days/day1/program-items'));
      expect(adapter.lastBody?['title'], 'Mittagessen');
      expect(adapter.lastBody?['type'], 'meal');
      expect(
        DateTime.parse(adapter.lastBody!['starts_at'] as String),
        startsAt.toUtc(),
      );
      expect(
        DateTime.parse(adapter.lastBody!['ends_at'] as String),
        endsAt.toUtc(),
      );
      expect(item.id, 'pi1');
      expect(item.type, ProgramItemType.meal);
    });
  });

  group('ApiProgramItemRepository.update (ADR 0025)', () {
    test('PATCH /program-items/{id} sends only the given fields', () async {
      adapter.response = _programItemJson(title: 'Abendessen');
      final startsAt = DateTime(2026, 10, 11, 18);

      final item = await repository.update(
        'pi1',
        title: 'Abendessen',
        startsAt: startsAt,
      );

      expect(adapter.lastMethod, 'PATCH');
      expect(adapter.lastPath, contains('/program-items/pi1'));
      expect(adapter.lastBody?['title'], 'Abendessen');
      expect(adapter.lastBody?.containsKey('type'), isFalse);
      expect(adapter.lastBody?.containsKey('ends_at'), isFalse);
      expect(
        DateTime.parse(adapter.lastBody!['starts_at'] as String),
        startsAt.toUtc(),
      );
      expect(item.title, 'Abendessen');
    });
  });

  group('ApiProgramItemRepository.delete (ADR 0025)', () {
    test('DELETE /program-items/{id}', () async {
      adapter.statusCode = 204;
      adapter.response = null;

      await repository.delete('pi1');

      expect(adapter.lastMethod, 'DELETE');
      expect(adapter.lastPath, contains('/program-items/pi1'));
    });
  });
}
