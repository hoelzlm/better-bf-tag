import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session.dart';
import 'dio_provider.dart';

/// Adds `Authorization: Bearer *** to outgoing requests when signed in,
/// and transparently refreshes+retries once on a 401 from a non-auth path.
///
/// Session-agnostic: reads/refreshes the token via
/// [authSessionBindingProvider] (defaults to the web admin
/// `SessionController`; mobile/monitor apps override that provider with a
/// `PairedSessionController`-backed binding in their own `ProviderScope`).
///
/// Takes a [Ref] rather than the controller directly so it can be
/// constructed before the controller/provider graph exists, avoiding a
/// provider initialization cycle with [dioProvider].
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  bool _isAuthPath(String path) => path.contains('/auth/');

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (!_isAuthPath(options.path)) {
      final token = _ref.read(authSessionBindingProvider).accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestOptions = err.requestOptions;
    final statusCode = err.response?.statusCode;
    if (statusCode == 401 &&
        !_isAuthPath(requestOptions.path) &&
        requestOptions.extra['bftagRefreshRetried'] != true) {
      _retryWithRefresh(requestOptions, err, handler);
      return;
    }
    handler.next(err);
  }

  Future<void> _retryWithRefresh(
    RequestOptions requestOptions,
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final newToken =
        await _ref.read(authSessionBindingProvider).refreshAccessToken();
    if (newToken == null) {
      handler.next(err);
      return;
    }
    try {
      requestOptions.extra['bftagRefreshRetried'] = true;
      requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final dio = _ref.read(dioProvider);
      final response = await dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } catch (retryError) {
      if (retryError is DioException) {
        handler.next(retryError);
      } else {
        handler.next(err);
      }
    }
  }
}
