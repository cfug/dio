import 'dart:io';
import 'package:dio/dio.dart';



main() async {
  var dio = new Dio(Options(
    baseUrl: "https://www.baidu.com"
  ));
 Response response= await dio.get("http://www.w3school.com.cn/tags/html_ref_httpmethods.asp");
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
