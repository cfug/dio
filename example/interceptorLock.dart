import 'dart:async';

import 'package:dio/dio.dart';

main() async {
  Dio dio = new Dio();
  // new dio instance to request token
  Dio tokenDio = new Dio();
  String csrfToken;
  dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  tokenDio.options = dio.options;
  dio.interceptor.request.onSend = (Options options) {
    print('send request：path:${options.path}，baseURL:${options.baseUrl}');
    if (csrfToken == null) {
      print("no token，request token firstly...");
      //lock the dio.
      dio.lock();
      return tokenDio.get("/token").then((d) {
        options.headers["csrfToken"] = csrfToken = d.data['data']['token'];
        print("request token succeed, value: " + d.data['data']['token']);
        print('continue to perform request：path:${options.path}，baseURL:${options.path}');
        return options;
      }).whenComplete(() => dio.unlock()); // unlock the dio
    } else {
      options.headers["csrfToken"] = csrfToken;
      return options;
    }
  };
  _onResult(d){
    print("request ok!");
   }
  await Future.wait([
    dio.get("/test?tag=1").then(_onResult),
    dio.get("/test?tag=2").then(_onResult),
    dio.get("/test?tag=3").then(_onResult)
  ]);
}