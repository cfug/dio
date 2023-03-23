import 'dart:io';
import 'dart:typed_data';

import 'package:cronet_http/cronet_http.dart';
import 'package:cupertino_http/cupertino_http.dart';
import 'package:dio/dio.dart';
import 'cronet_adapter.dart';
import 'cupertino_adapter.dart';

/// A [HttpClientAdapter] for Dio which delegates HTTP requests
/// to the native platform, where possible.
///
/// On iOS and macOS this uses [cupertino_http](https://pub.dev/packages/cupertino_http)
/// to make HTTP requests.
///
/// On Android this uses [cronet_http](https://pub.dev/packages/cronet_http) to
/// make HTTP requests.
class NativeAdapter implements HttpClientAdapter {
  NativeAdapter({
    CronetEngine? androidCronetEngine,
    URLSessionConfiguration? cupertinoConfiguration,
  }) {
    if (Platform.isAndroid) {
      _adapter = CronetAdapter(androidCronetEngine);
    } else if (Platform.isIOS || Platform.isMacOS) {
      _adapter = CupertinoAdapter(
        cupertinoConfiguration ??
            URLSessionConfiguration.defaultSessionConfiguration(),
      );
    } else {
      _adapter = HttpClientAdapter();
    }
  }

  late final HttpClientAdapter _adapter;

  @override
  void close({bool force = false}) => _adapter.close(force: force);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) =>
      _adapter.fetch(options, requestStream, cancelFuture);
}
