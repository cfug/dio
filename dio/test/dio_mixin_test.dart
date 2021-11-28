import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('#assureResponse', () {
    final untypedResponse = Response<dynamic>(
      requestOptions: RequestOptions(path: ''),
      data: null,
    );
    expect(untypedResponse is Response<int?>, isFalse);

    final typedResponse = DioMixin.assureResponse<int?>(untypedResponse);
    expect(typedResponse.data, isNull);
  });
}
