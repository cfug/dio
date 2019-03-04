import 'dart:io';

import 'package:dio/dio.dart';

main() async {
  BaseOptions options =
      BaseOptions(baseUrl: "https://github.com", method: "GET");
  Dio dio = Dio(options);
  dio.interceptors.add(InterceptorsWrapper(onRequest: (r) {
    //return dio.reject("xxxx");
  }, onError: (e) {
    print(e);
  }));
  Response response;
  dio.options.contentType=ContentType.parse("application/x-www-form-urlencoded");
  dio.options.baseUrl="http://erp.xlianba.com/";
  response = await dio.post("Api.php?c=Approval&a=post",
      data: {"company_id": '27', "user_id": '204', "page": '0'},
  );
  print(response);
//  response = await dio
//      .request<Map>("http://www.dtworkroom.com/doris/1/2.0.0/test")
//      .catchError((e) => print(e.request));
//  print(response.data.runtimeType);
}
