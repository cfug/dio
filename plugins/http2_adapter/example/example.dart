import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

void main() async {
  final dio = Dio()
    ..options.baseUrl = 'https://pub.dev'
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: Duration(seconds: 10),
      ),
    );

  Response<String> response;

  response = await dio.get('/?xx=6');
  print(response.data?.length);
  print(response.redirects.length);
  print(response.data);
}
