import 'package:dio/dio.dart';
import '../../tests.dart';

typedef TestSuiteFunction = void Function(
  Dio Function(String baseUrl) create,
);

const _tests = [
  basicTests,
  cancellationTests,
  corsTests,
  downloadTests,
  headerTests,
  httpMethodTests,
  parameterTests,
  redirectTests,
  statusCodeTests,
  timeoutTests,
  uploadTests,
  urlEncodedTests,
];

void dioAdapterTestSuite(
  Dio Function(String baseUrl) create, {
  List<TestSuiteFunction> tests = _tests,
}) =>
    tests.forEach((test) => test(create));
