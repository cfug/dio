import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('requests', () {
    late Dio dio;

    setUp(() {
      dio = Dio();
      dio.options.baseUrl = 'https://httpbun.com/';
    });

    group('restful APIs', () {
      const data = {'content': 'I am payload'};

      test('HEAD', () async {
        final response = await dio.head(
          '/anything',
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
      });

      test('GET', () async {
        final response = await dio.get(
          '/get',
          queryParameters: {'id': '12', 'name': 'wendu'},
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'GET');
        expect(response.data['args'], {'id': '12', 'name': 'wendu'});
      });

      // TODO This is not supported on web, should we warn?
      test('GET with content', () async {
        final response = await dio.get(
          '/anything',
          queryParameters: {'id': '12', 'name': 'wendu'},
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'GET');
        expect(response.data['args'], {'id': '12', 'name': 'wendu'});
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      }, testOn: '!browser');

      test('POST', () async {
        final response = await dio.post(
          '/post',
          data: data,
          options: Options(contentType: Headers.jsonContentType),
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'POST');
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      });

      test('PUT', () async {
        final response = await dio.put(
          '/put',
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'PUT');
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      });

      test('PATCH', () async {
        final response = await dio.patch(
          '/patch',
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'PATCH');
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      });

      test('DELETE', () async {
        final response = await dio.delete(
          '/delete',
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'DELETE');
      });

      test('DELETE with content', () async {
        final response = await dio.delete(
          '/delete',
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'DELETE');
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      });
    });

    group('request with URI', () {
      const data = {'content': 'I am payload'};

      test('HEAD', () async {
        final response = await dio.headUri(
          Uri.parse('/anything'),
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
      });

      test('GET', () async {
        final response = await dio.getUri(
          Uri(path: '/get', queryParameters: {'id': '12', 'name': 'wendu'}),
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['args'], {'id': '12', 'name': 'wendu'});
      });

      // Not supported on web
      test('GET with content', () async {
        final response = await dio.getUri(
          Uri(
            path: '/anything',
            queryParameters: {'id': '12', 'name': 'wendu'},
          ),
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['args'], {'id': '12', 'name': 'wendu'});
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      }, testOn: '!browser');

      test('POST', () async {
        final response = await dio.postUri(
          Uri.parse('/post'),
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'POST');
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      });

      test('PUT', () async {
        final response = await dio.putUri(
          Uri.parse('/put'),
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'PUT');
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      });

      test('PATCH', () async {
        final response = await dio.patchUri(
          Uri.parse('/patch'),
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'PATCH');
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      });

      test('DELETE', () async {
        final response = await dio.deleteUri(
          Uri.parse('/delete'),
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'DELETE');
      });

      test('DELETE with content', () async {
        final response = await dio.deleteUri(
          Uri.parse('/delete'),
          data: data,
        );
        expect(response.statusCode, 200);
        expect(response.isRedirect, isFalse);
        expect(response.data['method'], 'DELETE');
        expect(response.data['json'], data);
        expect(
          response.data['headers']['Content-Type'],
          Headers.jsonContentType,
        );
      });
    });

    group('redirects', () {
      test('single', () async {
        final response = await dio.get(
          '/redirect',
          queryParameters: {'url': 'https://httpbun.com/get'},
          onReceiveProgress: (received, total) {
            // ignore progress
          },
        );
        expect(response.isRedirect, isTrue);

        if (!isWeb) {
          // Redirects are not supported in web.
          // Rhe browser will follow the redirects automatically.
          expect(response.redirects.length, 1);
          final ri = response.redirects.first;
          expect(ri.statusCode, 302);
          expect(ri.location.path, '/get');
          expect(ri.method, 'GET');
        }
      });

      test('multiple', () async {
        final response = await dio.get(
          '/redirect/3',
        );
        expect(response.isRedirect, isTrue);

        if (!isWeb) {
          // Redirects are not supported in web.
          // Rhe browser will follow the redirects automatically.
          expect(response.redirects.length, 3);
          final ri = response.redirects.first;
          expect(ri.statusCode, 302);
          expect(ri.method, 'GET');
        }
      });
    });

    group('status codes', () {
      for (final code in [400, 401, 404, 500, 503]) {
        test('$code', () async {
          expect(
            dio.get('/status/$code').catchError(
                (e) => throw (e as DioException).response!.statusCode!),
            throwsA(equals(code)),
          );
        });
      }
    });

    test('multi value headers', () async {
      final Response response = await dio.get(
        '/get',
        options: Options(
          headers: {
            'x-multi-value-request-header': ['value1', 'value2'],
          },
        ),
      );
      expect(response.statusCode, 200);
      expect(response.isRedirect, isFalse);
      expect(
        response.data['headers']['X-Multi-Value-Request-Header'],
        // TODO we have a diff here between browser and non-browser
        equals('value1, value2'),
      );
    });

    group('generic parameters', () {
      test('default (Map)', () async {
        final response = await dio.get('/get');
        expect(response.data, isA<Map>());
        expect(response.data, isNotEmpty);
      });

      test('Map', () async {
        final response = await dio.get<Map>('/get');
        expect(response.data, isA<Map>());
        expect(response.data, isNotEmpty);
      });

      test('String', () async {
        final response = await dio.get<String>('/get');
        expect(response.data, isA<String>());
        expect(response.data, isNotEmpty);
      });

      test('List', () async {
        final response = await dio.post<List>(
          '/payload',
          data: '[1,2,3]',
        );
        expect(response.data, isA<List>());
        expect(response.data, isNotEmpty);
        expect(response.data![0], 1);
      });
    });

    // Test that browsers can correctly classify requests as
    // either "simple" or "preflighted". Reference:
    // https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#simple_requests
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
        expect(() async {
          final _ = await dio.get(
            '/status/418',
            options: Options(
              headers: {
                'x-request-header': 'value',
              },
            ),
          );
        }, throwsDioExceptionConnectionError);
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
        expect(() async {
          final _ = await dio.post(
            '/status/418',
            data: 'body text',
            options: Options(
              validateStatus: (status) => true,
              contentType: Headers.textPlainContentType,
              sendTimeout: Duration(seconds: 1),
            ),
          );
        }, throwsDioExceptionConnectionError);
      });

      test('POST with onSendProgress is preflighted', () async {
        // If there is a preflight (OPTIONS) request, the server fails it
        // by responding with status 418. This fails CORS, so the browser
        // never sends the main request and this code throws.
        expect(() async {
          final _ = await dio.post(
            '/status/418',
            data: 'body text',
            options: Options(
              validateStatus: (status) => true,
              contentType: Headers.textPlainContentType,
            ),
            onSendProgress: (_, __) {},
          );
        }, throwsDioExceptionConnectionError);
      });
    }, testOn: 'browser');
  });
}
