import 'package:dio/dio.dart';
import 'package:dio_test/util.dart';
import 'package:test/test.dart';

// Test that browsers can correctly classify requests as
// either "simple" or "preflighted". Reference:
// https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests
void main() {
  late Dio dio;

  setUpAll(() {
    dio = Dio(BaseOptions(baseUrl: 'https://httpbun.com/'));
  });

  group('CORS preflight', () {
    test('empty GET is not preflighted', () async {
      // If there is no preflight (OPTIONS) request, the main request
      // successfully completes with status 418.
      final response = await dio.get(
        '/status/418',
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      expect(response.statusCode, 418);
    });

    test('GET with custom headers is preflighted', () async {
      // If there is a preflight (OPTIONS) request, the server fails it
      // by responding with status 418. This fails CORS, so the browser
      // never sends the main request and this code throws.
      expect(
        () async {
          final _ = await dio.get(
            '/status/418',
            options: Options(
              headers: {
                'x-request-header': 'value',
              },
            ),
          );
        },
        throwsDioException(
          DioExceptionType.connectionError,
          stackTraceContains: 'test/request_integration_test.dart',
        ),
      );
    });

    test('POST with text body is not preflighted', () async {
      // If there is no preflight (OPTIONS) request, the main request
      // successfully completes with status 418.
      final response = await dio.post(
        '/status/418',
        data: 'body text',
        options: Options(
          validateStatus: (status) => true,
          contentType: Headers.textPlainContentType,
        ),
      );
      expect(response.statusCode, 418);
    });

    test('POST with sendTimeout is preflighted', () async {
      // If there is a preflight (OPTIONS) request, the server fails it
      // by responding with status 418. This fails CORS, so the browser
      // never sends the main request and this code throws.
      expect(
        () async {
          final _ = await dio.post(
            '/status/418',
            data: 'body text',
            options: Options(
              validateStatus: (status) => true,
              contentType: Headers.textPlainContentType,
              sendTimeout: Duration(seconds: 1),
            ),
          );
        },
        throwsDioException(
          DioExceptionType.connectionError,
          stackTraceContains: 'test/request_integration_test.dart',
        ),
      );
    });

    test('POST with onSendProgress is preflighted', () async {
      // If there is a preflight (OPTIONS) request, the server fails it
      // by responding with status 418. This fails CORS, so the browser
      // never sends the main request and this code throws.
      expect(
        () async {
          final _ = await dio.post(
            '/status/418',
            data: 'body text',
            options: Options(
              validateStatus: (status) => true,
              contentType: Headers.textPlainContentType,
            ),
            onSendProgress: (_, __) {},
          );
        },
        throwsDioException(
          DioExceptionType.connectionError,
          stackTraceContains: 'test/request_integration_test.dart',
        ),
      );
    });
  }, testOn: 'browser');
}
