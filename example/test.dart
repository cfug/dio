import 'dart:io';
import 'package:dio/dio.dart';



main() async {
//  String s=Transformer.urlEncodeMap({
//    'a': 1,
//    'b': 2,
//    "c":{
//      "a":5,
//      "b":6
//    }
//  });

  var dio = new Dio(Options(
    baseUrl: "https://www.baidu.com"
  ));
 Response response= await dio.get("https://www.toutiao.com/stream/widget/local_weather/data/?city=%E4%B8%8A%E6%B5%B7");
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
