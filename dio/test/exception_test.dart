@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  /// https://github.com/cfug/diox/issues/66
  test('Ensure DioException is an Exception', () {
    final error = DioException(requestOptions: RequestOptions());
    expect(error, isA<Exception>());
  });

  test('catch DioException', () async {
    DioException? error;
    try {
      await Dio().get('https://does.not.exist');
      fail('did not throw');
    } on DioException catch (e) {
      error = e;
    }
    expect(error, isNotNull);
  });

  test('catch DioException as Exception', () async {
    DioException? error;
    try {
      await Dio().get('https://does.not.exist');
      fail('did not throw');
    } on DioException catch (e) {
      error = e;
    }
    expect(error, isNotNull);
  });

  test('catch DioException: hostname mismatch', () async {
    DioException? error;
    try {
      await Dio().get('https://wrong.host.badssl.com/');
      fail('did not throw');
    } on DioException catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error.error, isA<HandshakeException>());
    expect((error.error as HandshakeException).osError, isNotNull);
    expect(
      ((error.error as HandshakeException).osError as OSError).message,
      contains('Hostname mismatch'),
    );
  });

  test(
    'allow badssl',
    () async {
      final dio = Dio();
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          return HttpClient()
            ..badCertificateCallback = (cert, host, port) => true;
        },
      );
      Response response = await dio.get('https://wrong.host.badssl.com/');
      expect(response.statusCode, 200);
      response = await dio.get('https://expired.badssl.com/');
      expect(response.statusCode, 200);
      response = await dio.get('https://self-signed.badssl.com/');
      expect(response.statusCode, 200);
    },
    testOn: '!browser',
  );
}
