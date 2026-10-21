import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Mitte Deutschlands -- Fallback-Kartenmittelpunkt ohne Einsatz/Wache
/// (ADR 0026, Web-Einsatzformular Startansicht).
const _germanyCenter = LatLng(51.16, 10.45);

/// Attribution text shown on every [IncidentMap] (ADR 0026): required by
/// OpenStreetMap's tile usage policy.
const osmAttribution = '© OpenStreetMap-Mitwirkende';

/// Shared map widget (ADR 0026, "Clients"): OSM-Kacheln, Einsatz-Pin
/// (rot) und optionalem Wache-Pin, immer sichtbare Attribution.
///
/// The camera is computed once from [incident]/[station]/[initialCenter]/
/// [initialZoom] when the widget is built; it does not re-fit when
/// [incident] changes later (the marker does update -- see the class
/// doc of [IncidentMap] in ADR 0026, "wenn sich `incident` ändert
/// (Kamera darf bleiben)").
class IncidentMap extends StatelessWidget {
  const IncidentMap({
    super.key,
    this.incident,
    this.station,
    this.interactive = false,
    this.onTap,
    this.tileProvider,
    this.initialCenter,
    this.initialZoom,
  });

  /// Einsatzort, or `null` for none (red `Icons.location_on` pin).
  final LatLng? incident;

  /// Wache, or `null` for none (`Icons.home` pin).
  final LatLng? station;

  /// `false` disables all map gestures (pan/zoom/rotate) -- used for the
  /// Monitor-Einsatzansicht and the App's small map.
  final bool interactive;

  /// Called with the tapped point when [interactive] is `true`; wired
  /// to [MapOptions.onTap].
  final void Function(LatLng point)? onTap;

  /// Injectable [TileProvider] so widget tests run without network
  /// access (ADR 0026).
  final TileProvider? tileProvider;

  /// Fallback camera center used only when neither [incident] nor
  /// [station] is set.
  final LatLng? initialCenter;

  /// Fallback camera zoom, paired with [initialCenter].
  final double? initialZoom;

  @override
  Widget build(BuildContext context) {
    final center = _cameraCenter();
    final zoom = _cameraZoom();
    final bounds = _cameraBounds();

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        initialCameraFit: bounds == null
            ? null
            : CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(48),
                maxZoom: 16,
              ),
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: interactive && onTap != null
            ? (tapPosition, point) => onTap!(point)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'de.bftag.app',
          maxZoom: 19,
          tileProvider: tileProvider,
        ),
        MarkerLayer(
          markers: [
            if (incident != null)
              Marker(
                key: const Key('incident-map-incident-pin'),
                point: incident!,
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,
                child: const _Pin(
                  icon: Icons.location_on,
                  color: Color(0xFFD32F2F),
                ),
              ),
            if (station != null)
              Marker(
                key: const Key('incident-map-station-pin'),
                point: station!,
                width: 40,
                height: 40,
                child: const _Pin(icon: Icons.home, color: Color(0xFF1A237E)),
              ),
          ],
        ),
        const SimpleAttributionWidget(source: Text(osmAttribution)),
      ],
    );
  }

  LatLng _cameraCenter() {
    final incident = this.incident;
    final station = this.station;
    if (incident != null && station != null) {
      return LatLng(
        (incident.latitude + station.latitude) / 2,
        (incident.longitude + station.longitude) / 2,
      );
    }
    if (incident != null) {
      return incident;
    }
    if (initialCenter != null) {
      return initialCenter!;
    }
    if (station != null) {
      return station;
    }
    return _germanyCenter;
  }

  double _cameraZoom() {
    if (incident != null && station != null) {
      // Overridden by initialCameraFit (see [_cameraBounds]); kept as a
      // sane fallback in case fitting fails.
      return 16;
    }
    if (incident != null) {
      return 15;
    }
    if (initialZoom != null) {
      return initialZoom!;
    }
    if (station != null) {
      // Wache only (Monitor before the Einsatzort is known): neighbourhood
      // view so the pin and the surrounding streets are readable from afar.
      return 15;
    }
    return 6;
  }

  LatLngBounds? _cameraBounds() {
    final incident = this.incident;
    final station = this.station;
    if (incident == null || station == null) {
      return null;
    }
    return LatLngBounds(incident, station);
  }
}

/// Map pin with a fixed colour and a white halo, so it stays visible on the
/// light OSM tiles regardless of the app theme (the dark Monitor theme made
/// an uncoloured icon white and practically invisible).
class _Pin extends StatelessWidget {
  const _Pin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: 40,
      shadows: const [
        Shadow(color: Colors.white, blurRadius: 6),
        Shadow(color: Colors.white, blurRadius: 3),
      ],
    );
  }
}
