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
    final dio = Dio();
    dio.options.baseUrl = serverUrl.toString();
    await dio.download(
      '/download', savePath, // disable gzip
      onReceiveProgress: (received, total) {
        // ignore progress
      },
    );

    final f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
    f.deleteSync(recursive: false);
  });

  test('download2', () async {
    const savePath = 'test/_download_test.md';
    final dio = Dio();
    dio.options.baseUrl = serverUrl.toString();
    await dio.downloadUri(
      serverUrl.replace(path: '/download'),
      (header) => savePath, // disable gzip
    );

    final f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
    f.deleteSync(recursive: false);
  });

  test('download error', () async {
    const savePath = 'test/_download_test.md';
    final dio = Dio();
    dio.options.baseUrl = serverUrl.toString();
    Response response = await dio
        .download('/error', savePath)
        .catchError((e) => (e as DioError).response!);
    expect(response.data, 'error');
    response = await dio
        .download(
          '/error',
          savePath,
          options: Options(receiveDataWhenStatusError: false),
        )
        .catchError((e) => (e as DioError).response!);
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
          .catchError((e) => throw (e as DioError).type),
      throwsA(DioErrorType.receiveTimeout),
    );
    //print(r);
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
          .catchError((e) => throw (e as DioError).type),
      throwsA(DioErrorType.cancel),
    );
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
