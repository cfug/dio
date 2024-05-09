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
