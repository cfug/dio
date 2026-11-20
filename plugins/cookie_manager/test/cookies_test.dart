@TestOn('vm')
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:test/test.dart';

class _TestRequestInterceptorHandler extends RequestInterceptorHandler {
  final Completer<RequestOptions> _result = Completer();

  Future<RequestOptions> get result => _result.future;

  @override
  void next(RequestOptions requestOptions) {
    _result.complete(requestOptions);
  }

  @override
  void reject(
    DioException error, [
    bool callFollowingErrorInterceptor = false,
  ]) {
    _result.completeError(error, error.stackTrace);
  }
}

class MockResponseInterceptorHandler extends ResponseInterceptorHandler {}

Future<void> expectRequestCookies(
  CookieManager cookieManager,
  RequestOptions options,
  String? expected,
) async {
  final handler = _TestRequestInterceptorHandler();
  await cookieManager.onRequest(options, handler);
  final result = await handler.result;
  expect(result, same(options));
  expect(options.headers[HttpHeaders.cookieHeader], expected);
}

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

class _MockNextErrorInterceptorHandler extends ErrorInterceptorHandler {
  _MockNextErrorInterceptorHandler(this.onNext);

  final void Function() onNext;

  @override
  void next(DioException error) {
    onNext();
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
    final options = RequestOptions(
      baseUrl: exampleUrl,
      headers: {
        HttpHeaders.cookieHeader: mockSecondRequestCookies,
      },
    );
    await expectRequestCookies(cookieManager, options, expectResult);
  });

  group('reusing request options', () {
    const exampleUrl = 'https://example.com/api/endpoint';

    test('does not append the cookie jar values again through Dio.fetch',
        () async {
      final cookieJar = CookieJar();
      await cookieJar.saveFromResponse(
        Uri.parse(exampleUrl),
        [
          Cookie('session', 'root')..path = '/',
          Cookie('session', 'api')..path = '/api',
        ],
      );
      final cookieManager = CookieManager(cookieJar);
      final adapter = _CookieRecordingAdapter();
      final dio = Dio()
        ..httpClientAdapter = adapter
        ..interceptors.add(cookieManager);
      addTearDown(dio.close);
      final options = RequestOptions(
        baseUrl: exampleUrl,
        responseType: ResponseType.plain,
      );

      await dio.fetch(options);
      await dio.fetch(options);
      await dio.fetch(options);

      expect(
        adapter.cookieHeaders,
        everyElement(
          equals(
            'session=api; session=root',
          ),
        ),
      );
      expect(adapter.cookieHeaders, hasLength(3));
      expect(adapter.requestOptions, everyElement(same(options)));
    });

    test('preserves a same-name cookie supplied by the caller', () async {
      final cookieJar = CookieJar();
      await cookieJar.saveFromResponse(
        Uri.parse(exampleUrl),
        [Cookie('session', 'saved')..path = '/'],
      );
      final cookieManager = CookieManager(cookieJar);
      final options = RequestOptions(
        baseUrl: exampleUrl,
        headers: {HttpHeaders.cookieHeader: 'session=provided'},
      );

      await expectRequestCookies(
        cookieManager,
        options,
        'session=provided; session=saved',
      );
      await expectRequestCookies(
        cookieManager,
        options,
        'session=provided; session=saved',
      );
    });

    test('reloads saved cookies without retaining their old values', () async {
      final cookieJar = CookieJar();
      final uri = Uri.parse(exampleUrl);
      await cookieJar.saveFromResponse(
        uri,
        [Cookie('session', 'old')..path = '/'],
      );
      final cookieManager = CookieManager(cookieJar);
      final options = RequestOptions(
        baseUrl: exampleUrl,
        headers: {HttpHeaders.cookieHeader: 'provided=value'},
      );

      await expectRequestCookies(
        cookieManager,
        options,
        'provided=value; session=old',
      );
      await cookieJar.saveFromResponse(
        uri,
        [Cookie('session', 'new')..path = '/'],
      );
      await expectRequestCookies(
        cookieManager,
        options,
        'provided=value; session=new',
      );
      await cookieJar.deleteAll();
      await expectRequestCookies(cookieManager, options, 'provided=value');
    });

    test('uses a cookie header changed by the caller as the new input',
        () async {
      final cookieJar = CookieJar();
      await cookieJar.saveFromResponse(
        Uri.parse(exampleUrl),
        [Cookie('saved', 'value')..path = '/'],
      );
      final cookieManager = CookieManager(cookieJar);
      final options = RequestOptions(
        baseUrl: exampleUrl,
        headers: {HttpHeaders.cookieHeader: 'provided=first'},
      );

      await expectRequestCookies(
        cookieManager,
        options,
        'provided=first; saved=value',
      );
      options.headers[HttpHeaders.cookieHeader] = 'provided=changed';
      await expectRequestCookies(
        cookieManager,
        options,
        'provided=changed; saved=value',
      );
      await expectRequestCookies(
        cookieManager,
        options,
        'provided=changed; saved=value',
      );
    });

    test('does not retain saved cookies after the request origin changes',
        () async {
      final cookieJar = CookieJar();
      await cookieJar.saveFromResponse(
        Uri.parse(exampleUrl),
        [Cookie('session', 'saved')..path = '/'],
      );
      final cookieManager = CookieManager(cookieJar);
      final options = RequestOptions(
        baseUrl: exampleUrl,
        headers: {HttpHeaders.cookieHeader: 'provided=value'},
      );

      await expectRequestCookies(
        cookieManager,
        options,
        'provided=value; session=saved',
      );
      options.baseUrl = 'https://other.example.com';
      await expectRequestCookies(cookieManager, options, 'provided=value');
    });

    test('keeps state separate between request options', () async {
      final cookieJar = CookieJar();
      await cookieJar.saveFromResponse(
        Uri.parse(exampleUrl),
        [Cookie('saved', 'value')..path = '/'],
      );
      final cookieManager = CookieManager(cookieJar);
      final first = RequestOptions(
        baseUrl: exampleUrl,
        headers: {HttpHeaders.cookieHeader: 'provided=first'},
      );
      final second = RequestOptions(
        baseUrl: exampleUrl,
        headers: {HttpHeaders.cookieHeader: 'provided=second'},
      );

      await expectRequestCookies(
        cookieManager,
        first,
        'provided=first; saved=value',
      );
      await expectRequestCookies(
        cookieManager,
        second,
        'provided=second; saved=value',
      );
      await expectRequestCookies(
        cookieManager,
        first,
        'provided=first; saved=value',
      );
      await expectRequestCookies(
        cookieManager,
        second,
        'provided=second; saved=value',
      );
    });
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
      await expectRequestCookies(cookieManager, options, expectResult);
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

  group('ignoreInvalidCookies', () {
    const exampleUrl = 'https://example.com';

    // "Secure" is an invalid Set-Cookie value since it has no name=value pair,
    // which is the exact scenario from issue #2492.
    const invalidSetCookie = 'Secure';
    const validSetCookie = 'valid=cookie; path=/';

    test('throws by default when Set-Cookie header is invalid', () async {
      final cookieJar = CookieJar();
      final cookieManager = CookieManager(cookieJar);

      final requestOptions = RequestOptions(baseUrl: exampleUrl);
      final mockResponse = Response(
        requestOptions: requestOptions,
        headers: Headers.fromMap({
          HttpHeaders.setCookieHeader: [invalidSetCookie],
        }),
      );

      final handler = _MockRejectResponseInterceptorHandler(
        isA<DioException>()
            .having((e) => e.type, 'type', equals(DioExceptionType.unknown))
            .having(
              (e) => e.error,
              'error',
              isA<CookieManagerSaveException>(),
            ),
      );
      await cookieManager.onResponse(mockResponse, handler);
    });

    test('ignores invalid Set-Cookie header when enabled', () async {
      final cookieJar = CookieJar();
      final cookieManager = CookieManager(
        cookieJar,
        ignoreInvalidCookies: true,
      );

      final requestOptions = RequestOptions(baseUrl: exampleUrl);
      final mockResponse = Response(
        requestOptions: requestOptions,
        headers: Headers.fromMap({
          HttpHeaders.setCookieHeader: [invalidSetCookie],
        }),
      );

      final handler = MockResponseInterceptorHandler();
      await cookieManager.onResponse(mockResponse, handler);

      final savedCookies =
          await cookieJar.loadForRequest(Uri.parse(exampleUrl));
      expect(savedCookies, isEmpty);
    });

    test('preserves valid cookies alongside invalid ones when enabled',
        () async {
      final cookieJar = CookieJar();
      final cookieManager = CookieManager(
        cookieJar,
        ignoreInvalidCookies: true,
      );

      final requestOptions = RequestOptions(baseUrl: exampleUrl);
      final mockResponse = Response(
        requestOptions: requestOptions,
        headers: Headers.fromMap(
          {
            HttpHeaders.setCookieHeader: [validSetCookie, invalidSetCookie],
          },
        ),
      );

      final handler = MockResponseInterceptorHandler();
      await cookieManager.onResponse(mockResponse, handler);

      final savedCookies =
          await cookieJar.loadForRequest(Uri.parse(exampleUrl));
      expect(savedCookies.length, 1);
      expect(savedCookies.first.name, 'valid');
      expect(savedCookies.first.value, 'cookie');
    });

    test('ignores invalid Set-Cookie header in onError when enabled', () async {
      final cookieJar = CookieJar();
      final cookieManager = CookieManager(
        cookieJar,
        ignoreInvalidCookies: true,
      );

      final requestOptions = RequestOptions(baseUrl: exampleUrl);
      final mockResponse = Response(
        requestOptions: requestOptions,
        headers: Headers.fromMap(
          {
            HttpHeaders.setCookieHeader: [validSetCookie, invalidSetCookie],
          },
        ),
      );
      final error = DioException(
        requestOptions: requestOptions,
        response: mockResponse,
      );

      bool nextCalled = false;
      final handler = _MockNextErrorInterceptorHandler(() {
        nextCalled = true;
      });
      await cookieManager.onError(error, handler);

      expect(nextCalled, isTrue);
      final savedCookies =
          await cookieJar.loadForRequest(Uri.parse(exampleUrl));
      expect(savedCookies.length, 1);
      expect(savedCookies.first.name, 'valid');
    });
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

class _CookieRecordingAdapter implements HttpClientAdapter {
  final List<String?> cookieHeaders = [];
  final List<RequestOptions> requestOptions = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions.add(options);
    cookieHeaders.add(options.headers[HttpHeaders.cookieHeader] as String?);
    return ResponseBody.fromString('', HttpStatus.ok);
  }

  @override
  void close({bool force = false}) {}
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
