import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

const _kIsWeb = bool.hasEnvironment('dart.library.js_util')
    ? bool.fromEnvironment('dart.library.js_util')
    : identical(0, 0.0);

/// - `(?<=)` is a positive lookbehind assertion that matches a comma (",")
/// only if it's preceded by a specific pattern. In this case, the lookbehind
/// assertion is empty, which means it matches any comma that's preceded by any character.
/// - `(,)` captures the comma as a group.
/// - `(?=[^;]+?=)` is a positive lookahead assertion that matches a comma only
/// if it's followed by a specific pattern. In this case, it matches any comma
/// that's followed by one or more characters that are not semicolons (";") and
/// then an equals sign ("="). This ensures that the comma is not part of a cookie
/// attribute like "expires=Sun, 19 Feb 3000 01:43:15 GMT", which could also contain commas.
final _setCookieReg = RegExp('(?<=)(,)(?=[^;]+?=)');

/// Cookie manager for HTTP requests based on [CookieJar].
class CookieManager extends Interceptor {
  const CookieManager(
    this.cookieJar,
  ) : assert(!_kIsWeb, "Don't use the manager in Web environments.");

  final CookieJar cookieJar;

  /// Merge cookies into a Cookie string.
  /// Cookies with longer paths are listed before cookies with shorter paths.
  static String getCookies(List<Cookie> cookies) {
    // Sort cookies by path (longer path first).
    cookies.sort((a, b) {
      if (a.path == null && b.path == null) {
        return 0;
      } else if (a.path == null) {
        return -1;
      } else if (b.path == null) {
        return 1;
      } else {
        return b.path!.length.compareTo(a.path!.length);
      }
    });
    return cookies.map((cookie) => '${cookie.name}=${cookie.value}').join('; ');
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    cookieJar.loadForRequest(options.uri).then((cookies) {
      final previousCookies =
          options.headers[HttpHeaders.cookieHeader] as String?;
      final newCookies = getCookies([
        ...?previousCookies
            ?.split(';')
            .where((e) => e.isNotEmpty)
            .map((c) => Cookie.fromSetCookieValue(c)),
        ...cookies,
      ]);
      options.headers[HttpHeaders.cookieHeader] =
          newCookies.isNotEmpty ? newCookies : null;
      handler.next(options);
    }).catchError((dynamic e, StackTrace s) {
      final err = DioException(
        requestOptions: options,
        error: e,
        stackTrace: s,
      );
      handler.reject(err, true);
    });
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _saveCookies(response).then((_) => handler.next(response)).catchError(
      (dynamic e, StackTrace s) {
        final err = DioException(
          requestOptions: response.requestOptions,
          error: e,
          stackTrace: s,
        );
        handler.reject(err, true);
      },
    );
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response != null) {
      _saveCookies(err.response!).then((_) => handler.next(err)).catchError(
        (dynamic e, StackTrace s) {
          final error = DioException(
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
    if (setCookies == null || setCookies.isEmpty) {
      return;
    }
    final List<Cookie> cookies = setCookies
        .map((str) => str.split(_setCookieReg))
        .expand((cookie) => cookie)
        .where((cookie) => cookie.isNotEmpty)
        .map((str) => Cookie.fromSetCookieValue(str))
        .toList();
    // Handle `Set-Cookie` when `followRedirects` is false
    // and the response returns a redirect status code.
    final statusCode = response.statusCode ?? 0;
    // 300 indicates the URL has multiple choices, so here we use list literal.
    final locations = response.headers[HttpHeaders.locationHeader] ?? [];
    // We don't want to explicitly consider recursive redirections
    // cookie handling here, because when `followRedirects` is set to false,
    // users will be available to handle cookies themselves.
    final isRedirectRequest = statusCode >= 300 && statusCode < 400;
    // Saving cookies for the original site.
    await cookieJar.saveFromResponse(response.realUri, cookies);
    if (isRedirectRequest && locations.isNotEmpty) {
      final originalUri = response.realUri;
      await Future.wait(
        locations.map(
          (location) => cookieJar.saveFromResponse(
            // Resolves the location based on the current Uri.
            originalUri.resolve(location),
            cookies,
          ),
        ),
      );
    }
  }
}
