import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_provider.dart';
import '../domain/permission.dart';
import '../domain/person.dart';
import 'auth_session_binding.dart';

/// The state of the current web session.
///
/// `SessionUnknown` is the initial state before [SessionController.restore]
/// has resolved; UI should show a loading screen in that state, not redirect.
sealed class SessionState {
  const SessionState();
}

/// Initial state: we haven't determined yet whether a session exists.
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

/// No signed-in person.
class SessionSignedOut extends SessionState {
  const SessionSignedOut();
}

/// A signed-in person with a valid (in-memory) access token.
class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.person, this.accessToken);

  final Person person;
  final String accessToken;
}

/// Thrown by [SessionController.login] when the login attempt failed, with a
/// message safe to show to the user.
class LoginFailure implements Exception {
  const LoginFailure(this.message);

  final String message;

  @override
  String toString() => message;
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

/// Owns the current [SessionState] and the login/logout/refresh flows.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionUnknown();

  Future<String?>? _refreshInFlight;

  /// Restores a session from a stored refresh token, if any.
  Future<void> restore() async {
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.refresh();
      final data = response.data;
      if (data == null) {
        state = const SessionSignedOut();
        return;
      }
      state = SessionSignedIn(_personFromApi(data.person), data.accessToken);
    } catch (_) {
      state = const SessionSignedOut();
    }
  }

  /// Logs in with username/password and transitions to [SessionSignedIn].
  Future<void> login(String username, String password) async {
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.login(
        loginRequest: LoginRequest(
          (b) => b
            ..username = username
            ..password = password,
        ),
      );
      final data = response.data;
      if (data == null) {
        throw const LoginFailure('Server nicht erreichbar.');
      }
      state = SessionSignedIn(_personFromApi(data.person), data.accessToken);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const LoginFailure('Benutzername oder Passwort falsch.');
      }
      if (error.response?.statusCode == 429) {
        throw const LoginFailure(
          'Zu viele Versuche. Bitte später erneut versuchen.',
        );
      }
      throw const LoginFailure('Server nicht erreichbar.');
    }
  }

  /// Logs out and transitions to [SessionSignedOut].
  Future<void> logout() async {
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      await api.logout();
    } catch (_) {
      // Ignore errors; the session is considered over regardless.
    }
    state = const SessionSignedOut();
  }

  /// Refreshes the access token, returning the new token or null on failure.
  ///
  /// Concurrent calls share one in-flight request.
  Future<String?> refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _doRefresh() async {
    final api = ref.read(apiClientProvider).getAuthApi();
    try {
      final response = await api.refresh();
      final data = response.data;
      if (data == null) {
        state = const SessionSignedOut();
        return null;
      }
      state = SessionSignedIn(_personFromApi(data.person), data.accessToken);
      return data.accessToken;
    } catch (_) {
      state = const SessionSignedOut();
      return null;
    }
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class _SessionControllerAuthBinding implements AuthSessionBinding {
  _SessionControllerAuthBinding(this._ref);

  final Ref _ref;

  @override
  String? get accessToken {
    final session = _ref.read(sessionControllerProvider);
    return session is SessionSignedIn ? session.accessToken : null;
  }

  @override
  Future<String?> refreshAccessToken() =>
      _ref.read(sessionControllerProvider.notifier).refreshAccessToken();
}

/// The [AuthSessionBinding] used by [AuthInterceptor] to attach and refresh
/// the `Authorization` header. Defaults to the web admin
/// [SessionController]; mobile/monitor apps override this provider (in
/// their own `ProviderScope`) with a binding backed by
/// `PairedSessionController`.
final authSessionBindingProvider = Provider<AuthSessionBinding>(
  (ref) => _SessionControllerAuthBinding(ref),
);
