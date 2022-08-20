import 'dart:io';
import 'package:crypto/crypto.dart';
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

  test('catch sslerror: certificate not allowed', () async {
    dynamic error;

    try {
      var dio = Dio();
      (dio.httpClientAdapter as DefaultHttpClientAdapter).responseCertApprover =
          (certificate, host, port) => false;
      await dio.get('https://mozilla-intermediate.badssl.com/');
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  }, testOn: "!browser");

  test('pinning: certificate allowed', () async {
    // OpenSSL output like: SHA256 Fingerprint=EE:5C:E1:DF:A7:A4...
    final lines = File('test/_pinning.txt').readAsLinesSync();
    final fingerprint =
        lines.first.split('=').last.toLowerCase().replaceAll(':', '');

    var dio = Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).responseCertApprover =
        (cert, host, port) =>
            fingerprint == sha256.convert(cert!.der).toString();
    final response = await dio.get('https://mozilla-intermediate.badssl.com/',
        options: Options(validateStatus: (status) => true));
    expect(response, isNotNull);
  }, testOn: "!browser");

  test('bad pinning: badCertCallback does not use leaf certificate', () async {
    // OpenSSL output like: SHA256 Fingerprint=EE:5C:E1:DF:A7:A4...
    final lines = File('test/_pinning.txt').readAsLinesSync();
    final fingerprint =
        lines.first.split('=').last.toLowerCase().replaceAll(':', '');

    dynamic error;

    try {
      var dio = Dio();
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (HttpClient client) {
        final effectiveClient =
            HttpClient(context: SecurityContext(withTrustedRoots: false));
        effectiveClient.badCertificateCallback =
            (X509Certificate cert, String host, int port) =>
                fingerprint == sha256.convert(cert.der).toString();
        return effectiveClient;
      };
      await dio.get('https://mozilla-intermediate.badssl.com/',
          options: Options(validateStatus: (status) => true));
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  }, testOn: "!browser");

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
