import '../domain/alarm.dart';
import '../domain/bf_day.dart';
import '../domain/fms_status.dart';
import '../domain/incident.dart';
import '../domain/shift.dart';
import '../domain/slide.dart';
import '../domain/vehicle.dart';

/// Server->client WebSocket event, per ADR 0009 ("Client-Protokoll") and
/// docs/04-api.md.
///
/// Hand-written (not generated) because the event hierarchy is small and
/// forward-compatible: a type this build doesn't know about still parses
/// (as [UnknownEvent]) so its `seq` can advance the client's counter.
sealed class RealtimeEvent {
  const RealtimeEvent({required this.seq, required this.at});

  /// The global sequence number this event was published at.
  final int seq;

  /// Server clock timestamp the event was published at, when present.
  ///
  /// `null` for `skip` messages, which per ADR 0009 carry only `seq`/`type`.
  final DateTime? at;

  /// Parses one `{"seq":N,"type":"...","at":ISO,"data":{...}}` message (or
  /// `{"seq":N,"type":"skip"}`, which has no `at`/`data`).
  ///
  /// `type: "skip"` (an event filtered out by permission, see ADR 0009) and
  /// any other type this build doesn't recognize both become
  /// [UnknownEvent] -- they still carry `seq` so the client's gap detection
  /// keeps working.
  factory RealtimeEvent.fromJson(Map<String, dynamic> json) {
    final seq = json['seq'] as int;
    final atRaw = json['at'] as String?;
    final at = atRaw == null ? null : DateTime.parse(atRaw);
    final type = json['type'] as String;
    final data = json['data'];
    switch (type) {
      case 'vehicle.status_changed':
        final map = data as Map<String, dynamic>;
        return VehicleStatusChanged(
          seq: seq,
          at: at,
          vehicleId: map['vehicle_id'] as String,
          status: FmsStatus.fromCode(map['status'] as int),
          source: map['source'] as String?,
        );
      case 'vehicle.updated':
        final map = data as Map<String, dynamic>;
        return VehicleUpdated(
          seq: seq,
          at: at,
          vehicle: Vehicle.fromJson(map),
        );
      case 'slides.changed':
        final map = data as Map<String, dynamic>;
        final slidesJson = map['slides'] as List<dynamic>;
        return SlidesChanged(
          seq: seq,
          at: at,
          slides: slidesJson
              .map((e) => Slide.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      case 'shift.crew_changed':
        final map = data as Map<String, dynamic>;
        return ShiftCrewChanged(
          seq: seq,
          at: at,
          shift: Shift.fromJson(map),
        );
      case 'shift.deleted':
        final map = data as Map<String, dynamic>;
        return ShiftDeleted(
          seq: seq,
          at: at,
          id: map['id'] as String,
          bfDayId: map['bf_day_id'] as String,
        );
      case 'bf_day.updated':
        final map = data as Map<String, dynamic>;
        return BfDayUpdated(
          seq: seq,
          at: at,
          bfDay: BfDay.fromJson(map),
        );
      case 'incident.created':
        final map = data as Map<String, dynamic>;
        return IncidentCreated(
          seq: seq,
          at: at,
          incident: Incident.fromJson(map),
        );
      case 'incident.updated':
        final map = data as Map<String, dynamic>;
        return IncidentUpdated(
          seq: seq,
          at: at,
          incident: Incident.fromJson(map),
        );
      case 'alarm.triggered':
        final map = data as Map<String, dynamic>;
        return AlarmTriggered(
          seq: seq,
          at: at,
          incident: Incident.fromJson(map['incident'] as Map<String, dynamic>),
          alarm: Alarm.fromJson(map['alarm'] as Map<String, dynamic>),
        );
      case 'alarm.planned':
        final map = data as Map<String, dynamic>;
        return AlarmPlanned(
          seq: seq,
          at: at,
          incident: Incident.fromJson(map['incident'] as Map<String, dynamic>),
          alarm: Alarm.fromJson(map['alarm'] as Map<String, dynamic>),
        );
      case 'alarm.missed':
        final map = data as Map<String, dynamic>;
        return AlarmMissed(
          seq: seq,
          at: at,
          incident: Incident.fromJson(map['incident'] as Map<String, dynamic>),
          alarm: Alarm.fromJson(map['alarm'] as Map<String, dynamic>),
        );
      case 'alarm.discarded':
        final map = data as Map<String, dynamic>;
        return AlarmDiscarded(
          seq: seq,
          at: at,
          alarmId: map['alarm_id'] as String,
          incidentId: map['incident_id'] as String,
        );
      case 'alarm.acknowledged':
        final map = data as Map<String, dynamic>;
        return AlarmAcknowledged(
          seq: seq,
          at: at,
          alarmId: map['alarm_id'] as String,
          incidentId: map['incident_id'] as String,
          personId: map['person_id'] as String,
          displayName: map['display_name'] as String,
          acknowledgedAt: DateTime.parse(map['acknowledged_at'] as String),
        );
      case 'alarm.push_reported':
        final map = data as Map<String, dynamic>;
        return AlarmPushReported(
          seq: seq,
          at: at,
          alarmId: map['alarm_id'] as String,
          incidentId: map['incident_id'] as String,
          pushDelivered: map['push_delivered'] as int,
          pushRejected: map['push_rejected'] as int,
        );
      case 'incident.closed':
        final map = data as Map<String, dynamic>;
        return IncidentClosed(
          seq: seq,
          at: at,
          id: map['id'] as String,
        );
      case 'incident.close_suggested':
        final map = data as Map<String, dynamic>;
        return IncidentCloseSuggested(
          seq: seq,
          at: at,
          id: map['id'] as String,
          suggested: map['suggested'] as bool,
        );
      default:
        return UnknownEvent(seq: seq, at: at, type: type);
    }
  }
}

/// `vehicle.status_changed`: a vehicle's FMS status changed.
class VehicleStatusChanged extends RealtimeEvent {
  const VehicleStatusChanged({
    required super.seq,
    required super.at,
    required this.vehicleId,
    required this.status,
    this.source,
  });

  final String vehicleId;
  final FmsStatus status;

  /// `app`, `dispatch`, or `system`; not present on every payload shape.
  final String? source;
}

/// `vehicle.updated`: a vehicle was created, edited, (de-)activated, or
/// reordered. Carries the full vehicle.
class VehicleUpdated extends RealtimeEvent {
  const VehicleUpdated({
    required super.seq,
    required super.at,
    required this.vehicle,
  });

  final Vehicle vehicle;
}

/// `slides.changed` (ADR 0014): any change to Folien (create, edit, delete,
/// reorder, image set/cleared). Carries the full, replacement list of
/// active Folien, sorted by `sort_order` -- the client replaces its list
/// wholesale rather than merging.
class SlidesChanged extends RealtimeEvent {
  const SlidesChanged({
    required super.seq,
    required super.at,
    required this.slides,
  });

  final List<Slide> slides;
}

/// `shift.crew_changed` (ADR 0013): a shift was created/edited or its crew
/// was replaced, or a participant removal cleared some of its crew.
/// Carries the full shift with crew.
class ShiftCrewChanged extends RealtimeEvent {
  const ShiftCrewChanged({
    required super.seq,
    required super.at,
    required this.shift,
  });

  final Shift shift;
}

/// `shift.deleted` (ADR 0013): a shift was deleted.
class ShiftDeleted extends RealtimeEvent {
  const ShiftDeleted({
    required super.seq,
    required super.at,
    required this.id,
    required this.bfDayId,
  });

  final String id;
  final String bfDayId;
}

/// `bf_day.updated` (ADR 0013): a BF-Tag was created, edited, started, or
/// ended. Carries the full BF-Tag.
class BfDayUpdated extends RealtimeEvent {
  const BfDayUpdated({
    required super.seq,
    required super.at,
    required this.bfDay,
  });

  final BfDay bfDay;
}

/// `incident.created` (ADR 0016): a new Einsatz was created (always
/// `draft`, so clients that track only `running` Einsätze ignore it).
/// Only delivered to `preparation`/`dispatch`/`admin`, always with
/// Drehbuch.
class IncidentCreated extends RealtimeEvent {
  const IncidentCreated({
    required super.seq,
    required super.at,
    required this.incident,
  });

  final Incident incident;
}

/// `incident.updated` (ADR 0016): an Einsatz was edited or discarded.
/// Delivered to `preparation`/`dispatch`/`admin` always, and to
/// Mannschaft/Monitor when `state` is `running` or `closed`; Drehbuch is
/// projected per connection (present only with permission).
class IncidentUpdated extends RealtimeEvent {
  const IncidentUpdated({
    required super.seq,
    required super.at,
    required this.incident,
  });

  final Incident incident;
}

/// `alarm.triggered` (ADR 0017): a new Alarmierung (Erstalarm, later also
/// Nachalarmierung) was triggered. Carries both the Alarmierung and the
/// Einsatz it belongs to (projected per connection, same rule as
/// [IncidentUpdated]) -- the Einsatz may have just transitioned
/// `draft` -> `running`.
class AlarmTriggered extends RealtimeEvent {
  const AlarmTriggered({
    required super.seq,
    required super.at,
    required this.incident,
    required this.alarm,
  });

  final Incident incident;
  final Alarm alarm;
}

/// `alarm.planned` (ADR 0022): a Alarmierung was neu geplant oder
/// geändert (Zeitpunkt/Fahrzeuge). Upsert-Semantik -- also fires for a
/// re-plan and for the recalculation of dependent relative Alarmierungen.
/// Audience `preparation`/`dispatch`/`admin` only (Mannschaft/Monitor
/// erfahren nichts davon).
class AlarmPlanned extends RealtimeEvent {
  const AlarmPlanned({
    required super.seq,
    required super.at,
    required this.incident,
    required this.alarm,
  });

  final Incident incident;
  final Alarm alarm;
}

/// `alarm.missed` (ADR 0022): a geplante Alarmierung wurde verpasst (mehr
/// als 10 Minuten nach `scheduled_at`, oder nicht mehr auslösbar).
/// Audience `preparation`/`dispatch`/`admin` only.
class AlarmMissed extends RealtimeEvent {
  const AlarmMissed({
    required super.seq,
    required super.at,
    required this.incident,
    required this.alarm,
  });

  final Incident incident;
  final Alarm alarm;
}

/// `alarm.discarded` (ADR 0022): a geplante oder verpasste Alarmierung
/// wurde verworfen (auch als Kaskade einer verworfenen Basis-Alarmierung,
/// oder beim Schließen/Verwerfen des Einsatzes). Audience
/// `preparation`/`dispatch`/`admin` only.
class AlarmDiscarded extends RealtimeEvent {
  const AlarmDiscarded({
    required super.seq,
    required super.at,
    required this.alarmId,
    required this.incidentId,
  });

  final String alarmId;
  final String incidentId;
}

/// `alarm.acknowledged` (ADR 0017): a recipient quittierte ihre
/// Alarmierung.
class AlarmAcknowledged extends RealtimeEvent {
  const AlarmAcknowledged({
    required super.seq,
    required super.at,
    required this.alarmId,
    required this.incidentId,
    required this.personId,
    required this.displayName,
    required this.acknowledgedAt,
  });

  final String alarmId;
  final String incidentId;
  final String personId;
  final String displayName;
  final DateTime acknowledgedAt;
}

/// `alarm.push_reported` (ADR 0018): the push delivery for an Alarmierung
/// finished; carries only the updated counters, never Personendaten.
class AlarmPushReported extends RealtimeEvent {
  const AlarmPushReported({
    required super.seq,
    required super.at,
    required this.alarmId,
    required this.incidentId,
    required this.pushDelivered,
    required this.pushRejected,
  });

  final String alarmId;
  final String incidentId;
  final int pushDelivered;
  final int pushRejected;
}

/// `incident.closed` (ADR 0019): a running Einsatz was geschlossen. The
/// Einsatz and its Alarmierungen are already removed by the preceding
/// `incident.updated` (state `closed`); this is a pure follow-up signal
/// (e.g. for the Alarm-Vollbild closing), applying it again is a no-op.
class IncidentClosed extends RealtimeEvent {
  const IncidentClosed({
    required super.seq,
    required super.at,
    required this.id,
  });

  final String id;
}

/// `incident.close_suggested` (ADR 0019): whether a running Einsatz is
/// abschlussreif changed. Audience `dispatch`/`admin` only -- other
/// connections never receive this event.
class IncidentCloseSuggested extends RealtimeEvent {
  const IncidentCloseSuggested({
    required super.seq,
    required super.at,
    required this.id,
    required this.suggested,
  });

  final String id;
  final bool suggested;
}

/// Any event type this build doesn't know about yet (including `skip`).
///
/// Forward-compatible: the event's `seq` still advances the client's
/// counter, it just has no effect on vehicle state.
class UnknownEvent extends RealtimeEvent {
  const UnknownEvent({
    required super.seq,
    required super.at,
    required this.type,
  });

  final String type;
}
