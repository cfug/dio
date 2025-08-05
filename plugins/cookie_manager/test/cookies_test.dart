@TestOn('vm')
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:test/test.dart';

class MockRequestInterceptorHandler extends RequestInterceptorHandler {
  MockRequestInterceptorHandler(this.expectResult);

  final String expectResult;

  @override
  void next(RequestOptions requestOptions) {
    final c = requestOptions.headers[HttpHeaders.cookieHeader];
    expect(c == expectResult, true);
    super.next(requestOptions);
  }
}

class MockResponseInterceptorHandler extends ResponseInterceptorHandler {}

class _MockRejectRequestInterceptorHandler extends RequestInterceptorHandler {
  _MockRejectRequestInterceptorHandler(this.matcher);

  final Matcher matcher;

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    expect(error, matcher);
  }
}

class _MockRejectResponseInterceptorHandler extends ResponseInterceptorHandler {
  _MockRejectResponseInterceptorHandler(this.matcher);

  final Matcher matcher;

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    expect(error, matcher);
  }
}

class _MockRejectErrorInterceptorHandler extends ErrorInterceptorHandler {
  _MockRejectErrorInterceptorHandler(this.matcher);

  final Matcher matcher;

  @override
  void next(DioException error) {
    expect(error, matcher);
  }
}

class _OverrideCookieManager extends CookieManager {
  _OverrideCookieManager(super.cookieJar);

  @override
  Future<String> loadCookies(RequestOptions options) async {
    await Future.microtask(() {});
    throw 'unexpected load';
  }

  @override
  Future<void> saveCookies(Response response) async {
    await Future.microtask(() {});
    throw 'unexpected save';
  }
}

void main() {
  test('testing merge cookies', () async {
    const List<String> mockFirstRequestCookies = [
      'foo=bar; Path=/',
      'a=c; Path=/',
    ];
    const exampleUrl = 'https://example.com';
    const String mockSecondRequestCookies = 'd=e;e=f';

    final expectResult = 'd=e; e=f; foo=bar; a=c';

    final cookieJar = CookieJar();
    final cookieManager = CookieManager(cookieJar);

    // Saving mock cookies.
    final firstRequestOptions = RequestOptions(baseUrl: exampleUrl);
    final mockResponse = Response(
      requestOptions: firstRequestOptions,
      headers: Headers.fromMap(
        {HttpHeaders.setCookieHeader: mockFirstRequestCookies},
      ),
    );
    final mockResponseInterceptorHandler = MockResponseInterceptorHandler();
    await cookieManager.onResponse(
      mockResponse,
      mockResponseInterceptorHandler,
    );

    // Verify mock cookies.
    final mockRequestInterceptorHandler =
        MockRequestInterceptorHandler(expectResult);
    final options = RequestOptions(
      baseUrl: exampleUrl,
      headers: {
        HttpHeaders.cookieHeader: mockSecondRequestCookies,
      },
    );
    await cookieManager.onRequest(
      options,
      mockRequestInterceptorHandler,
    );
  });

  group('Set-Cookie', () {
    test('can be parsed correctly', () async {
      const List<String> mockResponseCookies = [
        'key=value; expires=Sun, 19 Feb 3000 00:42:14 GMT; path=/; HttpOnly; secure; SameSite=Lax',
        'key1=value1; expires=Sun, 19 Feb 3000 01:43:15 GMT; path=/; HttpOnly; secure; SameSite=Lax, '
            'key2=value2; expires=Sat, 20 May 3000 00:43:15 GMT; path=/; HttpOnly; secure; SameSite=Lax',
      ];
      const exampleUrl = 'https://example.com';

      final expectResult = 'key=value; key1=value1; key2=value2';

      final cookieJar = CookieJar();
      final cookieManager = CookieManager(cookieJar);

      // Saving mock cookies.
      final requestOptions = RequestOptions(baseUrl: exampleUrl);
      final mockResponse = Response(
        requestOptions: requestOptions,
        headers: Headers.fromMap(
          {HttpHeaders.setCookieHeader: mockResponseCookies},
        ),
      );
      final mockResponseInterceptorHandler = MockResponseInterceptorHandler();
      await cookieManager.onResponse(
        mockResponse,
        mockResponseInterceptorHandler,
      );

      // Verify mock cookies.
      final options = RequestOptions(baseUrl: exampleUrl);
      final mockRequestInterceptorHandler =
          MockRequestInterceptorHandler(expectResult);
      await cookieManager.onRequest(
        options,
        mockRequestInterceptorHandler,
      );
    });

    test('can be saved to the location', () async {
      final cookieJar = CookieJar();
      final dio = Dio()
        ..httpClientAdapter = _RedirectAdapter()
        ..interceptors.add(CookieManager(cookieJar))
        ..options.followRedirects = false
        ..options.validateStatus =
            (status) => status != null && status >= 200 && status < 400;
      await Future.wait(
        ['/redirection', '/redirection1', '/redirection2', '/redirection3'].map(
          (url) async {
            final response1 = await dio.get(url);
            expect(response1.realUri.path, url);
            final cookies1 = await cookieJar.loadForRequest(response1.realUri);
            expect(cookies1.length, 3);
            final location1 = response1.realUri
                .resolve(response1.headers.value(HttpHeaders.locationHeader)!)
                .toString();
            final response2 = await dio.get(location1);
            expect(response2.realUri.toString(), location1);
            final cookies2 = await cookieJar.loadForRequest(response2.realUri);
            expect(cookies2.length, 3);
            expect(
              response2.requestOptions.headers[HttpHeaders.cookieHeader],
              'key=value; key1=value1; key2=value2',
            );
          },
        ),
      );
    });
  });

  group('Empty cookies', () {
    test('not produced by default', () async {
      final dio = Dio();
      dio.interceptors.add(CookieManager(CookieJar()));
      final response = await dio.get('http://www.gstatic.com/generate_204');
      expect(response.requestOptions.headers[HttpHeaders.cookieHeader], null);
    });

    test('can be parsed', () async {
      final dio = Dio();
      dio.interceptors
        ..add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              // Write an empty cookie header.
              options.headers[HttpHeaders.cookieHeader] = '';
              handler.next(options);
            },
          ),
        )
        ..add(CookieManager(CookieJar()));
      final response = await dio.get('http://www.gstatic.com/generate_204');
      expect(response.requestOptions.headers[HttpHeaders.cookieHeader], null);
    });
  });

  test('cookies replacement', () async {
    final cookies = [
      Cookie('foo', 'bar')..path = '/',
      Cookie('a', 'c')..path = '/',
    ];
    final previousCookies = [
      Cookie('foo', 'oldbar'),
      Cookie('d', 'e'),
      Cookie('e', 'f'),
    ];
    final newCookies = CookieManager.getCookies(
      [
        ...previousCookies,
        ...cookies,
      ],
    );
    expect(newCookies, 'foo=oldbar; d=e; e=f; foo=bar; a=c');
  });

  test('RFC6265 5.4 #2 sorting', () async {
    // To test cookies with longer paths are listed before
    // cookies with shorter paths.
    final cookies = [
      Cookie('a', 'k'),
      Cookie('a', 'b')..path = '/',
      Cookie('c', 'd')..path = '/foo',
      Cookie('e', 'f')..path = '/foo/bar',
      Cookie('g', 'h')..path = '/foo/bar/baz',
      Cookie('i', 'j'),
    ];
    final newCookies = CookieManager.getCookies(cookies);
    expect(newCookies, 'a=k; i=j; g=h; e=f; c=d; a=b');
  });

  test('throws as expected', () async {
    final cookieManager = _OverrideCookieManager(CookieJar());

    final loadExceptionMatcher = isA<DioException>()
        .having((e) => e.type, 'type', equals(DioExceptionType.unknown))
        .having(
          (e) => e.error,
          'error',
          isA<CookieManagerLoadException>()
              .having((e) => e.error, 'error', 'unexpected load'),
        );

    final saveExceptionMatcher = isA<DioException>()
        .having((e) => e.type, 'type', equals(DioExceptionType.unknown))
        .having(
          (e) => e.error,
          'error',
          isA<CookieManagerSaveException>()
              .having((e) => e.error, 'error', 'unexpected save'),
        );

    final mockRequestInterceptorHandler = _MockRejectRequestInterceptorHandler(
      loadExceptionMatcher,
    );
    final options = RequestOptions();
    await cookieManager.onRequest(
      options,
      mockRequestInterceptorHandler,
    );

    final mockResponseInterceptorHandler =
        _MockRejectResponseInterceptorHandler(saveExceptionMatcher);
    final requestOptions = RequestOptions();
    final response = Response(requestOptions: requestOptions);
    await cookieManager.onResponse(
      response,
      mockResponseInterceptorHandler,
    );

    final mockErrorInterceptorHandler =
        _MockRejectErrorInterceptorHandler(saveExceptionMatcher);
    final error =
        DioException(requestOptions: requestOptions, response: response);
    await cookieManager.onError(error, mockErrorInterceptorHandler);
  });
}

class _RedirectAdapter implements HttpClientAdapter {
  final HttpClientAdapter _adapter = IOHttpClientAdapter();

  static const List<String> _setCookieHeaders = [
    'key=value; expires=Sun, 19 Feb 3000 00:42:14 GMT; path=/; HttpOnly; secure; SameSite=Lax, '
        'key1=value1; expires=Sun, 19 Feb 3000 01:43:15 GMT; path=/; HttpOnly; secure; SameSite=Lax, '
        'key2=value2; expires=Sat, 20 May 3000 00:43:15 GMT; path=/; HttpOnly; secure; SameSite=Lax',
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Uri uri = options.uri;
    final int statusCode = HttpStatus.found;
    switch (uri.path) {
      case '/redirection':
        return ResponseBody.fromString(
          '',
          statusCode,
          headers: {
            HttpHeaders.locationHeader: [
              uri.replace(path: '/destination').toString(),
            ],
            HttpHeaders.setCookieHeader: _setCookieHeaders,
          },
        );
      case '/redirection1':
        return ResponseBody.fromString(
          '',
          statusCode,
          headers: {
            HttpHeaders.locationHeader: ['/destination'],
            HttpHeaders.setCookieHeader: _setCookieHeaders,
          },
        );
      case '/redirection2':
        return ResponseBody.fromString(
          '',
          statusCode,
          headers: {
            HttpHeaders.locationHeader: ['destination?param1=true'],
            HttpHeaders.setCookieHeader: _setCookieHeaders,
          },
        );
      case '/redirection3':
        return ResponseBody.fromString(
          '',
          statusCode,
          headers: {
            HttpHeaders.locationHeader: ['www.google.com/test-path'],
            HttpHeaders.setCookieHeader: _setCookieHeaders,
          },
        );
      default:
        return ResponseBody.fromString('', HttpStatus.ok);
    }
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}
