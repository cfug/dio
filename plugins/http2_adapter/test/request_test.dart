import 'dart:io';

import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:dio/dio.dart';
import 'package:dio_test/util.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  final dio = Dio()
    ..httpClientAdapter = Http2Adapter(null)
    ..options.baseUrl = 'https://httpbun.com/';

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('dio_test_');
    addTearDown(() {
      tmp.deleteSync(recursive: true);
    });
  });

  group('requests >', () {
    test('download bytes', () async {
      final path = p.join(tmp.path, 'bytes.txt');

      final size = 10000;
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
      expect(progressEventCount, greaterThan(1));
      expect(count, total);
    });

    test('cancels request', () async {
      final cancelToken = CancelToken();

      Future.delayed(const Duration(milliseconds: 50), () {
        cancelToken.cancel();
      });

      await expectLater(
        dio.get(
          '/bytes/5000',
          options: Options(responseType: ResponseType.stream),
          cancelToken: cancelToken,
        ),
        throwsDioException(
          DioExceptionType.cancel,
          stackTraceContains: 'test/request_test.dart',
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
          '/bytes/5000',
          path,
          cancelToken: cancelToken,
        ),
        throwsDioException(
          DioExceptionType.cancel,
          stackTraceContains: 'test/request_test.dart',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 250), () {});
      expect(File(path).existsSync(), false);
    });

    test('cancels streamed response mid request', () async {
      final cancelToken = CancelToken();
      final response = await dio.get(
        'bytes/${1024 * 1024 * 100}',
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
          stackTraceContains: 'test/request_test.dart',
        ),
      );
    });

    test('cancels download mid request', () async {
      final cancelToken = CancelToken();
      final path = p.join(tmp.path, 'download_2.txt');

      await expectLater(
        dio.download(
          'bytes/${1024 * 1024 * 10}',
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
          stackTraceContains: 'test/request_test.dart',
        ),
      );

      await Future.delayed(const Duration(milliseconds: 250), () {});
      expect(File(path).existsSync(), false);
    });
  });
}
