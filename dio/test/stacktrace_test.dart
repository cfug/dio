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
  group('$DioError.stackTrace', () {
    test(DioErrorType.badResponse, () async {
      final dio = Dio(BaseOptions())
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = MockAdapter.mockBase;

      await expectLater(
        dio.get('/foo'),
        throwsA(allOf([
          isA<DioError>(),
          (DioError e) => e.type == DioErrorType.badResponse,
          (DioError e) =>
              e.stackTrace.toString().contains('test/stacktrace_test.dart'),
        ])),
      );
    });

    test(DioErrorType.cancel, () async {
      final dio = Dio(BaseOptions())
        ..httpClientAdapter = MockAdapter()
        ..options.baseUrl = MockAdapter.mockBase;

      final token = CancelToken();
      Future.delayed(const Duration(milliseconds: 10), () {
        token.cancel('cancelled');
        dio.httpClientAdapter.close(force: true);
      });

      await expectLater(
        dio.get('/test-timeout', cancelToken: token),
        throwsA(allOf([
          isA<DioError>(),
          (DioError e) => e.type == DioErrorType.cancel,
          (DioError e) =>
              e.stackTrace.toString().contains('test/stacktrace_test.dart'),
        ])),
      );
    });

    test(
      DioErrorType.connectionTimeout,
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final timeout = Duration(milliseconds: 10);
          final dio = Dio(BaseOptions()
            ..connectTimeout = timeout
            ..baseUrl = 'https://does.not.exist');

          when(httpClientMock.openUrl('GET', any)).thenAnswer((_) async {
            final request = MockHttpClientRequest();
            await Future.delayed(
                Duration(milliseconds: timeout.inMilliseconds + 10));
            return request;
          });

          await expectLater(
            dio.get('/test'),
            throwsA(allOf([
              isA<DioError>(),
              (DioError e) => e.type == DioErrorType.connectionTimeout,
              (DioError e) =>
                  e.stackTrace.toString().contains('test/stacktrace_test.dart'),
            ])),
          );
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );

    test(
      DioErrorType.receiveTimeout,
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final timeout = Duration(milliseconds: 10);
          final dio = Dio(BaseOptions()
            ..receiveTimeout = timeout
            ..baseUrl = 'https://does.not.exist');

          when(httpClientMock.openUrl('GET', any)).thenAnswer((_) async {
            final request = MockHttpClientRequest();
            final response = MockHttpClientResponse();
            when(request.close()).thenAnswer((_) => Future.delayed(
                  Duration(milliseconds: timeout.inMilliseconds + 10),
                  () => response,
                ));
            return request;
          });

          await expectLater(
            dio.get('/test'),
            throwsA(allOf([
              isA<DioError>(),
              (DioError e) => e.type == DioErrorType.receiveTimeout,
              (DioError e) =>
                  e.stackTrace.toString().contains('test/stacktrace_test.dart'),
            ])),
          );
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );

    test(
      DioErrorType.sendTimeout,
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final timeout = Duration(milliseconds: 10);
          final dio = Dio(BaseOptions()
            ..sendTimeout = timeout
            ..baseUrl = 'https://does.not.exist');

          when(httpClientMock.openUrl('GET', any)).thenAnswer((_) async {
            final request = MockHttpClientRequest();
            when(request.addStream(any)).thenAnswer(
              (_) async => Future.delayed(
                Duration(milliseconds: timeout.inMilliseconds + 10),
              ),
            );
            when(request.headers).thenReturn(MockHttpHeaders());
            return request;
          });

          await expectLater(
            dio.get('/test', data: 'some data'),
            throwsA(allOf([
              isA<DioError>(),
              (DioError e) => e.type == DioErrorType.sendTimeout,
              (DioError e) =>
                  e.stackTrace.toString().contains('test/stacktrace_test.dart'),
            ])),
          );
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );

    test(
      DioErrorType.badCertificate,
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final dio = Dio(BaseOptions()..baseUrl = 'https://does.not.exist')
            ..httpClientAdapter = (IOHttpClientAdapter()
              ..validateCertificate = (certificate, host, port) => false);

          when(httpClientMock.openUrl('GET', any)).thenAnswer((_) async {
            final request = MockHttpClientRequest();
            final response = MockHttpClientResponse();
            when(request.close()).thenAnswer((_) => Future.value(response));
            when(response.certificate).thenReturn(null);
            return request;
          });

          await expectLater(
            dio.get('/test'),
            throwsA(allOf([
              isA<DioError>(),
              (DioError e) => e.type == DioErrorType.badCertificate,
              (DioError e) =>
                  e.stackTrace.toString().contains('test/stacktrace_test.dart'),
            ])),
          );
        }, MockHttpOverrides());
      },
      testOn: '!browser',
    );

    test(
      DioErrorType.unknown,
      () async {
        final dio = Dio(BaseOptions()..baseUrl = 'https://does.not.exist');

        await expectLater(
          dio.get(
            '/test',
            options: Options(contentType: Headers.jsonContentType),
            data: Object(),
          ),
          throwsA(allOf([
            isA<DioError>(),
            (DioError e) => e.type == DioErrorType.unknown,
            (DioError e) => e.error is JsonUnsupportedObjectError,
            (DioError e) =>
                e.stackTrace.toString().contains('test/stacktrace_test.dart'),
          ])),
        );
      },
      testOn: '!browser',
    );
  });
}
