/// Ein Programmpunkt des Tagesablaufs (ADR 0025): fester Zeitabschnitt mit
/// Titel und Typ, ohne Personenbezug.
///
/// Siehe CONTEXT.md und docs/adr/0025-tagesablauf.md.
enum ProgramItemType {
  meal,
  training,
  maintenance,
  rest,
  other;

  /// Deutsches Label für die UI.
  String get label {
    switch (this) {
      case ProgramItemType.meal:
        return 'Essen';
      case ProgramItemType.training:
        return 'Ausbildung';
      case ProgramItemType.maintenance:
        return 'Fahrzeugpflege';
      case ProgramItemType.rest:
        return 'Ruhe';
      case ProgramItemType.other:
        return 'Sonstiges';
    }
  }

  /// Parses the wire representation (`meal`/`training`/`maintenance`/
  /// `rest`/`other`).
  static ProgramItemType fromWire(String value) {
    switch (value) {
      case 'meal':
        return ProgramItemType.meal;
      case 'training':
        return ProgramItemType.training;
      case 'maintenance':
        return ProgramItemType.maintenance;
      case 'rest':
        return ProgramItemType.rest;
      case 'other':
        return ProgramItemType.other;
    }
    throw ArgumentError('Unknown ProgramItemType wire value: $value');
  }

  /// Serializes back to the wire representation.
  String toWire() => name;
}

/// Ein Programmpunkt (ADR 0025): `id`, zugehöriger BF-Tag, Titel, Typ und
/// Zeitraum (`startsAt < endsAt`), kein Personenbezug.
class ProgramItem {
  const ProgramItem({
    required this.id,
    required this.bfDayId,
    required this.title,
    required this.type,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final String bfDayId;
  final String title;
  final ProgramItemType type;
  final DateTime startsAt;
  final DateTime endsAt;

  /// Parses the wire representation used by the backend API (REST,
  /// Snapshot and WebSocket events), e.g.
  /// `{id,bf_day_id,title,type,starts_at,ends_at}`. DateTimes are parsed
  /// to UTC.
  factory ProgramItem.fromJson(Map<String, dynamic> json) {
    return ProgramItem(
      id: json['id'] as String,
      bfDayId: json['bf_day_id'] as String,
      title: json['title'] as String,
      type: ProgramItemType.fromWire(json['type'] as String),
      startsAt: DateTime.parse(json['starts_at'] as String).toUtc(),
      endsAt: DateTime.parse(json['ends_at'] as String).toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bf_day_id': bfDayId,
      'title': title,
      'type': type.toWire(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt.toUtc().toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ProgramItem &&
      other.id == id &&
      other.bfDayId == bfDayId &&
      other.title == title &&
      other.type == type &&
      other.startsAt == startsAt &&
      other.endsAt == endsAt;

  @override
  int get hashCode =>
      Object.hash(id, bfDayId, title, type, startsAt, endsAt);

  @override
  String toString() => 'ProgramItem($title, type: $type)';
}
