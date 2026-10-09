import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists whether the Onboarding (ADR 0021) has been completed on this
/// device. Implementations: [SecureOnboardingStore] (apps/mobile,
/// `flutter_secure_storage`) and [InMemoryOnboardingStore] (tests).
abstract class OnboardingStore {
  Future<bool> isCompleted();

  Future<void> setCompleted(bool v);
}

/// [OnboardingStore] backed by `flutter_secure_storage`, so the flag
/// survives app restarts but is cleared on logout (ADR 0021).
class SecureOnboardingStore implements OnboardingStore {
  SecureOnboardingStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'onboarding_completed';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> isCompleted() async {
    final value = await _storage.read(key: _key);
    return value == 'true';
  }

  @override
  Future<void> setCompleted(bool v) async {
    await _storage.write(key: _key, value: v.toString());
  }
}

/// In-memory [OnboardingStore], for tests.
class InMemoryOnboardingStore implements OnboardingStore {
  InMemoryOnboardingStore({this.completed = false});

  bool completed;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> setCompleted(bool v) async {
    completed = v;
  }
}

/// The [OnboardingStore] used by [OnboardingCompletedNotifier]. Defaults to
/// [SecureOnboardingStore]; tests override this with
/// [InMemoryOnboardingStore].
final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => SecureOnboardingStore(),
);

/// Whether the Onboarding (ADR 0021) has been completed on this device.
/// `null` means "not loaded yet" -- the router must not redirect based on
/// this value while it's `null`. Loaded via [load] once the paired session
/// becomes [Paired], cleared (set to `false`) on logout.
class OnboardingCompletedNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  /// Reads the persisted flag and updates state.
  Future<void> load() async {
    final completed = await ref.read(onboardingStoreProvider).isCompleted();
    state = completed;
  }

  /// Marks the Onboarding as completed ("Fertig").
  Future<void> complete() async {
    await ref.read(onboardingStoreProvider).setCompleted(true);
    state = true;
  }

  /// Marks the Onboarding as not completed (e.g. on logout), so the next
  /// paired session goes through it again.
  Future<void> reset() async {
    await ref.read(onboardingStoreProvider).setCompleted(false);
    state = false;
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool?>(
  OnboardingCompletedNotifier.new,
);
