@TestOn('vm')
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:dio/io.dart';

void main() {
  // NOTE: Run test.sh to download the currrent certs to the file below.
  final trustedCertUrl = 'https://sha256.badssl.com/';
  final untrustedCertUrl = 'https://wrong.host.badssl.com/';

  // OpenSSL output like: SHA256 Fingerprint=EE:5C:E1:DF:A7:A4...
  // All badssl.com hosts have the same cert, they just have TLS
  // setting or other differences (like host name) that make them bad.
  final lines = File('test/_pinning.txt').readAsLinesSync();
  final fingerprint =
      lines.first.split('=').last.toLowerCase().replaceAll(':', '');

  test('pinning: trusted host allowed with no approver', () async {
    await Dio().get(trustedCertUrl);
  });

  test('pinning: untrusted host rejected with no approver', () async {
    dynamic error;

    try {
      var dio = Dio();
      await dio.get(untrustedCertUrl);
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test('pinning: every certificate tested and rejected', () async {
    dynamic error;

    try {
      var dio = Dio();
      (dio.httpClientAdapter as DefaultHttpClientAdapter).validateCertificate =
          (certificate, host, port) => false;
      await dio.get(trustedCertUrl);
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test('pinning: trusted certificate tested and allowed', () async {
    var dio = Dio();
    // badCertificateCallback never called for trusted certificate
    (dio.httpClientAdapter as DefaultHttpClientAdapter).validateCertificate =
        (cert, host, port) =>
            fingerprint == sha256.convert(cert!.der).toString();
    final response = await dio.get(trustedCertUrl,
        options: Options(validateStatus: (status) => true));
    expect(response, isNotNull);
  });

  test('pinning: untrusted certificate tested and allowed', () async {
    var dio = Dio();
    // badCertificateCallback must allow the untrusted certificate through
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      return client..badCertificateCallback = (cert, host, port) => true;
    };
    (dio.httpClientAdapter as DefaultHttpClientAdapter).validateCertificate =
        (cert, host, port) =>
            fingerprint == sha256.convert(cert!.der).toString();
    final response = await dio.get(untrustedCertUrl,
        options: Options(validateStatus: (status) => true));
    expect(response, isNotNull);
  });

  test('pinning: untrusted certificate rejected before validateCertificate',
      () async {
    dynamic error;

    try {
      var dio = Dio();
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (_) => HttpClient(context: SecurityContext(withTrustedRoots: false));
      (dio.httpClientAdapter as DefaultHttpClientAdapter).validateCertificate =
          (cert, host, port) => fail('Should not be evaluated');
      await dio.get(untrustedCertUrl,
          options: Options(validateStatus: (status) => true));
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test('bad pinning: badCertCallback does not use leaf certificate', () async {
    dynamic error;

    try {
      var dio = Dio();
      (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
          (HttpClient client) {
        final effectiveClient =
            HttpClient(context: SecurityContext(withTrustedRoots: false));
        // Comparison fails because fingerprint is for leaf cert, but
        // this cert is from Let's Encrypt.
        effectiveClient.badCertificateCallback =
            (X509Certificate cert, String host, int port) =>
                fingerprint == sha256.convert(cert.der).toString();
        return effectiveClient;
      };
      await dio.get(trustedCertUrl,
          options: Options(validateStatus: (status) => true));
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test('pinning: 2 requests == 2 approvals', () async {
    int approvalCount = 0;
    var dio = Dio();
    // badCertificateCallback never called for trusted certificate
    (dio.httpClientAdapter as DefaultHttpClientAdapter).validateCertificate =
        (cert, host, port) {
      approvalCount++;
      return fingerprint == sha256.convert(cert!.der).toString();
    };
    Response response = await dio.get(trustedCertUrl,
        options: Options(validateStatus: (status) => true));
    expect(response.data, isNotNull);
    response = await dio.get(trustedCertUrl,
        options: Options(validateStatus: (status) => true));
    expect(response.data, isNotNull);
    expect(approvalCount, 2);
  });
}
