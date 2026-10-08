import 'package:bftag_core/bftag_core.dart';

/// Non-web stub for [LocalStorageTokenStore] so `flutter test` (VM) can
/// compile this file; it is never exercised there (tests use
/// [InMemoryTokenStore]).
class LocalStorageTokenStore implements TokenStore {
  @override
  Future<StoredDeviceSession?> read() async => null;

  @override
  Future<void> write(StoredDeviceSession session) async {}

  @override
  Future<void> clear() async {}
}
