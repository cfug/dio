import 'package:dio/dio.dart';
import 'package:dio_test/tests.dart';

void main() {
  dioAdapterTestSuite(
    (baseUrl) => Dio(BaseOptions(baseUrl: baseUrl)),
  );
}
