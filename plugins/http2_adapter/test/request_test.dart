@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;

  final dio = Dio()
    ..httpClientAdapter = Http2Adapter(null)
    ..options.baseUrl = 'https://httpbun.com/';

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('dio_http_download_test');
    addTearDown(() {
      tmp.deleteSync(recursive: true);
    });
  });

  group('requests', () {
    test('download README.md', () async {
      final path = p.join(tmp.path, 'README.md');

      int count = 0;
      int total = 0;
      final source = File('README.md');
      await dio.download(
        '/payload',
        path,
        options: Options(
          method: 'POST',
          contentType: 'text/plain',
        ),
        data: source.openRead(),
        onReceiveProgress: (c, t) {
          total = t;
          count = c;
        },
      );

      final f = File(path);
      expect(f.readAsStringSync(), source.readAsStringSync());
      expect(count, await source.length());

      // TODO: disabled pending https://github.com/sharat87/httpbun/issues/13
      // expect(count, total);
      expect(-1, total);
    });

    test('cancels request', () async {
      final cancelToken = CancelToken();

      expectLater(
        dio.get(
          'get',
          cancelToken: cancelToken,
        ),
        throwsA(predicate((DioException e) =>
            e.type == DioExceptionType.cancel &&
            e.message!
                .contains('The request was manually cancelled by the user'))),
      );

      Future.delayed(const Duration(milliseconds: 50), () {
        cancelToken.cancel();
      });
    });

    test('cancels streamed responses', () async {
      final cancelToken = CancelToken();
      final response = await dio.get(
        'bytes/${1024 * 1024 * 20}',
        options: Options(responseType: ResponseType.stream),
        cancelToken: cancelToken,
      );

      Future.delayed(const Duration(milliseconds: 750), () {
        cancelToken.cancel();
      });

      expect(response.statusCode, 200);

      await expectLater(
        (response.data as ResponseBody).stream.last,
        throwsA(predicate((DioException e) =>
            e.type == DioExceptionType.cancel &&
            e.message!
                .contains('The request was manually cancelled by the user'))),
      );
    });
  });
}
