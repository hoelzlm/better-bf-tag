/// Die Zahlen einer Anonymisierung (ADR 0020): entweder als Vorschau (`GET
/// /bf-days/{id}/anonymization-preview`) oder als Ergebnis von `POST
/// /bf-days/{id}/anonymize`.
class AnonymizationSummary {
  const AnonymizationSummary({
    required this.participations,
    required this.crewAssignments,
    required this.alarmRecipients,
    required this.statusEvents,
    required this.personsDeleted,
  });

  /// Anzahl gelöschter Teilnahmen.
  final int participations;

  /// Anzahl gelöschter Besatzungseinträge.
  final int crewAssignments;

  /// Anzahl gelöschter Empfänger/Quittierungen.
  final int alarmRecipients;

  /// Anzahl Statushistorie-Einträge, deren Personenbezug entfernt wurde.
  final int statusEvents;

  /// Anzahl gelöschter Personen anderer Feuerwehren.
  final int personsDeleted;

  @override
  bool operator ==(Object other) =>
      other is AnonymizationSummary &&
      other.participations == participations &&
      other.crewAssignments == crewAssignments &&
      other.alarmRecipients == alarmRecipients &&
      other.statusEvents == statusEvents &&
      other.personsDeleted == personsDeleted;

  @override
  int get hashCode => Object.hash(
        participations,
        crewAssignments,
        alarmRecipients,
        statusEvents,
        personsDeleted,
      );

  @override
  String toString() =>
      'AnonymizationSummary(participations: $participations, '
      'crewAssignments: $crewAssignments, alarmRecipients: $alarmRecipients, '
      'statusEvents: $statusEvents, personsDeleted: $personsDeleted)';
}
