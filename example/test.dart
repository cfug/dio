import 'dart:io';
import 'package:dio/dio.dart';

class MyInter extends Interceptor {
  final tag;

  MyInter(this.tag);

  @override
  onRequest(Options options) {
    //return DioError(message: "niha");
    //return Response(data: "xx");
    //return Future<Options>.delayed(Duration(seconds: 2), () => options);
  }

  @override
  onResponse(Response e) {
    //return DioError(message: "niha");
    //print(e);
  }

  @override
  onError(DioError e) {
    print("");
    print(e);
  }
}

main() async {
  var dio = new Dio();
  dio.options.baseUrl = "https://baidu.com";
  dio.options.connectTimeout = 5000; //5s
  dio.options.receiveTimeout = 5000;
  dio.options.headers = {'user-agent': 'dio', 'common-header': 'xx'};
  dio.interceptors..add(new MyInter("1"))..add(LogInterceptor(responseBody: false));
  await dio.get("/");
  await dio.get("/");
}
