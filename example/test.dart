import 'package:dio/dio.dart';

void getHttp() async {
  var dio=Dio();
  dio.interceptors.add(LogInterceptor());
  try {
    Response response = await dio.get("http://httpbin.org/");
    print(response.data);
  } catch (e) {
    print(e);
  }
}

main() async {
  await getHttp();
}
