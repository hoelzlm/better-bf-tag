import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../domain/alarm.dart';
import '../domain/bf_day.dart';
import '../domain/incident.dart';
import '../domain/shift.dart';
import '../domain/slide.dart';
import '../domain/vehicle.dart';
import 'realtime_event.dart';
import 'snapshot.dart';
import 'web_socket_connection.dart';

/// Connection status exposed to the UI alongside the live vehicle list.
///
/// [revoked] is terminal: reached after a `session.revoked` control message
/// or close code 4403 (ADR 0010); the client stops and never reconnects.
enum ConnectionStatus { connecting, live, reconnecting, revoked }

/// A snapshot of realtime state: the current `seq`, the active vehicles
/// (sorted by `sort_order`), the active Folien (ADR 0014, in `sort_order`),
/// the running BF-Tag and its shifts (ADR 0013), the running Einsätze of
/// that BF-Tag (ADR 0016, sorted by `number`), the `triggered` Alarmierungen
/// of those Einsätze (ADR 0017, sorted by `triggered_at`), and the
/// connection status.
class RealtimeState {
  const RealtimeState({
    required this.seq,
    required this.vehicles,
    required this.status,
    this.slides = const <Slide>[],
    this.bfDay,
    this.shifts = const [],
    this.incidents = const <Incident>[],
    this.alarms = const <Alarm>[],
    this.closeSuggestedIncidentIds = const <String>{},
  });

  final int seq;
  final List<Vehicle> vehicles;
  final List<Slide> slides;
  final ConnectionStatus status;
  final BfDay? bfDay;
  final List<Shift> shifts;
  final List<Incident> incidents;
  final List<Alarm> alarms;

  /// Ids of `running` Einsätze that are abschlussreif (ADR 0019), computed
  /// for `dispatch`/`admin` only -- always empty for other Berechtigungen.
  final Set<String> closeSuggestedIncidentIds;
}

/// Computes the delay before reconnect attempt number [attempt] (0-based):
/// exponential backoff 1s, 2s, 4s, ... capped at 30s, plus up to 20% jitter.
Duration defaultReconnectBackoff(int attempt, Random random) {
  final baseSeconds = min(30, 1 << min(attempt, 10));
  final jitterMs = (random.nextDouble() * baseSeconds * 1000 * 0.2).round();
  return Duration(milliseconds: baseSeconds * 1000 + jitterMs);
}

/// Implements the ADR 0009 ("Client-Protokoll") realtime client:
///
/// - connects to `/ws`, buffering incoming messages until the snapshot
///   (`loadSnapshot`) has loaded, then drops events with `seq <=
///   snapshot.seq` and applies the rest in order,
/// - afterwards requires every event's `seq == last + 1` and every
///   `hello`/`heartbeat`'s `seq == last`; any mismatch reloads the
///   snapshot (gap),
/// - watches for silence (no message for 2x [heartbeatInterval]) and
///   reconnects with exponential backoff (reset after a successful
///   snapshot load),
/// - on close code 4401 (token invalid), calls [refreshSession] before
///   reconnecting.
/// - on the `session.revoked` control message (no `seq`, ADR 0010) or
///   close code 4403, stops without reconnecting, calls [onRevoked] once,
///   and exposes [ConnectionStatus.revoked].
class RealtimeClient {
  RealtimeClient({
    required Uri wsEndpoint,
    required Future<Snapshot> Function() loadSnapshot,
    required Future<String?> Function() accessToken,
    required Future<void> Function() refreshSession,
    void Function()? onRevoked,
    WebSocketConnector connector = connectWebSocket,
    this.heartbeatInterval = const Duration(seconds: 25),
    Random? random,
    Duration Function(int attempt, Random random)? backoff,
  })  : _wsEndpoint = wsEndpoint,
        _loadSnapshotFn = loadSnapshot,
        _accessToken = accessToken,
        _refreshSession = refreshSession,
        _onRevoked = onRevoked,
        _connector = connector,
        _random = random ?? Random(),
        _backoff = backoff ?? defaultReconnectBackoff;

  final Uri _wsEndpoint;
  final Future<Snapshot> Function() _loadSnapshotFn;
  final Future<String?> Function() _accessToken;
  final Future<void> Function() _refreshSession;
  final void Function()? _onRevoked;
  final WebSocketConnector _connector;
  final Duration heartbeatInterval;
  final Random _random;
  final Duration Function(int attempt, Random random) _backoff;

  final StreamController<RealtimeState> _controller =
      StreamController<RealtimeState>.broadcast();

  /// Emits a new [RealtimeState] whenever the vehicle list, `seq`, or
  /// connection status changes.
  Stream<RealtimeState> get states => _controller.stream;

  final StreamController<Alarm> _liveAlarmTriggeredController =
      StreamController<Alarm>.broadcast();

  /// Emits an [Alarm] only for `alarm.triggered` events received live over
  /// the WebSocket -- never for Alarmierungen loaded via the (initial or
  /// a gap/resync-triggered) snapshot. Drives Ton/Gong (ADR 0017): a
  /// reload must never re-trigger it.
  Stream<Alarm> get liveAlarmTriggered => _liveAlarmTriggeredController.stream;

  int _lastSeq = 0;
  final Map<String, Vehicle> _vehiclesById = <String, Vehicle>{};
  List<Slide> _slides = <Slide>[];
  BfDay? _bfDay;
  final Map<String, Shift> _shiftsById = <String, Shift>{};
  final Map<String, Incident> _incidentsById = <String, Incident>{};
  final Map<String, Alarm> _alarmsById = <String, Alarm>{};
  final Set<String> _closeSuggestedIncidentIds = <String>{};
  ConnectionStatus _status = ConnectionStatus.connecting;

  /// true until the (initial or a reload-triggered) snapshot has loaded;
  /// incoming messages are buffered in [_messageQueue] while true.
  bool _awaitingSnapshot = true;
  final List<Map<String, dynamic>> _messageQueue = <Map<String, dynamic>>[];

  WebSocketConnection? _connection;
  StreamSubscription<dynamic>? _subscription;
  Timer? _watchdogTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _started = false;
  bool _disposed = false;

  /// true once `session.revoked` or close code 4403 has been seen; the
  /// client never reconnects afterwards.
  bool _revoked = false;

  /// Tests only: how many times [loadSnapshot] has been called.
  int snapshotLoadCount = 0;

  /// Connects (or reconnects) for the first time. Idempotent.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    unawaited(_connect());
  }

  /// Stops reconnecting and releases all resources. The client cannot be
  /// restarted afterwards.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _watchdogTimer?.cancel();
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    try {
      await _connection?.sink.close();
    } catch (_) {
      // Ignore: we're tearing down anyway.
    }
    await _controller.close();
    await _liveAlarmTriggeredController.close();
  }

  Future<void> _connect() async {
    if (_disposed || _revoked) return;
    _status = ConnectionStatus.connecting;

    final token = await _accessToken();
    if (_disposed) return;
    final queryParameters = <String, String>{
      ..._wsEndpoint.queryParameters,
      if (token != null) 'token': token,
    };
    final uri = _wsEndpoint.replace(queryParameters: queryParameters);

    final WebSocketConnection connection;
    try {
      connection = _connector(uri);
    } catch (_) {
      _scheduleReconnect();
      return;
    }
    _connection = connection;
    _subscription = connection.stream.listen(
      _onMessage,
      onDone: _onSocketDone,
      onError: (Object _, StackTrace __) => _onSocketDone(),
      cancelOnError: true,
    );
    _resetWatchdog();
    unawaited(_loadSnapshot());
  }

  Future<void> _loadSnapshot() async {
    try {
      final snapshot = await _loadSnapshotFn();
      snapshotLoadCount++;
      if (_disposed) return;
      _lastSeq = snapshot.seq;
      _vehiclesById
        ..clear()
        ..addEntries(snapshot.vehicles.map((v) => MapEntry(v.id, v)));
      _slides = List.of(snapshot.slides);
      _bfDay = snapshot.bfDay;
      _shiftsById
        ..clear()
        ..addEntries(snapshot.shifts.map((s) => MapEntry(s.id, s)));
      _incidentsById
        ..clear()
        ..addEntries(snapshot.incidents.map((i) => MapEntry(i.id, i)));
      _alarmsById
        ..clear()
        ..addEntries(snapshot.alarms.map((a) => MapEntry(a.id, a)));
      _closeSuggestedIncidentIds
        ..clear()
        ..addAll(snapshot.closeSuggestedIncidentIds);
      _awaitingSnapshot = false;
      _reconnectAttempt = 0;
      _status = ConnectionStatus.live;
      _emit();
      _drainQueue();
    } catch (_) {
      if (_disposed) return;
      _closeAndReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    _resetWatchdog();
    if (_revoked) return;
    final Map<String, dynamic> json;
    try {
      json = raw is String
          ? jsonDecode(raw) as Map<String, dynamic>
          : Map<String, dynamic>.from(raw as Map);
    } catch (_) {
      return;
    }
    // `session.revoked` carries no `seq` (ADR 0010) and is not buffered:
    // it must take effect immediately, even mid-snapshot-reload.
    if (json['type'] == 'session.revoked') {
      _handleRevoked();
      return;
    }
    if (_awaitingSnapshot) {
      _messageQueue.add(json);
      return;
    }
    _processMessage(json);
  }

  void _drainQueue() {
    final queued = List<Map<String, dynamic>>.of(_messageQueue);
    _messageQueue.clear();
    for (final json in queued) {
      if (_awaitingSnapshot) {
        // A gap was detected mid-drain and a reload is already underway;
        // the remaining (stale) queue is irrelevant once it completes.
        break;
      }
      _processMessage(json);
    }
  }

  void _processMessage(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    final seq = json['seq'] as int?;
    if (seq == null) return;

    if (type == 'hello' || type == 'heartbeat') {
      if (seq != _lastSeq) {
        _handleGap();
      }
      return;
    }

    if (seq <= _lastSeq) {
      return; // Stale/duplicate: already covered by the snapshot or applied.
    }
    if (seq != _lastSeq + 1) {
      _handleGap();
      return;
    }
    _lastSeq = seq;
    _applyEvent(json);
    _emit();
  }

  void _applyEvent(Map<String, dynamic> json) {
    final event = RealtimeEvent.fromJson(json);
    switch (event) {
      case VehicleUpdated(:final vehicle):
        if (vehicle.active) {
          _vehiclesById[vehicle.id] = vehicle;
        } else {
          _vehiclesById.remove(vehicle.id);
        }
      case VehicleStatusChanged(:final vehicleId, :final status, :final at):
        final existing = _vehiclesById[vehicleId];
        if (existing != null) {
          _vehiclesById[vehicleId] =
              existing.copyWith(status: status, statusChangedAt: at);
        }
      case SlidesChanged(:final slides):
        _slides = List.of(slides);
      case ShiftCrewChanged(:final shift):
        // Upsert only if it belongs to the currently running BF-Tag;
        // otherwise ignore (ADR 0013, "Client-Verhalten").
        if (_bfDay != null && shift.bfDayId == _bfDay!.id) {
          _shiftsById[shift.id] = shift;
        }
      case ShiftDeleted(:final id):
        _shiftsById.remove(id);
      case IncidentCreated(:final incident):
        _applyIncident(incident);
      case IncidentUpdated(:final incident):
        _applyIncident(incident);
      case AlarmTriggered(:final incident, :final alarm):
        _applyIncident(incident);
        _alarmsById[alarm.id] = alarm;
        _liveAlarmTriggeredController.add(alarm);
      case AlarmAcknowledged(:final alarmId, :final personId, :final acknowledgedAt):
        _applyAlarmAcknowledged(alarmId, personId, acknowledgedAt);
      case AlarmPushReported(:final alarmId, :final pushDelivered, :final pushRejected):
        _applyAlarmPushReported(alarmId, pushDelivered, pushRejected);
      case BfDayUpdated():
        // The current BF-Tag/shifts changed in a way too varied to patch
        // incrementally (new BF-Tag started, time range changed, ...);
        // reload the whole snapshot (ADR 0013), same mechanism as a gap.
        _handleGap();
      case IncidentClosed(:final id):
        // The Einsatz/its Alarmierungen were already removed by the
        // preceding `incident.updated` (ADR 0019); also drop any leftover
        // Abschlussvorschlag so both orders are idempotent.
        _closeSuggestedIncidentIds.remove(id);
      case IncidentCloseSuggested(:final id, :final suggested):
        if (suggested) {
          _closeSuggestedIncidentIds.add(id);
        } else {
          _closeSuggestedIncidentIds.remove(id);
        }
      case UnknownEvent():
        // Forward-compatible no-op: seq already advanced above.
        break;
    }
  }

  /// Upserts [incident] if it's `running` and belongs to the currently
  /// running BF-Tag, otherwise removes it (ADR 0016, "Snapshot"): covers
  /// both a transition away from `running` (closed/discarded) and an
  /// Einsatz belonging to a BF-Tag that isn't the running one.
  void _applyIncident(Incident incident) {
    final matchesRunningDay =
        _bfDay != null && incident.bfDayId == _bfDay!.id;
    if (incident.state == IncidentState.running && matchesRunningDay) {
      _incidentsById[incident.id] = incident;
    } else {
      _incidentsById.remove(incident.id);
      _alarmsById.removeWhere((_, alarm) => alarm.incidentId == incident.id);
      _closeSuggestedIncidentIds.remove(incident.id);
    }
  }

  /// Sets `acknowledgedAt` on the matching recipient of [alarmId], if both
  /// the Alarmierung and the recipient are known (ADR 0017).
  void _applyAlarmAcknowledged(
    String alarmId,
    String personId,
    DateTime acknowledgedAt,
  ) {
    final alarm = _alarmsById[alarmId];
    if (alarm == null) return;
    final recipients = [
      for (final recipient in alarm.recipients)
        if (recipient.personId == personId)
          recipient.copyWith(acknowledgedAt: acknowledgedAt)
        else
          recipient,
    ];
    _alarmsById[alarmId] = alarm.copyWith(recipients: recipients);
  }

  /// Updates the push counters on the matching Alarmierung (ADR 0018),
  /// ignoring the event if the Alarmierung is unknown.
  void _applyAlarmPushReported(
    String alarmId,
    int pushDelivered,
    int pushRejected,
  ) {
    final alarm = _alarmsById[alarmId];
    if (alarm == null) return;
    _alarmsById[alarmId] = alarm.copyWith(
      pushDelivered: pushDelivered,
      pushRejected: pushRejected,
    );
  }

  /// A gap was detected (gaps include: gaps in event seq, hello/heartbeat
  /// seq mismatch, and the initial connect). Reload the snapshot once;
  /// further gaps detected while already reloading are no-ops.
  void _handleGap() {
    if (_awaitingSnapshot) return;
    _awaitingSnapshot = true;
    _messageQueue.clear();
    unawaited(_loadSnapshot());
  }

  /// Handles the `session.revoked` control message: marks the client
  /// revoked and closes the connection without reconnecting.
  void _handleRevoked() {
    if (_disposed || _revoked) return;
    _markRevoked();
    unawaited(_subscription?.cancel());
    _subscription = null;
    try {
      _connection?.sink.close();
    } catch (_) {
      // Ignore: we're tearing down anyway.
    }
    _connection = null;
  }

  void _markRevoked() {
    if (_revoked) return;
    _revoked = true;
    _watchdogTimer?.cancel();
    _reconnectTimer?.cancel();
    _messageQueue.clear();
    _status = ConnectionStatus.revoked;
    _emit();
    _onRevoked?.call();
  }

  List<Vehicle> get _sortedActiveVehicles {
    final vehicles = _vehiclesById.values.where((v) => v.active).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return vehicles;
  }

  List<Shift> get _sortedShifts {
    final shifts = _shiftsById.values.toList()
      ..sort((a, b) {
        final byStart = a.startsAt.compareTo(b.startsAt);
        return byStart != 0 ? byStart : a.name.compareTo(b.name);
      });
    return shifts;
  }

  List<Incident> get _sortedIncidents {
    final incidents = _incidentsById.values.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    return incidents;
  }

  List<Alarm> get _sortedAlarms {
    final alarms = _alarmsById.values.toList()
      ..sort((a, b) {
        final at = a.triggeredAt;
        final bt = b.triggeredAt;
        if (at == null && bt == null) return 0;
        if (at == null) return -1;
        if (bt == null) return 1;
        return at.compareTo(bt);
      });
    return alarms;
  }

  void _emit() {
    if (_disposed) return;
    _controller.add(
      RealtimeState(
        seq: _lastSeq,
        vehicles: _sortedActiveVehicles,
        slides: List.of(_slides),
        status: _status,
        bfDay: _bfDay,
        shifts: _sortedShifts,
        incidents: _sortedIncidents,
        alarms: _sortedAlarms,
        closeSuggestedIncidentIds: Set.of(_closeSuggestedIncidentIds),
      ),
    );
  }

  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    if (_disposed) return;
    _watchdogTimer = Timer(heartbeatInterval * 2, _onSilence);
  }

  void _onSilence() {
    _closeAndReconnect();
  }

  void _closeAndReconnect() {
    if (_disposed) return;
    _watchdogTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    try {
      _connection?.sink.close();
    } catch (_) {
      // Ignore: reconnecting regardless.
    }
    _connection = null;
    _onSocketClosed(null);
  }

  void _onSocketDone() {
    _watchdogTimer?.cancel();
    final closeCode = _connection?.closeCode;
    _onSocketClosed(closeCode);
  }

  void _onSocketClosed(int? closeCode) {
    if (_disposed || _revoked) return;
    if (closeCode == 4403) {
      _markRevoked();
      return;
    }
    _awaitingSnapshot = true;
    _messageQueue.clear();
    _status = ConnectionStatus.reconnecting;
    _emit();
    if (closeCode == 4401) {
      unawaited(_refreshThenReconnect());
    } else {
      _scheduleReconnect();
    }
  }

  Future<void> _refreshThenReconnect() async {
    try {
      await _refreshSession();
    } catch (_) {
      // Best-effort: reconnect anyway, the server will reject again if the
      // refresh genuinely failed, re-triggering this path.
    }
    if (_disposed || _revoked) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _revoked) return;
    _reconnectTimer?.cancel();
    _status = ConnectionStatus.reconnecting;
    _emit();
    final delay = _backoff(_reconnectAttempt, _random);
    _reconnectAttempt++;
    _reconnectTimer = Timer(delay, () {
      unawaited(_connect());
    });
  }
}
