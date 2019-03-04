import 'package:dio/dio.dart';

main() async {
  BaseOptions options = BaseOptions( baseUrl: "https://github.com", method: "GET");
  Dio dio = Dio(options);
  Response<String> r = await dio.request<String>("/flutterchina/dio/issues/196");
  print(r);
}
