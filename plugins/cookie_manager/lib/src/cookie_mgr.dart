import 'dart:async';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

import 'exception.dart';

const _kIsWebInterop = bool.fromEnvironment('dart.library.js_interop');
const _kIsWebUtil = bool.fromEnvironment('dart.library.js_util');
const _kIsWeb = _kIsWebInterop || _kIsWebUtil || identical(0, 0.0);

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

class _CookieHeaderState {
  const _CookieHeaderState(this.source, this.merged);

  final String? source;
  final String merged;
}

/// Cookie manager for HTTP requests based on [CookieJar].
///
/// Register this after interceptors that may change [RequestOptions.uri] or
/// the Cookie request header. Cookies are selected from the URI and reused
/// request options are recognized only while the header exactly matches this
/// manager's previous output.
class CookieManager extends Interceptor {
  CookieManager(
    this.cookieJar, {
    this.ignoreInvalidCookies = false,
  }) : assert(!_kIsWeb, "Don't use the manager in Web environments.");

  /// The cookie jar used to load and save cookies.
  ///
  /// See also:
  /// * [CookieJar]
  /// * [PersistCookieJar]
  final CookieJar cookieJar;

  /// Whether to ignore invalid cookies during parsing or saving.
  bool ignoreInvalidCookies;

  final Expando<_CookieHeaderState> _cookieHeaderStates = Expando();

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
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final cookies = await loadCookies(options);
      options.headers[HttpHeaders.cookieHeader] =
          cookies.isNotEmpty ? cookies : null;
      handler.next(options);
    } catch (e, s) {
      final exception = DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: CookieManagerLoadException(error: e, stackTrace: s),
        message: 'Failed to load cookies for the request.',
      );
      handler.reject(exception, true);
    }
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    try {
      await saveCookies(response);
      handler.next(response);
    } catch (e, s) {
      final exception = DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.unknown,
        error: CookieManagerSaveException(
          response: response,
          error: e,
          stackTrace: s,
          dioException: null,
        ),
        stackTrace: s,
      );
      handler.reject(exception, true);
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    if (response == null) {
      handler.next(err);
      return;
    }

    try {
      await saveCookies(response);
      handler.next(err);
    } catch (e, s) {
      final exception = DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.unknown,
        error: CookieManagerSaveException(
          response: response,
          error: e,
          stackTrace: s,
          dioException: err,
        ),
        stackTrace: s,
      );
      handler.next(exception);
    }
  }

  Cookie? _fromSetCookieValue(String value) {
    try {
      return Cookie.fromSetCookieValue(value);
    } on HttpException catch (_) {
      if (ignoreInvalidCookies) {
        return null;
      }
      rethrow;
    }
  }

  /// Load cookies in cookie string for the request.
  ///
  /// State is scoped to the identity of [options]. When the same instance is
  /// reused, its original Cookie header is restored only if the current header
  /// exactly matches the previous result of this method. Any other header is
  /// treated as a new source. Incrementally modifying a generated header after
  /// this manager can therefore cause saved cookies to be merged again.
  Future<String> loadCookies(RequestOptions options) async {
    final savedCookies = await cookieJar.loadForRequest(options.uri);
    final previousCookies =
        options.headers[HttpHeaders.cookieHeader] as String?;
    final previousState = _cookieHeaderStates[options];
    // Rebuild a header that still exactly matches this manager's last output.
    // Any other header becomes the source for the next merge.
    final sourceCookies =
        previousState != null && previousState.merged == previousCookies
            ? previousState.source
            : previousCookies;
    final cookies = getCookies([
      ...?sourceCookies
          ?.split(';')
          .where((e) => e.isNotEmpty)
          .map((c) => _fromSetCookieValue(c))
          .whereType<Cookie>(), // Use .nonNulls when the minimum SDK is 3.0.
      ...savedCookies,
    ]);
    _cookieHeaderStates[options] = _CookieHeaderState(sourceCookies, cookies);
    return cookies;
  }

  /// Save cookies from the response including redirected requests.
  Future<void> saveCookies(Response response) async {
    final setCookies = response.headers[HttpHeaders.setCookieHeader];
    if (setCookies == null || setCookies.isEmpty) {
      return;
    }

    final List<Cookie> cookies = setCookies
        .map((str) => str.split(_setCookieReg))
        .expand((cookie) => cookie)
        .where((cookie) => cookie.isNotEmpty)
        .map((str) => _fromSetCookieValue(str))
        .whereType<Cookie>() // Use .nonNulls when the minimum SDK is 3.0.
        .toList();

    // Saving cookies for the original site.
    // Spec: https://www.rfc-editor.org/rfc/rfc7231#section-7.1.2.
    final originalUri = response.requestOptions.uri;
    final realUri = originalUri.resolveUri(response.realUri);
    await cookieJar.saveFromResponse(realUri, cookies);

    // Handle `Set-Cookie` when `followRedirects` is false
    // and the response returns a redirect status code.
    final statusCode = response.statusCode ?? 0;
    // 300 indicates the URL has multiple choices, so here we use list literal.
    final locations = response.headers[HttpHeaders.locationHeader] ?? [];
    // We don't want to explicitly consider recursive redirections
    // cookie handling here, because when `followRedirects` is set to false,
    // users will be available to handle cookies themselves.
    final redirected = statusCode >= 300 && statusCode < 400;
    if (redirected && locations.isNotEmpty) {
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
