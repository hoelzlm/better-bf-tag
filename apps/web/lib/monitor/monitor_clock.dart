import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time, ticking once a second; injectable so standby-screen
/// tests are deterministic (override with `Stream.value(fixedTime)`).
final monitorClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});
