import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/announcement.dart';
import 'dio_provider.dart';

Announcement _announcementFromApi(
  GetSnapshot200ResponseAnnouncementsInner a,
) {
  return Announcement(
    id: a.id,
    bfDayId: a.bfDayId,
    shiftId: a.shiftId,
    text: a.text,
    createdBy: a.createdBy,
    createdAt: DateTime.parse(a.createdAt),
  );
}

/// Access to Durchsagen (ADR 0024): `GET/POST /bf-days/{day}/announcements`,
/// `DELETE /announcements/{id}`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [AnnouncementsApi]/`Dio`.
abstract class AnnouncementRepository {
  /// `GET /bf-days/{day}/announcements`: all sichtbaren Durchsagen of
  /// [bfDayId], newest first.
  Future<List<Announcement>> list(String bfDayId);

  /// `POST /bf-days/{day}/announcements`. [text] is trimmed server-side
  /// to 1-500 characters; [shiftId] restricts visibility to that Schicht
  /// when given, otherwise the Durchsage is visible to everyone.
  Future<Announcement> create(
    String bfDayId, {
    required String text,
    String? shiftId,
  });

  /// `DELETE /announcements/{id}`.
  Future<void> delete(String id);
}

/// [AnnouncementRepository] backed by the generated [AnnouncementsApi].
class ApiAnnouncementRepository implements AnnouncementRepository {
  const ApiAnnouncementRepository(this._api);

  final AnnouncementsApi _api;

  @override
  Future<List<Announcement>> list(String bfDayId) async {
    final response = await _api.listAnnouncements(day: bfDayId);
    final data = response.data ??
        BuiltList<GetSnapshot200ResponseAnnouncementsInner>();
    return data.map(_announcementFromApi).toList();
  }

  @override
  Future<Announcement> create(
    String bfDayId, {
    required String text,
    String? shiftId,
  }) async {
    final response = await _api.createAnnouncement(
      day: bfDayId,
      createAnnouncementRequest: CreateAnnouncementRequest(
        (b) => b
          ..text = text
          ..shiftId = shiftId,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError(
        'POST /bf-days/{day}/announcements returned no body',
      );
    }
    return _announcementFromApi(data);
  }

  @override
  Future<void> delete(String id) async {
    await _api.deleteAnnouncement(id: id);
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiAnnouncementRepository(apiClient.getAnnouncementsApi());
});
