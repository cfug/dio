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
      onError: (DioException err, handler) {
        if (err.response != null) {
          switch (err.response!.requestOptions.path) {
            case urlNotFound:
              return handler.next(err);
            case urlNotFound1:
              handler.resolve(
                Response(
                  requestOptions: err.requestOptions,
                  data: 'fake data',
                ),
              );
              break;
            case urlNotFound2:
              handler.resolve(
                Response(
                  requestOptions: err.requestOptions,
                  data: 'fake data',
                ),
              );
              break;
            case urlNotFound3:
              handler.next(
                err.copyWith(
                  error: 'custom error info [${err.response!.statusCode}]',
                ),
              );
              break;
          }
        } else {
          handler.next(err);
        }
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
