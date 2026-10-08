import '../domain/vehicle.dart';

/// A consistent point-in-time view of realtime state, loaded via
/// `GET /api/v1/snapshot`.
///
/// [seq] is the `seq` the data in [vehicles] is consistent with (see ADR
/// 0009, "Client-Protokoll"); [vehicles] holds the active vehicles, sorted
/// by `sort_order`.
class Snapshot {
  const Snapshot({required this.seq, required this.vehicles});

  final int seq;
  final List<Vehicle> vehicles;
}
