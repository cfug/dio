@TestOn('vm')
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

typedef _FetchCallback = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
  Future<void>? cancelFuture,
);

class _TestAdapter implements HttpClientAdapter {
  _TestAdapter({required _FetchCallback fetch}) : _fetch = fetch;

  final _FetchCallback _fetch;
  final HttpClientAdapter _adapter = IOHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _fetch(options, requestStream, cancelFuture);

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}

class _SaveCall {
  _SaveCall(this.uri, this.cookies);

  final String uri;
  final String cookies;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SaveCall &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          cookies == other.cookies;

  @override
  int get hashCode => uri.hashCode ^ cookies.hashCode;

  @override
  String toString() {
    return '_SaveCall{uri: $uri, cookies: $cookies}';
  }
}

class _FakeCookieJar extends Fake implements CookieJar {
  final _saveCalls = <_SaveCall>[];

  List<_SaveCall> get saveCalls => UnmodifiableListView(_saveCalls);

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    return const [];
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    _saveCalls.add(
      _SaveCall(
        uri.toString(),
        cookies.join('; '),
      ),
    );
  }
}

void main() {
  group('CookieJar.saveFromResponse()', () {
    test(
      'is called with a full Uri for requests that had relative redirects',
      () async {
        final cookieJar = _FakeCookieJar();
        final dio = Dio()
          ..httpClientAdapter = _TestAdapter(
            fetch: (options, requestStream, cancelFuture) async => ResponseBody(
              Stream.value(Uint8List.fromList(utf8.encode(''))),
              HttpStatus.ok,
              redirects: [
                RedirectRecord(
                  HttpStatus.found,
                  'GET',
                  Uri(path: 'redirect'),
                ),
              ],
              headers: {
                HttpHeaders.setCookieHeader: ['Cookie1=value1; Path=/'],
              },
            ),
          )
          ..interceptors.add(CookieManager(cookieJar))
          ..options.validateStatus =
              (status) => status != null && status >= 200 && status < 400;

        await dio.get('https://test.com');
        expect(cookieJar.saveCalls, [
          _SaveCall(
            'https://test.com/redirect',
            'Cookie1=value1; Path=/',
          ),
        ]);
      },
    );

    test(
      'saves cookies only for final destination upon non-relative redirects',
      () async {
        final cookieJar = _FakeCookieJar();
        final dio = Dio()
          ..httpClientAdapter = _TestAdapter(
            fetch: (options, requestStream, cancelFuture) async => ResponseBody(
              Stream.value(Uint8List.fromList(utf8.encode(''))),
              HttpStatus.ok,
              redirects: [
                RedirectRecord(
                  HttpStatus.found,
                  'GET',
                  Uri.parse('https://example.com/redirect'),
                ),
              ],
              headers: {
                HttpHeaders.setCookieHeader: ['Cookie1=value1; Path=/'],
              },
            ),
          )
          ..interceptors.add(CookieManager(cookieJar))
          ..options.validateStatus =
              (status) => status != null && status >= 200 && status < 400;

        await dio.get('https://test.com');
        expect(cookieJar.saveCalls, [
          _SaveCall(
            'https://example.com/redirect',
            'Cookie1=value1; Path=/',
          ),
        ]);
      },
    );
  });
}
