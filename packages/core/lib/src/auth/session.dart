import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/person.dart';

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

/// Owns the current [SessionState] and the login/logout/refresh flows.
///
/// Implemented as TODO stubs in this card; T01-7 fills in the real auth
/// wiring against `bftag_api_client`'s `AuthApi`.
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionUnknown();

  /// Restores a session from a stored refresh token, if any.
  Future<void> restore() async {
    throw UnimplementedError('SessionController.restore: implemented in T01-7');
  }

  /// Logs in with username/password and transitions to [SessionSignedIn].
  Future<void> login(String username, String password) async {
    throw UnimplementedError('SessionController.login: implemented in T01-7');
  }

  /// Logs out and transitions to [SessionSignedOut].
  Future<void> logout() async {
    throw UnimplementedError('SessionController.logout: implemented in T01-7');
  }

  /// Refreshes the access token, returning the new token or null on failure.
  Future<String?> refreshAccessToken() async {
    throw UnimplementedError(
      'SessionController.refreshAccessToken: implemented in T01-7',
    );
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
