import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/shift.dart';
import 'dio_provider.dart';

Shift _shiftFromApi(GetSnapshot200ResponseShiftsInner s) {
  return Shift(
    id: s.id,
    bfDayId: s.bfDayId,
    name: s.name,
    startsAt: DateTime.parse(s.startsAt),
    endsAt: DateTime.parse(s.endsAt),
    crew: s.crew
        .map(
          (c) => CrewAssignment(
            vehicleId: c.vehicleId,
            personId: c.personId,
            displayName: c.displayName,
            function: c.function_,
          ),
        )
        .toList(),
  );
}

/// Input for [ShiftRepository.setCrew]: one Besatzung entry (ADR 0013).
class CrewAssignmentInput {
  const CrewAssignmentInput({
    required this.vehicleId,
    required this.personId,
    required this.function,
  });

  final String vehicleId;
  final String personId;
  final String function;
}

/// Admin access to Schichten (ADR 0013): `GET/POST/PATCH/DELETE
/// /bf-days/{day}/shifts`, `PUT /shifts/{id}/crew`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [ShiftsApi]/`Dio`.
abstract class ShiftRepository {
  /// `GET /bf-days/{day}/shifts`: all shifts of a BF-Tag, with crew.
  Future<List<Shift>> listShifts(String day);

  /// `POST /bf-days/{day}/shifts`.
  Future<Shift> createShift(
    String day, {
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  });

  /// `PATCH /bf-days/{day}/shifts/{id}`: only the given fields are sent.
  Future<Shift> updateShift(
    String day,
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  });

  /// `DELETE /bf-days/{day}/shifts/{id}`. Fails (`last_shift`) if this is
  /// the only shift of a running BF-Tag.
  Future<void> deleteShift(String day, String id);

  /// `PUT /shifts/{id}/crew`: full replacement of the shift's crew.
  Future<Shift> setCrew(String shiftId, List<CrewAssignmentInput> assignments);
}

/// [ShiftRepository] backed by the generated [ShiftsApi].
class ApiShiftRepository implements ShiftRepository {
  const ApiShiftRepository(this._api);

  final ShiftsApi _api;

  @override
  Future<List<Shift>> listShifts(String day) async {
    final response = await _api.listShifts(day: day);
    final data =
        response.data ?? BuiltList<GetSnapshot200ResponseShiftsInner>();
    return data.map(_shiftFromApi).toList();
  }

  @override
  Future<Shift> createShift(
    String day, {
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    final response = await _api.createShift(
      day: day,
      createBfDayRequest: CreateBfDayRequest(
        (b) => b
          ..name = name
          ..startsAt = startsAt
          ..endsAt = endsAt,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /bf-days/{day}/shifts returned no body');
    }
    return _shiftFromApi(data);
  }

  @override
  Future<Shift> updateShift(
    String day,
    String id, {
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final response = await _api.updateShift(
      day: day,
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
      throw StateError('PATCH /bf-days/{day}/shifts/{id} returned no body');
    }
    return _shiftFromApi(data);
  }

  @override
  Future<void> deleteShift(String day, String id) async {
    await _api.deleteShift(day: day, id: id);
  }

  @override
  Future<Shift> setCrew(
    String shiftId,
    List<CrewAssignmentInput> assignments,
  ) async {
    final response = await _api.setShiftCrew(
      id: shiftId,
      setShiftCrewRequest: SetShiftCrewRequest(
        (b) => b.assignments.addAll(
          assignments.map(
            (a) => SetShiftCrewRequestAssignmentsInner(
              (ab) => ab
                ..vehicleId = a.vehicleId
                ..personId = a.personId
                ..function_ = a.function,
            ),
          ),
        ),
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PUT /shifts/{id}/crew returned no body');
    }
    return _shiftFromApi(data);
  }
}

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiShiftRepository(apiClient.getShiftsApi());
});
