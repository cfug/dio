@TestOn('vm')
import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:test/test.dart';

void main() {
  test('works with non-TLS requests', () async {
    final dio = Dio()..httpClientAdapter = Http2Adapter(ConnectionManager());
    await dio.get('http://flutter.cn/');
    await dio.get('https://flutter.cn/non-exist-destination');
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

  test('adds one to input values', () async {
    final dio = Dio()
      ..options.baseUrl = 'https://httpbun.com/'
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: Duration(milliseconds: 10),
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),
      );

    Response<String> response;
    response = await dio.get('get');
    assert(response.statusCode == 200);
    response = await dio.get(
      'nkjnjknjn.html',
      options: Options(validateStatus: (status) => true),
    );
    assert(response.statusCode == 404);
  });

  test('request with payload', () async {
    final dio = Dio()
      ..options.baseUrl = 'https://httpbun.com/'
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: Duration(milliseconds: 10),
        ),
      );

    final res = await dio.post('post', data: 'TEST');
    expect(res.data.toString(), contains('TEST'));
  });

  test(
    'request with payload via proxy',
    () async {
      final dio = Dio()
        ..options.baseUrl = 'https://httpbun.com/'
        ..httpClientAdapter = Http2Adapter(ConnectionManager(
          idleTimeout: Duration(milliseconds: 10),
          onClientCreate: (uri, settings) =>
              settings.proxy = Uri.parse('http://localhost:3128'),
        ));

      final res = await dio.post('post', data: 'TEST');
      expect(res.data.toString(), contains('TEST'));
    },
    tags: ['proxy'],
  );

  test('request without network and restore', () async {
    bool needProxy = true;
    final dio = Dio()
      ..options.baseUrl = 'https://httpbun.com/'
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: Duration(milliseconds: 10),
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
      ));
    try {
      // will throw SocketException
      await dio.post('post', data: 'TEST');
    } on DioException {
      // ignore
    }
    final res = await dio.post('post', data: 'TEST');
    expect(res.data.toString(), contains('TEST'));
  });

  test('catch DioException when receiveTimeout', () {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://httpbun.com/',
        receiveTimeout: Duration(seconds: 5),
      ),
    );
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: Duration(milliseconds: 10),
      ),
    );

    expectLater(
      dio.get('/drip?delay=10&numbytes=1'),
      allOf([
        throwsA(isA<DioException>()),
        throwsA(predicate(
            (DioException e) => e.type == DioExceptionType.receiveTimeout)),
        throwsA(predicate(
            (DioException e) => e.message!.contains('0:00:05.000000'))),
      ]),
    );
  });

  test('no DioException when receiveTimeout > request duration', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://httpbun.com/',
        receiveTimeout: Duration(seconds: 5),
      ),
    );
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: Duration(milliseconds: 10),
      ),
    );

    await dio.get('/drip?delay=1&numbytes=1');
  });

  test('request with redirect', () async {
    final dio = Dio()
      ..options.baseUrl = 'https://httpbun.com/'
      ..httpClientAdapter = Http2Adapter(ConnectionManager());

    final res = await dio.get('absolute-redirect/2');
    expect(res.statusCode, 200);
  });

  test('header value types implicit support', () async {
    final dio = Dio()
      ..options.baseUrl = 'https://httpbun.com/'
      ..httpClientAdapter = Http2Adapter(ConnectionManager());

    final res = await dio.post(
      'post',
      data: 'TEST',
      options: Options(
        headers: {
          'ListKey': ['1', '2'],
          'StringKey': '1',
          'NumKey': 2,
          'BooleanKey': false,
        },
      ),
    );
    final content = res.data.toString();
    expect(content, contains('TEST'));
    expect(content, contains('Listkey: 1, 2'));
    expect(content, contains('Stringkey: 1'));
    expect(content, contains('Numkey: 2'));
    expect(content, contains('Booleankey: false'));
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
