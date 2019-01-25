import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class a {
  int i;
  void t() {}
}

class b implements a {
  @override
  int i;

  @override
  void t() {
    // TODO: implement t
  }
}



main() async {
  var dio = new Dio(Options(baseUrl: "https://www.baidu.com"));
  Response response = await dio.get(
      "https://www.toutiao.com/stream/widget/local_weather/data/?city=%E4%B8%8A%E6%B5%B7");
  print(response);
//  dio.interceptor.response.onError=(DioError error){
//    print(error);
//    print(error.response.statusCode);
//  };
//  try {
//    Response r = await dio.get("https://www.instagram.com");
//    print(r.headers);
//  }on DioError catch(e){
//     print(e);
//     print(e.response.statusCode);
//  }
}
