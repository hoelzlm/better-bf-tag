import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Injectable [TileProvider] for every [IncidentMap] in apps/web (ADR
/// 0026, "Clients"): `null` lets `flutter_map` use its default (network)
/// tile provider in production; widget tests override this with an
/// offline fake so no tile requests are made.
final mapTileProviderProvider = Provider<TileProvider?>((ref) => null);
