import 'dart:async';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_config.dart';
import '../api/dio_provider.dart';
import '../auth/session.dart';
import '../domain/fms_status.dart';
import '../domain/vehicle.dart';
import 'realtime_client.dart';
import 'snapshot.dart';

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

/// Derives the `/ws` endpoint (without the `?token=` query parameter, added
/// per-connection by [RealtimeClient]) from [config].
///
/// An empty `baseUrl` means "same origin" (see [ApiConfig]); `Uri.base`
/// resolves that on web. Mobile/desktop clients always configure an
/// explicit `API_BASE_URL`, so this fallback is web-only in practice.
Uri wsEndpointFromApiConfig(ApiConfig config) {
  final base = config.baseUrl.isEmpty ? Uri.base : Uri.parse(config.baseUrl);
  final scheme = base.scheme == 'https' ? 'wss' : 'ws';
  return base.replace(scheme: scheme, path: '/ws', query: '');
}

/// The [RealtimeClient] for the current session, or `null` when signed out.
///
/// Rebuilds (disposing the previous client) whenever [sessionControllerProvider]
/// transitions between signed-in/signed-out, so a freshly signed-in session
/// gets its own connection and a sign-out tears the old one down.
final realtimeClientProvider = Provider<RealtimeClient?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  if (session is! SessionSignedIn) {
    return null;
  }
  final config = ref.watch(apiConfigProvider);
  final apiClient = ref.watch(apiClientProvider);

  final client = RealtimeClient(
    wsEndpoint: wsEndpointFromApiConfig(config),
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
      final current = ref.read(sessionControllerProvider);
      return current is SessionSignedIn ? current.accessToken : null;
    },
    refreshSession: () async {
      await ref.read(sessionControllerProvider.notifier).refreshAccessToken();
    },
  );
  client.start();
  ref.onDispose(() {
    unawaited(client.dispose());
  });
  return client;
});

/// The live, sorted, active vehicles -- empty while signed out or before
/// the first snapshot has loaded.
final vehiclesProvider = StreamProvider<List<Vehicle>>((ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) {
    return Stream.value(const <Vehicle>[]);
  }
  return client.states.map((state) => state.vehicles);
});

/// The current realtime connection status.
final realtimeConnectionProvider = StreamProvider<ConnectionStatus>((ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) {
    return Stream.value(ConnectionStatus.connecting);
  }
  return client.states.map((state) => state.status);
});
