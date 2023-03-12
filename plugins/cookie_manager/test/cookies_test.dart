import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:test/test.dart';

class MockRequestInterceptorHandler extends RequestInterceptorHandler {
  final String expectResult;

  MockRequestInterceptorHandler(this.expectResult);

  @override
  void next(RequestOptions requestOptions) {
    final c = requestOptions.headers[HttpHeaders.cookieHeader];
    expect(c == expectResult, true);
    super.next(requestOptions);
  }
}

class MockResponseInterceptorHandler extends ResponseInterceptorHandler {}

void main() {
  test('testing merge cookies', () async {
    const List<String> mockFirstRequestCookies = [
      'foo=bar; Path=/',
      'a=c; Path=/'
    ];
    const exampleUrl = 'https://example.com';
    const String mockSecondRequestCookies = 'd=e;e=f';

    final expectResult = mockFirstRequestCookies
            .map((mock) => mock.replaceAll(' Path=/', ' '))
            .join() +
        mockSecondRequestCookies.split(';').join('; ');

    final cookieJar = CookieJar();
    final cookieManager = CookieManager(cookieJar);
    final mockRequestInterceptorHandler =
        MockRequestInterceptorHandler(expectResult);
    final mockResponseInterceptorHandler = MockResponseInterceptorHandler();
    final firstRequestOptions = RequestOptions(baseUrl: exampleUrl);

    final mockResponse = Response(
      requestOptions: firstRequestOptions,
      headers: Headers.fromMap(
        {HttpHeaders.setCookieHeader: mockFirstRequestCookies},
      ),
    );
    cookieManager.onResponse(mockResponse, mockResponseInterceptorHandler);
    final options = RequestOptions(
      baseUrl: exampleUrl,
      headers: {
        HttpHeaders.cookieHeader: mockSecondRequestCookies,
      },
    );

    cookieManager.onRequest(options, mockRequestInterceptorHandler);
  });
  test('testing set-cookies parsing', () async {
    const List<String> mockResponseCookies = [
      'key=value; expires=Sun, 19 Feb 3000 00:42:14 GMT; path=/; HttpOnly; secure; SameSite=Lax',
      'key1=value1; expires=Sun, 19 Feb 3000 01:43:15 GMT; path=/; HttpOnly; secure; SameSite=Lax, '
          'key2=value2; expires=Sat, 20 May 3000 00:43:15 GMT; path=/; HttpOnly; secure; SameSite=Lax',
    ];
    const exampleUrl = 'https://example.com';

    final expectResult = 'key=value; key1=value1; key2=value2';

    final cookieJar = CookieJar();
    final cookieManager = CookieManager(cookieJar);
    final mockRequestInterceptorHandler =
        MockRequestInterceptorHandler(expectResult);
    final mockResponseInterceptorHandler = MockResponseInterceptorHandler();
    final requestOptions = RequestOptions(baseUrl: exampleUrl);

    final mockResponse = Response(
      requestOptions: requestOptions,
      headers: Headers.fromMap(
        {HttpHeaders.setCookieHeader: mockResponseCookies},
      ),
    );
    cookieManager.onResponse(mockResponse, mockResponseInterceptorHandler);
    final options = RequestOptions(baseUrl: exampleUrl);

    cookieManager.onRequest(options, mockRequestInterceptorHandler);
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
}
