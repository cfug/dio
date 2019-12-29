import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

main() async {
  var dio = Dio();
  var cookieJar = CookieJar();
  dio.interceptors..add(LogInterceptor())..add(CookieManager(cookieJar));
  await dio.get("https://baidu.com/");
  // Print cookies
  print(cookieJar.loadForRequest(Uri.parse("https://baidu.com/")));
  // second request with the cookie
  await dio.get("https://baidu.com/");
}
