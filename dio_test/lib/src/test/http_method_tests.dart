import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../util.dart';

void httpMethodTests(
  Dio Function(String baseUrl) create,
) {
  const data = {'content': 'I am payload'};

  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('HTTP method', () {
    group('constructed with String & query map', () {
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

      test(
        'GET with content',
        () async {
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
        },
        testOn: '!browser',
      );

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

    group('constructed with URI', () {
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
      test(
        'GET with content',
        () async {
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
        },
        testOn: '!browser',
      );

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
  });
}
