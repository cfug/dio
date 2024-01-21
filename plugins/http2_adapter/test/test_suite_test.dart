@TestOn('vm')
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:dio_test/tests.dart';
import 'package:test/test.dart';

void main() {
  Dio create() => Dio(BaseOptions(baseUrl: 'https://httpbun.com/'))
    ..httpClientAdapter = Http2Adapter(ConnectionManager());

  headerTests(create);
  httpMethodTests(create);
  redirectTests(create);
  parameterTests(create);
  statusCodeTests(create);
}
