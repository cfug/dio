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

    test('emits receiveTimeout when no body bytes arrive after headers',
        () async {
      final stream = handleResponseStream(
        RequestOptions(
          receiveTimeout: const Duration(milliseconds: 100),
        ),
        ResponseBody(source.stream, 200),
      );

      await expectLater(
        stream,
        emitsInOrder([
          emitsError(
            matchesDioException(DioExceptionType.receiveTimeout),
          ),
          emitsDone,
        ]),
      );
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

    test('propagates downstream pause/resume as backpressure to the source',
        () async {
      // An observable upstream: its onPause/onResume fire only when its own
      // subscriber pauses — proving backpressure reaches the socket.
      var upstreamPaused = false;
      var upstreamResumed = false;
      final observableSource = StreamController<Uint8List>(
        onPause: () => upstreamPaused = true,
        onResume: () => upstreamResumed = true,
      );

      final stream = handleResponseStream(
        RequestOptions(),
        ResponseBody(observableSource.stream, 200),
      );

      final received = <int>[];
      late StreamSubscription<List<int>> downstream;
      var pausedOnce = false;
      downstream = stream.listen((data) {
        received.addAll(data);
        // The consumer is slow: apply backpressure once, then stay drained.
        if (!pausedOnce) {
          pausedOnce = true;
          downstream.pause();
        }
      });

      observableSource.add(Uint8List.fromList([1]));
      // Let the chunk travel downstream and the pause travel upstream.
      await Future.delayed(Duration.zero);

      expect(
        upstreamPaused,
        isTrue,
        reason: 'A downstream pause must propagate to the source. '
            'Otherwise the socket keeps draining into memory (OOM risk).',
      );

      // While paused, additional data must not reach the consumer.
      observableSource.add(Uint8List.fromList([2, 3]));
      await Future.delayed(Duration.zero);
      expect(received, [1], reason: 'No data should arrive while paused.');

      downstream.resume();
      // Resuming flows the buffered upstream chunk through.
      await Future.delayed(Duration.zero);
      expect(upstreamResumed, isTrue);
      expect(received, [1, 2, 3]);

      // Tear down without depending on done delivery.
      await downstream.cancel();
      await observableSource.close();
    });

    test('does not buffer an unbounded source when the consumer pauses',
        () async {
      // An async-generator source is backpressure-aware just like a socket:
      // it blocks at the yield when its subscriber pauses, and only produces
      // more data once resumed. This mirrors a large download where the
      // network keeps sending until the socket stops draining.
      var produced = 0;
      Stream<Uint8List> unboundedSource(int maxChunks) async* {
        for (var i = 0; i < maxChunks; i++) {
          produced++;
          yield Uint8List(1024);
        }
      }

      final stream = handleResponseStream(
        RequestOptions(),
        ResponseBody(unboundedSource(10000), 200),
      );

      final receivedLength = <int>[];
      late StreamSubscription<List<int>> downstream;
      downstream = stream.listen((data) {
        receivedLength.add(data.length);
        // Slow consumer applies backpressure after the first chunk.
        downstream.pause();
      });

      // Pump the event loop generously; a broken pipe would keep draining the
      // generator and buffer ~10MB. A correct one halts the source.
      for (var i = 0; i < 100; i++) {
        await Future.delayed(Duration.zero);
      }

      expect(
        produced,
        lessThan(5),
        reason: 'With backpressure the source must halt after the consumer '
            'pauses. Without it the entire response (~10MB here) would be '
            'buffered in memory, which triggers OOM on constrained devices.',
      );

      await downstream.cancel();
    });
  });
}
