@TestOn('vm')
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:test/test.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio();
    dio.options.baseUrl = 'https://httpbun.local/';
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: Duration(seconds: 30)),
    );
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
                (e) =>
                    e.message!.contains(dio.options.receiveTimeout.toString()),
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
                  (e) => e.message!
                      .contains(dio.options.receiveTimeout.toString()),
                ),
              ),
            ]));
      });
    });
  });
}
