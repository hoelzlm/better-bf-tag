import 'fms_status.dart';

/// Ein Fahrzeug der eigenen Feuerwehr.
///
/// Siehe CONTEXT.md ("Fahrzeug") und docs/03-datenmodell.md.
class Vehicle {
  const Vehicle({
    required this.id,
    required this.callSign,
    required this.shortName,
    required this.type,
    required this.status,
    required this.statusChangedAt,
    required this.sortOrder,
    required this.active,
  });

  final String id;
  final String callSign;
  final String shortName;
  final String type;
  final FmsStatus status;
  final DateTime? statusChangedAt;
  final int sortOrder;
  final bool active;

  /// Parses the wire representation used by the backend API (REST and
  /// WebSocket events), e.g.
  /// `{id,call_sign,short_name,type,status,status_changed_at,sort_order,active}`.
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final statusChangedAtRaw = json['status_changed_at'] as String?;
    return Vehicle(
      id: json['id'] as String,
      callSign: json['call_sign'] as String,
      shortName: json['short_name'] as String,
      type: json['type'] as String,
      status: FmsStatus.fromCode(json['status'] as int),
      statusChangedAt:
          statusChangedAtRaw == null ? null : DateTime.parse(statusChangedAtRaw),
      sortOrder: json['sort_order'] as int,
      active: json['active'] as bool,
    );
  }

  Vehicle copyWith({
    String? id,
    String? callSign,
    String? shortName,
    String? type,
    FmsStatus? status,
    DateTime? statusChangedAt,
    int? sortOrder,
    bool? active,
  }) {
    return Vehicle(
      id: id ?? this.id,
      callSign: callSign ?? this.callSign,
      shortName: shortName ?? this.shortName,
      type: type ?? this.type,
      status: status ?? this.status,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      sortOrder: sortOrder ?? this.sortOrder,
      active: active ?? this.active,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Vehicle &&
      other.id == id &&
      other.callSign == callSign &&
      other.shortName == shortName &&
      other.type == type &&
      other.status == status &&
      other.statusChangedAt == statusChangedAt &&
      other.sortOrder == sortOrder &&
      other.active == active;

  @override
  int get hashCode => Object.hash(
        id,
        callSign,
        shortName,
        type,
        status,
        statusChangedAt,
        sortOrder,
        active,
      );

  @override
  String toString() =>
      'Vehicle($callSign, $shortName, status: ${status.code}, active: $active)';
}
