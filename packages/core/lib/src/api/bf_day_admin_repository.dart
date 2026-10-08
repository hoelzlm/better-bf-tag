import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/bf_day.dart';
import '../domain/participant.dart';
import '../domain/permission.dart';
import 'dio_provider.dart';

BfDay _bfDayFromApi(ListBfDays200ResponseInner d) {
  return BfDay(
    id: d.id,
    name: d.name,
    startsAt: DateTime.parse(d.startsAt),
    endsAt: DateTime.parse(d.endsAt),
    state: BfDayState.fromWire(d.state.name),
  );
}

PersonType _personTypeFromApi(
  ListParticipants200ResponseInnerPersonTypeEnum type,
) {
  switch (type.name) {
    case 'youth':
      return PersonType.youth;
    case 'supervisor':
      return PersonType.supervisor;
  }
  throw ArgumentError('Unknown person_type wire value: ${type.name}');
}

Participant _participantFromApi(ListParticipants200ResponseInner p) {
  return Participant(
    personId: p.personId,
    displayName: p.displayName,
    personType: _personTypeFromApi(p.personType),
    permission: Permission.fromApi(p.permission.name),
    fireDepartmentId: p.fireDepartmentId,
  );
}

/// Admin access to BF-Tage und deren Teilnahmen (ADR 0013): `GET/POST/PATCH
/// /bf-days`, `POST /bf-days/{id}/start|end`, `GET/PUT
/// /bf-days/{day}/participants`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [BfDaysApi]/`Dio`.
abstract class BfDayAdminRepository {
  /// `GET /bf-days`: all BF-Tage.
  Future<List<BfDay>> list();

  /// `POST /bf-days`.
  Future<BfDay> create({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  });

  /// `PATCH /bf-days/{id}`: only the given fields are sent. Fails
  /// (`invalid_state_transition`) once the BF-Tag has started.
  Future<BfDay> update(
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  /// `POST /bf-days/{id}/start`. Fails (`bf_day_already_running`) if
  /// another BF-Tag is already running.
  Future<BfDay> start(String id);

  /// `POST /bf-days/{id}/end`.
  Future<BfDay> end(String id);

  /// `GET /bf-days/{day}/participants`: active Personen teilnehmend an
  /// diesem BF-Tag.
  Future<List<Participant>> listParticipants(String day);

  /// `PUT /bf-days/{day}/participants`: full replacement of the
  /// participant list by person id.
  Future<void> setParticipants(String day, List<String> personIds);
}

/// [BfDayAdminRepository] backed by the generated [BfDaysApi].
class ApiBfDayAdminRepository implements BfDayAdminRepository {
  const ApiBfDayAdminRepository(this._api);

  final BfDaysApi _api;

  @override
  Future<List<BfDay>> list() async {
    final response = await _api.listBfDays();
    final data = response.data ?? BuiltList<ListBfDays200ResponseInner>();
    return data.map(_bfDayFromApi).toList();
  }

  @override
  Future<BfDay> create({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final response = await _api.createBfDay(
      createBfDayRequest: CreateBfDayRequest(
        (b) => b
          ..name = name
          ..startsAt = startsAt
          ..endsAt = endsAt,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /bf-days returned no body');
    }
    return _bfDayFromApi(data);
  }

  @override
  Future<BfDay> update(
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final response = await _api.updateBfDay(
      id: id,
      updateBfDayRequest: UpdateBfDayRequest(
        (b) => b
          ..name = name
          ..startsAt = startsAt
          ..endsAt = endsAt,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH /bf-days/{id} returned no body');
    }
    return _bfDayFromApi(data);
  }

  @override
  Future<BfDay> start(String id) async {
    final response = await _api.startBfDay(id: id);
    final data = response.data;
    if (data == null) {
      throw StateError('POST /bf-days/{id}/start returned no body');
    }
    return _bfDayFromApi(data);
  }

  @override
  Future<BfDay> end(String id) async {
    final response = await _api.endBfDay(id: id);
    final data = response.data;
    if (data == null) {
      throw StateError('POST /bf-days/{id}/end returned no body');
    }
    return _bfDayFromApi(data);
  }

  @override
  Future<List<Participant>> listParticipants(String day) async {
    final response = await _api.listParticipants(day: day);
    final data =
        response.data ?? BuiltList<ListParticipants200ResponseInner>();
    return data.map(_participantFromApi).toList();
  }

  @override
  Future<void> setParticipants(String day, List<String> personIds) async {
    await _api.setParticipants(
      day: day,
      setParticipantsRequest: SetParticipantsRequest(
        (b) => b..personIds.addAll(personIds),
      ),
    );
  }
}

final bfDayAdminRepositoryProvider = Provider<BfDayAdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiBfDayAdminRepository(apiClient.getBfDaysApi());
});
