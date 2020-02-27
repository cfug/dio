// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('#test options', () {
    var map = {'a': '5'};
    var mapOverride = {'b': '6'};
    var baseOptions = BaseOptions(
      connectTimeout: 2000,
      receiveTimeout: 2000,
      sendTimeout: 2000,
      baseUrl: 'http://localhost',
      queryParameters: map,
      extra: map,
      headers: map,
      contentType: "application/json",
      followRedirects: false,
    );
    var opt1 = baseOptions.merge(
      method: 'post',
      receiveTimeout: 3000,
      sendTimeout: 3000,
      baseUrl: 'https://flutterchina.club',
      extra: mapOverride,
      headers: mapOverride,
      contentType: 'text/html',
    );
    assert(opt1.method == "post");
    assert(opt1.receiveTimeout == 3000);
    assert(opt1.connectTimeout == 2000);
    assert(opt1.followRedirects == false);
    assert(opt1.baseUrl == 'https://flutterchina.club');
    assert(opt1.headers['b'] == '6');
    assert(opt1.extra['b'] == '6');
    assert(opt1.queryParameters['b'] == null);
    assert(opt1.contentType == 'text/html');

    var opt2 = Options(
      method: 'get',
      receiveTimeout: 2000,
      sendTimeout: 2000,
      extra: map,
      headers: map,
      contentType: "application/json",
      followRedirects: false,
    );
    var opt3 = opt2.merge(
      method: 'post',
      receiveTimeout: 3000,
      sendTimeout: 3000,
      extra: mapOverride,
      headers: mapOverride,
      contentType: 'text/html',
    );
    assert(opt3.method == "post");
    assert(opt3.receiveTimeout == 3000);
    assert(opt3.followRedirects == false);
    assert(opt3.headers['b'] == '6');
    assert(opt3.extra['b'] == '6');
    assert(opt3.contentType == 'text/html');

    var opt4 = RequestOptions(
      sendTimeout: 2000,
      followRedirects: false,
    );
    var opt5 = opt4.merge(
      method: 'post',
      receiveTimeout: 3000,
      sendTimeout: 3000,
      extra: mapOverride,
      headers: mapOverride,
      data: "xx=5",
      path: '/',
      contentType: 'text/html',
    );
    assert(opt5.method == "post");
    assert(opt5.receiveTimeout == 3000);
    assert(opt5.followRedirects == false);
    assert(opt5.contentType == 'text/html');
    assert(opt5.headers['b'] == '6');
    assert(opt5.extra['b'] == '6');
    assert(opt5.data == 'xx=5');
    assert(opt5.path == '/');
  });

  test('#test headers', () {
    var headers = Headers.fromMap({
      "set-cookie": ['k=v', 'k1=v1'],
      'content-length': ['200'],
      'test': ['1', '2'],
    });
    headers.add('SET-COOKIE', 'k2=v2');
    assert(headers.value('content-length') == '200');
    expect(Future(() => headers.value('test')), throwsException);
    assert(headers['set-cookie'].length == 3);
    headers.remove("set-cookie", 'k=v');
    assert(headers['set-cookie'].length == 2);
    headers.removeAll('set-cookie');
    assert(headers['set-cookie'] == null);
    var ls = [];
    headers.forEach((k, list) {
      ls.addAll(list);
    });
    assert(ls.length == 3);
    assert(headers.toString() == "content-length: 200\ntest: 1\ntest: 2\n");
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
    expect(Dio().get('http://http.invalid').catchError((e) => throw e.error),
        throwsA(const TypeMatcher<SocketException>()));
  });

  test('#cancellation', () async {
    var dio = Dio();
    CancelToken token = CancelToken();
    Timer(Duration(milliseconds: 10), () {
      token.cancel('cancelled');
      dio.httpClientAdapter.close(force: true);
    });

    var url = 'https://accounts.google.com';
    expect(
        dio
            .get(url, cancelToken: token)
            .catchError((e) => throw CancelToken.isCancel(e)),
        throwsA(isTrue));
  });

  test('#url encode ', () {
    var data = {
      'a': '你好',
      'b': [5, '6'],
      'c': {
        'd': 8,
        'e': {
          'a': 5,
          'b': [66, 8]
        }
      }
    };
    var result =
        'a=%E4%BD%A0%E5%A5%BD&b%5B%5D=5&b%5B%5D=6&c%5Bd%5D=8&c%5Be%5D%5Ba%5D=5&c%5Be%5D%5Bb%5D%5B%5D=66&c%5Be%5D%5Bb%5D%5B%5D=8';
    expect(Transformer.urlEncodeMap(data), result);
  });
}
