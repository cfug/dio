import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  group(
    IOHttpClientAdapter,
    () {
      test('createHttpClientCount is only executed once per request', () async {
        int createHttpClientCount = 0;
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          createHttpClient: () {
            createHttpClientCount++;
            return HttpClient();
          },
        );
        await dio.get('https://pub.dev');
        expect(createHttpClientCount, 1);
      });
    },
    testOn: 'vm',
  );
}
