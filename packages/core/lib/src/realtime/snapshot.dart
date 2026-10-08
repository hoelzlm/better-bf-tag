import '../domain/bf_day.dart';
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
/// time the snapshot was taken, per `currentShift`.
class Snapshot {
  const Snapshot({
    required this.seq,
    required this.vehicles,
    this.slides = const <Slide>[],
    this.bfDay,
    this.shifts = const [],
    this.currentShiftId,
  });

  final int seq;
  final List<Vehicle> vehicles;
  final List<Slide> slides;
  final BfDay? bfDay;
  final List<Shift> shifts;
  final String? currentShiftId;
}
