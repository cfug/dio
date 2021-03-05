import 'package:dio/dio.dart';
import 'package:dio/src/parameter.dart';
import 'package:test/test.dart';

void main() {
  var data = {
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
  test('#url encode default ', () {
    var result =
        'a=%E4%BD%A0%E5%A5%BD&b=5&b=6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66&c%5Be%5D%5Bb%5D=8';
    expect(Transformer.urlEncodeMap(data), result);
  });
  test('#url encode csv', () {
    var result =
        'a=%E4%BD%A0%E5%A5%BD&b=5%2C6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66%2C8';
    expect(Transformer.urlEncodeMap(data, ListFormat.csv), result);
  });
  test('#url encode ssv', () {
    var result =
        'a=%E4%BD%A0%E5%A5%BD&b=5+6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66+8';
    expect(Transformer.urlEncodeMap(data, ListFormat.ssv), result);
  });
  test('#url encode tsv', () {
    var result =
        'a=%E4%BD%A0%E5%A5%BD&b=5%5Ct6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66%5Ct8';
    expect(Transformer.urlEncodeMap(data, ListFormat.tsv), result);
  });
  test('#url encode pipe', () {
    var result =
        'a=%E4%BD%A0%E5%A5%BD&b=5%7C6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=66%7C8';
    expect(Transformer.urlEncodeMap(data, ListFormat.pipes), result);
  });
  test('#url encode multi', () {
    var result =
        'a=%E4%BD%A0%E5%A5%BD&b%5B%5D=5&b%5B%5D=6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D%5B%5D=66&c%5Be%5D%5Bb%5D%5B%5D=8';
    expect(Transformer.urlEncodeMap(data, ListFormat.multiCompatible), result);
  });

  test('#url encode custom', () {
    var result =
        'a=%E4%BD%A0%E5%A5%BD&b=5%7C6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D=foo%2Cbar&c%5Be%5D%5Bc%5D=foo+bar&c%5Be%5D%5Bd%5D%5B%5D=foo&c%5Be%5D%5Bd%5D%5B%5D=bar&c%5Be%5D%5Be%5D=foo%5Ctbar';
    expect(
      Transformer.urlEncodeMap(
        {
          'a': Param('你好'),
          'b': MultiParam<int>([5, 6], ListFormat.pipes),
          'c': Param({
            'd': Param(8),
            'e': Param({
              'a': Param(5),
              'b': MultiParam<String>(['foo', 'bar'], ListFormat.csv),
              'c': MultiParam<String>(['foo', 'bar'], ListFormat.ssv),
              'd': MultiParam<String>(['foo', 'bar'], ListFormat.multi),
              'e': MultiParam<String>(['foo', 'bar'], ListFormat.tsv),
            }),
          }),
        },
        ListFormat.multiCompatible,
      ),
      result,
    );
  });
}
