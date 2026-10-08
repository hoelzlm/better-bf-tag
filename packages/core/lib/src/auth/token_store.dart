import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A persisted device session: the rotating refresh token plus the
/// device id issued by `POST /auth/pair` (ADR 0010).
class StoredDeviceSession {
  const StoredDeviceSession({required this.refreshToken, required this.deviceId});

  final String refreshToken;
  final String deviceId;
}

/// Persists the current device/monitor session across app restarts.
///
/// Implementations: `SecureTokenStore` (apps/mobile, `flutter_secure_storage`),
/// `LocalStorageTokenStore` (apps/web monitor, browser storage, Ticket 03),
/// and [InMemoryTokenStore] for tests.
abstract class TokenStore {
  Future<StoredDeviceSession?> read();

  Future<void> write(StoredDeviceSession session);

  Future<void> clear();
}

/// In-memory [TokenStore], for tests.
class InMemoryTokenStore implements TokenStore {
  StoredDeviceSession? _stored;

  @override
  Future<StoredDeviceSession?> read() async => _stored;

  @override
  Future<void> write(StoredDeviceSession session) async {
    _stored = session;
  }

  @override
  Future<void> clear() async {
    _stored = null;
  }
}

/// The [TokenStore] used by [PairedSessionController].
///
/// Has no default implementation: every app that uses
/// `PairedSessionController` must override this provider (mobile with
/// `SecureTokenStore`, the web monitor with `LocalStorageTokenStore`, tests
/// with [InMemoryTokenStore]).
final tokenStoreProvider = Provider<TokenStore>((ref) {
  throw UnimplementedError(
    'tokenStoreProvider must be overridden by the app.',
  );
});
