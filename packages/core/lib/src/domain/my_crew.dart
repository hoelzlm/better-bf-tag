import 'current_shift.dart';
import 'shift.dart';
import 'vehicle.dart';

/// One Fahrzeug a Person is Besatzung of, in the current Schicht (ADR
/// 0015): the Schicht itself, the Fahrzeug, the Person's own Funktion on
/// it, and the full Besatzung of that Fahrzeug in that Schicht (including
/// the Person itself).
class MyCrewAssignment {
  const MyCrewAssignment({
    required this.shift,
    required this.vehicle,
    required this.function,
    required this.crew,
  });

  final Shift shift;
  final Vehicle vehicle;
  final String function;
  final List<CrewAssignment> crew;
}

/// The Fahrzeuge [personId] is currently Besatzung of (ADR 0015): looks up
/// the current Schicht ([currentShift]) and returns one [MyCrewAssignment]
/// per `crew_assignment` of [personId] in that Schicht, skipping any whose
/// Fahrzeug is not in [vehicles] (e.g. inactive -- [vehicles] is expected
/// to already be the active-only list from `pairedVehiclesProvider`).
/// Empty when there is no current Schicht. Sorted by Fahrzeug
/// `sort_order`. A Person may appear more than once (Doppelbesetzung).
List<MyCrewAssignment> myCrewAssignments({
  required List<Shift> shifts,
  required List<Vehicle> vehicles,
  required String personId,
  required DateTime now,
}) {
  final shift = currentShift(shifts, now);
  if (shift == null) {
    return const [];
  }

  final vehiclesById = {for (final vehicle in vehicles) vehicle.id: vehicle};

  final result = <MyCrewAssignment>[];
  for (final assignment in shift.crew) {
    if (assignment.personId != personId) continue;
    final vehicle = vehiclesById[assignment.vehicleId];
    if (vehicle == null) continue;

    final crewOfVehicle = shift.crew
        .where((c) => c.vehicleId == assignment.vehicleId)
        .toList();

    result.add(
      MyCrewAssignment(
        shift: shift,
        vehicle: vehicle,
        function: assignment.function,
        crew: crewOfVehicle,
      ),
    );
  }

  result.sort((a, b) => a.vehicle.sortOrder.compareTo(b.vehicle.sortOrder));
  return result;
}
