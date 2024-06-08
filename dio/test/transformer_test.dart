import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
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

  group(Utf8JsonTransformer(), () {
    test('transformResponse transforms json without content-length set in response', () async {
      final transformer = Utf8JsonTransformer();
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
      final transformer = Utf8JsonTransformer();
      const jsonString = '{"foo": "bar"}';
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody.fromString(
          jsonString,
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
            Headers.contentLengthHeader: [utf8.encode(jsonString).length.toString()],
          },
        ),
      );
      expect(response, {'foo': 'bar'});
    });


    test('transforms json in background isolate', () async {
      final transformer = Utf8JsonTransformer(contentLengthIsolateThreshold: 0);
      final jsonString = '{"foo": "bar"}';
      final response = await transformer.transformResponse(
        RequestOptions(responseType: ResponseType.json),
        ResponseBody.fromString(
          jsonString,
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
            Headers.contentLengthHeader: [utf8.encode(jsonString).length.toString()],
          },
        ),
      );
      expect(response, {'foo': 'bar'});
    });


    test('transformResponse transforms that arrives in many chunks', () async {
      final transformer = Utf8JsonTransformer();
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
      final transformer = Utf8JsonTransformer();
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
      final transformer = Utf8JsonTransformer();
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
      final transformer = Utf8JsonTransformer();
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

    test('transformResponse handles streams', () async {
      final transformer = Utf8JsonTransformer();
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
      final transformer = Utf8JsonTransformer();
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
      final transformer = Utf8JsonTransformer();

      final request = await transformer.transformRequest(
        RequestOptions(responseType: ResponseType.json, data: {'foo': 'bar'}),
      );
      expect(request, 'foo=bar');
    });

    test('transform the request using json', () async {
      final transformer = Utf8JsonTransformer();

      final request = await transformer.transformRequest(
        RequestOptions(
          responseType: ResponseType.json,
          data: {'foo': 'bar'},
          headers: {'Content-Type': 'application/json'},
        ),
      );
      expect(request, '{"foo":"bar"}');
    });
  });
}
