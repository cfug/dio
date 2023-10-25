import 'dart:async';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group(Headers, () {
    test('set', () {
      final headers = Headers.fromMap({
        'set-cookie': ['k=v', 'k1=v1'],
        'content-length': ['200'],
        'test': ['1', '2'],
      });
      headers.add('SET-COOKIE', 'k2=v2');
      expect(headers.value('content-length'), '200');
      expect(Future(() => headers.value('test')), throwsException);
      expect(headers['set-cookie']?.length, 3);
      headers.remove('set-cookie', 'k=v');
      expect(headers['set-cookie']?.length, 2);
      headers.removeAll('set-cookie');
      expect(headers['set-cookie'], isNull);
      final ls = [];
      headers.forEach((k, list) => ls.addAll(list));
      expect(ls.length, 3);
      expect(headers.toString(), 'content-length: 200\ntest: 1\ntest: 2\n');
      headers.set('content-length', '300');
      expect(headers.value('content-length'), '300');
      headers.set('content-length', ['400']);
      expect(headers.value('content-length'), '400');
    });

    test('clear', () {
      final headers1 = Headers();
      headers1.set('xx', 'v');
      expect(headers1.value('xx'), 'v');
      headers1.clear();
      expect(headers1.map.isEmpty, isTrue);
    });

    test('case-sensitive', () {
      final headers = Headers.fromMap(
        {
          'SET-COOKIE': ['k=v', 'k1=v1'],
          'content-length': ['200'],
          'Test': ['1', '2'],
        },
        preserveHeaderCase: true,
      );
      expect(headers['SET-COOKIE']?.length, 2);
      // Although it's case-sensitive, we still use case-insensitive map.
      expect(headers['set-cookie']?.length, 2);
      expect(headers['content-length']?.length, 1);
      expect(headers['Test']?.length, 2);
    });
  });
}
