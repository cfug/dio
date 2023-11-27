import 'dart:convert';

import 'package:dio/dio.dart';

void main() async {
  const urlNotFound = 'https://wendux.github.io/xxxxx/';
  const urlNotFound1 = '${urlNotFound}1';
  const urlNotFound2 = '${urlNotFound}2';
  const urlNotFound3 = '${urlNotFound}3';
  final dio = Dio();
  dio.options.baseUrl = 'https://httpbin.org/';
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        response.data = json.decode(response.data['data']);
        handler.next(response);
      },
      onError: (DioException error, ErrorInterceptorHandler handler) {
        final response = error.response;
        if (response != null) {
          switch (response.requestOptions.path) {
            case urlNotFound:
              return handler.next(error);
            case urlNotFound1:
              return handler.resolve(
                Response(
                  requestOptions: error.requestOptions,
                  data: 'fake data',
                ),
              );
            case urlNotFound2:
              return handler.resolve(
                Response(
                  requestOptions: error.requestOptions,
                  data: 'fake data',
                ),
              );
            case urlNotFound3:
              return handler.next(
                error.copyWith(
                  error: 'custom error info [${response.statusCode}]',
                ),
              );
          }
        }
        handler.next(error);
      },
    ),
  );

  Response response;
  response = await dio.post('/post', data: {'a': 5});
  print(response.headers);
  assert(response.data['a'] == 5);
  try {
    await dio.get(urlNotFound);
  } on DioException catch (e) {
    assert(e.response!.statusCode == 404);
  }
  response = await dio.get('${urlNotFound}1');
  assert(response.data == 'fake data');
  response = await dio.get('${urlNotFound}2');
  assert(response.data == 'fake data');
  try {
    await dio.get('${urlNotFound}3');
  } on DioException catch (e) {
    assert(e.message == 'custom error info [404]');
  }
}
