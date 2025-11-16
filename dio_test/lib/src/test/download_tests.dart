import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../util.dart';

void downloadTests(
  Dio Function(String baseUrl) create,
) {
  group(
    'download',
    () {
      late Dio dio;
      late Directory tmp;

      setUp(() {
        dio = create(httpbunBaseUrl);
      });

      setUpAll(() {
        tmp = Directory.systemTemp.createTempSync('dio_test_');
        addTearDown(() {
          tmp.deleteSync(recursive: true);
        });
      });

      test('bytes', () async {
        final path = p.join(tmp.path, 'bytes.txt');

        final size = 50;
        int progressEventCount = 0;
        int count = 0;
        int total = 0;
        await dio.download(
          '/bytes/$size',
          path,
          onReceiveProgress: (c, t) {
            count = c;
            total = t;
            progressEventCount++;
          },
        );

        final f = File(path);
        expect(count, f.readAsBytesSync().length);
        expect(progressEventCount, greaterThanOrEqualTo(1));
        expect(count, total);
      });

      test('cancels request', () async {
        final cancelToken = CancelToken();

        final res = await dio.get<ResponseBody>(
          '/drip',
          queryParameters: {'delay': '0', 'duration': '2'},
          options: Options(responseType: ResponseType.stream),
          cancelToken: cancelToken,
        );

        Future.delayed(const Duration(seconds: 1), () {
          cancelToken.cancel();
        });

        final completer = Completer<Never>();
        res.data!.stream.listen(
          (event) {},
          onError: (e, s) {
            completer.completeError(e, s);
          },
        );

        await expectLater(
          completer.future,
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );
      });

      test('cancels download', () async {
        final cancelToken = CancelToken();
        final path = p.join(tmp.path, 'download.txt');

        Future.delayed(const Duration(milliseconds: 50), () {
          cancelToken.cancel();
        });

        await expectLater(
          dio.download(
            '/drip',
            path,
            queryParameters: {'delay': '0', 'duration': '2'},
            cancelToken: cancelToken,
          ),
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 250), () {});
        expect(File(path).existsSync(), false);
      });

      test('cancels streamed response mid request', () async {
        final cancelToken = CancelToken();
        final response = await dio.get(
          '/drip',
          queryParameters: {'delay': '0', 'duration': '2', 'numbytes': '20'},
          options: Options(responseType: ResponseType.stream),
          cancelToken: cancelToken,
          onReceiveProgress: (c, t) {
            if (c > 10) {
              cancelToken.cancel();
            }
          },
        );

        await expectLater(
          (response.data as ResponseBody).stream.last,
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );
      });

      test('cancels download mid request', () async {
        final cancelToken = CancelToken();
        final path = p.join(tmp.path, 'download_2.txt');

        await expectLater(
          dio.download(
            '/drip',
            path,
            queryParameters: {'delay': '0', 'duration': '2', 'numbytes': '20'},
            cancelToken: cancelToken,
            onReceiveProgress: (c, t) {
              if (c > 10) {
                cancelToken.cancel();
              }
            },
          ),
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 250), () {});
        expect(File(path).existsSync(), false);
      });

      test('does not change the response type', () async {
        final savePath = p.join(tmp.path, 'download0.md');

        final options = Options(responseType: ResponseType.plain);
        await dio.download('/bytes/50', savePath, options: options);
        expect(options.responseType, ResponseType.plain);
      });

      test('text file', () async {
        final savePath = p.join(tmp.path, 'download.txt');

        int? total;
        int? count;
        await dio.download(
          '/payload',
          savePath,
          data: 'I am a text file',
          options: Options(
            contentType: Headers.textPlainContentType,
          ),
          onReceiveProgress: (c, t) {
            total = t;
            count = c;
          },
        );

        final f = File(savePath);
        expect(
          f.readAsStringSync(),
          equals('I am a text file'),
        );
        expect(count, f.readAsBytesSync().length);
        expect(count, total);
      });

      test('text file 2', () async {
        final savePath = p.join(tmp.path, 'download2.txt');

        await dio.downloadUri(
          Uri.parse(dio.options.baseUrl).replace(path: '/payload'),
          (header) => savePath,
          data: 'I am a text file',
          options: Options(
            contentType: Headers.textPlainContentType,
          ),
        );

        final f = File(savePath);
        expect(
          f.readAsStringSync(),
          equals('I am a text file'),
        );
      });

      test('error', () async {
        final savePath = p.join(tmp.path, 'download_error.md');

        expectLater(
          dio.download(
            '/mix/s=400/b64=${base64Encode('error'.codeUnits)}',
            savePath,
          ),
          throwsDioException(
            DioExceptionType.badResponse,
            stackTraceContains: 'test/download_tests.dart',
            matcher: isA<DioException>().having(
              (e) => e.response!.data,
              'data',
              'error',
            ),
          ),
        );

        expectLater(
          dio.download(
            '/mix/s=400/b64=${base64Encode('error'.codeUnits)}',
            savePath,
            options: Options(receiveDataWhenStatusError: false),
          ),
          throwsDioException(
            DioExceptionType.badResponse,
            stackTraceContains: 'test/download_tests.dart',
            matcher: isA<DioException>().having(
              (e) => e.response!.data,
              'data',
              isNull,
            ),
          ),
        );
      });

      test('receiveTimeout triggers if gaps are too big', () {
        expectLater(
          dio.download(
            '/drip',
            p.join(tmp.path, 'download_timeout.md'),
            queryParameters: {
              'delay': '0',
              'duration': '4',
              'numbytes': '2',
            },
            options: Options(receiveTimeout: const Duration(seconds: 1)),
          ),
          throwsDioException(
            DioExceptionType.receiveTimeout,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );
      });

      test(
        'receiveTimeout does not trigger if constantly getting response bytes',
        () {
          expectLater(
            dio.download(
              '/drip',
              p.join(tmp.path, 'download_timeout.md'),
              queryParameters: {
                'delay': '0',
                'duration': '4',
                'numbytes': '8',
              },
              options: Options(receiveTimeout: const Duration(seconds: 1)),
            ),
            completes,
          );
        },
      );

      test('delete on error', () async {
        final savePath = p.join(tmp.path, 'delete_on_error.txt');
        final f = File(savePath)..createSync(recursive: true);
        expect(f.existsSync(), isTrue);

        await expectLater(
          dio.download(
            '/drip',
            savePath,
            deleteOnError: true,
            queryParameters: {'delay': '0', 'duration': '2'},
            onReceiveProgress: (count, total) => throw AssertionError(),
          ),
          throwsDioException(
            DioExceptionType.unknown,
            stackTraceContains: 'test/download_tests.dart',
            matcher: isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<AssertionError>(),
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        expect(f.existsSync(), isFalse);
      });

      test('delete on cancel', () async {
        final savePath = p.join(tmp.path, 'delete_on_cancel.md');
        final f = File(savePath)..createSync(recursive: true);
        expect(f.existsSync(), isTrue);

        final cancelToken = CancelToken();

        await expectLater(
          dio.download(
            '/bytes/50',
            savePath,
            deleteOnError: true,
            cancelToken: cancelToken,
            onReceiveProgress: (count, total) => cancelToken.cancel(),
          ),
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        expect(f.existsSync(), isFalse);
      });

      test('cancel download mid stream', () async {
        const savePath = 'test/download/_test.md';
        final f = File(savePath)..createSync(recursive: true);
        expect(f.existsSync(), isTrue);

        final cancelToken = CancelToken();
        final dio = Dio()..options.baseUrl = httpbunBaseUrl;

        await expectLater(
          dio.download(
            '/drip',
            savePath,
            queryParameters: {'delay': '0', 'duration': '2', 'numbytes': '20'},
            cancelToken: cancelToken,
            deleteOnError: true,
            onReceiveProgress: (c, t) {
              if (c > 10) {
                cancelToken.cancel();
              }
            },
          ),
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));
        expect(f.existsSync(), isFalse);
      });

      test('`savePath` types', () async {
        final testPath = p.join(tmp.path, 'savePath.txt');

        await expectLater(
          dio.download(
            '/bytes/50',
            testPath,
          ),
          completes,
        );
        await expectLater(
          dio.download(
            '/bytes/50',
            (headers) => testPath,
          ),
          completes,
        );
        await expectLater(
          dio.download(
            '/bytes/50',
            (headers) async => testPath,
          ),
          completes,
        );
      });

      test('append bytes to previous download', () async {
        final cancelToken = CancelToken();
        final path = p.join(tmp.path, 'download_3.txt');
        int recievedBytes1 = 0;
        await expectLater(
          dio.download(
            '/drip',
            path,
            queryParameters: {'delay': '0', 'duration': '2', 'numbytes': '20'},
            cancelToken: cancelToken,
            onReceiveProgress: (c, t) {
              if (c > 10) {
                recievedBytes1 = c;
                cancelToken.cancel();
              }
            },
            deleteOnError: false,
          ),
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );

        final cancelToken2 = CancelToken();
        int recievedBytes2 = 0;
        expectLater(
          dio.download(
            '/drip',
            path,
            queryParameters: {'delay': '0', 'duration': '2', 'numbytes': '20'},
            cancelToken: cancelToken2,
            onReceiveProgress: (c, t) {
              recievedBytes2 = c;
              if (c > 10) {
                cancelToken2.cancel();
              }
            },
            deleteOnError: false,
            fileAccessMode: FileAccessMode.append,
          ),
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_tests.dart',
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100), () {});
        expect(File(path).lengthSync(), recievedBytes1 + recievedBytes2);
      });
    },
    testOn: 'vm',
  );
}
