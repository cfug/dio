import 'package:dio/dio.dart';
import 'package:dio_test/tests.dart';

typedef TestSuiteFunction = void Function(
  Dio Function(String baseUrl) create,
);

const _tests = [
  basicTests,
  cancellationTests,
  corsTests,
  downloadStreamTests,
  headerTests,
  httpMethodTests,
  parameterTests,
  redirectTests,
  statusCodeTests,
  timeoutTests,
];

void dioAdapterTestSuite(
  Dio Function(String baseUrl) create, {
  List<TestSuiteFunction> tests = _tests,
}) =>
    tests.forEach((test) => test(create));
