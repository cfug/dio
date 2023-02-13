import 'dart:async';

import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  dio.interceptors.add(LogInterceptor());
  // Token can be shared with different requests.
  final token = CancelToken();
  // In one minute, we cancel!
  Timer(Duration(milliseconds: 500), () {
    token.cancel('cancelled');
  });

  // The follow three requests with the same token.
  final url1 = 'https://pub.dev';
  final url2 = 'https://dart.dev';
  final url3 = 'https://flutter.dev';

  await Future.wait([
    dio
        .get(url1, cancelToken: token)
        .then((response) => print('${response.requestOptions.path}: succeed!'))
        .catchError(
      (e) {
        if (CancelToken.isCancel(e)) {
          print('$url1: $e');
        }
      },
    ),
    dio
        .get(url2, cancelToken: token)
        .then((response) => print('${response.requestOptions.path}: succeed!'))
        .catchError((e) {
      if (CancelToken.isCancel(e)) {
        print('$url2: $e');
      }
    }),
    dio
        .get(url3, cancelToken: token)
        .then((response) => print('${response.requestOptions.path}: succeed!'))
        .catchError((e) {
      if (CancelToken.isCancel(e)) {
        print('$url3: $e');
      }
      print(e);
    })
  ]);
}
