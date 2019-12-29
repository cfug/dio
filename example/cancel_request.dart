import 'dart:async';
import 'package:dio/dio.dart';

main() async {
  var dio = Dio();
  dio.interceptors.add(LogInterceptor());
  // Token can be shared with different requests.
  CancelToken token = CancelToken();
  // In one minute, we cancel!
  Timer(Duration(milliseconds: 500), () {
    token.cancel("cancelled");
  });

  // The follow three requests with the same token.
  var url1 = "https://www.google.com";
  var url2 = "https://www.facebook.com";
  var url3 = "https://www.baidu.com";

  await Future.wait([
    dio
        .get(url1, cancelToken: token)
        .then((response) => print('${response.request.path}: succeed!'))
        .catchError(
      (e) {
        if (CancelToken.isCancel(e)) {
          print('$url1: $e');
        }
      },
    ),
    dio
        .get(url2, cancelToken: token)
        .then((response) => print('${response.request.path}: succeed!'))
        .catchError((e) {
      if (CancelToken.isCancel(e)) {
        print('$url2: $e');
      }
    }),
    dio
        .get(url3, cancelToken: token)
        .then((response) => print('${response.request.path}: succeed!'))
        .catchError((e) {
      if (CancelToken.isCancel(e)) {
        print('$url3: $e');
      }
      print(e);
    })
  ]);
}
