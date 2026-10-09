/**
 * FMS-Regeln (ADR 0015): Status 7/8 (Patiententransport) sind nur für
 * Rettungs- und Krankentransportwagen zulässig. `type` ist Freitext;
 * verglichen wird getrimmt und in Großschreibung. Gleiche Regel in
 * `packages/core` (`allowsPatientStatus`).
 */
export function allowsPatientStatus(vehicleType: string): boolean {
  return ['RTW', 'KTW'].includes(vehicleType.trim().toUpperCase());
}

export function isPatientStatus(status: number): boolean {
  return status === 7 || status === 8;
}
