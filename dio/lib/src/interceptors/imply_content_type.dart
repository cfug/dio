import 'dart:developer' as dev;

import '../dio_mixin.dart';
import '../form_data.dart';
import '../headers.dart';
import '../options.dart';

// For the web platform, an inline `bool.fromEnvironment` translates to
// `core.bool.fromEnvironment` instead of correctly being replaced by the
// constant value found in the environment at build time.
//
// See https://github.com/flutter/flutter/issues/51186.
const _kReleaseMode = bool.fromEnvironment('dart.vm.product');

/// {@template dio.interceptors.ImplyContentTypeInterceptor}
/// The default `content-type` for requests will be implied by the
/// [ImplyContentTypeInterceptor] according to the type of the request payload.
/// The interceptor can be removed by
/// [Interceptors.removeImplyContentTypeInterceptor].
/// {@endtemplate}
class ImplyContentTypeInterceptor extends Interceptor {
  const ImplyContentTypeInterceptor();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final Object? data = options.data;
    if (data != null && options.contentType == null) {
      final String? contentType;
      if (data is FormData) {
        contentType = Headers.multipartFormDataContentType;
      } else if (data is List<Map> || data is Map || data is String) {
        contentType = Headers.jsonContentType;
      } else {
        // Do not log in the release mode.
        if (!_kReleaseMode) {
          dev.log(
            '${data.runtimeType} cannot be used '
            'to imply a default content-type, '
            'please set a proper content-type in the request.',
            level: 900,
            name: '🔔 Dio',
            stackTrace: StackTrace.current,
          );
        }
        contentType = null;
      }
      options.contentType = contentType;
    }
    handler.next(options);
  }
}
