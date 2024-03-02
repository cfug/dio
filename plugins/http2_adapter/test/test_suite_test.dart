import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:dio_test/tests.dart';

void main() {
  dioAdapterTestSuite(
    () => Dio(BaseOptions(baseUrl: 'https://httpbun.com/'))
      ..httpClientAdapter = Http2Adapter(ConnectionManager()),
  );
}
