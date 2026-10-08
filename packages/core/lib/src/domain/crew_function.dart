/// Standard Besatzungs-Funktionen (ADR 0013), used only as suggestions in
/// the UI -- `function` on a [CrewAssignment] is free text.
const standardCrewFunctions = ['GF', 'MA', 'ATF', 'ATM', 'WTF', 'WTM', 'ME'];

/// Orders crew functions by [standardCrewFunctions] first (in that order),
/// then any other function alphabetically, per ADR 0013 ("Antwortobjekt
/// Schicht").
int compareCrewFunctions(String a, String b) {
  final indexA = standardCrewFunctions.indexOf(a);
  final indexB = standardCrewFunctions.indexOf(b);
  if (indexA != -1 && indexB != -1) {
    return indexA.compareTo(indexB);
  }
  if (indexA != -1) {
    return -1;
  }
  if (indexB != -1) {
    return 1;
  }
  return a.compareTo(b);
}
