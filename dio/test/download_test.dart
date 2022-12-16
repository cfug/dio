// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'mock/adapters.dart';
import 'utils.dart';

void main() {
  setUp(startServer);
  tearDown(stopServer);
  test('#test download1', () async {
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

  test('#test download2', () async {
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

  test('#test download error', () async {
    const savePath = 'test/_download_test.md';
    final dio = Dio();
    dio.options.baseUrl = serverUrl.toString();
    Response response = await dio
        .download('/error', savePath)
        .catchError((e) => (e as DioError).response!);
    assert(response.data == 'error');
    response = await dio
        .download(
          '/error',
          savePath,
          options: Options(receiveDataWhenStatusError: false),
        )
        .catchError((e) => (e as DioError).response!);
    assert(response.data == null);
  });

  test('#test download timeout', () async {
    const savePath = 'test/_download_test.md';
    final dio = Dio(BaseOptions(
      receiveTimeout: Duration(milliseconds: 1),
      baseUrl: serverUrl.toString(),
    ));
    expect(
        dio
            .download('/download', savePath)
            .catchError((e) => throw (e as DioError).type),
        throwsA(DioErrorType.receiveTimeout));
    //print(r);
  });

  test('#test download cancellation', () async {
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
    //print(r);
  });

  test('Test `savePath` types', () async {
    Object? error;
    final dio = Dio()
      ..options.baseUrl = EchoAdapter.mockBase
      ..httpClientAdapter = EchoAdapter();
    try {
      await dio.download('/test', 'testPath');
      await dio.download('/test', (headers) => 'testPath');
      await dio.download('/test', (headers) async => 'testPath');
    } catch (e) {
      error = e;
    }
    expect(error, null);
  });
}
