import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

const _kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

final setCookieReg = RegExp('(?<=)(,)(?=[^;]+?=)');

/// Cookie manager for HTTP requests based on [CookieJar].
class CookieManager extends Interceptor {
  const CookieManager(
    this.cookieJar,
  ) : assert(!_kIsWeb, "Don't use the manager in Web environments.");

  final CookieJar cookieJar;

  /// Merge cookies into a Cookie string.
  static String getCookies(List<Cookie> cookies) {
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    cookieJar.loadForRequest(options.uri).then((cookies) {
      options.headers[HttpHeaders.cookieHeader] = getCookies([
        ...cookies,
        ...?options.headers[HttpHeaders.cookieHeader]
            ?.split(';')
            .map((c) => Cookie.fromSetCookieValue(c)),
      ]);
      handler.next(options);
    }).catchError((dynamic e, StackTrace s) {
      final err = DioError(requestOptions: options, error: e, stackTrace: s);
      handler.reject(err, true);
    });
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _saveCookies(response).then((_) => handler.next(response)).catchError(
      (dynamic e, StackTrace s) {
        final err = DioError(
          requestOptions: response.requestOptions,
          error: e,
          stackTrace: s,
        );
        handler.reject(err, true);
      },
    );
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      _saveCookies(err.response!).then((_) => handler.next(err)).catchError(
        (dynamic e, StackTrace s) {
          final error = DioError(
            requestOptions: err.response!.requestOptions,
            error: e,
            stackTrace: s,
          );
          handler.next(error);
        },
      );
    } else {
      handler.next(err);
    }
  }

  Future<void> _saveCookies(Response response) async {
    final setCookies = response.headers[HttpHeaders.setCookieHeader];

    if (setCookies != null) {
      final cookies = setCookies
          .map((str) => str.split(setCookieReg))
          .expand((element) => element);
      await cookieJar.saveFromResponse(
        response.requestOptions.uri,
        cookies.map((str) => Cookie.fromSetCookieValue(str)).toList(),
      );
    }
  }
}
