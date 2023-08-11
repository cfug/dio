@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'mock/adapters.dart';
import 'utils.dart';

void main() {
  setUp(startServer);
  tearDown(stopServer);
  test('download1', () async {
    const savePath = 'test/_download_test.md';
    final dio = Dio()..options.baseUrl = serverUrl.toString();
    await dio.download('/download', savePath);

    final f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
    f.deleteSync(recursive: false);
  });

  test('download2', () async {
    const savePath = 'test/_download_test.md';
    final dio = Dio()..options.baseUrl = serverUrl.toString();
    await dio.downloadUri(
      serverUrl.replace(path: '/download'),
      (header) => savePath,
    );

    final f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
    f.deleteSync(recursive: false);
  });

  test('download error', () async {
    const savePath = 'test/_download_test.md';
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
    const savePath = 'test/_download_test.md';
    final dio = Dio(
      BaseOptions(
        receiveTimeout: Duration(milliseconds: 1),
        baseUrl: serverUrl.toString(),
      ),
    );
    expect(
      dio
          .download('/download', savePath)
          .catchError((e) => throw (e as DioException).type),
      throwsA(DioExceptionType.receiveTimeout),
    );
  });

  test('download cancellation', () async {
    const savePath = 'test/_download_test.md';
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
    const savePath = 'test/_download_test.md';
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
    const savePath = 'test/_download_test.md';
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
    final testPath = p.join(Directory.systemTemp.path, 'dio', 'testPath');

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
