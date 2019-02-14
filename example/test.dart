import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

main() async {
  var dio = new Dio();
  dio.interceptors.add(LogInterceptor(responseBody: true));
  dio.get(
    "http://www.dtworkroom.com/doris/1/2.0.0/test",
    queryParameters: {"kk": "tt"},
    options: Options(
      headers: {HttpHeaders.acceptEncodingHeader: "*"},
      responseType: ResponseType.bytes,
    ),
    onReceiveProgress: (received, total) {
      if (total != -1) {
        print((received / total * 100).toStringAsFixed(0) + "%");
      }
    },
  ).catchError(print);
}
