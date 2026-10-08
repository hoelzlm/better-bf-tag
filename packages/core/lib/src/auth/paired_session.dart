import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_provider.dart';
import '../domain/permission.dart';
import '../domain/person.dart';
import 'auth_session_binding.dart';
import 'token_store.dart';

/// The state of a device's paired session (mobile app, or the web monitor
/// via Ticket 03): coupling a `Person` (mobile) resp. a monitor to this
/// device via `POST /auth/pair`, see ADR 0010 ("Geräte-Sitzung").
sealed class PairedSessionState {
  const PairedSessionState();
}

/// Initial state before [PairedSessionController.restore] has resolved; UI
/// should show a splash/loading screen in this state, not redirect.
class PairedUnknown extends PairedSessionState {
  const PairedUnknown();
}

/// No paired device session (never paired, logged out, or revoked).
///
/// [revoked] distinguishes an explicit logout/normal unpaired (false) from
/// a `session.revoked` notification (true), so the UI can show a
/// one-time "Dieses Gerät wurde abgemeldet." message; see
/// [PairedSessionController.acknowledgeRevoked].
class PairedUnpaired extends PairedSessionState {
  const PairedUnpaired({this.revoked = false});

  final bool revoked;
}

/// A paired device with a valid (in-memory) access token.
class Paired extends PairedSessionState {
  const Paired(this.person, this.accessToken, this.deviceId);

  final Person person;
  final String accessToken;
  final String deviceId;
}

/// A device session is stored, but the most recent refresh attempt failed
/// on a network error (not an explicit 401) during [PairedSessionController
/// .restore]. The stored refresh token is deliberately *not* cleared -- a
/// network hiccup must not force a re-pair -- but we also don't have fresh
/// person/access-token data to show, so this is distinct from [Paired].
///
/// Design choice (kept simple, per the ticket): there is no built-in retry
/// loop here. The app should call [PairedSessionController.restore] again
/// once connectivity looks better (e.g. from a connectivity listener or a
/// "retry" button), and show an offline hint meanwhile.
class PairedOffline extends PairedSessionState {
  const PairedOffline(this.deviceId);

  final String deviceId;
}

/// Thrown by [PairedSessionController.pair] when the pairing attempt
/// failed, with a message safe to show to the user.
class PairingFailure implements Exception {
  const PairingFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Normalizes a pairing code as entered by a user: uppercase, with spaces
/// and hyphens stripped (ADR 0010: "beim Einlösen werden Groß-
/// /Kleinschreibung, Leerzeichen und Bindestriche ignoriert").
String normalizePairingCode(String input) {
  return input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
}

PersonType _personTypeFromApi(Login200ResponsePersonPersonTypeEnum value) {
  if (value == Login200ResponsePersonPersonTypeEnum.supervisor) {
    return PersonType.supervisor;
  }
  return PersonType.youth;
}

Permission _permissionFromApi(Login200ResponsePersonPermissionEnum value) {
  if (value == Login200ResponsePersonPermissionEnum.preparation) {
    return Permission.preparation;
  }
  if (value == Login200ResponsePersonPermissionEnum.dispatch) {
    return Permission.dispatch;
  }
  if (value == Login200ResponsePersonPermissionEnum.admin) {
    return Permission.admin;
  }
  return Permission.crew;
}

Person _personFromApi(Login200ResponsePerson apiPerson) {
  return Person(
    id: apiPerson.id,
    displayName: apiPerson.displayName,
    personType: _personTypeFromApi(apiPerson.personType),
    permission: _permissionFromApi(apiPerson.permission),
  );
}

/// Owns the current [PairedSessionState] and the pair/restore/refresh/
/// logout/revoke flows for a device session (ADR 0010).
///
/// Persists the refresh token + device id via [tokenStoreProvider]; every
/// app using this controller must override that provider (mobile:
/// `SecureTokenStore`; web monitor: `LocalStorageTokenStore`; tests:
/// [InMemoryTokenStore]).
class PairedSessionController extends Notifier<PairedSessionState> {
  @override
  PairedSessionState build() => const PairedUnknown();

  String? _refreshToken;
  String? _accessToken;
  Future<String?>? _refreshInFlight;

  /// Restores a session from a stored refresh token, if any.
  ///
  /// - no stored session -> [PairedUnpaired]
  /// - 401 (revoked/unknown refresh token) -> clears the store, [PairedUnpaired]
  /// - any other error (network) -> keeps the store, [PairedOffline]
  Future<void> restore() async {
    final store = ref.read(tokenStoreProvider);
    final stored = await store.read();
    if (stored == null) {
      state = const PairedUnpaired();
      return;
    }
    _refreshToken = stored.refreshToken;
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.deviceRefresh(
        deviceRefreshRequest: DeviceRefreshRequest(
          (b) => b..refreshToken = stored.refreshToken,
        ),
      );
      final data = response.data;
      if (data == null) {
        state = PairedOffline(stored.deviceId);
        return;
      }
      await _applyPairResult(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await store.clear();
        _refreshToken = null;
        _accessToken = null;
        state = const PairedUnpaired();
      } else {
        state = PairedOffline(stored.deviceId);
      }
    }
  }

  /// Redeems a pairing code (ADR 0010: `POST /auth/pair`), normalizing it
  /// first. Throws [PairingFailure] with a German, user-safe message on
  /// failure.
  Future<void> pair(
    String code, {
    required PairRequestPlatformEnum platform,
    required String appVersion,
    String? deviceName,
  }) async {
    final normalized = normalizePairingCode(code);
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.pair(
        pairRequest: PairRequest(
          (b) => b
            ..code = normalized
            ..platform = platform
            ..appVersion = appVersion
            ..deviceName = deviceName,
        ),
      );
      final data = response.data;
      if (data == null) {
        throw const PairingFailure('Server nicht erreichbar.');
      }
      await _applyPairResult(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const PairingFailure('Code ungültig oder abgelaufen.');
      }
      if (error.response?.statusCode == 429) {
        throw const PairingFailure(
          'Zu viele Versuche. Bitte später erneut versuchen.',
        );
      }
      throw const PairingFailure('Server nicht erreichbar.');
    }
  }

  /// Refreshes the access token, returning the new token or `null` on
  /// failure. Concurrent calls share one in-flight request (single-flight).
  Future<String?> refresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null) {
      return null;
    }
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.deviceRefresh(
        deviceRefreshRequest: DeviceRefreshRequest(
          (b) => b..refreshToken = refreshToken,
        ),
      );
      final data = response.data;
      if (data == null) {
        return null;
      }
      await _applyPairResult(data);
      return data.accessToken;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await ref.read(tokenStoreProvider).clear();
        _refreshToken = null;
        _accessToken = null;
        state = const PairedUnpaired();
      }
      return null;
    }
  }

  /// Logs this device out (`POST /auth/device/logout`) and clears the
  /// store regardless of whether the request succeeded.
  Future<void> logout() async {
    final accessToken = _accessToken;
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      await api.deviceLogout(
        headers: accessToken == null
            ? null
            : {'Authorization': 'Bearer $accessToken'},
      );
    } catch (_) {
      // Ignore: the device session is considered over regardless.
    }
    await ref.read(tokenStoreProvider).clear();
    _refreshToken = null;
    _accessToken = null;
    state = const PairedUnpaired();
  }

  /// Called when the realtime connection reports `session.revoked` (ADR
  /// 0010): clears the stored session and returns to [PairedUnpaired]
  /// (with `revoked: true`, so the UI can show a one-time hint).
  Future<void> onRevoked() async {
    await ref.read(tokenStoreProvider).clear();
    _refreshToken = null;
    _accessToken = null;
    state = const PairedUnpaired(revoked: true);
  }

  /// Clears the `revoked` flag on [PairedUnpaired] once the UI has shown
  /// its one-time hint, so it isn't shown again on rebuild.
  void acknowledgeRevoked() {
    if (state case PairedUnpaired(revoked: true)) {
      state = const PairedUnpaired();
    }
  }

  Future<void> _applyPairResult(Pair200Response data) async {
    _refreshToken = data.refreshToken;
    _accessToken = data.accessToken;
    await ref.read(tokenStoreProvider).write(
          StoredDeviceSession(
            refreshToken: data.refreshToken,
            deviceId: data.deviceId,
          ),
        );
    state = Paired(_personFromApi(data.person), data.accessToken, data.deviceId);
  }
}

final pairedSessionControllerProvider =
    NotifierProvider<PairedSessionController, PairedSessionState>(
  PairedSessionController.new,
);

class _PairedSessionAuthBinding implements AuthSessionBinding {
  _PairedSessionAuthBinding(this._ref);

  final Ref _ref;

  @override
  String? get accessToken {
    final state = _ref.read(pairedSessionControllerProvider);
    return state is Paired ? state.accessToken : null;
  }

  @override
  Future<String?> refreshAccessToken() =>
      _ref.read(pairedSessionControllerProvider.notifier).refresh();
}

/// [AuthSessionBinding] backed by [PairedSessionController]. Mobile/monitor
/// apps override `authSessionBindingProvider` with this (directly, or via
/// `authSessionBindingProvider.overrideWith((ref) =>
/// ref.watch(pairedSessionAuthBindingProvider))`) in their own
/// `ProviderScope`.
final pairedSessionAuthBindingProvider = Provider<AuthSessionBinding>(
  (ref) => _PairedSessionAuthBinding(ref),
);
