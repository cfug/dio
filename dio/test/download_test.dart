// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  setUp(startServer);
  tearDown(stopServer);
  test('#test download', () async {
    const savePath = '../_download_test.md';
    var dio = Dio();
    dio.options.baseUrl = serverUrl.toString();
    await dio.download('/download', savePath, // disable gzip
        onReceiveProgress: (received, total) {
      if (total != -1) {
        print((received / total * 100).toStringAsFixed(0) + '%');
      }
    });

    var f = File(savePath);
    expect(f.readAsStringSync(), equals('I am a text file'));
    f.delete(recursive: false);
  });
}
