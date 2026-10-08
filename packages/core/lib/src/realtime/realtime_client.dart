import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../domain/vehicle.dart';
import 'realtime_event.dart';
import 'snapshot.dart';
import 'web_socket_connection.dart';

/// Connection status exposed to the UI alongside the live vehicle list.
enum ConnectionStatus { connecting, live, reconnecting }

/// A snapshot of realtime state: the current `seq`, the active vehicles
/// (sorted by `sort_order`), and the connection status.
class RealtimeState {
  const RealtimeState({
    required this.seq,
    required this.vehicles,
    required this.status,
  });

  final int seq;
  final List<Vehicle> vehicles;
  final ConnectionStatus status;
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
class RealtimeClient {
  RealtimeClient({
    required Uri wsEndpoint,
    required Future<Snapshot> Function() loadSnapshot,
    required Future<String?> Function() accessToken,
    required Future<void> Function() refreshSession,
    WebSocketConnector connector = connectWebSocket,
    this.heartbeatInterval = const Duration(seconds: 25),
    Random? random,
    Duration Function(int attempt, Random random)? backoff,
  })  : _wsEndpoint = wsEndpoint,
        _loadSnapshotFn = loadSnapshot,
        _accessToken = accessToken,
        _refreshSession = refreshSession,
        _connector = connector,
        _random = random ?? Random(),
        _backoff = backoff ?? defaultReconnectBackoff;

  final Uri _wsEndpoint;
  final Future<Snapshot> Function() _loadSnapshotFn;
  final Future<String?> Function() _accessToken;
  final Future<void> Function() _refreshSession;
  final WebSocketConnector _connector;
  final Duration heartbeatInterval;
  final Random _random;
  final Duration Function(int attempt, Random random) _backoff;

  final StreamController<RealtimeState> _controller =
      StreamController<RealtimeState>.broadcast();

  /// Emits a new [RealtimeState] whenever the vehicle list, `seq`, or
  /// connection status changes.
  Stream<RealtimeState> get states => _controller.stream;

  int _lastSeq = 0;
  final Map<String, Vehicle> _vehiclesById = <String, Vehicle>{};
  ConnectionStatus _status = ConnectionStatus.connecting;

  /// true until the (initial or a reload-triggered) snapshot has loaded;
  /// incoming messages are buffered in [_messageQueue] while true.
  bool _awaitingSnapshot = true;
  final List<dynamic> _messageQueue = <dynamic>[];

  WebSocketConnection? _connection;
  StreamSubscription<dynamic>? _subscription;
  Timer? _watchdogTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _started = false;
  bool _disposed = false;

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
  }

  Future<void> _connect() async {
    if (_disposed) return;
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
    if (_awaitingSnapshot) {
      _messageQueue.add(raw);
      return;
    }
    _processMessage(raw);
  }

  void _drainQueue() {
    final queued = List<dynamic>.of(_messageQueue);
    _messageQueue.clear();
    for (final raw in queued) {
      if (_awaitingSnapshot) {
        // A gap was detected mid-drain and a reload is already underway;
        // the remaining (stale) queue is irrelevant once it completes.
        break;
      }
      _processMessage(raw);
    }
  }

  void _processMessage(dynamic raw) {
    final Map<String, dynamic> json = raw is String
        ? jsonDecode(raw) as Map<String, dynamic>
        : Map<String, dynamic>.from(raw as Map);
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
      case UnknownEvent():
        // Forward-compatible no-op: seq already advanced above.
        break;
    }
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

  List<Vehicle> get _sortedActiveVehicles {
    final vehicles = _vehiclesById.values.where((v) => v.active).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return vehicles;
  }

  void _emit() {
    if (_disposed) return;
    _controller.add(
      RealtimeState(
        seq: _lastSeq,
        vehicles: _sortedActiveVehicles,
        status: _status,
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
    if (_disposed) return;
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
    if (_disposed) return;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
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
