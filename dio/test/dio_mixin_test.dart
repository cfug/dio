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
}
