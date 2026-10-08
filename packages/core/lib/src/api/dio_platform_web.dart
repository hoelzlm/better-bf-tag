import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Enables sending/receiving cookies (the `bftag_refresh` session cookie)
/// on web, where XHR/fetch otherwise omits credentials cross-origin.
void configureForPlatform(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter()..withCredentials = true;
}
