import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/vehicle.dart';
import 'dio_provider.dart';

/// Maps a [VehicleAdminRepository.setStatus] failure to a German,
/// user-safe message (ADR 0015): 403 means the Person is not Besatzung of
/// the Fahrzeug (and has no `dispatch`/`admin` override); 409
/// `status_not_allowed` means Status 7/8 was requested for a Fahrzeug that
/// is not RTW/KTW. Anything else (network, 409 `vehicle_inactive`, ...)
/// falls back to a generic message.
String describeSetStatusError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 403) {
      return 'Du bist nicht in der Besatzung dieses Fahrzeugs.';
    }
    if (statusCode == 409) {
      final data = error.response?.data;
      final errorBody = data is Map ? data['error'] : null;
      final code = errorBody is Map ? errorBody['code'] : null;
      if (code == 'status_not_allowed') {
        return 'Status nicht erlaubt für dieses Fahrzeug.';
      }
    }
  }
  return 'Status konnte nicht gesetzt werden.';
}

Vehicle _vehicleFromApi(ListVehicles200ResponseInner v) {
  return Vehicle.fromJson({
    'id': v.id,
    'call_sign': v.callSign,
    'short_name': v.shortName,
    'type': v.type,
    'status': v.status,
    'status_changed_at': v.statusChangedAt,
    'sort_order': v.sortOrder,
    'active': v.active,
  });
}

/// Admin access to Fahrzeuge (`GET/POST/PATCH /vehicles`, `PUT
/// /vehicles/order`, `PUT /vehicles/{id}/status`). Unlike [vehiclesProvider]
/// (realtime, active-only), this reflects a one-shot REST read/write and
/// includes inactive vehicles.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [VehiclesApi]/`Dio`.
abstract class VehicleAdminRepository {
  /// `GET /vehicles`: all vehicles (incl. inactive), in `sort_order`.
  Future<List<Vehicle>> listAll();

  /// `POST /vehicles`.
  Future<Vehicle> create({
    required String callSign,
    required String shortName,
    required String type,
  });

  /// `PATCH /vehicles/{id}`: only the given fields are sent.
  Future<Vehicle> update(
    String id, {
    String? callSign,
    String? shortName,
    String? type,
    bool? active,
  });

  /// `PUT /vehicles/order`: full ordered list of vehicle ids.
  Future<void> reorder(List<String> vehicleIds);

  /// `PUT /vehicles/{id}/status`. The UI should not optimistically apply
  /// this; the realtime `vehicle.status_changed` event updates the state.
  Future<void> setStatus(String id, int status);
}

/// [VehicleAdminRepository] backed by the generated [VehiclesApi].
class ApiVehicleAdminRepository implements VehicleAdminRepository {
  const ApiVehicleAdminRepository(this._api);

  final VehiclesApi _api;

  @override
  Future<List<Vehicle>> listAll() async {
    final response = await _api.listVehicles();
    final data = response.data ?? BuiltList<ListVehicles200ResponseInner>();
    final vehicles = data.map(_vehicleFromApi).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return vehicles;
  }

  @override
  Future<Vehicle> create({
    required String callSign,
    required String shortName,
    required String type,
  }) async {
    final response = await _api.createVehicle(
      createVehicleRequest: CreateVehicleRequest(
        (b) => b
          ..callSign = callSign
          ..shortName = shortName
          ..type = type,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /vehicles returned no body');
    }
    return _vehicleFromApi(data);
  }

  @override
  Future<Vehicle> update(
    String id, {
    String? callSign,
    String? shortName,
    String? type,
    bool? active,
  }) async {
    final response = await _api.updateVehicle(
      id: id,
      updateVehicleRequest: UpdateVehicleRequest(
        (b) => b
          ..callSign = callSign
          ..shortName = shortName
          ..type = type
          ..active = active,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH /vehicles/{id} returned no body');
    }
    return _vehicleFromApi(data);
  }

  @override
  Future<void> reorder(List<String> vehicleIds) async {
    await _api.reorderVehicles(
      reorderVehiclesRequest: ReorderVehiclesRequest(
        (b) => b..vehicleIds.addAll(vehicleIds),
      ),
    );
  }

  @override
  Future<void> setStatus(String id, int status) async {
    await _api.setVehicleStatus(
      id: id,
      setVehicleStatusRequest: SetVehicleStatusRequest(
        (b) => b..status = status,
      ),
    );
  }
}

final vehicleAdminRepositoryProvider = Provider<VehicleAdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiVehicleAdminRepository(apiClient.getVehiclesApi());
});
