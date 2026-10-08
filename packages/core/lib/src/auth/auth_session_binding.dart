/// A session-agnostic view of "the current access token" and "refresh it",
/// so [AuthInterceptor] (see `../api/auth_interceptor.dart`) works for the
/// web admin `SessionController` and the mobile/monitor
/// `PairedSessionController` alike, without depending on either directly.
abstract class AuthSessionBinding {
  /// The current access token, or `null` when signed out/unpaired.
  String? get accessToken;

  /// Refreshes the access token, returning the new token, or `null` on
  /// failure. Implementations should single-flight concurrent calls.
  Future<String?> refreshAccessToken();
}
