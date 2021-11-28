import 'dart:async';

import 'package:dio/dio.dart';

void main() async {
  var dio = Dio();
  //  dio instance to request token
  var tokenDio = Dio();
  String? csrfToken;
  dio.options.baseUrl = 'http://www.dtworkroom.com/doris/1/2.0.0/';
  tokenDio.options = dio.options;
  dio.interceptors.add(QueuedInterceptorsWrapper(
    onRequest: (options, handler) {
      print('send request：path:${options.path}，baseURL:${options.baseUrl}');
      if (csrfToken == null) {
        print('no token，request token firstly...');
        tokenDio.get('/token').then((d) {
          options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
          print('request token succeed, value: ' + d.data['data']['token']);
          print(
              'continue to perform request：path:${options.path}，baseURL:${options.path}');
          handler.next(options);
        }).catchError((error, stackTrace) {
          handler.reject(error, true);
        });
      } else {
        options.headers['csrfToken'] = csrfToken;
        return handler.next(options);
      }
    },
    onError: (error, handler) {
      //print(error);
      // Assume 401 stands for token expired
      if (error.response?.statusCode == 401) {
        var options = error.response!.requestOptions;
        // If the token has been updated, repeat directly.
        if (csrfToken != options.headers['csrfToken']) {
          options.headers['csrfToken'] = csrfToken;
          //repeat
          dio.fetch(options).then(
            (r) => handler.resolve(r),
            onError: (e) {
              handler.reject(e);
            },
          );
          return;
        }
        tokenDio.get('/token').then((d) {
          //update csrfToken
          options.headers['csrfToken'] = csrfToken = d.data['data']['token'];
        }).then((e) {
          //repeat
          dio.fetch(options).then(
            (r) => handler.resolve(r),
            onError: (e) {
              handler.reject(e);
            },
          );
        });
        return;
      }
      return handler.next(error);
    },
  ));

  FutureOr<void> _onResult(d) {
    print('request ok!');
  }

  await Future.wait([
    dio.get('/test?tag=1').then(_onResult),
    dio.get('/test?tag=2').then(_onResult),
    dio.get('/test?tag=3').then(_onResult)
  ]);
}
