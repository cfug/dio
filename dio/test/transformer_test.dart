import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/src/transformers/util/consolidate_bytes.dart';
import 'package:test/test.dart';

void main() {
  // Regression: https://github.com/cfug/dio/issues/2256
  test('Transformer.isJsonMimeType', () {
    expect(Transformer.isJsonMimeType('application/json'), isTrue);
    expect(Transformer.isJsonMimeType('application/json;charset=utf8'), isTrue);
    expect(Transformer.isJsonMimeType('text/json'), isTrue);
    expect(Transformer.isJsonMimeType('image/jpg'), isFalse);
    expect(Transformer.isJsonMimeType('image/png'), isFalse);
    expect(Transformer.isJsonMimeType('.png'), isFalse);
    expect(Transformer.isJsonMimeType('.png;charset=utf-8'), isFalse);
  });

  group(BackgroundTransformer(), () {
    test('transformResponse transforms the request', () async {
      final transformer = BackgroundTransformer();
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody.fromString(
          '{"foo": "bar"}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      expect(response, {'foo': 'bar'});
    });
  });

  // Regression: https://github.com/cfug/dio/issues/1834
  test('null response body only when the response is JSON', () async {
    final transformer = BackgroundTransformer();
    for (final responseType in ResponseType.values) {
      final response = await transformer.transformResponse(
        RequestOptions(responseType: responseType),
        ResponseBody.fromBytes([], 200),
      );
      switch (responseType) {
        case ResponseType.json:
        case ResponseType.plain:
          expect(response, '');
          break;
        case ResponseType.stream:
          expect(response, isA<ResponseBody>());
          break;
        case ResponseType.bytes:
          expect(response, []);
          break;
        default:
          throw AssertionError('Unknown response type: $responseType');
      }
    }
    final jsonResponse = await transformer.transformResponse(
      RequestOptions(responseType: ResponseType.json),
      ResponseBody.fromBytes(
        [],
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    expect(jsonResponse, null);
  });

  group(FusedTransformer, () {
    test(
        'transformResponse transforms json without content-length set in response',
        () async {
      final transformer = FusedTransformer();
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody.fromString(
          '{"foo": "bar"}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      expect(response, {'foo': 'bar'});
    });

    test('transformResponse transforms json with content-length', () async {
      final transformer = FusedTransformer();
      const jsonString = '{"foo": "bar"}';
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody.fromString(
          jsonString,
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
            Headers.contentLengthHeader: [
              utf8.encode(jsonString).length.toString(),
            ],
          },
        ),
      );
      expect(response, {'foo': 'bar'});
    });

    test('transformResponse transforms json array', () async {
      final transformer = FusedTransformer();
      const jsonString = '[{"foo": "bar"}]';
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody.fromString(
          jsonString,
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
            Headers.contentLengthHeader: [
              utf8.encode(jsonString).length.toString(),
            ],
          },
        ),
      );
      expect(
        response,
        [
          {'foo': 'bar'},
        ],
      );
    });

    test('transforms json in background isolate', () async {
      final transformer = FusedTransformer(contentLengthIsolateThreshold: 0);
      final jsonString = '{"foo": "bar"}';
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody.fromString(
          jsonString,
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
            Headers.contentLengthHeader: [
              utf8.encode(jsonString).length.toString(),
            ],
          },
        ),
      );
      expect(response, {'foo': 'bar'});
    });

    test('transformResponse transforms that arrives in many chunks', () async {
      final transformer = FusedTransformer();
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody(
          Stream.fromIterable(
              /* utf-8 encoding of {"foo": "bar"} */
              [
                Uint8List.fromList([123]),
                Uint8List.fromList([34]),
                Uint8List.fromList([102, 111, 111]),
                Uint8List.fromList([34]),
                Uint8List.fromList([58]),
                Uint8List.fromList([34]),
                Uint8List.fromList([98, 97, 114]),
                Uint8List.fromList([34]),
                Uint8List.fromList([125]),
              ]),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      expect(response, {'foo': 'bar'});
    });

    test('transformResponse handles bytes', () async {
      final transformer = FusedTransformer();
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.bytes),
        ResponseBody.fromBytes(
          [1, 2, 3],
          200,
        ),
      );
      expect(response, [1, 2, 3]);
    });

    test('transformResponse handles when response stream has multiple chunks',
        () async {
      final transformer = FusedTransformer();
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.bytes),
        ResponseBody(
          Stream.fromIterable([
            Uint8List.fromList([1, 2, 3]),
            Uint8List.fromList([4, 5, 6]),
            Uint8List.fromList([7, 8, 9]),
          ]),
          200,
        ),
      );
      expect(response, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('transformResponse handles plain text', () async {
      final transformer = FusedTransformer();
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.plain),
        ResponseBody.fromString(
          'plain text',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/plain'],
          },
        ),
      );
      expect(response, 'plain text');
    });

    test('ResponseType.plain takes precedence over content-type', () async {
      final transformer = FusedTransformer();
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.plain),
        ResponseBody.fromString(
          '{"text": "plain text"}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      expect(response, '{"text": "plain text"}');
    });

    test('transformResponse handles streams', () async {
      final transformer = FusedTransformer();
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.stream),
        ResponseBody.fromBytes(
          [1, 2, 3],
          200,
        ),
      );
      expect(response, isA<ResponseBody>());
    });

    test('null response body only when the response is JSON', () async {
      final transformer = FusedTransformer();
      for (final responseType in ResponseType.values) {
        final response = await transformer.transformResponse(
          RequestOptions(responseType: responseType),
          ResponseBody.fromBytes([], 200),
        );
        switch (responseType) {
          case ResponseType.json:
          case ResponseType.plain:
            expect(response, '');
            break;
          case ResponseType.stream:
            expect(response, isA<ResponseBody>());
            break;
          case ResponseType.bytes:
            expect(response, []);
            break;
          default:
            throw AssertionError('Unknown response type: $responseType');
        }
      }
      final jsonResponse = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody.fromBytes(
          [],
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      expect(jsonResponse, null);
    });

    test('transform the request using urlencode', () async {
      final transformer = FusedTransformer();

      final request = await transformer.transformRequest(
        RequestOptions(responseType: ResponseType.json, data: {'foo': 'bar'}),
      );
      expect(request, 'foo=bar');
    });

    test('transform the request using json', () async {
      final transformer = FusedTransformer();

      final request = await transformer.transformRequest(
        RequestOptions(
          responseType: ResponseType.json,
          data: {'foo': 'bar'},
          headers: {'Content-Type': 'application/json'},
        ),
      );
      expect(request, '{"foo":"bar"}');
    });

    test(
      'HEAD request with content-length but empty body should not return null',
      () async {
        final transformer = FusedTransformer();
        final response = await transformer.transformResponse(
          RequestOptions(responseType: ResponseType.json, method: 'HEAD'),
          ResponseBody(
            Stream.value(Uint8List(0)),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
              Headers.contentLengthHeader: ['123'],
            },
          ),
        );
        expect(response, null);
      },
    );

    test(
      'can handle status 304 responses with content-length but empty body',
      () async {
        final transformer = FusedTransformer();
        final response = await transformer.transformResponse(
          RequestOptions(responseType: ResponseType.json),
          ResponseBody(
            Stream.value(Uint8List(0)),
            304,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
              Headers.contentLengthHeader: ['123'],
            },
          ),
        );
        expect(response, null);
      },
    );
  });

  group('consolidate bytes', () {
    test('consolidates bytes from a stream', () async {
      final stream = Stream.fromIterable([
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([4, 5, 6]),
        Uint8List.fromList([7, 8, 9]),
      ]);
      final bytes = await consolidateBytes(stream);
      expect(bytes, Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9]));
    });

    test('handles empty stream', () async {
      const stream = Stream<Uint8List>.empty();
      final bytes = await consolidateBytes(stream);
      expect(bytes, Uint8List(0));
    });

    test('handles empty lists', () async {
      final stream = Stream.value(Uint8List(0));
      final bytes = await consolidateBytes(stream);
      expect(bytes, Uint8List(0));
    });
  });
}
