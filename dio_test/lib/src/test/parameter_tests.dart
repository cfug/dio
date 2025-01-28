import 'package:dio/dio.dart';
import 'package:test/test.dart';

import '../../util.dart';

void parameterTests(
  Dio Function(String baseUrl) create,
) {
  late Dio dio;

  setUp(() {
    dio = create(httpbunBaseUrl);
  });

  group('parameters', () {
    group('generic parameters', () {
      test('default (Map)', () async {
        final response = await dio.get('/get');
        expect(response.data, isA<Map>());
        expect(response.data, isNotEmpty);
      });

      test('Map', () async {
        final response = await dio.get<Map>('/get');
        expect(response.data, isA<Map>());
        expect(response.data, isNotEmpty);
      });

      test('String', () async {
        final response = await dio.get<String>('/get');
        expect(response.data, isA<String>());
        expect(response.data, isNotEmpty);
      });

      test('List', () async {
        final response = await dio.post<List>(
          '/payload',
          data: '[1,2,3]',
        );
        expect(response.data, isA<List>());
        expect(response.data, isNotEmpty);
        expect(response.data![0], 1);
      });
    });
  });
}
