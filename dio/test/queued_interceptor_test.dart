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
