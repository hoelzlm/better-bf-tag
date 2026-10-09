import 'fms_status.dart';

/// Whether [vehicleType] is a RTW or KTW, the only Fahrzeugtypen that may
/// report Fahrzeugstatus 7/8 (ADR 0015). The match is on the trimmed,
/// upper-cased free-text `type` field (no enum yet), so e.g. `'RTW 2'`
/// does not match. Identical rule to `backend/src/vehicles/fms-rules.ts`.
bool allowsPatientStatus(String vehicleType) {
  final normalized = vehicleType.trim().toUpperCase();
  return normalized == 'RTW' || normalized == 'KTW';
}

/// The Fahrzeugstatus a Fahrzeug of [vehicleType] may be set to: always
/// s1..s6, plus s7/s8 when [allowsPatientStatus] (ADR 0015). Used by both
/// the FMS-Bedienteil (`apps/mobile`) and the Leitstelle status picker
/// (`apps/web`) so neither ever offers 7/8 outside RTW/KTW.
List<FmsStatus> offeredStatuses(String vehicleType) {
  const base = [
    FmsStatus.s1,
    FmsStatus.s2,
    FmsStatus.s3,
    FmsStatus.s4,
    FmsStatus.s5,
    FmsStatus.s6,
  ];
  if (!allowsPatientStatus(vehicleType)) {
    return base;
  }
  return const [
    FmsStatus.s1,
    FmsStatus.s2,
    FmsStatus.s3,
    FmsStatus.s4,
    FmsStatus.s5,
    FmsStatus.s6,
    FmsStatus.s7,
    FmsStatus.s8,
  ];
}
