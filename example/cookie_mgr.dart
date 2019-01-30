import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';


main() async {
  var dio = new Dio();
  dio.interceptors
    ..add(CookieManager(CookieJar()))
    ..add(LogInterceptor(responseBody: false));
  await dio.get("https://baidu.com/");
  // second request with the cookie
  await dio.get("https://baidu.com/");
}
