@TestOn('vm')
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  final trustedCertUrl = 'https://sha256.badssl.com/';
  final untrustedCertUrl = 'https://wrong.host.badssl.com/';

  /// NOTE: Run scripts/prepare_pinning_certs.sh
  /// to download the current certs to the file below.
  String fingerprint() {
    // OpenSSL output like: SHA256 Fingerprint=EE:5C:E1:DF:A7:A4...
    // All badssl.com hosts have the same cert, they just have TLS
    // setting or other differences (like host name) that make them bad.
    final lines = File('test/_pinning.txt').readAsLinesSync();
    return lines.first.split('=').last.toLowerCase().replaceAll(':', '');
  }

  group('pinning:', () {
    test('trusted host allowed with no approver', () async {
      await Dio().get(trustedCertUrl);
    });

    test('untrusted host rejected with no approver', () async {
      DioException? error;
      try {
        final dio = Dio();
        await dio.get(untrustedCertUrl);
        fail('did not throw');
      } on DioException catch (e) {
        error = e;
      }
      expect(error, isNotNull);
    });

    test('every certificate tested and rejected', () async {
      DioException? error;
      try {
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (certificate, host, port) => false,
        );
        await dio.get(trustedCertUrl);
        fail('did not throw');
      } on DioException catch (e) {
        error = e;
      }
      expect(error, isNotNull);
    });

    test(
      'trusted certificate tested and allowed',
      () async {
        final dio = Dio();
        // badCertificateCallback never called for trusted certificate
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) =>
              fingerprint() == sha256.convert(cert!.der).toString(),
        );
        final response = await dio.get(
          trustedCertUrl,
          options: Options(validateStatus: (status) => true),
        );
        expect(response, isNotNull);
      },
      tags: ['tls'],
    );

    test(
      'untrusted certificate tested and allowed',
      () async {
        final dio = Dio();
        // badCertificateCallback must allow the untrusted certificate through
        dio.httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () {
            return HttpClient()
              ..badCertificateCallback = (cert, host, port) => true;
          },
          validateCertificate: (cert, host, port) {
            return fingerprint() == sha256.convert(cert!.der).toString();
          },
        );
        final response = await dio.get(
          untrustedCertUrl,
          options: Options(validateStatus: (status) => true),
        );
        expect(response, isNotNull);
      },
      tags: ['tls'],
    );

    test(
      'untrusted certificate rejected before validateCertificate',
      () async {
        DioException? error;
        try {
          final dio = Dio();
          dio.httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () {
              return HttpClient(
                context: SecurityContext(withTrustedRoots: false),
              );
            },
            validateCertificate: (cert, host, port) =>
                fail('Should not be evaluated'),
          );
          await dio.get(
            untrustedCertUrl,
            options: Options(validateStatus: (status) => true),
          );
          fail('did not throw');
        } on DioException catch (e) {
          error = e;
        }
        expect(error, isNotNull);
      },
    );

    test(
      'badCertCallback does not use leaf certificate',
      () async {
        DioException? error;
        try {
          final dio = Dio();
          dio.httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () {
              final effectiveClient = HttpClient(
                context: SecurityContext(withTrustedRoots: false),
              );
              // Comparison fails because fingerprint is for leaf cert, but
              // this cert is from Let's Encrypt.
              effectiveClient.badCertificateCallback = (cert, host, port) =>
                  fingerprint() == sha256.convert(cert.der).toString();
              return effectiveClient;
            },
          );
          await dio.get(
            trustedCertUrl,
            options: Options(validateStatus: (status) => true),
          );
          fail('did not throw');
        } on DioException catch (e) {
          error = e;
        }
        expect(error, isNotNull);
      },
      tags: ['tls'],
    );

    test(
      '2 requests share connection (1 approval)',
      () async {
        // Validation is now per TCP connection (not per HTTP request) since
        // the callback fires from the connectionFactory pre-emission rather
        // than post-response. HttpClient pools connections, so back-to-back
        // requests within idleTimeout (3s) share one connection and one
        // approval. Matches dio_http2_adapter's long-standing semantics.
        int approvalCount = 0;
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) {
            approvalCount++;
            return fingerprint() == sha256.convert(cert!.der).toString();
          },
        );
        Response response = await dio.get(
          trustedCertUrl,
          options: Options(validateStatus: (status) => true),
        );
        expect(response.data, isNotNull);
        response = await dio.get(
          trustedCertUrl,
          options: Options(validateStatus: (status) => true),
        );
        expect(response.data, isNotNull);
        expect(approvalCount, 1);
      },
      tags: ['tls'],
    );

    group('pre-emission validation:', () {
      late HttpServer secureServer;
      late int bytesReceived;
      late int requestsHandled;

      setUp(() async {
        bytesReceived = 0;
        requestsHandled = 0;
        final ctx = SecurityContext()
          ..useCertificateChain('test/_pinning/server_cert.pem')
          ..usePrivateKey('test/_pinning/server_key.pem');
        secureServer = await HttpServer.bindSecure('localhost', 0, ctx);
        secureServer.listen((req) async {
          requestsHandled++;
          try {
            await for (final chunk in req) {
              bytesReceived += chunk.length;
            }
          } finally {
            req.response.statusCode = 200;
            req.response.write('ok');
            await req.response.close();
          }
        });
      });

      tearDown(() async {
        await secureServer.close(force: true);
      });

      test('rejection blocks request body emission', () async {
        // Load-bearing regression test for #2418: when validateCertificate
        // returns false, the request body must never reach the server.
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) => false,
        );
        DioException? error;
        try {
          await dio.post(
            'https://localhost:${secureServer.port}/leak',
            data: 'SENSITIVE-PAYLOAD',
          );
          fail('did not throw');
        } on DioException catch (e) {
          error = e;
        }
        // Allow any in-flight server activity to settle.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(error, isNotNull);
        expect(error.type, DioExceptionType.badCertificate);
        expect(bytesReceived, 0);
        expect(requestsHandled, 0);
      });

      test('approval lets the request through', () async {
        bool approverCalled = false;
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) {
            approverCalled = true;
            return true;
          },
        );
        final res = await dio.post(
          'https://localhost:${secureServer.port}/echo',
          data: 'hi',
          options: Options(responseType: ResponseType.plain),
        );
        expect(approverCalled, isTrue);
        expect(res.statusCode, 200);
        expect(res.data, 'ok');
        expect(requestsHandled, 1);
      });

      test('createHttpClient escape hatch keeps post-response validation',
          () async {
        // When createHttpClient is supplied, the connectionFactory cannot
        // be installed without clobbering the user-built HttpClient.
        // validateCertificate continues to fire post-response (legacy 5.x
        // behavior).
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () => HttpClient()
            ..badCertificateCallback = (cert, host, port) => true,
          validateCertificate: (cert, host, port) => false,
        );
        DioException? error;
        try {
          await dio.post(
            'https://localhost:${secureServer.port}/legacy',
            data: 'payload',
          );
          fail('did not throw');
        } on DioException catch (e) {
          error = e;
        }
        expect(error, isNotNull);
        expect(error.type, DioExceptionType.badCertificate);
        // Legacy path: server received the request before validation ran.
        expect(requestsHandled, 1);
        expect(bytesReceived, greaterThan(0));
      });
    });

    test('plain http does not invoke validateCertificate', () async {
      final server = await HttpServer.bind('localhost', 0);
      try {
        server.listen((req) {
          req.response.statusCode = 200;
          req.response.write('plain');
          req.response.close();
        });
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) {
            fail('validateCertificate must not run on plain HTTP');
          },
        );
        final res = await dio.get(
          'http://localhost:${server.port}/',
          options: Options(responseType: ResponseType.plain),
        );
        expect(res.statusCode, 200);
        expect(res.data, 'plain');
      } finally {
        await server.close(force: true);
      }
    });
  });
}
