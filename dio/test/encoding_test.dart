import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group(Transformer.urlEncodeMap, () {
    final data = {
      'a': '你好',
      'b': [5, '6'],
      'c': {
        'd': 8,
        'e': {
          'a': 5,
          'b': [66, 8]
        }
      }
    };
    test('default ', () {
      // a=你好&b=5&b=6&c[d]=8&c[e][a]=5&c[e][b]=66&c[e][b]=8
      final result =
          'a=%E4%BD%A0%E5%A5%BD&b=5&b=6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66&c%5Be%5D%5Bb%5D=8';
      expect(Transformer.urlEncodeMap(data), result);
    });
    test('csv', () {
      // a=你好&b=5,6&c[d]=8&c[e][a]=5&c[e][b]=66,8
      final result =
          'a=%E4%BD%A0%E5%A5%BD&b=5%2C6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66%2C8';
      expect(Transformer.urlEncodeMap(data, ListFormat.csv), result);
    });
    test('ssv', () {
      // a=你好&b=5+6&c[d]=8&c[e][a]=5&c[e][b]=66+8
      final result =
          'a=%E4%BD%A0%E5%A5%BD&b=5+6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66+8';
      expect(Transformer.urlEncodeMap(data, ListFormat.ssv), result);
    });
    test('tsv', () {
      // a=你好&b=5\t6&c[d]=8&c[e][a]=5&c[e][b]=66\t8
      final result =
          'a=%E4%BD%A0%E5%A5%BD&b=5%5Ct6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66%5Ct8';
      expect(Transformer.urlEncodeMap(data, ListFormat.tsv), result);
    });
    test('pipe', () {
      //a=你好&b=5|6&c[d]=8&c[e][a]=5&c[e][b]=66|8
      final result =
          'a=%E4%BD%A0%E5%A5%BD&b=5%7C6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66%7C8';
      expect(Transformer.urlEncodeMap(data, ListFormat.pipes), result);
    });

    test('multi', () {
      //a=你好&b[]=5&b[]=6&c[d]=8&c[e][a]=5&c[e][b][]=66&c[e][b][]=8
      final result =
          'a=%E4%BD%A0%E5%A5%BD&b%5B%5D=5&b%5B%5D=6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D%5B%5D=66&c%5Be%5D%5Bb%5D%5B%5D=8';
      expect(
        Transformer.urlEncodeMap(data, ListFormat.multiCompatible),
        result,
      );
    });

    test('multi2', () {
      final data = {
        'a': 'string',
        'b': 'another_string',
        'z': ['string'],
      };
      // a=string&b=another_string&z[]=string
      final result = 'a=string&b=another_string&z%5B%5D=string';
      expect(
        Transformer.urlEncodeMap(data, ListFormat.multiCompatible),
        result,
      );
    });

    test('custom', () {
      final result =
          'a=%E4%BD%A0%E5%A5%BD&b=5%7C6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=foo%2Cbar&c%5Be%5D%5Bc%5D=foo+bar&c%5Be%5D%5Bd%5D%5B%5D=foo&c%5Be%5D%5Bd%5D%5B%5D=bar&c%5Be%5D%5Be%5D=foo%5Ctbar';
      expect(
        Transformer.urlEncodeMap(
          {
            'a': '你好',
            'b': ListParam<int>([5, 6], ListFormat.pipes),
            'c': {
              'd': 8,
              'e': {
                'a': 5,
                'b': ListParam<String>(['foo', 'bar'], ListFormat.csv),
                'c': ListParam<String>(['foo', 'bar'], ListFormat.ssv),
                'd': ListParam<String>(['foo', 'bar'], ListFormat.multi),
                'e': ListParam<String>(['foo', 'bar'], ListFormat.tsv),
              },
            },
          },
          ListFormat.multiCompatible,
        ),
        result,
      );
    });
  });

  group(Transformer.urlEncodeQueryMap, () {
    test(ListFormat.csv, () {
      expect(
        Transformer.urlEncodeQueryMap({
          'foo': ListParam(['1', '%', '\$'], ListFormat.csv)
        }),
        'foo=1,%25,%24',
      );
    });

    test('custom', () {
      expect(
        Transformer.urlEncodeQueryMap(
          {
            'a': '你好',
            'b': ListParam<int>([5, 6], ListFormat.pipes),
            'c': {
              'd': 8,
              'e': {
                'a': 5,
                'b': ListParam<Object>(['foo', 'bar', 1, 2.2], ListFormat.csv),
                'c': ListParam<Object>(['foo', 'bar', 1, 2.2], ListFormat.ssv),
                'd':
                    ListParam<Object>(['foo', 'bar', 1, 2.2], ListFormat.multi),
                'e': ListParam<Object>(['foo', 'bar', 1, 2.2], ListFormat.tsv),
              },
            },
          },
          ListFormat.multiCompatible,
        ),
        'a=%E4%BD%A0%E5%A5%BD&b=5|6&c[d]=8&c[e][a]=5&c[e][b]=foo,bar,1,2.2&c[e][c]=foo%20bar%201%202.2&c[e][d][]=foo&c[e][d][]=bar&c[e][d][]=1&c[e][d][]=2.2&c[e][e]=foo\\tbar\\t1\\t2.2',
      );
    });
  });
}
