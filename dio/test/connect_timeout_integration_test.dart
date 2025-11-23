import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('connectTimeout can be set through Options', () {
    // Create options with connectTimeout
    final options = Options(
      connectTimeout: const Duration(seconds: 10),
    );

    expect(options.connectTimeout, const Duration(seconds: 10));
  });

  test('Options connectTimeout overrides BaseOptions', () {
    final baseOptions = BaseOptions(
      baseUrl: 'http://example.com',
      connectTimeout: const Duration(seconds: 5),
    );

    final options = Options(
      connectTimeout: const Duration(seconds: 10),
    );

    final requestOptions = options.compose(baseOptions, '/test');
    expect(requestOptions.connectTimeout, const Duration(seconds: 10));
  });

  test('BaseOptions connectTimeout is used when Options does not set it', () {
    final baseOptions = BaseOptions(
      baseUrl: 'http://example.com',
      connectTimeout: const Duration(seconds: 5),
    );

    final options = Options();

    final requestOptions = options.compose(baseOptions, '/test');
    expect(requestOptions.connectTimeout, const Duration(seconds: 5));
  });
}
