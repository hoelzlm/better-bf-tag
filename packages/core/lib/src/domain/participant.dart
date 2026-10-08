import 'permission.dart';

/// Eine Teilnahme am BF-Tag (ADR 0013, `GET /bf-days/{day}/participants`):
/// die teilnehmende Person mit den für die Einteilung relevanten Feldern.
class Participant {
  const Participant({
    required this.personId,
    required this.displayName,
    required this.personType,
    required this.permission,
    required this.fireDepartmentId,
  });

  final String personId;
  final String displayName;
  final PersonType personType;
  final Permission permission;
  final String fireDepartmentId;

  @override
  bool operator ==(Object other) =>
      other is Participant &&
      other.personId == personId &&
      other.displayName == displayName &&
      other.personType == personType &&
      other.permission == permission &&
      other.fireDepartmentId == fireDepartmentId;

  @override
  int get hashCode => Object.hash(
        personId,
        displayName,
        personType,
        permission,
        fireDepartmentId,
      );
}
