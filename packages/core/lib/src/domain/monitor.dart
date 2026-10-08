/// Ein Monitor (Fernseher im BF-Tag-Zelt), siehe ADR 0012 ("Monitor
/// (Stammdaten)") und CONTEXT.md ("Monitor" -- nie "Display"/"Bildschirm").
///
/// `paired` reflects whether a pairing hash currently exists on the backend
/// (`GET/POST/PATCH /monitors`); it does not by itself mean "gesperrt" --
/// that is derived separately from [revokedAt] (see `monitorStatusOf` in
/// apps/web/lib/admin/monitor_status.dart).
class Monitor {
  const Monitor({
    required this.id,
    required this.name,
    required this.paired,
    this.pairedAt,
    this.lastSeenAt,
    this.revokedAt,
    required this.createdAt,
  });

  final String id;
  final String name;
  final bool paired;
  final DateTime? pairedAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;
  final DateTime createdAt;

  /// Whether this monitor has been locked (`Sperren`).
  bool get isRevoked => revokedAt != null;

  Monitor copyWith({
    String? name,
    bool? paired,
    Object? pairedAt = _unset,
    Object? lastSeenAt = _unset,
    Object? revokedAt = _unset,
  }) {
    return Monitor(
      id: id,
      name: name ?? this.name,
      paired: paired ?? this.paired,
      pairedAt: pairedAt == _unset ? this.pairedAt : pairedAt as DateTime?,
      lastSeenAt:
          lastSeenAt == _unset ? this.lastSeenAt : lastSeenAt as DateTime?,
      revokedAt: revokedAt == _unset ? this.revokedAt : revokedAt as DateTime?,
      createdAt: createdAt,
    );
  }

  static const _unset = Object();
}

/// A one-time pairing code for a Monitor (ADR 0012), as returned by
/// `POST /monitors/{id}/pairing-code`.
///
/// Unlike [PairingCodeItem] (Personen, ADR 0010) there is no QR code -- the
/// TV has no camera, the code is typed in manually.
class MonitorPairingCode {
  const MonitorPairingCode({
    required this.monitorId,
    required this.name,
    required this.code,
    required this.expiresAt,
  });

  final String monitorId;
  final String name;
  final String code;
  final DateTime expiresAt;
}
