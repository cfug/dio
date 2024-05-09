import 'dart:io';

import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://httpbin.org/',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      // 5s
      headers: {
        HttpHeaders.userAgentHeader: 'dio',
        'api': '1.0.0',
      },
      contentType: Headers.jsonContentType,
      // Transform the response data to a String encoded with UTF8.
      // The default value is [ResponseType.JSON].
      responseType: ResponseType.plain,
    ),
  );

  Response response;

  response = await dio.get('/get');
  print(response.data);

  final responseMap = await dio.get(
    '/get',
    // Transform response data to Json Map
    options: Options(responseType: ResponseType.json),
  );
  print(responseMap.data);
  response = await dio.post(
    '/post',
    data: {
      'id': 8,
      'info': {'name': 'wendux', 'age': 25},
    },
    // Send data with "application/x-www-form-urlencoded" format
    options: Options(
      contentType: Headers.formUrlEncodedContentType,
    ),
  );
  print(response.data);

  response = await dio.fetch(
    RequestOptions(path: 'https://baidu.com/'),
  );
  print(response.data);
}
