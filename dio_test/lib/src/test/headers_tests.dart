import 'package:dio/dio.dart';
import 'package:test/test.dart';

void headerTests(
  Dio Function() create,
) {
  late Dio dio;

  setUpAll(() {
    dio = create();
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
  });
}
