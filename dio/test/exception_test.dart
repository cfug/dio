import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test("catch DioError", () async {
    dynamic error;

    try {
      await Dio().get("https://does.not.exist");
      fail("did not throw");
    } on DioError catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test("catch DioError as Exception", () async {
    dynamic error;

    try {
      await Dio().get("https://does.not.exist");
      fail("did not throw");
    } on Exception catch (e) {
      error = e;
    }

    expect(error, isNotNull);
    expect(error is Exception, isTrue);
  });

  test("catch DioError with onError callback", () async {
    dynamic error;

    final options = Options(onError: (DioError _error) {
      error = _error;
      print(error);
    });

    try {
      await Dio().get("https://does.not.exist", options: options);
      expect(error, isNotNull);
      expect(error is DioError, isTrue);
    } on Exception catch (e) {
      fail("was not caught: $e");
    }
  });

  test('rethrow DioError from onError callback', () async {
    dynamic error;

    final options = Options(onError: (DioError error) {
      return Response(data: error);
    });

    try {
      final response = await Dio().get("https://does.not.exist", options: options);
      if (response.data is DioError) throw response.data;
    } on DioError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error is DioError, isTrue);
  });
}