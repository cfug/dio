import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';

void getHttp() async {
  var file=File("./example/log.txt");
  var sink=file.openWrite();
  try {
    var dio = Dio();
    dio.interceptors.add(LogInterceptor(logPrint: sink.writeln));
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.findProxy = (uri) {
        //proxy all request to localhost:8888
        return "PROXY localhost:8888";
      };
    };
    Response response = await dio.post(
      "http://httpbin.org/post",
      data: {"rows": 1, "page": 10},
    );
    //Response response = await dio.get("http://xxx.xxx");
    print(response);
  } catch (e) {
    print(e);
  }
  await sink.close();
}

main() async {
  await getHttp();
}
