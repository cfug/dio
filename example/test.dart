import 'dart:io';
import 'package:dio/dio.dart';


main() async {
  var dio = new Dio();
  dio.options.baseUrl = "http://www.dtworkroom.com/doris/1/2.0.0/";
  dio.options.connectTimeout = 5000; //5s
  dio.options.receiveTimeout = 5000;
  dio.options.headers = {
    'user-agent': 'dio',
    'common-header': 'xx'
  };

  var u = new Uri(scheme: "https", host: "www.baidu.com", queryParameters: {
    "a": "你好",
    "b": "hi",
  });




  print(u.toString());

  // Add request interceptor
  dio.interceptor.request.onSend = (Options options) async {
    // return ds.resolve(new Response(data:"xxx"));
    // return ds.reject(new DioError(message: "eh"));
    return options;
  };


}
