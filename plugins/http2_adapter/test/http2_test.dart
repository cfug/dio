import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

void main() {
  // NOTE: Run test.sh to download the currrent certs to the file below.
  //
  // OpenSSL output like: SHA256 Fingerprint=EE:5C:E1:DF:A7:A4...
  // All badssl.com hosts have the same cert, they just have TLS
  // setting or other differences (like host name) that make them bad.
  final lines = File('test/_pinning_http2.txt').readAsLinesSync();
  final fingerprint =
      lines.first.split('=').last.toLowerCase().replaceAll(':', '');

  test('adds one to input values', () async {
    var dio = Dio()
      ..options.baseUrl = 'https://www.ustc.edu.cn/'
      ..interceptors.add(LogInterceptor())
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: Duration(milliseconds: 10),
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),
      );

    Response<String> response;
    response = await dio.get('?xx=6');
    assert(response.statusCode == 200);
    response = await dio.get(
      'nkjnjknjn.html',
      options: Options(validateStatus: (status) => true),
    );
    assert(response.statusCode == 404);
  });

  test('request with payload', () async {
    final dio = Dio()
      ..options.baseUrl = 'https://httpbin.org/'
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: Duration(milliseconds: 10),
      ));

    final res = await dio.post('post', data: 'TEST');
    expect(res.data.toString(), contains('TEST'));
  });

  test('pinning: trusted host allowed with no approver', () async {
    final dio = Dio()
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: Duration(seconds: 10),
      ));

    final res = await dio.get('https://httpbin.org/get');
    expect(res, isNotNull);
    expect(res.data, isNotNull);
    expect(res.data.toString(), contains('Host: httpbin.org'));
  });

  test('pinning: untrusted host rejected with no approver', () async {
    dynamic error;

    try {
      final dio = Dio()
        ..httpClientAdapter = Http2Adapter(ConnectionManager(
            idleTimeout: Duration(seconds: 10),
            onClientCreate: (url, config) {
              // Consider all hosts untrusted
              config.context = SecurityContext(withTrustedRoots: false);
            }));

      await dio.get('https://httpbin.org/get');
      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test('pinning: trusted certificate tested and allowed', () async {
    bool approved = false;
    final dio = Dio()
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: Duration(seconds: 10),
        onClientCreate: (url, config) {
          config.validateCertificate = (certificate, host, port) {
            approved = true;
            return true;
          };
        },
      ));

    final res = await dio.get('https://httpbin.org/get');
    expect(approved, true);
    expect(res, isNotNull);
    expect(res.data, isNotNull);
    expect(res.data.toString(), contains('Host: httpbin.org'));
  });

  test('pinning: untrusted certificate tested and allowed', () async {
    bool badCert = false;
    bool approved = false;
    final dio = Dio()
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: Duration(seconds: 10),
        onClientCreate: (url, config) {
          config.context = SecurityContext(withTrustedRoots: false);
          config.onBadCertificate = (certificate) {
            badCert = true;
            return true;
          };
          config.validateCertificate = (certificate, host, port) {
            approved = true;
            return true;
          };
        },
      ));

    final res = await dio.get('https://httpbin.org/get');
    expect(badCert, true);
    expect(approved, true);
    expect(res, isNotNull);
    expect(res.data, isNotNull);
    expect(res.data.toString(), contains('Host: httpbin.org'));
  });

  test('pinning: untrusted certificate tested and allowed', () async {
    bool badCert = false;
    bool approved = false;
    String? badCertSubject;
    String? approverSubject;
    String? badCertSha256;
    String? approverSha256;

    final dio = Dio()
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: Duration(seconds: 10),
        onClientCreate: (url, config) {
          config.context = SecurityContext(withTrustedRoots: false);
          config.onBadCertificate = (certificate) {
            badCert = true;
            badCertSubject = certificate.subject.toString();
            badCertSha256 = sha256.convert(certificate.der).toString();
            return true;
          };
          config.validateCertificate = (certificate, host, port) {
            if (certificate == null) fail('must include a certificate');
            approved = true;
            approverSubject = certificate.subject.toString();
            approverSha256 = sha256.convert(certificate.der).toString();
            return true;
          };
        },
      ));

    final res = await dio.get('https://httpbin.org/get');
    expect(badCert, true);
    expect(approved, true);
    expect(badCertSubject, isNotNull);
    expect(badCertSubject, isNot(contains('httpbin.org')));
    expect(badCertSha256, isNot(fingerprint));
    expect(approverSubject, isNotNull);
    expect(approverSubject, contains('httpbin.org'));
    expect(approverSha256, fingerprint);
    expect(approverSubject, isNot(badCertSubject));
    expect(approverSha256, isNot(badCertSha256));
    expect(res, isNotNull);
    expect(res.data, isNotNull);
    expect(res.data.toString(), contains('Host: httpbin.org'));
  });

  test('pinning: 2 requests == 1 approval', () async {
    int approvalCount = 0;
    final dio = Dio()
      ..options.baseUrl = 'https://httpbin.org/'
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        // allow connection reuse
        idleTimeout: Duration(seconds: 20),
        onClientCreate: (url, config) {
          config.validateCertificate = (certificate, host, port) {
            approvalCount++;
            return true;
          };
        },
      ));

    Response res = await dio.get('get');
    final firstTime = res.headers['date'];
    expect(approvalCount, 1);
    expect(res.data, isNotNull);
    expect(res.data.toString(), contains('Host: httpbin.org'));
    await Future.delayed(Duration(milliseconds: 900));
    res = await dio.get('get');
    final secondTime = res.headers['date'];
    expect(approvalCount, 1);
    expect(firstTime, isNot(secondTime));
    expect(res.data, isNotNull);
    expect(res.data.toString(), contains('Host: httpbin.org'));
  });
}
