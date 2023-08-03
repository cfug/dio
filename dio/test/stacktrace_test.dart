import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';
import 'mock/http_mock.dart';
import 'mock/http_mock.mocks.dart';

void main() async {
  group('$DioException.stackTrace', () {
    test(DioExceptionType.badResponse, () async {
      final dio = Dio()
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = MockAdapter.mockBase;

      await expectLater(
        dio.get('/foo'),
        throwsA(
          allOf([
            isA<DioException>(),
            (e) => e.type == DioExceptionType.badResponse,
            (e) =>
                e.stackTrace.toString().contains('test/stacktrace_test.dart'),
          ]),
        ),
      );
    });

    test(DioExceptionType.cancel, () async {
      final dio = Dio()
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = MockAdapter.mockBase;

      final token = CancelToken();
      Future.delayed(const Duration(milliseconds: 10), () {
        token.cancel('cancelled');
        dio.httpClientAdapter.close(force: true);
      });

      await expectLater(
        dio.get('/test-timeout', cancelToken: token),
        throwsA(
          allOf([
            isA<DioException>(),
            (e) => e.type == DioExceptionType.cancel,
            (e) =>
                e.stackTrace.toString().contains('test/stacktrace_test.dart'),
          ]),
        ),
      );
    });

    test(
      DioExceptionType.connectionTimeout,
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final timeout = Duration(milliseconds: 10);
          final dio = Dio()
            ..options.connectTimeout = timeout
            ..options.baseUrl = 'https://does.not.exist';

          when(httpClientMock.openUrl('GET', any)).thenAnswer(
            (_) async {
              final request = MockHttpClientRequest();
              await Future.delayed(
                Duration(milliseconds: timeout.inMilliseconds + 10),
              );
              return request;
            },
          );

          await expectLater(
            dio.get('/test'),
            throwsA(
              allOf([
                isA<DioException>(),
                (e) => e.type == DioExceptionType.connectionTimeout,
                (e) => e.stackTrace
                    .toString()
                    .contains('test/stacktrace_test.dart'),
              ]),
            ),
          );
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );

    test(
      DioExceptionType.receiveTimeout,
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final timeout = Duration(milliseconds: 10);
          final dio = Dio()
            ..options.receiveTimeout = timeout
            ..options.baseUrl = 'https://does.not.exist';

          when(httpClientMock.openUrl('GET', any)).thenAnswer(
            (_) async {
              final request = MockHttpClientRequest();
              final response = MockHttpClientResponse();
              when(request.close()).thenAnswer(
                (_) => Future.delayed(
                  Duration(milliseconds: timeout.inMilliseconds + 10),
                  () => response,
                ),
              );
              return request;
            },
          );

          await expectLater(
            dio.get('/test'),
            throwsA(
              allOf([
                isA<DioException>(),
                (DioException e) => e.type == DioExceptionType.receiveTimeout,
                (DioException e) => e.stackTrace
                    .toString()
                    .contains('test/stacktrace_test.dart'),
              ]),
            ),
          );
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );

    test(
      DioExceptionType.sendTimeout,
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final timeout = Duration(milliseconds: 10);
          final dio = Dio()
            ..options.sendTimeout = timeout
            ..options.baseUrl = 'https://does.not.exist';

          when(httpClientMock.openUrl('GET', any)).thenAnswer(
            (_) async {
              final request = MockHttpClientRequest();
              when(request.addStream(any)).thenAnswer(
                (_) async => Future.delayed(
                  Duration(milliseconds: timeout.inMilliseconds + 10),
                ),
              );
              when(request.headers).thenReturn(MockHttpHeaders());
              return request;
            },
          );

          await expectLater(
            dio.get('/test', data: 'some data'),
            throwsA(
              allOf([
                isA<DioException>(),
                (DioException e) => e.type == DioExceptionType.sendTimeout,
                (DioException e) => e.stackTrace
                    .toString()
                    .contains('test/stacktrace_test.dart'),
              ]),
            ),
          );
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );

    test(
      DioExceptionType.badCertificate,
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final dio = Dio()
            ..options.baseUrl = 'https://does.not.exist'
            ..httpClientAdapter = IOHttpClientAdapter(
              validateCertificate: (_, __, ___) => false,
            );

          when(httpClientMock.openUrl('GET', any)).thenAnswer(
            (_) async {
              final request = MockHttpClientRequest();
              final response = MockHttpClientResponse();
              when(request.close()).thenAnswer((_) => Future.value(response));
              when(response.certificate).thenReturn(null);
              return request;
            },
          );

          await expectLater(
            dio.get('/test'),
            throwsA(
              allOf([
                isA<DioException>(),
                (DioException e) => e.type == DioExceptionType.badCertificate,
                (DioException e) => e.stackTrace
                    .toString()
                    .contains('test/stacktrace_test.dart'),
              ]),
            ),
          );
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );
    group('DioExceptionType.connectionError', () {
      test(
        'SocketException on request',
        () async {
          final dio = Dio()
            ..options.baseUrl = 'https://does.not.exist'
            ..httpClientAdapter = IOHttpClientAdapter();
          await expectLater(
            dio.get('/test', data: 'test'),
            throwsA(
              allOf([
                isA<DioException>(),
                (e) => e.type == DioExceptionType.connectionError,
                (e) => e.error is SocketException,
                (e) => (e.error as SocketException)
                    .message
                    .contains("Failed host lookup: 'does.not.exist'"),
                (e) => e.stackTrace
                    .toString()
                    .contains('test/stacktrace_test.dart'),
              ]),
            ),
          );
        },
        testOn: 'vm',
      );
    });
    group('DioExceptionType.unknown', () {
      test(
        JsonUnsupportedObjectError,
        () async {
          final dio = Dio()..options.baseUrl = 'https://does.not.exist';

          await expectLater(
            dio.get(
              '/test',
              options: Options(contentType: Headers.jsonContentType),
              data: Object(),
            ),
            throwsA(
              allOf([
                isA<DioException>(),
                (DioException e) => e.type == DioExceptionType.unknown,
                (DioException e) => e.error is JsonUnsupportedObjectError,
                (DioException e) => e.stackTrace
                    .toString()
                    .contains('test/stacktrace_test.dart'),
              ]),
            ),
          );
        },
        testOn: '!browser',
      );

      test(
        'SocketException on response',
        () async {
          final dio = Dio()
            ..options.baseUrl = 'https://does.not.exist'
            ..httpClientAdapter = IOHttpClientAdapter(
              createHttpClient: () {
                final request = MockHttpClientRequest();
                final client = MockHttpClient();
                when(client.openUrl(any, any)).thenAnswer((_) async => request);
                when(request.headers).thenReturn(MockHttpHeaders());
                when(request.addStream(any)).thenAnswer((_) => Future.value());
                when(request.close()).thenAnswer(
                  (_) => Future.delayed(Duration(milliseconds: 50), () {
                    throw SocketException('test');
                  }),
                );
                return client;
              },
            );

          await expectLater(
            dio.get('/test', data: 'test'),
            throwsA(
              allOf([
                isA<DioException>(),
                (e) => e.type == DioExceptionType.unknown,
                (e) => e.error is SocketException,
                (e) => e.stackTrace
                    .toString()
                    .contains('test/stacktrace_test.dart'),
              ]),
            ),
          );
        },
        testOn: 'vm',
      );
    });

    test('Interceptor gets stacktrace in onError', () async {
      final dio = Dio()
        ..options.baseUrl = EchoAdapter.mockBase
        ..httpClientAdapter = EchoAdapter();

      StackTrace? caughtStackTrace;
      dio.interceptors.addAll([
        InterceptorsWrapper(
          onError: (err, handler) {
            caughtStackTrace = err.stackTrace;
            handler.next(err);
          },
        ),
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final error = DioException(error: Error(), requestOptions: options);
            handler.reject(error, true);
          },
        ),
      ]);

      await expectLater(
        dio.get('/error'),
        throwsA(
          allOf([
            isA<DioException>(),
            (e) => e.stackTrace == caughtStackTrace,
            (e) =>
                e.stackTrace.toString().contains('test/stacktrace_test.dart'),
          ]),
        ),
        reason: 'Stacktrace should be available in onError',
      );
    });

    test('QueuedInterceptor gets stacktrace in onError', () async {
      final dio = Dio()
        ..options.baseUrl = EchoAdapter.mockBase
        ..httpClientAdapter = EchoAdapter();

      StackTrace? caughtStackTrace;
      dio.interceptors.addAll([
        QueuedInterceptorsWrapper(
          onError: (err, handler) {
            caughtStackTrace = err.stackTrace;
            handler.next(err);
          },
        ),
        QueuedInterceptorsWrapper(
          onRequest: (options, handler) {
            final error = DioException(
              error: Error(),
              requestOptions: options,
            );
            handler.reject(error, true);
          },
        ),
      ]);

      await expectLater(
        dio.get('/error'),
        throwsA(
          allOf([
            isA<DioException>(),
            (e) => e.stackTrace == caughtStackTrace,
            (e) =>
                e.stackTrace.toString().contains('test/stacktrace_test.dart'),
          ]),
        ),
        reason: 'Stacktrace should be available in onError',
      );
    });
  });
}
