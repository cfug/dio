import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/src/response/response_stream_handler.dart';
import 'package:dio_test/util.dart';
import 'package:test/test.dart';

void main() {
  group(handleResponseStream, () {
    late StreamController<Uint8List> source;

    setUp(() {
      source = StreamController<Uint8List>();
    });

    test('completes', () async {
      final stream = handleResponseStream(
        RequestOptions(),
        ResponseBody(
          source.stream,
          200,
        ),
      );

      expectLater(
        stream,
        emitsInOrder([
          Uint8List.fromList([0]),
          Uint8List.fromList([1, 2]),
          emitsDone,
        ]),
      );

      source.add(Uint8List.fromList([0]));
      source.add(Uint8List.fromList([1, 2]));
      source.close();
    });

    test('unsubscribes from source on cancel', () async {
      final cancelToken = CancelToken();
      final stream = handleResponseStream(
        RequestOptions(
          cancelToken: cancelToken,
        ),
        ResponseBody(
          source.stream,
          200,
        ),
      );

      expectLater(
        stream,
        emitsInOrder([
          Uint8List.fromList([0]),
          emitsError(
            matchesDioException(
              DioExceptionType.cancel,
              stackTraceContains: 'test/response/response_stream_test.dart',
            ),
          ),
          emitsDone,
        ]),
      );

      source.add(Uint8List.fromList([0]));

      expect(source.hasListener, isTrue);
      cancelToken.cancel();

      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(source.hasListener, isFalse);
      });
    });

    test('sends progress with total', () async {
      int count = 0;
      int total = 0;

      final stream = handleResponseStream(
        RequestOptions(
          onReceiveProgress: (c, t) {
            count = c;
            total = t;
          },
        ),
        ResponseBody(
          source.stream,
          200,
          headers: {
            Headers.contentLengthHeader: ['6'],
          },
        ),
      );

      expectLater(
        stream,
        emitsInOrder([
          Uint8List.fromList([0]),
          Uint8List.fromList([1, 2]),
          Uint8List.fromList([3, 4, 5]),
          emitsDone,
        ]),
      );

      source.add(Uint8List.fromList([0]));
      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(count, 1);
        expect(total, 6);
      });

      source.add(Uint8List.fromList([1, 2]));
      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(count, 3);
        expect(total, 6);
      });

      source.add(Uint8List.fromList([3, 4, 5]));
      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(count, 6);
        expect(total, 6);
      });

      source.close();
    });

    test('sends progress without total', () async {
      int count = 0;
      int total = 0;

      final stream = handleResponseStream(
        RequestOptions(
          onReceiveProgress: (c, t) {
            count = c;
            total = t;
          },
        ),
        ResponseBody(
          source.stream,
          200,
        ),
      );

      expectLater(
        stream,
        emitsInOrder([
          Uint8List.fromList([0]),
          Uint8List.fromList([1, 2]),
          Uint8List.fromList([3, 4, 5]),
          emitsDone,
        ]),
      );

      source.add(Uint8List.fromList([0]));
      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(count, 1);
        expect(total, -1);
      });

      source.add(Uint8List.fromList([1, 2]));
      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(count, 3);
        expect(total, -1);
      });

      source.add(Uint8List.fromList([3, 4, 5]));
      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(count, 6);
        expect(total, -1);
      });

      source.close();
    });

    test('emits error on source error', () async {
      final stream = handleResponseStream(
        RequestOptions(),
        ResponseBody(
          source.stream,
          200,
        ),
      );

      expectLater(
        stream,
        emitsInOrder([
          Uint8List.fromList([0]),
          emitsError(isA<FormatException>()),
          emitsDone,
        ]),
      );

      source.add(Uint8List.fromList([0]));
      source.addError(const FormatException());
      source.close();

      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(source.hasListener, isFalse);
      });
    });

    test('emits error on receiveTimeout', () async {
      final stream = handleResponseStream(
        RequestOptions(
          receiveTimeout: const Duration(milliseconds: 100),
        ),
        ResponseBody(
          source.stream,
          200,
        ),
      );

      expectLater(
        stream,
        emitsInOrder([
          Uint8List.fromList([0]),
          Uint8List.fromList([1]),
          emitsError(
            matchesDioException(
              DioExceptionType.receiveTimeout,
              stackTraceContains: 'test/response/response_stream_test.dart',
            ),
          ),
          emitsDone,
        ]),
      );

      source.add(Uint8List.fromList([0]));
      await Future.delayed(const Duration(milliseconds: 90), () {
        source.add(Uint8List.fromList([1]));
      });
      await Future.delayed(const Duration(milliseconds: 110), () {
        source.add(Uint8List.fromList([2]));
      });

      await Future.delayed(const Duration(milliseconds: 100), () {
        expect(source.hasListener, isFalse);
      });
    });

    test('not watching the receive timeout after cancelled', () async {
      bool timerCancelled = false;
      final cancelToken = CancelToken();
      final stream = handleResponseStream(
        RequestOptions(
          cancelToken: cancelToken,
          receiveTimeout: const Duration(seconds: 1),
        ),
        ResponseBody(source.stream, 200),
        onReceiveTimeoutWatchCancelled: () => timerCancelled = true,
      );
      expect(source.hasListener, isTrue);
      expectLater(
        stream,
        emitsInOrder([
          Uint8List.fromList([0]),
          emitsError(
            matchesDioException(
              DioExceptionType.cancel,
              stackTraceContains: 'test/response/response_stream_test.dart',
            ),
          ),
          emitsDone,
        ]),
      );
      source.add(Uint8List.fromList([0]));
      cancelToken.cancel();
      await Future.microtask(() {});
      expect(timerCancelled, isTrue);
    });
  });
}
