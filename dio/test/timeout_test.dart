import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:test/test.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio();
    dio.options.baseUrl = 'https://httpbun.com/';
  });

  group('Timeout exception of', () {
    group('connectTimeout', () {
      test('update between calls', () async {
        final client = HttpClient();
        final dio = Dio()
          ..options.baseUrl = 'https://httpbun.com'
          ..httpClientAdapter = IOHttpClientAdapter(
            createHttpClient: () => client,
          );

        dio.options.connectTimeout = Duration(milliseconds: 5);
        await dio
            .get('/')
            .catchError((e) => Response(requestOptions: RequestOptions()));
        expect(client.connectionTimeout, dio.options.connectTimeout);
        dio.options.connectTimeout = Duration(milliseconds: 10);
        await dio
            .get('/')
            .catchError((e) => Response(requestOptions: RequestOptions()));
        expect(client.connectionTimeout, dio.options.connectTimeout);
      }, testOn: 'vm');
    });
  });
}
