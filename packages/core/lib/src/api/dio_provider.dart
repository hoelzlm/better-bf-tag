import 'package:bftag_api_client/bftag_api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_config.dart';
import 'dio_platform_stub.dart'
    if (dart.library.js_interop) 'dio_platform_web.dart'
    if (dart.library.html) 'dio_platform_web.dart' as platform;

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(apiConfigProvider);
  final dio = Dio(BaseOptions(baseUrl: config.baseUrl));
  platform.configureForPlatform(dio);
  return dio;
});

final apiClientProvider = Provider<BftagApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return BftagApiClient(dio: dio);
});
