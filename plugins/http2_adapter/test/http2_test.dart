import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:dio_test/util.dart';
import 'package:test/test.dart';

void main() {
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
