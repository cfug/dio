// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  setUp(startServer);
  tearDown(stopServer);
  test('#test download1', () async {
    const savePath = '../_download_test.md';
    var dio = Dio();
    dio.options.baseUrl = serverUrl.toString();
    await dio.download(
      '/download', savePath, // disable gzip
      onReceiveProgress: (received, total) {
        // ignore progress
      },
    );

    var f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
    f.deleteSync(recursive: false);
  });

  test('#test download2', () async {
    const savePath = '../_download_test.md';
    var dio = Dio();
    dio.options.baseUrl = serverUrl.toString();
    await dio.downloadUri(
      serverUrl.replace(path: '/download'),
      (header) => savePath, // disable gzip
    );

    var f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
    f.deleteSync(recursive: false);
  });

  test('#test download error', () async {
    const savePath = '../_download_test.md';
    var dio = Dio();
    dio.options.baseUrl = serverUrl.toString();
    var r =
        await dio.download('/error', savePath).catchError((e) => e.response);
    assert(r.data == 'error');
    r = await dio
        .download(
          '/error',
          savePath,
          options: Options(receiveDataWhenStatusError: false),
        )
        .catchError((e) => e.response);
    assert(r.data == null);
  });

  test('#test download timeout', () async {
    const savePath = '../_download_test.md';
    var dio = Dio(BaseOptions(
      receiveTimeout: 1,
      baseUrl: serverUrl.toString(),
    ));
    expect(dio.download('/download', savePath).catchError((e) => throw e.type),
        throwsA(DioErrorType.receiveTimeout));
    //print(r);
  });

  test('#test download cancellation', () async {
    const savePath = '../_download_test.md';
    var cancelToken = CancelToken();
    Future.delayed(Duration(milliseconds: 100), () {
      cancelToken.cancel();
    });
    expect(
      Dio()
          .download(
            serverUrl.toString() + '/download',
            savePath,
            cancelToken: cancelToken,
          )
          .catchError((e) => throw e.type),
      throwsA(DioErrorType.cancel),
    );
    //print(r);
  });
}
