import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

main() async {
  var dio = Dio()
    ..options.baseUrl = "https://google.com"
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: 10000),
    );

  Response<String> response;
  response = await dio.get("/?xx=6");
  response.redirects.forEach((e) {
    print("redirect: ${e.statusCode} ${e.location}");
  });
  print(response.data);
}
