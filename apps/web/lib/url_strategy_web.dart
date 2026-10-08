import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Uses path-based URLs (no `#`) on web.
void configureUrlStrategy() {
  usePathUrlStrategy();
}
