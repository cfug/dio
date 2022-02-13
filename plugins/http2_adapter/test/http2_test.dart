import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

void main() {
  test('get requests', () async {
    var dio = Dio()
      ..options.baseUrl = 'https://www.ustc.edu.cn/'
      ..interceptors.add(LogInterceptor())
      ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: 10000,
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),
      );

    Response<String> response;
    response = await dio.get('?xx=6');
    assert(response.statusCode == 200);
    response = await dio.get(
      'nkjnjknjn.html',
      options: Options(validateStatus: (status) => true), // stop DioError
    );
    assert(response.statusCode == 404);
  });

  test('post request', () async {
    final dio = Dio()
      ..options.baseUrl = 'https://postman-echo.com/'
      ..httpClientAdapter = Http2Adapter(ConnectionManager());

    final res = await dio.post('post', data: 'TEST');
    assert(res.data['data'] == 'TEST');
  });

  test('catch badssl', () async {
    dynamic error;
    try {
      final dio = Dio()
        ..options.baseUrl = 'https://wrong.host.badssl.com/'
        ..httpClientAdapter = Http2Adapter(ConnectionManager());
      await dio.get('');

      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }

    assert(error.error.osError.toString().contains("Hostname mismatch"));
  });

  test('allow badssl', () async {
    dynamic error;
    try {
      final dio = Dio()
        ..options.baseUrl = 'https://wrong.host.badssl.com/'
        ..httpClientAdapter = Http2Adapter(ConnectionManager(
          onClientCreate: (_, config) =>
              config..onBadCertificate = ((_) => true),
        ));
      await dio.get('');

      fail('did not throw');
    } on DioError catch (e) {
      error = e;
    }

    // badssl.com not support HTTP/2 as of now, and no failback in dio_http2_adapter.
    assert(error.message.contains("HTTP/2 error"));
  });

  test('request with bad proxy server', () async {
    dynamic error;
    final dio = Dio()
      ..options.baseUrl = 'https://httpbin.org/'
      ..httpClientAdapter = Http2Adapter(ConnectionManager(
        onClientCreate: (_, config) =>
            config..proxy = Uri.parse('http://localhost:45678'),
      ));
    try {
      final res = await dio.get(
        'response-headers?freeform=TEST',
      );
      fail('The connection should have been timed out or rejected.');
    } on DioError catch (e) {
      error = e;
    }

    assert(error.toString().contains("SocketException"));
  });
}
