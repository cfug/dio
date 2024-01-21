import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../matcher.dart';

void statusCodeTests(
  Dio Function() create,
) {
  late Dio dio;

  setUpAll(() {
    dio = create();
  });

  group('status code', () {
    for (final code in [400, 401, 404, 500, 503]) {
      test('$code', () async {
        expect(
          dio.get('/status/$code'),
          throwsDioException(
            DioExceptionType.badResponse,
            stackTraceContains: 'test/status_code_tests.dart',
            matcher: isA<DioException>().having(
              (e) => e.response!.statusCode,
              'statusCode',
              equals(code),
            ),
          ),
        );
      });
    }
  });
}
