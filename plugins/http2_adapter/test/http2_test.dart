import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:dio_test/util.dart';
import 'package:http2/transport.dart';
import 'package:test/test.dart';

void main() {
  test('httpVersion is set to 2.0 for HTTP/2 connections', () async {
    final dio = Dio()
      ..options.baseUrl = httpbunBaseUrl
      ..httpClientAdapter = Http2Adapter(ConnectionManager());
    final response = await dio.get('/get');
    final httpVersion = response.extra[HttpClientAdapter.extraKeyHttpVersion];
    expect(httpVersion, equals('2.0'));
  });

  test('handles gracefully if H2 is not supported', () async {
    const destinationHost = 'www.baidu.com';
    final destination = Uri.https(destinationHost);
    final dioWithNothing = Dio()
      ..httpClientAdapter = Http2Adapter(ConnectionManager());
    await expectLater(
      await dioWithNothing.getUri(destination),
      allOf([
        isA<Response>(),
        (Response r) => r.realUri.host == destinationHost,
      ]),
    );
    final dioWithCallback = Dio()
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(),
        onNotSupported: (_, __, ___, e) {
          return Future.value(ResponseBody.fromString('', 200));
        },
      );
    await expectLater(
      await dioWithCallback.getUri(destination),
      allOf([
        isA<Response>(),
        (Response r) => r.data == '',
      ]),
    );
    final dioWithThrows = Dio()
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(),
        onNotSupported: (_, __, ___, e) => throw e,
      );
    await expectLater(
      dioWithThrows.getUri(destination),
      throwsA(
        allOf([
          isA<DioException>(),
          (e) => e.error is DioH2NotSupportedException,
          (e) =>
              (e.error as DioH2NotSupportedException).uri.host ==
              destinationHost,
        ]),
      ),
    );
  });

  test(
    'request with payload via proxy',
    () async {
      final dio = Dio()
        ..options.baseUrl = httpbunBaseUrl
        ..httpClientAdapter = Http2Adapter(
          ConnectionManager(
            idleTimeout: const Duration(milliseconds: 10),
            onClientCreate: (uri, settings) =>
                settings.proxy = Uri.parse('http://localhost:3128'),
          ),
        );

      final res = await dio.post('/post', data: 'TEST');
      expect(res.data.toString(), contains('TEST'));
    },
    tags: ['proxy'],
  );

  test('request without network and restore', () async {
    bool needProxy = true;
    final dio = Dio()
      ..options.baseUrl = httpbunBaseUrl
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: const Duration(milliseconds: 10),
          onClientCreate: (uri, settings) {
            if (needProxy) {
              // first request use bad proxy to simulate network error
              settings.proxy = Uri.parse('http://localhost:1234');
              needProxy = false;
            } else {
              // remove proxy to restore network
              settings.proxy = null;
            }
          },
        ),
      );
    try {
      // will throw SocketException
      await dio.post('/post', data: 'TEST');
    } on DioException {
      // ignore
    }
    final res = await dio.post('/post', data: 'TEST');
    expect(res.data.toString(), contains('TEST'));
  });

  group('request stream', () {
    late ServerSocket serverSocket;
    late Http2Adapter adapter;
    final serverConnections = <ServerTransportConnection>[];

    setUp(() async {
      serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      adapter = Http2Adapter(null);
    });

    tearDown(() async {
      adapter.close(force: true);
      for (final connection in serverConnections) {
        await connection.terminate();
      }
      serverConnections.clear();
      await serverSocket.close();
    });

    test(
      'reports a transport error when the connection closes during upload',
      () async {
        serverSocket.listen((socket) {
          final connection = ServerTransportConnection.viaSocket(socket);
          serverConnections.add(connection);
          connection.incomingStreams.listen((stream) async {
            await for (final message in stream.incomingMessages) {
              if (message is HeadersStreamMessage) {
                await connection.terminate();
                break;
              }
            }
          });
        });

        final requestStream = (() async* {
          for (int i = 0; i < 20; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            yield Uint8List(1024);
          }
        })();
        final resultCompleter = Completer<Object?>();

        void completeResult(Object? result) {
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(result);
          }
        }

        runZonedGuarded(
          () async {
            try {
              await adapter.fetch(
                RequestOptions(
                  path: '/upload',
                  method: 'POST',
                  baseUrl: 'http://127.0.0.1:${serverSocket.port}',
                ),
                requestStream,
                null,
              );
              completeResult(null);
            } catch (error) {
              completeResult(error);
            }
          },
          (error, _) => completeResult(error),
        );

        final result = await resultCompleter.future.timeout(
          const Duration(seconds: 2),
        );
        expect(result, isA<TransportConnectionException>());
      },
    );

    test('settles the adapter future when an upload is canceled', () async {
      final requestDataReceived = Completer<void>();
      serverSocket.listen((socket) {
        final connection = ServerTransportConnection.viaSocket(socket);
        serverConnections.add(connection);
        connection.incomingStreams.listen((stream) async {
          await for (final message in stream.incomingMessages) {
            if (message is DataStreamMessage &&
                !requestDataReceived.isCompleted) {
              requestDataReceived.complete();
            }
          }
          stream.sendHeaders(
            [Header.ascii(':status', '200')],
            endStream: true,
          );
        });
      });

      final requestController = StreamController<Uint8List>();
      addTearDown(requestController.close);
      final cancelCompleter = Completer<void>();
      final fetchFuture = adapter.fetch(
        RequestOptions(
          path: '/upload',
          method: 'POST',
          baseUrl: 'http://127.0.0.1:${serverSocket.port}',
        ),
        requestController.stream,
        cancelCompleter.future,
      );

      requestController.add(Uint8List(1024));
      await requestDataReceived.future.timeout(const Duration(seconds: 2));
      cancelCompleter.complete();

      final response = await fetchFuture.timeout(const Duration(seconds: 2));
      expect(response.statusCode, 200);
      expect(requestController.hasListener, isFalse);
    });
  });

  group(ConnectionManager, () {
    test('returns correct connection', () async {
      final manager = ConnectionManager();
      final tlsConnection = await manager.getConnection(
        RequestOptions(path: 'https://flutter.cn'),
        [],
      );
      final tlsWithSameHostRedirects = await manager.getConnection(
        RequestOptions(path: 'https://flutter.cn'),
        [
          RedirectRecord(301, 'GET', Uri.parse('https://flutter.cn/404')),
        ],
      );
      final tlsDifferentHostRedirects = await manager.getConnection(
        RequestOptions(path: 'https://flutter.cn'),
        [
          RedirectRecord(301, 'GET', Uri.parse('https://flutter.dev')),
        ],
      );
      final tlsDifferentHostsRedirects = await manager.getConnection(
        RequestOptions(path: 'https://flutter.cn'),
        [
          RedirectRecord(301, 'GET', Uri.parse('https://flutter.dev')),
          RedirectRecord(301, 'GET', Uri.parse('https://flutter.dev/404')),
        ],
      );
      final nonTLSConnection = await manager.getConnection(
        RequestOptions(path: 'http://flutter.cn'),
        [],
      );
      final nonTLSConnectionWithTLSRedirects = await manager.getConnection(
        RequestOptions(path: 'http://flutter.cn'),
        [
          RedirectRecord(301, 'GET', Uri.parse('https://flutter.cn/')),
        ],
      );
      final differentHostConnection = await manager.getConnection(
        RequestOptions(path: 'https://flutter.dev'),
        [],
      );
      expect(tlsConnection == tlsWithSameHostRedirects, true);
      expect(tlsConnection == tlsDifferentHostRedirects, false);
      expect(tlsConnection == tlsDifferentHostsRedirects, false);
      expect(tlsConnection == nonTLSConnection, false);
      expect(tlsConnection == nonTLSConnectionWithTLSRedirects, true);
      expect(tlsConnection == differentHostConnection, false);
      expect(tlsDifferentHostRedirects == differentHostConnection, true);
      expect(tlsDifferentHostsRedirects == differentHostConnection, true);
      expect(nonTLSConnection == nonTLSConnectionWithTLSRedirects, false);
    });

    test('throws TimeoutException on handshakeTimeout set', () async {
      const handshakeTimeout = Duration(microseconds: 1);
      final dio = Dio()
        ..options.baseUrl = httpbunBaseUrl
        ..httpClientAdapter = Http2Adapter(
          ConnectionManager(
            handshakeTimout: handshakeTimeout,
          ),
        );

      await expectLater(
        dio.post('/post', data: 'TEST'),
        throwsA(
          allOf([
            isA<DioException>(),
            (e) => e.error is TimeoutException,
            (e) => (e.error as TimeoutException).duration == handshakeTimeout,
          ]),
        ),
      );
    });

    // Regression test for https://github.com/cfug/dio/pull/2481
    // Verifies that connections are properly removed from cache after idle
    // timeout. Previously, there was an inconsistency in cache key format:
    // - getConnection used 'scheme://host:port' (e.g., 'https://example.com:443')
    // - _connect used 'host:port' (e.g., 'example.com:443')
    // This caused _transportsMap.remove() to fail, leading to memory leaks.
    test('removes connection from cache after idle timeout', () async {
      final manager = ConnectionManager(
        idleTimeout: const Duration(milliseconds: 500),
      );
      final dio = Dio()
        ..options.baseUrl = httpbunBaseUrl
        ..httpClientAdapter = Http2Adapter(manager);

      // Make a request to establish a connection
      await dio.get('/get');

      // Verify connection is cached
      expect(manager.cachedConnectionsCount, equals(1));

      // Wait for idle timeout to trigger (500ms + buffer)
      // The connection becomes inactive after the request completes,
      // then the idle timer will remove it from the cache.
      await Future<void>.delayed(const Duration(milliseconds: 5000));

      // Verify connection has been removed from cache
      expect(manager.cachedConnectionsCount, equals(0));

      manager.close(force: true);
    });

    // Regression: with only ['h2'] in supportedProtocols the TLS handshake
    // is aborted by an RFC 7301-strict server with a fatal
    // no_application_protocol alert before any Dio code runs,
    // so fallbackAdapter is never reached.
    test(
      'fails with HandshakeException when only h2 is advertised to an http/1.1-only server',
      () async {
        const supportedProtocols = ['h2'];

        final port = await _bindHttp11OnlyServer();
        final serverUri = Uri(scheme: 'https', host: 'localhost', port: port);

        var fallbackCalled = false;
        final dio = Dio()
          ..httpClientAdapter = Http2Adapter(
            ConnectionManager(
              supportedProtocols: supportedProtocols,
              onClientCreate: (_, settings) =>
                  settings.onBadCertificate = (_) => true,
            ),
            fallbackAdapter: _TrackingAdapter(
              () => fallbackCalled = true,
              IOHttpClientAdapter(
                createHttpClient: () =>
                    HttpClient()..badCertificateCallback = (_, __, ___) => true,
              ),
            ),
          );

        await expectLater(
          dio.getUri(serverUri),
          throwsA(
            allOf([
              isA<DioException>(),
              (DioException e) => e.error is HandshakeException,
            ]),
          ),
        );
        expect(fallbackCalled, isFalse);
      },
    );

    test(
      'routes to fallbackAdapter when h2 and http/1.1 are both advertised & server selects http/1.1',
      () async {
        const supportedProtocols = ['h2', 'http/1.1'];

        final port = await _bindHttp11OnlyServer();
        final serverUri = Uri(scheme: 'https', host: 'localhost', port: port);

        var fallbackCalled = false;
        final dio = Dio()
          ..httpClientAdapter = Http2Adapter(
            ConnectionManager(
              supportedProtocols: supportedProtocols,
              onClientCreate: (_, settings) =>
                  settings.onBadCertificate = (_) => true,
            ),
            fallbackAdapter: _TrackingAdapter(
              () => fallbackCalled = true,
              IOHttpClientAdapter(
                createHttpClient: () =>
                    HttpClient()..badCertificateCallback = (_, __, ___) => true,
              ),
            ),
          );
        final response = await dio.getUri(serverUri);
        expect(response.statusCode, 200);
        expect(fallbackCalled, isTrue);
      },
    );
  });

  group(ProxyConnectedPredicate, () {
    group('defaultProxyConnectedPredicate', () {
      test(
        'accepts HTTP/1.x for HTTP/1.1 proxy',
        () {
          expect(
            defaultProxyConnectedPredicate('HTTP/1.1', 'HTTP/1.1 200'),
            true,
          );
          expect(
            defaultProxyConnectedPredicate('HTTP/1.1', 'HTTP/1.0 200'),
            true,
          );
        },
      );
    });
  });
}

/// Starts an `openssl s_server` process that strictly enforces `http/1.1` via
/// ALPN (RFC 7301). A client that advertises only `h2` receives a fatal
/// `no_application_protocol` TLS alert. A client advertising `http/1.1`
/// completes the handshake and receives a minimal `HTTP/1.1 200 OK` response.
///
/// Skips the calling test if `openssl` is not found on PATH or if the process
/// exits before binding (e.g. cert files not found).
///
/// Returns the port the server is listening on.
Future<int> _bindHttp11OnlyServer() async {
  // Allocate a free port. openssl s_server in -quiet mode does not print its
  // bound port, so we allocate one ourselves and pass it explicitly.
  final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = probe.port;
  await probe.close();

  late final Process process;
  try {
    // Raw pipe mode (-quiet): decrypted client bytes arrive on process.stdout;
    // data written to process.stdin is TLS-encrypted and sent to the client.
    // -quiet also suppresses openssl session info on stdout, so the only data
    // that arrives on stdout is the actual HTTP request from the client.
    process = await Process.start('openssl', [
      's_server',
      '-key',
      'test/certificates/server.key',
      '-cert',
      'test/certificates/server.crt',
      '-accept',
      '127.0.0.1:$port',
      '-alpn',
      'http/1.1',
      '-quiet',
    ]);
  } on ProcessException {
    markTestSkipped('openssl not found on PATH — skipping strict-ALPN test');
    return 0; // unreachable
  }

  addTearDown(() => process.kill());

  process.stderr.drain<void>();
  _serveHttp11Response(process);

  // -quiet suppresses the ACCEPT readiness line, so poll until the port is
  // reachable. Detect early exit (e.g. wrong CWD, cert files missing) to skip
  // rather than time out.
  await _pollUntilListening(port, process);
  return port;
}

/// Responds to the first HTTP request that arrives on [process.stdout] with a
/// minimal `HTTP/1.1 200 OK`, then closes stdin to end the TLS session.
void _serveHttp11Response(Process process) {
  var responded = false;
  process.stdout.listen((data) {
    if (responded) {
      return;
    }
    responded = true;
    process.stdin
      ..write(
        'HTTP/1.1 200 OK\r\n'
        'Content-Length: 0\r\n'
        'Connection: close\r\n'
        '\r\n',
      )
      ..close();
  });
}

/// Polls [port] on loopback until a TCP connection succeeds (openssl is ready)
/// or [process] exits early (cert error, wrong CWD, etc.).
///
/// Skips the calling test if openssl does not start listening within ~2 s.
Future<void> _pollUntilListening(int port, Process process) async {
  var processExited = false;
  process.exitCode.then<void>((_) => processExited = true);

  for (var i = 0; i < 40; i++) {
    if (processExited) {
      markTestSkipped(
        'openssl exited before binding — check that test/certificates/ exists '
        'and dart test is run from the package root',
      );
      return; // unreachable
    }
    try {
      final s = await Socket.connect(
        '127.0.0.1',
        port,
        timeout: const Duration(milliseconds: 50),
      );
      await s.close();
      return;
    } on SocketException {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  markTestSkipped('openssl did not start listening within 2 s');
}

/// Wraps another [HttpClientAdapter], calling [onFetch] before each request.
class _TrackingAdapter implements HttpClientAdapter {
  _TrackingAdapter(this.onFetch, this._delegate);

  final void Function() onFetch;
  final HttpClientAdapter _delegate;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    onFetch();
    return _delegate.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) => _delegate.close(force: force);
}
