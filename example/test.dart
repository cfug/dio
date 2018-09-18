import 'dart:io';
import 'package:dio/dio.dart';



main() async {
  var dio = new Dio();
  dio.interceptor.response.onError=(DioError error){
    print(error);
    print(error.response.statusCode);
  };
  try {
    Response r = await dio.get("https://www.instagram.com");
    print(r.headers);
  }on DioError catch(e){
     print(e);
     print(e.response.statusCode);
  }
}
