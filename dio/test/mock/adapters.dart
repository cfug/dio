import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class MockAdapter implements HttpClientAdapter {
  static const mockHost = 'mockserver';
  static const mockBase = 'https://$mockHost';
  final _adapter = IOHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    if (uri.host == mockHost) {
      switch (uri.path) {
        case '/test':
          return ResponseBody.fromString(
            jsonEncode({
              'errCode': 0,
              'data': {'path': uri.path}
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        case '/test-auth':
          return Future.delayed(Duration(milliseconds: 300), () {
            if (options.headers['csrfToken'] == null) {
              return ResponseBody.fromString(
                jsonEncode({
                  'errCode': -1,
                  'data': {'path': uri.path}
                }),
                401,
                headers: {
                  Headers.contentTypeHeader: [Headers.jsonContentType],
                },
              );
            }
            return ResponseBody.fromString(
              jsonEncode({
                'errCode': 0,
                'data': {'path': uri.path}
              }),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          });
        case '/download':
          return Future.delayed(Duration(milliseconds: 300), () {
            return ResponseBody(
              File('./README.md').openRead().cast<Uint8List>(),
              200,
              headers: {
                Headers.contentLengthHeader: [
                  File('./README.md').lengthSync().toString()
                ],
              },
            );
          });
        case '/token':
          final t = 'ABCDEFGHIJKLMN'.split('')..shuffle();
          return ResponseBody.fromBytes(
            utf8.encode(
              jsonEncode({
                'errCode': 0,
                'data': {'token': t.join()}
              }),
            ),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        case '/test-plain-text-content-type':
          return ResponseBody.fromString(
            '{"code":0,"result":"ok"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.textPlainContentType],
            },
          );
        case '/test-timeout':
          await Future.delayed(const Duration(days: 365));
          return ResponseBody.fromString('', 200);
        default:
          return ResponseBody.fromString('', 404);
      }
    }
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}

/// [EchoAdapter] will return the data as-is
/// if the host is [EchoAdapter.mockHost].
class EchoAdapter implements HttpClientAdapter {
  static const String mockHost = 'mockserver';
  static const String mockBase = 'https://$mockHost';

  final HttpClientAdapter _adapter = IOHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final Uri uri = options.uri;
    if (uri.host == mockHost) {
      final statusCode = int.tryParse(uri.path.replaceFirst('/', '')) ?? 200;
      if (requestStream != null) {
        return ResponseBody(requestStream, statusCode);
      } else {
        return ResponseBody.fromString(uri.path, statusCode);
      }
    }
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}
