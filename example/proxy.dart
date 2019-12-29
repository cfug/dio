import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';

main() async {
  var dio = Dio();
  dio.options.headers["user-agent"] = "xxx";
  dio.options.contentType = "text";
  // dio.options.connectTimeout = 2000;
  // More about HttpClient proxy topic please refer to Dart SDK doc.
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      (HttpClient client) {
    client.findProxy = (uri) {
      //proxy all request to localhost:8888
      return "PROXY localhost:8888";
    };
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
  };
  var dir = Directory("./cookies");
  await dir.create();
  Response<String> response;
  //response= await dio.get("https://github.com/wendux/fly");
  response = await dio.get("https://www.baidu.com");
  print(response.statusCode);
  response = await dio.get("https://www.baidu.com");
  print(response.statusCode);
}
