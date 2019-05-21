import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';

main() async {
  var dio = new Dio();
  var cookieJar=CookieJar();
  dio.interceptors
    ..add(CookieManager(cookieJar))
    ..add(LogInterceptor(responseBody: false));
  await dio.get("https://baidu.com/");
  // Print cookies
  print(cookieJar.loadForRequest(Uri.parse("https://baidu.com/")));
  // second request with the cookie
  await dio.get("https://baidu.com/");
}
