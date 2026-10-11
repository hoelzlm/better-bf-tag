import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Wache-Koordinaten (ADR 0026) for [IncidentMap]'s `station` pin, loaded
/// once via `GET /snapshot` rather than through the realtime client: the
/// Wache has no dedicated endpoint and emits no event (ADR 0026, "Wache"
/// -- "ändert sich nur per Neustart"), so a one-shot fetch is enough.
///
/// Resolves against whichever [apiClientProvider] override is in scope,
/// so it works unchanged both for the admin web session (root scope) and
/// the paired Monitor session (`/monitor`'s own `ProviderScope`).
final stationProvider = FutureProvider<LatLng?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getSnapshotApi().getSnapshot();
  final station = response.data?.station;
  if (station == null) return null;
  return LatLng(station.latitude.toDouble(), station.longitude.toDouble());
});
