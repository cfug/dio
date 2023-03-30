import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';

void main() async {
  group('x-www-url-encoded', () {
    test('posts maps correctly', () async {
      final data = {
        'spec': [6],
        'items': [
          {'name': 'foo', 'value': 1},
          {'name': 'bar', 'value': 2},
        ],
        'api': {
          'dest': '/',
          'data': {
            'a': 1,
            'b': 2,
            'c': 3,
          },
        },
      };

      final dio = Dio()
        ..options.baseUrl = EchoAdapter.mockBase
        ..httpClientAdapter = EchoAdapter();

      final response = await dio.post(
        '/post',
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          listFormat: ListFormat.multiCompatible,
        ),
      );

      final expected =
          'spec%5B%5D=6&items%5B0%5D%5Bname%5D=foo&items%5B0%5D%5Bvalue%5D=1&items%5B1%5D%5Bname%5D=bar&items%5B1%5D%5Bvalue%5D=2&api%5Bdest%5D=%2F&api%5Bdata%5D%5Ba%5D=1&api%5Bdata%5D%5Bb%5D=2&api%5Bdata%5D%5Bc%5D=3';
      final expectedDecoded =
          'spec[]=6&items[0][name]=foo&items[0][value]=1&items[1][name]=bar&items[1][value]=2&api[dest]=/&api[data][a]=1&api[data][b]=2&api[data][c]=3';
      expect(
        response.data,
        expected,
      );
      expect(
        Uri.decodeQueryComponent(response.data),
        expectedDecoded,
      );
    });
  });
}
