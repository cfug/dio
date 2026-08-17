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
      'badCertCallback rejects a non-matching pinned fingerprint',
      () async {
        DioException? error;
        try {
          final dio = Dio();
          dio.httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () {
              final effectiveClient = HttpClient(
                context: SecurityContext(withTrustedRoots: false),
              );
              // Pin a fingerprint that is not the served leaf certificate's
              // so badCertificateCallback rejects the handshake. Previous
              // revisions pinned a sibling badssl.com host's fingerprint,
              // which stopped mismatching once all badssl.com hosts started
              // serving the same wildcard certificate.
              final pinnedFingerprint = sha256.convert([0]).toString();
              effectiveClient.badCertificateCallback = (cert, host, port) =>
                  pinnedFingerprint == sha256.convert(cert.der).toString();
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
      '2 requests == 2 approvals',
      () async {
        int approvalCount = 0;
        final dio = Dio();
        // badCertificateCallback never called for trusted certificate
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
        expect(approvalCount, 2);
      },
      tags: ['tls'],
    );
  });
}
