import 'dart:io';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../util.dart';

void basicTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('basic request', () {
    test(
      'works with non-TLS requests',
      () => dio.get('http://flutter-io.cn/'),
      testOn: 'vm',
    );

    test('fails with an invalid HTTP URL', () {
      expectLater(
        dio.get('http://does.not.exist'),
        throwsDioException(
          DioExceptionType.connectionError,
          matcher: kIsWeb
              ? null
              : isA<DioException>().having(
                  (e) => e.error,
                  'inner exception',
                  isA<SocketException>(),
                ),
        ),
      );
    });

    test('fails with an invalid HTTPS URL', () {
      expectLater(
        dio.get('https://does.not.exist'),
        throwsDioException(
          DioExceptionType.connectionError,
          matcher: kIsWeb
              ? null
              : isA<DioException>().having(
                  (e) => e.error,
                  'inner exception',
                  isA<SocketException>(),
                ),
        ),
      );
    });

    test('throws DioException that can be caught', () async {
      try {
        await dio.get('https://does.not.exist');
        fail('did not throw');
      } on DioException catch (e) {
        expect(e, isNotNull);
      }
    });

    test('POST string', () async {
      final response = await dio.post('/post', data: 'TEST');
      expect(response.data['data'], 'TEST');
    });

    test('POST map', () async {
      final response = await dio.post(
        '/post',
        data: {'a': 1, 'b': 2, 'c': 3},
      );
      expect(response.data['data'], '{"a":1,"b":2,"c":3}');
      expect(response.statusCode, 200);
    });
  });
}
