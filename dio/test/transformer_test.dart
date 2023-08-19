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
}
