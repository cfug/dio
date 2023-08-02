import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('assureResponse', () {
    final requestOptions = RequestOptions(path: '');
    final untypedResponse = Response<dynamic>(
      requestOptions: requestOptions,
      data: null,
    );
    expect(untypedResponse is Response<int?>, isFalse);

    final typedResponse = DioMixin.assureResponse<int?>(
      untypedResponse,
      requestOptions,
    );
    expect(typedResponse.data, isNull);
  });

  test('throws UnimplementedError when calling download', () {
    expectLater(() => _TextDioMixin().download('a', 'b'), throwsA<UnimplementedError>();
  });
}

class _TestDioMixin with DioMixin implements Dio {}
