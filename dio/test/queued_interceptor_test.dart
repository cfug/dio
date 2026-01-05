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
