import 'package:bftag_core/bftag_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Die Wache-Koordinaten (ADR 0026) der aktuellen paired-Session,
/// `null` solange unpaired, vor dem ersten Snapshot, oder wenn keine
/// Wache konfiguriert ist. Mirrors [pairedIncidentsProvider] -- the web
/// admin session has no equivalent yet.
final pairedStationProvider = StreamProvider<LatLng?>((ref) {
  final client = ref.watch(pairedRealtimeClientProvider);
  if (client == null) {
    return Stream.value(null);
  }
  return client.states.map((state) => state.station);
});
