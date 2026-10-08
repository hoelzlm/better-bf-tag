export 'monitor_fullscreen_stub.dart'
    if (dart.library.js_interop) 'monitor_fullscreen_web.dart'
    if (dart.library.html) 'monitor_fullscreen_web.dart';
