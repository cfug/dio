import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  group(
    IOHttpClientAdapter,
    () {
      test('onHttpClientCreate is only executed once per request', () async {
        int onHttpClientCreateInvokeCount = 0;
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter(
          // ignore: deprecated_member_use_from_same_package
          onHttpClientCreate: (client) {
            onHttpClientCreateInvokeCount++;
            return client;
          },
        );
        await dio.get('https://pub.dev');
        expect(onHttpClientCreateInvokeCount, 1);
      });

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

      test('httpVersion is set in response extra', () async {
        final dio = Dio();
        dio.httpClientAdapter = IOHttpClientAdapter();
        final response = await dio.get('https://pub.dev');
        final httpVersion =
            response.extra[HttpClientAdapter.extraKeyHttpVersion];
        expect(httpVersion, isNotNull);
        expect(httpVersion, anyOf(equals('1.0'), equals('1.1')));
      });
    },
    testOn: 'vm',
  );
}
