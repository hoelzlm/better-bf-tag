import '../domain/alarm.dart';
import '../domain/bf_day.dart';
import '../domain/incident.dart';
import '../domain/shift.dart';
import '../domain/slide.dart';
import '../domain/vehicle.dart';

/// A consistent point-in-time view of realtime state, loaded via
/// `GET /api/v1/snapshot`.
///
/// [seq] is the `seq` the data in [vehicles]/[slides] is consistent with
/// (see ADR 0009, "Client-Protokoll"); [vehicles] holds the active
/// vehicles, sorted by `sort_order`; [slides] holds the active Folien,
/// sorted by `sort_order` (ADR 0014), defaulting to empty when the backend
/// doesn't send it (tolerate missing, see ADR 0014 "Snapshot und Event").
/// [bfDay] (ADR 0013) is the currently running BF-Tag, or `null`; [shifts]
/// holds all shifts of that BF-Tag with their crew (empty if none is
/// running); [currentShiftId] is the id of the "aktuelle Schicht" at the
/// time the snapshot was taken, per `currentShift`. [incidents] (ADR 0016)
/// holds the `running` Einsätze of the running BF-Tag, sorted by `number`,
/// with Drehbuch only when the caller may see it; empty when no BF-Tag is
/// running. [alarms] (ADR 0017) holds all `triggered` Alarmierungen of
/// those Einsätze, sorted by `triggered_at`; empty when no BF-Tag is
/// running. [scheduledAlarms] (ADR 0022) holds all `planned`/`missed`
/// Alarmierungen of the `draft`/`running` Einsätze of the running BF-Tag,
/// sorted by `scheduled_at`, `id` -- only for callers with Drehbuch
/// permission (`preparation`/`dispatch`/`admin`), defaulting to empty when
/// the backend doesn't send it (older servers/tests).
class Snapshot {
  const Snapshot({
    required this.seq,
    required this.vehicles,
    this.slides = const <Slide>[],
    this.bfDay,
    this.shifts = const [],
    this.currentShiftId,
    this.incidents = const <Incident>[],
    this.alarms = const <Alarm>[],
    this.closeSuggestedIncidentIds = const <String>{},
    this.scheduledAlarms = const <ScheduledAlarm>[],
  });

  final int seq;
  final List<Vehicle> vehicles;
  final List<Slide> slides;
  final BfDay? bfDay;
  final List<Shift> shifts;
  final String? currentShiftId;
  final List<Incident> incidents;
  final List<Alarm> alarms;

  /// Ids of `running` Einsätze that are abschlussreif (ADR 0019), computed
  /// for `dispatch`/`admin` only -- always empty for other Berechtigungen.
  final Set<String> closeSuggestedIncidentIds;

  /// `planned`/`missed` Alarmierungen (ADR 0022), see above.
  final List<ScheduledAlarm> scheduledAlarms;
}
