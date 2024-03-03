import 'package:dio/dio.dart';
import 'package:dio_test/tests.dart';

typedef TestSuiteFunction = void Function(
  Dio Function() create,
);

const _tests = [
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
  Dio Function() create, {
  List<TestSuiteFunction> tests = _tests,
}) =>
    tests.forEach((test) => test(create));
