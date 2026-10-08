import 'dart:async';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:bftag_core/bftag_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The state of the web monitor's own session (ADR 0012, "Monitor im
/// Browser"), independent of the admin web session
/// ([sessionControllerProvider]): pairing a Monitor (not a Person) to this
/// browser via `POST /auth/monitor/pair`.
sealed class MonitorSessionState {
  const MonitorSessionState();
}

/// Initial state before [MonitorSessionController.restore] has resolved;
/// UI should show a loading screen in this state, not the pairing screen.
class MonitorUnknown extends MonitorSessionState {
  const MonitorUnknown();
}

/// No paired monitor session (never paired, or cleared after a 401/revoke).
///
/// [revoked] distinguishes an explicit revoke/re-pair notification (true)
/// from a plain unpaired state (false), so the UI can show "Dieser Monitor
/// wurde gesperrt oder neu gekoppelt."
class MonitorUnpaired extends MonitorSessionState {
  const MonitorUnpaired({this.revoked = false});

  final bool revoked;
}

/// A paired monitor with a valid (in-memory) access token.
class MonitorPaired extends MonitorSessionState {
  const MonitorPaired({
    required this.monitorId,
    required this.name,
    required this.accessToken,
  });

  final String monitorId;
  final String name;
  final String accessToken;
}

/// A monitor session is stored, but the most recent refresh attempt failed
/// on a network error (not an explicit 401). The stored refresh token is
/// deliberately *not* cleared; the UI shows the connection banner and
/// retries (same design choice as `PairedOffline`, see
/// packages/core/lib/src/auth/paired_session.dart).
class MonitorOffline extends MonitorSessionState {
  const MonitorOffline(this.monitorId);

  final String monitorId;
}

/// Thrown by [MonitorSessionController.pair] on failure, with a message
/// safe to show to the user.
class MonitorPairingFailure implements Exception {
  const MonitorPairingFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Owns the current [MonitorSessionState] and the pair/restore/refresh/
/// onRevoked flows for the web monitor (ADR 0012). Modelled after
/// [PairedSessionController], but talks to the Monitor-specific endpoints
/// (`/auth/monitor/pair`, `/auth/monitor/refresh`) and response shape
/// (`monitor: {id, name}`, no `person`), so it is kept separate rather than
/// parameterising `PairedSessionController`.
///
/// Persists the refresh token + monitor id via [tokenStoreProvider]
/// (the same [TokenStore] abstraction `PairedSessionController` uses);
/// `apps/web`'s `/monitor` route overrides it with `LocalStorageTokenStore`,
/// tests with `InMemoryTokenStore`.
class MonitorSessionController extends Notifier<MonitorSessionState> {
  @override
  MonitorSessionState build() => const MonitorUnknown();

  String? _refreshToken;
  Future<String?>? _refreshInFlight;

  /// Restores a session from a stored refresh token, if any.
  Future<void> restore() async {
    final store = ref.read(tokenStoreProvider);
    final stored = await store.read();
    if (stored == null) {
      state = const MonitorUnpaired();
      return;
    }
    _refreshToken = stored.refreshToken;
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.monitorRefresh(
        deviceRefreshRequest: DeviceRefreshRequest(
          (b) => b..refreshToken = stored.refreshToken,
        ),
      );
      final data = response.data;
      if (data == null) {
        state = MonitorOffline(stored.deviceId);
        return;
      }
      await _applyResult(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await store.clear();
        _refreshToken = null;
        state = const MonitorUnpaired();
      } else {
        state = MonitorOffline(stored.deviceId);
      }
    }
  }

  /// Redeems a pairing code (`POST /auth/monitor/pair`), normalizing it
  /// first. Throws [MonitorPairingFailure] with a German, user-safe
  /// message on failure.
  Future<void> pair(String code) async {
    final normalized = normalizePairingCode(code);
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.monitorPair(
        monitorPairRequest: MonitorPairRequest((b) => b..code = normalized),
      );
      final data = response.data;
      if (data == null) {
        throw const MonitorPairingFailure('Server nicht erreichbar.');
      }
      await _applyResult(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const MonitorPairingFailure('Code ungültig oder abgelaufen.');
      }
      if (error.response?.statusCode == 429) {
        throw const MonitorPairingFailure(
          'Zu viele Versuche. Bitte später erneut versuchen.',
        );
      }
      throw const MonitorPairingFailure('Server nicht erreichbar.');
    }
  }

  /// Refreshes the access token, returning the new token or `null` on
  /// failure. Concurrent calls share one in-flight request (single-flight).
  Future<String?> refresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      return null;
    }
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.monitorRefresh(
        deviceRefreshRequest: DeviceRefreshRequest(
          (b) => b..refreshToken = refreshToken,
        ),
      );
      final data = response.data;
      if (data == null) {
        return null;
      }
      await _applyResult(data);
      return data.accessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await ref.read(tokenStoreProvider).clear();
        _refreshToken = null;
        state = const MonitorUnpaired();
      }
      return null;
    }
  }

  /// Called when the realtime connection reports `session.revoked` / close
  /// 4403, or a refresh comes back 401: clears the stored session and
  /// returns to [MonitorUnpaired] with `revoked: true`.
  Future<void> onRevoked() async {
    await ref.read(tokenStoreProvider).clear();
    _refreshToken = null;
    state = const MonitorUnpaired(revoked: true);
  }

  Future<void> _applyResult(MonitorPair200Response data) async {
    _refreshToken = data.refreshToken;
    await ref.read(tokenStoreProvider).write(
          StoredDeviceSession(
            refreshToken: data.refreshToken,
            deviceId: data.monitor.id,
          ),
        );
    state = MonitorPaired(
      monitorId: data.monitor.id,
      name: data.monitor.name,
      accessToken: data.accessToken,
    );
  }
}

final monitorSessionControllerProvider =
    NotifierProvider<MonitorSessionController, MonitorSessionState>(
  MonitorSessionController.new,
);

class _MonitorSessionAuthBinding implements AuthSessionBinding {
  _MonitorSessionAuthBinding(this._ref);

  final Ref _ref;

  @override
  String? get accessToken {
    final state = _ref.read(monitorSessionControllerProvider);
    return state is MonitorPaired ? state.accessToken : null;
  }

  @override
  Future<String?> refreshAccessToken() =>
      _ref.read(monitorSessionControllerProvider.notifier).refresh();
}

/// Never used by the monitor flow -- overriding [sessionControllerProvider]
/// (the web admin session) with this inside the `/monitor` `ProviderScope`
/// guarantees the admin session (and its `/auth/refresh` cookie flow)
/// cannot leak into the monitor, regardless of whether an admin is also
/// signed in elsewhere in the same browser.
class MonitorUnusedAdminSessionController extends SessionController {
  @override
  SessionState build() => const SessionSignedOut();
}

Vehicle _vehicleFromApi(ListVehicles200ResponseInner v) {
  final statusChangedAtRaw = v.statusChangedAt;
  return Vehicle(
    id: v.id,
    callSign: v.callSign,
    shortName: v.shortName,
    type: v.type,
    status: FmsStatus.fromCode(v.status),
    statusChangedAt:
        statusChangedAtRaw == null ? null : DateTime.parse(statusChangedAtRaw),
    sortOrder: v.sortOrder,
    active: v.active,
  );
}

/// The [WebSocketConnector] used by the monitor's [RealtimeClient].
/// Production uses the real [connectWebSocket]; tests override this with a
/// fake connector instead of hitting the network.
final monitorWebSocketConnectorProvider = Provider<WebSocketConnector>(
  (ref) => connectWebSocket,
);

RealtimeClient? _buildMonitorRealtimeClient(Ref ref) {
  final session = ref.watch(monitorSessionControllerProvider);
  if (session is! MonitorPaired) {
    return null;
  }
  final config = ref.watch(apiConfigProvider);
  final apiClient = ref.watch(apiClientProvider);
  final connector = ref.watch(monitorWebSocketConnectorProvider);

  final client = RealtimeClient(
    wsEndpoint: wsEndpointFromApiConfig(config),
    connector: connector,
    loadSnapshot: () async {
      final response = await apiClient.getSnapshotApi().getSnapshot();
      final data = response.data;
      if (data == null) {
        throw StateError('GET /snapshot returned no body');
      }
      return Snapshot(
        seq: data.seq,
        vehicles: data.vehicles.map(_vehicleFromApi).toList(),
      );
    },
    accessToken: () async {
      final current = ref.read(monitorSessionControllerProvider);
      return current is MonitorPaired ? current.accessToken : null;
    },
    refreshSession: () async {
      await ref.read(monitorSessionControllerProvider.notifier).refresh();
    },
    onRevoked: () {
      unawaited(
        ref.read(monitorSessionControllerProvider.notifier).onRevoked(),
      );
    },
  );
  client.start();
  ref.onDispose(() {
    unawaited(client.dispose());
  });
  return client;
}

Stream<List<Vehicle>> _buildMonitorVehicles(Ref ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) {
    return Stream.value(const <Vehicle>[]);
  }
  return client.states.map((state) => state.vehicles);
}

Stream<ConnectionStatus> _buildMonitorConnection(Ref ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) {
    return Stream.value(ConnectionStatus.connecting);
  }
  return client.states.map((state) => state.status);
}

/// The provider overrides that wire the `/monitor` `ProviderScope` to its
/// own session, own `Dio`/`RealtimeClient`, and keep the admin web session
/// out of the picture entirely -- so `VehicleStatusBar`
/// (`vehiclesProvider`/`realtimeConnectionProvider`) works unchanged.
///
/// [dio] lets tests inject a `Dio` wired to a fake `HttpClientAdapter`;
/// production (the `/monitor` route) omits it, building a real `Dio` from
/// [apiConfigProvider].
List<Override> monitorProviderOverrides({
  required TokenStore tokenStore,
  Dio? dio,
}) {
  return [
    tokenStoreProvider.overrideWithValue(tokenStore),
    dioProvider.overrideWith((ref) {
      final config = ref.watch(apiConfigProvider);
      final d = dio ?? Dio(BaseOptions(baseUrl: config.baseUrl));
      d.interceptors.add(AuthInterceptor(ref));
      return d;
    }),
    apiClientProvider.overrideWith(
      (ref) => BftagApiClient(dio: ref.watch(dioProvider)),
    ),
    authSessionBindingProvider.overrideWith(
      (ref) => _MonitorSessionAuthBinding(ref),
    ),
    sessionControllerProvider.overrideWith(
      MonitorUnusedAdminSessionController.new,
    ),
    // Forces this provider's instance to live in the `/monitor`
    // `ProviderScope` rather than the root: an un-overridden Notifier
    // provider resolves against the *root* container regardless of where
    // it is read from, which would make its own `ref.read(tokenStoreProvider)`
    // miss the override above entirely.
    monitorSessionControllerProvider.overrideWith(
      MonitorSessionController.new,
    ),
    realtimeClientProvider.overrideWith(_buildMonitorRealtimeClient),
    vehiclesProvider.overrideWith(_buildMonitorVehicles),
    realtimeConnectionProvider.overrideWith(_buildMonitorConnection),
  ];
}
