import 'package:dio/dio.dart';
import 'package:dio_test/tests.dart';

void main() {
  dioAdapterTestSuite(
    () => Dio(BaseOptions(baseUrl: 'https://httpbun.com/')),
  );
}
