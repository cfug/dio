import 'dart:async';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../util.dart';

void timeoutTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('Timeout exception of', () {
    group('connectTimeout', () {
      test('throws', () async {
        dio.options.connectTimeout = const Duration(milliseconds: 3);
        await expectLater(
          dio.get(nonRoutableUrl),
          throwsDioException(
            DioExceptionType.connectionTimeout,
            messageContains: dio.options.connectTimeout.toString(),
          ),
        );
      });
    });

    group('receiveTimeout', () {
      test('with normal response', () async {
        dio.options.receiveTimeout = const Duration(seconds: 1);
        await expectLater(
          dio.get('/drip', queryParameters: {'delay': 2}),
          throwsDioException(
            DioExceptionType.receiveTimeout,
            messageContains: dio.options.receiveTimeout.toString(),
          ),
        );
      });

      test(
        'with streamed response',
        () async {
          dio.options.receiveTimeout = const Duration(seconds: 1);
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
            throwsDioException(
              DioExceptionType.receiveTimeout,
              messageContains: dio.options.receiveTimeout.toString(),
            ),
          );
        },
        testOn: 'vm',
      );
    });
  });

  test('no DioException when receiveTimeout > request duration', () async {
    dio.options.receiveTimeout = const Duration(seconds: 5);

    await dio.get('/drip?delay=1&numbytes=1');
  });

  test('ignores zero duration timeouts', () async {
    dio.options
      ..connectTimeout = Duration.zero
      ..receiveTimeout = Duration.zero;
    // Ignores zero duration timeouts from the base options.
    await dio.get('/drip-lines?delay=1');
    // Reset the base options.
    dio.options.receiveTimeout = const Duration(milliseconds: 1);
    await expectLater(
      dio.get('/drip-lines?delay=1'),
      throwsDioException(
        DioExceptionType.receiveTimeout,
        messageContains: dio.options.receiveTimeout.toString(),
      ),
    );
    dio.options.connectTimeout = const Duration(milliseconds: 1);
    await expectLater(
      dio.get(nonRoutableUrl),
      throwsDioException(
        DioExceptionType.connectionTimeout,
        messageContains: dio.options.connectTimeout.toString(),
      ),
    );
    dio.options.connectTimeout = Duration.zero;
    // Override with request options.
    await dio.get(
      '/drip-lines?delay=1',
      options: Options(receiveTimeout: Duration.zero),
    );
  });
}
