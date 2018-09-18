import 'dart:async';
import 'package:dio/dio.dart';

main() async {
  var dio = new Dio();
  // Token can be shared with different requests.
  CancelToken token = new CancelToken();
  // In one minute, we cancel!
  new Timer(new Duration(milliseconds: 1000), () {
    token.cancel("cancelled");
  });

  // The follow three requests with the same token.
  var url1="https://accounts.google.com";
  var url2="https://www.facebook.com";
  var url3="https://www.baidu.com";
  dio.get(url1, cancelToken: token)
      .then((response) => print('${response.request.path}: succeed!'))
      .catchError((DioError e) {
    if (CancelToken.isCancel(e)) {
      print('$url1: $e');
    }
  });

  dio.get(url2, cancelToken: token)
      .then((response) => print('${response.request.path}: succeed!'))
      .catchError((DioError e) {
    if (CancelToken.isCancel(e)) {
      print('$url2: $e');
    }
  });

  dio.get(url3, cancelToken: token)
      .then((response) => print('${response.request.path}: succeed!'))
      .catchError((DioError e) {
    if (CancelToken.isCancel(e)) {
      print('$url3: $e');
    }
  });

}