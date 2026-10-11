/// Eine Durchsage (ADR 0024): ein Text, optional an eine Schicht gerichtet,
/// sonst für alle sichtbar.
///
/// Siehe CONTEXT.md und docs/adr/0024-durchsage.md.
class Announcement {
  const Announcement({
    required this.id,
    required this.bfDayId,
    this.shiftId,
    required this.text,
    required this.createdBy,
    required this.createdAt,
  });

  final String id;
  final String bfDayId;

  /// `null` wenn die Durchsage für alle sichtbar ist, sonst die Schicht,
  /// an die sie gerichtet ist (ADR 0024, "Sichtbarkeit").
  final String? shiftId;
  final String text;

  /// Id der Person, die die Durchsage erstellt hat.
  final String createdBy;
  final DateTime createdAt;

  /// Parses the wire representation used by the backend API (REST,
  /// Snapshot and WebSocket events), e.g.
  /// `{id,bf_day_id,shift_id,text,created_by,created_at}`.
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      bfDayId: json['bf_day_id'] as String,
      shiftId: json['shift_id'] as String?,
      text: json['text'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bf_day_id': bfDayId,
      'shift_id': shiftId,
      'text': text,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Announcement &&
      other.id == id &&
      other.bfDayId == bfDayId &&
      other.shiftId == shiftId &&
      other.text == text &&
      other.createdBy == createdBy &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, bfDayId, shiftId, text, createdBy, createdAt);

  @override
  String toString() => 'Announcement($text, shiftId: $shiftId)';
}
