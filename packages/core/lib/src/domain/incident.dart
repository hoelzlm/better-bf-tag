/// Zustand eines Einsatzes (ADR 0016): `draft` -> `running` -> `closed`,
/// oder `draft` -> `discarded`. `running` -> `closed` und die
/// Alarmierungs-Übergänge kommen mit Ticket 08.
enum IncidentState {
  draft,
  running,
  closed,
  discarded;

  /// German display label.
  String get label {
    switch (this) {
      case IncidentState.draft:
        return 'Entwurf';
      case IncidentState.running:
        return 'laufend';
      case IncidentState.closed:
        return 'abgeschlossen';
      case IncidentState.discarded:
        return 'verworfen';
    }
  }

  /// Parses the wire representation (`draft`/`running`/`closed`/`discarded`).
  static IncidentState fromWire(String value) {
    switch (value) {
      case 'draft':
        return IncidentState.draft;
      case 'running':
        return IncidentState.running;
      case 'closed':
        return IncidentState.closed;
      case 'discarded':
        return IncidentState.discarded;
    }
    throw ArgumentError('Unknown IncidentState wire value: $value');
  }
}

/// Ein Einsatz innerhalb eines BF-Tags (ADR 0016): Meldebild (sichtbar) und
/// Drehbuch (nur für Betreuer mit entsprechender Berechtigung).
///
/// Siehe CONTEXT.md ("Einsatz", "Meldebild", "Drehbuch").
class Incident {
  const Incident({
    required this.id,
    required this.bfDayId,
    required this.number,
    required this.keyword,
    required this.address,
    required this.report,
    required this.script,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.closedAt,
  });

  final String id;
  final String bfDayId;
  final int number;
  final String keyword;
  final String address;
  final String report;

  /// Drehbuch: `null` when the server didn't include the `script` key at
  /// all (ADR 0016, "Ein Serialisierer, Feld fehlt statt `null`") -- i.e.
  /// the caller has no permission to see it. Never inferred from
  /// permission on the client side.
  final String? script;
  final IncidentState state;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// When the Einsatz was geschlossen (ADR 0019), `null` otherwise.
  final DateTime? closedAt;

  /// Parses the wire representation used by the backend API (REST and
  /// WebSocket events), e.g.
  /// `{id,bf_day_id,number,keyword,address,report,state,created_at,updated_at,closed_at}`
  /// with `script` present only when the caller may see it.
  factory Incident.fromJson(Map<String, dynamic> json) {
    final closedAtRaw = json['closed_at'] as String?;
    return Incident(
      id: json['id'] as String,
      bfDayId: json['bf_day_id'] as String,
      number: json['number'] as int,
      keyword: json['keyword'] as String,
      address: json['address'] as String,
      report: json['report'] as String,
      script: json.containsKey('script') ? json['script'] as String? : null,
      state: IncidentState.fromWire(json['state'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      closedAt: closedAtRaw == null ? null : DateTime.parse(closedAtRaw),
    );
  }

  /// Wire representation, omitting the `script` key entirely when it's
  /// `null` -- mirrors the server's serializer (ADR 0016).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bf_day_id': bfDayId,
      'number': number,
      'keyword': keyword,
      'address': address,
      'report': report,
      'state': state.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
      if (script != null) 'script': script,
    };
  }

  Incident copyWith({
    String? keyword,
    String? address,
    String? report,
    String? script,
    IncidentState? state,
    DateTime? updatedAt,
    DateTime? closedAt,
  }) {
    return Incident(
      id: id,
      bfDayId: bfDayId,
      number: number,
      keyword: keyword ?? this.keyword,
      address: address ?? this.address,
      report: report ?? this.report,
      script: script ?? this.script,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Incident &&
      other.id == id &&
      other.bfDayId == bfDayId &&
      other.number == number &&
      other.keyword == keyword &&
      other.address == address &&
      other.report == report &&
      other.script == script &&
      other.state == state &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.closedAt == closedAt;

  @override
  int get hashCode => Object.hash(
        id,
        bfDayId,
        number,
        keyword,
        address,
        report,
        script,
        state,
        createdAt,
        updatedAt,
        closedAt,
      );

  @override
  String toString() => 'Incident(#$number $keyword, state: $state)';
}
