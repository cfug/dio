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
  Response response;
  try {
    response=await dio.get(url1, cancelToken: token);
    print(response);
  }catch (e){
    if (CancelToken.isCancel(e)) {
      print('$url1: $e');
    }
  }

  /**
   * 由于dart-lang #34586 bug所致，下面链式调用方式会抛出异常，目前的解决方法是使用await和try/catch
   * 的方式来调用。
   * 相关issue:
   *  https://github.com/dart-lang/sdk/issues/35426
   *  https://github.com/dart-lang/sdk/issues/34586
   **/
//  dio.get(url1, cancelToken: token)
//      .then((response) => print('${response.request.path}: succeed!'))
//      .catchError((DioError e) {
//    if (CancelToken.isCancel(e)) {
//      print('$url1: $e');
//    }
//  });

//  dio.get(url2, cancelToken: token)
//      .then((response) => print('${response.request.path}: succeed!'))
//      .catchError((DioError e) {
//    if (CancelToken.isCancel(e)) {
//      print('$url2: $e');
//    }
//  });
//
//  dio.get(url3, cancelToken: token)
//      .then((response) => print('${response.request.path}: succeed!'))
//      .catchError((DioError e) {
//    if (CancelToken.isCancel(e)) {
//      print('$url3: $e');
//    }
//  });

}
