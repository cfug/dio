@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'utils.dart';

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
      await dio.download(
        '/bytes/$size',
        path,
        onReceiveProgress: (c, t) {
          count = c;
          progressEventCount++;
        },
      );

      final f = File(path);
      expect(count, f.readAsBytesSync().length);
      expect(progressEventCount, greaterThan(1));
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

    test('cancels streamed responses', () async {
      final cancelToken = CancelToken();
      final response = await dio.get(
        'bytes/${1024 * 1024 * 10}',
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      Future.delayed(const Duration(milliseconds: 750), () {
        cancelToken.cancel();
      });

      expect(response.statusCode, 200);

      await expectLater(
        (response.data as ResponseBody).stream.last,
        throwsDioException(
          DioExceptionType.cancel,
          stackTraceContains: 'test/request_test.dart',
        ),
      );
    });
  });
}
