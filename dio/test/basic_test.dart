// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {

  test('#test headers', () {
    var headers = Headers.fromMap({
      'set-cookie': ['k=v', 'k1=v1'],
      'content-length': ['200'],
      'test': ['1', '2'],
    });
    headers.add('SET-COOKIE', 'k2=v2');
    assert(headers.value('content-length') == '200');
    expect(Future(() => headers.value('test')), throwsException);
    assert(headers['set-cookie']?.length == 3);
    headers.remove('set-cookie', 'k=v');
    assert(headers['set-cookie']?.length == 2);
    headers.removeAll('set-cookie');
    assert(headers['set-cookie'] == null);
    var ls = [];
    headers.forEach((k, list) {
      ls.addAll(list);
    });
    assert(ls.length == 3);
    assert(headers.toString() == 'content-length: 200\ntest: 1\ntest: 2\n');
    headers.set('content-length', '300');
    assert(headers.value('content-length') == '300');
    headers.set('content-length', ['400']);
    assert(headers.value('content-length') == '400');

    var headers1 = Headers();
    headers1.set('xx', 'v');
    assert(headers1.value('xx') == 'v');
    headers1.clear();
    assert(headers1.map.isEmpty == true);
  });

  test('#send with an invalid URL', () {
    expect(
      Dio().get('http://http.invalid').catchError((e) => throw e.error),
      throwsA(const TypeMatcher<SocketException>()),
    );
  });

  test('#cancellation', () async {
    var dio = Dio();
    final token = CancelToken();
    Timer(Duration(milliseconds: 10), () {
      token.cancel('cancelled');
      dio.httpClientAdapter.close(force: true);
    });

    var url = 'https://accounts.google.com';
    expect(
      dio
          .get(url, cancelToken: token)
          .catchError((e) => throw CancelToken.isCancel(e)),
      throwsA(isTrue),
    );
  });

  test('#status error', () async {
    var dio = Dio()..options.baseUrl = 'http://httpbin.org/status/';

    expect(
      dio.get('401').catchError((e) => throw e.response.statusCode),
      throwsA(401),
    );

    var r = await dio.get(
      '401',
      options: Options(validateStatus: (status) => true),
    );
    expect(r.statusCode, 401);
  });
}
