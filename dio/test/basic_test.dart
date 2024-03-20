import 'dart:async';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';

void main() {
  test('cancellation', () async {
    final dio = Dio()
      ..httpClientAdapter = MockAdapter()
      ..options.baseUrl = MockAdapter.mockBase;
    final token = CancelToken();
    Future.delayed(const Duration(milliseconds: 10), () {
      token.cancel('cancelled');
      dio.httpClientAdapter.close(force: true);
    });

    await expectLater(
      dio.get('/test-timeout', cancelToken: token),
      throwsA((e) => e is DioException && CancelToken.isCancel(e)),
    );
  });
}
