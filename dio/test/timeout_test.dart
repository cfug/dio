@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio();
    dio.options.baseUrl = 'https://httpbun.com/';
  });

  test('catch DioException when connect timeout', () {
    dio.options.connectTimeout = Duration(milliseconds: 3);

    expectLater(
      dio.get('/drip-lines?delay=2'),
      allOf(
        throwsA(isA<DioException>()),
        throwsA(predicate((DioException e) =>
            e.type == DioExceptionType.connectionTimeout &&
            e.message!.contains('0:00:00.003000'))),
      ),
    );
  });

  test('catch DioException when receiveTimeout', () {
    dio.options.receiveTimeout = Duration(milliseconds: 10);

    expectLater(
      dio.get(
        '/bytes/${1024 * 1024 * 20}',
        options: Options(responseType: ResponseType.stream),
      ),
      allOf([
        throwsA(isA<DioException>()),
        throwsA(predicate(
            (DioException e) => e.type == DioExceptionType.receiveTimeout)),
        throwsA(predicate(
            (DioException e) => e.message!.contains('0:00:00.010000'))),
      ]),
    );
  }, testOn: 'vm');

  test('no DioException when receiveTimeout > request duration', () async {
    dio.options.receiveTimeout = Duration(seconds: 5);

    await dio.get('/drip?delay=1&numbytes=1');
  });

  test('change connectTimeout in run time ', () async {
    final dio = Dio();
    final adapter = IOHttpClientAdapter();
    final http = HttpClient();

    adapter.createHttpClient = () => http;
    dio.httpClientAdapter = adapter;
    dio.options.connectTimeout = Duration(milliseconds: 200);

    try {
      await dio.get('/');
    } on DioException catch (_) {}
    expect(http.connectionTimeout?.inMilliseconds == 200, isTrue);

    try {
      dio.options.connectTimeout = Duration(seconds: 1);
      await dio.get('/');
    } on DioException catch (_) {}
    expect(http.connectionTimeout?.inSeconds == 1, isTrue);
  }, testOn: 'vm');

  test('ignores zero duration timeouts', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://httpbun.com/',
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () =>
          HttpClient()..findProxy = (_) => 'PROXY 192.168.0.10:8764',
    );
    // Ignores zero duration timeouts from the base options.
    await dio.get('/drip-lines?delay=1');
    // Reset the base options.
    dio.options.receiveTimeout = Duration(milliseconds: 10);
    await expectLater(
      dio.get('/drip-lines?delay=1'),
      allOf([
        throwsA(isA<DioException>()),
        throwsA(
          predicate<DioException>(
            (e) => e.type == DioExceptionType.receiveTimeout,
          ),
        ),
        throwsA(
          predicate<DioException>(
            (e) => e.message!.contains('0:00:00.010000'),
          ),
        ),
      ]),
    );
    dio.options.connectTimeout = Duration(milliseconds: 10);
    await expectLater(
      dio.get('/drip-lines?delay=1'),
      allOf([
        throwsA(isA<DioException>()),
        throwsA(
          predicate<DioException>(
            (e) => e.type == DioExceptionType.connectionTimeout,
          ),
        ),
        throwsA(
          predicate<DioException>(
            (e) => e.message!.contains('0:00:00.010000'),
          ),
        ),
      ]),
    );
    dio.options.connectTimeout = Duration.zero;
    // Override with request options.
    await dio.get(
      '/drip-lines?delay=1',
      options: Options(receiveTimeout: Duration.zero),
    );
  });
}
