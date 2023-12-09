import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio();
    dio.options.baseUrl = 'https://httpbun.local/';
  });

  group('Timeout exception of', () {
    group('connectTimeout', () {
      test('with response', () async {
        dio.options.connectTimeout = Duration(milliseconds: 3);
        await expectLater(
          dio.get('/'),
          allOf(
            throwsA(isA<DioException>()),
            throwsA(predicate((DioException e) =>
                e.type == DioExceptionType.connectionTimeout &&
                e.message!.contains('${dio.options.connectTimeout}'))),
          ),
        );
      });

      test('update between calls', () async {
        final client = HttpClient();
        final dio = Dio()
          ..options.baseUrl = 'https://httpbun.com'
          ..httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () => client,
          );

        dio.options.connectTimeout = Duration(milliseconds: 5);
        await dio
            .get('/')
            .catchError((e) => Response(requestOptions: RequestOptions()));
        expect(client.connectionTimeout, dio.options.connectTimeout);
        dio.options.connectTimeout = Duration(milliseconds: 10);
        await dio
            .get('/')
            .catchError((e) => Response(requestOptions: RequestOptions()));
        expect(client.connectionTimeout, dio.options.connectTimeout);
      }, testOn: 'vm');
    });

    group('receiveTimeout', () {
      test('with normal response', () async {
        dio.options.receiveTimeout = Duration(seconds: 1);
        await expectLater(
          dio.get('/drip', queryParameters: {'delay': 2}),
          allOf([
            throwsA(isA<DioException>()),
            throwsA(
              predicate<DioException>(
                (e) => e.type == DioExceptionType.receiveTimeout,
              ),
            ),
            throwsA(
              predicate<DioException>(
                (e) => e.message!.contains('${dio.options.receiveTimeout}'),
              ),
            ),
          ]),
        );
      });

      test('with streamed response', () async {
        dio.options.receiveTimeout = Duration(seconds: 1);
        final completer = Completer<void>();
        final streamedResponse = await dio.get(
          '/drip',
          queryParameters: {'delay': 0, 'duration': 20},
          options: Options(responseType: ResponseType.stream),
        );
        (streamedResponse.data as ResponseBody).stream.listen(
          (event) {},
          onError: (error) {
            if (!completer.isCompleted) {
              completer.completeError(error);
            }
          },
          onDone: () {
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );
        await expectLater(
          completer.future,
          allOf([
            throwsA(isA<DioException>()),
            throwsA(
              predicate<DioException>(
                (e) => e.type == DioExceptionType.receiveTimeout,
              ),
            ),
            throwsA(
              predicate<DioException>(
                (e) => e.message!.contains('${dio.options.receiveTimeout}'),
              ),
            ),
          ]),
        );
      }, testOn: 'vm');
    });
  });

  test('no DioException when receiveTimeout > request duration', () async {
    dio.options.receiveTimeout = Duration(seconds: 5);

    await dio.get('/drip?delay=1&numbytes=1');
  });

  test('ignores zero duration timeouts', () async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://httpbun.local/',
        connectTimeout: Duration.zero,
        receiveTimeout: Duration.zero,
      ),
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
    dio.options.receiveTimeout = Duration.zero;
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
