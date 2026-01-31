@TestOn('browser')

import 'package:dio/dio.dart';
import 'package:dio_web_adapter/dio_web_adapter.dart';
import 'package:test/test.dart';

void main() {
  group('DioForBrowser.download', () {
    late DioForBrowser dio;

    setUp(() {
      dio = DioForBrowser();
    });

    tearDown(() {
      dio.close();
    });

    test('throws ArgumentError for invalid savePath type', () async {
      expect(
        () => dio.download(
          'https://example.com/file.pdf',
          123, // Invalid type - not String or Function
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for invalid savePath type (Map)', () async {
      expect(
        () => dio.download(
          'https://example.com/file.pdf',
          {'invalid': 'type'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for invalid savePath type (List)', () async {
      expect(
        () => dio.download(
          'https://example.com/file.pdf',
          ['invalid', 'type'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts String savePath without throwing UnsupportedError', () async {
      // This test verifies that the method no longer throws UnsupportedError
      // It will fail with a network error since we're not mocking the request,
      // but that's expected - we just want to verify it attempts the request
      try {
        await dio.download(
          'https://httpbin.org/bytes/100',
          'test-file.bin',
        );
      } on DioException {
        // Expected - network request may fail in test environment
        // The important thing is it didn't throw UnsupportedError
      }
    });

    test('accepts callback savePath without throwing UnsupportedError',
        () async {
      // This test verifies that callback savePath is accepted
      try {
        await dio.download(
          'https://httpbin.org/bytes/100',
          (Headers headers) => 'test-file.bin',
        );
      } on DioException {
        // Expected - network request may fail in test environment
      }
    });

    test('accepts async callback savePath', () async {
      try {
        await dio.download(
          'https://httpbin.org/bytes/100',
          (Headers headers) async => 'test-file.bin',
        );
      } on DioException {
        // Expected - network request may fail in test environment
      }
    });

    test('supports onReceiveProgress callback', () async {
      var progressCallCount = 0;
      try {
        await dio.download(
          'https://httpbin.org/bytes/1000',
          'test-file.bin',
          onReceiveProgress: (received, total) {
            progressCallCount++;
          },
        );
        // If we get here, download succeeded and progress should have been called
        expect(progressCallCount, greaterThan(0));
      } on DioException {
        // Network errors are acceptable in test environment
        // Progress callback may or may not have been called depending on timing
      }
    });

    test('supports cancelToken', () async {
      final cancelToken = CancelToken();

      // Cancel immediately
      cancelToken.cancel('Test cancellation');

      expect(
        () => dio.download(
          'https://httpbin.org/bytes/100',
          'test-file.bin',
          cancelToken: cancelToken,
        ),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
    });
  });
}
