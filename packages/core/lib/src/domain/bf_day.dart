/// Zustand eines BF-Tags (ADR 0013): `planning` -> `running` -> `ended`,
/// kein Zurück.
enum BfDayState {
  planning,
  running,
  ended;

  /// Deutsches Label für die UI.
  String get label {
    switch (this) {
      case BfDayState.planning:
        return 'in Planung';
      case BfDayState.running:
        return 'läuft';
      case BfDayState.ended:
        return 'beendet';
    }
  }

  /// Parses the wire representation (`planning`/`running`/`ended`).
  static BfDayState fromWire(String value) {
    switch (value) {
      case 'planning':
        return BfDayState.planning;
      case 'running':
        return BfDayState.running;
      case 'ended':
        return BfDayState.ended;
    }
    throw ArgumentError('Unknown BfDayState wire value: $value');
  }
}

/// Ein BF-Tag (ADR 0013): der Zeitrahmen, für den Teilnahmen, Schichten und
/// Besatzungen verwaltet werden. Höchstens einer ist zu einem Zeitpunkt
/// `running`.
class BfDay {
  const BfDay({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.state,
    this.anonymizedAt,
  });

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final BfDayState state;

  /// Wann der BF-Tag anonymisiert wurde (ADR 0020), oder `null`, wenn noch
  /// nicht anonymisiert.
  final DateTime? anonymizedAt;

  /// Ob der BF-Tag bereits anonymisiert wurde (ADR 0020).
  bool get isAnonymized => anonymizedAt != null;

  /// Parses the wire representation used by the backend API (REST and
  /// WebSocket events), e.g. `{id,name,starts_at,ends_at,state,...}`.
  factory BfDay.fromJson(Map<String, dynamic> json) {
    final anonymizedAtRaw = json['anonymized_at'] as String?;
    return BfDay(
      id: json['id'] as String,
      name: json['name'] as String,
      startsAt: DateTime.parse(json['starts_at'] as String),
      endsAt: DateTime.parse(json['ends_at'] as String),
      state: BfDayState.fromWire(json['state'] as String),
      anonymizedAt:
          anonymizedAtRaw == null ? null : DateTime.parse(anonymizedAtRaw),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BfDay &&
      other.id == id &&
      other.name == name &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt &&
      other.state == state &&
      other.anonymizedAt == anonymizedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, startsAt, endsAt, state, anonymizedAt);

  @override
  String toString() => 'BfDay($name, state: $state)';
}
