import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:test/test.dart';

class MockRequestInterceptorHandler extends RequestInterceptorHandler {
  String cookies = '';
  @override
  void next(RequestOptions requestOptions) {
    final c = requestOptions.headers[HttpHeaders.cookieHeader];
    expect(c == expectResult, true);
    super.next(requestOptions);
  }
}

class MockResponseInterceptorHandler extends ResponseInterceptorHandler {}

const expectResult = 'foo=bar; a=c; d=e; e=f';

void main() {
  test('testing merge cookies', () async {
    const List<String> mockFirstRequestCookies = [
      "foo=bar; Path=/",
      "a=c; Path=/"
    ];
    const exampleUrl = 'https://example.com';
    const String mockSecondRequestCookies = 'd=e;e=f';
    final cookieJar = CookieJar();
    final cookieManager = CookieManager(cookieJar);
    final mockRequestInterceptorHandler = MockRequestInterceptorHandler();
    final mockResponseInterceptorHandler = MockResponseInterceptorHandler();
    final firstRequestOptions =
        RequestOptions(baseUrl: exampleUrl, headers: {});

    final mockResponse = Response(
        requestOptions: firstRequestOptions,
        headers: Headers.fromMap(
          {HttpHeaders.setCookieHeader: mockFirstRequestCookies},
        ));
    cookieManager.onResponse(mockResponse, mockResponseInterceptorHandler);
    final options = RequestOptions(baseUrl: exampleUrl, headers: {
      HttpHeaders.cookieHeader: mockSecondRequestCookies,
    });

    cookieManager.onRequest(options, mockRequestInterceptorHandler);
  });
}
