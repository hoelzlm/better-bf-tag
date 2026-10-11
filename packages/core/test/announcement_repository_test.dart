import 'dart:convert';
import 'dart:typed_data';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [HttpClientAdapter] that routes by path and returns a canned JSON
/// response, so [ApiAnnouncementRepository] can be tested without any
/// real network calls (same pattern as alarm_repository_test.dart).
class _FakeAnnouncementAdapter implements HttpClientAdapter {
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

Map<String, dynamic> _announcementJson({
  String id = 'ann1',
  String bfDayId = 'day1',
  String? shiftId,
  String text = 'Essen ist fertig',
  String createdBy = 'p1',
  String createdAt = '2026-10-11T10:00:00Z',
}) {
  return {
    'id': id,
    'bf_day_id': bfDayId,
    'shift_id': shiftId,
    'text': text,
    'created_by': createdBy,
    'created_at': createdAt,
  };
}

void main() {
  late _FakeAnnouncementAdapter adapter;
  late ApiAnnouncementRepository repository;

  setUp(() {
    adapter = _FakeAnnouncementAdapter();
    final dio = Dio(BaseOptions(baseUrl: ''));
    dio.httpClientAdapter = adapter;
    final apiClient = BftagApiClient(dio: dio);
    repository = ApiAnnouncementRepository(apiClient.getAnnouncementsApi());
  });

  group('ApiAnnouncementRepository.list (ADR 0024)', () {
    test('GET /bf-days/{day}/announcements', () async {
      adapter.response = [
        _announcementJson(id: 'ann1'),
        _announcementJson(id: 'ann2', shiftId: 'shift1'),
      ];

      final announcements = await repository.list('day1');

      expect(adapter.lastMethod, 'GET');
      expect(adapter.lastPath, contains('/bf-days/day1/announcements'));
      expect(announcements, hasLength(2));
      expect(announcements[0].id, 'ann1');
      expect(announcements[0].shiftId, isNull);
      expect(announcements[1].shiftId, 'shift1');
    });
  });

  group('ApiAnnouncementRepository.create (ADR 0024)', () {
    test('POST /bf-days/{day}/announcements without shift_id', () async {
      adapter.response = _announcementJson();

      final announcement = await repository.create(
        'day1',
        text: 'Essen ist fertig',
      );

      expect(adapter.lastMethod, 'POST');
      expect(adapter.lastPath, contains('/bf-days/day1/announcements'));
      expect(adapter.lastBody?['text'], 'Essen ist fertig');
      expect(adapter.lastBody?.containsKey('shift_id'), isFalse);
      expect(announcement.id, 'ann1');
      expect(announcement.text, 'Essen ist fertig');
      expect(announcement.shiftId, isNull);
      expect(
        announcement.createdAt,
        DateTime.parse('2026-10-11T10:00:00Z'),
      );
    });

    test('POST /bf-days/{day}/announcements with shift_id', () async {
      adapter.response = _announcementJson(shiftId: 'shift1');

      final announcement = await repository.create(
        'day1',
        text: 'Nur für die Tagschicht',
        shiftId: 'shift1',
      );

      expect(adapter.lastBody?['shift_id'], 'shift1');
      expect(announcement.shiftId, 'shift1');
    });
  });

  group('ApiAnnouncementRepository.delete (ADR 0024)', () {
    test('DELETE /announcements/{id}', () async {
      adapter.statusCode = 204;
      adapter.response = null;

      await repository.delete('ann1');

      expect(adapter.lastMethod, 'DELETE');
      expect(adapter.lastPath, contains('/announcements/ann1'));
    });
  });
}
