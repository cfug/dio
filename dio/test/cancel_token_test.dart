import 'dart:typed_data' show Uint8List;

import 'package:dio/dio.dart';
import 'package:dio/src/adapters/io_adapter.dart';
import 'package:dio_test/util.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mock/http_mock.mocks.dart';

void main() {
  group(CancelToken, () {
    test('cancel returns the correct DioException', () async {
      final token = CancelToken();
      const reason = 'cancel';

      expectLater(
        token.whenCancel,
        completion(
          matchesDioException(DioExceptionType.cancel),
        ),
      );
      token.requestOptions = RequestOptions();
      token.cancel(reason);
      token.cancel('after cancelled');
      expect(token.cancelError?.error, reason);
    });

    test('cancel without use does not throw (#1765)', () async {
      CancelToken().cancel();
    });

    test('cancels multiple requests', () async {
      final client = MockHttpClient();
      final token = CancelToken();
      const reason = 'cancel';
      final dio = Dio()
        ..httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () => client,
        );

      final requests = <MockHttpClientRequest>[];
      when(client.openUrl(any, any)).thenAnswer((_) async {
        final request = MockHttpClientRequest();
        requests.add(request);
        when(request.close()).thenAnswer((_) async {
          final response = MockHttpClientResponse();
          when(response.headers).thenReturn(MockHttpHeaders());
          when(response.statusCode).thenReturn(200);
          await Future.delayed(const Duration(milliseconds: 200));
          return response;
        });
        return request;
      });

      final futures = [
        dio.get('https://pub.dev', cancelToken: token),
        dio.get('https://pub.dev', cancelToken: token),
      ];

      for (final future in futures) {
        expectLater(
          future,
          throwsDioException(
            DioExceptionType.cancel,
            matcher: isA<DioException>().having(
              (e) => e.error,
              'error',
              reason,
            ),
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));
      token.cancel(reason);

      expect(requests, hasLength(2));

      try {
        await Future.wait(futures);
      } catch (_) {
        // ignore, just waiting here till all futures are completed.
      }

      for (final request in requests) {
        verify(request.abort()).called(1);
      }
    });

    test('throws if cancelled before making requests', () async {
      final cancelToken = CancelToken();

      bool walkThroughHandlers = false;
      final interceptor = QueuedInterceptorsWrapper(
        onRequest: (options, handler) {
          walkThroughHandlers = true;
          handler.next(options);
        },
      );

      cancelToken.cancel();
      final dio = Dio();
      dio.interceptors.add(interceptor);
      await expectLater(
        () => dio.get('/test', cancelToken: cancelToken),
        throwsDioException(
          DioExceptionType.cancel,
          matcher: isA<DioException>(),
        ),
      );
      expect(walkThroughHandlers, isFalse);
    });
  });

  test(
    'deallocates HttpClientRequest',
    () async {
      final client = MockHttpClient();
      final dio = Dio();
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () => client,
      );
      final token = CancelToken();
      final requests = <MockHttpClientRequest>{};
      final requestsReferences = <WeakReference<MockHttpClientRequest>>{};
      when(client.openUrl(any, any)).thenAnswer((_) async {
        final request = MockHttpClientRequest();
        requests.add(request);
        requestsReferences.add(WeakReference(request));
        when(request.close()).thenAnswer((_) async {
          final response = MockHttpClientResponse();
          when(response.headers).thenReturn(MockHttpHeaders());
          when(response.statusCode).thenReturn(200);
          when(response.reasonPhrase).thenReturn('OK');
          when(response.isRedirect).thenReturn(false);
          when(response.redirects).thenReturn([]);
          when(response.cast())
              .thenAnswer((_) => const Stream<Uint8List>.empty());
          await Future.delayed(const Duration(milliseconds: 200));
          return response;
        });
        when(request.abort()).thenAnswer((realInvocation) {
          requests.remove(request);
        });
        return request;
      });

      final futures = [
        dio.get('https://does.not.exists', cancelToken: token),
        dio.get('https://does.not.exists', cancelToken: token),
      ];
      for (final future in futures) {
        expectLater(
          future,
          throwsDioException(DioExceptionType.cancel),
        );
      }

      // Opening requests.
      await Future.delayed(const Duration(milliseconds: 100));
      token.cancel();
      // Aborting requests.
      await Future.delayed(const Duration(seconds: 1));
      expect(requests, isEmpty);

      try {
        await Future.wait(futures);
      } catch (_) {
        // Waiting here until all futures are completed.
      }
      expect(requests, isEmpty);
      expect(requestsReferences, hasLength(2));

      // GC.
      produceGarbage();
      await Future.delayed(const Duration(seconds: 1));
      expect(requestsReferences.every((e) => e.target == null), isTrue);
    },
    tags: ['gc'],
    testOn: 'vm',
  );
}
