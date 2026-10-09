import 'shift.dart';

/// Zustand einer Alarmierung (ADR 0017): `planned` -> `triggered` ->
/// `missed`, oder direkt `discarded`. Ticket 08 kennt nur den Erstalarm,
/// der direkt mit `triggered` angelegt wird.
enum AlarmState {
  planned,
  triggered,
  missed,
  discarded;

  /// Parses the wire representation (`planned`/`triggered`/`missed`/`discarded`).
  static AlarmState fromWire(String value) {
    switch (value) {
      case 'planned':
        return AlarmState.planned;
      case 'triggered':
        return AlarmState.triggered;
      case 'missed':
        return AlarmState.missed;
      case 'discarded':
        return AlarmState.discarded;
    }
    throw ArgumentError('Unknown AlarmState wire value: $value');
  }
}

/// Zustand der Quittierung eines einzelnen Empfängers (ADR 0017):
/// `acknowledgedAt != null` ⇒ [acknowledged]; sonst [pending] wenn
/// `hasDevice`, sonst [noDevice]. „Kein Gerät“ zählt nie als ausstehend.
enum AckState { acknowledged, pending, noDevice }

/// Ein Empfänger einer Alarmierung (ADR 0017): zum Auslösezeitpunkt
/// eingefrorene Besatzung (Person, Fahrzeug, Funktion), ob die Person ein
/// gekoppeltes Gerät hatte, und wann sie quittiert hat.
class AlarmRecipient {
  const AlarmRecipient({
    required this.personId,
    required this.displayName,
    required this.vehicleId,
    required this.function,
    required this.hasDevice,
    this.acknowledgedAt,
  });

  final String personId;
  final String displayName;
  final String vehicleId;
  final String function;
  final bool hasDevice;
  final DateTime? acknowledgedAt;

  /// `acknowledgedAt != null` ⇒ [AckState.acknowledged]; sonst
  /// [AckState.pending] wenn [hasDevice], sonst [AckState.noDevice].
  AckState get ackState {
    if (acknowledgedAt != null) return AckState.acknowledged;
    if (hasDevice) return AckState.pending;
    return AckState.noDevice;
  }

  /// Parses `{person_id,display_name,vehicle_id,function,has_device,acknowledged_at}`.
  factory AlarmRecipient.fromJson(Map<String, dynamic> json) {
    final acknowledgedAtRaw = json['acknowledged_at'] as String?;
    return AlarmRecipient(
      personId: json['person_id'] as String,
      displayName: json['display_name'] as String,
      vehicleId: json['vehicle_id'] as String,
      function: json['function'] as String,
      hasDevice: json['has_device'] as bool,
      acknowledgedAt:
          acknowledgedAtRaw == null ? null : DateTime.parse(acknowledgedAtRaw),
    );
  }

  AlarmRecipient copyWith({DateTime? acknowledgedAt}) {
    return AlarmRecipient(
      personId: personId,
      displayName: displayName,
      vehicleId: vehicleId,
      function: function,
      hasDevice: hasDevice,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AlarmRecipient &&
      other.personId == personId &&
      other.displayName == displayName &&
      other.vehicleId == vehicleId &&
      other.function == function &&
      other.hasDevice == hasDevice &&
      other.acknowledgedAt == acknowledgedAt;

  @override
  int get hashCode => Object.hash(
        personId,
        displayName,
        vehicleId,
        function,
        hasDevice,
        acknowledgedAt,
      );

  @override
  String toString() => 'AlarmRecipient($displayName, $ackState)';
}

/// Zähler über die [AlarmRecipient.ackState] eines [Alarm].
class AckSummary {
  const AckSummary({
    required this.acknowledged,
    required this.pending,
    required this.noDevice,
  });

  final int acknowledged;
  final int pending;
  final int noDevice;

  @override
  bool operator ==(Object other) =>
      other is AckSummary &&
      other.acknowledged == acknowledged &&
      other.pending == pending &&
      other.noDevice == noDevice;

  @override
  int get hashCode => Object.hash(acknowledged, pending, noDevice);

  @override
  String toString() =>
      'AckSummary(acknowledged: $acknowledged, pending: $pending, noDevice: $noDevice)';
}

/// Eine Alarmierung eines Einsatzes (ADR 0017): Fahrzeuge, eingefrorene
/// Empfänger und ihr Quittierungsstatus. Enthält nie das Drehbuch.
class Alarm {
  const Alarm({
    required this.id,
    required this.incidentId,
    required this.state,
    this.scheduledAt,
    this.triggeredAt,
    required this.vehicleIds,
    required this.recipients,
  });

  final String id;
  final String incidentId;
  final AlarmState state;
  final DateTime? scheduledAt;
  final DateTime? triggeredAt;
  final List<String> vehicleIds;
  final List<AlarmRecipient> recipients;

  /// Zähler über [recipients] nach [AlarmRecipient.ackState].
  AckSummary get summary {
    var acknowledged = 0;
    var pending = 0;
    var noDevice = 0;
    for (final recipient in recipients) {
      switch (recipient.ackState) {
        case AckState.acknowledged:
          acknowledged++;
        case AckState.pending:
          pending++;
        case AckState.noDevice:
          noDevice++;
      }
    }
    return AckSummary(
      acknowledged: acknowledged,
      pending: pending,
      noDevice: noDevice,
    );
  }

  /// Parses `{id,incident_id,state,scheduled_at,triggered_at,vehicle_ids,recipients}`.
  factory Alarm.fromJson(Map<String, dynamic> json) {
    final scheduledAtRaw = json['scheduled_at'] as String?;
    final triggeredAtRaw = json['triggered_at'] as String?;
    final vehicleIdsJson = json['vehicle_ids'] as List<dynamic>;
    final recipientsJson = json['recipients'] as List<dynamic>;
    return Alarm(
      id: json['id'] as String,
      incidentId: json['incident_id'] as String,
      state: AlarmState.fromWire(json['state'] as String),
      scheduledAt:
          scheduledAtRaw == null ? null : DateTime.parse(scheduledAtRaw),
      triggeredAt:
          triggeredAtRaw == null ? null : DateTime.parse(triggeredAtRaw),
      vehicleIds: vehicleIdsJson.cast<String>().toList(),
      recipients: recipientsJson
          .map((e) => AlarmRecipient.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Alarm copyWith({
    AlarmState? state,
    DateTime? triggeredAt,
    List<AlarmRecipient>? recipients,
  }) {
    return Alarm(
      id: id,
      incidentId: incidentId,
      state: state ?? this.state,
      scheduledAt: scheduledAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      vehicleIds: vehicleIds,
      recipients: recipients ?? this.recipients,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Alarm &&
      other.id == id &&
      other.incidentId == incidentId &&
      other.state == state &&
      other.scheduledAt == scheduledAt &&
      other.triggeredAt == triggeredAt &&
      _listEquals(other.vehicleIds, vehicleIds) &&
      _listEquals(other.recipients, recipients);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        incidentId,
        state,
        scheduledAt,
        triggeredAt,
        Object.hashAll(vehicleIds),
        Object.hashAll(recipients),
      );

  @override
  String toString() => 'Alarm($id, incident: $incidentId, state: $state)';
}

/// Eine Person, die auf mehr als einem der ausgewählten/alarmierten
/// Fahrzeuge sitzt (ADR 0017, Doppelbesetzung).
class DoubleCrewed {
  const DoubleCrewed({
    required this.personId,
    required this.displayName,
    required this.vehicleIds,
  });

  final String personId;
  final String displayName;
  final List<String> vehicleIds;

  /// Parses `{person_id,display_name,vehicle_ids}`.
  factory DoubleCrewed.fromJson(Map<String, dynamic> json) {
    final vehicleIdsJson = json['vehicle_ids'] as List<dynamic>;
    return DoubleCrewed(
      personId: json['person_id'] as String,
      displayName: json['display_name'] as String,
      vehicleIds: vehicleIdsJson.cast<String>().toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DoubleCrewed &&
      other.personId == personId &&
      other.displayName == displayName &&
      _listEquals(other.vehicleIds, vehicleIds);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(personId, displayName, Object.hashAll(vehicleIds));

  @override
  String toString() => 'DoubleCrewed($displayName, $vehicleIds)';
}

/// Vorabwarnung bei Doppelbesetzung (ADR 0017): Personen aus [shift]' Crew,
/// die auf mehr als einem der [vehicleIds] sitzen. Pure Funktion, damit sie
/// im Alarmieren-Dialog ohne Serverantwort berechnet werden kann. `null`
/// [shift] (keine aktuelle Schicht) liefert immer eine leere Liste.
List<DoubleCrewed> doubleCrewedIn(Shift? shift, Iterable<String> vehicleIds) {
  if (shift == null) return const [];
  final selected = vehicleIds.toSet();
  final vehiclesByPerson = <String, List<CrewAssignment>>{};
  for (final assignment in shift.crew) {
    if (!selected.contains(assignment.vehicleId)) continue;
    vehiclesByPerson.putIfAbsent(assignment.personId, () => []).add(assignment);
  }
  final result = <DoubleCrewed>[];
  for (final entry in vehiclesByPerson.entries) {
    if (entry.value.length < 2) continue;
    result.add(
      DoubleCrewed(
        personId: entry.key,
        displayName: entry.value.first.displayName,
        vehicleIds: entry.value.map((a) => a.vehicleId).toList(),
      ),
    );
  }
  return result;
}
