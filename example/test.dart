import 'package:dio/dio.dart';

void getHttp() async {
  var dio = Dio();
  dio.interceptors.add(LogInterceptor(responseBody: true));
  //dio.options.baseUrl = "http://httpbin.org";
  dio.options.baseUrl = "http://localhost:3000";
  dio.options.receiveDataWhenStatusError=false;
  try {
    await Future.wait([
      dio.get("/get", queryParameters: {"id": 1}),
      dio.get("/get", queryParameters: {"id": 2})
    ]);
  } catch (e) {
    print(e);
  }
}

main() async {
  await getHttp();
//  var t = await MultipartFile.fromBytes([5]);
//  print(t);
}
