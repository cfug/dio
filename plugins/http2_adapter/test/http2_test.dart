import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:test/test.dart';

void main() {
  test('adds one to input values', () async {
    final dio = Dio()
      ..options.baseUrl = 'https://pub.dev/'
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
      ..options.baseUrl = 'https://httpbun.com/'
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: Duration(milliseconds: 10),
        ),
      );

    final res = await dio.post('post', data: 'TEST');
    expect(res.data.toString(), contains('TEST'));
  });

  test('request with payload via proxy', () async {
    final dio = Dio()
      ..options.baseUrl = 'https://httpbun.com/'
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        idleTimeout: Duration(milliseconds: 10),
        onClientCreate: (uri, settings) =>
            settings.proxy = Uri.parse('http://localhost:3128'),
      ));

    final res = await dio.post('post', data: 'TEST');
    expect(res.data.toString(), contains('TEST'));
  });

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
    } on DioException catch (e) {
      // ignore
    }
    final res = await dio.post('post', data: 'TEST');
    expect(res.data.toString(), contains('TEST'));
  });
}
