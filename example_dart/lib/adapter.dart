import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class MyAdapter implements HttpClientAdapter {
  final HttpClientAdapter _adapter = HttpClientAdapter();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    // Hook requests to pub.dev
    if (uri.host == 'pub.dev') {
      return ResponseBody.fromString('Welcome to pub.dev', 200);
    }
    return _adapter.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {
    _adapter.close(force: force);
  }
}

void main() async {
  final dio = Dio()..httpClientAdapter = MyAdapter();
  Response response = await dio.get('https://pub.dev/');
  print(response);
  response = await dio.get('https://dart.dev/');
  print(response);
}
