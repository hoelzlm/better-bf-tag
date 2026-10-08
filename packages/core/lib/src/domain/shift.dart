/// Eine Besatzung: eine Person auf einem Fahrzeug in einer bestimmten
/// Funktion, innerhalb einer [Shift]. Siehe ADR 0013.
class CrewAssignment {
  const CrewAssignment({
    required this.vehicleId,
    required this.personId,
    required this.displayName,
    required this.function,
  });

  final String vehicleId;
  final String personId;
  final String displayName;
  final String function;

  /// Parses `{vehicle_id,person_id,display_name,function}`.
  factory CrewAssignment.fromJson(Map<String, dynamic> json) {
    return CrewAssignment(
      vehicleId: json['vehicle_id'] as String,
      personId: json['person_id'] as String,
      displayName: json['display_name'] as String,
      function: json['function'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CrewAssignment &&
      other.vehicleId == vehicleId &&
      other.personId == personId &&
      other.displayName == displayName &&
      other.function == function;

  @override
  int get hashCode =>
      Object.hash(vehicleId, personId, displayName, function);

  @override
  String toString() => 'CrewAssignment($vehicleId, $personId, $function)';
}

/// Eine Schicht innerhalb eines BF-Tags (ADR 0013). Schichten dürfen sich
/// überlappen; welche "aktuell" ist, ermittelt [currentShift].
class Shift {
  const Shift({
    required this.id,
    required this.bfDayId,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.crew,
  });

  final String id;
  final String bfDayId;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final List<CrewAssignment> crew;

  /// Parses `{id,bf_day_id,name,starts_at,ends_at,crew:[...]}`.
  factory Shift.fromJson(Map<String, dynamic> json) {
    final crewJson = json['crew'] as List<dynamic>? ?? const [];
    return Shift(
      id: json['id'] as String,
      bfDayId: json['bf_day_id'] as String,
      name: json['name'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      crew: crewJson
          .map((e) => CrewAssignment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Shift copyWith({
    String? name,
    DateTime? startsAt,
    DateTime? endsAt,
    List<CrewAssignment>? crew,
  }) {
    return Shift(
      id: id,
      bfDayId: bfDayId,
      name: name ?? this.name,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      crew: crew ?? this.crew,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Shift &&
      other.id == id &&
      other.bfDayId == bfDayId &&
      other.name == name &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt &&
      _crewEquals(other.crew, crew);

  static bool _crewEquals(List<CrewAssignment> a, List<CrewAssignment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, bfDayId, name, startsAt, endsAt, Object.hashAll(crew));

  @override
  String toString() => 'Shift($name, $startsAt - $endsAt)';
}
