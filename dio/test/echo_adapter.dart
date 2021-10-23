import 'dart:async';
import 'dart:typed_data';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';

class EchoAdapter extends HttpClientAdapter {
  static const mockHost = 'mockserver';
  static const mockBase = 'http://$mockHost';
  final _adapter = DefaultHttpClientAdapter();

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future? cancelFuture) async {
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
