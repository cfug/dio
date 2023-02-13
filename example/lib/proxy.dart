import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void main() async {
  final dio = Dio();
  dio.options
    ..headers['user-agent'] = 'xxx'
    ..contentType = 'text';
  // dio.options.connectTimeout = 2000;
  // More about HttpClient proxy topic please refer to Dart SDK doc.
  dio.httpClientAdapter = IOHttpClientAdapter()
    ..onHttpClientCreate = (HttpClient client) {
      client.findProxy = (uri) {
        //proxy all request to localhost:8888
        return 'PROXY localhost:8888';
      };
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

  Response<String> response;
  response = await dio.get('https://www.baidu.com');
  print(response.statusCode);
  response = await dio.get('https://www.baidu.com');
  print(response.statusCode);
}
