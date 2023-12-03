@TestOn('vm')
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:test/test.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio();
    dio.options.baseUrl = 'https://httpbun.com/';
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: Duration(seconds: 30)),
    );
  });

  test('catch DioException when connectTimeout', () {
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

  test('catch DioException when receiveTimeout', () async {
    dio.options.receiveTimeout = Duration(seconds: 1);

    final matcher = allOf([
      throwsA(isA<DioException>()),
      throwsA(
        predicate<DioException>(
          (e) => e.type == DioExceptionType.receiveTimeout,
        ),
      ),
      throwsA(
        predicate<DioException>((e) => e.message!.contains('0:00:01.000000')),
      ),
    ]);
    await expectLater(
      dio.get(
        '/drip',
        queryParameters: {'delay': 2},
      ),
      matcher,
    );

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
    await expectLater(completer.future, matcher);
    await expectLater(
      dio.get(
        '/drip',
        queryParameters: {'delay': 0, 'duration': 2},
        options: Options(responseType: ResponseType.stream),
      ),
      matcher,
    );
  });
}
