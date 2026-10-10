import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/alarm.dart';
import 'dio_provider.dart';

/// Generates a fresh v4 UUID, for the idempotency `id` a client creates
/// once when opening the Alarmieren-Dialog (ADR 0017).
String newIdempotencyId() => const Uuid().v4();

AlarmRecipient _recipientFromApi(
  GetSnapshot200ResponseAlarmsInnerRecipientsInner r,
) {
  return AlarmRecipient(
    personId: r.personId,
    displayName: r.displayName,
    vehicleId: r.vehicleId,
    function: r.function_,
    hasDevice: r.hasDevice,
    acknowledgedAt:
        r.acknowledgedAt == null ? null : DateTime.parse(r.acknowledgedAt!),
  );
}

Alarm _alarmFromApi(GetSnapshot200ResponseAlarmsInner a) {
  return Alarm(
    id: a.id,
    incidentId: a.incidentId,
    state: AlarmState.fromWire(a.state.name),
    scheduledAt: a.scheduledAt == null ? null : DateTime.parse(a.scheduledAt!),
    triggeredAt: a.triggeredAt == null ? null : DateTime.parse(a.triggeredAt!),
    vehicleIds: a.vehicleIds.toList(),
    recipients: a.recipients.map(_recipientFromApi).toList(),
    pushDelivered: a.pushDelivered,
    pushRejected: a.pushRejected,
    relativeToAlarmId: a.relativeToAlarmId,
    offsetMinutes: a.offsetMinutes,
  );
}

DoubleCrewed _doubleCrewedFromApi(
  CreateAlarm200ResponseDoubleCrewedInner d,
) {
  return DoubleCrewed(
    personId: d.personId,
    displayName: d.displayName,
    vehicleIds: d.vehicleIds.toList(),
  );
}

/// Result of [AlarmRepository.trigger]/[AlarmRepository.triggerNow]: the
/// created (or, on idempotent repeat, the existing) [Alarm], and
/// [doubleCrewed] -- Personen, die auf mehr als einem der alarmierten
/// Fahrzeuge sitzen (leer bei Wiederholung, ADR 0017).
class TriggerAlarmResult {
  const TriggerAlarmResult({required this.alarm, required this.doubleCrewed});

  final Alarm alarm;
  final List<DoubleCrewed> doubleCrewed;
}

/// Access to Alarmierungen (ADR 0017) and geplante/verpasste
/// Alarmierungen (ADR 0022): `POST /incidents/{id}/alarms`,
/// `POST /alarms/{id}/acknowledge`, `PATCH /alarms/{id}`,
/// `POST /alarms/{id}/discard`, `POST /alarms/{id}/trigger`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [AlarmsApi]/`Dio`.
abstract class AlarmRepository {
  /// `POST /incidents/{id}/alarms`. [id] is the client-generated
  /// idempotency key (ADR 0017): a repeated call with the same [id] for
  /// the same Einsatz returns the existing Alarmierung with an empty
  /// `double_crewed`, without a new event.
  Future<TriggerAlarmResult> trigger(
    String incidentId,
    List<String> vehicleIds, {
    required String id,
  });

  /// `POST /alarms/{id}/acknowledge`. Idempotent: a repeated call is a
  /// no-op (ADR 0017).
  Future<void> acknowledge(String alarmId);

  /// `POST /incidents/{id}/alarms` with `scheduled_at` or
  /// `relative_to_alarm_id`/`offset_minutes` (ADR 0022): plant eine
  /// Alarmierung statt sie sofort auszulösen. [id] is the
  /// client-generated idempotency key, like [trigger].
  Future<Alarm> plan(
    String incidentId,
    List<String> vehicleIds, {
    String? id,
    DateTime? scheduledAt,
    int? offsetMinutes,
  });

  /// `PATCH /alarms/{id}` (ADR 0022): ändert Zeitpunkt und/oder
  /// Fahrzeuge einer geplanten Alarmierung.
  Future<Alarm> update(
    String alarmId, {
    DateTime? scheduledAt,
    int? offsetMinutes,
    List<String>? vehicleIds,
  });

  /// `POST /alarms/{id}/discard` (ADR 0022): verwirft eine geplante oder
  /// verpasste Alarmierung.
  Future<Alarm> discard(String alarmId);

  /// `POST /alarms/{id}/trigger` (ADR 0022): löst eine geplante
  /// Alarmierung sofort/manuell aus.
  Future<TriggerAlarmResult> triggerNow(String alarmId);
}

/// [AlarmRepository] backed by the generated [AlarmsApi].
class ApiAlarmRepository implements AlarmRepository {
  const ApiAlarmRepository(this._api);

  final AlarmsApi _api;

  @override
  Future<TriggerAlarmResult> trigger(
    String incidentId,
    List<String> vehicleIds, {
    required String id,
  }) async {
    final response = await _api.createAlarm(
      id: incidentId,
      createAlarmRequest: CreateAlarmRequest(
        (b) => b
          ..id = id
          ..vehicleIds.addAll(vehicleIds),
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /incidents/{id}/alarms returned no body');
    }
    return TriggerAlarmResult(
      alarm: _alarmFromApi(data.alarm),
      doubleCrewed: data.doubleCrewed.map(_doubleCrewedFromApi).toList(),
    );
  }

  @override
  Future<void> acknowledge(String alarmId) async {
    await _api.acknowledgeAlarm(id: alarmId);
  }

  @override
  Future<Alarm> plan(
    String incidentId,
    List<String> vehicleIds, {
    String? id,
    DateTime? scheduledAt,
    int? offsetMinutes,
  }) async {
    final response = await _api.createAlarm(
      id: incidentId,
      createAlarmRequest: CreateAlarmRequest(
        (b) {
          if (id != null) b.id = id;
          b.vehicleIds.addAll(vehicleIds);
          b.scheduledAt = scheduledAt;
          b.offsetMinutes = offsetMinutes;
        },
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('POST /incidents/{id}/alarms returned no body');
    }
    return _alarmFromApi(data.alarm);
  }

  @override
  Future<Alarm> update(
    String alarmId, {
    DateTime? scheduledAt,
    int? offsetMinutes,
    List<String>? vehicleIds,
  }) async {
    final response = await _api.updateAlarm(
      id: alarmId,
      updateAlarmRequest: UpdateAlarmRequest(
        (b) {
          b.scheduledAt = scheduledAt;
          b.offsetMinutes = offsetMinutes;
          if (vehicleIds != null) b.vehicleIds.addAll(vehicleIds);
        },
      ),
    );
    final data = response.data;
    if (data == null) {
      throw StateError('PATCH /alarms/{id} returned no body');
    }
    return _alarmFromApi(data.alarm);
  }

  @override
  Future<Alarm> discard(String alarmId) async {
    final response = await _api.discardAlarm(id: alarmId);
    final data = response.data;
    if (data == null) {
      throw StateError('POST /alarms/{id}/discard returned no body');
    }
    return _alarmFromApi(data.alarm);
  }

  @override
  Future<TriggerAlarmResult> triggerNow(String alarmId) async {
    final response = await _api.triggerAlarm(id: alarmId);
    final data = response.data;
    if (data == null) {
      throw StateError('POST /alarms/{id}/trigger returned no body');
    }
    return TriggerAlarmResult(
      alarm: _alarmFromApi(data.alarm),
      doubleCrewed: data.doubleCrewed.map(_doubleCrewedFromApi).toList(),
    );
  }
}

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiAlarmRepository(apiClient.getAlarmsApi());
});
