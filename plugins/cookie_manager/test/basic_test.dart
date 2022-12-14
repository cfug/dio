import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:test/test.dart';

void main() {
  test('cookie-jar', () async {
    final dio = Dio();
    final cookieJar = CookieJar();
    dio.interceptors
      ..add(CookieManager(cookieJar))
      ..add(LogInterceptor());
    await dio.get('https://pub.dev/');
    // Print cookies
    print(cookieJar.loadForRequest(Uri.parse('https://pub.dev/')));
    // second request with the cookie
    await dio.get('https://pub.dev/');
  });
}
