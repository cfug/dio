import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;



main() async {
  var dio = new Dio();
  dio.interceptor.response.onError=(DioError error){
    print(error);
    print(error.response.statusCode);
  };
  try {
    Response r = await dio.get("http://capi.takeeasy.hk/order/list/1");
  }on DioError catch(e){
     print(e);
     print(e.response.statusCode);
  }

}
