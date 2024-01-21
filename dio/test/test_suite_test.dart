import 'package:dio/dio.dart';
import 'package:dio_test/tests.dart';

void main() {
  Dio create() => Dio(BaseOptions(baseUrl: 'https://httpbun.com/'));

  headerTests(create);
  httpMethodTests(create);
  redirectTests(create);
  parameterTests(create);
  statusCodeTests(create);
}
