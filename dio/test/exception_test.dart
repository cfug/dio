import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:dio/io.dart';

void main() {
  test('catch DioError', () async {
    dynamic error;

    try {
      await Dio().get('https://does.not.exist');
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    expect(error is DioError, isTrue);
  });

  test('catch DioError as Exception', () async {
    dynamic error;

    try {
      await Dio().get('https://does.not.exist');
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    expect(error is DioError, isTrue);
  });

  test('catch sslerror: hostname mismatch', () async {
    dynamic error;

    try {
      await Dio().get('https://wrong.host.badssl.com/');
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is DioError, isTrue);
  });

  test('allow badssl', () async {
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
  }, testOn: "!browser");
}
