import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void main() async {
  final dio = Dio();
  dio.options
    ..headers['user-agent'] = 'xxx'
    ..contentType = 'text';
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      client.findProxy = (uri) {
        // Proxy all request to localhost:8888.
        // Be aware, the proxy should went through you running device,
        // not the host platform.
        return 'PROXY localhost:8888';
      };
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    },
  );

  Response<String> response;
  response = await dio.get('https://www.baidu.com');
  print(response.statusCode);
  response = await dio.get('https://www.baidu.com');
  print(response.statusCode);
}
