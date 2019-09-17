import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

main() async {
  var dio = Dio()
    ..options.baseUrl = "https://www.ustc.edu.cn/"
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: 10000,
        /// Ignore bad certificate
        onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
      ),
    );

  Response<String> response;
  response = await dio.get("/?xx=6");
  print(response.data);
  response = await dio.get("2062/list.htm");
  print(response.data);
}
