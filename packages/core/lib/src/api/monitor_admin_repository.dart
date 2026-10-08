import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/monitor.dart';
import 'dio_provider.dart';

Monitor _monitorFromApi(ListMonitors200ResponseInner m) {
  return Monitor(
    id: m.id,
    name: m.name,
    paired: m.paired,
    pairedAt: m.pairedAt == null ? null : DateTime.parse(m.pairedAt!),
    lastSeenAt: m.lastSeenAt == null ? null : DateTime.parse(m.lastSeenAt!),
    revokedAt: m.revokedAt == null ? null : DateTime.parse(m.revokedAt!),
    createdAt: DateTime.parse(m.createdAt),
  );
}

MonitorPairingCode _pairingCodeFromApi(
  CreateMonitorPairingCode201Response r,
) {
  return MonitorPairingCode(
    monitorId: r.monitorId,
    name: r.name,
    code: r.code,
    expiresAt: DateTime.parse(r.expiresAt),
  );
}

/// Admin access to Monitore (`GET/POST/PATCH/DELETE /monitors`,
/// `POST /monitors/{id}/pairing-code`), siehe ADR 0012.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [MonitorsApi]/`Dio`.
abstract class MonitorAdminRepository {
  /// `GET /monitors`: all monitors, sorted by name.
  Future<List<Monitor>> listMonitors();

  /// `POST /monitors`.
  Future<Monitor> createMonitor({required String name});

  /// `PATCH /monitors/{id}`.
  Future<Monitor> updateMonitor(String id, {required String name});

  /// `DELETE /monitors/{id}`: sperren (idempotent).
  Future<void> revokeMonitor(String id);

  /// `POST /monitors/{id}/pairing-code`.
  Future<MonitorPairingCode> createPairingCode(String id);
}

/// [MonitorAdminRepository] backed by the generated [MonitorsApi].
class ApiMonitorAdminRepository implements MonitorAdminRepository {
  const ApiMonitorAdminRepository(this._api);

  final MonitorsApi _api;

  @override
  Future<List<Monitor>> listMonitors() async {
    final response = await _api.listMonitors();
    final data = response.data ?? BuiltList<ListMonitors200ResponseInner>();
    return data.map(_monitorFromApi).toList();
  }

  @override
  Future<Monitor> createMonitor({required String name}) async {
    final response = await _api.createMonitor(
      createMonitorRequest: CreateMonitorRequest((b) => b..name = name),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /monitors returned no body');
    }
    return _monitorFromApi(data);
  }

  @override
  Future<Monitor> updateMonitor(String id, {required String name}) async {
    final response = await _api.updateMonitor(
      id: id,
      createMonitorRequest: CreateMonitorRequest((b) => b..name = name),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH /monitors/{id} returned no body');
    }
    return _monitorFromApi(data);
  }

  @override
  Future<void> revokeMonitor(String id) async {
    await _api.revokeMonitor(id: id);
  }

  @override
  Future<MonitorPairingCode> createPairingCode(String id) async {
    final response = await _api.createMonitorPairingCode(id: id);
    final data = response.data;
    if (data == null) {
      throw StateError(
        'POST /monitors/{id}/pairing-code returned no body',
      );
    }
    return _pairingCodeFromApi(data);
  }
}

final monitorAdminRepositoryProvider = Provider<MonitorAdminRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiMonitorAdminRepository(apiClient.getMonitorsApi());
});
