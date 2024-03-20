import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_test/util.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void downloadStreamTests(
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

        final size = 50000;
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
          queryParameters: {'duration': '5', 'delay': '0'},
          options: Options(responseType: ResponseType.stream),
          cancelToken: cancelToken,
        );

        Future.delayed(const Duration(seconds: 2), () {
          cancelToken.cancel();
        });

        final completer = Completer();
        res.data!.stream.listen((event) {}, onError: (e, s) {
          completer.completeError(e, s);
        });

        await expectLater(
          completer.future,
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_stream_tests.dart',
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
            queryParameters: {'duration': '5', 'delay': '0'},
            cancelToken: cancelToken,
          ),
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_stream_tests.dart',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 250), () {});
        expect(File(path).existsSync(), false);
      });

      test('cancels streamed response mid request', () async {
        final cancelToken = CancelToken();
        final response = await dio.get(
          '/bytes/${1024 * 1024 * 100}',
          options: Options(responseType: ResponseType.stream),
          cancelToken: cancelToken,
          onReceiveProgress: (c, t) {
            if (c > 5000) {
              cancelToken.cancel();
            }
          },
        );

        await expectLater(
          (response.data as ResponseBody).stream.last,
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_stream_tests.dart',
          ),
        );
      });

      test('cancels download mid request', () async {
        final cancelToken = CancelToken();
        final path = p.join(tmp.path, 'download_2.txt');

        await expectLater(
          dio.download(
            '/bytes/${1024 * 1024 * 10}',
            path,
            cancelToken: cancelToken,
            onReceiveProgress: (c, t) {
              if (c > 5000) {
                cancelToken.cancel();
              }
            },
          ),
          throwsDioException(
            DioExceptionType.cancel,
            stackTraceContains: 'test/download_stream_tests.dart',
          ),
        );

        await Future.delayed(const Duration(milliseconds: 250), () {});
        expect(File(path).existsSync(), false);
      });
    },
    testOn: 'vm',
  );
}
