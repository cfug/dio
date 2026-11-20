@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    // Throwaway self-signed localhost keypairs are generated at runtime so
    // that no private key is committed to the repository. openssl is already
    // a requirement for scripts/prepare_pinning_certs.sh (used by the tls
    // network tests in this group), so it is a safe build dependency to lean
    // on here.
    //
    // The certificate at [certPath] is added to the default trust store of
    // this test isolate and stands in for a certificate issued by a publicly
    // trusted CA. The one at [untrustedCertPath] stands in for a certificate
    // presented by an attacker, which the default trust store rejects.
    late Directory certDir;
    late String certPath;
    late String keyPath;
    late String untrustedCertPath;
    late String untrustedKeyPath;

    setUpAll(() {
      certDir = Directory.systemTemp.createTempSync('dio_pinning_test_');
      certPath = '${certDir.path}/server_cert.pem';
      keyPath = '${certDir.path}/server_key.pem';
      untrustedCertPath = '${certDir.path}/untrusted_cert.pem';
      untrustedKeyPath = '${certDir.path}/untrusted_key.pem';
      _generateLocalhostCertificate(certPath, keyPath);
      _generateLocalhostCertificate(untrustedCertPath, untrustedKeyPath);
      SecurityContext.defaultContext.setTrustedCertificates(certPath);
    });

    tearDownAll(() {
      if (certDir.existsSync()) {
        certDir.deleteSync(recursive: true);
      }
    });

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

    group('pre-emission validation:', () {
      late HttpServer secureServer;
      late int bytesReceived;
      late int requestsHandled;

      setUp(() async {
        bytesReceived = 0;
        requestsHandled = 0;
        final ctx = SecurityContext()
          ..useCertificateChain(certPath)
          ..usePrivateKey(keyPath);
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
        final requestsHandledAtValidation = <int>[];
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) {
            requestsHandledAtValidation.add(requestsHandled);
            return true;
          },
        );
        final res = await dio.post(
          'https://localhost:${secureServer.port}/echo',
          data: 'hi',
          options: Options(responseType: ResponseType.plain),
        );
        // Called once before the server receives the request and once more
        // when the response headers arrive.
        expect(requestsHandledAtValidation, [0, 1]);
        expect(res.statusCode, 200);
        expect(res.data, 'ok');
        expect(requestsHandled, 1);
      });

      test('two pooled requests: 1 pre-emission + 2 post-response validations',
          () async {
        // Two back-to-back requests within idleTimeout (3s) share one pooled
        // TCP connection, so the connectionFactory pre-emission hook runs
        // once (per connection) while the post-response block runs once per
        // request. The validator is therefore invoked 3 times for 2 requests.
        // This replaces the former network-dependent '2 requests' test with a
        // deterministic local-server assertion.
        int approvals = 0;
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) {
            approvals++;
            return true;
          },
        );
        await dio.post(
          'https://localhost:${secureServer.port}/one',
          data: 'a',
          options: Options(responseType: ResponseType.plain),
        );
        await dio.post(
          'https://localhost:${secureServer.port}/two',
          data: 'b',
          options: Options(responseType: ResponseType.plain),
        );
        expect(approvals, 3);
        expect(requestsHandled, 2);
      });
    });

    test(
        'certificates rejected by the default trust store never reach '
        'validateCertificate', () async {
      // Checking before the request is sent must not replace the chain
      // validation: an approving callback (e.g. one that only logs) must not
      // turn a certificate the platform rejects into a trusted connection.
      final ctx = SecurityContext()
        ..useCertificateChain(untrustedCertPath)
        ..usePrivateKey(untrustedKeyPath);
      final server = await HttpServer.bindSecure('localhost', 0, ctx);
      int requestsHandled = 0;
      server.listen((req) async {
        requestsHandled++;
        await req.drain<void>();
        await req.response.close();
      });
      try {
        int validatorCalls = 0;
        final dio = Dio()
          ..httpClientAdapter = IOHttpClientAdapter(
            validateCertificate: (cert, host, port) {
              validatorCalls++;
              return true;
            },
          );
        await expectLater(
          dio.post(
            'https://localhost:${server.port}/leak',
            data: 'SENSITIVE-PAYLOAD',
          ),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<HandshakeException>(),
            ),
          ),
        );
        expect(validatorCalls, 0);
        expect(requestsHandled, 0);
      } finally {
        await server.close(force: true);
      }
    });

    test('rejected redirect target fails with badCertificate', () async {
      // HttpClient follows the redirect itself and connects to the target
      // through the connectionFactory, so the rejection surfaces from the
      // response future instead of openUrl.
      final ctx = SecurityContext()
        ..useCertificateChain(certPath)
        ..usePrivateKey(keyPath);
      final target = await HttpServer.bindSecure('localhost', 0, ctx);
      int targetRequests = 0;
      target.listen((req) async {
        targetRequests++;
        await req.drain<void>();
        await req.response.close();
      });
      final origin = await HttpServer.bindSecure('localhost', 0, ctx);
      origin.listen((req) async {
        await req.drain<void>();
        await req.response.redirect(
          Uri.parse('https://localhost:${target.port}/landing'),
        );
      });
      try {
        final dio = Dio()
          ..httpClientAdapter = IOHttpClientAdapter(
            validateCertificate: (cert, host, port) => port != target.port,
          );
        await expectLater(
          dio.get('https://localhost:${origin.port}/start'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.badCertificate,
            ),
          ),
        );
        expect(targetRequests, 0);
      } finally {
        await origin.close(force: true);
        await target.close(force: true);
      }
    });

    group('customized HttpClient keeps its TLS configuration:', () {
      // The server presents a certificate the default trust store rejects, so
      // a request can only reach it if the badCertificateCallback configured
      // by the user was honored. The connectionFactory used for the
      // pre-emission check cannot see that configuration, so it must not be
      // installed and validateCertificate runs on the response instead.
      late HttpServer server;
      late int requestsHandled;

      setUp(() async {
        requestsHandled = 0;
        final ctx = SecurityContext()
          ..useCertificateChain(untrustedCertPath)
          ..usePrivateKey(untrustedKeyPath);
        server = await HttpServer.bindSecure('localhost', 0, ctx);
        server.listen((req) async {
          requestsHandled++;
          await req.drain<void>();
          await req.response.close();
        });
      });

      tearDown(() => server.close(force: true));

      Future<void> expectValidatedOnResponse(
        IOHttpClientAdapter adapter,
      ) async {
        adapter.validateCertificate = (cert, host, port) => false;
        final dio = Dio()..httpClientAdapter = adapter;
        await expectLater(
          dio.post('https://localhost:${server.port}/', data: 'payload'),
          throwsA(
            isA<DioException>().having(
              (e) => e.type,
              'type',
              DioExceptionType.badCertificate,
            ),
          ),
        );
        expect(requestsHandled, 1);
      }

      test('createHttpClient', () async {
        await expectValidatedOnResponse(
          IOHttpClientAdapter(
            createHttpClient: () => HttpClient()
              ..badCertificateCallback = (cert, host, port) => true,
          ),
        );
      });

      test('onHttpClientCreate', () async {
        await expectValidatedOnResponse(
          IOHttpClientAdapter(
            // ignore: deprecated_member_use_from_same_package
            onHttpClientCreate: (client) =>
                client..badCertificateCallback = (cert, host, port) => true,
          ),
        );
      });

      test('HttpOverrides', () async {
        await HttpOverrides.runWithHttpOverrides(
          () => expectValidatedOnResponse(IOHttpClientAdapter()),
          _AcceptAllCertificatesOverrides(),
        );
      });
    });

    test('plain http skips pre-emission validation', () async {
      // The pre-emission factory short-circuits non-https URLs to
      // [Socket.startConnect] without invoking the validator. The
      // post-response block still fires (with a null cert, as it always
      // has), so the user's callback decides what to do with null — the
      // typical pinning callback rejects it and the request fails.
      final server = await HttpServer.bind('localhost', 0);
      try {
        server.listen((req) {
          req.response.statusCode = 200;
          req.response.write('plain');
          req.response.close();
        });
        X509Certificate? observedCert;
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) {
            observedCert = cert;
            return true; // accept the null cert so we can assert observability
          },
        );
        final res = await dio.get(
          'http://localhost:${server.port}/',
          options: Options(responseType: ResponseType.plain),
        );
        expect(res.statusCode, 200);
        expect(res.data, 'plain');
        // Only the post-response call fires (and with null cert because
        // there is no TLS handshake on plain HTTP).
        expect(observedCert, isNull);
      } finally {
        await server.close(force: true);
      }
    });

    test(
        'validateCertificate set after construction still fires (legacy '
        'post-response path)', () async {
      // Late-mutation regression guard: a user who constructs the adapter
      // without validateCertificate and sets it later should still have the
      // callback fire (via the legacy post-response path), even though the
      // pre-emission factory could not be installed.
      final ctx = SecurityContext()
        ..useCertificateChain(certPath)
        ..usePrivateKey(keyPath);
      final server = await HttpServer.bindSecure('localhost', 0, ctx);
      server.listen((req) {
        req.response.statusCode = 200;
        req.response.write('ok');
        req.response.close();
      });
      try {
        final adapter = IOHttpClientAdapter();
        final dio = Dio()..httpClientAdapter = adapter;
        // Warm the cached HttpClient with no validator set.
        final ok = await dio.get(
          'https://localhost:${server.port}/',
          options: Options(responseType: ResponseType.plain),
        );
        expect(ok.statusCode, 200);
        // Now set the validator.
        adapter.validateCertificate = (cert, host, port) => false;
        await expectLater(
          dio.get('https://localhost:${server.port}/'),
          throwsA(
            allOf([
              isA<DioException>(),
              (DioException e) => e.type == DioExceptionType.badCertificate,
            ]),
          ),
        );
      } finally {
        await server.close(force: true);
      }
    });

    group('through a CONNECT proxy (post-response validation):', () {
      late HttpServer secureBackend;
      late ServerSocket proxy;
      late _StubProxy proxyState;

      setUp(() async {
        final ctx = SecurityContext()
          ..useCertificateChain(certPath)
          ..usePrivateKey(keyPath);
        secureBackend = await HttpServer.bindSecure('localhost', 0, ctx);
        secureBackend.listen((req) async {
          req.response.statusCode = 200;
          req.response.write('ok');
          await req.response.close();
        });
        proxyState = _StubProxy();
        proxy = await proxyState.bind('localhost');
      });

      tearDown(() async {
        await proxy.close();
        await secureBackend.close(force: true);
      });

      // A direct request creates the adapter's HttpClient first, so the
      // pre-emission connectionFactory is installed. Overriding
      // findProxyFromEnvironment afterwards routes the default
      // HttpClient.findProxy through the stub proxy, as an https_proxy
      // environment variable would.
      Future<T> throughProxy<T>(Future<T> Function() request) {
        return HttpOverrides.runWithHttpOverrides(
          request,
          _ProxyOverrides('localhost:${proxy.port}'),
        );
      }

      test('validateCertificate runs (post-response) through proxy', () async {
        final validatedPorts = <int>[];
        final adapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) {
            expect(host, 'localhost');
            validatedPorts.add(port);
            return true;
          },
        );
        final dio = Dio()..httpClientAdapter = adapter;
        final url = 'https://localhost:${secureBackend.port}/';
        final options = Options(responseType: ResponseType.plain);
        await dio.get(url, options: options);
        expect(proxyState.connectCount, 0);
        validatedPorts.clear();

        final res = await throughProxy(() => dio.get(url, options: options));
        expect(res.statusCode, 200);
        expect(res.data, 'ok');
        expect(proxyState.connectCount, 1);
        // Only the response check runs for the tunneled connection.
        expect(validatedPorts, [secureBackend.port]);
      });

      test(
          'rejection through proxy raises badCertificate '
          '(post-response, not pre-emission)', () async {
        bool reject = false;
        final adapter = IOHttpClientAdapter(
          validateCertificate: (cert, host, port) => !reject,
        );
        final dio = Dio()..httpClientAdapter = adapter;
        await dio.get('https://localhost:${secureBackend.port}/');
        reject = true;
        await expectLater(
          throughProxy(
            () => dio.post(
              'https://localhost:${secureBackend.port}/leak',
              data: 'SENSITIVE-PAYLOAD',
            ),
          ),
          throwsA(
            allOf([
              isA<DioException>(),
              (DioException e) => e.type == DioExceptionType.badCertificate,
            ]),
          ),
        );
        // The proxy was reached, the tunnel was established, the request
        // was forwarded to the backend (post-response path leaks the body
        // — documented limitation of the proxy path).
        expect(proxyState.connectCount, 1);
      });
    });
  });
}

/// Generates a self-signed certificate for `localhost` that carries the
/// subjectAltName and serverAuth extended key usage platform verifiers
/// require from a TLS server certificate.
void _generateLocalhostCertificate(String certPath, String keyPath) {
  final result = Process.runSync('openssl', [
    'req',
    '-x509',
    '-newkey',
    'rsa:2048',
    '-nodes',
    '-keyout',
    keyPath,
    '-out',
    certPath,
    '-days',
    '1',
    '-subj',
    '/CN=localhost',
    '-addext',
    'subjectAltName=DNS:localhost',
    '-addext',
    'extendedKeyUsage=serverAuth',
  ]);
  if (result.exitCode != 0) {
    throw StateError(
      'Failed to generate a self-signed test certificate with openssl '
      '(exit ${result.exitCode}). openssl must be installed to run the '
      'pinning tests.\n${result.stderr}',
    );
  }
}

/// Configures every [HttpClient] it creates to accept any certificate, like
/// the `HttpOverrides.global` setups apps use for development servers.
class _AcceptAllCertificatesOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

/// Resolves every request to [proxy], like an `https_proxy` environment
/// variable does for the default [HttpClient.findProxy].
class _ProxyOverrides extends HttpOverrides {
  _ProxyOverrides(this.proxy);

  final String proxy;

  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    return 'PROXY $proxy';
  }
}

/// Stub HTTP/1.1 CONNECT proxy for tests. Accepts `CONNECT host:port` and
/// opens a TCP tunnel to the target, forwarding bytes both directions.
class _StubProxy {
  int connectCount = 0;

  Future<ServerSocket> bind(String address) async {
    final server = await ServerSocket.bind(address, 0);
    server.listen(_handleClient);
    return server;
  }

  void _handleClient(Socket client) {
    final headerBuffer = BytesBuilder(copy: false);
    Socket? backend;
    bool tunneled = false;

    client.listen(
      (chunk) async {
        if (tunneled) {
          backend?.add(chunk);
          return;
        }
        headerBuffer.add(chunk);
        final decoded =
            ascii.decode(headerBuffer.toBytes(), allowInvalid: true);
        final end = decoded.indexOf('\r\n\r\n');
        if (end < 0) {
          return;
        }
        final requestLine = decoded.substring(0, decoded.indexOf('\r\n'));
        final match = RegExp(r'^CONNECT (\S+):(\d+)').firstMatch(requestLine);
        if (match == null) {
          client.write('HTTP/1.1 400 Bad Request\r\n\r\n');
          await client.close();
          return;
        }
        connectCount++;
        try {
          backend =
              await Socket.connect(match.group(1)!, int.parse(match.group(2)!));
        } catch (_) {
          client.write('HTTP/1.1 502 Bad Gateway\r\n\r\n');
          await client.close();
          return;
        }
        client.write('HTTP/1.1 200 Connection established\r\n\r\n');
        tunneled = true;
        backend!.listen(
          client.add,
          onError: (_) => client.destroy(),
          onDone: () => client.destroy(),
        );
      },
      onError: (_) => backend?.destroy(),
      onDone: () => backend?.destroy(),
    );
  }
}
