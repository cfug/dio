import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';
import 'utils.dart';

void main() {
  test('send with an invalid URL', () async {
    await expectLater(
      Dio().get('http://http.invalid'),
      throwsA(
        allOf([
          isA<DioException>(),
          (DioException e) => e.type == (DioExceptionType.connectionError),
          if (!isWeb) (DioException e) => e.error is SocketException,
        ]),
      ),
    );
  });

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

  test('status error', () async {
    final dio = Dio()
      ..options.baseUrl = EchoAdapter.mockBase
      ..httpClientAdapter = EchoAdapter();
    await expectLater(
      dio.get('/401'),
      throwsA(
        (e) =>
            e is DioException &&
            e.type == DioExceptionType.badResponse &&
            e.response!.statusCode == 401,
      ),
    );
    final r = await dio.get(
      '/401',
      options: Options(validateStatus: (status) => true),
    );
    expect(r.statusCode, 401);
  });

  test('post map', () async {
    final dio = Dio()
      ..options.baseUrl = EchoAdapter.mockBase
      ..httpClientAdapter = EchoAdapter();

    final response = await dio.post(
      '/post',
      data: {'a': 1, 'b': 2, 'c': 3},
    );
    expect(response.data, '{"a":1,"b":2,"c":3}');
    expect(response.statusCode, 200);
  });
}
