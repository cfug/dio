import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

void main() {
  test('cookie-jar', () async {
    var dio = Dio();
    var cookieJar = CookieJar();
    dio.interceptors..add(CookieManager(cookieJar))..add(LogInterceptor());
    await dio.get("https://baidu.com/");
    // Print cookies
    print(cookieJar.loadForRequest(Uri.parse("https://baidu.com/")));
    // second request with the cookie
    await dio.get("https://baidu.com/");
  });
}
