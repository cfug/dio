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

  test(
    'catch DioException: hostname mismatch',
    () async {
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
    },
    tags: ['tls'],
  );

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

  test('DioExceptionReadableStringBuilder', () {
    final requestOptions = RequestOptions(path: 'just/a/test', method: 'POST');
    final exception = DioException(
      requestOptions: requestOptions,
      response: Response(requestOptions: requestOptions),
      error: 'test',
      message: 'test message',
      stackTrace: StackTrace.current,
    );
    DioException.readableStringBuilder = (e) => 'Hey, Dio throws an exception: '
        '${e.requestOptions.path}, '
        '${e.requestOptions.method}, '
        '${e.type}, '
        '${e.error}, '
        '${e.stackTrace}, '
        '${e.message}';
    expect(
      exception.toString(),
      'Hey, Dio throws an exception: '
      'just/a/test, '
      'POST, '
      'DioExceptionType.unknown, '
      'test, '
      '${exception.stackTrace}, '
      'test message',
    );
    exception.stringBuilder = (e) => 'Locally override: ${e.message}';
    expect(exception.toString(), 'Locally override: test message');
  });
}
