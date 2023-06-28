import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  //  dio instance to request token
  final tokenDio = Dio();
  String? csrfToken;
  dio.options.baseUrl = 'https://seunghwanlytest.mocklab.io/';
  tokenDio.options = dio.options;
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        print('send request：path:${options.path}，baseURL:${options.baseUrl}');

        if (csrfToken == null) {
          print('no token，request token firstly...');

          final result = await tokenDio.get('/token');

          if (result.statusCode != null && result.statusCode! ~/ 100 == 2) {
            /// assume `token` is in response body
            final body = jsonDecode(result.data) as Map<String, dynamic>?;

            if (body != null && body.containsKey('data')) {
              options.headers['csrfToken'] = csrfToken = body['data']['token'];
              print('request token succeed, value: $csrfToken');
              print(
                'continue to perform request：path:${options.path}，baseURL:${options.path}',
              );
              return handler.next(options);
            }
          }

          return handler.reject(
            DioException(requestOptions: result.requestOptions),
            true,
          );
        }

        options.headers['csrfToken'] = csrfToken;
        return handler.next(options);
      },
      onError: (error, handler) async {
        /// Assume 401 stands for token expired
        if (error.response?.statusCode == 401) {
          print('the token has expired, need to receive new token');
          final options = error.response!.requestOptions;

          /// assume receiving the token has no errors
          /// to check `null-safety` and error handling
          /// please check inside the [onRequest] closure
          final tokenResult = await tokenDio.get('/token');

          /// update [csrfToken]
          /// assume `token` is in response body
          final body = jsonDecode(tokenResult.data) as Map<String, dynamic>?;
          options.headers['csrfToken'] = csrfToken = body!['data']['token'];

          if (options.headers['csrfToken'] != null) {
            print('the token has been updated');

            /// since the api has no state, force to pass the 401 error
            /// by adding query parameter
            final originResult = await dio.fetch(options..path += '&pass=true');
            if (originResult.statusCode != null &&
                originResult.statusCode! ~/ 100 == 2) {
              return handler.resolve(originResult);
            }
          }
          print('the token has not been updated');
          return handler.reject(
            DioException(requestOptions: options),
          );
        }
        return handler.next(error);
      },
    ),
  );

  FutureOr<void> onResult(d) {
    print('request ok!');
  }

  /// assume `/test?tag=2` path occurs the authorization error (401)
  /// and token to be updated
  await dio.get('/test?tag=1').then(onResult);
  await dio.get('/test?tag=2').then(onResult);
  await dio.get('/test?tag=3').then(onResult);
}
