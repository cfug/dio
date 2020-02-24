// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

void main() {
  test('#send with an invalid URL', () {
    expect(Dio().get('http://http.invalid').catchError((e) => throw e.error),
        throwsA(const TypeMatcher<SocketException>()));
  });
  test('#cancellation', () async {
    var dio = Dio();
    CancelToken token = CancelToken();
    Timer(Duration(milliseconds: 10), () {
      token.cancel('cancelled');
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
