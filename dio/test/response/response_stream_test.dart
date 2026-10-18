import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/src/response/response_stream_handler.dart';
import 'package:dio_test/util.dart';
import 'package:test/test.dart';

void main() {
  group('ResponseType.stream consumer cancellation', () {
    test('first cancels the adapter response stream', () async {
      var cancelCount = 0;
      final source = StreamController<Uint8List>(
        onCancel: () => cancelCount++,
      );
      final cancelToken = CancelToken();
      final dio = Dio()
        ..httpClientAdapter =
            _StreamingAdapter(ResponseBody(source.stream, 200));
      addTearDown(() async {
        cancelToken.cancel();
        await Future<void>.delayed(Duration.zero);
        await source.close();
        dio.close();
      });

      final response = await dio.get<ResponseBody>(
        'https://example.test/stream',
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );
      final first = response.data!.stream.first;
      source.add(Uint8List.fromList([1]));

      expect(await first, [1]);
      expect(source.hasListener, isFalse);
      expect(cancelCount, 1);
    });

    for (final pauseBeforeCancel in [false, true]) {
      test(
          'cancel releases the response${pauseBeforeCancel ? ' while paused' : ''}',
          () async {
        final source = StreamController<Uint8List>();
        var closeCount = 0;
        final progress = <int>[];
        final cancelToken = CancelToken();
        final dio = Dio()
          ..httpClientAdapter = _StreamingAdapter(
            ResponseBody(source.stream, 200, onClose: () => closeCount++),
          );
        addTearDown(() async {
          cancelToken.cancel();
          await Future<void>.delayed(Duration.zero);
          await source.close();
          dio.close();
        });

        final response = await dio.get<ResponseBody>(
          'https://example.test/stream',
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: const Duration(milliseconds: 30),
          ),
          cancelToken: cancelToken,
          onReceiveProgress: (count, _) => progress.add(count),
        );
        final subscription = response.data!.stream.listen((_) {});
        source.add(Uint8List.fromList([1]));
        await Future<void>.delayed(Duration.zero);
        if (pauseBeforeCancel) {
          subscription.pause();
          expect(source.isPaused, isTrue);
        }

        await subscription.cancel();
        expect(source.hasListener, isFalse);
        expect(closeCount, 1);

        source.add(Uint8List.fromList([2]));
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(progress, [1]);
        expect(closeCount, 1, reason: 'The receive timer must not fire.');

        cancelToken.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(
          closeCount,
          1,
          reason: 'Later cancellation must not close again.',
        );
      });
    }

    test('cancel waits for asynchronous adapter cleanup', () async {
      final cleanupStarted = Completer<void>();
      final cleanupFinished = Completer<void>();
      final source = StreamController<Uint8List>(
        onCancel: () {
          cleanupStarted.complete();
          return cleanupFinished.future;
        },
      );
      final cancelToken = CancelToken();
      final dio = Dio()
        ..httpClientAdapter =
            _StreamingAdapter(ResponseBody(source.stream, 200));
      addTearDown(() async {
        if (!cleanupFinished.isCompleted) {
          cleanupFinished.complete();
        }
        cancelToken.cancel();
        await Future<void>.delayed(Duration.zero);
        await source.close();
        dio.close();
      });
      final response = await dio.get<ResponseBody>(
        'https://example.test/stream',
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );
      var cancellationCompleted = false;
      final cancellation = response.data!.stream.listen((_) {}).cancel().then(
            (_) => cancellationCompleted = true,
          );

      await Future<void>.delayed(Duration.zero);
      expect(cleanupStarted.isCompleted, isTrue);
      expect(cancellationCompleted, isFalse);
      cleanupFinished.complete();
      await cancellation;
      expect(cancellationCompleted, isTrue);
    });

    for (final withError in [false, true]) {
      test(
          'late token cancellation after source ${withError ? 'error' : 'done'}',
          () async {
        var sourceCancelCount = 0;
        var closeCount = 0;
        final source = StreamController<Uint8List>(
          onCancel: () => sourceCancelCount++,
        );
        final cancelToken = CancelToken();
        final dio = Dio()
          ..httpClientAdapter = _StreamingAdapter(
            ResponseBody(source.stream, 200, onClose: () => closeCount++),
          );
        addTearDown(() async {
          await source.close();
          dio.close();
        });
        final response = await dio.get<ResponseBody>(
          'https://example.test/stream',
          options: Options(responseType: ResponseType.stream),
          cancelToken: cancelToken,
        );
        final received = response.data!.stream.toList();
        if (withError) {
          source.addError(StateError('response failed'));
          await expectLater(received, throwsA(isA<StateError>()));
        } else {
          source.add(Uint8List.fromList([1]));
          source.close();
          expect(
            await received,
            [
              Uint8List.fromList([1]),
            ],
          );
        }

        expect(sourceCancelCount, 1);
        expect(closeCount, 0);
        cancelToken.cancel();
        await Future<void>.delayed(Duration.zero);
        expect(sourceCancelCount, 1);
        expect(closeCount, 0);
      });
    }
  });

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
      // Model a socket-like source with an explicit production loop that
      // yields control between chunks and stops once the source subscription
      // is paused. This is platform-agnostic (unlike an `async*` generator,
      // whose pause semantics are not honored under dart2wasm) and directly
      // mirrors a network socket that keeps pushing until backpressure arrives.
      final source = StreamController<Uint8List>();
      final stream = handleResponseStream(
        RequestOptions(),
        ResponseBody(source.stream, 200),
      );

      late StreamSubscription<List<int>> downstream;
      downstream = stream.listen((_) {
        // Slow consumer applies backpressure after the first chunk.
        downstream.pause();
      });

      // The source keeps pushing data; a correct pipe pauses the subscription
      // and the loop observes it via [StreamController.isPaused].
      var produced = 0;
      for (var i = 0; i < 10000; i++) {
        if (source.isPaused) {
          break;
        }
        produced++;
        source.add(Uint8List(1024));
        // Let the event loop deliver the chunk and propagate the pause.
        await Future.delayed(Duration.zero);
      }

      expect(
        produced,
        lessThan(5),
        reason: 'With backpressure the source must halt after the consumer '
            'pauses. Without it the entire response (~10MB here) would be '
            'buffered in memory, which triggers OOM on constrained devices.',
      );

      // Clear the backpressure so the upstream subscription can drain and
      // the source can close, then tear down.
      downstream.resume();
      await downstream.cancel();
      await source.close();
    });
  });
}

class _StreamingAdapter implements HttpClientAdapter {
  _StreamingAdapter(this.response);

  final ResponseBody response;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      response;

  @override
  void close({bool force = false}) {}
}
