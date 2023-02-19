@TestOn('chrome')

import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('with credentials', () async {
    // run ../example/server/server.dart before doing the following test.
    final browserAdapter = BrowserHttpClientAdapter();
    browserAdapter.withCredentials = true;
    final options = BaseOptions(
      baseUrl: 'http://127.0.0.1:2384',
    );
    final dio = DioForBrowser(options);
    dio.httpClientAdapter = browserAdapter;

    // Request to get the cookies from the server.
    await dio.get(
      '/cors/getCookie',
      queryParameters: {'value': 'Dio'},
    );
    // Request again to verify if the cookies are obtained and have been pass-through.
    final response = await dio.get(
      '/cors/checkCookie',
      queryParameters: {'value': 'Dio'},
    );

    expect(response.statusCode, 200);
  });

}
