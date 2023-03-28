import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group(CancelToken, () {
    test('cancel returns the correct DioError', () async {
      final token = CancelToken();
      const reason = 'cancel';

      expectLater(token.whenCancel, completion((error) {
        return error is DioError &&
            error.type == DioErrorType.cancel &&
            error.error == reason;
      }));
      token.requestOptions = RequestOptions();
      token.cancel(reason);
    });

    test('cancel without use does not throw (#1765)', () async {
      CancelToken().cancel();
    });
  });
}
