import 'dart:convert';

import 'package:dio/dio.dart';

void main() async {
  const URL_NOT_FIND = 'https://wendux.github.io/xxxxx/';
  const URL_NOT_FIND_1 = URL_NOT_FIND + '1';
  const URL_NOT_FIND_2 = URL_NOT_FIND + '2';
  const URL_NOT_FIND_3 = URL_NOT_FIND + '3';
  var dio = Dio();
  dio.options.baseUrl = 'http://httpbin.org/';
  dio.interceptors.add(InterceptorsWrapper(
    onResponse: (response, handler) {
      response.data = json.decode(response.data['data']);
      handler.next(response);
    },
    onError: (DioError e, handler) {
      if (e.response != null) {
        switch (e.response!.requestOptions.path) {
          case URL_NOT_FIND:
            return handler.next(e);
          case URL_NOT_FIND_1:
            handler.resolve(
              Response(
                requestOptions: e.requestOptions,
                data: 'fake data',
              ),
            );
            break;
          case URL_NOT_FIND_2:
            handler.resolve(
              Response(
                requestOptions: e.requestOptions,
                data: 'fake data',
              ),
            );
            break;
          case URL_NOT_FIND_3:
            handler.next(
              e..error = 'custom error info [${e.response?.statusCode}]',
            );
            break;
        }
      } else {
        handler.next(e);
      }
    },
  ));

  Response response;
  response = await dio.post('/post', data: {'a': 5});
  print(response.headers);
  assert(response.data['a'] == 5);
  try {
    await dio.get(URL_NOT_FIND);
  } on DioError catch (e) {
    assert(e.response!.statusCode == 404);
  }
  response = await dio.get(URL_NOT_FIND + '1');
  assert(response.data == 'fake data');
  response = await dio.get(URL_NOT_FIND + '2');
  assert(response.data == 'fake data');
  try {
    await dio.get(URL_NOT_FIND + '3');
  } on DioError catch (e) {
    assert(e.message == 'custom error info [404]');
  }
}
