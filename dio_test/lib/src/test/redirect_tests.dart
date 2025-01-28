import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../util.dart';

void redirectTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('redirects', () {
    test('single', () async {
      final response = await dio.get(
        '/redirect',
        queryParameters: {'url': '$httpbunBaseUrl/get'},
        onReceiveProgress: (received, total) {
          // ignore progress
        },
      );
      expect(response.isRedirect, isTrue);

      if (!kIsWeb) {
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

      if (!kIsWeb) {
        // Redirects are not supported in web.
        // The browser will follow the redirects automatically.
        expect(response.redirects.length, 3);
        final ri = response.redirects.first;
        expect(ri.statusCode, 302);
        expect(ri.method, 'GET');
      }
    });

    test(
      'empty location',
      () async {
        final response = await dio.get(
          '/redirect',
        );
        expect(response.isRedirect, isTrue);
        expect(response.redirects.length, 1);

        final ri = response.redirects.first;
        expect(ri.statusCode, 302);
        expect(ri.location.path, '/get');
        expect(ri.method, 'GET');
      },
      skip: 'Httpbun does not support empty location redirects',
    );

    test('request with redirect', () async {
      final res = await dio.get('/absolute-redirect/2');
      expect(res.statusCode, 200);
    });
  });
}
