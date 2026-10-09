import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dio_provider.dart';

/// Access to the device's push token (ADR 0018): `PUT
/// /me/device/push-token`.
///
/// An interface (rather than a concrete class) so tests can substitute a
/// fake without constructing a real [AuthApi]/`Dio`.
abstract class PushTokenRepository {
  /// `PUT /me/device/push-token`. Sends `{token}` with the body; the
  /// backend atomically moves [token] off any other device (ADR 0018).
  Future<void> updatePushToken(String token);
}

/// [PushTokenRepository] backed by the generated [AuthApi].
class ApiPushTokenRepository implements PushTokenRepository {
  const ApiPushTokenRepository(this._api);

  final AuthApi _api;

  @override
  Future<void> updatePushToken(String token) async {
    await _api.updatePushToken(
      updatePushTokenRequest: UpdatePushTokenRequest(
        (b) => b..token = token,
      ),
    );
  }
}

final pushTokenRepositoryProvider = Provider<PushTokenRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiPushTokenRepository(apiClient.getAuthApi());
});
