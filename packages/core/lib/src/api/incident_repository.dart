import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/incident.dart';
import 'dio_provider.dart';

Incident _incidentFromApi(GetSnapshot200ResponseIncidentsInner i) {
  return Incident.fromJson({
    'id': i.id,
    'bf_day_id': i.bfDayId,
    'number': i.number,
    'keyword': i.keyword,
    'address': i.address,
    'report': i.report,
    'state': i.state.name,
    'created_at': i.createdAt,
    'updated_at': i.updatedAt,
    // The generated model always exposes `script` (as `null` when the
    // wire payload omitted it), so the `containsKey` check in
    // [Incident.fromJson] would always be true here; explicitly drop the
    // key to preserve "field absent means no permission" (ADR 0016).
    if (i.script != null) 'script': i.script,
  });
}

String _wireState(IncidentState state) {
  switch (state) {
    case IncidentState.draft:
      return 'draft';
    case IncidentState.running:
      return 'running';
    case IncidentState.closed:
      return 'closed';
    case IncidentState.discarded:
      return 'discarded';
  }
}

/// Maps an [IncidentRepository] failure to a German, user-safe message
/// (ADR 0016): the backend already returns a localized `error.message`
/// for `incident_not_editable`, `invalid_state_transition`, and
/// `bf_day_ended` (and any other 4xx); this just extracts it, falling
/// back to [fallback] for anything else (network errors, unexpected
/// shape).
String describeIncidentError(
  Object error, {
  String fallback = 'Einsatz konnte nicht gespeichert werden.',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = (data['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
  }
  return fallback;
}

/// Whether [error] is the 404 `not_found` the backend returns for
/// `GET /bf-days/current/incidents` (and `.../current`) when no BF-Tag is
/// running (ADR 0016 via `resolveBfDay`). Lets callers show "Kein
/// laufender BF-Tag." instead of a generic error message.
bool isNoRunningBfDayError(Object error) {
  return error is DioException && error.response?.statusCode == 404;
}

/// Access to Einsätze (ADR 0016): `GET/POST /bf-days/{day}/incidents`,
/// `GET/PATCH /incidents/{id}`, `POST /incidents/{id}/discard`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [IncidentsApi]/`Dio`. Works with both
/// the web admin session's `Dio` and the paired (app) session's `Dio`,
/// via whichever [apiClientProvider] is in scope.
abstract class IncidentRepository {
  /// `GET /bf-days/{day}/incidents[?state=...]`, sorted by `number`.
  /// `day` may also be `current` (resolves to the running BF-Tag).
  Future<List<Incident>> list(String day, {IncidentState? state});

  /// `GET /incidents/{id}`.
  Future<Incident> get(String id);

  /// `POST /bf-days/{day}/incidents` -> 201 `draft`. Fails
  /// (`bf_day_ended`) if the BF-Tag has already ended.
  Future<Incident> create(
    String day, {
    required String keyword,
    required String address,
    String? report,
    String? script,
  });

  /// `PATCH /incidents/{id}`: only the given fields are sent. Fails
  /// (`incident_not_editable`) for `closed`/`discarded` Einsätze.
  Future<Incident> update(
    String id, {
    String? keyword,
    String? address,
    String? report,
    String? script,
  });

  /// `POST /incidents/{id}/discard`. Fails (`invalid_state_transition`)
  /// unless the Einsatz is still `draft`.
  Future<Incident> discard(String id);
}

/// [IncidentRepository] backed by the generated [IncidentsApi].
class ApiIncidentRepository implements IncidentRepository {
  const ApiIncidentRepository(this._api);

  final IncidentsApi _api;

  @override
  Future<List<Incident>> list(String day, {IncidentState? state}) async {
    final response = await _api.listIncidents(
      day: day,
      state: state == null ? null : _wireState(state),
    );
    final data =
        response.data ?? BuiltList<GetSnapshot200ResponseIncidentsInner>();
    return data.map(_incidentFromApi).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  @override
  Future<Incident> get(String id) async {
    final response = await _api.getIncident(id: id);
    final data = response.data;
    if (data == null) {
      throw StateError('GET /incidents/{id} returned no body');
    }
    return _incidentFromApi(data);
  }

  @override
  Future<Incident> create(
    String day, {
    required String keyword,
    required String address,
    String? report,
    String? script,
  }) async {
    final response = await _api.createIncident(
      day: day,
      createIncidentRequest: CreateIncidentRequest(
        (b) => b
          ..keyword = keyword
          ..address = address
          ..report = report
          ..script = script,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /bf-days/{day}/incidents returned no body');
    }
    return _incidentFromApi(data);
  }

  @override
  Future<Incident> update(
    String id, {
    String? keyword,
    String? address,
    String? report,
    String? script,
  }) async {
    final response = await _api.updateIncident(
      id: id,
      updateIncidentRequest: UpdateIncidentRequest(
        (b) => b
          ..keyword = keyword
          ..address = address
          ..report = report
          ..script = script,
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH /incidents/{id} returned no body');
    }
    return _incidentFromApi(data);
  }

  @override
  Future<Incident> discard(String id) async {
    final response = await _api.discardIncident(id: id);
    final data = response.data;
    if (data == null) {
      throw StateError('POST /incidents/{id}/discard returned no body');
    }
    return _incidentFromApi(data);
  }
}

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiIncidentRepository(apiClient.getIncidentsApi());
});
