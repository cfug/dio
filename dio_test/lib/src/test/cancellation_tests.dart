import 'dart:async';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../util.dart';

void cancellationTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('cancellation', () {
    test('basic', () {
      final token = CancelToken();

      Future.delayed(const Duration(milliseconds: 250), () {
        token.cancel('cancelled');
      });

      expectLater(
        dio.get('/drip-lines?delay=0', cancelToken: token),
        throwsDioException(
          DioExceptionType.cancel,
          stackTraceContains: kIsWeb
              ? 'test/test_suite_test.dart'
              : 'test/cancellation_tests.dart',
          matcher: allOf([
            isA<DioException>().having(
              (e) => e.error,
              'error',
              'cancelled',
            ),
            isA<DioException>().having(
              (e) => e.message,
              'message',
              'The request was manually cancelled by the user.',
            ),
          ]),
        ),
      );
    });

    test('cancel multiple requests with single token', () async {
      final token = CancelToken();

      final receiveSuccess1 = Completer();
      final receiveSuccess2 = Completer();
      final futures = [
        dio.get(
          '/drip-lines?delay=0&duration=5&numbytes=100',
          cancelToken: token,
          onReceiveProgress: (count, total) {
            if (!receiveSuccess1.isCompleted) {
              receiveSuccess1.complete();
            }
          },
        ),
        dio.get(
          '/drip-lines?delay=0&duration=5&numbytes=100',
          cancelToken: token,
          onReceiveProgress: (count, total) {
            if (!receiveSuccess2.isCompleted) {
              receiveSuccess2.complete();
            }
          },
        ),
      ];

      for (final future in futures) {
        expectLater(
          future,
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: kIsWeb
                ? 'test/test_suite_test.dart'
                : 'test/cancellation_tests.dart',
            matcher: allOf([
              isA<DioException>().having(
                (e) => e.error,
                'error',
                'cancelled',
              ),
              isA<DioException>().having(
                (e) => e.message,
                'message',
                'The request was manually cancelled by the user.',
              ),
            ]),
          ),
        );
      }

      await Future.wait([
        receiveSuccess1.future,
        receiveSuccess2.future,
      ]);

      token.cancel('cancelled');

      expect(receiveSuccess1.isCompleted, isTrue);
      expect(receiveSuccess2.isCompleted, isTrue);
      expect(token.isCancelled, isTrue);
      expect(
        token.cancelError,
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      );
    });

    // Regression: https://github.com/cfug/dio/issues/2170
    test(
      'not closing sockets with requests that have same hosts',
      () async {
        final token = CancelToken();
        await expectLater(dio.get('/get', cancelToken: token), completes);
        expectLater(dio.get('/drip?duration=3'), completes);
        Future.delayed(const Duration(seconds: 1), token.cancel);
      },
      testOn: '!browser',
    );
  });
}
