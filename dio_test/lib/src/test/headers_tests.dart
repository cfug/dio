import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../util.dart';

void headerTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('headers', () {
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
        equals('value1, value2'),
      );
    });

    test('header value types implicit support', () async {
      final res = await dio.post(
        '/post',
        data: 'TEST',
        options: Options(
          headers: {
            'ListKey': ['1', '2'],
            'StringKey': '1',
            'NumKey': 2,
            'BooleanKey': false,
          },
        ),
      );
      final content = res.data.toString();
      expect(content, contains('TEST'));
      expect(content, contains('Listkey: 1, 2'));
      expect(content, contains('Stringkey: 1'));
      expect(content, contains('Numkey: 2'));
      expect(content, contains('Booleankey: false'));
    });

    test(
      'headers are kept after redirects',
      () async {
        dio.options.headers.putIfAbsent('x-test-base', () => 'test-base');

        final response = await dio.get(
          '/redirect/3',
          options: Options(headers: {'x-test-header': 'test-value'}),
        );
        expect(response.isRedirect, isTrue);
        // The returned headers are uppercased by the server.
        expect(
          response.data['headers']['X-Test-Base'],
          equals('test-base'),
        );
        expect(
          response.data['headers']['X-Test-Header'],
          equals('test-value'),
        );
        // The sent headers are still lowercase.
        expect(
          response.requestOptions.headers['x-test-base'],
          equals('test-base'),
        );
        expect(
          response.requestOptions.headers['x-test-header'],
          equals('test-value'),
        );
      },
      testOn: 'vm',
    );

    test('default content-type', () async {
      final r1 = await dio.get('/get');
      expect(
        r1.requestOptions.headers[Headers.contentTypeHeader],
        null,
      );

      final r2 = await dio.get(
        '/get',
        options: Options(contentType: Headers.jsonContentType),
      );
      expect(
        r2.requestOptions.headers[Headers.contentTypeHeader],
        Headers.jsonContentType,
      );

      final r3 = await dio.get(
        '/get',
        options: Options(
          headers: {Headers.contentTypeHeader: Headers.jsonContentType},
        ),
      );
      expect(
        r3.requestOptions.headers[Headers.contentTypeHeader],
        Headers.jsonContentType,
      );

      final r4 = await dio.post('/post', data: '');
      expect(
        r4.requestOptions.headers[Headers.contentTypeHeader],
        Headers.jsonContentType,
      );

      final r5 = await dio.get(
        '/get',
        options: Options(
          // Final result should respect this.
          contentType: Headers.textPlainContentType,
          // Rather than this.
          headers: {
            Headers.contentTypeHeader: Headers.formUrlEncodedContentType,
          },
        ),
      );
      expect(
        r5.requestOptions.headers[Headers.contentTypeHeader],
        Headers.textPlainContentType,
      );

      final r6 = await dio.get(
        '/get',
        data: '',
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {Headers.contentTypeHeader: Headers.jsonContentType},
        ),
      );
      expect(
        r6.requestOptions.headers[Headers.contentTypeHeader],
        Headers.formUrlEncodedContentType,
      );

      // Update the base option.
      dio.options.contentType = Headers.textPlainContentType;
      final r7 = await dio.get('/get');
      expect(
        r7.requestOptions.headers[Headers.contentTypeHeader],
        Headers.textPlainContentType,
      );

      final r8 = await dio.get(
        '/get',
        options: Options(contentType: Headers.jsonContentType),
      );
      expect(
        r8.requestOptions.headers[Headers.contentTypeHeader],
        Headers.jsonContentType,
      );

      final r9 = await dio.get(
        '/get',
        options: Options(
          headers: {Headers.contentTypeHeader: Headers.jsonContentType},
        ),
      );
      expect(
        r9.requestOptions.headers[Headers.contentTypeHeader],
        Headers.jsonContentType,
      );

      final r10 = await dio.post('/post', data: FormData());
      expect(
        r10.requestOptions.contentType,
        startsWith(Headers.multipartFormDataContentType),
      );

      // Regression: https://github.com/cfug/dio/issues/1834
      final r11 = await dio.get('/payload');
      expect(r11.data, '');
      final r12 = await dio.get<Map>('/payload');
      expect(r12.data, null);
      final r13 = await dio.get<Map<String, Object>>('/payload');
      expect(r13.data, null);
    });
  });
}
