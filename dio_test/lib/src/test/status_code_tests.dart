import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../util.dart';

void statusCodeTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('status code', () {
    for (final code in [400, 401, 404, 500, 503]) {
      test('$code', () {
        expect(
          dio.get('/status/$code'),
          throwsDioException(
            DioExceptionType.badResponse,
            stackTraceContains: kIsWeb
                ? 'test/test_suite_test.dart'
                : 'test/status_code_tests.dart',
            matcher: isA<DioException>().having(
              (e) => e.response!.statusCode,
              'statusCode',
              code,
            ),
          ),
        );
      });
    }
  });

  group(ValidateStatus, () {
    test('200 with validateStatus => false', () {
      expect(
        dio.get(
          '/status/200',
          options: Options(validateStatus: (status) => false),
        ),
        throwsDioException(
          DioExceptionType.badResponse,
          stackTraceContains: kIsWeb
              ? 'test/test_suite_test.dart'
              : 'test/status_code_tests.dart',
          matcher: isA<DioException>().having(
            (e) => e.response!.statusCode,
            'statusCode',
            200,
          ),
        ),
      );
    });

    test('500 with validateStatus => true', () async {
      final response = await dio.get(
        '/status/500',
        options: Options(validateStatus: (status) => true),
      );

      expect(response.statusCode, 500);
    });
  });
}
