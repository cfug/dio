import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../utils.dart';

void redirectTests(
  Dio Function() create,
) {
  late Dio dio;

  setUpAll(() {
    dio = create();
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
        // The browser will follow the redirects automatically.
        expect(response.redirects.length, 3);
        final ri = response.redirects.first;
        expect(ri.statusCode, 302);
        expect(ri.method, 'GET');
      }
    });
  });
}
