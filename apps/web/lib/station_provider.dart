import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Wache-Koordinaten (ADR 0026) for [IncidentMap]'s `station` pin, loaded
/// once via `GET /snapshot` rather than through the realtime client: the
/// Wache has no dedicated endpoint and emits no event (ADR 0026, "Wache"
/// -- "ändert sich nur per Neustart"), so a one-shot fetch is enough.
///
/// Scoping: an un-overridden provider lives in the *root* container, even
/// when read from the `/monitor` route's nested `ProviderScope`. There it
/// would read the admin [apiClientProvider] (no monitor token) and, in debug
/// builds, trip Riverpod's "dependency overridden but provider is not"
/// assertion. `monitorProviderOverrides` therefore overrides this provider
/// with [loadStation] so the Monitor gets its own scoped instance.
final stationProvider = FutureProvider<LatLng?>(loadStation);

/// Fetches the Wache coordinates via whichever [apiClientProvider] the
/// calling scope resolves.
Future<LatLng?> loadStation(Ref ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.getSnapshotApi().getSnapshot();
  final station = response.data?.station;
  if (station == null) return null;
  return LatLng(station.latitude.toDouble(), station.longitude.toDouble());
}
