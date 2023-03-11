@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  /// https://github.com/cfug/diox/issues/66
  test('Ensure DioError is an Exception', () {
    final error = DioError(requestOptions: RequestOptions());
    expect(error, isA<Exception>());
  });

  test('catch DioError', () async {
    DioError? error;
    try {
      await Dio().get('https://does.not.exist');
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
  });

  test('catch DioError as Exception', () async {
    DioError? error;
    try {
      await Dio().get('https://does.not.exist');
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
  });

  test('catch DioError: hostname mismatch', () async {
    DioError? error;
    try {
      await Dio().get('https://wrong.host.badssl.com/');
      fail('did not throw');
    } on DioError catch (e) {
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
      dio.httpClientAdapter = IOHttpClientAdapter()
        ..onHttpClientCreate = (client) {
          return client..badCertificateCallback = (cert, host, port) => true;
        };
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
