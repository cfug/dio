import 'dart:async';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test(
      'QueuedInterceptor should catch synchronous errors in onRequest and reject handler',
      () async {
    final dio = Dio();
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          throw Exception('Oops');
        },
      ),
    );
    dio.httpClientAdapter = _MockAdapter();

    try {
      await dio.get('https://example.com').timeout(const Duration(seconds: 1));
      fail('Should have failed');
    } on DioException catch (e) {
      expect(e.error, isA<Exception>());
      expect(e.error.toString(), contains('Oops'));
    } catch (e) {
      fail('Thrown unexpected error: $e');
    }
  });

  test(
      'QueuedInterceptor should catch synchronous errors in onResponse and reject handler',
      () async {
    final dio = Dio();
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onResponse: (response, handler) {
          throw Exception('Oops in Response');
        },
      ),
    );
    dio.httpClientAdapter = _MockAdapter();

    try {
      await dio.get('https://example.com').timeout(const Duration(seconds: 1));
      fail('Should have failed');
    } on DioException catch (e) {
      expect(e.error, isA<Exception>());
      expect(e.error.toString(), contains('Oops in Response'));
    } catch (e) {
      fail('Thrown unexpected error: $e');
    }
  });

  test(
      'QueuedInterceptor should catch synchronous errors in onError and pass to next handler',
      () async {
    final dio = Dio();
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onError: (error, handler) {
          throw Exception('Oops in Error Handler');
        },
      ),
    );
    dio.httpClientAdapter = _FailingMockAdapter();

    try {
      await dio.get('https://example.com').timeout(const Duration(seconds: 1));
      fail('Should have failed');
    } on DioException catch (e) {
      expect(e.error, isA<Exception>());
      expect(e.error.toString(), contains('Oops in Error Handler'));
    } catch (e) {
      fail('Thrown unexpected error: $e');
    }
  });

  test('Reproduces issue #2138 scenario with QueuedInterceptor', () async {
    final dio = Dio();

    dio.interceptors.add(_QueuedInterceptorWithError());
    dio.httpClientAdapter = _MockAdapter();

    try {
      await dio.get('https://google.com').timeout(const Duration(seconds: 1));
      fail('Should have failed');
    } on DioException catch (e) {
      expect(e.error, isA<Exception>());
      expect(e.error.toString(), contains('some error'));
    } catch (e) {
      fail('Thrown unexpected error: $e');
    }
  });

  test(
      'QueuedInterceptor should not stall the queue when the active request is '
      'cancelled mid-callback', () async {
    final dio = Dio();
    dio.httpClientAdapter = _MockAdapter();

    final tokenA = CancelToken();
    final aOnRequestStarted = Completer<void>();

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          // Simulate a slow async step (e.g. refreshing auth) that has NOT yet
          // called handler.next when the request is cancelled.
          if (options.path.contains('reqA')) {
            aOnRequestStarted.complete();
            await Future.delayed(const Duration(seconds: 5));
          }
          handler.next(options);
        },
      ),
    );

    // A becomes the active queued task; it is expected to be cancelled.
    final futureA = dio.get(
      'https://example.com/test?reqA',
      cancelToken: tokenA,
    );
    // Install the rejection expectation up-front so its error listener is
    // attached to [futureA] before the cancellation propagates. Without this
    // the unawaited rejection would leak as an unhandled async error into
    // subsequent tests; the returned future is awaited at the end of the
    // test so the assertion is actually verified.
    final aRejected = expectLater(
      futureA,
      throwsA(
        isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.cancel),
      ),
    );

    await aOnRequestStarted.future;

    // B is an independent request with NO cancel token, queued behind A on the
    // same QueuedInterceptor.
    final futureB = dio.get('https://example.com/test?reqB');

    // Cancel A while it is the active queued task.
    tokenA.cancel('cancel A');

    // B must complete promptly; if the queue stalled this times out.
    final response = await futureB.timeout(
      const Duration(seconds: 2),
      onTimeout: () => throw StateError(
        'Queue stalled: a non-cancelled request never ran after the active '
        'queued task was cancelled.',
      ),
    );
    expect(response.statusCode, 200);

    await aRejected;
  });

  test(
      'QueuedInterceptor should not stall the response queue when the active '
      'response is cancelled mid-callback', () async {
    final dio = Dio();
    dio.httpClientAdapter = _MockAdapter();

    final tokenA = CancelToken();
    final aOnResponseStarted = Completer<void>();

    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onResponse: (response, handler) async {
          if (response.requestOptions.path.contains('reqA')) {
            aOnResponseStarted.complete();
            await Future.delayed(const Duration(seconds: 5));
          }
          handler.next(response);
        },
      ),
    );

    final futureA = dio.get(
      'https://example.com/test?reqA',
      cancelToken: tokenA,
    );
    // See test above: install the rejection assertion up-front so its
    // listener is attached before cancellation, then await it at the end.
    final aRejected = expectLater(
      futureA,
      throwsA(
        isA<DioException>()
            .having((e) => e.type, 'type', DioExceptionType.cancel),
      ),
    );

    await aOnResponseStarted.future;

    final futureB = dio.get('https://example.com/test?reqB');
    tokenA.cancel('cancel A');

    final response = await futureB.timeout(
      const Duration(seconds: 2),
      onTimeout: () => throw StateError(
        'Response queue stalled: a non-cancelled request never ran after the '
        'active queued response task was cancelled.',
      ),
    );
    expect(response.statusCode, 200);

    await aRejected;
  });
}

class _MockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FailingMockAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      message: 'Mock request failed',
    );
  }

  @override
  void close({bool force = false}) {}
}

class _QueuedInterceptorWithError extends QueuedInterceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    throw Exception('some error');
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    handler.next(err);
  }
}
