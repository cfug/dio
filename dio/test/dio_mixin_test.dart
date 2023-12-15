import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('not thrown for implements', () {
    expect(_TestDioMixin().interceptors, isA<Interceptors>());
    expect(_TestDioMixinExtends().interceptors, isA<Interceptors>());
  });

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
    expectLater(
      () => _TestDioMixin().download('a', 'b'),
      throwsA(TypeMatcher<UnimplementedError>()),
    );
  });
}

class _TestDioMixin with DioMixin implements Dio {}

class _TestDioMixinExtends extends DioMixin implements Dio {}
