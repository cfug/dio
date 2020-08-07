import 'package:dio/dio.dart';

void getHttp() async {
  var dio = Dio();
  dio.interceptors.add(LogInterceptor(responseBody: true));
  dio.options.baseUrl = "http://httpbin.org";
  dio.options.headers=   {
  'Authorization': 'Bearer '
  };
  //dio.options.baseUrl = "http://localhost:3000";
  var response=await dio.post("/post",data:null,
      options: Options(contentType: Headers.jsonContentType, headers: {"Content-Type": "application/json"})
  );
  print(response);
}

main() async {
  await getHttp();

//  var response = await Dio().get("http://flutterchina.club");
//  print(response.isRedirect);

//  var t = await MultipartFile.fromBytes([5]);
//  print(t);
}
