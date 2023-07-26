import 'package:w_dio/dio.dart';
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
    final r1 = await transformer.transformResponse(
      RequestOptions(responseType: ResponseType.json),
      ResponseBody.fromBytes([], 200),
    );
    expect(r1, '');
    final r2 = await transformer.transformResponse(
      RequestOptions(responseType: ResponseType.bytes),
      ResponseBody.fromBytes([], 200),
    );
    expect(r2, []);
    final r3 = await transformer.transformResponse(
      RequestOptions(responseType: ResponseType.plain),
      ResponseBody.fromBytes([], 200),
    );
    expect(r3, '');
    final r4 = await transformer.transformResponse(
      RequestOptions(responseType: ResponseType.json),
      ResponseBody.fromBytes(
        [],
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
    expect(r4, null);
  });
}
