// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'package:dio/dio.dart';
import 'package:test/test.dart';

import 'echo_adapter.dart';

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
      contentType: 'application/json',
      followRedirects: false,
    );
    var opt1 = baseOptions.copyWith(
      method: 'post',
      receiveTimeout: 3000,
      sendTimeout: 3000,
      baseUrl: 'https://flutterchina.club',
      extra: mapOverride,
      headers: mapOverride,
      contentType: 'text/html',
    );
    assert(opt1.method == 'post');
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
      contentType: 'application/json',
      followRedirects: false,
    );

    var opt3 = opt2.copyWith(
      method: 'post',
      receiveTimeout: 3000,
      sendTimeout: 3000,
      extra: mapOverride,
      headers: mapOverride,
      contentType: 'text/html',
    );

    assert(opt3.method == 'post');
    assert(opt3.receiveTimeout == 3000);
    assert(opt3.followRedirects == false);
    assert(opt3.headers!['b'] == '6');
    assert(opt3.extra!['b'] == '6');
    assert(opt3.contentType == 'text/html');

    var opt4 = RequestOptions(
      path: '/xxx',
      sendTimeout: 2000,
      followRedirects: false,
    );
    var opt5 = opt4.copyWith(
      method: 'post',
      receiveTimeout: 3000,
      sendTimeout: 3000,
      extra: mapOverride,
      headers: mapOverride,
      data: 'xx=5',
      path: '/',
      contentType: 'text/html',
    );
    assert(opt5.method == 'post');
    assert(opt5.receiveTimeout == 3000);
    assert(opt5.followRedirects == false);
    assert(opt5.contentType == 'text/html');
    assert(opt5.headers['b'] == '6');
    assert(opt5.extra['b'] == '6');
    assert(opt5.data == 'xx=5');
    assert(opt5.path == '/');

    // Keys of header are case-insensitive
    expect(opt5.headers['B'], '6');
    opt5.headers['B'] = 9;
    assert(opt5.headers['b'] == 9);
  });
  test('#test options content-type', () {
    const contentType = 'text/html';
    const contentTypeJson = 'appliction/json';
    var headers = {'content-type': contentType};
    var jsonHeaders = {'content-type': contentTypeJson};

    try {
      BaseOptions(contentType: contentType, headers: headers);
      assert(false, 'baseOptions1');
    } catch (e) {
      //
    }

    var bo1 = BaseOptions(contentType: contentType);
    var bo2 = BaseOptions(headers: headers);

    assert(bo1.headers['content-type'] == contentType);
    assert(bo2.headers['content-type'] == contentType);

    try {
      bo1.copyWith(headers: headers);
      assert(false, 'baseOptions copyWith 1');
    } catch (e) {
      //
    }

    try {
      bo2.copyWith(contentType: contentType);
      assert(false, 'baseOptions copyWith 2');
    } catch (e) {
      //
    }

    /// options
    try {
      Options(contentType: contentType, headers: headers);
      assert(false, 'Options1');
    } catch (e) {
      //
    }

    var o1 = Options(contentType: contentType);
    var o2 = Options(headers: headers);

    try {
      o1.copyWith(headers: headers);
      assert(false, 'Options copyWith 1');
    } catch (e) {
      //
    }

    try {
      o2.copyWith(contentType: contentType);
      assert(false, 'Options copyWith 2');
    } catch (e) {
      //
    }

    assert(Options(contentType: contentTypeJson).compose(bo1, '').contentType ==
        contentTypeJson);

    assert(Options(contentType: contentTypeJson).compose(bo2, '').contentType ==
        contentTypeJson);

    assert(Options(headers: jsonHeaders).compose(bo1, '').contentType ==
        contentTypeJson);

    assert(Options(headers: jsonHeaders).compose(bo2, '').contentType ==
        contentTypeJson);

    /// RequestOptions
    try {
      RequestOptions(path: '', contentType: contentType, headers: headers);
      assert(false, 'Options1');
    } catch (e) {
      //
    }

    var ro1 = RequestOptions(path: '', contentType: contentType);
    var ro2 = RequestOptions(path: '', headers: headers);

    try {
      ro1.copyWith(headers: headers);
      assert(false, 'RequestOptions copyWith 1');
    } catch (e) {
      //
    }

    try {
      ro2.copyWith(contentType: contentType);
      assert(false, 'RequestOptions copyWith 2');
    } catch (e) {
      //
    }
  });

  test('#test default content-type', () async {
    var dio = Dio();
    dio.options.baseUrl = EchoAdapter.mockBase;
    dio.httpClientAdapter = EchoAdapter();

    var r1 = await dio.get('');
    assert(r1.requestOptions.headers[Headers.contentTypeHeader] == null);

    dio.options.setRequestContentTypeWhenNoPayload = true;

    r1 = await dio.get('');
    assert(r1.requestOptions.headers[Headers.contentTypeHeader] ==
        Headers.jsonContentType);

    dio.options.setRequestContentTypeWhenNoPayload = false;

    var r2 = await dio.get(
      '',
      options: Options(contentType: Headers.jsonContentType),
    );

    assert(r2.requestOptions.headers[Headers.contentTypeHeader] ==
        Headers.jsonContentType);

    var r3 = await dio.get(
      '',
      options: Options(headers: {
        Headers.contentTypeHeader: Headers.jsonContentType,
      }),
    );
    assert(r3.requestOptions.headers[Headers.contentTypeHeader] ==
        Headers.jsonContentType);

    var r4 = await dio.post('', data: '');
    assert(r4.requestOptions.headers[Headers.contentTypeHeader] ==
        Headers.jsonContentType);
  });

  test('#test default content-type2', () async {
    final dio = Dio();
    dio.options.setRequestContentTypeWhenNoPayload = true;
    Options(method: 'GET')
        .compose(dio.options, '/test')
        .copyWith(baseUrl: 'https://www.example.com');

    var r1 = Options(method: 'GET').compose(dio.options, '/test').copyWith(
      headers: {Headers.contentTypeHeader: Headers.textPlainContentType},
    );
    assert(
        r1.headers[Headers.contentTypeHeader] == Headers.textPlainContentType);

    var r2 = Options(method: 'GET').compose(dio.options, '/test').copyWith(
          contentType: Headers.textPlainContentType,
        );
    assert(
        r2.headers[Headers.contentTypeHeader] == Headers.textPlainContentType);

    try {
      Options(method: 'GET').compose(dio.options, '/test').copyWith(
        headers: {Headers.contentTypeHeader: Headers.textPlainContentType},
        contentType: Headers.formUrlEncodedContentType,
      );
      assert(false);
    } catch (e) {
      //
    }

    dio.options.setRequestContentTypeWhenNoPayload = false;

    var r3 = Options(method: 'GET')
        .compose(dio.options, '/test')
        .copyWith(baseUrl: 'https://www.example.com');
    assert(r3.headers[Headers.contentTypeHeader] == null);
  });
}
