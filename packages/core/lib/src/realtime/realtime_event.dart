import '../domain/fms_status.dart';
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
