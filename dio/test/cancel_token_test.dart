import 'package:dio/dio.dart';
import 'package:dio/src/adapters/io_adapter.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mock/http_mock.mocks.dart';

void main() {
  group(CancelToken, () {
    test('cancel returns the correct DioException', () async {
      final token = CancelToken();
      const reason = 'cancel';

      expectLater(token.whenCancel, completion((error) {
        return error is DioException &&
            error.type == DioExceptionType.cancel &&
            error.error == reason;
      }));
      token.requestOptions = RequestOptions();
      token.cancel(reason);
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
          throwsA((error) =>
              error is DioError &&
              error.type == DioErrorType.cancel &&
              error.error == reason),
        );
      }

      await Future.delayed(const Duration(milliseconds: 50));
      token.cancel(reason);

      expect(requests, hasLength(2));

      try {
        await Future.wait(futures);
      } catch (_) {
        // ignore, just waiting here till all futures are completed
      }

      for (final request in requests) {
        verify(request.abort()).called(1);
      }
    });
  });
}
