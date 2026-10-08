import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Best-effort browser fullscreen request for `document.documentElement`
/// (ADR 0012: triggered by the "Zum Aktivieren tippen" user gesture).
/// Browsers reject this outside a user gesture or when unsupported; callers
/// must treat failures as non-fatal.
Future<void> requestFullscreenPlatform() async {
  await web.document.documentElement?.requestFullscreen().toDart;
}
