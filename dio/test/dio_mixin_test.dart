import 'dart:typed_data';

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
      throwsA(const TypeMatcher<UnimplementedError>()),
    );
  });

  test('cloned', () {
    final dio = Dio();
    final cloned = dio.clone();
    expect(dio == cloned, false);
    expect(dio.options, equals(cloned.options));
    expect(dio.interceptors, equals(cloned.interceptors));
    expect(dio.httpClientAdapter, equals(cloned.httpClientAdapter));
    expect(dio.transformer, equals(cloned.transformer));
    final clonedWithFields = dio.clone(
      options: BaseOptions(baseUrl: 'http://localhost'),
      interceptors: Interceptors()..add(InterceptorsWrapper()),
      httpClientAdapter: _TestAdapter(),
      transformer: SyncTransformer(),
    );
    expect(clonedWithFields.options.baseUrl, equals('http://localhost'));
    expect(clonedWithFields.interceptors.length, equals(2));
    expect(clonedWithFields.httpClientAdapter, isA<_TestAdapter>());
    expect(clonedWithFields.transformer, isA<SyncTransformer>());
  });
}

class _TestDioMixin with DioMixin implements Dio {}

class _TestDioMixinExtends extends DioMixin implements Dio {}

class _TestAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw UnimplementedError();
  }

  @override
  void close({bool force = false}) {}
}
