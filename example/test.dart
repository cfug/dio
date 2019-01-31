import 'package:dio/dio.dart';


main() async {
  var dio = new Dio();
  dio.interceptors.add(LogInterceptor(responseBody: false));
  dio.get("https://github.com/wendux/tt?aa=b",queryParameters: {"kk":"tt"}).catchError(print);
}
