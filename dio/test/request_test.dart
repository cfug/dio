@TestOn('vm')
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  setUp(startServer);

  tearDown(stopServer);

  group('requests', () {
    late Dio dio;
    setUp(() {
      dio = Dio();
      dio.options
        ..baseUrl = serverUrl.toString()
        ..connectTimeout = Duration(seconds: 1)
        ..receiveTimeout = Duration(seconds: 5)
        ..headers = {'User-Agent': 'dartisan'};
      dio.interceptors.add(
        LogInterceptor(
          responseBody: true,
          requestBody: true,
          logPrint: (log) => {
            // ignore log
          },
        ),
      );
    });
    test('restful APIs', () async {
      Response response;
      // test get
      response = await dio.get(
        '/test',
        queryParameters: {'id': '12', 'name': 'wendu'},
      );
      expect(response.statusCode, 200);
      expect(response.isRedirect, false);
      expect(response.data['query'], equals('id=12&name=wendu'));
      expect(response.headers.value('single'), equals('value'));

      const map = {'content': 'I am playload'};
      // test post
      response = await dio.post(
        '/test',
        data: map,
        options: Options(contentType: Headers.jsonContentType),
      );
      expect(response.data['method'], 'POST');
      expect(response.data['body'], jsonEncode(map));

      // test put
      response = await dio.put(
        '/test',
        data: map,
        options: Options(contentType: Headers.jsonContentType),
      );
      expect(response.data['method'], 'PUT');
      expect(response.data['body'], jsonEncode(map));

      // test patch
      response = await dio.patch(
        '/test',
        data: map,
        options: Options(contentType: Headers.jsonContentType),
      );
      expect(response.data['method'], 'PATCH');
      expect(response.data['body'], jsonEncode(map));

      // test head
      response = await dio.delete('/test', data: map);
      expect(response.data['method'], 'DELETE');
      expect(response.data['path'], '/test');

      // error test
      expect(
        dio
            .get('/error')
            .catchError((e) => throw (e as DioException).response!.statusCode!),
        throwsA(equals(400)),
      );

      // redirect test
      response = await dio.get(
        '/redirect',
        onReceiveProgress: (received, total) {
          // ignore progress
        },
      );
      expect(response.isRedirect, true);
      expect(response.redirects.length, 1);
      final ri = response.redirects.first;
      expect(ri.statusCode, 302);
      expect(ri.method, 'GET');
    });

    test('multi value headers', () async {
      final Response response = await dio.get(
        '/multi-value-header',
        options: Options(
          headers: {
            'x-multi-value-request-header': ['value1', 'value2'],
          },
        ),
      );
      expect(response.statusCode, 200);
      expect(
        response.headers.value('x-multi-value-request-header-echo'),
        equals('value1, value2'),
      );
    });

    test('request with URI', () async {
      Response response;

      // test get
      response = await dio.getUri(
        Uri(path: '/test', queryParameters: {'id': '12', 'name': 'wendu'}),
      );
      expect(response.statusCode, 200);
      expect(response.isRedirect, false);
      expect(response.data['query'], equals('id=12&name=wendu'));
      expect(response.headers.value('single'), equals('value'));

      const map = {'content': 'I am playload'};

      // test post
      response = await dio.postUri(
        Uri(path: '/test'),
        data: map,
        options: Options(contentType: Headers.jsonContentType),
      );
      expect(response.data['method'], 'POST');
      expect(response.data['body'], jsonEncode(map));

      // test put
      response = await dio.putUri(
        Uri(path: '/test'),
        data: map,
        options: Options(contentType: Headers.jsonContentType),
      );
      expect(response.data['method'], 'PUT');
      expect(response.data['body'], jsonEncode(map));

      // test patch
      response = await dio.patchUri(
        Uri(path: '/test'),
        data: map,
        options: Options(contentType: Headers.jsonContentType),
      );
      expect(response.data['method'], 'PATCH');
      expect(response.data['body'], jsonEncode(map));

      // test head
      response = await dio.deleteUri(Uri(path: '/test'), data: map);
      expect(response.data['method'], 'DELETE');
      expect(response.data['path'], '/test');
    });

    test('redirect', () async {
      Response response;
      response = await dio.get('/redirect');
      expect(response.isRedirect, true);
      expect(response.redirects.length, 1);
      final ri = response.redirects.first;
      expect(ri.statusCode, 302);
      expect(ri.method, 'GET');
      expect(ri.location.path, '/');
    });

    test('generic parameters', () async {
      Response response;

      // default is "Map"
      response = await dio.get('/test');
      expect(response.data, isA<Map>());

      // get response as `string`
      response = await dio.get<String>('/test');
      expect(response.data, isA<String>());

      // get response as `Map`
      response = await dio.get<Map>('/test');
      expect(response.data, isA<Map>());

      // get response as `List`
      response = await dio.get<List>('/list');
      expect(response.data, isA<List>());
      expect(response.data[0], 1);
    });
  });
}
