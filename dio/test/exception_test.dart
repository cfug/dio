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
}
