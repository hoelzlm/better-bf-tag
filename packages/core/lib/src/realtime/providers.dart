import 'dart:async';

import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_config.dart';
import '../api/dio_provider.dart';
import '../auth/paired_session.dart';
import '../auth/session.dart';
import '../domain/bf_day.dart';
import '../domain/fms_status.dart';
import '../domain/shift.dart';
import '../domain/slide.dart';
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

Slide _slideFromApi(GetSnapshot200ResponseSlidesInner s) {
  final image = s.image;
  return Slide(
    id: s.id,
    title: s.title,
    body: s.body,
    durationSeconds: s.durationSeconds,
    sortOrder: s.sortOrder,
    active: s.active,
    image: image == null
        ? null
        : SlideImage(
            contentType: image.contentType,
            sizeBytes: image.sizeBytes,
            version: image.version,
          ),
  );
}

BfDay? _bfDayFromApi(GetSnapshot200ResponseBfDay? day) {
  if (day == null) return null;
  return BfDay(
    id: day.id,
    name: day.name,
    startsAt: DateTime.parse(day.startsAt),
    endsAt: DateTime.parse(day.endsAt),
    state: BfDayState.fromWire(day.state.name),
  );
}

Shift _shiftFromApi(GetSnapshot200ResponseShiftsInner s) {
  return Shift(
    id: s.id,
    bfDayId: s.bfDayId,
    name: s.name,
    startsAt: DateTime.parse(s.startsAt),
    endsAt: DateTime.parse(s.endsAt),
    crew: s.crew
        .map(
          (c) => CrewAssignment(
            vehicleId: c.vehicleId,
            personId: c.personId,
            displayName: c.displayName,
            function: c.function_,
          ),
        )
        .toList(),
  );
}

Snapshot _snapshotFromApi(GetSnapshot200Response data) {
  return Snapshot(
    seq: data.seq,
    vehicles: data.vehicles.map(_vehicleFromApi).toList(),
    slides: data.slides.map(_slideFromApi).toList(),
    bfDay: _bfDayFromApi(data.bfDay),
    shifts: data.shifts.map(_shiftFromApi).toList(),
    currentShiftId: data.currentShiftId,
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
      return _snapshotFromApi(data);
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

/// The live, sorted, active Folien (ADR 0014) -- empty while signed out,
/// before the first snapshot has loaded, or when there are none.
final slidesProvider = StreamProvider<List<Slide>>((ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) {
    return Stream.value(const <Slide>[]);
  }
  return client.states.map((state) => state.slides);
});

/// The current realtime connection status.
final realtimeConnectionProvider = StreamProvider<ConnectionStatus>((ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) {
    return Stream.value(ConnectionStatus.connecting);
  }
  return client.states.map((state) => state.status);
});

/// The currently running BF-Tag (ADR 0013), or `null` -- empty while signed
/// out, before the first snapshot has loaded, or when no BF-Tag is running.
final bfDayProvider = StreamProvider<BfDay?>((ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) {
    return Stream.value(null);
  }
  return client.states.map((state) => state.bfDay);
});

/// The shifts of the currently running BF-Tag (ADR 0013), with crew --
/// empty while signed out, before the first snapshot has loaded, or when
/// no BF-Tag is running.
final shiftsProvider = StreamProvider<List<Shift>>((ref) {
  final client = ref.watch(realtimeClientProvider);
  if (client == null) {
    return Stream.value(const <Shift>[]);
  }
  return client.states.map((state) => state.shifts);
});

/// The [RealtimeClient] for the current paired device session (mobile app,
/// or the web monitor via Ticket 03), or `null` when unpaired. Mirrors
/// [realtimeClientProvider] but is bound to [pairedSessionControllerProvider]
/// instead of the web admin [sessionControllerProvider]. On `session.revoked`
/// / close code 4403, calls [PairedSessionController.onRevoked].
final pairedRealtimeClientProvider = Provider<RealtimeClient?>((ref) {
  final session = ref.watch(pairedSessionControllerProvider);
  if (session is! Paired) {
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
      return _snapshotFromApi(data);
    },
    accessToken: () async {
      final current = ref.read(pairedSessionControllerProvider);
      return current is Paired ? current.accessToken : null;
    },
    refreshSession: () async {
      await ref.read(pairedSessionControllerProvider.notifier).refresh();
    },
    onRevoked: () {
      unawaited(
        ref.read(pairedSessionControllerProvider.notifier).onRevoked(),
      );
    },
  );
  client.start();
  ref.onDispose(() {
    unawaited(client.dispose());
  });
  return client;
});

/// The connection status of [pairedRealtimeClientProvider].
final pairedRealtimeConnectionProvider = StreamProvider<ConnectionStatus>((
  ref,
) {
  final client = ref.watch(pairedRealtimeClientProvider);
  if (client == null) {
    return Stream.value(ConnectionStatus.connecting);
  }
  return client.states.map((state) => state.status);
});
