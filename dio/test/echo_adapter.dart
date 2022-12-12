import 'dart:async';
import 'dart:typed_data';

import 'package:dio/io.dart';
import 'package:dio/dio.dart';

class EchoAdapter implements HttpClientAdapter {
  static const mockHost = 'mockserver';
  static const mockBase = 'http://$mockHost';
  final _adapter = IOHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;

    if (uri.host == mockHost) {
      if (requestStream != null) {
        return ResponseBody(requestStream, 200);
      } else {
        return ResponseBody.fromString(uri.path, 200);
      }
    }

    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}
