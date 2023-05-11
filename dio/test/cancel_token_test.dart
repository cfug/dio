import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group(CancelToken, () {
    test('cancel returns the correct DioException', () async {
      final token = CancelToken();
      const reason = 'cancel';

      expectLater(token.whenCancel, completion((error) {
        return error is DioException &&
            error.type == DioExceptionType.cancel &&
            error.error == reason;
      }));
      token.requestOptions = RequestOptions();
      token.cancel(reason);
    });

    test('cancel without use does not throw (#1765)', () async {
      CancelToken().cancel();
    });

    test('cancels multiple requests', () async {
      final token = CancelToken();
      const reason = 'cancel';
      final dio = Dio();
      expectLater(
        dio.get('https://pub.dev', cancelToken: token),
        throwsA((error) =>
            error is DioError &&
            error.type == DioErrorType.cancel &&
            error.error == reason),
      );
      expectLater(
        dio.get('https://pub.dev', cancelToken: token),
        throwsA((error) =>
            error is DioError &&
            error.type == DioErrorType.cancel &&
            error.error == reason),
      );
      await Future.delayed(const Duration(milliseconds: 5));
      token.cancel(reason);
    });
  });
}
