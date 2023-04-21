import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group(SyncTransformer, () {
    test('can encode Map<dynamic, dynamic>', () async {
      final transformer = SyncTransformer();
      final map = {'a': 'a', 'b': 1, 2: 'c'};
      final request = await transformer.transformRequest(
        RequestOptions(data: map),
      );
      expect(request, 'a=a&b=1&2=c');
    });
  });

  group(BackgroundTransformer, () {
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
}
