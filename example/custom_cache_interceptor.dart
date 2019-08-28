import 'dart:async';

import 'package:dio/dio.dart';

class CacheInterceptor extends Interceptor {
  CacheInterceptor();

  var _cache =  Map<Uri, Response>();

  @override
  FutureOr<dynamic> onRequest(RequestOptions options) {
    Response response = _cache[options.uri];
    if (options.extra["refresh"] == true) {
      print("${options.uri}: force refresh, ignore cache! \n");
      return options;
    } else if (response != null) {
      print("cache hit: ${options.uri} \n");
      return response;
    }
  }

  @override
  FutureOr<dynamic> onResponse(Response response) {
    _cache[response.request.uri] = response;
  }

  @override
  FutureOr<dynamic> onError(DioError e) {
    print('onError: $e');
  }
}

main() async {
  var dio =  Dio();
  dio.options.baseUrl = "https://baidu.com";
  dio.interceptors
    ..add(CacheInterceptor())
    ..add(LogInterceptor(requestHeader: false, responseHeader: false));

  await dio.get("/"); // second request
  await dio.get("/"); // Will hit cache
  // Force refresh
  await dio.get("/", options: Options(extra: {'refresh': true}));
}
