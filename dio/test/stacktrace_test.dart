import 'package:dio/dio.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';

void main() async {
  group('useStackTraceChains', () {
    test('enabled', () async {
      final dio = Dio(BaseOptions(useStackTraceChains: true))
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = MockAdapter.mockBase;

      try {
        await dio.get('/foo');
      } catch (e, stackTrace) {
        expect(stackTrace, isA<Chain>());
        expect(stackTrace.toString(), contains('test/stacktrace_test.dart'));
      }
    });

    test('disabled', () async {
      final dio = Dio(BaseOptions())
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = MockAdapter.mockBase;
      try {
        await dio.get('/foo');
      } catch (e, stackTrace) {
        expect(stackTrace, isNot(isA<Chain>()));
        expect(stackTrace.toString(),
            isNot(contains('test/stacktrace_test.dart')));
      }
    });
  });
}
