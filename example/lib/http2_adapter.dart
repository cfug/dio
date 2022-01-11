import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

void main() async {
  var dio = Dio()
    ..options.baseUrl = 'https://pub.dev/packages/dio'
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: 10000),
    );

  final response = await dio.get('/changelog');
  for (final e in response.redirects) {
    print('redirect: ${e.statusCode} ${e.location}');
  }
  print(response.data);
}
