import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
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
}
