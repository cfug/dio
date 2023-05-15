import 'dart:io';

import 'package:dio/dio.dart';

void main() async {
  final dio = Dio();
  dio.options
    ..baseUrl = 'https://httpbin.org/'
    ..connectTimeout = Duration(seconds: 5)
    ..receiveTimeout = Duration(seconds: 5)
    ..validateStatus = (int? status) {
      return status != null && status > 0;
    }
    ..headers = {
      HttpHeaders.userAgentHeader: 'dio',
      'common-header': 'xx',
    };

  // Or you can create dio instance and config it as follow:
  //  final dio = Dio(BaseOptions(
  //    baseUrl: "http://www.dtworkroom.com/doris/1/2.0.0/",
  //    connectTimeout: const Duration(seconds: 5),
  //    receiveTimeout: const Duration(seconds: 5),
  //    headers: {
  //      HttpHeaders.userAgentHeader: 'dio',
  //      'common-header': 'xx',
  //    },
  //  ));
  dio.interceptors
    ..add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // return handler.resolve( Response(data:"xxx"));
          // return handler.reject( DioException(message: "eh"));
          return handler.next(options);
        },
      ),
    )
    ..add(LogInterceptor(responseBody: false)); //Open log;

  Response response = await dio.get('https://pub.dev/');

  // Download a file
  response = await dio.download(
    'https://pub.dev/',
    './example/xx.html',
    queryParameters: {'a': 1},
    onReceiveProgress: (received, total) {
      if (total != -1) {
        print('$received,$total');
      }
    },
  );

  // Create a FormData
  final formData = FormData.fromMap({
    'age': 25,
    'file': await MultipartFile.fromFile(
      './example/upload.txt',
      filename: 'upload.txt',
    )
  });

  // Send FormData
  response = await dio.post('/test', data: formData);
  print(response);

  // post data with "application/x-www-form-urlencoded" format
  response = await dio.post(
    '/test',
    data: {
      'id': 8,
      'info': {
        'name': 'wendux',
        'age': 25,
      }
    },
    options: Options(
      contentType: Headers.formUrlEncodedContentType,
    ),
  );
  print(response.data);
}
