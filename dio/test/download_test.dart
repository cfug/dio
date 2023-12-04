@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'mock/adapters.dart';
import 'utils.dart';

void main() {
  late Directory tmp;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('dio_test_');
    addTearDown(() {
      tmp.deleteSync(recursive: true);
    });
    print(tmp.path);
  });

  setUp(startServer);
  tearDown(stopServer);

  test('download does not change the response type', () async {
    final savePath = p.join(tmp.path, 'download0.md');

    final dio = Dio()..options.baseUrl = serverUrl.toString();
    final options = Options(responseType: ResponseType.plain);
    await dio.download('/download', savePath, options: options);
    expect(options.responseType, ResponseType.plain);
  });

  test('download1', () async {
    final savePath = p.join(tmp.path, 'download1.md');
    final dio = Dio()..options.baseUrl = serverUrl.toString();
    await dio.download('/download', savePath);

    final f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
    f.deleteSync(recursive: false);
  });

  test('download2', () async {
    final savePath = p.join(tmp.path, 'download2.md');
    final dio = Dio()..options.baseUrl = serverUrl.toString();
    await dio.downloadUri(
      serverUrl.replace(path: '/download'),
      (header) => savePath,
    );

    final f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
  });

  test('download error', () async {
    final savePath = p.join(tmp.path, 'download_error.md');
    final dio = Dio()..options.baseUrl = serverUrl.toString();
    Response response = await dio
        .download('/error', savePath)
        .catchError((e) => (e as DioException).response!);
    expect(response.data, 'error');
    response = await dio
        .download(
          '/error',
          savePath,
          options: Options(receiveDataWhenStatusError: false),
        )
        .catchError((e) => (e as DioException).response!);
    expect(response.data, null);
  });

  test('download timeout', () async {
    final dio = Dio();
    final timeoutMatcher = allOf([
      throwsA(isA<DioException>()),
      throwsA(
        predicate<DioException>(
          (e) => e.type == DioExceptionType.receiveTimeout,
        ),
      ),
    ]);
    await expectLater(
      dio.downloadUri(
        Uri.parse('$serverUrl/download').replace(
          queryParameters: {'count': '3', 'gap': '2'},
        ),
        p.join(tmp.path, 'download_timeout.md'),
        options: Options(receiveTimeout: Duration(seconds: 1)),
      ),
      timeoutMatcher,
    );
    // Throws nothing if it constantly gets response bytes.
    await dio.download(
      'https://github.com/cfug/flutter.cn/archive/refs/heads/main.zip',
      p.join(tmp.path, 'main.zip'),
      options: Options(receiveTimeout: Duration(seconds: 1)),
    );
  });

  test('download cancellation', () async {
    final savePath = p.join(tmp.path, 'download_cancellation.md');
    final cancelToken = CancelToken();
    Future.delayed(Duration(milliseconds: 100), () {
      cancelToken.cancel();
    });
    expect(
      Dio()
          .download(
            '$serverUrl/download',
            savePath,
            cancelToken: cancelToken,
          )
          .catchError((e) => throw (e as DioException).type),
      throwsA(DioExceptionType.cancel),
    );
  });

  test('delete on error', () async {
    final savePath = p.join(tmp.path, 'delete_on_error.md');
    final f = File(savePath)..createSync(recursive: true);
    expect(f.existsSync(), isTrue);

    final dio = Dio()..options.baseUrl = serverUrl.toString();
    await expectLater(
      dio
          .download(
            '/download',
            savePath,
            deleteOnError: true,
            onReceiveProgress: (count, total) => throw AssertionError(),
          )
          .catchError((e) => throw (e as DioException).error!),
      throwsA(isA<AssertionError>()),
    );
    expect(f.existsSync(), isFalse);
  });

  test('delete on cancel', () async {
    final savePath = p.join(tmp.path, 'delete_on_cancel.md');
    final f = File(savePath)..createSync(recursive: true);
    expect(f.existsSync(), isTrue);

    final cancelToken = CancelToken();
    final dio = Dio()..options.baseUrl = serverUrl.toString();
    await expectLater(
      dio
          .download(
            '/download',
            savePath,
            deleteOnError: true,
            cancelToken: cancelToken,
            onReceiveProgress: (count, total) => cancelToken.cancel(),
          )
          .catchError((e) => throw (e as DioException).type),
      throwsA(DioExceptionType.cancel),
    );
    await Future.delayed(const Duration(milliseconds: 100));
    expect(f.existsSync(), isFalse);
  });

  test('`savePath` types', () async {
    final testPath = p.join(tmp.path, 'savePath');

    final dio = Dio()
      ..options.baseUrl = EchoAdapter.mockBase
      ..httpClientAdapter = EchoAdapter();

    await expectLater(
      dio.download('/test', testPath),
      completes,
    );
    await expectLater(
      dio.download('/test', (headers) => testPath),
      completes,
    );
    await expectLater(
      dio.download('/test', (headers) async => testPath),
      completes,
    );
  });
}
