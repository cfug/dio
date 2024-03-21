import 'package:dio/dio.dart';
import 'package:dio_test/util.dart';
import 'package:test/test.dart';

void headerTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
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

    test('header value types implicit support', () async {
      final res = await dio.post(
        '/post',
        data: 'TEST',
        options: Options(
          headers: {
            'ListKey': ['1', '2'],
            'StringKey': '1',
            'NumKey': 2,
            'BooleanKey': false,
          },
        ),
      );
      final content = res.data.toString();
      expect(content, contains('TEST'));
      expect(content, contains('Listkey: 1, 2'));
      expect(content, contains('Stringkey: 1'));
      expect(content, contains('Numkey: 2'));
      expect(content, contains('Booleankey: false'));
    });
  });
}
