import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:dio/adapter.dart';

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
    expect(error is Exception, isTrue);
  });

  test('catch DioError as Exception', () async {
    dynamic error;

    try {
      await Dio().get('https://does.not.exist');
      fail('did not throw');
    } on Exception catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    expect(error is Exception, isTrue);
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
    expect(error is Exception, isTrue);
  });

  test('allow badssl', () async {
    var dio = Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    };
    var response = await dio.get('https://wrong.host.badssl.com/');
    expect(response.statusCode, 200);
    response = await dio.get('https://expired.badssl.com/');
    expect(response.statusCode, 200);
    response = await dio.get('https://self-signed.badssl.com/');
    expect(response.statusCode, 200);
  }, testOn: "!browser");
}
