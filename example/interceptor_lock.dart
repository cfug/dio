import 'dart:async';

import 'package:dio/dio.dart';

main() async {
  Dio dio = Dio();
  //  dio instance to request token
  Dio tokenDio = Dio();
  String csrfToken;
  dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  tokenDio.options = dio.options;
  dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options) {
    print('send request：path:${options.path}，baseURL:${options.baseUrl}');
    if (csrfToken == null) {
      print("no token，request token firstly...");
      dio.lock();
      //print(dio.interceptors.requestLock.locked);
      return tokenDio.get("/token").then((d) {
        options.headers["csrfToken"] = csrfToken = d.data['data']['token'];
        print("request token succeed, value: " + d.data['data']['token']);
        print(
            'continue to perform request：path:${options.path}，baseURL:${options.path}');
        return options;
      }).whenComplete(() => dio.unlock()); // unlock the dio
    } else {
      options.headers["csrfToken"] = csrfToken;
      return options;
    }
  }, onError: (DioError error) {
    //print(error);
    // Assume 401 stands for token expired
    if (error.response?.statusCode == 401) {
      RequestOptions options = error.response.request;
      // If the token has been updated, repeat directly.
      if (csrfToken != options.headers["csrfToken"]) {
        options.headers["csrfToken"] = csrfToken;
        //repeat
        return dio.request(options.path, options: options);
      }
      // update token and repeat
      // Lock to block the incoming request until the token updated
      dio.lock();
      dio.interceptors.responseLock.lock();
      dio.interceptors.errorLock.lock();
      return tokenDio.get("/token").then((d) {
        //update csrfToken
        options.headers["csrfToken"] = csrfToken = d.data['data']['token'];
      }).whenComplete(() {
        dio.unlock();
        dio.interceptors.responseLock.unlock();
        dio.interceptors.errorLock.unlock();
      }).then((e) {
        //repeat
        return dio.request(options.path, options: options);
      });
    }
    return error;
  }));

  _onResult(d) {
    print("request ok!");
  }

  await Future.wait([
    dio.get("/test?tag=1").then(_onResult),
    dio.get("/test?tag=2").then(_onResult),
    dio.get("/test?tag=3").then(_onResult)
  ]);
}
