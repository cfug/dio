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
  group('DioException is thrown with correct stackTrace', () {
    test(DioExceptionType.badResponse, () async {
      final dio = Dio()
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = MockAdapter.mockBase;

      try {
        await dio.get('/foo');
        fail('should throw');
      } on DioException catch (e, s) {
        expect(e.type, DioExceptionType.badResponse);
        expect(s.toString(), contains('test/stacktrace_test.dart'));
      } catch (_) {
        fail('should throw DioException');
      }
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

      try {
        await dio.get('/test-timeout', cancelToken: token);
        fail('should throw');
      } on DioException catch (e, s) {
        expect(e.type, DioExceptionType.cancel);
        expect(s.toString(), contains('test/stacktrace_test.dart'));
      } catch (_) {
        fail('should throw DioException');
      }
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

          try {
            await dio.get('/test');
            fail('should throw');
          } on DioException catch (e, s) {
            expect(e.type, DioExceptionType.connectionTimeout);
            expect(s.toString(), contains('test/stacktrace_test.dart'));
          } catch (_) {
            fail('should throw DioException');
          }
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

          try {
            await dio.get('/test');
            fail('should throw');
          } on DioException catch (e, s) {
            expect(e.type, DioExceptionType.receiveTimeout);
            expect(s.toString(), contains('test/stacktrace_test.dart'));
          } catch (_) {
            fail('should throw DioException');
          }
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

          try {
            await dio.get('/test', data: 'some data');
            fail('should throw');
          } on DioException catch (e, s) {
            expect(e.type, DioExceptionType.sendTimeout);
            expect(s.toString(), contains('test/stacktrace_test.dart'));
          } catch (_) {
            fail('should throw DioException');
          }
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

          try {
            await dio.get('/test');
            fail('should throw');
          } on DioException catch (e, s) {
            expect(e.type, DioExceptionType.badCertificate);
            expect(s.toString(), contains('test/stacktrace_test.dart'));
          } catch (_) {
            fail('should throw DioException');
          }
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );

    group(DioExceptionType.connectionError, () {
      test(
        'SocketException on request',
        () async {
          final dio = Dio()
            ..options.baseUrl = 'https://does.not.exist'
            ..httpClientAdapter = IOHttpClientAdapter();

          try {
            await dio.get('/test', data: 'test');
            fail('should throw');
          } on DioException catch (e, s) {
            expect(e.type, DioExceptionType.connectionError);
            expect(e.cause, isA<SocketException>());
            expect(
              (e.cause as SocketException).message,
              contains("Failed host lookup: 'does.not.exist'"),
            );
            expect(s.toString(), contains('test/stacktrace_test.dart'));
          } catch (_) {
            fail('should throw DioException');
          }
        },
        testOn: 'vm',
      );
    });

    group(DioExceptionType.unknown, () {
      test(
        JsonUnsupportedObjectError,
        () async {
          final dio = Dio()..options.baseUrl = 'https://does.not.exist';

          try {
            await dio.get(
              '/test',
              options: Options(contentType: Headers.jsonContentType),
              data: Object(),
            );
            fail('should throw');
          } on DioException catch (e, s) {
            expect(e.type, DioExceptionType.unknown);
            expect(e.cause, isA<JsonUnsupportedObjectError>());
            expect(s.toString(), contains('test/stacktrace_test.dart'));
          } catch (_) {
            fail('should throw DioException');
          }
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

          try {
            await dio.get('/test', data: 'test');
            fail('should throw');
          } on DioException catch (e, s) {
            expect(e.type, DioExceptionType.unknown);
            expect(e.cause, isA<SocketException>());
            expect(s.toString(), contains('test/stacktrace_test.dart'));
          } catch (_) {
            fail('should throw DioException');
          }
        },
        testOn: 'vm',
      );
    });

    test('Interceptor gets stacktrace in onError', () async {
      final dio = Dio()
        ..options.baseUrl = EchoAdapter.mockBase
        ..httpClientAdapter = EchoAdapter();

      // StackTrace? caughtStackTrace;
      dio.interceptors.addAll([
        InterceptorsWrapper(
          onError: (err, handler) {
            // caughtStackTrace = err.bestStackTrace;
            handler.next(err);
          },
        ),
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final error = DioException(cause: Error(), requestOptions: options);
            handler.reject(error, true);
          },
        ),
      ]);

      try {
        await dio.get('/error');
        fail('should throw');
      } on DioException catch (e, s) {
        expect(e.type, DioExceptionType.unknown);
        expect(e.cause, isA<Error>());
        expect(s.toString(), contains('test/stacktrace_test.dart'));
        // expect(s, caughtStackTrace);
      } catch (_) {
        fail('should throw DioException');
      }
    });

    test('QueuedInterceptor gets stacktrace in onError', () async {
      final dio = Dio()
        ..options.baseUrl = EchoAdapter.mockBase
        ..httpClientAdapter = EchoAdapter();

      // StackTrace? caughtStackTrace;
      dio.interceptors.addAll([
        QueuedInterceptorsWrapper(
          onError: (err, handler) {
            // TODO should we get better access to the stacktrace here?
            // caughtStackTrace = err.bestStackTrace;
            handler.next(err);
          },
        ),
        QueuedInterceptorsWrapper(
          onRequest: (options, handler) {
            final error = DioException(
              cause: Error(),
              requestOptions: options,
            );
            handler.reject(error, true);
          },
        ),
      ]);

      try {
        await dio.get('/error');
        fail('should throw');
      } on DioException catch (e, s) {
        expect(e.type, DioExceptionType.unknown);
        expect(e.cause, isA<Error>());
        expect(s.toString(), contains('test/stacktrace_test.dart'));
        // expect(s, caughtStackTrace);
      } catch (_) {
        fail('should throw DioException');
      }
    });
  });
}
