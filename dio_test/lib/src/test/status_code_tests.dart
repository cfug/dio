import 'package:dio/dio.dart';
import 'package:dio_test/util.dart';
import 'package:test/test.dart';

void statusCodeTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('status code', () {
    for (final code in [400, 401, 404, 500, 503]) {
      test('$code', () async {
        expect(
          dio.get('/status/$code'),
          throwsDioException(
            DioExceptionType.badResponse,
            stackTraceContains: kIsWeb ? null : 'test/status_code_tests.dart',
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
