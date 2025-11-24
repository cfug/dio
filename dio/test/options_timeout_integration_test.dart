import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  group('Options timeout overrides', () {
    test('Options.connectTimeout is used by adapter', () async {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30), // Long timeout in base
        ),
      );

      // Override with a short timeout via Options
      final startTime = DateTime.now();
      try {
        await dio.get(
          'http://10.0.0.0', // Non-routable address
          options: Options(
            connectTimeout: const Duration(milliseconds: 100), // Short timeout
          ),
        );
        fail('Should have thrown a connection timeout exception');
      } on DioException catch (e) {
        final elapsed = DateTime.now().difference(startTime);

        // Verify it's a connection timeout
        expect(e.type, DioExceptionType.connectionTimeout);

        // Verify it used the Options timeout (100ms), not BaseOptions timeout (30s)
        // Allow some margin for test execution overhead
        expect(
          elapsed.inMilliseconds,
          lessThan(5000),
          reason: 'Should timeout quickly (100ms + margin), not after 30s',
        );
      }
    });

    test('Options.connectTimeout composes correctly with BaseOptions', () {
      final baseOptions = BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        baseUrl: 'http://example.com',
      );

      final options = Options(
        connectTimeout: const Duration(seconds: 10),
        method: 'POST',
      );

      final requestOptions = options.compose(baseOptions, '/test');

      // Verify Options.connectTimeout takes precedence
      expect(requestOptions.connectTimeout, const Duration(seconds: 10));
      expect(requestOptions.method, 'POST');
      expect(requestOptions.baseUrl, 'http://example.com');
    });

    test('Options.sendTimeout composes correctly with BaseOptions', () {
      final baseOptions = BaseOptions(
        sendTimeout: const Duration(seconds: 5),
        baseUrl: 'http://example.com',
      );

      final options = Options(
        sendTimeout: const Duration(seconds: 10),
        method: 'POST',
      );

      final requestOptions = options.compose(baseOptions, '/test');

      // Verify Options.sendTimeout takes precedence
      expect(requestOptions.sendTimeout, const Duration(seconds: 10));
      expect(requestOptions.method, 'POST');
      expect(requestOptions.baseUrl, 'http://example.com');
    });

    test('Options.receiveTimeout composes correctly with BaseOptions', () {
      final baseOptions = BaseOptions(
        receiveTimeout: const Duration(seconds: 5),
        baseUrl: 'http://example.com',
      );

      final options = Options(
        receiveTimeout: const Duration(seconds: 10),
        method: 'POST',
      );

      final requestOptions = options.compose(baseOptions, '/test');

      // Verify Options.receiveTimeout takes precedence
      expect(requestOptions.receiveTimeout, const Duration(seconds: 10));
      expect(requestOptions.method, 'POST');
      expect(requestOptions.baseUrl, 'http://example.com');
    });

    test('All timeout types can be set via Options simultaneously', () {
      final baseOptions = BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        baseUrl: 'http://example.com',
      );

      final options = Options(
        connectTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        method: 'POST',
      );

      final requestOptions = options.compose(baseOptions, '/test');

      // Verify all Options timeouts take precedence
      expect(requestOptions.connectTimeout, const Duration(seconds: 10));
      expect(requestOptions.sendTimeout, const Duration(seconds: 15));
      expect(requestOptions.receiveTimeout, const Duration(seconds: 20));
      expect(requestOptions.method, 'POST');
      expect(requestOptions.baseUrl, 'http://example.com');
    });
  });
}
